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

        function loadMatStyleUsesPartialReadForRegularSelection(testCase)
            lazyArray = io.backend.zarr2.Zarr2LazyArray(testCase.fixturePath, testCase.datasetPath);
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual( ...
                lazyArray.load_mat_style(1:2:3, 2:4:10), ...
                fullData(1:2:3, 2:4:10));
        end
    end
end
