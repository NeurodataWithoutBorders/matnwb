function s = cellPrettyPrint(val)
s = '';
for i=1:length(val)
    v = val{i};
    if all(isstrprop(v, 'digit'))
        wrapped_v = v;
    else
        wrapped_v = ['''' v ''''];
    end
    s = [s ' ' wrapped_v];
end
s = ['{ ' strtrim(s) ' }'];
end