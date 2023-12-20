classdef PatchClampSeries < types.core.TimeSeries & types.untyped.GroupClass
% PATCHCLAMPSERIES An abstract base class for patch-clamp data - stimulus or response, current or voltage.


% OPTIONAL PROPERTIES
properties
    electrode; %  IntracellularElectrode
    gain; %  (single) Gain of the recording, in units Volt/Amp (v-clamp) or Volt/Volt (c-clamp).
    stimulus_description; %  (char) Protocol/stimulus name for this patch-clamp dataset.
    sweep_number; %  (uint32) Sweep number, allows to group different PatchClampSeries together.
end

methods
    function obj = PatchClampSeries(varargin)
        % PATCHCLAMPSERIES Constructor for PatchClampSeries
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'electrode',[]);
        addParameter(p, 'gain',[]);
        addParameter(p, 'stimulus_description',[]);
        addParameter(p, 'sweep_number',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.data_unit = p.Results.data_unit;
        obj.electrode = p.Results.electrode;
        obj.gain = p.Results.gain;
        obj.stimulus_description = p.Results.stimulus_description;
        obj.sweep_number = p.Results.sweep_number;
        if strcmp(class(obj), 'types.core.PatchClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.electrode(obj, val)
        obj.electrode = obj.validate_electrode(val);
    end
    function set.gain(obj, val)
        obj.gain = obj.validate_gain(val);
    end
    function set.stimulus_description(obj, val)
        obj.stimulus_description = obj.validate_stimulus_description(val);
    end
    function set.sweep_number(obj, val)
        obj.sweep_number = obj.validate_sweep_number(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
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
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
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
    function val = validate_electrode(obj, val)
        val = types.util.checkDtype('electrode', 'types.core.IntracellularElectrode', val);
    end
    function val = validate_gain(obj, val)
        val = types.util.checkDtype('gain', 'single', val);
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
    function val = validate_stimulus_description(obj, val)
        val = types.util.checkDtype('stimulus_description', 'char', val);
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
    function val = validate_sweep_number(obj, val)
        val = types.util.checkDtype('sweep_number', 'uint32', val);
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
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrode.export(fid, [fullpath '/electrode'], refs);
        if ~isempty(obj.gain)
            if startsWith(class(obj.gain), 'types.untyped.')
                refs = obj.gain.export(fid, [fullpath '/gain'], refs);
            elseif ~isempty(obj.gain)
                io.writeDataset(fid, [fullpath '/gain'], obj.gain);
            end
        end
        io.writeAttribute(fid, [fullpath '/stimulus_description'], obj.stimulus_description);
        if ~isempty(obj.sweep_number)
            io.writeAttribute(fid, [fullpath '/sweep_number'], obj.sweep_number);
        end
    end
end

end