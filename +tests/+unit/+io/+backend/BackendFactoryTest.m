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

        function createHDF5LazyArrayForH5File(testCase)
            filename = "factory-lazy-array-test.h5";
            h5create(filename, "/data", [4, 3, 2]);
            h5write(filename, "/data", reshape(1:24, [4, 3, 2]));

            lazyArray = io.backend.BackendFactory.createLazyArray(filename, "/data");

            testCase.verifyClass(lazyArray, "io.backend.hdf5.HDF5LazyArray");
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
