classdef BehavioralEpochs < types.core.NWBDataInterface & types.untyped.GroupClass
% BEHAVIORALEPOCHS - TimeSeries for storing behavioral epochs.  The objective of this and the other two Behavioral interfaces (e.g. BehavioralEvents and BehavioralTimeSeries) is to provide generic hooks for software tools/scripts. This allows a tool/script to take the output one specific interface (e.g., UnitTimes) and plot that data relative to another data modality (e.g., behavioral events) without having to define all possible modalities in advance. Declaring one of these interfaces means that one or more TimeSeries of the specified type is published. These TimeSeries should reside in a group having the same name as the interface. For example, if a BehavioralTimeSeries interface is declared, the module will have one or more TimeSeries defined in the module sub-group 'BehavioralTimeSeries'. BehavioralEpochs should use IntervalSeries. BehavioralEvents is used for irregular events. BehavioralTimeSeries is for continuous data.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    intervalseries; %  (IntervalSeries) IntervalSeries object containing start and stop times of epochs.
end

methods
    function obj = BehavioralEpochs(varargin)
        % BEHAVIORALEPOCHS - Constructor for BehavioralEpochs
        %
        % Syntax:
        %  behavioralEpochs = types.core.BEHAVIORALEPOCHS() creates a BehavioralEpochs object with unset property values.
        %
        %  behavioralEpochs = types.core.BEHAVIORALEPOCHS(Name, Value) creates a BehavioralEpochs object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - intervalseries (IntervalSeries) - IntervalSeries object containing start and stop times of epochs.
        %
        % Output Arguments:
        %  - behavioralEpochs (types.core.BehavioralEpochs) - A BehavioralEpochs object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.intervalseries, ivarargin] = types.util.parseConstrained(obj,'intervalseries', 'types.core.IntervalSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.BehavioralEpochs')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.intervalseries(obj, val)
        obj.intervalseries = obj.validate_intervalseries(val);
    end
    %% VALIDATORS
    
    function val = validate_intervalseries(obj, val)
        namedprops = struct();
        constrained = {'types.core.IntervalSeries'};
        types.util.checkSet('intervalseries', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.intervalseries)
            refs = obj.intervalseries.export(fid, fullpath, refs);
        end
    end
end

end