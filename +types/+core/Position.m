classdef Position < types.core.NWBDataInterface & types.untyped.GroupClass
% POSITION - Position data, whether along the x, x/y or x/y/z axis.
%
% Required Properties:
%  spatialseries


% REQUIRED PROPERTIES
properties
    spatialseries; % REQUIRED (SpatialSeries) SpatialSeries object containing position data.
end

methods
    function obj = Position(varargin)
        % POSITION - Constructor for Position
        %
        % Syntax:
        %  position = types.core.POSITION() creates a Position object with unset property values.
        %
        %  position = types.core.POSITION(Name, Value) creates a Position object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - spatialseries (SpatialSeries) - SpatialSeries object containing position data.
        %
        % Output Arguments:
        %  - position (types.core.Position) - A Position object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.spatialseries, ivarargin] = types.util.parseConstrained(obj,'spatialseries', 'types.core.SpatialSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.Position')
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
        refs = obj.spatialseries.export(fid, fullpath, refs);
    end
end

end