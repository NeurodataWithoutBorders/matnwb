classdef ElementIdentifiers < types.hdmf_common.Data & types.untyped.DatasetClass
% ELEMENTIDENTIFIERS - A list of unique identifiers for values within a dataset, e.g. rows of a DynamicTable.
%
% Required Properties:
%  data



methods
    function obj = ElementIdentifiers(varargin)
        % ELEMENTIDENTIFIERS - Constructor for ElementIdentifiers
        %
        % Syntax:
        %  elementIdentifiers = types.hdmf_common.ELEMENTIDENTIFIERS() creates a ElementIdentifiers object with unset property values.
        %
        %  elementIdentifiers = types.hdmf_common.ELEMENTIDENTIFIERS(Name, Value) creates a ElementIdentifiers object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (int8) - No description
        %
        % Output Arguments:
        %  - elementIdentifiers (types.hdmf_common.ElementIdentifiers) - A ElementIdentifiers object
        
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.hdmf_common.ElementIdentifiers')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'int8', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Data(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end