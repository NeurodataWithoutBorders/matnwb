function shapes = findShapes(indices)
% FINDSHAPES Split indices along one dimension into hyperslab shapes.
%   shapes = FINDSHAPES(indices) returns a cell array of io.space.Shape
%   objects whose union selects the given 1-based indices along one
%   dimension of a dataspace. io.space.getReadSpace ORs one hyperslab per
%   shape into the file space, so fewer shapes make a cheaper selection.
%
%   The indices are sorted and deduplicated. Each run of two or more
%   consecutive indices becomes an io.space.shape.Block with step 1 and
%   each isolated index an io.space.shape.Point, in increasing order. This
%   split takes time linear in the number of indices.
%
%   When most indices are isolated, as in 1:2:N, a strided block search
%   runs first. Each pass takes the longest regularly strided block, so a
%   pure stride becomes one strided Block. A pass is only accepted when its
%   block covers a quarter of the remaining indices, which bounds the number
%   of passes by a logarithm of the number of indices; irregular isolated
%   indices fall back to the run split after one rejected pass.
%
%   An empty input selects nothing: a Block with stop 0.
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
