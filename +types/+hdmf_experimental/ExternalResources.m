classdef ExternalResources < types.hdmf_common.Container & types.untyped.GroupClass
% EXTERNALRESOURCES - A set of four tables for tracking external resource references in a file. NOTE: this data type is in beta testing and is subject to change in a later version.
%
% Required Properties:
%  entities, keys, object_keys, objects, resources


% REQUIRED PROPERTIES
properties
    entities; % REQUIRED (Data) A table for mapping user terms (i.e., keys) to resource entities.
    keys; % REQUIRED (Data) A table for storing user terms that are used to refer to external resources.
    object_keys; % REQUIRED (Data) A table for identifying which objects use which keys.
    objects; % REQUIRED (Data) A table for identifying which objects in a file contain references to external resources.
    resources; % REQUIRED (Data) A table for mapping user terms (i.e., keys) to resource entities.
end

methods
    function obj = ExternalResources(varargin)
        % EXTERNALRESOURCES - Constructor for ExternalResources
        %
        % Syntax:
        %  externalResources = types.hdmf_experimental.EXTERNALRESOURCES() creates a ExternalResources object with unset property values.
        %
        %  externalResources = types.hdmf_experimental.EXTERNALRESOURCES(Name, Value) creates a ExternalResources object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - entities (Data) - A table for mapping user terms (i.e., keys) to resource entities.
        %
        %  - keys (Data) - A table for storing user terms that are used to refer to external resources.
        %
        %  - object_keys (Data) - A table for identifying which objects use which keys.
        %
        %  - objects (Data) - A table for identifying which objects in a file contain references to external resources.
        %
        %  - resources (Data) - A table for mapping user terms (i.e., keys) to resource entities.
        %
        % Output Arguments:
        %  - externalResources (types.hdmf_experimental.ExternalResources) - A ExternalResources object
        
        obj = obj@types.hdmf_common.Container(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'entities',[]);
        addParameter(p, 'keys',[]);
        addParameter(p, 'object_keys',[]);
        addParameter(p, 'objects',[]);
        addParameter(p, 'resources',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.entities = p.Results.entities;
        obj.keys = p.Results.keys;
        obj.object_keys = p.Results.object_keys;
        obj.objects = p.Results.objects;
        obj.resources = p.Results.resources;
        if strcmp(class(obj), 'types.hdmf_experimental.ExternalResources')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.entities(obj, val)
        obj.entities = obj.validate_entities(val);
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
    function set.resources(obj, val)
        obj.resources = obj.validate_resources(val);
    end
    %% VALIDATORS
    
    function val = validate_entities(obj, val)
        types.util.checkType('entities', 'types.hdmf_common.Data', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            if isempty(val)
                % skip validation for empty values
            else
                vprops = struct();
                vprops.keys_idx = 'uint';
                vprops.resources_idx = 'uint';
                vprops.entity_id = 'char';
                vprops.entity_uri = 'char';
                val = types.util.checkDtype('entities', vprops, val);
            end
            types.util.validateShape('entities', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_keys(obj, val)
        types.util.checkType('keys', 'types.hdmf_common.Data', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            if isempty(val)
                % skip validation for empty values
            else
                vprops = struct();
                vprops.key = 'char';
                val = types.util.checkDtype('keys', vprops, val);
            end
            types.util.validateShape('keys', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_object_keys(obj, val)
        types.util.checkType('object_keys', 'types.hdmf_common.Data', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            if isempty(val)
                % skip validation for empty values
            else
                vprops = struct();
                vprops.objects_idx = 'uint';
                vprops.keys_idx = 'uint';
                val = types.util.checkDtype('object_keys', vprops, val);
            end
            types.util.validateShape('object_keys', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_objects(obj, val)
        types.util.checkType('objects', 'types.hdmf_common.Data', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            if isempty(val)
                % skip validation for empty values
            else
                vprops = struct();
                vprops.object_id = 'char';
                vprops.field = 'char';
                val = types.util.checkDtype('objects', vprops, val);
            end
            types.util.validateShape('objects', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_resources(obj, val)
        types.util.checkType('resources', 'types.hdmf_common.Data', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            if isempty(val)
                % skip validation for empty values
            else
                vprops = struct();
                vprops.resource = 'char';
                vprops.resource_uri = 'char';
                val = types.util.checkDtype('resources', vprops, val);
            end
            types.util.validateShape('resources', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.entities.export(fid, [fullpath '/entities'], refs);
        refs = obj.keys.export(fid, [fullpath '/keys'], refs);
        refs = obj.object_keys.export(fid, [fullpath '/object_keys'], refs);
        refs = obj.objects.export(fid, [fullpath '/objects'], refs);
        refs = obj.resources.export(fid, [fullpath '/resources'], refs);
    end
end

end