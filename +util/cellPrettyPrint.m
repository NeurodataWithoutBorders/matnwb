function s = cellPrettyPrint(val)
s = '';
for i=1:length(val)
    s = [s ' ''' val{i} ''''];
end
s = ['{ ' strtrim(s) ' }'];
end