classdef BackendFactory
    % BackendFactory - Factory for creating storage backend components.

    methods (Static)
        function writer = createWriter(fileReference, options)

            arguments
                fileReference
                options.Mode (1,1) string {mustBeMember(options.Mode, ["edit", "overwrite"])} = "edit"
                options.StorageBackend (1,1) string = "hdf5"
            end

            storageBackend = io.backend.BackendFactory.normalizeStorageBackend(options.StorageBackend);

            switch storageBackend
                case "auto"
                    writer = io.backend.hdf5.HDF5Writer(fileReference, options.Mode);
                case "hdf5"
                    writer = io.backend.hdf5.HDF5Writer(fileReference, options.Mode);
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", storageBackend)
            end
        end

        function reader = createReader(filename, options)
            arguments
                filename (1,1) string
                options.StorageBackend (1,1) string = "auto"
            end

            storageBackend = io.backend.BackendFactory.normalizeStorageBackend(options.StorageBackend);

            switch storageBackend
                case "auto"
                    if io.backend.BackendFactory.isHDF5File(filename)
                        reader = io.backend.hdf5.HDF5Reader(filename);
                    elseif io.backend.BackendFactory.isZarrDirectory(filename)
                        reader = io.backend.zarr2.Zarr2Reader(filename);
                    else
                        error("NWB:BackendFactory:UnsupportedFormat", ...
                            "No supported reader found for `%s`.", filename)
                    end
                case "hdf5"
                    if ~io.backend.BackendFactory.isHDF5File(filename)
                        error("NWB:BackendFactory:InvalidHDF5", ...
                            "`%s` is not a valid HDF5 file.", filename)
                    end
                    reader = io.backend.hdf5.HDF5Reader(filename);
                case "zarr"
                    if ~io.backend.BackendFactory.isZarrDirectory(filename)
                        error("NWB:BackendFactory:InvalidZarr", ...
                            "`%s` is not a supported local Zarr directory store.", filename)
                    end
                    reader = io.backend.zarr2.Zarr2Reader(filename);
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", storageBackend)
            end
        end

        function lazyArray = createLazyArray(filename, datasetPath, dims, dataType, options)
            arguments
                filename (1,1) string
                datasetPath (1,1) string
                dims double = []
                dataType = []
                options.StorageBackend (1,1) string = "auto"
            end

            storageBackend = io.backend.BackendFactory.normalizeStorageBackend(options.StorageBackend);

            switch storageBackend
                case "auto"
                    if io.backend.BackendFactory.isHDF5File(filename)
                        lazyArray = io.backend.hdf5.HDF5LazyArray(filename, datasetPath, dims, dataType);
                    elseif io.backend.BackendFactory.isZarrDirectory(filename)
                        lazyArray = io.backend.zarr2.Zarr2LazyArray(filename, datasetPath, dims, dataType);
                    else
                        error("NWB:BackendFactory:UnsupportedFormat", ...
                            "No supported lazy array backend found for `%s`.", filename)
                    end
                case "hdf5"
                    if ~io.backend.BackendFactory.isHDF5File(filename)
                        error("NWB:BackendFactory:InvalidHDF5", ...
                            "`%s` is not a valid HDF5 file.", filename)
                    end
                    lazyArray = io.backend.hdf5.HDF5LazyArray(filename, datasetPath, dims, dataType);
                case "zarr"
                    if ~io.backend.BackendFactory.isZarrDirectory(filename)
                        error("NWB:BackendFactory:InvalidZarr", ...
                            "`%s` is not a supported local Zarr directory store.", filename)
                    end
                    lazyArray = io.backend.zarr2.Zarr2LazyArray(filename, datasetPath, dims, dataType);
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", storageBackend)
            end
        end

        function storageBackend = normalizeStorageBackend(storageBackend)
            storageBackend = lower(string(storageBackend));
            if storageBackend == "h5"
                storageBackend = "hdf5";
            elseif storageBackend == "zarr2"
                storageBackend = "zarr";
            end
        end

        function tf = isHDF5File(filename)
            arguments
                filename (1,1) string
            end

            tf = false;
            if isfile(filename)
                try
                    fid = H5F.open(filename, "H5F_ACC_RDONLY", "H5P_DEFAULT");
                    H5F.close(fid);
                    tf = true;
                catch
                    tf = false;
                end
            end
        end

        function tf = isZarrDirectory(filename)
            arguments
                filename (1,1) string
            end

            tf = false;
            if startsWith(filename, "s3://", "IgnoreCase", true) || ~isfolder(filename)
                return
            end

            if ~endsWith(filename, ".zarr", "IgnoreCase", true)
                return
            end

            tf = isfile(fullfile(filename, ".zgroup")) ...
                || isfile(fullfile(filename, ".zmetadata"));
        end
    end
end
