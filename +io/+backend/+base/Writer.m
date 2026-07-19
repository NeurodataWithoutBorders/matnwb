classdef Writer < handle
    % Writer - Base class for storage backend writers.
    %
    % This class defines the minimal write-side interface used by export
    % code. Concrete backends should override the methods below.

    properties (SetAccess = protected)
        Filename
    end

    properties (Dependent, SetAccess = private, Hidden)
        FileId
    end

    methods
        function obj = Writer(filename)
            if nargin < 1
                filename = [];
            end
            obj.Filename = filename;
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

        function fileId = get.FileId(obj)
            fileId = obj.getFileId();
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

    methods (Access = protected)
        function fileId = getFileId(obj) %#ok<MANU>
            io.backend.base.Writer.throwNotImplemented("getFileId")
            fileId = [];
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:Writer:NotImplemented", ...
                "Writer method `%s` is not implemented.", methodName)
        end
    end
end
