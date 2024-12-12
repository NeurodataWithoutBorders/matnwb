classdef DfOverF < types.core.NWBDataInterface & types.untyped.GroupClass
% DFOVERF - dF/F information about a region of interest (ROI). Storage hierarchy of dF/F should be the same as for segmentation (i.e., same names for ROIs and for image planes).
%
% Required Properties:
%  roiresponseseries


% REQUIRED PROPERTIES
properties
    roiresponseseries; % REQUIRED (RoiResponseSeries) RoiResponseSeries object(s) containing dF/F for a ROI.
end

methods
    function obj = DfOverF(varargin)
        % DFOVERF - Constructor for DfOverF
        %
        % Syntax:
        %  dfOverF = types.core.DFOVERF() creates a DfOverF object with unset property values.
        %
        %  dfOverF = types.core.DFOVERF(Name, Value) creates a DfOverF object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - roiresponseseries (RoiResponseSeries) - RoiResponseSeries object(s) containing dF/F for a ROI.
        %
        % Output Arguments:
        %  - dfOverF (types.core.DfOverF) - A DfOverF object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.roiresponseseries, ivarargin] = types.util.parseConstrained(obj,'roiresponseseries', 'types.core.RoiResponseSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.DfOverF')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.roiresponseseries(obj, val)
        obj.roiresponseseries = obj.validate_roiresponseseries(val);
    end
    %% VALIDATORS
    
    function val = validate_roiresponseseries(obj, val)
        namedprops = struct();
        constrained = {'types.core.RoiResponseSeries'};
        types.util.checkSet('roiresponseseries', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.roiresponseseries.export(fid, fullpath, refs);
    end
end

end