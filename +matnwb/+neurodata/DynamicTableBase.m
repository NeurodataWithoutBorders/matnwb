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
        %  - columnVector (VectorData | VectorIndex | types.untyped.abstract.ExpandableTableColumn) -
        %    Corresponding VectorData or VectorIndex for the new column. An
        %    ExpandableTableColumn, such as a types.untyped.RaggedArrayColumn,
        %    adds the column together with the objects it is stored with, for
        %    example '<columnName>_index'.
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
            columnVectorPairs = types.util.dynamictable.expandTableColumns(columnVectorPairs(:)');
            types.util.dynamictable.addVarargColumn(obj, columnVectorPairs{:});
        end

        function addRaggedArrayColumn(obj, columnName, data, options)
        % addRaggedArrayColumn - Add a ragged or doubly ragged column to the DynamicTable.
        %
        % Syntax:
        %  dynamicTable.addRaggedArrayColumn(columnName, data) Adds a column in
        %  which each row holds a variable number of elements. The elements of
        %  all rows are stored in one VectorData named columnName, and a
        %  VectorIndex named '<columnName>_index' stores where each row ends.
        %
        %  dynamicTable.addRaggedArrayColumn(columnName, data, Name, Value) Adds
        %  the column using optional name-value pairs. With Depth 2 the column
        %  is doubly ragged, like the 'waveforms' column of Units: each row holds
        %  a variable number of sub-groups, and each sub-group holds a variable
        %  number of elements. '<columnName>_index' then stores where each
        %  sub-group ends, and a second VectorIndex named
        %  '<columnName>_index_index' stores where each row ends.
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
        %  - options (name-value pairs) -
        %    Optional name-value pairs. Available options:
        %
        %    - Description (string) -
        %      Description stored on the VectorData column. Default: "no description".
        %
        %    - TargetTable (DynamicTable) -
        %      If provided, the column is created as a DynamicTableRegion
        %      instead of a VectorData, and the values in data are 0-based row
        %      indices into this table.
        %
        %    - Depth (integer) -
        %      Number of VectorIndex levels: 1 (default) for a ragged column,
        %      2 for a doubly ragged column.
        %
        %    - ElementsPerRow (vector of non-negative integers) -
        %      Number of elements in each row, for data that is already flat:
        %      data then holds the elements of all rows in row order, and the
        %      column has depth 1. For example, pixel masks as one table of all
        %      pixels plus the number of pixels of each ROI.
        %
        %    - ElementsPerSubGroup (positive integer | vector of positive integers) -
        %      Number of elements in each sub-group of the numeric rows of a
        %      column with Depth 2, as one value or one value per row. A row is
        %      then [elementDims x nElements], with nElements a multiple of the
        %      row's value, or [elementDims x value x nSubGroups]. For the Units
        %      'waveforms' column this is the number of electrodes of each
        %      unit. Without it, the number is read from the dimensions of the
        %      rows.
        %
        % Usage:
        %  Example 1 - Add spike times for two units with 3 and 2 spikes::
        %
        %    units = types.core.Units('colnames', {}, 'description', 'units');
        %    units.addRaggedArrayColumn('spike_times', {[0.1 0.2 0.3], [0.5 0.6]});
        %
        %  Example 2 - Add electrode references for the same two units::
        %
        %    % electrodeTable is a DynamicTable with 4 rows. Row indices start at 0.
        %    units.addRaggedArrayColumn('electrodes', {[0 1 2], 3}, 'TargetTable', electrodeTable);
        %
        %  Example 3 - Add waveforms for the same two units, with 2 and 3 spike events on 3 electrodes::
        %
        %    % Each spike event is a [num_samples x num_electrodes] matrix.
        %    unit1 = {rand(40, 3), rand(40, 3)};
        %    unit2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
        %    units.addRaggedArrayColumn('waveforms', {unit1, unit2}, 'Depth', 2);
        %
        %  Example 4 - Add waveforms as one [num_samples x num_electrodes x num_spike_events] array per unit::
        %
        %    units = types.core.Units('colnames', {}, 'description', 'units');
        %    units.addRaggedArrayColumn('waveforms', {rand(40, 3, 2), rand(40, 3, 3)}, 'Depth', 2);
        %
        %  Example 5 - Add pixel masks from one table of all pixels and the number of pixels of each ROI::
        %
        %    % 5 pixels: the first 3 belong to ROI 1, the last 2 to ROI 2.
        %    pixels = table(uint32([1; 2; 3; 7; 8]), uint32([4; 4; 5; 9; 9]), single([1; 1; 0.5; 1; 1]), ...
        %        'VariableNames', {'x', 'y', 'weight'});
        %    planeSegmentation = types.core.PlaneSegmentation('description', 'rois');
        %    planeSegmentation.addRaggedArrayColumn('pixel_mask', pixels, 'ElementsPerRow', [3 2]);
        %
        % See also:
        %   util.create_indexed_column, addColumn, addDoublyRaggedArrayColumn

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data
                options.Description (1,1) string = "no description"
                options.TargetTable {mustBeEmptyOrDynamicTable} = []
                options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
                options.ElementsPerRow {mustBeNumeric, mustBeInteger, mustBeNonnegative}
                options.ElementsPerSubGroup {mustBeNumeric, mustBeInteger, mustBePositive}
            end

            columnOptions = namedargs2cell(options);
            obj.addColumn(columnName, types.untyped.RaggedArrayColumn(data, columnOptions{:}));
        end

        function addDoublyRaggedArrayColumn(obj, columnName, data, options)
        % addDoublyRaggedArrayColumn - Add a doubly ragged column to the DynamicTable.
        %
        % Syntax:
        %  dynamicTable.addDoublyRaggedArrayColumn(columnName, data) Adds a
        %  column in which each row holds a variable number of sub-groups, and
        %  each sub-group holds a variable number of elements. It is the same as
        %  dynamicTable.addRaggedArrayColumn(columnName, data, 'Depth', 2).
        %
        %  dynamicTable.addDoublyRaggedArrayColumn(columnName, data, Name,
        %  Value) Adds the column using optional name-value pairs.
        %
        % Input Arguments:
        %  - columnName (string) -
        %    Name of the new column.
        %
        %  - data (cell) -
        %    A cell array with one cell per row, holding that row's sub-groups,
        %    either as a cell of [elementDims x nElements] arrays or as one
        %    [elementDims x nElements x nSubGroups] array. See addRaggedArrayColumn.
        %
        %  - options (name-value pairs) -
        %    Optional name-value pairs. Available options:
        %
        %    - Description (string) -
        %      Description stored on the VectorData column. Default: "no description".
        %
        %    - ElementsPerSubGroup (positive integer | vector of positive integers) -
        %      Number of elements in each sub-group of the numeric rows. See
        %      addRaggedArrayColumn.
        %
        % Usage:
        %  Example 1 - Add waveforms for two units with 2 and 3 spike events on 3 electrodes::
        %
        %    % Each spike event is a [num_samples x num_electrodes] matrix.
        %    units = types.core.Units('colnames', {}, 'description', 'units');
        %    unit1 = {rand(40, 3), rand(40, 3)};
        %    unit2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
        %    units.addDoublyRaggedArrayColumn('waveforms', {unit1, unit2});
        %
        % See also:
        %   addRaggedArrayColumn

            arguments
                obj (1,1) {matnwb.common.validation.mustBeDynamicTable}
                columnName (1,1) string
                data cell
                options.Description (1,1) string = "no description"
                options.ElementsPerSubGroup {mustBeNumeric, mustBeInteger, mustBePositive}
            end

            forwardedOptions = namedargs2cell(options);
            obj.addRaggedArrayColumn(columnName, data, forwardedOptions{:}, 'Depth', 2);
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

function mustBeEmptyOrDynamicTable(value)
    % The table that a DynamicTableRegion column references, or empty for a
    % VectorData column.
    if ~isempty(value)
        matnwb.common.validation.mustBeDynamicTable(value)
    end
end
