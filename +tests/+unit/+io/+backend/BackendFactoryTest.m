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

        function createZarrReaderForZarrDirectory(testCase)
            wrapperPath = "/Users/eivind/Code/MATLAB/General/Repositories/mathworks/MATLAB-support-for-Zarr-files";
            fixturePath = "/Users/eivind/Code/MATLAB/Sandbox/CN/zarr_matlab/test_data/test_zarr_sub_anm00239123_ses_20170627T093549_ecephys_and_ogen.nwb.zarr";

            testCase.assumeTrue(isfolder(wrapperPath) && isfolder(fixturePath));
            addpath(wrapperPath)
            testCase.addTeardown(@() rmpath(wrapperPath))

            reader = io.backend.BackendFactory.createReader(fixturePath);

            testCase.verifyClass(reader, "io.backend.zarr2.Zarr2Reader");
        end

        function unsupportedBackendThrowsError(testCase)
            nwb = tests.factory.NWBFile();
            filename = "factory-test.nwb";
            nwbExport(nwb, filename);

            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(filename, "zarr"), ...
                "NWB:BackendFactory:InvalidZarr");
        end
    end
end
