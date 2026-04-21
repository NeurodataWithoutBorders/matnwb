classdef Zarr2LazyArrayTest < matlab.unittest.TestCase

    properties (Constant, Access = private)
        fixturePath = "/Users/eivind/Code/MATLAB/Sandbox/CN/zarr_matlab/test_data/test_zarr_sub_anm00239123_ses_20170627T093549_ecephys_and_ogen.nwb.zarr"
        wrapperPath = "/Users/eivind/Code/MATLAB/General/Repositories/mathworks/MATLAB-support-for-Zarr-files"
        datasetPath = "/units/waveform_mean"
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
        function loadDataAndMetadata(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            datasetInfo = io.backend.zarr2.Zarr2Reader(testCase.fixturePath).readNodeInfo(testCase.datasetPath);
            expectedData = io.internal.zarr2.readDataset( ...
                fullfile(testCase.fixturePath, "units", "waveform_mean"), datasetInfo);

            testCase.verifyEqual(lazyArray.dims, [29 4]);
            testCase.verifyEqual(lazyArray.maxDims, [29 4]);
            testCase.verifyEqual(lazyArray.dataType, 'single');
            testCase.verifyEqual(lazyArray.load_h5_style(), expectedData);
        end

        function loadPartialDataWithH5StyleSelection(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();
            partialData = lazyArray.load_h5_style([2 1], [3 2], [2 1]);

            testCase.verifyEqual(partialData, fullData(2:2:6, 1:2));
        end

        function dataStubSupportsSimpleIndexing(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            datasetInfo = io.backend.zarr2.Zarr2Reader(testCase.fixturePath).readNodeInfo(testCase.datasetPath);
            expectedData = io.internal.zarr2.readDataset( ...
                fullfile(testCase.fixturePath, "units", "waveform_mean"), datasetInfo);
            dataStub = types.untyped.DataStub( ...
                testCase.fixturePath, testCase.datasetPath, [], [], lazyArray);

            testCase.verifyEqual(dataStub.load(), expectedData);
            testCase.verifyEqual(dataStub(1:5, 2), expectedData(1:5, 2));
        end

        function loadMatStyleUsesPartialReadForRegularSelection(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual( ...
                lazyArray.load_mat_style(2:2:6, 1:2), ...
                fullData(2:2:6, 1:2));
        end
    end
end
