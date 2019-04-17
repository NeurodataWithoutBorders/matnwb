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
        [o, tokens] = resolveSet(o, tokens);
    else
        [o, tokens] = resolveObj(o, tokens);
    end
    if isempty(o)
        error(errmsg, path);
    end
end
end

function [o, remainder] = resolveSet(obj, tokens)
tok = tokens{1};
if any(strcmp(keys(obj), tok))
    o = obj.get(tok);
    remainder = tokens(2:end);
else
    o = [];
    remainder = tokens;
end
end

function [o, remainder] = resolveObj(obj, tokens)
props = properties(obj);
toklen = length(tokens);
eagerlist = cell(toklen,1);
for i=1:toklen
    eagerlist{i} = strjoin(tokens(1:i), '_');
end
% stable in this case preserves ordering with eagerlist bias
[eagers, ei, ~] = intersect(eagerlist, props, 'stable');
if isempty(eagers)
    % go one level down and check for sets
    proplen = length(props);
    issetprops = false(proplen, 1);
    for i=1:proplen
        issetprops(i) = isa(obj.(props{i}), 'types.untyped.Set');
    end
    setprops = props(issetprops);
    new_objects = cell(length(setprops),3);
    for i=1:length(setprops)
        [new_o, new_tokens] = resolveSet(obj.(setprops{i}), tokens);
        new_objects(i,:) = {new_o, new_tokens, length(new_tokens)};
    end
    
    [~,minidx] = min(cell2mat(new_objects(:,3)));
    o = new_objects{minidx,1};
    remainder = new_objects{minidx,2};
else
    o = obj.(eagers{end});
    remainder = tokens(ei(end)+1:end);
end
end