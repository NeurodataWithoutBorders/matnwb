function cs = padCellStr(cstr, maxsize)
if nargin < 2
    maxsize = max(cellfun('length', cstr));
end
for i=1:length(cstr)
    cstrlen = length(cstr{i});
    if cstrlen < maxsize
        cstr{i} = [cstr{i} char(zeros(1, maxsize - cstrlen))];
    end
end
cs = cstr;
end