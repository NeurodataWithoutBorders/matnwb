function shapes = segmentSelection(selections, dims)
%SEGMENTSELECTION Given a cell array of 1-indexed indices along with a vector of
%bounds, returns a cell array of io.space.Shape objects indicating the
%selectsion are optimally segmented. This is for optimally selecting a
%dataset given a set of MATLAB indices.
validateattributes(dims, {'numeric'}, {'vector', 'nonnegative'});
validateattributes(selections, {'cell'}, {'vector', 'nonempty'});
for i = 1:length(selections)
    validateattributes(selections{i}, {'numeric'}, {'nonnegative', '<=', dims(i)});
end

rank = length(dims);
shapes = cell(1, rank); % cell array of cell arrays of shapes
isDanglingGroup = ischar(selections{end});
for i = 1:rank
    if i > length(selections) && ~isDanglingGroup % select a scalar element.
        shapes{i} = {io.space.shape.Point(1)};
    elseif (i > length(selections) && isDanglingGroup)...
            || ischar(selections{i})
        % select the whole dimension
        % dims(i) - 1 because block represents 0-indexed
        % inclusive stop. The Block.length == dims(i)
        shapes{i} = {io.space.shape.Block('stop', dims(i))};
    else
        % break the selection into range/point pieces
        % per dimension.
        shapes{i} = io.space.findShapes(selections{i});
    end
end
end

