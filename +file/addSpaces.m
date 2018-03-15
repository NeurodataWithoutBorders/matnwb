function asstr = addSpaces(str, numspaces)
if isempty(str)
    asstr = str;
else
    strbloc = repmat(' ', [1 numspaces]);
    asstr = [strbloc strtrim(strrep(str, newline, [newline strbloc])) newline];
end
end