classdef Data < types.untyped.MetaClass & types.untyped.DatasetClass
% DATA - An abstract data type for a dataset.
%
% Required Properties:
%  data


% REQUIRED PROPERTIES
properties
    data; % REQUIRED any
end

methods
    function obj = Data(varargin)
        % DATA - Constructor for Data
        %
        % Syntax:
        %  data = types.hdmf_common.DATA() creates a Data object with unset property values.
        %
        %  data = types.hdmf_common.DATA(Name, Value) creates a Data object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (any) - No description
        %
        % Output Arguments:
        %  - data (types.hdmf_common.Data) - A Data object
        
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.hdmf_common.Data')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end