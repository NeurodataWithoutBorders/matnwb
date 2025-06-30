classdef FrequencyBandsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% FREQUENCYBANDSTABLE - Table for describing the bands that DecompositionSeries was generated from. There should be one row in this table for each band.
%
% Required Properties:
%  band_limits, band_name, colnames, description, id


% REQUIRED PROPERTIES
properties
    band_limits; % REQUIRED (VectorData) Low and high limit of each band in Hz. If it is a Gaussian filter, use 2 SD on either side of the center.
    band_name; % REQUIRED (VectorData) Name of the band, e.g. theta.
end
% OPTIONAL PROPERTIES
properties
    band_mean; %  (VectorData) The mean Gaussian filters, in Hz.
    band_stdev; %  (VectorData) The standard deviation of Gaussian filters, in Hz.
end

methods
    function obj = FrequencyBandsTable(varargin)
        % FREQUENCYBANDSTABLE - Constructor for FrequencyBandsTable
        %
        % Syntax:
        %  frequencyBandsTable = types.core.FREQUENCYBANDSTABLE() creates a FrequencyBandsTable object with unset property values.
        %
        %  frequencyBandsTable = types.core.FREQUENCYBANDSTABLE(Name, Value) creates a FrequencyBandsTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - band_limits (VectorData) - Low and high limit of each band in Hz. If it is a Gaussian filter, use 2 SD on either side of the center.
        %
        %  - band_mean (VectorData) - The mean Gaussian filters, in Hz.
        %
        %  - band_name (VectorData) - Name of the band, e.g. theta.
        %
        %  - band_stdev (VectorData) - The standard deviation of Gaussian filters, in Hz.
        %
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - frequencyBandsTable (types.core.FrequencyBandsTable) - A FrequencyBandsTable object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'band_limits',[]);
        addParameter(p, 'band_mean',[]);
        addParameter(p, 'band_name',[]);
        addParameter(p, 'band_stdev',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.band_limits = p.Results.band_limits;
        obj.band_mean = p.Results.band_mean;
        obj.band_name = p.Results.band_name;
        obj.band_stdev = p.Results.band_stdev;
        if strcmp(class(obj), 'types.core.FrequencyBandsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.FrequencyBandsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.band_limits(obj, val)
        obj.band_limits = obj.validate_band_limits(val);
    end
    function set.band_mean(obj, val)
        obj.band_mean = obj.validate_band_mean(val);
    end
    function set.band_name(obj, val)
        obj.band_name = obj.validate_band_name(val);
    end
    function set.band_stdev(obj, val)
        obj.band_stdev = obj.validate_band_stdev(val);
    end
    %% VALIDATORS
    
    function val = validate_band_limits(obj, val)
        val = types.util.checkDtype('band_limits', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_band_mean(obj, val)
        val = types.util.checkDtype('band_mean', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_band_name(obj, val)
        val = types.util.checkDtype('band_name', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_band_stdev(obj, val)
        val = types.util.checkDtype('band_stdev', 'types.hdmf_common.VectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.band_limits.export(fid, [fullpath '/band_limits'], refs);
        if ~isempty(obj.band_mean)
            refs = obj.band_mean.export(fid, [fullpath '/band_mean'], refs);
        end
        refs = obj.band_name.export(fid, [fullpath '/band_name'], refs);
        if ~isempty(obj.band_stdev)
            refs = obj.band_stdev.export(fid, [fullpath '/band_stdev'], refs);
        end
    end
end

end