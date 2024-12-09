function shapes = findShapes(indices)
% FINDSHAPES given a vector of indices, this function spits out a cell
% array of "selections" (types.untyped.datastub.shape objects). These
% indicate how the H5S calls should be iterated over.
% A Block selection, for instance, indicates that the (step, stride, count)
% method used by H5S should be used while Point selection indicates that
% only one part of this dimension should be iterated over at a time.
import io.space.shape.Block;
import io.space.shape.Point;
validateattributes(indices, {'numeric'}, {'nonnegative', 'finite'});
if isempty(indices)
    shapes = {Block('stop', 0)};
    return;
end
assert(isvector(indices),...
    'NWB:DataStub:FindShapes:InvalidShape',...
    'Indices cannot be matrices.');
indices = unique(indices);
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
import io.space.shape.Block;
if iscolumn(indices)
    indices = indices .';
end
stop = 1;
start = 1;
step = 1;
count = 0;
for stepInd = 2:length(indices)
    tempStep = indices(stepInd) - indices(1);
    idealRange = indices(1):tempStep:indices(end);
    if length(idealRange) <= count
        break;
    end
    rangeMatches = ismembc(idealRange, indices);
    startInd = find(rangeMatches, 1);
    stopInd = find(rangeMatches, 1, 'last');
    splitPoints = find(~rangeMatches(startInd:stopInd)) + startInd - 1;
    if ~isempty(splitPoints)
        subStarts = [startInd (splitPoints + 1)];
        subStops = [(splitPoints - 1) stopInd];
        segment = subStops - subStarts + 1;
        [~, largestSegInd] = max(segment(:));
        startInd = subStarts(largestSegInd);
        stopInd = subStops(largestSegInd);
    end
    subCount = sum(rangeMatches(startInd:stopInd));
    if subCount > count
        start = idealRange(startInd);
        stop = idealRange(stopInd);
        step = tempStep;
        count = subCount;
    end
end
optimalBlock = Block('start', start, 'step', step, 'stop', stop);
end