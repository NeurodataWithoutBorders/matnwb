classdef Container < types.untyped.MetaClass & types.untyped.GroupClass
% CONTAINER An abstract data type for a group storing collections of data and metadata. Base type for all data and metadata containers.



methods
    function obj = Container(varargin)
        % CONTAINER Constructor for Container
        obj = obj@types.untyped.MetaClass(varargin{:});
        if strcmp(class(obj), 'types.hdmf_common.Container')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end