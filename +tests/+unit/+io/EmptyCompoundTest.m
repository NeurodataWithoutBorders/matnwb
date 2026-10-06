classdef EmptyCompoundTest < tests.abstract.NwbTestCase
% EmptyCompoundTest - Test that a compound dataset without rows is imported correctly
%
% A compound dataset can legitimately hold no rows, as the HERD tables of a
% file without external resource references do. Its member names and types are
% part of its structure, so reading it must keep them available even though
% there is no data to inspect.

    properties (Constant, Access = private)
        DatasetPath = '/analysis/compound/data'
    end

    methods (TestClassSetup)
        function generateTestSchemas(testCase)
            % Generate the rrs and cs test extensions for use in all tests
            % of this test suite, using fixture for proper cleanup
            testCase.applyTestSchemaFixture('rrs');
            testCase.applyTestSchemaFixture('cs');
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testEmptyCompoundIO(testCase)
            import tests.unit.io.EmptyCompoundTest

            sourceFileName = testCase.writeFileWithEmptyCompound();

            sourceDescription = ...
                EmptyCompoundTest.describeCompound(sourceFileName, EmptyCompoundTest.DatasetPath);
            testCase.assertEqual(sourceDescription.Size, 0, ...
                'Expected the compound dataset under test to hold no rows.')

            % Read
            nwbIn = nwbRead(sourceFileName, 'ignorecache');
            stub = nwbIn.analysis.get('compound').data;

            % The dataset is stubbed rather than collapsed to [], so that the
            % member names and types survive the read.
            testCase.verifyClass(stub, 'types.untyped.DataStub')
            testCase.verifyEqual(stub.dims, 0)
            testCase.verifyEqual(stub.dataType, ...
                struct('index', 'uint32', 'label', 'char', 'flag', 'logical'))

            loaded = stub.load();
            testCase.verifyEqual(fieldnames(loaded), {'index'; 'label'; 'flag'})
            testCase.verifyClass(loaded.index, 'uint32')
            testCase.verifyClass(loaded.label, 'cell')
            testCase.verifyClass(loaded.flag, 'logical')
            testCase.verifyEmpty(loaded.index)

            % Indexing yields the zero-row form of the table a populated
            % compound dataset is read as.
            indexed = stub(:);
            testCase.verifyClass(indexed, 'table')
            testCase.verifySize(indexed, [0 3])
            testCase.verifyEqual(indexed.Properties.VariableNames, ...
                {'index', 'label', 'flag'})

            % Round trip: the dataset is written back out with the members and
            % types it was read with.
            roundTripFileName = testCase.getRandomFilename();
            nwbExport(nwbIn, roundTripFileName);

            testCase.verifyEqual( ...
                EmptyCompoundTest.describeCompound(roundTripFileName, EmptyCompoundTest.DatasetPath), ...
                sourceDescription)

            nwbRoundTrip = nwbRead(roundTripFileName, 'ignorecache');
            testCase.verifyEqual( ...
                nwbRoundTrip.analysis.get('compound').data.dataType, stub.dataType)
        end

        function testEmptyCompoundWithReferenceMember(testCase)
            % Boolean and reference members are stored as an enum and as a raw
            % HDF5 reference, so their MATLAB types can only be recovered from
            % the compound type once the dataset holds no rows to inspect.

            fileName = testCase.getRandomFilename();
            datasetPath = '/empty_compound';
            tests.unit.io.EmptyCompoundTest.writeReferenceCompound(fileName, datasetPath);

            datasetInfo = h5info(fileName, datasetPath);
            parsed = io.parseDataset(fileName, datasetInfo, datasetPath);
            stub = parsed('empty_compound');

            testCase.verifyClass(stub, 'types.untyped.DataStub')
            testCase.verifyEqual(stub.dataType, struct( ...
                'flag', 'logical', ...
                'objref', 'types.untyped.ObjectView'))

            loaded = stub.load();
            testCase.verifyEqual(fieldnames(loaded), {'flag'; 'objref'})
            testCase.verifyClass(loaded.flag, 'logical')
            testCase.verifyClass(loaded.objref, 'types.untyped.ObjectView')
            testCase.verifyEmpty(loaded.objref)

            % Exporting copies the dataset rather than rewriting it row by row,
            % so the reference member survives even though there is no
            % reference value to derive its HDF5 type from.
            copyFileName = testCase.getRandomFilename();
            writer = io.backend.BackendFactory.createWriter(copyFileName, 'Mode', "overwrite");
            writerCleanup = onCleanup(@() writer.close());
            stub.export(writer, datasetPath, {});
            clear writerCleanup

            testCase.verifyEqual( ...
                tests.unit.io.EmptyCompoundTest.describeCompound(copyFileName, datasetPath), ...
                tests.unit.io.EmptyCompoundTest.describeCompound(fileName, datasetPath))
        end
    end

    methods (Access = private)
        function fileName = writeFileWithEmptyCompound(testCase)
        % writeFileWithEmptyCompound - Write a file holding a row-less compound
        % dataset, as another NWB writer would produce it.
        %
        % Exporting the row-less form directly would not produce the dataset at
        % all: the generated export guards an untyped dataset property with
        % ~isempty, and a table without rows is empty. The dataset is therefore
        % exported with rows and then replaced by a row-less dataset of the same
        % compound type. That also matches how such a dataset reaches MatNWB in
        % practice, written by another NWB writer.

            import tests.unit.io.EmptyCompoundTest

            nwb = tests.factory.NWBFile();
            populatedData = table( ...
                uint32([1; 2]), ...
                {'first'; 'second'}, ...
                [true; false], ...
                'VariableNames', {'index', 'label', 'flag'});
            nwb.analysis.set('compound', ...
                types.cs.PlainCompoundData('data', populatedData));

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);
            EmptyCompoundTest.dropCompoundRows(fileName, EmptyCompoundTest.DatasetPath);
        end
    end

    methods (Static, Access = private)
        function description = describeCompound(fileName, datasetPath)
        % describeCompound - Row count and member types of a compound dataset.
            info = h5info(fileName, datasetPath);
            description = struct('Size', info.Dataspace.Size, 'Members', struct());
            for iMember = 1:numel(info.Datatype.Type.Member)
                member = info.Datatype.Type.Member(iMember);
                description.Members.(member.Name) = member.Datatype.Class;
            end
        end

        function dropCompoundRows(fileName, datasetPath)
        % dropCompoundRows - Replace a compound dataset with a row-less dataset
        % of the same compound type.
            fileId = H5F.open(fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId));

            datasetId = H5D.open(fileId, datasetPath);
            typeId = H5D.get_type(datasetId);
            typeCleanup = onCleanup(@() H5T.close(typeId));
            H5D.close(datasetId);

            H5L.delete(fileId, datasetPath, 'H5P_DEFAULT');

            spaceId = H5S.create_simple(1, 0, []);
            spaceCleanup = onCleanup(@() H5S.close(spaceId));
            datasetId = H5D.create(fileId, datasetPath, typeId, spaceId, 'H5P_DEFAULT');
            H5D.close(datasetId);
        end

        function writeReferenceCompound(fileName, datasetPath)
        % writeReferenceCompound - Write a row-less compound dataset holding a
        % boolean and an object reference member.
        %
        % io.writeCompound cannot produce this dataset because it derives the
        % HDF5 reference data from the reference values, of which there are
        % none, so the compound type is assembled here instead.
            fileId = H5F.create(fileName, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId));

            boolTypeId = io.getBaseType('logical');
            boolCleanup = onCleanup(@() H5T.close(boolTypeId));
            referenceTypeId = io.getBaseType('types.untyped.ObjectView');

            boolSize = H5T.get_size(boolTypeId);
            referenceSize = H5T.get_size(referenceTypeId);

            typeId = H5T.create('H5T_COMPOUND', boolSize + referenceSize);
            typeCleanup = onCleanup(@() H5T.close(typeId));
            H5T.insert(typeId, 'flag', 0, boolTypeId);
            H5T.insert(typeId, 'objref', boolSize, referenceTypeId);

            spaceId = H5S.create_simple(1, 0, []);
            spaceCleanup = onCleanup(@() H5S.close(spaceId));

            datasetId = H5D.create(fileId, datasetPath, typeId, spaceId, 'H5P_DEFAULT');
            H5D.close(datasetId);
        end
    end
end
