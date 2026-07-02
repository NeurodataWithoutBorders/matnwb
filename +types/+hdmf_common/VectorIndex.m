classdef VectorIndex < types.hdmf_common.VectorData & types.untyped.DatasetClass
% VECTORINDEX - Used with VectorData to encode a ragged array. An array of indices into the first dimension of the target VectorData, forming a map between the rows of a DynamicTable and the indices of the VectorData. The name of the VectorIndex is expected to be the name of the target VectorData object followed by "_index".
%
% Required Properties:
%  data, description, target


% REQUIRED PROPERTIES
properties
    target; % REQUIRED (Object reference to VectorData) Reference to the target dataset that this index applies to.
end

methods
    function obj = VectorIndex(varargin)
        % VECTORINDEX - Constructor for VectorIndex
        %
        % Syntax:
        %  vectorIndex = types.hdmf_common.VECTORINDEX() creates a VectorIndex object with unset property values.
        %
        %  vectorIndex = types.hdmf_common.VECTORINDEX(Name, Value) creates a VectorIndex object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (uint8) - Data property for dataset class (VectorIndex)
        %
        %  - description (char) - Description of what these vectors represent.
        %
        %  - target (Object reference to VectorData) - Reference to the target dataset that this index applies to.
        %
        % Output Arguments:
        %  - vectorIndex (types.hdmf_common.VectorIndex) - A VectorIndex object
        
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'target',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.target = p.Results.target;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.hdmf_common.VectorIndex') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.target(obj, val)
        obj.target = obj.validate_target(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint8', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_target(obj, val)
        % Reference to type `VectorData`
        val = types.util.validateReferenceType('target', val, 'types.hdmf_common.VectorData', 'types.untyped.ObjectView');
        types.util.validateShape('target', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        writer.writeAttribute([fullpath '/target'], obj.target);
    end
end

end