classdef Reader < handle
% Reader - Base class for storage backend readers.
%
% This class defines the minimal read-side interface used by nwbRead
% and the parse helpers. Concrete backends should override the methods
% below.
%
% A reader describes the nodes of a file with the classes in
% io.backend.model: GroupInfo, DatasetInfo, LinkInfo and AttributeInfo.
% The parse helpers read names, child nodes, links and attribute values
% from them, and pass dataset and attribute descriptions back to the
% reader to read values. How a backend stores types and shapes stays in
% the BackendInfo property of DatasetInfo and AttributeInfo, which only
% the reader that created the object reads.

% Note: This class is intended to be abstract. However, it is implemented as a
% concrete class so it can be used for property and argument validation across 
% its subclasses. The methods defined here establish the shared interface and 
% throw not-implemented errors by default.


    properties (SetAccess = protected)
        Filename (1,1) string
    end

    methods
        function obj = Reader(filename)
        % Reader - Create a reader instance for a storage backend.
        %
        % Input Arguments:
        %   filename - Path to the backend resource represented by this
        %       reader.
        %
        % Output Arguments:
        %   obj - Reader instance initialized with the provided filename.

            arguments
                filename (1,1) string = missing
            end
            obj.Filename = filename;
        end

        function version = getSchemaVersion(obj) %#ok<MANU>
        % getSchemaVersion - Return the schema version stored by the backend.
        %
        % Input Arguments:
        %   obj - Reader instance used to query backend metadata.
        %
        % Output Arguments:
        %   version - Schema version string reported by the backend.

            version = string.empty;
            io.backend.base.Reader.throwNotImplemented("getSchemaVersion")
        end

        function specLocation = getEmbeddedSpecLocation(obj) %#ok<MANU>
        % getEmbeddedSpecLocation - Return the location of embedded schema specifications.
        %
        % Input Arguments:
        %   obj - Reader instance used to query backend metadata.
        %
        % Output Arguments:
        %   specLocation - Identifier or path describing where embedded
        %       schema specifications are stored.

            specLocation = string.empty;
            io.backend.base.Reader.throwNotImplemented("getEmbeddedSpecLocation")
        end

        function node = readRootInfo(obj) %#ok<MANU>
        % readRootInfo - Return the description of the root group.
        %
        % Input Arguments:
        %   obj - Reader instance used to inspect the backend resource.
        %
        % Output Arguments:
        %   node - io.backend.model.GroupInfo describing the root group and,
        %       through its child groups, the whole hierarchy.

            node = io.backend.model.GroupInfo.empty;
            io.backend.base.Reader.throwNotImplemented("readRootInfo")
        end

        function node = readNodeInfo(obj, nodePath) %#ok<INUSD>
        % readNodeInfo - Return the description of the node at a path.
        %
        % A link at nodePath is described without following it, so a
        % caller can tell a link apart from the node it points to.
        %
        % Input Arguments:
        %   obj - Reader instance used to inspect the backend resource.
        %   nodePath - Absolute path of the node within the backend resource.
        %
        % Output Arguments:
        %   node - io.backend.model.GroupInfo, io.backend.model.DatasetInfo
        %       or io.backend.model.LinkInfo, depending on the node.

            node = io.backend.model.GroupInfo.empty;
            io.backend.base.Reader.throwNotImplemented("readNodeInfo")
        end

        function attributeValue = readAttributeValue(obj, attributeInfo, attributePath) %#ok<INUSD>
        % readAttributeValue - Read the value of an attribute from the backend.
        %
        % Input Arguments:
        %   obj - Reader instance used to access backend content.
        %   attributeInfo - io.backend.model.AttributeInfo describing the
        %       attribute, as listed with its node.
        %   attributePath - Path of the node that holds the attribute.
        %
        % Output Arguments:
        %   attributeValue - Value read for the requested attribute.

            attributeValue = [];
            io.backend.base.Reader.throwNotImplemented("readAttributeValue")
        end

        function tf = isReferenceDataset(obj, datasetInfo) %#ok<INUSD>
        % isReferenceDataset - Whether a dataset holds object references.
        %
        % A dataset of references has to be read and resolved rather than
        % returned as a lazy stub, so callers deciding how to handle a
        % dataset need to ask this without knowing how the backend encodes
        % references.
        %
        % Input Arguments:
        %  - obj - Reader instance.
        %  - datasetInfo - io.backend.model.DatasetInfo, as returned by
        %    readNodeInfo.
        %
        % Output Arguments:
        %  - tf - true when the dataset holds references.
            tf = false;
            io.backend.base.Reader.throwNotImplemented("isReferenceDataset")
        end

        function base = getExternalLinkBase(obj) %#ok<MANU>
        % getExternalLinkBase - Base location for resolving relative link targets.
        %
        % A relative target filename stored in an external link resolves
        % against a backend-specific location: HDF5 resolves it against the
        % directory containing the linking file, while hdmf-zarr resolves
        % it against the store path itself.
        %
        % Output Arguments:
        %  - base - Absolute path that relative external-link targets in
        %    this backend resource resolve against.
            base = string.empty;
            io.backend.base.Reader.throwNotImplemented("getExternalLinkBase")
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath) %#ok<INUSD>
        % readDatasetValue - Read the value of a dataset from the backend.
        %
        % Input Arguments:
        %   obj - Reader instance used to access backend content.
        %   datasetInfo - io.backend.model.DatasetInfo describing the
        %       dataset, as returned by readNodeInfo.
        %   datasetPath - Absolute path of the dataset.
        %
        % Output Arguments:
        %   datasetValue - Value read for the requested dataset.

            datasetValue = [];
            io.backend.base.Reader.throwNotImplemented("readDatasetValue")
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
        % throwNotImplemented - Raise a standardized error for abstract reader methods.
        %
        % Input Arguments:
        %   methodName - Name of the reader method that must be implemented
        %       by a concrete backend class.

            error("NWB:Backend:Reader:NotImplemented", ...
                "Reader method `%s` is not implemented.", methodName)
        end
    end
end
