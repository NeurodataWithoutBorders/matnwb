classdef Zarr3ReaderTest < matlab.unittest.TestCase

    properties (Access = private)
        FixturePath (1,1) string
    end

    methods (TestClassSetup)
        function setupZarrFixture(testCase)
            tests.util.assumeZarr3Support(testCase)

            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            testCase.applyFixture(PathFixture(tests.util.getZarr3DependencyPaths()));

            tempFixture = testCase.applyFixture(TemporaryFolderFixture);
            testCase.FixturePath = tests.fixtures.createZarr3TestFile(tempFixture.Folder);
        end
    end

    methods (Test)
        function readRootInfoAndSchemaVersion(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            rootInfo = reader.readRootInfo();

            testCase.verifyEqual(rootInfo.Name, '/');
            testCase.verifyEqual(reader.getSchemaVersion(), "2.7.0");
            testCase.verifyEqual(reader.getEmbeddedSpecLocation(), "/specifications");
            testCase.verifyTrue(any(strcmp({rootInfo.Groups.Name}, '/general')));
        end

        function readNodeInfoIncludesLinks(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            nodeInfo = reader.readNodeInfo("/general/extracellular_ephys/shank0");

            testCase.verifyEqual(nodeInfo.Name, '/general/extracellular_ephys/shank0');
            testCase.verifyEqual(numel(nodeInfo.Links), 1);
            testCase.verifyEqual(nodeInfo.Links(1).Name, 'device');
            testCase.verifyEqual(nodeInfo.Links(1).Type, 'soft link');
            testCase.verifyEqual(string(nodeInfo.Links(1).Value{1}), "/general/devices/array");

            % The reserved zarr_link attribute must not leak into Attributes.
            testCase.verifyEmpty(nodeInfo.Attributes);
        end

        function readNodeInfoIncludesExternalLinks(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            nodeInfo = reader.readNodeInfo("/acquisition");

            testCase.verifyEqual(numel(nodeInfo.Links), 1);
            testCase.verifyEqual(nodeInfo.Links(1).Name, 'external_series');
            testCase.verifyEqual(nodeInfo.Links(1).Type, 'external link');
            testCase.verifyEqual(string(nodeInfo.Links(1).Value), ...
                ["other_session.nwb.zarr", "/acquisition/es"]);
        end

        function readAttributeValueConvertsObjectReference(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            nodeInfo = reader.readNodeInfo("/units/spike_times_index");
            attributeInfo = nodeInfo.Attributes(strcmp({nodeInfo.Attributes.Name}, 'target'));
            attributeValue = reader.readAttributeValue(attributeInfo, "/units/spike_times_index");

            testCase.verifyClass(attributeValue, "types.untyped.ObjectView");
            testCase.verifyEqual(string(attributeValue.path), "/units/spike_times");
        end

        function readDatasetValueReturnsScalarString(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            rootInfo = reader.readRootInfo();
            datasetInfo = rootInfo.Datasets(strcmp({rootInfo.Datasets.Name}, 'identifier'));
            datasetValue = reader.readDatasetValue(datasetInfo, "/identifier");

            testCase.verifyClass(datasetValue, "char");
            testCase.verifyEqual(datasetValue, 'ZARR3_FIXTURE');
        end

        function readNonScalarDatasetValueReturnsDataStub(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = reader.readNodeInfo("/acquisition/es/data");
            datasetValue = reader.readDatasetValue(datasetInfo, "/acquisition/es/data");

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
            testCase.verifyEqual(datasetValue.dims, [4 29]);
            testCase.verifyEqual(datasetValue.load(), reshape(single(1:116), [4 29]));
        end

        function read1dDatasetReturnsDataStub(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = reader.readNodeInfo("/units/spike_times");
            datasetValue = reader.readDatasetValue(datasetInfo, "/units/spike_times");

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
            testCase.verifyEqual(datasetValue.dims, 5);
            testCase.verifyEqual(datasetValue.load(), [1.1 2.2 3.3 4.4 5.5]');
        end

        function readStringArrayDatasetContainsExpectedValues(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            locationPath = "/general/extracellular_ephys/electrodes/location";
            datasetInfo = reader.readNodeInfo(locationPath);
            datasetValue = reader.readDatasetValue(datasetInfo, locationPath);

            loadedValue = datasetValue.load();
            if iscell(loadedValue)
                loadedValue = string(loadedValue);
            end

            testCase.verifyEqual(numel(loadedValue), 4);
            testCase.verifyTrue(all(string(loadedValue) == "brain"));
        end

        function readIntegerDatasetHasCorrectMatlabType(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            idPath = "/general/extracellular_ephys/electrodes/id";
            datasetInfo = reader.readNodeInfo(idPath);
            datasetValue = reader.readDatasetValue(datasetInfo, idPath);

            testCase.verifyEqual(datasetValue.dataType, 'int64');
            testCase.verifyEqual(datasetValue.load(), int64([0; 1; 2; 3]));
        end

        function externalLinkToDatasetDereferences(testCase)
        % End to end: an external link read out of a Zarr store resolves,
        % through io.backend.BackendFactory, into a reader for the target
        % store and yields that dataset. Exercises the whole chain
        % types.untyped.ExternalLink.deref depends on -- backend detection,
        % readNodeInfo, node classification and isReferenceDataset.
            link = testCase.readScratchLink("linked_data");

            target = link.deref();

            testCase.verifyClass(target, "types.untyped.DataStub");
            testCase.verifyEqual(target.load(), int64([7; 8; 9]));
        end

        function externalLinkToUntypedGroupIsReported(testCase)
        % An untyped group cannot be returned on its own, and deref says so
        % by name. Reaching that specific error is what proves the node was
        % recognised as a group at all: a classification that does not fit
        % this backend fails earlier, with UnknownNodeType.
            link = testCase.readScratchLink("linked_group");

            testCase.verifyError(@() link.deref(), ...
                'NWB:ExternalLink:UntypedGroup');
        end

        function isReferenceDatasetIdentifiesReferenceDatasets(testCase)
        % types.untyped.ExternalLink.deref asks the reader whether a linked
        % dataset holds references, to decide between parsing it and
        % returning a lazy stub. Zarr encodes that as hdmf-zarr's
        % zarr_dtype:"object" rather than a datatype class, which is why the
        % question belongs to the backend.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);

            referenceInfo = reader.readNodeInfo(...
                "/general/extracellular_ephys/electrodes/group");
            testCase.verifyTrue(reader.isReferenceDataset(referenceInfo));

            plainInfo = reader.readNodeInfo(...
                "/general/extracellular_ephys/electrodes/id");
            testCase.verifyFalse(reader.isReferenceDataset(plainInfo));

            % A compound dataset is not a reference dataset, even though
            % individual fields of it may hold references.
            compoundInfo = reader.readNodeInfo(...
                "/processing/ophys/PlaneSegmentation/pixel_mask");
            testCase.verifyFalse(reader.isReferenceDataset(compoundInfo));
        end

        function readObjectReferenceDatasetReturnsObjectViews(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            groupColumnPath = "/general/extracellular_ephys/electrodes/group";
            datasetInfo = reader.readNodeInfo(groupColumnPath);
            testCase.verifyEqual(datasetInfo.Datatype, 'object');

            datasetValue = reader.readDatasetValue(datasetInfo, groupColumnPath);
            testCase.verifyClass(datasetValue, "types.untyped.ObjectView");
            testCase.verifySize(datasetValue, [4 1]);
            testCase.verifyTrue(all(string({datasetValue.path}) == ...
                "/general/extracellular_ephys/shank0"));

            % The reserved zarr_dtype marker must not leak into Attributes.
            testCase.verifyFalse(any(strcmp({datasetInfo.Attributes.Name}, 'zarr_dtype')));
        end

        function readCompoundDatasetReturnsCompoundDataStub(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            pixelMaskPath = "/processing/ophys/PlaneSegmentation/pixel_mask";
            datasetInfo = reader.readNodeInfo(pixelMaskPath);
            datasetValue = reader.readDatasetValue(datasetInfo, pixelMaskPath);

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
            testCase.verifyTrue(datasetValue.isCompoundType());
            testCase.verifyEqual(datasetValue.dataType, ...
                struct('x', 'uint32', 'y', 'uint32', 'weight', 'single'));

            loadedValue = datasetValue.load();
            testCase.verifyClass(loadedValue, "struct");
            testCase.verifyEqual(loadedValue.x, uint32([0; 1; 2]));
            testCase.verifyEqual(loadedValue.y, uint32([0; 1; 2]));
            testCase.verifyEqual(loadedValue.weight, single([0.5; 0.6; 0.7]));

            selectedRecords = datasetValue.load(1, 2);
            testCase.verifyClass(selectedRecords, "table");
            testCase.verifyEqual(selectedRecords.x, uint32([0; 1]));
        end

        function readNodeInfoThrowsForMissingNode(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            testCase.verifyError(...
                @() reader.readNodeInfo("/does/not/exist"), ...
                "NWB:Zarr3Reader:NodeNotFound");
        end

        function readNodeInfoNormalizesPath(testCase)
        % An empty path names the root node, and a missing leading slash
        % is added before the lookup.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);

            rootInfo = reader.readNodeInfo("");
            testCase.verifyEqual(rootInfo.Name, '/');

            unitsInfo = reader.readNodeInfo("units");
            testCase.verifyEqual(unitsInfo.Name, '/units');
        end

        function missingSchemaVersionErrors(testCase)
        % A store whose root attributes lack nwb_version is not an NWB
        % store, and the reader must say so rather than guess.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            folderFixture = testCase.applyFixture(TemporaryFolderFixture);
            storePath = string(fullfile(folderFixture.Folder, "bare.zarr"));
            zarr.create_group(storePath);

            reader = io.backend.zarr3.Zarr3Reader(storePath);
            testCase.verifyError(@() reader.getSchemaVersion(), ...
                "NWB:Zarr3Reader:MissingSchemaVersion");
        end

        function specLocationFallsBackToConventionalGroupName(testCase)
        % A writer that omits the ".specloc" root attribute still gets its
        % cached specifications found under the conventional group name.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            folderFixture = testCase.applyFixture(TemporaryFolderFixture);
            storePath = string(fullfile(folderFixture.Folder, "no-specloc.zarr"));
            root = zarr.create_group(storePath, ...
                Attributes=struct('nwb_version', "2.7.0"));
            root.createGroup("specifications");

            reader = io.backend.zarr3.Zarr3Reader(storePath);
            testCase.verifyEqual(reader.getEmbeddedSpecLocation(), "/specifications");
        end

        function readAttributeValuePassesPlainValueThrough(testCase)
        % Only attributes tagged "object reference" are decoded; any other
        % attribute value is returned as stored.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            rootInfo = reader.readRootInfo();
            attributeInfo = rootInfo.Attributes(...
                strcmp({rootInfo.Attributes.Name}, 'nwb_version'));

            attributeValue = reader.readAttributeValue(attributeInfo, "/");

            testCase.verifyEqual(string(attributeValue), "2.7.0");
        end

        function readScalarMarkedDatasetReturnsBareValue(testCase)
        % hdmf-zarr represents an NWB scalar property as a rank-1, length-1
        % array tagged zarr_dtype:"scalar"; the tag, not the shape, is what
        % makes the reader return a bare value (see the corresponding
        % comment in readDatasetValue).
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = reader.readNodeInfo("/general/session_id");
            testCase.verifyEqual(datasetInfo.Datatype, 'scalar');

            datasetValue = reader.readDatasetValue(datasetInfo, "/general/session_id");

            testCase.verifyEqual(datasetValue, 'sess-01');
        end

        function readEmptyDatasetReturnsEmpty(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = reader.readNodeInfo("/scratch/empty");

            datasetValue = reader.readDatasetValue(datasetInfo, "/scratch/empty");

            testCase.verifyEmpty(datasetValue);
        end

        function readDatasetValueToleratesMissingDataspace(testCase)
        % A node info struct without a Dataspace field reads as a scalar;
        % the reader must not assume the field exists.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = struct('Datatype', 'string');

            datasetValue = reader.readDatasetValue(datasetInfo, "/identifier");

            testCase.verifyEqual(datasetValue, 'ZARR3_FIXTURE');
        end

        function readEagerValueUnwrapsScalarCell(testCase)
        % zarr-matlab reads a variable_length_bytes array back as a cell of
        % uint8 vectors; for a rank-0 dataset the eager path unwraps the
        % scalar cell so the caller gets the bare value.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            datasetInfo = reader.readNodeInfo("/scratch/blob");

            datasetValue = reader.readDatasetValue(datasetInfo, "/scratch/blob");

            testCase.verifyClass(datasetValue, "uint8");
            testCase.verifyEqual(datasetValue(:).', uint8([1 2 3]));
        end

        function readCompoundDatasetDecodesReferenceField(testCase)
        % A compound field tagged "object" via the array's zarr_dtype
        % attribute holds JSON reference records; the reader must declare it
        % as ObjectView in the type descriptor and decode it on load.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            referencePath = "/intervals/trials/timeseries";
            datasetInfo = reader.readNodeInfo(referencePath);

            datasetValue = reader.readDatasetValue(datasetInfo, referencePath);

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
            testCase.verifyEqual(datasetValue.dataType, struct(...
                'idx_start', 'int32', ...
                'count', 'int32', ...
                'timeseries', 'types.untyped.ObjectView'));

            loadedValue = datasetValue.load();
            testCase.verifyEqual(loadedValue.idx_start, int32([0; 10]));
            testCase.verifyClass(loadedValue.timeseries, "types.untyped.ObjectView");
            testCase.verifyTrue(all(string({loadedValue.timeseries.path}) == ...
                "/acquisition/es"));
        end
    end

    methods (Access = private)
        function link = readScratchLink(testCase, linkName)
        % readScratchLink - Build an ExternalLink from the fixture's own
        % metadata, so the target location is never hard-coded here.
            reader = io.backend.zarr3.Zarr3Reader(testCase.FixturePath);
            nodeInfo = reader.readNodeInfo("/scratch");
            record = nodeInfo.Links(strcmp({nodeInfo.Links.Name}, linkName));
            testCase.assertEqual(record.Type, 'external link');
            link = types.untyped.ExternalLink(record.Value{1}, record.Value{2});
        end
    end

end
