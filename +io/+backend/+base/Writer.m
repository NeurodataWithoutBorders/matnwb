classdef Writer < handle
    % Writer - Base class for storage backend writers.
    %
    % This class defines the minimal write-side interface used by export
    % code. Concrete backends should override the methods below.

    properties (SetAccess = protected)
        fileId
    end

    methods
        function obj = Writer(fileId)
            if nargin < 1
                fileId = [];
            end
            obj.fileId = fileId;
        end

        function groupExists = writeGroup(obj, groupPath) %#ok<INUSD,MANU>
            io.backend.base.Writer.throwNotImplemented("writeGroup")
            groupExists = false;
        end

        function writeValue(obj, datasetPath, value, varargin) %#ok<INUSD,MANU>
            io.backend.base.Writer.throwNotImplemented("writeValue")
        end

        function writeAttribute(obj, attributePath, value, varargin) %#ok<INUSD,MANU>
            io.backend.base.Writer.throwNotImplemented("writeAttribute")
        end
    end

    methods (Static)
        function writer = ensure(writerOrFileId)
            if isa(writerOrFileId, "io.backend.base.Writer")
                writer = writerOrFileId;
                return
            end

            writer = io.backend.BackendFactory.createWriter(writerOrFileId);
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:Writer:NotImplemented", ...
                "Writer method `%s` is not implemented.", methodName)
        end
    end
end
