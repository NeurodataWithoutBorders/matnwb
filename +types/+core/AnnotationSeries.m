classdef AnnotationSeries < types.core.TimeSeries & types.untyped.GroupClass
% ANNOTATIONSERIES Stores user annotations made during an experiment. The data[] field stores a text array, and timestamps are stored for each annotation (ie, interval=1). This is largely an alias to a standard TimeSeries storing a text array but that is identifiable as storing annotations in a machine-readable way.



methods
    function obj = AnnotationSeries(varargin)
        % ANNOTATIONSERIES Constructor for AnnotationSeries
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
        if strcmp(class(obj), 'types.core.AnnotationSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'char', val);
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
            error('Unable to set the ''data_resolution'' property of class ''<a href="matlab:doc types.core.AnnotationSeries">AnnotationSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'n/a')
            val = 'n/a';
        else
            error('Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.AnnotationSeries">AnnotationSeries</a>'' because it is read-only.')
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