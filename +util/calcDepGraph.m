function dg = calcDepGraph(src, numitems, idx2parentsFcn)
%reglist is the registry list of some objects
%idx2parentsFcn is a function of form (reglist, i) -> [ia ib ic] where ia..ic
%are index to parents
%dg: first idx = child, 2nd idx = parent
dg = zeros(numitems);
%construct adjacency map
for i=1:numitems
    pindices = idx2parentsFcn(src, i);
    if ~isempty(pindices)
        dg(i, pindices) = 1;
    end
end
end