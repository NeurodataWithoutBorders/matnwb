function [sz, names] = procdims(shape, dim)
%check for optional dims
assert(iscell(shape), '`shape` must be a cell.');

if isempty(shape)
    sz = {};
    names = {};
    return;
end

sz = shape;
if iscellstr(sz)
    sz = strrep(sz, 'null', 'Inf');
    emptySz = cellfun('isempty', sz);
    sz(emptySz) = {'Inf'};
    sz = sz(end:-1:1); %reverse dimensions
    sz = misc.cellPrettyPrint(sz);
else
    for i=1:length(sz)
        sz{i} = strrep(sz{i}, 'null', 'Inf');
        sz{i} = sz{i}(end:-1:1); %reverse dimensions
        sz{i} = misc.cellPrettyPrint(sz{i});
    end
end

names = dim;
end

function flat = flatten(tree)
    emptyFlat = cellfun('isempty', flat);
    flat(emptyFlat) = {''};
    
    if ~iscellstr(flat) %Reached end
        for i=1:numBranches
            %recurse
            flat{i} = flatten(flat{i});
        end
    end
end