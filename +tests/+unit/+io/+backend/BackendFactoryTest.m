classdef BackendFactoryTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function createHDF5ReaderForNwbFile(testCase)
            nwb = tests.factory.NWBFile();
            filename = "factory-test.nwb";
            nwbExport(nwb, filename);

            reader = io.backend.BackendFactory.createReader(filename);

            testCase.verifyClass(reader, "io.backend.hdf5.HDF5Reader");
        end

        function unsupportedBackendThrowsError(testCase)
            nwb = tests.factory.NWBFile();
            filename = "factory-test.nwb";
            nwbExport(nwb, filename);

            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(filename, "zarr"), ...
                "NWB:BackendFactory:UnsupportedBackend");
        end
    end
end
