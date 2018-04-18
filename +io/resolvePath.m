function obj = resolvePath(nwb, path)
    % given a HDF5 Path (delimited by forward slashes), resolved nwb object
    if length(path) < 2 || ~contains(path, '/')
        error('Invalid path, either too short or missing forward slash delimiters.');
    end
    
    tokens = split(path, '/');
    if isempty(tokens{1})
        tokens = tokens(2:end);
    end
    
    partial = '';
    cursor = nwb;
    for i=1:length(tokens)
        tok = tokens{i};
        if isempty(tok)
            error('Path syntax error `%s`', path);
        end
        if ~isempty(partial)
            tok = [partial '_' tok];
        end
        p = properties(cursor);
        
        %logical map indicating possible partial match
        potential = logical(size(p));
        found = false;
        for j=1:length(p)
            pnm = p{j};
            if strcmp(pnm, tok)
                found = true;
                partial = '';
                cursor = cursor.(pnm);
                break;
            elseif startsWith(pnm, tok)
                potential(j) = true;
            end
        end
        
        if ~found
            if any(potential)
                partial = tok;
            else
                error('`%s` was not found in the nwb object.', path);
            end
        end
    end
    obj = cursor;
end