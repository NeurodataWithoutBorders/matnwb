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
    end
end
