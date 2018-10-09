function [sz, names] = procdims(shape, dim)
%check for optional dims
assert(isa(shape, 'java.util.ArrayList'), '`shape` must be a java.util.ArrayList object.');

if shape.size() == 0
    sz = {};
    names = {};
    return;
end

sz = flatten(shape);
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

names = {};
if isa(dim, 'java.util.ArrayList') && dim.size() > 0
    names = flatten(dim);
end
end

function flat = flatten(tree)
    treelen = tree.size();
    flat = cell(treelen,1);
    for i=1:treelen
        flat{i} = tree.get(i-1);
    end
    
    emptyFlat = cellfun('isempty', flat);
    flat(emptyFlat) = {''};
    
    if ~iscellstr(flat) %Reached end
        for i=1:treelen
            %recurse
            flat{i} = flatten(flat{i});
        end
    end
end