classdef Zarr2ReaderTest < matlab.unittest.TestCase

    properties (Constant, Access = private)
        fixturePath = "/Users/eivind/Code/MATLAB/Sandbox/CN/zarr_matlab/test_data/test_zarr_sub_anm00239123_ses_20170627T093549_ecephys_and_ogen.nwb.zarr"
        wrapperPath = "/Users/eivind/Code/MATLAB/General/Repositories/mathworks/MATLAB-support-for-Zarr-files"
    end

    methods (TestClassSetup)
        function addZarrWrapperToPath(testCase)
            testCase.assumeTrue(isfolder(testCase.wrapperPath), ...
                "MathWorks Zarr wrapper checkout not found.")
            testCase.assumeTrue(isfolder(testCase.fixturePath), ...
                "Primary Zarr fixture not found.")

            addpath(testCase.wrapperPath)
            testCase.addTeardown(@() rmpath(testCase.wrapperPath))
        end
    end

    methods (Test)
        function readRootInfoAndSchemaVersion(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            rootInfo = reader.readRootInfo();

            testCase.verifyEqual(rootInfo.Name, '/');
            testCase.verifyEqual(reader.getSchemaVersion(), "2.7.0");
            testCase.verifyEqual(reader.getEmbeddedSpecLocation(), "/specifications");
            testCase.verifyTrue(any(strcmp({rootInfo.Groups.Name}, '/general')));
        end

        function readNodeInfoIncludesLinks(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            nodeInfo = reader.readNodeInfo("/general/extracellular_ephys/ADunit_32");

            testCase.verifyEqual(nodeInfo.Name, '/general/extracellular_ephys/ADunit_32');
            testCase.verifyEqual(numel(nodeInfo.Links), 1);
            testCase.verifyEqual(nodeInfo.Links(1).Name, 'device');
            testCase.verifyEqual(nodeInfo.Links(1).Type, 'soft link');
            testCase.verifyEqual(string(nodeInfo.Links(1).Value{1}), "/general/devices/ADunit");
        end

        function readAttributeValueConvertsObjectReference(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            nodeInfo = reader.readNodeInfo("/units/electrodes_index");
            attributeInfo = nodeInfo.Attributes(strcmp({nodeInfo.Attributes.Name}, 'target'));
            attributeValue = reader.readAttributeValue(attributeInfo, "/units/electrodes_index");

            testCase.verifyClass(attributeValue, "types.untyped.ObjectView");
            testCase.verifyEqual(string(attributeValue.path), "/units/electrodes");
        end

        function readDatasetValueReturnsScalarString(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            rootInfo = reader.readRootInfo();
            datasetInfo = rootInfo.Datasets(strcmp({rootInfo.Datasets.Name}, 'identifier'));
            datasetValue = reader.readDatasetValue(datasetInfo, "/identifier");

            testCase.verifyClass(datasetValue, "char");
            testCase.verifyFalse(isempty(datasetValue));
        end

        function readObjectDatasetValueReturnsObjectViews(testCase)
            reader = io.backend.zarr2.Zarr2Reader(testCase.fixturePath);
            datasetInfo = reader.readNodeInfo("/general/extracellular_ephys/electrodes/group");
            datasetValue = reader.readDatasetValue( ...
                datasetInfo, "/general/extracellular_ephys/electrodes/group");

            testCase.verifyClass(datasetValue, "cell");
            testCase.verifyClass(datasetValue{1}, "types.untyped.ObjectView");
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
