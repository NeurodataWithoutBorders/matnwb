classdef EnumData < types.hdmf_common.VectorData & types.untyped.DatasetClass
% ENUMDATA - Data that come from a fixed set of values. A data value of i corresponds to the i-th value in the VectorData referenced by the 'elements' attribute.
%
% Required Properties:
%  data


% REQUIRED PROPERTIES
properties
    elements; % REQUIRED (Object reference to VectorData) Reference to the VectorData object that contains the enumerable elements
end

methods
    function obj = EnumData(varargin)
        % ENUMDATA - Constructor for EnumData
        %
        % Syntax:
        %  enumData = types.hdmf_experimental.ENUMDATA() creates a EnumData object with unset property values.
        %
        %  enumData = types.hdmf_experimental.ENUMDATA(Name, Value) creates a EnumData object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (uint8) - No description
        %
        %  - description (char) - Description of what these vectors represent.
        %
        %  - elements (Object reference to VectorData) - Reference to the VectorData object that contains the enumerable elements
        %
        % Output Arguments:
        %  - enumData (types.hdmf_experimental.EnumData) - A EnumData object
        
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'elements',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.elements = p.Results.elements;
        if strcmp(class(obj), 'types.hdmf_experimental.EnumData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.elements(obj, val)
        obj.elements = obj.validate_elements(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint8', val);
    end
    function val = validate_elements(obj, val)
        % Reference to type `VectorData`
        val = types.util.checkDtype('elements', 'types.untyped.ObjectView', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/elements'], obj.elements);
    end
end

end