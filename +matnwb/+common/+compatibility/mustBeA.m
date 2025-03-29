function mustBeA(value, classNames)
% mustBeA - Check if value is one of specified classes
%
% mustBeA was introduced in R2020b.

    arguments
      value
      classNames (1,:) string
    end

    if verLessThan('matlab', '9.9') %#ok<VERLESSMATLAB>
        % Custom implementation (MATLAB < R2020b)
        try
            mustBeMember(class(value), classNames)
        catch ME
            ME = MException(...
                'MATLAB:validators:mustBeA', ...
                'Value must be one of the following types: %s.', strjoin(classNames, ', '));
            throwAsCaller(ME)
        end
    else % Use available builtin
        try
            mustBeA(value, classNames)
        catch ME
            throwAsCaller(ME)
        end
    end
end
