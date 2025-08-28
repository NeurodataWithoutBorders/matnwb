classdef Device < types.core.NWBContainer & types.untyped.GroupClass
% DEVICE - Metadata about a specific instance of a data acquisition device, e.g., recording system, electrode, microscope. Link to a DeviceModel.model to represent information about the model of the device.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the device as free-form text. If there is any software/firmware associated with the device, the names and versions of those can be added to NWBFile.was_generated_by.
    manufacturer; %  (char) DEPRECATED. The name of the manufacturer of the device, e.g., Imec, Plexon, Thorlabs. Instead of using this field, store the value in DeviceModel.manufacturer and link to that DeviceModel from this Device.
    model; %  DeviceModel
    model_name; %  (char) DEPRECATED. The model name of the device, e.g., Neuropixels 1.0, V-Probe, Bergamo III. Instead of using this field, create and add a new DeviceModel named the model name and link to that DeviceModel from this Device.
    model_number; %  (char) DEPRECATED. The model number (or part/product number) of the device, e.g., PRB_1_4_0480_1, PLX-VP-32-15SE(75)-(260-80)(460-10)-300-(1)CON/32m-V, BERGAMO. Instead of using this field, store the value in DeviceModel.model_number and link to that DeviceModel from this Device.
    serial_number; %  (char) The serial number of the device.
end

methods
    function obj = Device(varargin)
        % DEVICE - Constructor for Device
        %
        % Syntax:
        %  device = types.core.DEVICE() creates a Device object with unset property values.
        %
        %  device = types.core.DEVICE(Name, Value) creates a Device object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of the device as free-form text. If there is any software/firmware associated with the device, the names and versions of those can be added to NWBFile.was_generated_by.
        %
        %  - manufacturer (char) - DEPRECATED. The name of the manufacturer of the device, e.g., Imec, Plexon, Thorlabs. Instead of using this field, store the value in DeviceModel.manufacturer and link to that DeviceModel from this Device.
        %
        %  - model (DeviceModel) - The model of the device.
        %
        %  - model_name (char) - DEPRECATED. The model name of the device, e.g., Neuropixels 1.0, V-Probe, Bergamo III. Instead of using this field, create and add a new DeviceModel named the model name and link to that DeviceModel from this Device.
        %
        %  - model_number (char) - DEPRECATED. The model number (or part/product number) of the device, e.g., PRB_1_4_0480_1, PLX-VP-32-15SE(75)-(260-80)(460-10)-300-(1)CON/32m-V, BERGAMO. Instead of using this field, store the value in DeviceModel.model_number and link to that DeviceModel from this Device.
        %
        %  - serial_number (char) - The serial number of the device.
        %
        % Output Arguments:
        %  - device (types.core.Device) - A Device object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'manufacturer',[]);
        addParameter(p, 'model',[]);
        addParameter(p, 'model_name',[]);
        addParameter(p, 'model_number',[]);
        addParameter(p, 'serial_number',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.manufacturer = p.Results.manufacturer;
        obj.model = p.Results.model;
        obj.model_name = p.Results.model_name;
        obj.model_number = p.Results.model_number;
        obj.serial_number = p.Results.serial_number;
        if strcmp(class(obj), 'types.core.Device')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.manufacturer(obj, val)
        obj.manufacturer = obj.validate_manufacturer(val);
    end
    function set.model(obj, val)
        obj.model = obj.validate_model(val);
    end
    function set.model_name(obj, val)
        obj.model_name = obj.validate_model_name(val);
    end
    function set.model_number(obj, val)
        obj.model_number = obj.validate_model_number(val);
    end
    function set.serial_number(obj, val)
        obj.serial_number = obj.validate_serial_number(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    function val = validate_manufacturer(obj, val)
        val = types.util.checkDtype('manufacturer', 'char', val);
        types.util.validateShape('manufacturer', {[1]}, val)
    end
    function val = validate_model(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('model', 'types.core.DeviceModel', val.target);
            end
        else
            val = types.util.checkDtype('model', 'types.core.DeviceModel', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_model_name(obj, val)
        val = types.util.checkDtype('model_name', 'char', val);
        types.util.validateShape('model_name', {[1]}, val)
    end
    function val = validate_model_number(obj, val)
        val = types.util.checkDtype('model_number', 'char', val);
        types.util.validateShape('model_number', {[1]}, val)
    end
    function val = validate_serial_number(obj, val)
        val = types.util.checkDtype('serial_number', 'char', val);
        types.util.validateShape('serial_number', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        end
        if ~isempty(obj.manufacturer)
            io.writeAttribute(fid, [fullpath '/manufacturer'], obj.manufacturer);
        end
        if ~isempty(obj.model)
            refs = obj.model.export(fid, [fullpath '/model'], refs);
        end
        if ~isempty(obj.model_name)
            io.writeAttribute(fid, [fullpath '/model_name'], obj.model_name);
        end
        if ~isempty(obj.model_number)
            io.writeAttribute(fid, [fullpath '/model_number'], obj.model_number);
        end
        if ~isempty(obj.serial_number)
            io.writeAttribute(fid, [fullpath '/serial_number'], obj.serial_number);
        end
    end
end

end