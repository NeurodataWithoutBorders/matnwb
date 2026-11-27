function nameValuePairs = expandTableColumns(nameValuePairs)
% expandTableColumns - Replace each ExpandableTableColumn argument with the objects the column is stored as.
%
% Syntax:
%  nameValuePairs = types.util.dynamictable.expandTableColumns(nameValuePairs)
%  replaces every pair {columnName, column}, where column is a
%  types.untyped.abstract.ExpandableTableColumn, with the pairs that
%  column.toNameValuePairs(columnName) returns. For a
%  types.untyped.RaggedArrayColumn these are
%  {columnName, data, '<columnName>_index', index, ...}. Other pairs are
%  returned unchanged and in order.
%
% Generated DynamicTable constructors and DynamicTableBase.addColumn call
% this before they parse their arguments, so each receives the VectorData
% and VectorIndex objects it validates.

    arguments
        nameValuePairs (1,:) cell
    end

    % A malformed argument list is left for the caller's argument parsing to
    % report.
    if mod(numel(nameValuePairs), 2) ~= 0
        return
    end

    isExpandable = cellfun(@(value) isa(value, 'types.untyped.abstract.ExpandableTableColumn'), ...
        nameValuePairs(2:2:end));
    if ~any(isExpandable)
        return
    end

    numPairs = numel(isExpandable);
    expandedPairs = cell(1, numPairs);
    createdNames = cell(1, numPairs);
    creatorNames = cell(1, numPairs);
    for iPair = 1:numPairs
        name = nameValuePairs{2*iPair-1};
        value = nameValuePairs{2*iPair};
        if isExpandable(iPair)
            expandedPairs{iPair} = value.toNameValuePairs(name);
            createdNames{iPair} = string(expandedPairs{iPair}(3:2:end));
            creatorNames{iPair} = repmat(string(name), size(createdNames{iPair}));
        else
            expandedPairs{iPair} = {name, value};
        end
    end
    nameValuePairs = [expandedPairs{:}];

    % An object that an ExpandableTableColumn creates and that also appears
    % among the other arguments would set the same property twice.
    argumentNames = string(nameValuePairs(1:2:end));
    createdNames = [string.empty(1, 0), createdNames{:}];
    creatorNames = [string.empty(1, 0), creatorNames{:}];
    isGivenTwice = arrayfun(@(name) nnz(argumentNames == name) > 1, createdNames);
    if any(isGivenTwice)
        duplicates = compose("%s (created by %s)", ...
            createdNames(isGivenTwice)', creatorNames(isGivenTwice)');
        error('NWB:DynamicTable:ExpandableTableColumn:DuplicateArgument', ...
            ['A column given as an ExpandableTableColumn, such as a RaggedArrayColumn, ' ...
            'creates the objects it is stored with, so they cannot also be given as ' ...
            'arguments. Remove the argument(s): %s.'], ...
            strjoin(duplicates, ', '))
    end
end
