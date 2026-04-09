classdef BackendFactory
    % BackendFactory - Factory for creating storage backend components.

    methods (Static)
        function reader = createReader(filename, backendName)
            arguments
                filename (1,1) string
                backendName (1,1) string = "auto"
            end

            backendName = io.backend.BackendFactory.normalizeBackendName(backendName);

            switch backendName
                case "auto"
                    if io.backend.BackendFactory.isHDF5File(filename)
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
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", backendName)
            end
        end

        function lazyArray = createLazyArray(filename, datasetPath, dims, dataType, backendName)
            arguments
                filename (1,1) string
                datasetPath (1,1) string
                dims double = []
                dataType = []
                backendName (1,1) string = "auto"
            end

            backendName = io.backend.BackendFactory.normalizeBackendName(backendName);

            switch backendName
                case "auto"
                    if io.backend.BackendFactory.isHDF5File(filename)
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
                otherwise
                    error("NWB:BackendFactory:UnsupportedBackend", ...
                        "Unsupported backend `%s`.", backendName)
            end
        end

        function backendName = normalizeBackendName(backendName)
            backendName = lower(string(backendName));
            if backendName == "h5"
                backendName = "hdf5";
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
    end
end
