function fvstr = fillValidators(propnames, props)
fvstr = '';
return;
for i=1:length(propnames)
    nm = propnames{i};
    prop = props.properties(nm);
    fvstr = [fvstr ...
        'function validate_' nm '(obj, val)' newline...
        'end' newline];
end
end