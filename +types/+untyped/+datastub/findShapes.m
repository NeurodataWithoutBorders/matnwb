function shapes = findShapes(indices)
% FINDSHAPES given a vector of indices, this function spits out a cell
% array of "selections" (types.untyped.datastub.shape objects). These
% indicate how the H5S calls should be iterated over.
% A Block selection, for instance, indicates that the (step, stride, count)
% method used by H5S should be used while Point selection indicates that
% only one part of this dimension should be iterated over at a time.
import types.untyped.datastub.shape.Block;
import types.untyped.datastub.shape.Point;
validateattributes(indices, {'numeric'}, {'nonnegative', 'finite'});
if isempty(indices)
    shapes = {Block('count', 0)};
    return;
end
assert(isvector(indices),...
    'MatNwb:DataStub:FindShapes:InvalidShape',...
    'Indices cannot be matrices.');
indices = sort(indices);
shapes = {};
while ~isempty(indices)
    BlockSelection = findOptimalBlock(indices);
    if BlockSelection.length <= 1
        for i = 1:length(indices)
            shapes{end+1} = Point(indices(i));
        end
        return;
    end
    indices = setdiff(indices, BlockSelection.range, 'stable');
    shapes{end+1} = BlockSelection;
end
end

function optimalBlock = findOptimalBlock(indices)
import types.untyped.datastub.shape.Block;
if iscolumn(indices)
    indices = indices .';
end
stop = 1;
start = 1;
step = 0;
count = 0;
for i = 1:length(indices)
    tempStart = indices(i);
    if length(indices) - i <= count
        % number of elements cannot possibly be larger than what we have.
        break;
    end
    for j = 1:(length(indices)-i)
        tempStep = indices(i+j) - indices(i);
        for k = fliplr(i:length(indices))
            tempStop = indices(k);
            idealRange = tempStart:tempStep:tempStop;
            tempRange = intersect(indices, idealRange, 'stable');
            if length(tempRange) <= count 
                % number of intersected items is shorter than what we have.
                break;
            end
            if isequal(tempRange, idealRange)
                start = tempStart;
                step = tempStep;
                stop = tempStop;
                count = length(tempRange);
                break;
            end
        end
    end
end
optimalBlock = Block('start', start, 'step', step, 'stop', stop);
end