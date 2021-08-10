function [newSid, memSid] = getReadSpace(shapes, sid)
%GETREADSPACE Given a cell array of shapes and a valid space id, applies a
%selected version of that space id along with the memSid required for
%reading a dataset.
validateattributes(shapes, {'cell'}, {'nonempty', 'vector'});
for i = 1:length(shapes)
    validateattributes(shapes{i}, {'cell'}, {'vector'});
    for j = 1:length(shapes{i})
        validateattributes(shapes{i}{j}, {'io.space.Shape'}, {'scalar'});
    end
end
validateattributes(sid, {'H5ML.id'}, {'scalar', 'nonempty'});
assert(logical(H5I.is_valid(sid)),...
    'NWB:Space:GetReadSpace:InvalidId',...
    'Provided Space ID is invalid.');

newSid = H5S.copy(sid); % do not change the original space ID
H5S.select_none(newSid); % reset selection on file.
[rank, ~, ~] = H5S.get_simple_extent_dims(newSid);
shapeInd = ones(1, rank);
shapeIndEnd = cellfun('length', shapes);
while true
    start = ones(1, rank);
    stride = ones(1, rank);
    count = ones(1, rank);
    block = ones(1, rank);
    for i = 1:length(shapes)
        Selection = shapes{i}{shapeInd(i)};
        [start(i), stride(i), count(i), block(i)] = Selection.getSpaceSpec();
    end
    % convert start offset to 0-indexed and HDF5 dimension
    % order.
    H5S.select_hyperslab(newSid, 'H5S_SELECT_OR',...
        fliplr(start) - 1, fliplr(stride), fliplr(count), fliplr(block));
    
    iterateInd = find(shapeInd < shapeIndEnd, 1);
    if isempty(iterateInd)
        break;
    end
    shapeInd(iterateInd) = shapeInd(iterateInd) + 1;
    shapeInd(1:(iterateInd-1)) = 1;
end

if nargout <= 1
    return;
end

memSize = zeros(1, rank);
for i = 1:rank
    for j = 1:length(shapes{i})
        Selection = shapes{i}{j};
        if isa(Selection, 'io.space.shape.Point')
            memSize(i) = memSize(i) + 1;
        else
            memSize(i) = memSize(i) + Selection.length;
        end
    end
end
memSid = H5S.create_simple(length(memSize), fliplr(memSize), []);
end

