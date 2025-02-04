classdef ElectrodeGroup < types.core.NWBContainer & types.untyped.GroupClass
% ELECTRODEGROUP - A physical grouping of electrodes, e.g. a shank of an array.
%
% Required Properties:
%  None


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) Description of this electrode group.
    device; % REQUIRED Device
    location; % REQUIRED (char) Location of electrode group. Specify the area, layer, comments on estimation of area/layer, etc. Use standard atlas names for anatomical regions when possible.
end
% OPTIONAL PROPERTIES
properties
    position; %  (Table with columns: (x = single, y = single, z = single)) stereotaxic or common framework coordinates
end

methods
    function obj = ElectrodeGroup(varargin)
        % ELECTRODEGROUP - Constructor for ElectrodeGroup
        %
        % Syntax:
        %  electrodeGroup = types.core.ELECTRODEGROUP() creates a ElectrodeGroup object with unset property values.
        %
        %  electrodeGroup = types.core.ELECTRODEGROUP(Name, Value) creates a ElectrodeGroup object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of this electrode group.
        %
        %  - device (Device) - Link to the device that was used to record from this electrode group.
        %
        %  - location (char) - Location of electrode group. Specify the area, layer, comments on estimation of area/layer, etc. Use standard atlas names for anatomical regions when possible.
        %
        %  - position (Table with columns: (single, single, single)) - stereotaxic or common framework coordinates
        %
        % Output Arguments:
        %  - electrodeGroup (types.core.ElectrodeGroup) - A ElectrodeGroup object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'device',[]);
        addParameter(p, 'location',[]);
        addParameter(p, 'position',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.device = p.Results.device;
        obj.location = p.Results.location;
        obj.position = p.Results.position;
        if strcmp(class(obj), 'types.core.ElectrodeGroup')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.device(obj, val)
        obj.device = obj.validate_device(val);
    end
    function set.location(obj, val)
        obj.location = obj.validate_location(val);
    end
    function set.position(obj, val)
        obj.position = obj.validate_position(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_device(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('device', 'types.core.Device', val.target);
            end
        else
            val = types.util.checkDtype('device', 'types.core.Device', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_location(obj, val)
        val = types.util.checkDtype('location', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_position(obj, val)
        if isempty(val) || isa(val, 'types.untyped.DataStub')
            return;
        end
        if ~istable(val) && ~isstruct(val) && ~isa(val, 'containers.Map')
            error('NWB:Type:InvalidPropertyType', 'Property `position` must be a table, struct, or containers.Map.');
        end
        vprops = struct();
        vprops.x = 'single';
        vprops.y = 'single';
        vprops.z = 'single';
        val = types.util.checkDtype('position', vprops, val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/description'], obj.description);
        refs = obj.device.export(fid, [fullpath '/device'], refs);
        io.writeAttribute(fid, [fullpath '/location'], obj.location);
        if ~isempty(obj.position)
            if startsWith(class(obj.position), 'types.untyped.')
                refs = obj.position.export(fid, [fullpath '/position'], refs);
            elseif ~isempty(obj.position)
                io.writeCompound(fid, [fullpath '/position'], obj.position);
            end
        end
    end
end

end