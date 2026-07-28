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

            isEditable = ~isa(obj.id.data, 'types.untyped.DataStub');

            assert(isEditable, errorID, ... 
                ['Cannot write to on-file Dynamic Tables without enabling data pipes. '...
                'If this was produced with pynwb, please enable chunking for this table.']);
        end
    end
end
