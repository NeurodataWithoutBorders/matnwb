classdef EventWaveform < types.core.NWBDataInterface & types.untyped.GroupClass
% EVENTWAVEFORM - DEPRECATED. Represents either the waveforms of detected events, as extracted from a raw data trace in /acquisition, or the event waveforms that were stored during experiment acquisition.
%
% Required Properties:
%  spikeeventseries


% REQUIRED PROPERTIES
properties
    spikeeventseries; % REQUIRED (SpikeEventSeries) SpikeEventSeries object(s) containing detected spike event waveforms.
end

methods
    function obj = EventWaveform(varargin)
        % EVENTWAVEFORM - Constructor for EventWaveform
        %
        % Syntax:
        %  eventWaveform = types.core.EVENTWAVEFORM() creates a EventWaveform object with unset property values.
        %
        %  eventWaveform = types.core.EVENTWAVEFORM(Name, Value) creates a EventWaveform object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - spikeeventseries (SpikeEventSeries) - SpikeEventSeries object(s) containing detected spike event waveforms.
        %
        % Output Arguments:
        %  - eventWaveform (types.core.EventWaveform) - A EventWaveform object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.spikeeventseries, ivarargin] = types.util.parseConstrained(obj,'spikeeventseries', 'types.core.SpikeEventSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.EventWaveform')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.spikeeventseries(obj, val)
        obj.spikeeventseries = obj.validate_spikeeventseries(val);
    end
    %% VALIDATORS
    
    function val = validate_spikeeventseries(obj, val)
        namedprops = struct();
        constrained = {'types.core.SpikeEventSeries'};
        types.util.checkSet('spikeeventseries', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.spikeeventseries.export(fid, fullpath, refs);
    end
end

end