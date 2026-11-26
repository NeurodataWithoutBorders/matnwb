classdef BackendFactory
    % BackendFactory - Factory for creating storage backend components.
    %
    % A reader or lazy array is created by the backend that can open the
    % file. With StorageBackend "auto", the backends are asked in the order
    % listBackends gives, and the first that can open the file is used.

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

            backend = io.backend.BackendFactory.resolveBackend(filename, options.StorageBackend);
            reader = backend.CreateReader(filename);
        end

        function lazyArray = createLazyArray(filename, datasetPath, dims, dataType, options)
            arguments
                filename (1,1) string
                datasetPath (1,1) string
                dims double = []
                dataType = []
                options.StorageBackend (1,1) string = "auto"
            end

            backend = io.backend.BackendFactory.resolveBackend(filename, options.StorageBackend);
            lazyArray = backend.CreateLazyArray(filename, datasetPath, dims, dataType);
        end

        function storageBackend = normalizeStorageBackend(storageBackend)
            storageBackend = lower(string(storageBackend));
            if storageBackend == "h5"
                storageBackend = "hdf5";
            end
        end
    end

    methods (Static, Access = private)
        function backends = listBackends()
        % listBackends - Storage backends available for reading, in the
        % order StorageBackend "auto" tries them.
        %
        % Each backend is described by:
        %  - Name - Value of the StorageBackend option that selects it.
        %  - Label - Format name used in error identifiers and messages.
        %  - CanOpen - Function that reports whether the backend can open
        %    a file, without reading more than it needs to decide.
        %  - CreateReader - Constructor of the backend's reader.
        %  - CreateLazyArray - Constructor of the backend's lazy array.
            hdf5 = struct( ...
                'Name', "hdf5", ...
                'Label', "HDF5", ...
                'CanOpen', @io.backend.hdf5.HDF5Reader.canOpen, ...
                'CreateReader', @io.backend.hdf5.HDF5Reader, ...
                'CreateLazyArray', @io.backend.hdf5.HDF5LazyArray);
            backends = hdf5;
        end

        function backend = resolveBackend(filename, storageBackend)
        % resolveBackend - Backend that opens filename for a StorageBackend value.
        %
        % With "auto", the first backend that can open the file is used.
        % A named backend is used only if it can open the file.
            storageBackend = io.backend.BackendFactory.normalizeStorageBackend(storageBackend);
            backends = io.backend.BackendFactory.listBackends();

            if storageBackend == "auto"
                for iBackend = 1:numel(backends)
                    if backends(iBackend).CanOpen(filename)
                        backend = backends(iBackend);
                        return
                    end
                end
                error("NWB:BackendFactory:UnsupportedFormat", ...
                    "No supported storage backend found for `%s`.", filename)
            end

            isSelected = [backends.Name] == storageBackend;
            if ~any(isSelected)
                error("NWB:BackendFactory:UnsupportedBackend", ...
                    "Unsupported backend `%s`.", storageBackend)
            end
            backend = backends(isSelected);
            if ~backend.CanOpen(filename)
                error("NWB:BackendFactory:Invalid" + backend.Label, ...
                    "`%s` cannot be opened by the `%s` storage backend.", ...
                    filename, backend.Name)
            end
        end
    end
end
