classdef Zarr2ReaderTest < matlab.unittest.TestCase

    properties (Access = private)
        fixturePath (1,1) string
    end

    methods (TestClassSetup)
        function setupZarrFixture(testCase)
            tests.util.assumeZarrSupport(testCase)

            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            testCase.applyFixture(PathFixture(tests.util.getZarrWrapperPath()));

            tempFixture = testCase.applyFixture(TemporaryFolderFixture);
            testCase.fixturePath = tests.fixtures.createZarrTestFile(tempFixture.Folder);
        end
    end

    methods (Test)
        function readRootInfoAndSchemaVersion(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            rootInfo = reader.readRootInfo();

            testCase.verifyEqual(rootInfo.Name, '/');
            testCase.verifyMatches(char(reader.getSchemaVersion()), '^\d+\.\d+\.\d+$');
            testCase.verifyEqual(reader.getEmbeddedSpecLocation(), "/specifications");
            testCase.verifyTrue(any(strcmp({rootInfo.Groups.Name}, '/general')));
        end

        function readNodeInfoIncludesLinks(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            nodeInfo = reader.readNodeInfo("/general/extracellular_ephys/shank0");

            testCase.verifyEqual(nodeInfo.Name, '/general/extracellular_ephys/shank0');
            testCase.verifyEqual(numel(nodeInfo.Links), 1);
            testCase.verifyEqual(nodeInfo.Links(1).Name, 'device');
            testCase.verifyEqual(nodeInfo.Links(1).Type, 'soft link');
            testCase.verifyEqual(string(nodeInfo.Links(1).Value{1}), "/general/devices/array");
        end

        function readAttributeValueConvertsObjectReference(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            nodeInfo = reader.readNodeInfo("/units/spike_times_index");
            attributeInfo = nodeInfo.Attributes(strcmp({nodeInfo.Attributes.Name}, 'target'));
            attributeValue = reader.readAttributeValue(attributeInfo, "/units/spike_times_index");

            testCase.verifyClass(attributeValue, "types.untyped.ObjectView");
            testCase.verifyEqual(string(attributeValue.path), "/units/spike_times");
        end

        function readDatasetValueReturnsScalarString(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            rootInfo = reader.readRootInfo();
            datasetInfo = rootInfo.Datasets(strcmp({rootInfo.Datasets.Name}, 'identifier'));
            datasetValue = reader.readDatasetValue(datasetInfo, "/identifier");

            testCase.verifyClass(datasetValue, "char");
            testCase.verifyEqual(datasetValue, 'ZARR_FIXTURE');
        end

        function readObjectDatasetValueReturnsObjectViews(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            datasetInfo = reader.readNodeInfo("/general/extracellular_ephys/electrodes/group");
            datasetValue = reader.readDatasetValue( ...
                datasetInfo, "/general/extracellular_ephys/electrodes/group");

            testCase.verifyClass(datasetValue, "cell");
            testCase.verifyClass(datasetValue{1}, "types.untyped.ObjectView");
            testCase.verifyEqual(string(datasetValue{1}.path), "/general/extracellular_ephys/shank0");
        end

        function readNonScalarDatasetValueReturnsDataStub(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            datasetInfo = reader.readNodeInfo("/acquisition/es/data");
            datasetValue = reader.readDatasetValue(datasetInfo, "/acquisition/es/data");

            testCase.verifyClass(datasetValue, "types.untyped.DataStub");
            testCase.verifyEqual(datasetValue.dims, [4 29]);
        end

        function readEmbeddedSpecificationsFromZarr(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            specs = io.spec.readEmbeddedSpecifications( ...
                testCase.fixturePath, "/specifications", reader);

            testCase.verifyGreaterThan(numel(specs), 0);
            testCase.verifyTrue(any(strcmp(cellfun(@(s) s.namespaceName, specs, 'UniformOutput', false), 'core')));
        end
    end
end
