classdef HDF5WriterTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function deleteGroupDeletesPopulatedGroup(testCase)
            writer = io.backend.hdf5.HDF5Writer("writer-test.nwb", "overwrite");
            testCase.addTeardown(@() writer.close());
            writer.writeGroup('/specifications/core');
            writer.writeValue('/specifications/core/namespace', 'schema');

            writer.deleteGroup('/specifications/core');

            groupExists = H5L.exists(writer.FileId, ...
                '/specifications/core', 'H5P_DEFAULT');
            testCase.verifyFalse(logical(groupExists));
        end
    end
end
