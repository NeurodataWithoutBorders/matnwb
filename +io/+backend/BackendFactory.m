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
                    % Zarr is tested first: isfile is true for some store
                    % URLs (a server may redirect the store folder to a
                    % listing), which would send them to H5F.open.
                    if io.backend.BackendFactory.isZarr3Store(filename)
                        reader = io.backend.zarr3.Zarr3Reader(filename);
                    elseif io.backend.BackendFactory.isHDF5File(filename)
                        reader = io.backend.hdf5.HDF5Reader(filename);
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
                case "zarr3"
                    if ~io.backend.BackendFactory.isZarr3Store(filename)
                        error("NWB:BackendFactory:InvalidZarr3", ...
                            "`%s` is not a Zarr v3 store (a local directory or an http(s) URL).", filename)
                    end
                    reader = io.backend.zarr3.Zarr3Reader(filename);
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
                    % Zarr is tested first, for the reason given in createReader.
                    if io.backend.BackendFactory.isZarr3Store(filename)
                        lazyArray = io.backend.zarr3.Zarr3LazyArray(filename, datasetPath, dims, dataType);
                    elseif io.backend.BackendFactory.isHDF5File(filename)
                        lazyArray = io.backend.hdf5.HDF5LazyArray(filename, datasetPath, dims, dataType);
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
                case "zarr3"
                    if ~io.backend.BackendFactory.isZarr3Store(filename)
                        error("NWB:BackendFactory:InvalidZarr3", ...
                            "`%s` is not a Zarr v3 store (a local directory or an http(s) URL).", filename)
                    end
                    lazyArray = io.backend.zarr3.Zarr3LazyArray(filename, datasetPath, dims, dataType);
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", storageBackend)
            end
        end

        function storageBackend = normalizeStorageBackend(storageBackend)
            storageBackend = lower(string(storageBackend));
            if storageBackend == "h5"
                storageBackend = "hdf5";
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

        function tf = isZarr3Store(filename)
        % isZarr3Store - True for a ".zarr" store whose root declares Zarr v3.
        %
        % The store is a local directory, or an http(s) URL whose root
        % metadata is fetched over HTTP.
            arguments
                filename (1,1) string
            end

            tf = false;
            if ~endsWith(filename, ".zarr", "IgnoreCase", true)
                return
            end

            try
                if matnwb.common.isUrl(filename)
                    rootMetadataText = webread(filename + "/zarr.json", ...
                        weboptions("ContentType", "text"));
                elseif isfolder(filename)
                    rootMetadataText = fileread(fullfile(filename, "zarr.json"));
                else
                    return
                end
                rootMetadata = jsondecode(rootMetadataText);
                tf = isfield(rootMetadata, "zarr_format") && isequal(rootMetadata.zarr_format, 3);
            catch
                % An unreadable or missing zarr.json, or one that is not
                % JSON, means this is not a Zarr v3 store.
                tf = false;
            end
        end
    end
end
