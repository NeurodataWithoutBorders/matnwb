classdef OptogeneticSeries < types.core.TimeSeries & types.untyped.GroupClass
% OPTOGENETICSERIES An optogenetic stimulus.


% OPTIONAL PROPERTIES
properties
    site; %  OptogeneticStimulusSite
end

methods
    function obj = OptogeneticSeries(varargin)
        % OPTOGENETICSERIES Constructor for OptogeneticSeries
        varargin = [{'data_unit' 'watts'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'site',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.data_unit = p.Results.data_unit;
        obj.site = p.Results.site;
        if strcmp(class(obj), 'types.core.OptogeneticSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.site(obj, val)
        obj.site = obj.validate_site(val);
    end
    %% VALIDATORS
    
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
        validshapes = {[Inf,Inf], [Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'watts')
            val = 'watts';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.OptogeneticSeries">OptogeneticSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_site(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('site', 'types.core.OptogeneticStimulusSite', val.target);
            end
        else
            val = types.util.checkDtype('site', 'types.core.OptogeneticStimulusSite', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.site.export(fid, [fullpath '/site'], refs);
    end
end

end