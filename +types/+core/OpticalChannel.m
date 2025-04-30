classdef OpticalChannel < types.core.NWBContainer & types.untyped.GroupClass
% OPTICALCHANNEL - An optical channel used to record from an imaging plane.
%
% Required Properties:
%  description, emission_lambda


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) Description or other notes about the channel.
    emission_lambda; % REQUIRED (single) Emission wavelength for channel, in nm.
end

methods
    function obj = OpticalChannel(varargin)
        % OPTICALCHANNEL - Constructor for OpticalChannel
        %
        % Syntax:
        %  opticalChannel = types.core.OPTICALCHANNEL() creates a OpticalChannel object with unset property values.
        %
        %  opticalChannel = types.core.OPTICALCHANNEL(Name, Value) creates a OpticalChannel object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description or other notes about the channel.
        %
        %  - emission_lambda (single) - Emission wavelength for channel, in nm.
        %
        % Output Arguments:
        %  - opticalChannel (types.core.OpticalChannel) - A OpticalChannel object
        
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'emission_lambda',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.emission_lambda = p.Results.emission_lambda;
        if strcmp(class(obj), 'types.core.OpticalChannel')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.emission_lambda(obj, val)
        obj.emission_lambda = obj.validate_emission_lambda(val);
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
    function val = validate_emission_lambda(obj, val)
        val = types.util.checkDtype('emission_lambda', 'single', val);
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
        if startsWith(class(obj.description), 'types.untyped.')
            refs = obj.description.export(fid, [fullpath '/description'], refs);
        elseif ~isempty(obj.description)
            io.writeDataset(fid, [fullpath '/description'], obj.description);
        end
        if startsWith(class(obj.emission_lambda), 'types.untyped.')
            refs = obj.emission_lambda.export(fid, [fullpath '/emission_lambda'], refs);
        elseif ~isempty(obj.emission_lambda)
            io.writeDataset(fid, [fullpath '/emission_lambda'], obj.emission_lambda);
        end
    end
end

end