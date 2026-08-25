classdef Reader < handle
% Reader - Base class for storage backend readers.
%
% This class defines the minimal read-side interface used by nwbRead
% and the parse helpers. Concrete backends should override the methods
% below.

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
        % readRootInfo - Return metadata for the root node of the backend resource.
        %
        % Input Arguments:
        %   obj - Reader instance used to inspect the backend resource.
        %
        % Output Arguments:
        %   node - Structure containing metadata for the root node.

            node = struct();
            io.backend.base.Reader.throwNotImplemented("readRootInfo")
        end

        function node = readNodeInfo(obj, nodePath) %#ok<INUSD>
        % readNodeInfo - Return metadata for a node at the specified path.
        %
        % Input Arguments:
        %   obj - Reader instance used to inspect the backend resource.
        %   nodePath - Backend-relative path to the node being queried.
        %
        % Output Arguments:
        %   node - Structure containing metadata for the requested node.

            node = struct();
            io.backend.base.Reader.throwNotImplemented("readNodeInfo")
        end

        function attributeValue = readAttributeValue(obj, attributeInfo, attributePath) %#ok<INUSD>
        % readAttributeValue - Read the value of an attribute from the backend.
        %
        % Input Arguments:
        %   obj - Reader instance used to access backend content.
        %   attributeInfo - Structure or object describing the attribute to
        %       read.
        %   attributePath - Backend-relative path to the attribute being read.
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
        % it (HDF5 uses a reference datatype class; hdmf-zarr marks the
        % dataset with a "zarr_dtype" attribute of "object").
        %
        % Input Arguments:
        %  - obj - Reader instance.
        %  - datasetInfo - Dataset metadata, as returned by readNodeInfo.
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

        function linkInfo = readLinkInfo(obj, linkPath) %#ok<INUSD>
        % readLinkInfo - Return the target of a link without following it.
        %
        % Input Arguments:
        %  - obj - Reader instance.
        %  - linkPath - Path of the link node.
        %
        % Output Arguments:
        %  - linkInfo - Struct with fields type ("soft link" or "external
        %    link", matching the vocabulary io.parseGroup consumes),
        %    targetPath, and targetFilename (empty for a soft link).
            linkInfo = struct.empty;
            io.backend.base.Reader.throwNotImplemented("readLinkInfo")
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath) %#ok<INUSD>
        % readDatasetValue - Read the value of a dataset from the backend.
        %
        % Input Arguments:
        %   obj - Reader instance used to access backend content.
        %   datasetInfo - Structure or object describing the dataset to
        %       read.
        %   datasetPath - Backend-relative path to the dataset being read.
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
