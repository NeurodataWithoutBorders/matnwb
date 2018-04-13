function asstr = addSpaces(str, numspaces)
if isempty(str)
    asstr = str;
else
    indent = repmat(' ', [1 numspaces]);
    asstr = [indent strtrim(strrep(str, newline, [newline indent]))];
end
end