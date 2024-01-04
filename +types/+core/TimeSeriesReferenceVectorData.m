classdef TimeSeriesReferenceVectorData < types.hdmf_common.VectorData & types.untyped.DatasetClass
% TIMESERIESREFERENCEVECTORDATA Column storing references to a TimeSeries (rows). For each TimeSeries this VectorData column stores the start_index and count to indicate the range in time to be selected as well as an object reference to the TimeSeries.



methods
    function obj = TimeSeriesReferenceVectorData(varargin)
        % TIMESERIESREFERENCEVECTORDATA Constructor for TimeSeriesReferenceVectorData
        obj = obj@types.hdmf_common.VectorData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.core.TimeSeriesReferenceVectorData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        if isempty(val) || isa(val, 'types.untyped.DataStub')
            return;
        end
        if ~istable(val) && ~isstruct(val) && ~isa(val, 'containers.Map')
            error('Property `data` must be a table,struct, or containers.Map.');
        end
        vprops = struct();
        vprops.idx_start = 'int32';
        vprops.count = 'int32';
        vprops.timeseries = 'types.untyped.ObjectView';
        val = types.util.checkDtype('data', vprops, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.VectorData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end