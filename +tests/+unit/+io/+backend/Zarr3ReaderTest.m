classdef Zarr3ReaderTest < matlab.unittest.TestCase

    properties (Access = private)
        FixturePath (1,1) string
    end

    methods (TestClassSetup)
        function setupZarrFixture(testCase)
            tests.util.assumeZarr3Support(testCase)

            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            testCase.applyFixture(PathFixture(tests.util.getZarr3MatlabPath()));

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
    end
end
