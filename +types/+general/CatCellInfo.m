classdef CatCellInfo < types.core.NWBDataInterface
% CatCellInfo Categorical Cell Info

% READONLY
properties(SetAccess=protected)
    indices_values; % values that the indices are indexing
end
% PROPERTIES
properties
    cell_index; % global id for neuron
    indices; % list of indices for values
end
methods
    function obj = CatCellInfo(varargin)
        % CATCELLINFO Constructor for CatCellInfo
        %     obj = CATCELLINFO(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        
        % indices = int64
        % cell_index = int64
        % indices_values = char
        obj = obj@types.core.NWBDataInterface(varargin{:});
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'indices', []);
        addParameter(p, 'cell_index', []);
        addParameter(p, 'indices_values', []);
        parse(p, varargin{:});
        obj.indices = p.Results.indices;
        obj.cell_index = p.Results.cell_index;
        obj.indices_values = p.Results.indices_values;
    end
    %% SETTERS
    function obj = set.cell_index(obj, val)
        obj.cell_index = obj.validate_cell_index(val);
    end
    function obj = set.indices(obj, val)
        obj.indices = obj.validate_indices(val);
    end
    %% VALIDATORS
    
    function val = validate_cell_index(obj, val)
        val = types.util.checkDtype('cell_index', 'int64', val);
        valsz = size(val);
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_indices(obj, val)
        val = types.util.checkDtype('indices', 'int64', val);
        valsz = size(val);
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_indices_values(obj, val)
        val = types.util.checkDtype('indices_values', 'char', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.general.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.cell_index)
            if startsWith(class(obj.cell_index), 'types.untyped.')
                refs = obj.cell_index.export(fid, [fullpath '/cell_index'], refs);
            elseif ~isempty(obj.cell_index)
                io.writeDataset(fid, [fullpath '/cell_index'], class(obj.cell_index), obj.cell_index);
            end
        end
        if startsWith(class(obj.indices), 'types.untyped.')
            refs = obj.indices.export(fid, [fullpath '/indices'], refs);
        elseif ~isempty(obj.indices)
            io.writeDataset(fid, [fullpath '/indices'], class(obj.indices), obj.indices);
        end
        if ~isempty(obj.indices_values) && ~isempty(obj.indices)
            io.writeAttribute(fid, 'char', [fullpath '/indices/values'], obj.indices_values);
        end
    end
end
end