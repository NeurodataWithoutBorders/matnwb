classdef HDF5LazyArrayTest < matlab.unittest.TestCase

    properties (TestParameter)
        % Selections along the second dimension of a 20-column dataset:
        % runs with gaps, isolated indices, and unsorted indices with repeats.
        ColumnSelection = struct( ...
            'runsAndPoints', [2:4, 7, 9:10, 15:17], ...
            'isolated', [1 4 6 11 13 20], ...
            'stride', 1:3:20, ...
            'unsortedWithRepeats', [10 2 2 7])
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function loadDataAndMetadata(testCase)
            filename = "lazy-array-test.h5";
            data = reshape(1:24, [4, 3, 2]);
            h5create(filename, "/data", size(data));
            h5write(filename, "/data", data);

            lazyArray = io.backend.hdf5.HDF5LazyArray(filename, "/data");

            testCase.verifyEqual(lazyArray.dims, size(data));
            testCase.verifyEqual(lazyArray.maxDims, size(data));
            testCase.verifyEqual(lazyArray.dataType, 'double');
            testCase.verifyEqual(lazyArray.load_h5_style(), data);
            testCase.verifyEqual(lazyArray.load_mat_style(1:2, 2, ':'), data(1:2, 2, :));
        end

        function gappedSelectionOfMatrixMatchesIndexing(testCase, ColumnSelection)
            data = reshape(1:(6*20), 6, 20);
            lazyArray = testCase.writeLazyArray(data);
            rows = [1, 3:4, 6];

            testCase.verifyEqual(lazyArray.load_mat_style(':', ColumnSelection), data(:, ColumnSelection));
            testCase.verifyEqual(lazyArray.load_mat_style(rows, ColumnSelection), data(rows, ColumnSelection));
        end

        function gappedSelectionOfRowsMatchesIndexing(testCase)
            data = reshape(1:(20*3), 20, 3);
            lazyArray = testCase.writeLazyArray(data);
            rows = [2:4, 7, 9:10, 15:17];

            testCase.verifyEqual(lazyArray.load_mat_style(rows, ':'), data(rows, :));
            testCase.verifyEqual(lazyArray.load_mat_style(rows, 2), data(rows, 2));
        end

        function gappedSelectionOfVolumeMatchesIndexing(testCase, ColumnSelection)
            data = reshape(1:(4*5*20), 4, 5, 20);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(':', ':', ColumnSelection), data(:, :, ColumnSelection));
            testCase.verifyEqual(lazyArray.load_mat_style(2:3, [1 3 5], ColumnSelection), ...
                data(2:3, [1 3 5], ColumnSelection));
        end

        function gappedSelectionOfColumnVectorMatchesIndexing(testCase, ColumnSelection)
            data = (1:20)';
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(ColumnSelection), data(ColumnSelection));
        end

        function selectionWithManyRunsIsReadInGroups(testCase)
            % More runs than fit in one read selection, so the read is split
            % into groups along the selected dimension and joined again.
            maxHyperslabs = io.backend.hdf5.HDF5LazyArray.MaxHyperslabsPerRead;
            numRuns = 2*maxHyperslabs + 1;
            % Runs of 1 to 3 indices with gaps of 1 or 2 between them.
            runLengths = repmat([1 2 3], 1, ceil(numRuns/3));
            runLengths = runLengths(1:numRuns);
            gaps = repmat([1 2], 1, ceil(numRuns/2));
            runStarts = cumsum(gaps(1:numRuns) + [0, runLengths(1:end-1)]);
            columns = arrayfun(@(s, l) s:(s + l - 1), runStarts, runLengths, 'UniformOutput', false);
            columns = [columns{:}];

            data = reshape(1:(3*(columns(end) + 1)*2), 3, columns(end) + 1, 2);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(':', columns, ':'), data(:, columns, :));
            testCase.verifyEqual(lazyArray.load_mat_style([1 3], columns, 2), data([1 3], columns, 2));
            testCase.verifyEqual(lazyArray.load_mat_style(':', fliplr(columns), 1), data(:, fliplr(columns), 1));
            repeated = [columns(1:5), columns(1:5)];
            testCase.verifyEqual(lazyArray.load_mat_style(':', [columns, repeated], ':'), ...
                data(:, [columns, repeated], :));
        end

        function loadSelectionsReadsHyperslabsInOneCall(testCase)
            % One contiguous range or ':' per dimension of a numeric dataset.
            selections = {{':', ':', 2:3}, {1:2, 4, ':'}, {':', ':', 6}};
            lazyArray = testCase.createSpy();

            actual = lazyArray.loadSelections(selections);

            testCase.verifyEqual(lazyArray.LoadCount, 1, ...
                'Expected hyperslab selections to be read without load_mat_style.');
            testCase.verifySelectionsMatchLoadMatStyle(lazyArray, selections, actual)
        end

        function loadSelectionsReadsOtherSelectionsWithLoadMatStyle(testCase)
            % Indices with gaps, a linear index, and fewer subscripts than dimensions.
            selections = {{':', [1 3], 2}, {5:7}, {':', 2:4}};
            lazyArray = testCase.createSpy();

            actual = lazyArray.loadSelections(selections);

            testCase.verifyEqual(lazyArray.LoadCount, 1 + numel(selections), ...
                'Expected each selection to be read with load_mat_style.');
            testCase.verifySelectionsMatchLoadMatStyle(lazyArray, selections, actual)
        end
    end

    methods (Access = private)
        function lazyArray = writeLazyArray(~, data)
            % writeLazyArray - Write data to a dataset in a new file and return a lazy array for it.
            filename = [tempname(pwd), '.h5'];
            h5create(filename, "/data", size(data));
            h5write(filename, "/data", data);
            lazyArray = io.backend.hdf5.HDF5LazyArray(filename, "/data");
        end

        function lazyArray = createSpy(~)
            filename = "lazy-array-selections.h5";
            data = reshape(1:120, [4, 5, 6]);
            h5create(filename, "/data", size(data));
            h5write(filename, "/data", data);
            lazyArray = tests.unit.io.backend.doubles.HDF5LazyArraySpy(filename, "/data");
        end

        function verifySelectionsMatchLoadMatStyle(testCase, lazyArray, selections, actual)
            testCase.verifySize(actual, size(selections));
            for iSelection = 1:numel(selections)
                expected = lazyArray.load_mat_style(selections{iSelection}{:});
                testCase.verifyEqual(actual{iSelection}, expected, ...
                    sprintf('Selection %d differs from load_mat_style.', iSelection));
            end
        end
    end
end
