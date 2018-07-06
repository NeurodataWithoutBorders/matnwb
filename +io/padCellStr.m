function cs = padCellStr(cstr, maxsize)
if nargin < 2
    maxsize = max(cellfun('length', cstr));
end
for i=1:length(cstr)
    cstrlen = length(cstr{i});
    if cstrlen < maxsize
        %32 is a regular space character
        cstr{i} = [cstr{i} repmat(' ', 1, maxsize - cstrlen)];
    end
end
cs = cstr;
end