classdef Reader < handle
    % Reader - Base class for storage backend readers.
    %
    % This class defines the minimal read-side interface used by nwbRead
    % and the parse helpers. Concrete backends should override the methods
    % below.

    properties (SetAccess = protected)
        filename (1,1) string
    end

    methods
        function obj = Reader(filename)
            arguments
                filename (1,1) string = missing
            end
            obj.filename = filename;
        end

        function version = getSchemaVersion(obj) %#ok<MANU>
            io.backend.base.Reader.throwNotImplemented("getSchemaVersion")
            version = string.empty;
        end

        function specLocation = getEmbeddedSpecLocation(obj) %#ok<MANU>
            io.backend.base.Reader.throwNotImplemented("getEmbeddedSpecLocation")
            specLocation = string.empty;
        end

        function node = readRootInfo(obj) %#ok<MANU>
            io.backend.base.Reader.throwNotImplemented("readRootInfo")
            node = struct();
        end

        function node = readNodeInfo(obj, nodePath) %#ok<INUSD,MANU>
            io.backend.base.Reader.throwNotImplemented("readNodeInfo")
            node = struct();
        end

        function attributeValue = readAttributeValue(obj, attributeInfo, context) %#ok<INUSD,MANU>
            io.backend.base.Reader.throwNotImplemented("readAttributeValue")
            attributeValue = [];
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath) %#ok<INUSD,MANU>
            io.backend.base.Reader.throwNotImplemented("readDatasetValue")
            datasetValue = [];
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:Reader:NotImplemented", ...
                "Reader method `%s` is not implemented.", methodName)
        end
    end
end
