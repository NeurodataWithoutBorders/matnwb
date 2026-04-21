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

            % Verify both "auto" and "h5" creates a valid reader
            reader = io.backend.BackendFactory.createReader(filename, ...
                StorageBackend="auto");
            testCase.verifyClass(reader, "io.backend.hdf5.HDF5Reader");

            reader = io.backend.BackendFactory.createReader(filename, ...
                StorageBackend="h5");
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
                @() io.backend.BackendFactory.createReader(filename, StorageBackend="zarr"), ...
                "NWB:BackendFactory:UnsupportedBackend");

            zarrFilepath = 'test.zarr.nwb';
            mkdir(zarrFilepath)
               
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(zarrFilepath, StorageBackend="auto"), ...
                "NWB:BackendFactory:UnsupportedFormat");
        end

        function verifyInvalidHDF5FileThrowsError(testCase)
            zarrFilepath = 'test.zarr.nwb';
            mkdir(zarrFilepath)
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(zarrFilepath, StorageBackend="hdf5"), ...
                "NWB:BackendFactory:InvalidHDF5");
        end

        function createHDF5WriterWithStorageBackendOption(testCase)
            filename = "factory-writer-test.nwb";

            writer = io.backend.BackendFactory.createWriter(filename, ...
                Mode="overwrite", StorageBackend="h5");

            testCase.verifyClass(writer, "io.backend.hdf5.HDF5Writer");
            writer.close()
            testCase.verifyTrue(isfile(filename))
        end
    end
end
