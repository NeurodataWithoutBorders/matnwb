function elementsNames = getEnumElementsNames(vectorNames, vectors)
% getEnumElementsNames - Return the names of vectors that hold EnumData elements.
%
% Syntax:
%  elementsNames = types.util.dynamictable.internal.getEnumElementsNames(vectorNames, vectors)
%  finds the EnumData vectors in vectors that have an `elements` reference,
%  and returns the names of the vectors in vectors that those references
%  point to. Each name is returned once.
%
%  A reference points to a vector when its target is that vector object. A
%  reference read from a file has no target object, only a path, and points
%  to the vector whose name ends that path.
%
% Input Arguments:
%  - vectorNames (cell) - Name of each vector in vectors.
%  - vectors (cell) - Vector objects to search, in the order of vectorNames.
%
% Output Arguments:
%  - elementsNames (cell) - Names from vectorNames of the vectors that hold
%    the elements of an EnumData vector in vectors.

    arguments
        vectorNames (1,:) cell
        vectors (1,:) cell
    end

    isEnumColumn = false(size(vectors));
    for iVector = 1:numel(vectors)
        vector = vectors{iVector};
        isEnumColumn(iVector) = isa(vector, 'types.hdmf_experimental.EnumData') ...
            && ~isempty(vector.elements);
    end
    enumColumns = vectors(isEnumColumn);

    elementsNames = {};
    for iEnum = 1:numel(enumColumns)
        elements = enumColumns{iEnum}.elements;
        for iVector = 1:numel(vectors)
            if isReferenceTarget(elements, vectors{iVector}, vectorNames{iVector})
                elementsNames{end+1} = vectorNames{iVector}; %#ok<AGROW>
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
