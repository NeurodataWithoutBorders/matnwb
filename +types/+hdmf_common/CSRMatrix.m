classdef CSRMatrix < types.untyped.MetaClass
% CSRMATRIX a compressed sparse row matrix


% PROPERTIES
properties
    data; % values in the matrix
    indices; % column indices
    indptr; % index pointer
    shape; % the shape of this sparse matrix
end

methods
    function obj = CSRMatrix(varargin)
        % CSRMATRIX Constructor for CSRMatrix
        %     obj = CSRMATRIX(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % data = any
        % indices = int
        % indptr = int
        % shape = int
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'indices',[]);
        addParameter(p, 'indptr',[]);
        addParameter(p, 'shape',[]);
        parse(p, varargin{:});
        obj.data = p.Results.data;
        obj.indices = p.Results.indices;
        obj.indptr = p.Results.indptr;
        obj.shape = p.Results.shape;
        if strcmp(class(obj), 'types.hdmf_common.CSRMatrix')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    function obj = set.indices(obj, val)
        obj.indices = obj.validate_indices(val);
    end
    function obj = set.indptr(obj, val)
        obj.indptr = obj.validate_indptr(val);
    end
    function obj = set.shape(obj, val)
        obj.shape = obj.validate_shape(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    
    end
    function val = validate_indices(obj, val)
        val = types.util.checkDtype('indices', 'int', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_indptr(obj, val)
        val = types.util.checkDtype('indptr', 'int', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_shape(obj, val)
        val = types.util.checkDtype('shape', 'int', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.data)
            if startsWith(class(obj.data), 'types.untyped.')
                refs = obj.data.export(fid, [fullpath '/data'], refs);
            elseif ~isempty(obj.data)
                io.writeDataset(fid, [fullpath '/data'], obj.data);
            end
        else
            error('Property `data` is required.');
        end
        if ~isempty(obj.indices)
            if startsWith(class(obj.indices), 'types.untyped.')
                refs = obj.indices.export(fid, [fullpath '/indices'], refs);
            elseif ~isempty(obj.indices)
                io.writeDataset(fid, [fullpath '/indices'], obj.indices);
            end
        else
            error('Property `indices` is required.');
        end
        if ~isempty(obj.indptr)
            if startsWith(class(obj.indptr), 'types.untyped.')
                refs = obj.indptr.export(fid, [fullpath '/indptr'], refs);
            elseif ~isempty(obj.indptr)
                io.writeDataset(fid, [fullpath '/indptr'], obj.indptr);
            end
        else
            error('Property `indptr` is required.');
        end
        if ~isempty(obj.shape)
            io.writeAttribute(fid, [fullpath '/shape'], obj.shape);
        else
            error('Property `shape` is required.');
        end
    end
end

end