function shapes = findShapes(indices)
% findShapes - Convert indices along one dimension into hyperslab shapes.
%   shapes = io.space.findShapes(indices) returns a cell array of
%   io.space.shape.Block and io.space.shape.Point objects that together
%   select indices, a vector of 1-based indices along one dimension of a
%   dataset. Order and repeats in indices are ignored, and an empty
%   indices returns one Block that selects nothing.
%
%   A read with a subscript per dimension is described to HDF5 as a set
%   of hyperslabs. Along one dimension a hyperslab is a start, a step and
%   a count: it can select 1:100 or 1:2:99, but a list such as
%   [1 2 3 7 10] needs several. A Block is a range start:step:stop and a
%   Point a single index, so each shape fits in one hyperslab. A
%   selection takes longer to build the more hyperslabs it has, so
%   findShapes looks for few shapes, in two stages:
%
%   1. When the indices average fewer than two per run of consecutive
%      indices, as in 1:2:99, the longest evenly spaced stretches become
%      Blocks with that spacing as their step.
%   2. Each run of consecutive indices left becomes a Block with step 1,
%      and each single index left a Point.
%
%   Examples:
%     io.space.findShapes([5 1 2 3 3])   % Block 1:3, Point 5
%     io.space.findShapes(1:2:99)        % Block 1:2:99
%     io.space.findShapes([1 2 3 7 10])  % Block 1:3, Block 7:3:10
%
%   See also io.space.segmentSelection, io.space.getReadSpace

import io.space.shape.Block;
validateattributes(indices, {'numeric'}, {'nonnegative', 'finite'});
if isempty(indices)
    shapes = {Block('stop', 0)};
    return;
end
assert(isvector(indices),...
    'NWB:DataStub:FindShapes:InvalidShape',...
    'Indices cannot be matrices.');
indices = reshape(unique(indices), 1, []);

minimumStrideCoverage = 0.25;

shapes = {};
remaining = indices;
while ~isempty(remaining)
    [runFirst, runLast] = findRuns(remaining);
    isMostlyIsolated = numel(runFirst) > numel(remaining)/2;
    if ~isMostlyIsolated
        break;
    end
    stridedBlock = findOptimalBlock(remaining);
    if stridedBlock.length < max(2, minimumStrideCoverage*numel(remaining))
        break;
    end
    shapes{end+1} = stridedBlock; %#ok<AGROW>
    remaining = setdiff(remaining, stridedBlock.range);
end
if ~isempty(remaining)
    shapes = [shapes, createRunShapes(remaining, runFirst, runLast)];
end
end

function [runFirst, runLast] = findRuns(indices)
% findRuns - Positions of the first and last index of each run of consecutive indices.
    runFirst = find([true, diff(indices) > 1]);
    runLast = [runFirst(2:end) - 1, numel(indices)];
end

function shapes = createRunShapes(indices, runFirst, runLast)
% createRunShapes - One Block per run of consecutive indices and one Point per isolated index.
    import io.space.shape.Block;
    import io.space.shape.Point;
    shapes = cell(1, numel(runFirst));
    for iRun = 1:numel(runFirst)
        first = indices(runFirst(iRun));
        last = indices(runLast(iRun));
        if first == last
            shapes{iRun} = Point(first);
        else
            shapes{iRun} = Block('start', first, 'stop', last);
        end
    end
end

function optimalBlock = findOptimalBlock(indices)
% findOptimalBlock - The regularly strided block that covers the most indices.
%
% Every stride from the first index to another index is tried, and the
% longest unbroken stretch of matching indices is kept. The search stops
% once a stride cannot produce a longer block than the best one so far.
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
