classdef ElementIdentifiers < types.hdmf_common.Data
% ELEMENTIDENTIFIERS A list of unique identifiers for values within a dataset, e.g. rows of a DynamicTable.



methods
    function obj = ElementIdentifiers(varargin)
        % ELEMENTIDENTIFIERS Constructor for ElementIdentifiers
        %     obj = ELEMENTIDENTIFIERS(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.hdmf_common.Data(varargin{:});
        if strcmp(class(obj), 'types.hdmf_common.ElementIdentifiers')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'int', val);
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