function s = cellPrettyPrint(val)
s = '';
for i=1:length(val)
    v = val{i};
    if ~isnan(str2double(v))
        wrapped_v = v;
    else
        wrapped_v = ['''' v ''''];
    end
    s = [s ' ' wrapped_v];
end
s = ['{ ' strtrim(s) ' }'];
end