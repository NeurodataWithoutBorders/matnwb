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
        % VectorIndex ('<columnName>_index') marks each row's boundary. See
        % the "Tables and ragged arrays" section of the NWB format
        % specification.
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
        %  - data (cell) -
        %    A cell array with one cell per row; each cell holds that row's
        %    elements (e.g. {[1 2 3], [4 5]} for a 2-row table).
        %
        % Name-Value Arguments:
        %  - description (string) -
        %    Description stored on the VectorData column.
        %
        %  - table (DynamicTable) -
        %    If provided, the column is created as a DynamicTableRegion that
        %    references this table (row indices) instead of a VectorData.
        %
        % See also util.create_indexed_column, addColumn, addDoublyRaggedArray

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data cell
                options.description (1,1) string = "no description"
                options.table = []
            end

            if isempty(options.table)
                [vector, index] = util.create_indexed_column( ...
                    data, char(options.description));
            else
                [vector, index] = util.create_indexed_column( ...
                    data, char(options.description), options.table);
            end
            obj.addColumn(columnName, vector, columnName + "_index", index);
        end

        function addDoublyRaggedArray(obj, columnName, data, options)
        % addDoublyRaggedArray - Add a doubly-ragged-array column to the DynamicTable.
        %
        % A doubly-ragged array stores, for each row, a variable number of
        % sub-groups, each holding a variable number of fixed-length elements
        % (e.g. the Units table 'waveforms' column: per unit, a variable number
        % of spike events, each with a waveform per electrode). It is backed by
        % a VectorData column and two VectorIndex levels
        % ('<columnName>_index' over sub-groups and '<columnName>_index_index'
        % over rows). See the "Doubly ragged arrays" section of the NWB format
        % specification.
        %
        % Syntax:
        %  dynamicTable.addDoublyRaggedArray(columnName, data) build and add a
        %  doubly-ragged column named columnName, plus its two VectorIndex
        %  levels.
        %
        % Input Arguments:
        %  - columnName (string) -
        %    Name of the new column.
        %
        %  - data (cell) -
        %    A cell array with one cell per row. Each cell is either a numeric
        %    matrix [nSubGroups x nSamples] (one element per sub-group), or a
        %    cell array whose j-th entry is a [nElements x nSamples] matrix for
        %    sub-group j. See util.create_doubly_indexed_column.
        %
        % Name-Value Arguments:
        %  - description (string) -
        %    Description stored on the VectorData column.
        %
        % See also util.create_doubly_indexed_column, addColumn, addRaggedArray

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data cell
                options.description (1,1) string = "no description"
            end

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column(data, options.description);

            % The number of rows equals the length of the outermost index.
            rowCount = numel(indexIndex.data);

            % Initialize id for a new table before checking editability (which
            % inspects the id column).
            if isempty(obj.id) || isempty(obj.id.data)
                types.util.dynamictable.internal.initDynamicTableId(obj, rowCount);
            end

            obj.assertIsEditable('NWB:DynamicTable:AddDoublyRaggedArray:Uneditable')

            tableHeight = types.util.dynamictable.internal.getColumnHeight(obj.id);
            assert(rowCount == tableHeight, ...
                'NWB:DynamicTable:AddDoublyRaggedArray:MissingRows', ...
                'Column `%s` has %d rows, but the table height is %d.', ...
                columnName, rowCount, tableHeight)

            % Assign the data column and both index levels to the appropriate
            % storage (a typed property for schema-defined columns such as
            % Units.waveforms, otherwise the generic vectordata set). addColumn
            % is not used here because its height check only follows a single
            % index level.
            names = [columnName, columnName + "_index", columnName + "_index_index"];
            values = {vector, index, indexIndex};
            for iName = 1:numel(names)
                thisName = char(names(iName));
                storageTarget = types.util.dynamictable.resolveColumnStorage( ...
                    obj, thisName, values{iName});
                switch storageTarget
                    case 'property'
                        obj.(thisName) = values{iName};
                    case 'vectordata'
                        obj.vectordata.set(thisName, values{iName});
                end
            end

            % Only the data column is listed in colnames; the index levels are
            % implicit. Schema-defined columns are added by a property post-set
            % hook, so guard against duplicates.
            if ~any(strcmp(obj.colnames, char(columnName)))
                obj.colnames{end+1} = char(columnName);
            end
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
        % clear - Remove all row and column data from the DynamicTable.
        %
        % Resets the table to an empty state: all VectorData columns,
        % VectorIndex columns, and row ids are cleared. The colnames
        % property is preserved.

            types.util.dynamictable.clear(obj);
        end
    end
    
    methods (Hidden)
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

    methods (Access = private)
        function assertIsEditable(obj, errorID)
            arguments
                obj (1,1) matnwb.neurodata.DynamicTableBase
                errorID (1,1) string = "NWB:DynamicTable:Uneditable"
            end

            isEditable = ~isa(obj.id.data, 'types.untyped.DataStub');

            assert(isEditable, errorID, ... 
                ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
                'If this was produced with pynwb, please enable chunking for this table.']);
        end
    end
end
