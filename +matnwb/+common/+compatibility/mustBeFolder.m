function mustBeFolder(folderPath)
% mustBeFolder - Check if value is path name of existing folder.
%
% mustBeFolder was introduced in R2020b. In order to support older releases
% of MATLAB, this function implements mustBeFolder also for older releases.
%
% Note: Currently only works for scalar strings

    arguments
        folderPath (1,1) string
    end
    
    if verLessThan('matlab', '9.9') %#ok<VERLESSMATLAB>
        % Custom implementation (MATLAB < R2020b)
        isValid = isfolder(folderPath);

        if ~isValid
            ME = MException(...
                'MATLAB:validators:mustBeFolder', ...
                'The following folder does not exist: ''%s''.', folderPath);
            throwAsCaller(ME)
        end
    else % Use available builtin
        try
            mustBeFolder(folderPath)
        catch ME
            throwAsCaller(ME)
        end
    end
end
