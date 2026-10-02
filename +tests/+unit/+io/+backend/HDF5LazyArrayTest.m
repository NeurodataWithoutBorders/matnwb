classdef HDF5LazyArrayTest < matlab.unittest.TestCase

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

        function loadMatStyleReadsOneDimensionalSelections(testCase)
            % A selection that is one contiguous run is read as a hyperslab
            % and any other selection as points. Both return the elements
            % in the order they were asked for.
            filename = "lazy-array-1d.h5";
            data = (101:120)';
            h5create(filename, "/data", numel(data));
            h5write(filename, "/data", data);
            lazyArray = io.backend.hdf5.HDF5LazyArray(filename, "/data");

            selections = {5:9, (9:-1:5)', [3 3 4], 1:20, 20, uint64(5:9), [2 5 9]};
            for iSelection = 1:numel(selections)
                selection = selections{iSelection};
                testCase.verifyEqual(lazyArray.load_mat_style(selection), data(selection), ...
                    sprintf('Unexpected data for selection %s.', mat2str(selection)));
            end
        end
    end
end
