classdef DecompositionSeries < types.core.TimeSeries & types.untyped.GroupClass
% DECOMPOSITIONSERIES Spectral analysis of a time series, e.g. of an LFP or a speech signal.


% REQUIRED PROPERTIES
properties
    bands; % REQUIRED (DynamicTable) Table for describing the bands that this series was generated from. There should be one row in this table for each band.
    metric; % REQUIRED (char) The metric used, e.g. phase, amplitude, power.
end
% OPTIONAL PROPERTIES
properties
    source_channels; %  (DynamicTableRegion) DynamicTableRegion pointer to the channels that this decomposition series was generated from.
    source_timeseries; %  TimeSeries
end

methods
    function obj = DecompositionSeries(varargin)
        % DECOMPOSITIONSERIES Constructor for DecompositionSeries
        varargin = [{'data_unit' 'no unit'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'bands',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'metric',[]);
        addParameter(p, 'source_channels',[]);
        addParameter(p, 'source_timeseries',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.bands = p.Results.bands;
        obj.data = p.Results.data;
        obj.data_unit = p.Results.data_unit;
        obj.metric = p.Results.metric;
        obj.source_channels = p.Results.source_channels;
        obj.source_timeseries = p.Results.source_timeseries;
        if strcmp(class(obj), 'types.core.DecompositionSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.bands(obj, val)
        obj.bands = obj.validate_bands(val);
    end
    function set.metric(obj, val)
        obj.metric = obj.validate_metric(val);
    end
    function set.source_channels(obj, val)
        obj.source_channels = obj.validate_source_channels(val);
    end
    function set.source_timeseries(obj, val)
        obj.source_timeseries = obj.validate_source_timeseries(val);
    end
    %% VALIDATORS
    
    function val = validate_bands(obj, val)
        val = types.util.checkDtype('bands', 'types.hdmf_common.DynamicTable', val);
    end
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
        validshapes = {[Inf,Inf,Inf]};
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
    function val = validate_metric(obj, val)
        val = types.util.checkDtype('metric', 'char', val);
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
    function val = validate_source_channels(obj, val)
        val = types.util.checkDtype('source_channels', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_source_timeseries(obj, val)
        val = types.util.checkDtype('source_timeseries', 'types.core.TimeSeries', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.bands.export(fid, [fullpath '/bands'], refs);
        if startsWith(class(obj.metric), 'types.untyped.')
            refs = obj.metric.export(fid, [fullpath '/metric'], refs);
        elseif ~isempty(obj.metric)
            io.writeDataset(fid, [fullpath '/metric'], obj.metric);
        end
        if ~isempty(obj.source_channels)
            refs = obj.source_channels.export(fid, [fullpath '/source_channels'], refs);
        end
        if ~isempty(obj.source_timeseries)
            refs = obj.source_timeseries.export(fid, [fullpath '/source_timeseries'], refs);
        end
    end
end

end