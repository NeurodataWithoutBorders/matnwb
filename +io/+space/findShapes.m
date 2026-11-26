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
%   findShapes looks for few shapes, in three stages:
%
%   1. When the indices average fewer than two per run of consecutive
%      indices, as in 1:2:99, the longest stretches of three or more
%      evenly spaced indices become Blocks with that spacing as their
%      step.
%   2. The same search runs on the isolated indices, the ones in no run,
%      so the stride in [1:10 200:2:400] becomes one Block.
%   3. Each run of consecutive indices left becomes a Block with step 1,
%      and each isolated index left a Point.
%
%   Examples:
%     io.space.findShapes([5 1 2 3 3])       % Block 1:3, Point 5
%     io.space.findShapes(1:2:99)            % Block 1:2:99
%     io.space.findShapes([1:10 200:2:400])  % Block 200:2:400, Block 1:10
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

[stridedBlocks, remaining] = findStridedBlocks(indices);

% A stride mixed with runs, as in [1:10 200:2:400], is not found above: the
% search starts at the smallest index, and it only runs while the indices
% average fewer than two per run. Such a stride is found among the isolated
% indices. When every index left is isolated, the search above has already
% ended on this same set.
isolated = findIsolatedIndices(remaining);
if numel(isolated) < numel(remaining)
    [isolatedStridedBlocks, unmatched] = findStridedBlocks(isolated);
    remaining = setdiff(remaining, setdiff(isolated, unmatched));
    stridedBlocks = [stridedBlocks, isolatedStridedBlocks];
end

shapes = [stridedBlocks, createRunShapes(remaining)];
end

function [blocks, remaining] = findStridedBlocks(indices)
% findStridedBlocks - Strided blocks that each hold a large share of the indices.
%
% The search runs while the indices left average fewer than two per run of
% consecutive indices. Each pass keeps the block that findOptimalBlock finds
% and removes its indices from remaining. The search ends when that block is
% shorter than minimumStrideLength or holds less than minimumStrideCoverage
% of the indices left.

    % Any two indices are evenly spaced, so a block of two would pair
    % indices that have nothing to do with each other.
    minimumStrideLength = 3;

    % A strided block is kept only when it holds at least this fraction of the
    % indices left. Each kept block then removes a quarter or more of them, so
    % the search keeps at most log(n)/log(4/3) blocks for n indices, 48 for a
    % million, and every pass scans all indices left. A smaller fraction keeps
    % shorter strided blocks but allows more passes. A larger fraction leaves
    % more strides to be read as one Point per index.
    minimumStrideCoverage = 0.25;

    blocks = {};
    remaining = indices;
    while ~isempty(remaining)
        runFirst = findRuns(remaining);
        isMostlyIsolated = numel(runFirst) > numel(remaining)/2;
        if ~isMostlyIsolated
            break;
        end
        stridedBlock = findOptimalBlock(remaining);
        if stridedBlock.length < max(minimumStrideLength, minimumStrideCoverage*numel(remaining))
            break;
        end
        blocks{end+1} = stridedBlock; %#ok<AGROW>
        remaining = setdiff(remaining, stridedBlock.range);
    end
end

function [runFirst, runLast] = findRuns(indices)
% findRuns - Positions of the first and last index of each run of consecutive indices.
    if isempty(indices)
        runFirst = zeros(1, 0);
        runLast = zeros(1, 0);
        return
    end
    runFirst = find([true, diff(indices) > 1]);
    runLast = [runFirst(2:end) - 1, numel(indices)];
end

function isolated = findIsolatedIndices(indices)
% findIsolatedIndices - The indices that are in no run of two or more consecutive indices.
    [runFirst, runLast] = findRuns(indices);
    isolated = indices(runFirst(runFirst == runLast));
end

function shapes = createRunShapes(indices)
% createRunShapes - One Block per run of consecutive indices and one Point per isolated index.
    import io.space.shape.Block;
    import io.space.shape.Point;
    [runFirst, runLast] = findRuns(indices);
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
