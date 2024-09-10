classdef IntervalSeries < types.core.TimeSeries & types.untyped.GroupClass
% INTERVALSERIES Stores intervals of data. The timestamps field stores the beginning and end of intervals. The data field stores whether the interval just started (>0 value) or ended (<0 value). Different interval types can be represented in the same series by using multiple key values (eg, 1 for feature A, 2 for feature B, 3 for feature C, etc). The field data stores an 8-bit integer. This is largely an alias of a standard TimeSeries but that is identifiable as representing time intervals in a machine-readable way.



methods
    function obj = IntervalSeries(varargin)
        % INTERVALSERIES Constructor for IntervalSeries
        varargin = [{'data_resolution' types.util.correctType(-1, 'single') 'data_unit' 'n/a'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'data_resolution',[]);
        addParameter(p, 'data_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.data_resolution = p.Results.data_resolution;
        obj.data_unit = p.Results.data_unit;
        if strcmp(class(obj), 'types.core.IntervalSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'int8', val);
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
    function val = validate_data_resolution(obj, val)
        if isequal(val, -1)
            val = -1;
        else
            error('Unable to set the ''data_resolution'' property of class ''<a href="matlab:doc types.core.IntervalSeries">IntervalSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'n/a')
            val = 'n/a';
        else
            error('Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.IntervalSeries">IntervalSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end