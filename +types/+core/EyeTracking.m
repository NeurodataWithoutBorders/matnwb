classdef EyeTracking < types.core.NWBDataInterface & types.untyped.GroupClass & matnwb.mixin.HasUnnamedGroups
% EYETRACKING - Eye-tracking data, representing direction of gaze.
%
% Required Properties:
%  spatialseries


% REQUIRED PROPERTIES
properties
    spatialseries; % REQUIRED (SpatialSeries) SpatialSeries object containing data measuring direction of gaze.
end
properties (Access = protected)
    GroupPropertyNames = {'spatialseries'}
end

methods
    function obj = EyeTracking(varargin)
        % EYETRACKING - Constructor for EyeTracking
        %
        % Syntax:
        %  eyeTracking = types.core.EYETRACKING() creates a EyeTracking object with unset property values.
        %
        %  eyeTracking = types.core.EYETRACKING(Name, Value) creates a EyeTracking object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - spatialseries (SpatialSeries) - SpatialSeries object containing data measuring direction of gaze.
        %
        % Output Arguments:
        %  - eyeTracking (types.core.EyeTracking) - A EyeTracking object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.spatialseries, ivarargin] = types.util.parseConstrained(obj,'spatialseries', 'types.core.SpatialSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.EyeTracking') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            obj.setupHasUnnamedGroupsMixin();
        end
    end
    %% SETTERS
    function set.spatialseries(obj, val)
        obj.spatialseries = obj.validate_spatialseries(val);
    end
    %% VALIDATORS
    
    function val = validate_spatialseries(obj, val)
        namedprops = struct();
        constrained = {'types.core.SpatialSeries'};
        types.util.checkSet('spatialseries', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.spatialseries.export(writer, fullpath, refs);
    end
end

end