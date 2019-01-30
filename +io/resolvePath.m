function o = resolvePath(nwb, path)
dotTok = split(path, '.');
tokens = split(dotTok{1}, '/');
%skip first `/` if it exists
if isempty(tokens{1})
    tokens(1) = [];
end

%process slash tokens
o = nwb;
errmsg = 'Could not resolve path `%s`.';
while ~isempty(tokens)
    if isa(o, 'types.untyped.Set')
        tok = tokens{1};
        tokens(1) = [];
        if any(strcmp(keys(o), tok))
            o = o.get(tok);
        else
            error(errmsg, path);
        end
    else
        props = properties(o);
        tok = tokens{1};
        for i=length(tokens):-1:1
            eager = strjoin(tokens(1:i), '_');
            if any(strcmp(props, eager))
                tokens = tokens(i+1:end);
                break;
            end
        end
        if ~isempty(tokens) && strcmp(tokens{1}, tok)
            error(errmsg, path);
        else
            o = o.(eager);
        end
    end
end