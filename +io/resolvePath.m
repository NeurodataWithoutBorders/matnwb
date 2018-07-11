function o = resolvePath(nwb, path)
dotTok = split(path, '.');
tokens = split(dotTok{1}, '/');
%skip first `/` if it exists
if isempty(tokens{1})
    tokens(1) = [];
end

%process slash tokens
o = nwb;
prefix = '';
for i=1:length(tokens)
    tok = tokens{i};
    errmsg = 'Could not resolve path `%s`.  Could not find `%s`.';
    if isa(o, 'types.untyped.Set')
        if any(strcmp(keys(o), tok))
            o = o.get(tok);
        else
            error(errmsg, path, tok);
        end
        continue;
    end
    %is class
    props = properties(o);
    if any(strcmp(props, tok))
        o = o.(tok);
    elseif any(strcmp(props, [prefix '_' tok]))
        o = o.([prefix '_' tok]);
        prefix = '';
    elseif any(startsWith(props, tok))
        if isempty(prefix)
            prefix = tok;
        else
            prefix = [prefix '_' tok];
        end
    else
        %dig one level into untyped sets because we don't know
        %if the untyped set is extraneous to the type or not.
        found = false;
        for j=1:length(props)
            set = o.(props{j});
            if isa(set, 'types.untyped.Set') &&...
                    any(strcmp(keys(set), tok))
                o = set.get(tok);
                found = true;
                break;
            end
        end
        if ~found
            error(errmsg, path, tok);
        end
    end
end
end