classdef (Abstract) DynamicTableBase < handle
% DynamicTableBase - Non-generated base class for DynamicTable behavior.
%
% This class owns handwritten DynamicTable behavior that the generated
% schema class cannot express: row and column mutation helpers, row
% retrieval, table conversion, table clearing, and DynamicTable consistency
% validation.

    properties (Abstract)
        id
        colnames
        vectordata
    end
    
    methods
        function addRow(obj, columnName, columnValue, options)
        % addRow - Add a single row to the DynamicTable.
        %
        % Syntax:
        %  dynamicTable.addRow(columnName, columnValue, ..., columnNameN, columnValueN)
        %  append a single row to the DynamicTable.
        %
        %  dynamicTable.addRow(__, Name, Value) add a row, providing an
        %  optional value for the 'id' using the optional 'id' name-value
        %  argument
        %
        % Input Arguments (Repeating):
        %  - columnName (string) -
        %    Name of a column in the table.
        %
        %  - columnValue (any) -
        %    Corresponding value for the preceding columnName.
        %
        % Name-Value Arguments:
        %  - id (int) -
        %    A custom value for the id of the row being added.

            arguments
                obj (1,1) matnwb.neurodata.DynamicTableBase {matnwb.common.validation.mustBeDynamicTable}
            end
            arguments (Repeating)
                columnName (1,1) string
                columnValue
            end
            arguments
                options.id
            end

            assert(~isempty(columnName), ...
                'NWB:DynamicTable:AddRow:NoData', 'Not enough arguments')
            
            obj.assertIsEditable('NWB:DynamicTable:AddRow:Uneditable')

            assert(~isempty(obj.colnames), ...
                'NWB:DynamicTable:AddRow:NoColumns',...
                ['The `colnames` property of the DynamicTable needs to be ', ...
                'populated with a cell array of column names before being ', ...
                'able to add row data.'])

            obj.ensureDynamicTableConsistency()

            columnValuePairs = [columnName; columnValue];
            optionalArgs = namedargs2cell(options);
            
            types.util.dynamictable.addVarargRow(obj, columnValuePairs{:}, optionalArgs{:});
        end

        function addColumn(obj, columnName, columnVector)
        % addColumn - Add one or more columns to the DynamicTable.
        %
        %  Given a dynamic table and a set of keyword arguments for one or
        %  more columns, add one or more columns to the dynamic table by 
        %  providing name-value pairs where the name is a column name and
        %  the value is a column vector
        %
        % Syntax:
        %  dynamicTable.addColumn(columnName, columnVector) 
        %  add a single column to the DynamicTable.
        %
        %  dynamicTable.addColumn(columnName, columnVector, ..., columnNameN, columnVectorN) 
        %  add many new columns to the DynamicTable
        %
        % Input Arguments (Repeating):
        %  - columnName (string) -
        %    Name of the new column in the table.
        %
        %  - columnVector (VectorData | VectorIndex) -
        %    Corresponding VectorData or VectorIndex for the new column
        %
        % Note:
        %   The height of the columns to be appended must match the height of 
        %   the existing columns

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
            end

            arguments (Repeating)
                columnName (1,1) string
                columnVector
            end

            assert(~isempty(columnName), ...
                'NWB:DynamicTable:AddColumn:NoData', 'Not enough arguments')
            
            if isempty(obj.id)
                types.util.dynamictable.internal.initDynamicTableId(obj);
            end
            
            obj.assertIsEditable('NWB:DynamicTable:AddColumn:Uneditable')
        
            columnVectorPairs = [columnName; columnVector];
            types.util.dynamictable.addVarargColumn(obj, columnVectorPairs{:});
        end

        function addRaggedArray(obj, columnName, data, options)
        % addRaggedArray - Add a ragged-array column to the DynamicTable.
        %
        % A ragged array stores a variable number of elements per row. The
        % values are held in a single VectorData column, and a companion
        % VectorIndex ('<columnName>_index') marks each row's boundary. With
        % Depth 2 the column is doubly ragged: each row holds a variable
        % number of sub-groups, each with a variable number of elements, and a
        % second VectorIndex ('<columnName>_index_index') marks the rows. The
        % Units 'waveforms' column is the canonical doubly ragged column. See
        % the "Tables and ragged arrays" and "Doubly ragged arrays" sections
        % of the NWB format specification.
        %
        % Syntax:
        %  dynamicTable.addRaggedArray(columnName, data) build and add a
        %  ragged column named columnName, plus its VectorIndex.
        %
        %  dynamicTable.addRaggedArray(__, Name, Value) provide optional
        %  arguments (see below).
        %
        % Input Arguments:
        %  - columnName (string) -
        %    Name of the new column.
        %
        %  - data (cell | numeric | text | table | struct) -
        %    A cell array with one cell per row, holding that row's elements
        %    in the orientation of VectorData.data: a vector of scalars (e.g.
        %    {[1 2 3], [4 5]} for a 2-row table), an [elementDims x nElements]
        %    array with the ragged axis last, text, or compound data (a table
        %    or struct). With Depth 2 each cell holds the row's sub-groups,
        %    either as a cell of [elementDims x nElements] arrays or as one
        %    [elementDims x nElements x nSubGroups] array. With ElementsPerRow,
        %    data is instead the elements of all rows in row order. See
        %    util.create_indexed_column for all accepted forms.
        %
        % Name-Value Arguments:
        %  - description (string) -
        %    Description stored on the VectorData column.
        %
        %  - table (DynamicTable) -
        %    If provided, the column is created as a DynamicTableRegion that
        %    references this table (row indices) instead of a VectorData.
        %
        %  - Depth (integer) -
        %    Number of VectorIndex levels: 1 (default) for a ragged column,
        %    2 for a doubly ragged column.
        %
        %  - ElementsPerRow (vector of non-negative integers) -
        %    Number of elements in each row, for data that is already flat:
        %    data then holds the elements of all rows in row order, and the
        %    column has depth 1. For example, pixel masks as one table of all
        %    pixels plus the number of pixels of each ROI.
        %
        % See also util.create_indexed_column, addColumn, addDoublyRaggedArray

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data
                options.description (1,1) string = "no description"
                options.table = []
                options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
                options.ElementsPerRow {mustBeNumeric, mustBeInteger, mustBeNonnegative} = []
            end

            columns = cell(1, options.Depth + 1);
            [columns{:}] = util.create_indexed_column(data, ...
                char(options.description), options.table, ...
                'Depth', options.Depth, 'ElementsPerRow', options.ElementsPerRow);

            % The data column, then one index level per depth: '<name>_index',
            % '<name>_index_index', ...
            names = strings(1, options.Depth + 1);
            names(1) = columnName;
            for iLevel = 1:options.Depth
                names(iLevel + 1) = names(iLevel) + "_index";
            end
            pairs = [num2cell(names); columns];
            obj.addColumn(pairs{:});
        end

        function addDoublyRaggedArray(obj, columnName, data, options)
        % addDoublyRaggedArray - Add a doubly-ragged-array column to the DynamicTable.
        %
        % Equivalent to addRaggedArray(columnName, data, 'Depth', 2). See
        % addRaggedArray for the accepted forms of data.
        %
        % See also addRaggedArray

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data cell
                options.description (1,1) string = "no description"
            end

            obj.addRaggedArray(columnName, data, ...
                'description', options.description, 'Depth', 2);
        end

        function row = getRow(obj, rowIndices, options)
        % getRow - Return one or more DynamicTable rows.
        %
        % Syntax:
        %  dynamicTable.getRow(rowIndices) return one or more rows of the
        %  table given a scalar row index or a list of row indices.
        %
        %  dynamicTable.getRow(rowIndices, Name, Value) get rows providing 
        %  optional name-value pairs for customization (see Input Arguments).
        %
        % Input Arguments:
        %  - rowIndices (double) -
        %    A scalar index or a vector of row indices for rows to extract.
        %    Must be positive integers, respecting the row count of the table.
        %
        %  - options (name-value pairs) -
        %    Optional name-value pairs. Available options:
        %
        %    - columns (string) -
        %      A list of names of columns to retrieve. Allows for only 
        %      grabbing certain columns instead of returning all columns.
        %
        %    - useId (logical) -
        %      If true, rowIndices refer to the table's id column instead
        %      of the MATLAB-based row indices.
        %
        % Output Arguments:
        %  - row (table) -
        %    A table of specified rows, with columns ordered according to
        %    the DynamicTable's colnames property, or the values given for 
        %    the "columns" option if provided.

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                rowIndices (1,:) double {mustBeInteger}
                options.columns (1,:)
                options.useId (1,1) logical
            end

            nvPairs = namedargs2cell(options);
            row = types.util.dynamictable.getRow(obj, rowIndices, nvPairs{:});
        end

        function table = toTable(obj, keepRegionsIndexed)
        % toTable - Convert the DynamicTable to a MATLAB table.
        %
        % Syntax:
        %  dynamicTable.toTable() converts the DynamicTable object to a
        %  MATLAB table. DynamicTableRegion columns are kept as index
        %  references by default.
        %
        %  dynamicTable.toTable(keepRegionsIndexed) controls how
        %  DynamicTableRegion columns are represented (see Input Arguments).
        %
        % Input Arguments:
        %  - keepRegionsIndexed (logical) -
        %    When true (default), each DynamicTableRegion column is preserved
        %    as row indices into the referenced table. When false, each
        %    DynamicTableRegion column is expanded into a nested subtable of
        %    the referenced rows.

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                keepRegionsIndexed (1,1) logical = true
            end

            table = types.util.dynamictable.nwbToTable(obj, keepRegionsIndexed);
        end

        function clear(obj)
        % clear - Remove all rows and column data from the DynamicTable.
        %
        % Syntax:
        %  dynamicTable.clear() removes all column objects and the row ids
        %  of the table.
        %
        % The following is removed:
        %  - Every VectorData and VectorIndex column, both columns defined
        %    by the schema (for example `start_time` of a TimeIntervals
        %    table) and columns added by the user.
        %  - All row ids. The `id` property is reset to an
        %    ElementIdentifiers object without data.
        %
        % The following is preserved:
        %  - The `colnames` property, so rows can be added to the same
        %    columns again with addRow.
        %  - The `description` and other attributes of the table.

            types.util.dynamictable.clear(obj);
        end
    end
    
    methods (Hidden)
        function columnNames = getSchemaDefinedColumns(obj)
        % getSchemaDefinedColumns - Return schema-defined column names.
        %
        % Generated DynamicTable classes declare their local schema column
        % names as private constants. Aggregate them across the generated
        % neurodata type hierarchy so inherited columns are included.

            import matnwb.neurodata.internal.collectConstantPropertiesAcrossHierarchy

            columnNames = collectConstantPropertiesAcrossHierarchy( ...
                class(obj), 'DeclaredSchemaColumns');
        end

        function ensureDynamicTableConsistency(obj)
        % ensureDynamicTableConsistency - Ensure DynamicTable column consistency.
        %
        % This method validates column registration, row-height consistency,
        % compound column shape, VectorIndex chains, and id height. It may
        % also initialize missing ids when the table height can be inferred
        % from materialized columns.

            types.util.dynamictable.checkConfig(obj);
        end
    end

    methods (Access = {?matnwb.mixin.HasUnnamedGroups, ?matnwb.neurodata.AlignedDynamicTableBase})
        function wasHandled = handleUnnamedGroupAdd(obj, groupName, name, value)
        % handleUnnamedGroupAdd - Route vectordata additions through addColumn.

            arguments
                obj (1,1) matnwb.neurodata.DynamicTableBase
                groupName (1,1) string
                name (1,1) string
                value
            end

            wasHandled = false;

            if groupName ~= "vectordata"
                return
            end

            if ~isa(value, 'types.hdmf_common.VectorData') && ~isa(value, 'types.core.VectorData')
                return
            end

            obj.addColumn(name, value)
            wasHandled = true;
        end

        function tip = getCustomUnnamedGroupAddTip(~, groupName)
        % getCustomUnnamedGroupAddTip - Display the preferred column add method.

            arguments
                ~
                groupName (1,1) string
            end

            if groupName == "vectordata"
                tip = "Tip: Use the 'addColumn' method to add column data.";
            else
                tip = "Tip: Use the 'add' method to add data objects to this group.";
            end
        end
    end

    methods (Access = private)
        function assertIsEditable(obj, errorID)
            arguments
                obj (1,1) matnwb.neurodata.DynamicTableBase
                errorID (1,1) string = "NWB:DynamicTable:Uneditable"
            end

            % A table without an id object has no rows on file.
            isEditable = isempty(obj.id) || ~isa(obj.id.data, 'types.untyped.DataStub');

            assert(isEditable, errorID, ...
                ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
                'If this was produced with pynwb, please enable chunking for this table.']);
        end
    end
end
