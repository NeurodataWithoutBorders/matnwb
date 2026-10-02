classdef HDF5LazyArrayTest < matlab.unittest.TestCase

    properties (TestParameter)
        % Subscripts that select elements in a different order than the
        % file holds them, or select an element more than once.
        Subscript = struct( ...
            'unsorted', [3 1 2], ...
            'repeated', [2 2 3], ...
            'unsortedWithRepeats', [3 1 3])
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

        function reorderedFirstSubscriptBeforeColon(testCase, Subscript)
            data = reshape(1:(4*5), 4, 5);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(Subscript, ':'), data(Subscript, :));
        end

        function reorderedFirstSubscriptWithSortedSecond(testCase, Subscript)
            data = reshape(1:(4*5), 4, 5);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(Subscript, 1:3), data(Subscript, 1:3));
            testCase.verifyEqual(lazyArray.load_mat_style(Subscript, 2), data(Subscript, 2));
        end

        function reorderedLastSubscript(testCase, Subscript)
            data = reshape(1:(4*5), 4, 5);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(':', Subscript), data(:, Subscript));
            testCase.verifyEqual(lazyArray.load_mat_style(2:3, Subscript), data(2:3, Subscript));
        end

        function reorderedMiddleSubscriptOfVolume(testCase, Subscript)
            data = reshape(1:(4*5*3), 4, 5, 3);
            lazyArray = testCase.writeLazyArray(data);

            testCase.verifyEqual(lazyArray.load_mat_style(':', Subscript, ':'), data(:, Subscript, :));
            testCase.verifyEqual(lazyArray.load_mat_style(1:2, Subscript, 2), data(1:2, Subscript, 2));
            testCase.verifyEqual(lazyArray.load_mat_style(Subscript, Subscript, ':'), data(Subscript, Subscript, :));
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
    end
end
