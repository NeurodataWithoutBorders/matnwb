function shapes = segmentSelection(selections, dims)
%SEGMENTSELECTION Given a cell array of 1-indexed indices along with a vector of
%bounds, returns a cell array of io.space.Shape objects indicating the
%selections which are optimally segmented. This is for optimally selecting a
%dataset given a set of MATLAB indices.
validateattributes(dims, {'numeric'}, {'vector', 'nonnegative'});
validateattributes(selections, {'cell'}, {'vector', 'nonempty'});

rank = length(dims);
if isscalar(selections) && ~ischar(selections{1}) && 1 < rank
    % single-rank selection mode.
    newSelections = cell(1, rank);
    [newSelections{:}] = ind2sub(dims, selections{1});
    selections = newSelections;
end

for i = 1:length(selections)
    if ischar(selections{i})
        continue; % if ':' or some other char, the entire dimension is selected.
    end
    validateattributes(selections{i}, {'numeric'}, {'positive', '<=', dims(i)});
end

shapes = cell(1, rank); % cell array of cell arrays of shapes
isDanglingGroup = ischar(selections{end});
for i = 1:rank
    if i > length(selections) && ~isDanglingGroup % select a scalar element.
        shapes{i} = {io.space.shape.Point(1)};
    elseif (i > length(selections) && isDanglingGroup)...
            || ischar(selections{i})
        % select the whole dimension
        % The Block.length == dims(i)
        shapes{i} = {io.space.shape.Block('stop', dims(i))};
    else
        % break the selection into range/point pieces
        % per dimension.
        shapes{i} = io.space.findShapes(selections{i});
    end
end
end

