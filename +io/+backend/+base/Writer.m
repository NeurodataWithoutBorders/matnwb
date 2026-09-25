classdef Writer < handle
    % Writer - Base class for storage backend writers.
    %
    % This class defines the minimal write-side interface used by export
    % code. Concrete backends should override the methods below.

    properties (SetAccess = protected)
        Filename
    end

    properties (Access = private)
        % Maps the object id of each exported neurodata object to the file
        % location it was written to. Assigned in the constructor, not as a
        % property default, because a containers.Map default would be shared
        % by every Writer instance.
        ObjectIdToPathMap
    end

    methods
        function obj = Writer(filename)
            if nargin < 1
                filename = [];
            end
            obj.Filename = filename;
            obj.ObjectIdToPathMap = containers.Map();
        end

        function previousPath = registerWrittenObjectId(obj, objectId, fullPath)
        % registerWrittenObjectId - Record where an object id is written.
        %
        %   Returns the location this object id was previously written to,
        %   or '' when it has not been written before. A non-empty return
        %   value means the same object is being exported to a second
        %   location, which the caller must resolve: an object id is the
        %   identity of a neurodata object, so two objects sharing one id
        %   produce a file that other NWB APIs reject when reading it.
        %
        %   Re-registering the same location returns '' rather than
        %   reporting a duplicate. An object holding an ObjectView,
        %   RegionView or SoftLink that cannot be resolved yet is skipped
        %   during the main export and exported again by
        %   NwbFile.resolveReferences once its target exists — at the same
        %   location — so one location being registered twice is expected.

            arguments
                obj (1,1) io.backend.base.Writer
                objectId (1,:) char
                fullPath (1,:) char
            end

            previousPath = '';

            if isempty(fullPath)
                fullPath = '/'; % The root NwbFile is exported with an empty path
            end

            if isKey(obj.ObjectIdToPathMap, objectId)
                registeredPath = obj.ObjectIdToPathMap(objectId);
                if ~strcmp(registeredPath, fullPath)
                    previousPath = registeredPath;
                end
            else
                obj.ObjectIdToPathMap(objectId) = fullPath;
            end
        end

        function groupExists = writeGroup(obj, groupPath) %#ok<INUSD>
            groupExists = false;
            io.backend.base.Writer.throwNotImplemented("writeGroup")
        end

        function writeValue(obj, datasetPath, value, varargin) %#ok<INUSD>
            io.backend.base.Writer.throwNotImplemented("writeValue")
        end

        function writeAttribute(obj, attributePath, value, varargin) %#ok<INUSD>
            io.backend.base.Writer.throwNotImplemented("writeAttribute")
        end

        function copyDatasetFromFile(obj, sourceFilename, sourcePath, destinationPath) %#ok<INUSD>
        % copyDatasetFromFile - Copy a dataset from another file into this file.
        %
        % Copies the dataset at sourcePath inside the file sourceFilename,
        % together with its attributes, to destinationPath in the file this
        % writer targets. Used to carry data that is still stored in a
        % source file (types.untyped.DataStub) over to the file being
        % exported.
        %
        % The copy is skipped when the source and the destination are the
        % same store: a dataset re-exported to the file it came from is
        % already in place. It is also skipped when destinationPath is
        % already occupied, so that a second export pass over the same
        % object does not disturb data copied by the first (see
        % NwbFile.resolveReferences). Implementations may substitute an
        % element-wise rewrite for a raw copy when their storage layer
        % cannot copy the dataset faithfully; see the compound-reference
        % workaround in io.backend.hdf5.HDF5Writer.
        %
        % Input Arguments:
        %   obj - Writer instance targeting the destination file.
        %   sourceFilename - Name of the file holding the source dataset.
        %   sourcePath - Path of the dataset inside the source file.
        %   destinationPath - Path the dataset is copied to in this file.

            io.backend.base.Writer.throwNotImplemented("copyDatasetFromFile")
        end

        function writtenPipe = exportDataPipe(obj, dataPipe, destinationPath) %#ok<INUSD>
        % exportDataPipe - Write a DataPipe's dataset into this file.
        %
        % Writes the dataset held by dataPipe at destinationPath, honouring
        % the pipe's storage configuration (chunking, compression and the
        % other pipe properties). Returns the pipe state representing the
        % dataset as written; DataPipe.export stores it as the pipe's new
        % internal state, which is how an in-memory blueprint pipe becomes
        % bound to the dataset in this file. A pipe already bound to a
        % dataset in this file is left in place. A pipe bound to a dataset
        % in a different file holds only a reference to that data, not the
        % data itself, so exporting it raises an error
        % ('NWB:BoundPipe:CannotExportToNewFile').
        %
        % Input Arguments:
        %   obj - Writer instance targeting the destination file.
        %   dataPipe - types.untyped.DataPipe whose dataset is written.
        %   destinationPath - Path the dataset is written to in this file.
        %
        % Output Arguments:
        %   writtenPipe - Pipe object bound to the dataset as written.

            writtenPipe = [];
            io.backend.base.Writer.throwNotImplemented("exportDataPipe")
        end

        function writeSoftLink(obj, linkPath, targetPath) %#ok<INUSD>
            % writeSoftLink - Create a link to another location in this file.
            %
            % Creates a link at linkPath that resolves to targetPath within
            % the same file. Writing over an existing link with the same
            % target is a no-op; writing over one with a different target
            % replaces it, so that re-exporting an object whose link target
            % was not yet resolvable succeeds (see
            % NwbFile.resolveReferences).
            io.backend.base.Writer.throwNotImplemented("writeSoftLink")
        end

        function writeExternalLink(obj, linkPath, targetFilename, targetPath) %#ok<INUSD>
            % writeExternalLink - Create a link into a separate file.
            %
            % Creates a link at linkPath that resolves to targetPath inside
            % the file targetFilename. targetFilename is stored as given:
            % a relative path is recorded relative to this file, which is
            % how a linked pair of files stays movable together.
            io.backend.base.Writer.throwNotImplemented("writeExternalLink")
        end

        function validateReferenceResolvable(obj, referenceValue) %#ok<INUSD>
        % validateReferenceResolvable - Verify a reference target is resolvable.
        %
        % Probes whether the target of each ObjectView or RegionView in
        % referenceValue can be resolved in the file as written so far,
        % without writing anything. Returns silently when every target is
        % resolvable.
        %
        % Throws an error with identifier 'NWB:getRefData:InvalidPath'
        % when a target path does not (yet) exist in the file. Export
        % code treats that identifier, and 'NWB:ObjectView:MissingPath'
        % raised while resolving a view's own path, as "defer this object
        % to a second export pass once its target exists" (see
        % types.untyped.MetaClass.export and NwbFile.resolveReferences),
        % so implementations must let both propagate unchanged. For a
        % RegionView the probe must also verify that the referenced
        % dataset itself can be opened, not merely that its path exists.
        %
        % Input Arguments:
        %   obj - Writer instance used to probe the file written so far.
        %   referenceValue - Array of types.untyped.ObjectView or
        %       types.untyped.RegionView whose targets are probed.

            io.backend.base.Writer.throwNotImplemented("validateReferenceResolvable")
        end

        function specLocation = getEmbeddedSpecLocation(obj) %#ok<MANU>
            % getEmbeddedSpecLocation - Return the location of embedded schema
            % specifications, or '' if none are embedded yet. Mirrors
            % io.backend.base.Reader.getEmbeddedSpecLocation for the write
            % side (needed when editing a file that may already embed specs).
            specLocation = '';
            io.backend.base.Writer.throwNotImplemented("getEmbeddedSpecLocation")
        end

        function groupNames = listChildGroupNames(obj, groupPath) %#ok<INUSD>
            % listChildGroupNames - Return the names of immediate child
            % groups (not datasets) under groupPath.
            groupNames = {};
            io.backend.base.Writer.throwNotImplemented("listChildGroupNames")
        end

        function deleteGroup(obj, groupPath) %#ok<INUSD>
            % deleteGroup - Delete the group at groupPath and its contents.
            io.backend.base.Writer.throwNotImplemented("deleteGroup")
        end

        function close(obj) %#ok<MANU>
            % Default no-op. Concrete backends can override when they own
            % resources that should be released explicitly.
        end

        function abort(obj)
            obj.close();
        end
    end

    methods (Static)
        function writer = ensure(writerOrFileReference)
            if isa(writerOrFileReference, "io.backend.base.Writer")
                writer = writerOrFileReference;
                return
            end

            writer = io.backend.BackendFactory.createWriter(writerOrFileReference);
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:Writer:NotImplemented", ...
                "Writer method `%s` is not implemented.", methodName)
        end
    end
end
