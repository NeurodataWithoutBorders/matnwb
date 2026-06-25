function propertyBlockStr = fillPrivateConstantProperty(propertyName, listOfStrings)
% fillPrivateConstantProperty - Fill a private constant string-list property.

    arguments
        propertyName (1,1) string
        listOfStrings (1,:) string
    end

    if isempty(listOfStrings)
        propertyLine = sprintf('%s = string.empty(1, 0);', propertyName);
    else
        quotedStrings = """" + listOfStrings + """";
        propertyLine = sprintf('%s = [%s];', propertyName, strjoin(quotedStrings, ', '));
    end

    propertyBlockStr = strjoin({ ...
        'properties (Constant, Access = private)', ...
        file.addSpaces(propertyLine, 4), ...
        'end'}, newline);
end
