function mustBeNonzeroLengthText(text)
% mustBeNonzeroLengthText - Check that text has 1 or more characters.
%
% mustBeNonzeroLengthText was introduced in R2020b. In order to support 
% older releases of MATLAB, this function implements 
% mustBeNonzeroLengthText also for older releases.

    if verLessThan('matlab', '9.9') %#ok<VERLESSMATLAB>
        % Custom implementation (MATLAB < R2020b)
        isValid = ischar(text) || isstring(text) || ...
            (iscell(text) && all(cellfun(@(c) isa(c, 'char') || isa(c, 'string'), text)));
        if isValid
            if ischar(text)
                isValid = ~isempty(text);
            elseif isstring(text)
                isValid = ~isempty(char(text));
            elseif iscell(text)
                isValid = ~isempty(text) && ~all( cellfun(@(c) isempty(c), text) );
            end
        end
        if ~isValid
            ME = MException(...
                'MATLAB:validators:mustBeNonzeroLengthText', ...
                'Value must be text with one or more characters.');
            throwAsCaller(ME)
        end
    else % Use available builtin
        try
            mustBeNonzeroLengthText(text)
        catch ME
            throwAsCaller(ME)
        end
    end
end


