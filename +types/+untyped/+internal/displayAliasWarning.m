function displayAliasWarning(aliasTable, className)
% displayAliasWarning - Display warning with table of alias names for an object
%
%   Utility method that formats and displays a warning given an alias table
%   and the class name for an object. Will typically be used for an object
%   with dynamic properties where property identifiers are aliases for an
%   original name which is not a valid MATLAB identifier.

    if ~isempty(aliasTable)
        nameMap = evalc('disp(aliasTable)');

        warningIdentifier = 'NWB:DynamicPropertyAliasWarning';
        warningMessage = sprintf([...
            ['Names for some entries of "%s" have been modified to ', ...
            'make them valid MATLAB identifiers (the original names will still ', ...
            'be used when data is exported to file):\n'], ...
            '\n%s\n'], className, strip(nameMap, 'right'));

        warnState = warning('backtrace', 'off');
        resetWarningObj = onCleanup(@() warning(warnState));
        warning(warningIdentifier, warningMessage) %#ok<SPWRN>
    end
end
