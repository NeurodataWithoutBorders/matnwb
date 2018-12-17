classdef HilbertSeries < types.core.ElectricalSeries
% HilbertSeries output of hilbert transform


% PROPERTIES
properties
    filter_centers; % in Hz
    filter_sigmas; % in Hz
    imaginary_data; % The imaginary component of the complex result of the hilbert transform
    phase_data; % The phase of the complex result of the hilbert transform
    real_data; % The real component of the complex result of the hilbert transform
end

methods
    function obj = HilbertSeries(varargin)
        % HILBERTSERIES Constructor for HilbertSeries
        %     obj = HILBERTSERIES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % filter_centers = double
        % filter_sigmas = double
        % imaginary_data = double
        % phase_data = double
        % real_data = double
        varargin = [{ 'data_unit' 'no units' 'help' 'ENTER HELP INFO HERE' } varargin];
        obj = obj@types.core.ElectricalSeries(varargin{:});
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'filter_centers', []);
        addParameter(p, 'filter_sigmas', []);
        addParameter(p, 'imaginary_data', []);
        addParameter(p, 'phase_data', []);
        addParameter(p, 'real_data', []);
        parse(p, varargin{:});
        obj.filter_centers = p.Results.filter_centers;
        obj.filter_sigmas = p.Results.filter_sigmas;
        obj.imaginary_data = p.Results.imaginary_data;
        obj.phase_data = p.Results.phase_data;
        obj.real_data = p.Results.real_data;
        if endsWith(class(obj), 'time_frequency.HilbertSeries')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.filter_centers(obj, val)
        obj.filter_centers = obj.validate_filter_centers(val);
    end
    function obj = set.filter_sigmas(obj, val)
        obj.filter_sigmas = obj.validate_filter_sigmas(val);
    end
    function obj = set.imaginary_data(obj, val)
        obj.imaginary_data = obj.validate_imaginary_data(val);
    end
    function obj = set.phase_data(obj, val)
        obj.phase_data = obj.validate_phase_data(val);
    end
    function obj = set.real_data(obj, val)
        obj.real_data = obj.validate_real_data(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf   Inf   Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_filter_centers(obj, val)
        val = types.util.checkDtype('filter_centers', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_filter_sigmas(obj, val)
        val = types.util.checkDtype('filter_sigmas', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_imaginary_data(obj, val)
        val = types.util.checkDtype('imaginary_data', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf   Inf   Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_phase_data(obj, val)
        val = types.util.checkDtype('phase_data', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf   Inf   Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_real_data(obj, val)
        val = types.util.checkDtype('real_data', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf   Inf   Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ElectricalSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        
        if ~isempty(obj.filter_centers)
            if startsWith(class(obj.filter_centers), 'types.untyped.')
                refs = obj.filter_centers.export(fid, [fullpath '/filter_centers'], refs);
            elseif ~isempty(obj.filter_centers)
                io.writeDataset(fid, [fullpath '/filter_centers'], class(obj.filter_centers), obj.filter_centers);
            end
        else
            error('Property `filter_centers` is required.');
        end
        
        if ~isempty(obj.filter_sigmas)
            if startsWith(class(obj.filter_sigmas), 'types.untyped.')
                refs = obj.filter_sigmas.export(fid, [fullpath '/filter_sigmas'], refs);
            elseif ~isempty(obj.filter_sigmas)
                io.writeDataset(fid, [fullpath '/filter_sigmas'], class(obj.filter_sigmas), obj.filter_sigmas);
            end
        else
            error('Property `filter_sigmas` is required.');
        end
        
        if ~isempty(obj.imaginary_data)
            if startsWith(class(obj.imaginary_data), 'types.untyped.')
                refs = obj.imaginary_data.export(fid, [fullpath '/imaginary_data'], refs);
            elseif ~isempty(obj.imaginary_data)
                io.writeDataset(fid, [fullpath '/imaginary_data'], class(obj.imaginary_data), obj.imaginary_data);
            end
        end
        
        if ~isempty(obj.phase_data)
            if startsWith(class(obj.phase_data), 'types.untyped.')
                refs = obj.phase_data.export(fid, [fullpath '/phase_data'], refs);
            elseif ~isempty(obj.phase_data)
                io.writeDataset(fid, [fullpath '/phase_data'], class(obj.phase_data), obj.phase_data);
            end
        end
        
        if ~isempty(obj.real_data)
            if startsWith(class(obj.real_data), 'types.untyped.')
                refs = obj.real_data.export(fid, [fullpath '/real_data'], refs);
            elseif ~isempty(obj.real_data)
                io.writeDataset(fid, [fullpath '/real_data'], class(obj.real_data), obj.real_data);
            end
        end
    end
end

end