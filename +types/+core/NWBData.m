classdef NWBData < types.hdmf_common.Data & types.untyped.DatasetClass
% NWBDATA - An abstract data type for a dataset.
%
% Required Properties:
%  data



methods
    function obj = NWBData(varargin)
        % NWBDATA - Constructor for NWBData
        %
        % Syntax:
        %  nWBData = types.core.NWBDATA() creates a NWBData object with unset property values.
        %
        %  nWBData = types.core.NWBDATA(Name, Value) creates a NWBData object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (any) - No description
        %
        % Output Arguments:
        %  - nWBData (types.core.NWBData) - A NWBData object
        
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.core.NWBData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
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