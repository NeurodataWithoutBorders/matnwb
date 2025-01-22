classdef CompassDirection < types.core.NWBDataInterface & types.untyped.GroupClass
% COMPASSDIRECTION - With a CompassDirection interface, a module publishes a SpatialSeries object representing a floating point value for theta. The SpatialSeries::reference_frame field should indicate what direction corresponds to 0 and which is the direction of rotation (this should be clockwise). The si_unit for the SpatialSeries should be radians or degrees.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    spatialseries; %  (SpatialSeries) SpatialSeries object containing direction of gaze travel.
end

methods
    function obj = CompassDirection(varargin)
        % COMPASSDIRECTION - Constructor for CompassDirection
        %
        % Syntax:
        %  compassDirection = types.core.COMPASSDIRECTION() creates a CompassDirection object with unset property values.
        %
        %  compassDirection = types.core.COMPASSDIRECTION(Name, Value) creates a CompassDirection object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - spatialseries (SpatialSeries) - SpatialSeries object containing direction of gaze travel.
        %
        % Output Arguments:
        %  - compassDirection (types.core.CompassDirection) - A CompassDirection object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.spatialseries, ivarargin] = types.util.parseConstrained(obj,'spatialseries', 'types.core.SpatialSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.CompassDirection')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
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
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.spatialseries)
            refs = obj.spatialseries.export(fid, fullpath, refs);
        end
    end
end

end