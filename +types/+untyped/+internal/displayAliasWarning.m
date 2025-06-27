function displayAliasWarning(aliasTable, className)
% displayAliasWarning - Display warning if any names have aliases
    if ~isempty(aliasTable)
        nameMap = evalc('disp(aliasTable)');

        str = sprintf([...
            ['Names for some entries of "%s" have been modified to ', ...
            'make them valid MATLAB identifiers before adding them as ', ...
            'properties of the object. The original names will still ', ...
            'be used when data is exported to file:\n'], ...
            '\n%s\n'], className, strip(nameMap, 'right'));

        warnState = warning('backtrace', 'off');
        resetWarningObj = onCleanup(@() warning(warnState));
        warning(str) %#ok<SPWRN>
    end
end
