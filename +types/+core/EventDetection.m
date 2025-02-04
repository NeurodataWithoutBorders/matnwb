classdef EventDetection < types.core.NWBDataInterface & types.untyped.GroupClass
% EVENTDETECTION - Detected spike events from voltage trace(s).
%
% Required Properties:
%  detection_method, source_idx, times


% READONLY PROPERTIES
properties(SetAccess = protected)
    times_unit = "seconds"; %  (char) Unit of measurement for event times, which is fixed to 'seconds'.
end
% REQUIRED PROPERTIES
properties
    detection_method; % REQUIRED (char) Description of how events were detected, such as voltage threshold, or dV/dT threshold, as well as relevant values.
    source_electricalseries; % REQUIRED ElectricalSeries
    source_idx; % REQUIRED (int32) Indices (zero-based) into source ElectricalSeries::data array corresponding to time of event. ''description'' should define what is meant by time of event (e.g., .25 ms before action potential peak, zero-crossing time, etc). The index points to each event from the raw data.
    times; % REQUIRED (double) Timestamps of events, in seconds.
end

methods
    function obj = EventDetection(varargin)
        % EVENTDETECTION - Constructor for EventDetection
        %
        % Syntax:
        %  eventDetection = types.core.EVENTDETECTION() creates a EventDetection object with unset property values.
        %
        %  eventDetection = types.core.EVENTDETECTION(Name, Value) creates a EventDetection object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - detection_method (char) - Description of how events were detected, such as voltage threshold, or dV/dT threshold, as well as relevant values.
        %
        %  - source_electricalseries (ElectricalSeries) - Link to the ElectricalSeries that this data was calculated from. Metadata about electrodes and their position can be read from that ElectricalSeries so it's not necessary to include that information here.
        %
        %  - source_idx (int32) - Indices (zero-based) into source ElectricalSeries::data array corresponding to time of event. ''description'' should define what is meant by time of event (e.g., .25 ms before action potential peak, zero-crossing time, etc). The index points to each event from the raw data.
        %
        %  - times (double) - Timestamps of events, in seconds.
        %
        % Output Arguments:
        %  - eventDetection (types.core.EventDetection) - A EventDetection object
        
        varargin = [{'times_unit' 'seconds'} varargin];
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'detection_method',[]);
        addParameter(p, 'source_electricalseries',[]);
        addParameter(p, 'source_idx',[]);
        addParameter(p, 'times',[]);
        addParameter(p, 'times_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.detection_method = p.Results.detection_method;
        obj.source_electricalseries = p.Results.source_electricalseries;
        obj.source_idx = p.Results.source_idx;
        obj.times = p.Results.times;
        obj.times_unit = p.Results.times_unit;
        if strcmp(class(obj), 'types.core.EventDetection')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.detection_method(obj, val)
        obj.detection_method = obj.validate_detection_method(val);
    end
    function set.source_electricalseries(obj, val)
        obj.source_electricalseries = obj.validate_source_electricalseries(val);
    end
    function set.source_idx(obj, val)
        obj.source_idx = obj.validate_source_idx(val);
    end
    function set.times(obj, val)
        obj.times = obj.validate_times(val);
    end
    %% VALIDATORS
    
    function val = validate_detection_method(obj, val)
        val = types.util.checkDtype('detection_method', 'char', val);
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
    function val = validate_source_electricalseries(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('source_electricalseries', 'types.core.ElectricalSeries', val.target);
            end
        else
            val = types.util.checkDtype('source_electricalseries', 'types.core.ElectricalSeries', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_source_idx(obj, val)
        val = types.util.checkDtype('source_idx', 'int32', val);
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
    function val = validate_times(obj, val)
        val = types.util.checkDtype('times', 'double', val);
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
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.detection_method), 'types.untyped.')
            refs = obj.detection_method.export(fid, [fullpath '/detection_method'], refs);
        elseif ~isempty(obj.detection_method)
            io.writeDataset(fid, [fullpath '/detection_method'], obj.detection_method);
        end
        refs = obj.source_electricalseries.export(fid, [fullpath '/source_electricalseries'], refs);
        if startsWith(class(obj.source_idx), 'types.untyped.')
            refs = obj.source_idx.export(fid, [fullpath '/source_idx'], refs);
        elseif ~isempty(obj.source_idx)
            io.writeDataset(fid, [fullpath '/source_idx'], obj.source_idx, 'forceArray');
        end
        if startsWith(class(obj.times), 'types.untyped.')
            refs = obj.times.export(fid, [fullpath '/times'], refs);
        elseif ~isempty(obj.times)
            io.writeDataset(fid, [fullpath '/times'], obj.times, 'forceArray');
        end
        if ~isempty(obj.times) && ~isa(obj.times, 'types.untyped.SoftLink') && ~isa(obj.times, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/times/unit'], obj.times_unit);
        end
    end
end

end