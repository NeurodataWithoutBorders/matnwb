classdef Container < types.untyped.MetaClass
% CONTAINER An abstract data type for a generic container storing collections of data and metadata. Base type for all data and metadata containers.



methods
    function obj = Container(varargin)
        % CONTAINER Constructor for Container
        %     obj = CONTAINER(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.untyped.MetaClass(varargin{:});
        if strcmp(class(obj), 'types.hdmf_common.Container')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
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