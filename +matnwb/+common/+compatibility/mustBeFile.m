function mustBeFile(filePath)
% mustBeFile - Check if value is path name of existing file.
%
% mustBeFile was introduced in R2020b. In order to support older releases
% of MATLAB, this function implements mustBeFile also for older releases.
%
% Note: Currently only works for scalar strings

    arguments
        filePath (1,1) string
    end
    
    if verLessThan('matlab', '9.9') %#ok<VERLESSMATLAB>
        % Custom implementation (MATLAB < R2020b)
        try
            matnwb.common.compatibility.mustBeNonzeroLengthText(filePath)
        catch ME
            throwAsCaller(ME)
        end
        isValid = isfile(filePath);

        if ~isValid
            ME = MException(...
                'MATLAB:validators:mustBeFile', ...
                'The following file does not exist: ''%s''.', filePath);
            throwAsCaller(ME)
        end
    else % Use available builtin
        try
            mustBeFile(filePath)
        catch ME
            throwAsCaller(ME)
        end
    end
end

