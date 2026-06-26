function tf = isColnamesTextContainer(colnames)
% isColnamesTextContainer - Test whether colnames can be normalized as text.

    tf = iscellstr(colnames) || isstring(colnames) || ischar(colnames);
end
