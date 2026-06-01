classdef VectorData < types.hdmf_common.Data & types.untyped.DatasetClass
% VECTORDATA - An n-dimensional dataset representing a column of a DynamicTable. If used without an accompanying VectorIndex, first dimension is along the rows of the DynamicTable and each step along the first dimension is a cell of the larger table. VectorData can also be used to represent a ragged array if paired with a VectorIndex. This allows for storing arrays of varying length in a single cell of the DynamicTable by indexing into this VectorData. The first vector is at VectorData[0:VectorIndex[0]]. The second vector is at VectorData[VectorIndex[0]:VectorIndex[1]], and so on.
%
% Required Properties:
%  data, description


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) Description of what these vectors represent.
end

methods
    function obj = VectorData(varargin)
        % VECTORDATA - Constructor for VectorData
        %
        % Syntax:
        %  vectorData = types.hdmf_common.VECTORDATA() creates a VectorData object with unset property values.
        %
        %  vectorData = types.hdmf_common.VECTORDATA(Name, Value) creates a VectorData object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (any) - Data property for dataset class (VectorData)
        %
        %  - description (char) - Description of what these vectors represent.
        %
        % Output Arguments:
        %  - vectorData (types.hdmf_common.VectorData) - A VectorData object
        
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.hdmf_common.VectorData') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'any', val);
        types.util.validateShape('data', {[Inf,Inf,Inf,Inf], [Inf,Inf,Inf], [Inf,Inf], [Inf]}, val)
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.Data(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        writer.writeAttribute([fullpath '/description'], obj.description);
    end
end

end