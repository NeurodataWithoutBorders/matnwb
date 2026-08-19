classdef Zarr3LazyArrayTest < matlab.unittest.TestCase

    properties (Access = private)
        FixturePath (1,1) string
        DatasetPath = "/acquisition/es/data"
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
        function loadDataAndMetadata(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            expectedData = reshape(single(1:116), [4 29]);

            testCase.verifyEqual(lazyArray.dims, [4 29]);
            testCase.verifyEqual(lazyArray.maxDims, [4 29]);
            testCase.verifyEqual(lazyArray.dataType, 'single');
            testCase.verifyEqual(lazyArray.load_h5_style(), expectedData);
        end

        function loadPartialDataWithH5StyleSelection(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();
            partialData = lazyArray.load_h5_style([1 2], [2 3], [2 4]);

            testCase.verifyEqual(partialData, fullData(1:2:3, 2:4:10));
        end

        function dataStubSupportsSimpleIndexing(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            expectedData = reshape(single(1:116), [4 29]);
            dataStub = types.untyped.DataStub(...
                testCase.FixturePath, testCase.DatasetPath, [], [], lazyArray);

            testCase.verifyEqual(dataStub.load(), expectedData);
            testCase.verifyEqual(dataStub(1:3, 2), expectedData(1:3, 2));
        end

        function integer1dDatasetHasCorrectMatlabType(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, ...
                "/general/extracellular_ephys/electrodes/id");
            testCase.verifyEqual(lazyArray.dataType, 'int64');
        end

        function loadWithInfCountReadsToEnd(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();
            partialData = lazyArray.load_h5_style([2 3], [Inf Inf]);

            testCase.verifyEqual(partialData, fullData(2:end, 3:end));
        end

        function loadMatStyleIrregularSelectionFallsBackToFullRead(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();
            result = lazyArray.load_mat_style([1 2 4], 1:29);

            testCase.verifyEqual(result, fullData([1 2 4], 1:29));
        end

        function loadMatStyleUsesPartialReadForRegularSelection(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual(...
                lazyArray.load_mat_style(1:2:3, 2:4:10), ...
                fullData(1:2:3, 2:4:10));
        end

        function compoundDatasetHasStructTypeDescriptor(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");

            testCase.verifyEqual(lazyArray.dims, 3);
            testCase.verifyEqual(lazyArray.dataType, ...
                struct('x', 'uint32', 'y', 'uint32', 'weight', 'single'));
        end

        function compoundLoadH5StyleReturnsStructOfArrays(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");
            data = lazyArray.load_h5_style();

            testCase.verifyClass(data, "struct");
            testCase.verifyEqual(data.x, uint32([0; 1; 2]));
            testCase.verifyEqual(data.weight, single([0.5; 0.6; 0.7]));
        end

        function compoundLoadMatStyleReturnsTable(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");
            selectedRecords = lazyArray.load_mat_style(2:3);

            testCase.verifyClass(selectedRecords, "table");
            testCase.verifyEqual(selectedRecords.x, uint32([1; 2]));
            testCase.verifyEqual(selectedRecords.weight, single([0.6; 0.7]));
        end
    end
end
