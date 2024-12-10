function sz = formatShape(shape)
%check for optional dims
assert(iscell(shape), '`shape` must be a cell.');

if isempty(shape)
    sz = {};
    return;
end

sz = shape;
for i = 1:length(sz)
    if iscell(sz{i})
        sz{i} = file.formatShape(sz{i});
    elseif isnan(sz{i}) || isempty(sz{i})
        sz{i} = Inf;
    end
end
sz = sz(end:-1:1); % reverse dimensions
end