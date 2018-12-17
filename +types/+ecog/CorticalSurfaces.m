classdef CorticalSurfaces < types.core.NWBDataInterface
% CorticalSurfaces triverts for cortical surfaces


% PROPERTIES
properties
    surface; % brain cortical surface
end

methods
    function obj = CorticalSurfaces(varargin)
        % CORTICALSURFACES Constructor for CorticalSurfaces
        %     obj = CORTICALSURFACES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % surface = Surface
        varargin = [{'help' 'This holds the vertices and faces for the cortical surface meshes'} varargin];
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.surface, ivarargin] = types.util.parseConstrained(obj,'types.core.NWBDataInterface', 'types.ecog.Surface', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        parse(p, varargin{:});
        if strcmp(class(obj), 'types.ecog.CorticalSurfaces')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.surface(obj, val)
        obj.surface = obj.validate_surface(val);
    end
    %% VALIDATORS
    
    function val = validate_surface(obj, val)
        constrained = {'types.ecog.Surface'};
        types.util.checkSet('surface', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.surface)
            refs = obj.surface.export(fid, fullpath, refs);
        else
            error('Property `surface` is required.');
        end
    end
end

end