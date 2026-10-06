classdef ReferenceTargetResolverTest < matlab.unittest.TestCase
% ReferenceTargetResolverTest - Tests for io.backend.hdf5.ReferenceTargetResolver.
%
% The resolver replaces a per-reference H5R.get_name call with an address
% lookup, so these tests check that it returns exactly what H5R.get_name
% returns, for dataset and attribute references alike.

    properties (Constant)
        FileName = "reference-resolver-test.nwb"
        NumPlaneSegmentations = 3
        ElectrodesGroupPath = '/general/extracellular_ephys/electrodes/group'
    end

    methods (TestClassSetup)
        function createTestFile(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            nwb = tests.factory.NWBFile();

            % A "group" column of object references in a dataset.
            tests.factory.ElectrodeTable(nwb);

            % One VectorIndex per plane segmentation, each referencing its
            % target in an attribute, and a DynamicTableRegion referencing
            % a plane segmentation.
            device = types.core.Device();
            nwb.general_devices.set('Microscope', device);
            imagingPlane = tests.factory.ImagingPlane(device);
            nwb.general_optophysiology.set('ImagingPlane', imagingPlane);

            imageSegmentation = types.core.ImageSegmentation();
            for iTable = 1:testCase.NumPlaneSegmentations
                planeSegmentation = tests.factory.PlaneSegmentation(imagingPlane, ...
                    'RoiType', 'pixel_mask', 'NumRois', 2, 'ImageShape', [20, 20]);
                imageSegmentation.planesegmentation.set( ...
                    sprintf('PlaneSegmentation%d', iTable), planeSegmentation);
            end
            fluorescence = types.core.Fluorescence();
            fluorescence.roiresponseseries.set('RoiResponseSeries', ...
                tests.factory.RoiResponseSeries(planeSegmentation, 'NumTimepoints', 5));

            ophysModule = types.core.ProcessingModule('description', 'ophys');
            ophysModule.nwbdatainterface.set('ImageSegmentation', imageSegmentation);
            ophysModule.nwbdatainterface.set('Fluorescence', fluorescence);
            nwb.processing.set('ophys', ophysModule);

            nwbExport(nwb, testCase.FileName);
        end
    end

    methods (Test)
        function resolveMatchesGetNameForDatasetReferences(testCase)
            fileId = H5F.open(testCase.FileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>
            datasetId = H5D.open(fileId, testCase.ElectrodesGroupPath);
            datasetCleanup = onCleanup(@() H5D.close(datasetId)); %#ok<NASGU>
            rawReferences = H5D.read(datasetId);

            resolver = testCase.createResolver();
            referenceType = H5ML.get_constant_value('H5R_OBJECT');
            for iReference = 1:size(rawReferences, 2)
                rawReference = rawReferences(:, iReference);
                testCase.verifyEqual( ...
                    resolver.resolve(datasetId, referenceType, rawReference), ...
                    H5R.get_name(datasetId, referenceType, rawReference));
            end
        end

        function resolveMatchesGetNameForAttributeReferences(testCase)
            fileId = H5F.open(testCase.FileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>

            resolver = testCase.createResolver();
            referenceType = H5ML.get_constant_value('H5R_OBJECT');
            for iTable = 1:testCase.NumPlaneSegmentations
                indexPath = sprintf( ...
                    '/processing/ophys/ImageSegmentation/PlaneSegmentation%d/pixel_mask_index', iTable);
                attributeId = H5A.open_by_name(fileId, indexPath, 'target');
                rawReference = H5A.read(attributeId, 'H5ML_DEFAULT');

                expectedPath = H5R.get_name(attributeId, referenceType, rawReference);
                actualPath = resolver.resolve(attributeId, referenceType, rawReference);
                H5A.close(attributeId);

                testCase.verifyEqual(actualPath, expectedPath);
                testCase.verifyEqual(actualPath, sprintf( ...
                    '/processing/ophys/ImageSegmentation/PlaneSegmentation%d/pixel_mask', iTable));
            end
        end

        function resolveFallsBackForTargetsWithoutRecordedPath(testCase)
            % A resolver that knows no paths has to give the same answer
            % by falling back to H5R.get_name.
            fileId = H5F.open(testCase.FileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>
            datasetId = H5D.open(fileId, testCase.ElectrodesGroupPath);
            datasetCleanup = onCleanup(@() H5D.close(datasetId)); %#ok<NASGU>
            rawReferences = H5D.read(datasetId);

            resolver = io.backend.hdf5.ReferenceTargetResolver({});
            referenceType = H5ML.get_constant_value('H5R_OBJECT');
            testCase.verifyEqual( ...
                resolver.resolve(datasetId, referenceType, rawReferences(:, 1)), ...
                H5R.get_name(datasetId, referenceType, rawReferences(:, 1)));
        end

        function resolveUsesRecordedPathsInsteadOfGetName(testCase)
            % The target is reachable as both /a_alias and /z_target.
            % H5R.get_name returns /a_alias, the first path in name order,
            % while the address lookup returns the only path it recorded.
            % Returning /z_target therefore proves the lookup ran instead
            % of the H5R.get_name fallback.
            fileName = 'hard-linked-reference.h5';
            createHardLinkedReferenceFile(fileName);

            fileId = H5F.open(fileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>
            datasetId = H5D.open(fileId, '/refs');
            datasetCleanup = onCleanup(@() H5D.close(datasetId)); %#ok<NASGU>
            rawReference = H5D.read(datasetId);

            referenceType = H5ML.get_constant_value('H5R_OBJECT');
            testCase.assumeEqual( ...
                H5R.get_name(datasetId, referenceType, rawReference), '/a_alias', ...
                'H5R.get_name must return the alias for this test to tell the two paths apart.');

            resolver = io.backend.hdf5.ReferenceTargetResolver({'/', '/z_target'});
            testCase.verifyEqual( ...
                resolver.resolve(datasetId, referenceType, rawReference), '/z_target');
        end

        function objectPathsAreGatheredOnFirstResolve(testCase)
            fileId = H5F.open(testCase.FileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>
            datasetId = H5D.open(fileId, testCase.ElectrodesGroupPath);
            datasetCleanup = onCleanup(@() H5D.close(datasetId)); %#ok<NASGU>
            rawReferences = H5D.read(datasetId);

            callCounter = containers.Map({'count'}, {0});
            filename = char(testCase.FileName);
            resolver = io.backend.hdf5.ReferenceTargetResolver( ...
                @() countedListObjectPaths(filename, callCounter));
            testCase.verifyEqual(callCounter('count'), 0)

            referenceType = H5ML.get_constant_value('H5R_OBJECT');
            resolver.resolve(datasetId, referenceType, rawReferences(:, 1));
            resolver.resolve(datasetId, referenceType, rawReferences(:, 1));
            testCase.verifyEqual(callCounter('count'), 1)
        end

        function listObjectPathsIsDepthFirstInNameOrder(testCase)
            datasetB = struct('Name', 'b');
            groupA = struct('Name', '/a', 'Groups', [], 'Datasets', struct('Name', 'x'));
            groupC = struct('Name', '/c', 'Groups', [], 'Datasets', []);
            rootInfo = struct('Name', '/', 'Groups', [groupC, groupA], 'Datasets', datasetB);

            objectPaths = io.backend.hdf5.ReferenceTargetResolver.listObjectPaths(rootInfo);

            testCase.verifyEqual(objectPaths, {'/', '/a', '/a/x', '/b', '/c'});
        end

        function readerResolvesReferencesOnRead(testCase)
            nwb = nwbRead(testCase.FileName, 'ignorecache');

            planeSegmentation = nwb.processing.get('ophys') ...
                .nwbdatainterface.get('ImageSegmentation') ...
                .planesegmentation.get('PlaneSegmentation1');
            testCase.verifyEqual(planeSegmentation.pixel_mask_index.target.path, ...
                '/processing/ophys/ImageSegmentation/PlaneSegmentation1/pixel_mask');
        end
    end

    methods (Access = private)
        function resolver = createResolver(testCase)
            objectPaths = io.backend.hdf5.ReferenceTargetResolver.listObjectPaths( ...
                h5info(testCase.FileName));
            resolver = io.backend.hdf5.ReferenceTargetResolver(objectPaths);
        end
    end
end

function objectPaths = countedListObjectPaths(filename, callCounter)
    callCounter('count') = callCounter('count') + 1;
    objectPaths = io.backend.hdf5.ReferenceTargetResolver.listObjectPaths(h5info(filename));
end

function createHardLinkedReferenceFile(fileName)
% createHardLinkedReferenceFile - Write a dataset linked as /z_target and
% /a_alias, and a dataset /refs holding one object reference to /z_target.
    fileId = H5F.create(fileName, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
    fileCleanup = onCleanup(@() H5F.close(fileId)); %#ok<NASGU>

    targetSpaceId = H5S.create_simple(1, 3, []);
    targetSpaceCleanup = onCleanup(@() H5S.close(targetSpaceId)); %#ok<NASGU>
    targetId = H5D.create(fileId, '/z_target', 'H5T_NATIVE_DOUBLE', targetSpaceId, 'H5P_DEFAULT');
    targetCleanup = onCleanup(@() H5D.close(targetId)); %#ok<NASGU>
    H5D.write(targetId, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', [1, 2, 3]);

    H5L.create_hard(fileId, '/z_target', fileId, '/a_alias', 'H5P_DEFAULT', 'H5P_DEFAULT');

    referenceSpaceId = H5S.create_simple(1, 1, []);
    referenceSpaceCleanup = onCleanup(@() H5S.close(referenceSpaceId)); %#ok<NASGU>
    referencesId = H5D.create(fileId, '/refs', 'H5T_STD_REF_OBJ', referenceSpaceId, 'H5P_DEFAULT');
    referencesCleanup = onCleanup(@() H5D.close(referencesId)); %#ok<NASGU>
    rawReference = H5R.create(fileId, '/z_target', 'H5R_OBJECT', -1);
    H5D.write(referencesId, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', rawReference);
end
