function [data_vector, data_index] = create_indexed_column(data, description, table)
%CREATE_INDEXED_COLUMN creates the index and vector NWB objects for storing
%a ragged column in an NWB DynamicTable
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA)
%   expects DATA as a cell array with one cell per table row, holding that
%   row's elements. Each cell is one of:
%     - a numeric or logical vector (row or column): a list of scalar
%       elements. When every row is a vector, DATA_VECTOR.data is a column
%       vector holding all elements.
%     - a numeric or logical array [elementDims x nElements]: nElements
%       elements that each have the shape elementDims, with the ragged axis
%       last, in the same orientation as the data property of any MatNWB
%       VectorData. Rows are concatenated along that last dimension, so
%       DATA_VECTOR.data is [elementDims x totalElements]. On disk the ragged
%       axis then comes first, as the schema requires.
%     - a string array, character vector, struct array or array of objects
%       (such as types.untyped.ObjectView references) that is a vector: a
%       list of elements of that class, one per string, character, struct or
%       object. DATA_VECTOR.data keeps the class: a string column, a character
%       column, a struct column or an object column.
%     - [] for a row with no elements.
%   All rows must hold elements of the same type, and struct rows the same
%   fields. All array rows must share elementDims, which is taken from the first row
%   that is not a vector. A row holding a single element may be given with
%   its trailing dimension of 1 omitted (a column vector [k x 1] when elements
%   are k-sample vectors, a [k x m] matrix when elements are [k x m]).
%   EXAMPLE: [data_vector, data_index] = util.create_indexed_column({[1,2,3], [1,2,3,4]})
%     data_vector.data is [1;2;3;1;2;3;4] and data_index.data is [3;7].
%   EXAMPLE: [data_vector, data_index] = util.create_indexed_column({rand(4,2), rand(4,3)})
%     data_vector.data is [4 x 5] (five 4-sample elements) and data_index.data is [2;5].
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION)
%   adds the string DESCRIPTION in the description field of the data vector
%
%   [DYNAMICTABLEREGION, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION, TABLE)
%   If TABLE is supplied as on ObjectView of an NWB DynamicTable, a
%   DynamicTableRegion is instead output which references this table.
%   DynamicTableRegions can be indexed just like DataVectors

if ~exist('description', 'var') || isempty(description)
    description = 'no description';
end

[data, bounds] = flattenRows(data);

if exist('table', 'var')
    data_vector = types.hdmf_common.DynamicTableRegion( ...
        'table', types.untyped.ObjectView(table), ...
        'description', description, ...
        'data', data ...
    );
else
    data_vector = types.hdmf_common.VectorData( ...
        'data', data, ...
        'description', description ...
    );
end

ov = types.untyped.ObjectView(data_vector);
data_index = types.hdmf_common.VectorIndex( ...
    'data', bounds, ...
    'target', ov, ...
    'description', 'indexes data' ...
);
end

function [flatData, bounds] = flattenRows(rows)
    % Concatenate the rows along the ragged (last) axis and count the elements
    % of each row. BOUNDS is the cumulative element count, one entry per row.
    numRows = numel(rows);
    elementType = "";
    structFields = {};
    for iRow = 1:numRows
        row = rows{iRow};
        if isnumeric(row) || islogical(row)
            rowType = "numeric";
        elseif (isstring(row) || ischar(row) || isstruct(row) || isObjectArray(row)) ...
                && (isvector(row) || isempty(row))
            rowType = string(class(row));
        else
            error("NWB:CreateIndexedColumn:InvalidRow", ...
                "Each cell of DATA must be a numeric or logical array, or a vector of " + ...
                "strings, characters, structs or objects. Cell %d is a %s of size [%s].", ...
                iRow, class(row), join(string(size(row)), " "));
        end
        if isempty(row)
            continue
        end
        if elementType == ""
            elementType = rowType;
        elseif rowType ~= elementType
            error("NWB:CreateIndexedColumn:InconsistentElementType", ...
                "All rows must hold elements of the same type. Cell %d holds %s " + ...
                "elements, but an earlier row holds %s elements.", iRow, rowType, elementType);
        end
        if isstruct(row)
            if isempty(structFields)
                structFields = fieldnames(row);
            elseif ~isequal(sort(fieldnames(row)), sort(structFields))
                error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
                    "All struct rows must have the same fields. Cell %d has fields " + ...
                    "{%s}, but an earlier row has {%s}.", iRow, ...
                    strjoin(fieldnames(row), ", "), strjoin(structFields, ", "));
            end
        end
    end

    elementDims = findElementDims(rows);
    counts = zeros(numRows, 1);
    chunks = cell(1, numRows);
    for iRow = 1:numRows
        row = rows{iRow};
        if isempty(row)
            counts(iRow) = 0;
            chunks{iRow} = [];
        elseif isempty(elementDims)
            % Every row is a vector: a list of scalars, stacked into a column.
            counts(iRow) = numel(row);
            chunks{iRow} = row(:);
            if isstruct(row)
                % Concatenating structs needs the fields in the same order.
                chunks{iRow} = orderfields(chunks{iRow}, structFields);
            end
        else
            rowDims = size(row);
            if isequal(rowDims, elementDims)
                % A single element; MATLAB dropped the trailing dimension of 1.
                counts(iRow) = 1;
            elseif isequal(rowDims(1:end-1), elementDims)
                counts(iRow) = rowDims(end);
            else
                error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
                    "All elements must have the same shape. Expected elements of " + ...
                    "shape [%s], but row %d has size [%s]. Give the elements of a row " + ...
                    "as [elementShape x nElements], with the ragged axis last.", ...
                    join(string(elementDims), " "), iRow, join(string(rowDims), " "));
            end
            chunks{iRow} = row;
        end
    end
    bounds = uint64(cumsum(counts));

    nonEmptyChunks = chunks(counts > 0);
    if isempty(nonEmptyChunks)
        flatData = [];
    elseif isempty(elementDims)
        flatData = vertcat(nonEmptyChunks{:});
    else
        flatData = cat(numel(elementDims) + 1, nonEmptyChunks{:});
    end
end

function elementDims = findElementDims(rows)
    % The element shape, taken from the first row that is not a vector. Empty
    % when every row is a vector, i.e. the elements are scalars.
    elementDims = [];
    for iRow = 1:numel(rows)
        row = rows{iRow};
        if ~isempty(row) && ~isvector(row)
            rowDims = size(row);
            elementDims = rowDims(1:end-1);
            return
        end
    end
end

function tf = isObjectArray(row)
    % An array of objects such as types.untyped.ObjectView references. A
    % table is an object too, but its rows are not elements of one class.
    tf = isobject(row) && ~istable(row);
end
