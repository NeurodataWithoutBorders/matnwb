classdef Index < types.hdmf_common.Data
% INDEX Pointers that index data values.


% PROPERTIES
properties
    target; % Target dataset that this index applies to.
end

methods
    function obj = Index(varargin)
        % INDEX Constructor for Index
        %     obj = INDEX(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % target = ref to Data object
        obj = obj@types.hdmf_common.Data(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'target',[]);
        parse(p, varargin{:});
        obj.target = p.Results.target;
        if strcmp(class(obj), 'types.hdmf_common.Index')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.target(obj, val)
        obj.target = obj.validate_target(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    function val = validate_target(obj, val)
        % Reference to type `Data`
        val = types.util.checkDtype('target', 'types.untyped.ObjectView', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Data(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.target)
            io.writeAttribute(fid, [fullpath '/target'], obj.target);
        else
            error('Property `target` is required.');
        end
    end
end

end