classdef RaggedColumn
% RaggedColumn - Data for a DynamicTable column in which each row holds a variable number of elements.
%
% Syntax:
%  column = types.untyped.RaggedColumn(data) creates a ragged column from
%  a cell array with one cell per row.
%
%  column = types.untyped.RaggedColumn(data, Name, Value) creates the
%  column using optional name-value pairs.
%
% A RaggedColumn is passed to a DynamicTable constructor under the column's
% name, or added to an existing table with addRaggedArray. The table stores
% it as a VectorData (or a DynamicTableRegion, with TargetTable) named after
% the column, plus one VectorIndex per depth level: '<name>_index',
% '<name>_index_index'. A table read from a file holds those objects, not
% a RaggedColumn.
%
% Input Arguments:
%  - data (cell | numeric | text | table | struct) -
%    The rows of the column. See DynamicTableBase.addRaggedArray for the
%    accepted forms.
%
%  - options (name-value pairs) -
%    Optional name-value pairs: Description, TargetTable, Depth,
%    ElementsPerRow and ElementsPerSubGroup, as in
%    DynamicTableBase.addRaggedArray.
%
% Usage:
%  Example 1 - Create a Units table with spike times for two units::
%
%    spikeTimes = types.untyped.RaggedColumn({[0.1 0.2 0.3], [0.5 0.6]}, ...
%        Description="spike times of each unit, in seconds");
%    units = types.core.Units('colnames', {'spike_times'}, ...
%        'description', 'units', 'spike_times', spikeTimes);
%
% See also:
%   matnwb.neurodata.DynamicTableBase/addRaggedArray

    properties (SetAccess = private)
        % Data - The rows of the column, in a form accepted by addRaggedArray.
        Data

        % Description - Description stored on the VectorData column.
        Description (1,1) string = "no description"

        % TargetTable - Table that a DynamicTableRegion column references, or empty.
        TargetTable = []

        % Depth - Number of VectorIndex levels: 1 for ragged, 2 for doubly ragged.
        Depth (1,1) double {mustBeInteger, mustBePositive} = 1

        % ElementsPerRow - Number of elements in each row when Data is flat, or empty.
        ElementsPerRow = []

        % ElementsPerSubGroup - Number of elements in each sub-group, or empty.
        ElementsPerSubGroup = []
    end

    properties (Access = private)
        % LayoutOptionNames - The layout options that were given, out of
        % ElementsPerRow and ElementsPerSubGroup. An empty ElementsPerRow
        % describes a table with no rows, which differs from leaving it out.
        LayoutOptionNames (1,:) string = string.empty(1, 0)
    end

    methods
        function obj = RaggedColumn(data, options)
            arguments
                data
                options.Description (1,1) string = "no description"
                options.TargetTable {mustBeEmptyOrDynamicTable} = []
                options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
                options.ElementsPerRow {mustBeNumeric, mustBeInteger, mustBeNonnegative}
                options.ElementsPerSubGroup {mustBeNumeric, mustBeInteger, mustBePositive}
            end

            obj.Data = data;
            obj.Description = options.Description;
            obj.TargetTable = options.TargetTable;
            obj.Depth = options.Depth;
            if isfield(options, 'ElementsPerRow')
                obj.ElementsPerRow = options.ElementsPerRow;
                obj.LayoutOptionNames(end+1) = "ElementsPerRow";
            end
            if isfield(options, 'ElementsPerSubGroup')
                obj.ElementsPerSubGroup = options.ElementsPerSubGroup;
                obj.LayoutOptionNames(end+1) = "ElementsPerSubGroup";
            end
        end

        function nameValuePairs = toNameValuePairs(obj, columnName)
        % toNameValuePairs - Return the stored column objects as name-value pairs.
        %
        % Syntax:
        %  nameValuePairs = column.toNameValuePairs(columnName) returns
        %  {columnName, data, '<columnName>_index', index, ...}, with one
        %  VectorIndex per depth level.

            arguments
                obj (1,1) types.untyped.RaggedColumn
                columnName (1,1) string
            end

            layoutOptions = {'Depth', obj.Depth};
            for optionName = obj.LayoutOptionNames
                layoutOptions(end+1:end+2) = {char(optionName), obj.(optionName)};
            end

            columns = cell(1, obj.Depth+1);
            % The description is set on the column after the call: as a
            % positional argument, a text that starts an option name of
            % util.create_indexed_column, such as 'depth', is read as that
            % option name.
            [columns{:}] = util.create_indexed_column(obj.Data, ...
                '', obj.TargetTable, layoutOptions{:});
            if strlength(obj.Description) > 0
                columns{1}.description = char(obj.Description);
            end

            names = strings(1, obj.Depth+1);
            names(1) = columnName;
            for iLevel = 1:obj.Depth
                names(iLevel+1) = names(iLevel) + "_index";
            end
            nameValuePairs = [cellstr(names); columns];
            nameValuePairs = nameValuePairs(:)';
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
