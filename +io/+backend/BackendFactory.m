classdef BackendFactory < handle
    % BackendFactory - Factory class for creating file format backends
    %
    % This factory class determines the file format and creates the appropriate
    % backend for reading NWB files from different storage formats.
    
    methods (Static)
        function backend = createBackend(filename)
            % Create appropriate backend based on file format
            %
            % Input:
            %   filename - Path to the file
            %
            % Output:
            %   backend - Backend instance (HDF5Backend, ZarrBackend, etc.)
            
            arguments
                filename (1,1) string
            end
            
            % Ensure file exists
            if ~isfile(filename) && ~isfolder(filename)
                error('NWB:BackendFactory:FileNotFound', ...
                    'File or directory not found: %s', filename);
            end
            
            % Determine file format based on extension and content
            [~, ~, ext] = fileparts(filename);
            
            switch lower(ext)
                case {'.h5', '.hdf5', '.nwb'}
                    % Check if it's actually an HDF5 file
                    if io.backend.BackendFactory.isHDF5File(filename)
                        backend = io.backend.HDF5Backend(filename);
                    else
                        error('NWB:BackendFactory:InvalidHDF5', ...
                            'File has HDF5 extension but is not a valid HDF5 file: %s', filename);
                    end
                    
                case '.zarr'
                    % Zarr format (directory-based)
                    if isfolder(filename)
                        backend = io.backend.ZarrBackend(filename);
                    else
                        error('NWB:BackendFactory:InvalidZarr', ...
                            'Zarr files should be directories: %s', filename);
                    end
                    
                otherwise
                    % Try to detect format by content
                    if isfile(filename) && io.backend.BackendFactory.isHDF5File(filename)
                        backend = io.backend.HDF5Backend(filename);
                    elseif isfolder(filename) && io.backend.BackendFactory.isZarrDirectory(filename)
                        backend = io.backend.ZarrBackend(filename);
                    else
                        error('NWB:BackendFactory:UnsupportedFormat', ...
                            'Unsupported file format: %s', filename);
                    end
            end
        end
        
        function tf = isHDF5File(filename)
            % Check if file is a valid HDF5 file
            %
            % Input:
            %   filename - Path to the file
            %
            % Output:
            %   tf - True if file is HDF5, false otherwise
            
            arguments
                filename (1,1) string
            end
            
            tf = false;
            
            if ~isfile(filename)
                return;
            end
            
            try
                % Try to open as HDF5 file
                fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                H5F.close(fid);
                tf = true;
            catch
                % If opening fails, it's not a valid HDF5 file
                tf = false;
            end
        end
        
        function tf = isZarrDirectory(dirname)
            % Check if directory is a valid Zarr store
            %
            % Input:
            %   dirname - Path to the directory
            %
            % Output:
            %   tf - True if directory is Zarr store, false otherwise
            
            arguments
                dirname (1,1) string
            end
            
            tf = false;
            
            if ~isfolder(dirname)
                return;
            end
            
            % Check for Zarr metadata files
            zarrMetaFile = fullfile(dirname, '.zarray');
            zarrGroupFile = fullfile(dirname, '.zgroup');
            
            % A Zarr store should have either .zarray (for arrays) or .zgroup (for groups)
            tf = isfile(zarrMetaFile) || isfile(zarrGroupFile);
        end

        function supportedFormats = getSupportedFormats()
            % Get list of supported file formats
            %
            % Output:
            %   supportedFormats - Cell array of supported format descriptions
            
            supportedFormats = {
                'HDF5 (.h5, .hdf5, .nwb) - Hierarchical Data Format 5'
                'Zarr (.zarr) - Cloud-optimized chunked array storage'
            };
        end
        
        function printSupportedFormats()
            % Print supported file formats to console
            
            formats = io.backend.BackendFactory.getSupportedFormats();
            
            fprintf('Supported NWB file formats:\n');
            for i = 1:length(formats)
                fprintf('  %d. %s\n', i, formats{i});
            end
        end
    end
end
