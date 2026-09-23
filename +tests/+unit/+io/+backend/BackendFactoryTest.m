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

            lazyArray = io.backend.BackendFactory.createLazyArray(filename, "/data", ...
                StorageBackend="hdf5");
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

        function createWriterDefaultsToHDF5ForAutoBackend(testCase)
            filename = "factory-writer-auto-test.nwb";

            writer = io.backend.BackendFactory.createWriter(filename, ...
                Mode="overwrite", StorageBackend="auto");

            testCase.verifyClass(writer, "io.backend.hdf5.HDF5Writer");
            writer.close()
        end

        function createWriterRejectsUnsupportedBackend(testCase)
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createWriter("factory-writer-test.nwb", ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:UnsupportedBackend");
        end

        function createZarr3ReaderForZarrStore(testCase)
        % Backend detection only reads the root zarr.json, and the reader
        % constructor opens nothing, so a minimal handwritten store is
        % enough -- no zarr-matlab dependency needed here.
            storePath = testCase.createValidZarr3Store("valid.zarr");

            reader = io.backend.BackendFactory.createReader(storePath, ...
                StorageBackend="zarr3");
            testCase.verifyClass(reader, "io.backend.zarr3.Zarr3Reader");
        end

        function createZarr3ReaderRejectsNonZarrTarget(testCase)
            nwb = tests.factory.NWBFile();
            filename = "factory-test.nwb";
            nwbExport(nwb, filename);

            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(filename, ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:InvalidZarr3");
        end

        function createLazyArrayForZarrStore(testCase)
            storePath = testCase.createValidZarr3Store("valid.zarr");

            % Both auto-detection and an explicit backend name must work.
            lazyArray = io.backend.BackendFactory.createLazyArray(storePath, "/data");
            testCase.verifyClass(lazyArray, "io.backend.zarr3.Zarr3LazyArray");

            lazyArray = io.backend.BackendFactory.createLazyArray(storePath, "/data", ...
                StorageBackend="zarr3");
            testCase.verifyClass(lazyArray, "io.backend.zarr3.Zarr3LazyArray");
        end

        function createLazyArrayRejectsInvalidTargets(testCase)
            filename = "factory-lazy-array-test.h5";
            h5create(filename, "/data", [4, 3]);

            % An HDF5 file is not a Zarr store, and vice versa.
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createLazyArray(filename, "/data", ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:InvalidZarr3");

            zarrFilepath = 'test.zarr.nwb';
            mkdir(zarrFilepath)
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createLazyArray(zarrFilepath, "/data", ...
                    StorageBackend="hdf5"), ...
                "NWB:BackendFactory:InvalidHDF5");

            % Auto-detection finds no backend for a path that is neither.
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createLazyArray("missing.zarr", "/data", ...
                    StorageBackend="auto"), ...
                "NWB:BackendFactory:UnsupportedFormat");

            testCase.verifyError( ...
                @() io.backend.BackendFactory.createLazyArray(filename, "/data", ...
                    StorageBackend="hdf4"), ...
                "NWB:BackendFactory:UnsupportedBackend");
        end

        function zarr3DetectionRejectsMalformedStores(testCase)
        % Each store fails a different check in isZarr3Directory: a path
        % that is not a folder, a .zarr folder without root metadata, and
        % root metadata that is not valid JSON.
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader("missing.zarr", ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:InvalidZarr3");

            noMetadataStore = "no-metadata.zarr";
            mkdir(noMetadataStore)
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(noMetadataStore, ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:InvalidZarr3");

            malformedStore = "malformed.zarr";
            mkdir(malformedStore)
            tests.unit.io.backend.BackendFactoryTest.writeTextFile(...
                fullfile(malformedStore, "zarr.json"), "{not valid json");
            testCase.verifyError( ...
                @() io.backend.BackendFactory.createReader(malformedStore, ...
                    StorageBackend="zarr3"), ...
                "NWB:BackendFactory:InvalidZarr3");
        end
    end

    methods (Access = private)
        function storePath = createValidZarr3Store(~, storeName)
        % createValidZarr3Store - A folder holding only Zarr v3 root metadata.
            storePath = string(fullfile(pwd, storeName));
            mkdir(storePath)
            rootMetadata = struct('zarr_format', 3, 'node_type', 'group');
            tests.unit.io.backend.BackendFactoryTest.writeTextFile(...
                fullfile(storePath, "zarr.json"), jsonencode(rootMetadata));
        end
    end

    methods (Static, Access = private)
        function writeTextFile(filename, text)
            fileId = fopen(filename, "w");
            fprintf(fileId, "%s", text);
            fclose(fileId);
        end
    end
end
