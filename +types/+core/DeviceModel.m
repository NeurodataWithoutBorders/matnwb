classdef DeviceModel < types.core.NWBContainer & types.untyped.GroupClass
% DEVICEMODEL - Model properties of a data acquisition device, e.g., recording system, electrode, microscope. This should be extended for specific types of device models to include additional attributes specific to each type. The name of the DeviceModel should be the most common representation of the model name, e.g., Neuropixels 1.0, V-Probe, Bergamo III.
%
% Required Properties:
%  manufacturer


% REQUIRED PROPERTIES
properties
    manufacturer; % REQUIRED (char) The name of the manufacturer of the device model, e.g., Imec, Plexon, Thorlabs.
end
% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the device model as free-form text.
    model_number; %  (char) The model number (or part/product number) of the device, e.g., PRB_1_4_0480_1, PLX-VP-32-15SE(75)-(260-80)(460-10)-300-(1)CON/32m-V, BERGAMO.
end

methods
    function obj = DeviceModel(varargin)
        % DEVICEMODEL - Constructor for DeviceModel
        %
        % Syntax:
        %  deviceModel = types.core.DEVICEMODEL() creates a DeviceModel object with unset property values.
        %
        %  deviceModel = types.core.DEVICEMODEL(Name, Value) creates a DeviceModel object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of the device model as free-form text.
        %
        %  - manufacturer (char) - The name of the manufacturer of the device model, e.g., Imec, Plexon, Thorlabs.
        %
        %  - model_number (char) - The model number (or part/product number) of the device, e.g., PRB_1_4_0480_1, PLX-VP-32-15SE(75)-(260-80)(460-10)-300-(1)CON/32m-V, BERGAMO.
        %
        % Output Arguments:
        %  - deviceModel (types.core.DeviceModel) - A DeviceModel object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'manufacturer',[]);
        addParameter(p, 'model_number',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.manufacturer = p.Results.manufacturer;
        obj.model_number = p.Results.model_number;
        if strcmp(class(obj), 'types.core.DeviceModel')
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
    function set.model_number(obj, val)
        obj.model_number = obj.validate_model_number(val);
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
    function val = validate_model_number(obj, val)
        val = types.util.checkDtype('model_number', 'char', val);
        types.util.validateShape('model_number', {[1]}, val)
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
        io.writeAttribute(fid, [fullpath '/manufacturer'], obj.manufacturer);
        if ~isempty(obj.model_number)
            io.writeAttribute(fid, [fullpath '/model_number'], obj.model_number);
        end
    end
end

end