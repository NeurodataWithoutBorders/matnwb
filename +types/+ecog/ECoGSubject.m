classdef ECoGSubject < types.core.Subject
% ECoGSubject extension of subject that holds cortical surface data


% PROPERTIES
properties
    cortical_surfaces; % triverts for cortical surfaces
    images; % images of subject's brain
end

methods
    function obj = ECoGSubject(varargin)
        % ECOGSUBJECT Constructor for ECoGSubject
        %     obj = ECOGSUBJECT(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % images = Images
        % cortical_surfaces = CorticalSurfaces
        obj = obj@types.core.Subject(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'images',[]);
        addParameter(p, 'cortical_surfaces',types.untyped.Set());
        parse(p, varargin{:});
        obj.images = p.Results.images;
        obj.cortical_surfaces = p.Results.cortical_surfaces;
        if strcmp(class(obj), 'types.ecog.ECoGSubject')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.cortical_surfaces(obj, val)
        obj.cortical_surfaces = obj.validate_cortical_surfaces(val);
    end
    function obj = set.images(obj, val)
        obj.images = obj.validate_images(val);
    end
    %% VALIDATORS
    
    function val = validate_cortical_surfaces(obj, val)
        val = types.util.checkDtype('cortical_surfaces', 'types.ecog.CorticalSurfaces', val);
    end
    function val = validate_images(obj, val)
        val = types.util.checkDtype('images', 'types.core.Images', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Subject(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.cortical_surfaces)
            refs = obj.cortical_surfaces.export(fid, [fullpath '/cortical_surfaces'], refs);
        end
        if ~isempty(obj.images)
            refs = obj.images.export(fid, [fullpath '/images'], refs);
        else
            error('Property `images` is required.');
        end
    end
end

end