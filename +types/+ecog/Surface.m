classdef Surface < types.core.NWBDataInterface
% Surface brain cortical surface


% PROPERTIES
properties
    faces; % faces for surface, indexes vertices
    vertices; % vertices for surface, points in 3D space
end

methods
    function obj = Surface(varargin)
        % SURFACE Constructor for Surface
        %     obj = SURFACE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % faces = uint64
        % vertices = double
        varargin = [{'help' 'This holds Surface objects'} varargin];
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'faces',[]);
        addParameter(p, 'vertices',[]);
        parse(p, varargin{:});
        obj.faces = p.Results.faces;
        obj.vertices = p.Results.vertices;
        if strcmp(class(obj), 'types.ecog.Surface')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.faces(obj, val)
        obj.faces = obj.validate_faces(val);
    end
    function obj = set.vertices(obj, val)
        obj.vertices = obj.validate_vertices(val);
    end
    %% VALIDATORS
    
    function val = validate_faces(obj, val)
        val = types.util.checkDtype('faces', 'uint64', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[3 Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_vertices(obj, val)
        val = types.util.checkDtype('vertices', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[3 Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.faces)
            if startsWith(class(obj.faces), 'types.untyped.')
                refs = obj.faces.export(fid, [fullpath '/faces'], refs);
            elseif ~isempty(obj.faces)
                io.writeDataset(fid, [fullpath '/faces'], class(obj.faces), obj.faces);
            end
        else
            error('Property `faces` is required.');
        end
        if ~isempty(obj.vertices)
            if startsWith(class(obj.vertices), 'types.untyped.')
                refs = obj.vertices.export(fid, [fullpath '/vertices'], refs);
            elseif ~isempty(obj.vertices)
                io.writeDataset(fid, [fullpath '/vertices'], class(obj.vertices), obj.vertices);
            end
        else
            error('Property `vertices` is required.');
        end
    end
end

end