classdef Zarr2LazyArrayTest < matlab.unittest.TestCase

    properties (Access = private)
        fixturePath (1,1) string
        datasetPath = "/acquisition/es/data"
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
        function loadDataAndMetadata(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            datasetInfo = io.backend.zarr2.Zarr2Reader(testCase.fixturePath).readNodeInfo(testCase.datasetPath);
            expectedData = io.internal.zarr2.readDataset( ...
                fullfile(testCase.fixturePath, "acquisition", "es", "data"), datasetInfo);

            testCase.verifyEqual(lazyArray.dims, [4 29]);
            testCase.verifyEqual(lazyArray.maxDims, [4 29]);
            testCase.verifyEqual(lazyArray.dataType, 'single');
            testCase.verifyEqual(lazyArray.load_h5_style(), expectedData);
        end

        function loadPartialDataWithH5StyleSelection(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();
            partialData = lazyArray.load_h5_style([1 2], [2 3], [2 4]);

            testCase.verifyEqual(partialData, fullData(1:2:3, 2:4:10));
        end

        function dataStubSupportsSimpleIndexing(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            datasetInfo = io.backend.zarr2.Zarr2Reader(testCase.fixturePath).readNodeInfo(testCase.datasetPath);
            expectedData = io.internal.zarr2.readDataset( ...
                fullfile(testCase.fixturePath, "acquisition", "es", "data"), datasetInfo);
            dataStub = types.untyped.DataStub( ...
                testCase.fixturePath, testCase.datasetPath, [], [], lazyArray);

            testCase.verifyEqual(dataStub.load(), expectedData);
            testCase.verifyEqual(dataStub(1:3, 2), expectedData(1:3, 2));
        end

        function integer1dDatasetHasCorrectMatlabType(testCase)
            % electrodes/id is the auto-generated integer row-id column (int64).
            % Verifies that the integer dtype mapping reaches the LazyArray.
            lazyArray = io.backend.zarr2.Zarr2LazyArray( ...
                testCase.fixturePath, ...
                "/general/extracellular_ephys/electrodes/id");
            testCase.verifyEqual(lazyArray.dataType, 'int64');
        end

        function loadWithInfCountReadsToEnd(testCase)
            % Passing Inf in the count vector tells readPartialData to compute
            % count = floor((dims - start) / stride) + 1 for that dimension.
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();
            partialData = lazyArray.load_h5_style([2 3], [Inf Inf]);

            testCase.verifyEqual(partialData, fullData(2:end, 3:end));
        end

        function loadMatStyleIrregularSelectionFallsBackToFullRead(testCase)
            % Non-uniform step sizes ([1 2 4] has steps [1 2]) cannot be mapped
            % to a zarrread call, so the implementation falls back to reading all
            % data and indexing in MATLAB.
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();
            result = lazyArray.load_mat_style([1 2 4], 1:29);

            testCase.verifyEqual(result, fullData([1 2 4], 1:29));
        end

        function loadMatStyleUsesPartialReadForRegularSelection(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual( ...
                lazyArray.load_mat_style(1:2:3, 2:4:10), ...
                fullData(1:2:3, 2:4:10));
        end
    end
end
