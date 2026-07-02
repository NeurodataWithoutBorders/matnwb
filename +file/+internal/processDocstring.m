function docstring = processDocstring(docstring, continuationPrefix)
% processDocstring - Reflow a (possibly multiline) schema doc string for embedding in a comment
%
% Schema docs can be YAML literal block scalars (doc: |) and span multiple
% lines. Embedding such a string directly into a MATLAB comment leaves
% continuation lines without a leading "%", which breaks the comment block.
% This re-prefixes every continuation line so the result stays a valid
% comment when interpolated into generated code.
    arguments
        docstring (1,1) string
        continuationPrefix (1,1) string = "% "
    end

    docstring = strtrim(docstring);
    lines = strsplit(docstring, newline);
    lines = strip(lines, 'right');
    docstring = char(strjoin(lines, [newline char(continuationPrefix)]));
end
