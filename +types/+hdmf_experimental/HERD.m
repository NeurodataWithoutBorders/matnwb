classdef HERD < types.hdmf_common.Container & types.untyped.GroupClass
% HERD - HDMF External Resources Data Structure. A set of six tables for tracking external resource references in a file or across multiple files.
%
% Required Properties:
%  entities, entity_keys, files, keys, object_keys, objects


% REQUIRED PROPERTIES
properties
    entities; % REQUIRED (Data) A table for mapping user terms (i.e., keys) to resource entities.
    entity_keys; % REQUIRED (Data) A table for identifying which keys use which entity.
    files; % REQUIRED (Data) A table for storing object ids of files used in external resources.
    keys; % REQUIRED (Data) A table for storing user terms that are used to refer to external resources.
    object_keys; % REQUIRED (Data) A table for identifying which objects use which keys.
    objects; % REQUIRED (Data) A table for identifying which objects in a file contain references to external resources.
end

methods
    function obj = HERD(varargin)
        % HERD - Constructor for HERD
        %
        % Syntax:
        %  hERD = types.hdmf_experimental.HERD() creates a HERD object with unset property values.
        %
        %  hERD = types.hdmf_experimental.HERD(Name, Value) creates a HERD object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - entities (Data) - A table for mapping user terms (i.e., keys) to resource entities.
        %
        %  - entity_keys (Data) - A table for identifying which keys use which entity.
        %
        %  - files (Data) - A table for storing object ids of files used in external resources.
        %
        %  - keys (Data) - A table for storing user terms that are used to refer to external resources.
        %
        %  - object_keys (Data) - A table for identifying which objects use which keys.
        %
        %  - objects (Data) - A table for identifying which objects in a file contain references to external resources.
        %
        % Output Arguments:
        %  - hERD (types.hdmf_experimental.HERD) - A HERD object
        
        obj = obj@types.hdmf_common.Container(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'entities',[]);
        addParameter(p, 'entity_keys',[]);
        addParameter(p, 'files',[]);
        addParameter(p, 'keys',[]);
        addParameter(p, 'object_keys',[]);
        addParameter(p, 'objects',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.entities = p.Results.entities;
        obj.entity_keys = p.Results.entity_keys;
        obj.files = p.Results.files;
        obj.keys = p.Results.keys;
        obj.object_keys = p.Results.object_keys;
        obj.objects = p.Results.objects;
        if strcmp(class(obj), 'types.hdmf_experimental.HERD')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.entities(obj, val)
        obj.entities = obj.validate_entities(val);
    end
    function set.entity_keys(obj, val)
        obj.entity_keys = obj.validate_entity_keys(val);
    end
    function set.files(obj, val)
        obj.files = obj.validate_files(val);
    end
    function set.keys(obj, val)
        obj.keys = obj.validate_keys(val);
    end
    function set.object_keys(obj, val)
        obj.object_keys = obj.validate_object_keys(val);
    end
    function set.objects(obj, val)
        obj.objects = obj.validate_objects(val);
    end
    %% VALIDATORS
    
    function val = validate_entities(obj, val)
        val = types.util.checkDtype('entities', 'types.hdmf_common.Data', val);
    end
    function val = validate_entity_keys(obj, val)
        val = types.util.checkDtype('entity_keys', 'types.hdmf_common.Data', val);
    end
    function val = validate_files(obj, val)
        val = types.util.checkDtype('files', 'types.hdmf_common.Data', val);
    end
    function val = validate_keys(obj, val)
        val = types.util.checkDtype('keys', 'types.hdmf_common.Data', val);
    end
    function val = validate_object_keys(obj, val)
        val = types.util.checkDtype('object_keys', 'types.hdmf_common.Data', val);
    end
    function val = validate_objects(obj, val)
        val = types.util.checkDtype('objects', 'types.hdmf_common.Data', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.entities.export(fid, [fullpath '/entities'], refs);
        refs = obj.entity_keys.export(fid, [fullpath '/entity_keys'], refs);
        refs = obj.files.export(fid, [fullpath '/files'], refs);
        refs = obj.keys.export(fid, [fullpath '/keys'], refs);
        refs = obj.object_keys.export(fid, [fullpath '/object_keys'], refs);
        refs = obj.objects.export(fid, [fullpath '/objects'], refs);
    end
end

end