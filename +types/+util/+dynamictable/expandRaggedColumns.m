function nameValuePairs = expandRaggedColumns(nameValuePairs)
% expandRaggedColumns - Replace each RaggedColumn argument with its stored column objects.
%
% Syntax:
%  nameValuePairs = types.util.dynamictable.expandRaggedColumns(nameValuePairs)
%  replaces every pair {columnName, raggedColumn}, where raggedColumn is a
%  types.untyped.RaggedColumn, with {columnName, data, '<columnName>_index',
%  index, ...}. Other pairs are returned unchanged and in order.
%
% Generated DynamicTable constructors call this before they parse their
% arguments, so each constructor receives the VectorData and VectorIndex
% objects it validates.

    arguments
        nameValuePairs (1,:) cell
    end

    % A malformed argument list is left for the constructor's inputParser to
    % report.
    if mod(numel(nameValuePairs), 2) ~= 0
        return
    end

    isRaggedColumn = cellfun(@(value) isa(value, 'types.untyped.RaggedColumn'), ...
        nameValuePairs(2:2:end));
    if ~any(isRaggedColumn)
        return
    end

    expandedPairs = cell(1, numel(isRaggedColumn));
    indexNames = cell(1, numel(isRaggedColumn));
    for iPair = 1:numel(isRaggedColumn)
        name = nameValuePairs{2*iPair-1};
        value = nameValuePairs{2*iPair};
        if isRaggedColumn(iPair)
            expandedPairs{iPair} = value.toNameValuePairs(name);
            indexNames{iPair} = expandedPairs{iPair}(3:2:end);
        else
            expandedPairs{iPair} = {name, value};
        end
    end
    nameValuePairs = [expandedPairs{:}];

    % An index name that also appears among the other arguments would set
    % the same property twice.
    argumentNames = string(nameValuePairs(1:2:end));
    indexNames = string([indexNames{:}]);
    isGivenTwice = arrayfun(@(name) sum(argumentNames == name) > 1, indexNames);
    duplicateNames = indexNames(isGivenTwice);
    if ~isempty(duplicateNames)
        error('NWB:DynamicTable:RaggedColumn:DuplicateArgument', ...
            ['A RaggedColumn creates its own index columns, so they cannot also ' ...
            'be given as arguments. Remove the argument(s): %s.'], ...
            strjoin(duplicateNames, ', '))
    end
end
