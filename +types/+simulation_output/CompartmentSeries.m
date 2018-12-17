classdef CompartmentSeries < types.core.TimeSeries
% CompartmentSeries Stores continuous data in cell compartments


% PROPERTIES
properties
    compartment_position; % relative position of recording within a given cell
    element_id; % cell compartment ids corresponding to a given column in the data
    gid; % list of cell ids
    index_pointer; % index pointer
end

methods
    function obj = CompartmentSeries(varargin)
        % COMPARTMENTSERIES Constructor for CompartmentSeries
        %     obj = COMPARTMENTSERIES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % compartment_position = double
        % element_id = uint64
        % index_pointer = uint64
        % gid = uint64
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'compartment_position',[]);
        addParameter(p, 'element_id',[]);
        addParameter(p, 'index_pointer',[]);
        addParameter(p, 'gid',[]);
        parse(p, varargin{:});
        obj.compartment_position = p.Results.compartment_position;
        obj.element_id = p.Results.element_id;
        obj.index_pointer = p.Results.index_pointer;
        obj.gid = p.Results.gid;
        if strcmp(class(obj), 'types.simulation_output.CompartmentSeries')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.compartment_position(obj, val)
        obj.compartment_position = obj.validate_compartment_position(val);
    end
    function obj = set.element_id(obj, val)
        obj.element_id = obj.validate_element_id(val);
    end
    function obj = set.gid(obj, val)
        obj.gid = obj.validate_gid(val);
    end
    function obj = set.index_pointer(obj, val)
        obj.index_pointer = obj.validate_index_pointer(val);
    end
    %% VALIDATORS
    
    function val = validate_compartment_position(obj, val)
        val = types.util.checkDtype('compartment_position', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_element_id(obj, val)
        val = types.util.checkDtype('element_id', 'uint64', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_gid(obj, val)
        val = types.util.checkDtype('gid', 'uint64', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_index_pointer(obj, val)
        val = types.util.checkDtype('index_pointer', 'uint64', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = fliplr(val.dims);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.compartment_position)
            if startsWith(class(obj.compartment_position), 'types.untyped.')
                refs = obj.compartment_position.export(fid, [fullpath '/compartment_position'], refs);
            elseif ~isempty(obj.compartment_position)
                io.writeDataset(fid, [fullpath '/compartment_position'], class(obj.compartment_position), obj.compartment_position);
            end
        else
            error('Property `compartment_position` is required.');
        end
        if ~isempty(obj.element_id)
            if startsWith(class(obj.element_id), 'types.untyped.')
                refs = obj.element_id.export(fid, [fullpath '/element_id'], refs);
            elseif ~isempty(obj.element_id)
                io.writeDataset(fid, [fullpath '/element_id'], class(obj.element_id), obj.element_id);
            end
        else
            error('Property `element_id` is required.');
        end
        if ~isempty(obj.gid)
            if startsWith(class(obj.gid), 'types.untyped.')
                refs = obj.gid.export(fid, [fullpath '/gid'], refs);
            elseif ~isempty(obj.gid)
                io.writeDataset(fid, [fullpath '/gid'], class(obj.gid), obj.gid);
            end
        end
        if ~isempty(obj.index_pointer)
            if startsWith(class(obj.index_pointer), 'types.untyped.')
                refs = obj.index_pointer.export(fid, [fullpath '/index_pointer'], refs);
            elseif ~isempty(obj.index_pointer)
                io.writeDataset(fid, [fullpath '/index_pointer'], class(obj.index_pointer), obj.index_pointer);
            end
        else
            error('Property `index_pointer` is required.');
        end
    end
end

end