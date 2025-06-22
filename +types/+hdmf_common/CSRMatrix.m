classdef CSRMatrix < types.hdmf_common.Container & types.untyped.GroupClass
% CSRMATRIX - A compressed sparse row matrix. Data are stored in the standard CSR format, where column indices for row i are stored in indices[indptr[i]:indptr[i+1]] and their corresponding values are stored in data[indptr[i]:indptr[i+1]].
%
% Required Properties:
%  data, indices, indptr, shape


% REQUIRED PROPERTIES
properties
    data; % REQUIRED (any) The non-zero values in the matrix.
    indices; % REQUIRED (uint) The column indices.
    indptr; % REQUIRED (uint) The row index pointer.
    shape; % REQUIRED (uint) The shape (number of rows, number of columns) of this sparse matrix.
end

methods
    function obj = CSRMatrix(varargin)
        % CSRMATRIX - Constructor for CSRMatrix
        %
        % Syntax:
        %  cSRMatrix = types.hdmf_common.CSRMATRIX() creates a CSRMatrix object with unset property values.
        %
        %  cSRMatrix = types.hdmf_common.CSRMATRIX(Name, Value) creates a CSRMatrix object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (any) - The non-zero values in the matrix.
        %
        %  - indices (uint) - The column indices.
        %
        %  - indptr (uint) - The row index pointer.
        %
        %  - shape (uint) - The shape (number of rows, number of columns) of this sparse matrix.
        %
        % Output Arguments:
        %  - cSRMatrix (types.hdmf_common.CSRMatrix) - A CSRMatrix object
        
        obj = obj@types.hdmf_common.Container(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'indices',[]);
        addParameter(p, 'indptr',[]);
        addParameter(p, 'shape',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.indices = p.Results.indices;
        obj.indptr = p.Results.indptr;
        obj.shape = p.Results.shape;
        if strcmp(class(obj), 'types.hdmf_common.CSRMatrix')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    function set.indices(obj, val)
        obj.indices = obj.validate_indices(val);
    end
    function set.indptr(obj, val)
        obj.indptr = obj.validate_indptr(val);
    end
    function set.shape(obj, val)
        obj.shape = obj.validate_shape(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_indices(obj, val)
        val = types.util.checkDtype('indices', 'uint', val);
        types.util.validateShape('indices', {[Inf]}, val)
    end
    function val = validate_indptr(obj, val)
        val = types.util.checkDtype('indptr', 'uint', val);
        types.util.validateShape('indptr', {[Inf]}, val)
    end
    function val = validate_shape(obj, val)
        val = types.util.checkDtype('shape', 'uint', val);
        types.util.validateShape('shape', {[2]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.data), 'types.untyped.')
            refs = obj.data.export(fid, [fullpath '/data'], refs);
        elseif ~isempty(obj.data)
            io.writeDataset(fid, [fullpath '/data'], obj.data, 'forceArray');
        end
        if startsWith(class(obj.indices), 'types.untyped.')
            refs = obj.indices.export(fid, [fullpath '/indices'], refs);
        elseif ~isempty(obj.indices)
            io.writeDataset(fid, [fullpath '/indices'], obj.indices, 'forceArray');
        end
        if startsWith(class(obj.indptr), 'types.untyped.')
            refs = obj.indptr.export(fid, [fullpath '/indptr'], refs);
        elseif ~isempty(obj.indptr)
            io.writeDataset(fid, [fullpath '/indptr'], obj.indptr, 'forceArray');
        end
        io.writeAttribute(fid, [fullpath '/shape'], obj.shape, 'forceArray');
    end
end

end