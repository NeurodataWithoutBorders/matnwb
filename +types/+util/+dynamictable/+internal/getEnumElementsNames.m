function elementsNames = getEnumElementsNames(vectorNames, vectors)
% getEnumElementsNames - Return the names of vectors that hold EnumData elements.
%
% Given the names and objects of a set of vectors, return the names of those
% that an EnumData column in the same set refers to as its elements. The
% elements are stored next to the columns of a DynamicTable, but they are
% not a column: their height is the number of enumerated elements, not the
% number of rows, and they are not listed in `colnames`.

    arguments
        vectorNames (1,:) cell
        vectors (1,:) cell
    end

    elementsNames = {};
    for iEnum = 1:numel(vectors)
        enumColumn = vectors{iEnum};
        if isa(enumColumn, 'types.hdmf_experimental.EnumData') && ~isempty(enumColumn.elements)
            for iVector = 1:numel(vectors)
                if isReferenceTarget(enumColumn.elements, vectors{iVector}, vectorNames{iVector})
                    elementsNames{end+1} = vectorNames{iVector}; %#ok<AGROW>
                end
            end
        end
    end
    elementsNames = unique(elementsNames, 'stable');
end

function tf = isReferenceTarget(objectView, vector, vectorName)
    % A reference read from a file holds the path of its target instead of
    % the target object.
    if isempty(objectView.target)
        tf = endsWith(objectView.path, ['/' vectorName]);
    else
        tf = objectView.target == vector;
    end
end
