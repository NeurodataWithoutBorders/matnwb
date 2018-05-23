function cs = padCellStr(cstr, maxsize)
for i=1:length(cstr)
    cstrlen = length(cstr{i});
    if cstrlen < maxsize
        cstr{i} = [cstr{i} char(zeros(1, maxsize - cstrlen))];
    end
end
cs = cstr;
end