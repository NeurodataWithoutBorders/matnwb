function joinedPath = pathjoin(pathNames)

    arguments (Repeating)
        pathNames (1,1) string
    end

    pathNames = string(pathNames);

    % Join path parts with '/'
    joinedPath = join(pathNames, "/");
    
    % Replace double slashes '//' with single '/'
    while contains(joinedPath, '//')
        joinedPath = strrep(joinedPath, '//', '/');
    end
end
