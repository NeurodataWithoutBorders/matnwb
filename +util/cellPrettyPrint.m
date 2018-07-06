function s = cellPrettyPrint(val)
val = strrep(val, '''', '`');
nummatch = regexp(val, '^(?:.+\()?(NaN|\d+(?:\.\d+)?)\)?', 'match', 'once');
nonnums = ~strcmp(val, nummatch);
val(nonnums) = strcat('''', val(nonnums), '''');
s = ['{ ' strjoin(val, ' ') ' }'];
end