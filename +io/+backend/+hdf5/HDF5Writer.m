classdef HDF5Writer < io.backend.base.Writer
    % HDF5Writer - HDF5 implementation of the backend writer interface.
    %
    % This writer is intentionally thin and delegates to the existing HDF5
    % utility functions used by matnwb today.

    properties (SetAccess = private, Hidden)
        H5FileId
    end

    properties
        % Flag used to clean up if something goes wrong.
        IsEditingFile (1,1) logical = false
        OwnsFileHandle (1,1) logical = true
    end

    methods
        function obj = HDF5Writer(fileReference, mode)
            arguments
                fileReference
                mode (1,1) string {mustBeMember(mode, ["edit", "overwrite"])} = "edit"
            end
            if isa(fileReference, 'H5ML.id')
                filename = string(H5F.get_name(fileReference));
            else
                filename = string(fileReference);
            end

            obj@io.backend.base.Writer(filename);

            if isa(fileReference, 'H5ML.id')
                obj.H5FileId = fileReference;
                obj.OwnsFileHandle = false;
            else
                if isfile(obj.Filename)
                    if mode == "edit"
                        obj.H5FileId = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                        obj.IsEditingFile = true;
                    elseif mode == "overwrite"
                        obj.H5FileId = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
                    end
                else
                    obj.H5FileId = H5F.create(filename);
                end
            end
        end
    
        function delete(obj)
            obj.close();
        end
    end
    
    methods
        function close(obj)
            if obj.OwnsFileHandle && ~isempty(obj.H5FileId) && isvalid(obj.H5FileId)
                H5F.close(obj.H5FileId);
            end
            obj.H5FileId = [];
        end

        function abort(obj)
            filePath = char(obj.Filename);
            shouldDeleteFile = obj.OwnsFileHandle && ~obj.IsEditingFile && isfile(filePath);
            obj.close();
            if shouldDeleteFile
                delete(filePath);
            end
        end

        function groupExists = writeGroup(obj, groupPath)
            groupExists = io.writeGroup(obj.H5FileId, groupPath);
        end

        function writeValue(obj, datasetPath, value, varargin)
            if istable(value) || isstruct(value) || isa(value, "containers.Map")
                io.writeCompound(obj.H5FileId, datasetPath, value, varargin{:});
            else
                io.writeDataset(obj.H5FileId, datasetPath, value, varargin{:});
            end
        end

        function writeAttribute(obj, attributePath, value, varargin)
            io.writeAttribute(obj.H5FileId, attributePath, value, varargin{:});
        end

        function copyDatasetFromFile(obj, sourceFilename, sourcePath, destinationPath)
            % Compare canonical names as reported by the HDF5 library, not
            % the caller-supplied strings: two spellings of one path (e.g.
            % relative vs absolute) must count as the same file, otherwise
            % a dataset would be copied onto itself.
            src_fid = H5F.open(sourceFilename);
            src_filename = H5F.get_name(src_fid);
            dest_filename = H5F.get_name(obj.H5FileId);
            if strcmp(src_filename, dest_filename)
                H5F.close(src_fid);
                return
            end

            src_did = H5D.open(src_fid, sourcePath);
            src_tid = H5D.get_type(src_did);

            % Check for compound data type refs
            if H5T.get_class(src_tid) == H5ML.get_constant_value('H5T_COMPOUND')
                isCompoundDatasetWithReference = isCompoundWithReference(src_tid);
            else
                isCompoundDatasetWithReference = false;
            end

            % If dataset is compound and contains reference types, data needs
            % to be manually read and written to the new file. This is due to
            % a bug in the hdf5 library
            % (see e.g. https://github.com/HDFGroup/hdf5/issues/3429)
            if isCompoundDatasetWithReference
                % This requires loading the entire table.
                % Due to this HDF5 library's inability to delete/update
                % dataset data, this is unfortunately required.
                data = H5D.read(src_did);

                % Use io.parseCompound to consistently handle references,
                % character arrays, and logical types, ensuring all data types
                % are properly postprocessed in line with the rest of the
                % codebase.
                data = io.parseCompound(src_did, data);
                obj.writeValue(destinationPath, data);

            elseif ~H5L.exists(obj.H5FileId, destinationPath, 'H5P_DEFAULT')
                % copy data over and return destination.
                ocpl = H5P.create('H5P_OBJECT_COPY');
                lcpl = H5P.create('H5P_LINK_CREATE');
                H5O.copy(src_fid, sourcePath, obj.H5FileId, destinationPath, ocpl, lcpl);
                H5P.close(ocpl);
                H5P.close(lcpl);
            end
            H5T.close(src_tid);
            H5D.close(src_did);
            H5F.close(src_fid);
        end

        function writeSoftLink(obj, linkPath, targetPath)
            io.internal.h5.writeLink(obj.H5FileId, linkPath, "soft", targetPath);
        end

        function writeExternalLink(obj, linkPath, targetFilename, targetPath)
            io.internal.h5.writeLink(...
                obj.H5FileId, linkPath, "external", targetPath, targetFilename);
        end

        function validateReferenceResolvable(obj, referenceValue)
            % io.getRefData creates the reference bytes as a side effect
            % of probing; the result is discarded because the actual
            % reference data is written later through writeValue. Reusing
            % it keeps this probe and the eventual write agreeing on what
            % "resolvable" means: it opens a RegionView's dataset rather
            % than only checking that the target path exists.
            io.getRefData(obj.H5FileId, referenceValue);
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            specLocation = io.spec.internal.readEmbeddedSpecLocation(obj.H5FileId);
        end

        function groupNames = listChildGroupNames(obj, groupPath)
            groupNames = io.internal.h5.listGroupNames(obj.H5FileId, groupPath);
        end

        function deleteGroup(obj, groupPath)
            io.internal.h5.deleteGroup(obj.H5FileId, groupPath);
        end
    end

    methods (Access = protected)
        function fileId = getFileId(obj)
            fileId = obj.H5FileId;
        end
    end
end

function hasReference = isCompoundWithReference(src_tid)
    hasReference = false;

    ncol = H5T.get_nmembers(src_tid);
    refTypeConst = H5ML.get_constant_value('H5T_REFERENCE');

    for i = 1:ncol
        subclass = H5T.get_member_class(src_tid, i-1);
        if subclass == refTypeConst
            hasReference = true;
            return
        end
    end
end
