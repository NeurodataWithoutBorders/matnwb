classdef Zarr3LazyArrayTest < matlab.unittest.TestCase

    properties (Access = private)
        FixturePath (1,1) string
        DatasetPath = "/acquisition/es/data"
    end

    properties (TestParameter)
        % linearSelection - Single-subscript selections into the 4x29
        % fixture dataset, covering the orderings and shapes MATLAB linear
        % indexing has to reproduce.
        linearSelection = struct(...
            'scalar', 1, ...
            'ascending', [1 2 3], ...
            'unordered', [3 1 2], ...
            'duplicated', [5 5 2], ...
            'column', (1:6)', ...
            'lastElement', 116, ...
            'everyElement', 1:116, ...
            'empty', [])
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

        function linearIndexSelectionMatchesNativeIndexing(testCase, linearSelection)
        % A lone subscript is MATLAB linear indexing, which has no Zarr
        % equivalent -- zarr.Array.read takes a contiguous hyperslab. The
        % result must still match indexing the fully loaded array, including
        % the value order, the duplicates and the orientation.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();

            selectedData = lazyArray.load_mat_style(linearSelection);

            testCase.verifyEqual(selectedData, fullData(linearSelection));
        end

        function singleElementReadDoesNotMaterialiseSparseDataset(testCase)
        % Regression test: a single subscript used to be rejected by
        % tryBuildRegularSelection and fall through to a full read, so
        % probing a large sparse dataset -- which types.util.checkDtype does
        % via load(1) on every "any" dtype -- tried to allocate the whole
        % array and failed on the MATLAB array size limit.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            folderFixture = testCase.applyFixture(TemporaryFolderFixture);
            storePath = string(fullfile(folderFixture.Folder, "sparse.zarr"));

            % Metadata only: no chunk holds data, so the store stays tiny
            % while the array it describes could never fit in memory.
            zarr.create(storePath, [1e6 1e6], "double", ...
                Path="huge", ChunkShape=[10 10]);
            lazyArray = io.backend.zarr3.Zarr3LazyArray(storePath, "/huge");

            testCase.verifyEqual(lazyArray.dims, [1e6 1e6]);
            testCase.verifyEqual(lazyArray.load_mat_style(1), 0);
            testCase.verifyEqual(lazyArray.load_mat_style([1 2]), [0 0]);
        end

        function compoundTextFieldsReadBackAsCellstr(testCase)
        % zarr-matlab returns Zarr text as a MATLAB string, but
        % io.parseCompound gives a cellstr column for an HDF5 compound's
        % string field and the generated type classes declare such fields as
        % 'char'. The Zarr backend converts so that the same compound reads
        % back as the same MATLAB types on either backend -- without which
        % types.util.checkDtype rejects the dataset outright.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/entities");

            testCase.verifyEqual(lazyArray.dataType, ...
                struct('entity_id', 'char', 'entity_uri', 'char'));

            data = lazyArray.load_h5_style();
            testCase.verifyClass(data.entity_id, "cell");
            testCase.verifyEqual(data.entity_id, {'NCBITaxon:10090'; 'MBA:385'});
        end

        function compoundTextSurvivesPartialRead(testCase)
        % The conversion runs in postProcessCompound, which serves partial
        % reads too, so a selected record must convert the same way.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/entities");

            selectedRecords = lazyArray.load_mat_style(2);

            testCase.verifyClass(selectedRecords, "table");
            testCase.verifyEqual(selectedRecords.entity_id, {'MBA:385'});
        end

        function linearIndexOutOfRangeErrors(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, testCase.DatasetPath);

            testCase.verifyError(@() lazyArray.load_mat_style(117), ...
                'NWB:DataStub:Load:InvalidSelection');
            testCase.verifyError(@() lazyArray.load_mat_style(0), ...
                'NWB:DataStub:Load:InvalidSelection');
        end

        function loadMatStyleWithNoArgumentsLoadsEverything(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, testCase.DatasetPath);
            testCase.verifyEqual(lazyArray.load_mat_style(), ...
                reshape(single(1:116), [4 29]));

            % A compound dataset keeps the table convention on this path too.
            compoundArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");
            allRecords = compoundArray.load_mat_style();
            testCase.verifyClass(allRecords, "table");
            testCase.verifyEqual(height(allRecords), 3);
        end

        function compoundRegularSelectionUsesPartialRead(testCase)
        % Two subscripts route through the regular-selection partial read
        % (a lone subscript cannot: compound datasets are excluded from the
        % linear-selection path), and the selected records must still come
        % back as a table.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");

            selectedRecords = lazyArray.load_mat_style(2:3, 1);

            testCase.verifyClass(selectedRecords, "table");
            testCase.verifyEqual(selectedRecords.x, uint32([1; 2]));
            testCase.verifyEqual(selectedRecords.weight, single([0.6; 0.7]));
        end

        function emptySelectionOnCompoundReturnsNoRecords(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/processing/ophys/PlaneSegmentation/pixel_mask");

            selectedRecords = lazyArray.load_mat_style([]);

            testCase.verifyClass(selectedRecords, "table");
            testCase.verifyEqual(height(selectedRecords), 0);
        end

        function colonSelectionMatchesNativeIndexing(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual(lazyArray.load_mat_style(':'), fullData(:));
        end

        function logicalSelectionFallsBackToFullRead(testCase)
        % A logical mask is valid MATLAB indexing but has no hyperslab
        % equivalent, so it must take the full-read fallback.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, testCase.DatasetPath);
            fullData = lazyArray.load_h5_style();
            rowMask = logical([1 0 1 1]);

            testCase.verifyEqual(...
                lazyArray.load_mat_style(rowMask, 1:29), ...
                fullData(rowMask, 1:29));
        end

        function rank3DatasetReversesAxesAndPadsSelection(testCase)
        % Rank >= 3 exercises the permute branch of
        % io.internal.zarr3.normalizeDatasetDimensions (rank 2 uses a plain
        % transpose), and a selection naming fewer subscripts than the rank
        % reads index 1 of each unnamed trailing dimension -- matching
        % io.backend.hdf5.@HDF5LazyArray/load_mat_style, not MATLAB's
        % trailing-dimension folding.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/acquisition/vol/data");
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual(lazyArray.dims, [2 3 4]);
            % The store holds numpy-order [4 3 2] data written as
            % reshape(1:24, [4 3 2]); reversing the axes maps element
            % (i,j,k) to raw (k,j,i).
            testCase.verifyEqual(fullData(1, 1, 1), 1);
            testCase.verifyEqual(fullData(2, 3, 4), 24);

            testCase.verifyEqual(...
                lazyArray.load_mat_style(1:2, 2), ...
                fullData(1:2, 2, 1));
        end

        function linearIndexInto1dDatasetKeepsColumnShape(testCase)
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/units/spike_times");
            fullData = lazyArray.load_h5_style();

            testCase.verifyEqual(lazyArray.load_mat_style([3 1]), fullData([3 1]));
        end

        function linearIndexIntoRowVectorDatasetKeepsRowShape(testCase)
        % A [1 N] dataset is the one place a scalar linear selection must
        % come back 1x1 via the row-vector branch of getExpectedSize.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            folderFixture = testCase.applyFixture(TemporaryFolderFixture);
            storePath = string(fullfile(folderFixture.Folder, "row.zarr"));

            % numpy-order shape [3 1] reverses to MatNWB dims [1 3].
            rowArray = zarr.create(storePath, [3 1], "double", Path="row");
            rowArray.write([7; 8; 9]);
            lazyArray = io.backend.zarr3.Zarr3LazyArray(storePath, "/row");

            testCase.verifyEqual(lazyArray.dims, [1 3]);
            testCase.verifyEqual(lazyArray.load_mat_style(2), 8);
        end

        function suppliedReferenceFieldsDecodeToObjectViews(testCase)
        % io.backend.zarr3.Zarr3Reader passes the reference field names to
        % the constructor so a compound load does not re-read them from the
        % array's attributes; the supplied names must drive the decoding.
            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                testCase.FixturePath, "/intervals/trials/timeseries", ...
                2, [], "timeseries");

            data = lazyArray.load_h5_style();

            testCase.verifyClass(data.timeseries, "types.untyped.ObjectView");
            testCase.verifySize(data.timeseries, [2 1]);
            testCase.verifyTrue(all(string({data.timeseries.path}) == ...
                "/acquisition/es"));
            testCase.verifyEqual(data.count, int32([10; 5]));
        end
    end
end
