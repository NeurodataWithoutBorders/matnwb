function matnwb_createNwbInstallExtension()
% matnwb_createNwbInstallExtension - Create nwbInstallExtension and CatalogExtension from templates
%
%   Running this function updates two files from the records in the
%   neurodata extensions catalog:
%
%   - nwbInstallExtension.m in the root directory of the matnwb package,
%     whose docstring lists the available extension names.
%   - +matnwb/+extension/CatalogExtension.m, an enumeration with one member
%     per extension. nwbInstallExtension validates its first argument
%     against it, and MATLAB suggests its names for that argument.

    matnwbRootDir = misc.getMatnwbDir();
    templateFolder = fullfile(matnwbRootDir, 'resources', 'function_templates');

    extensionTable = matnwb.extension.listExtensions();
    extensionNames = extensionTable.name;

    fcnTemplate = fileread(fullfile(templateFolder, 'nwbInstallExtension.txt'));
    extensionNamesStr = compose("%%  - ""%s""", extensionNames);
    extensionNamesStr = strjoin(extensionNamesStr, newline);
    fcnStr = replace(fcnTemplate, "{{extensionNamesDoc}}", extensionNamesStr);
    writeFile(fullfile(matnwbRootDir, 'nwbInstallExtension.m'), fcnStr)

    classTemplate = fileread(fullfile(templateFolder, 'CatalogExtension.txt'));
    memberNames = matlab.lang.makeValidName(extensionNames);
    indentStr = repmat(' ', 1, 8);
    membersStr = compose("%s%s (""%s"")", indentStr, memberNames, extensionNames);
    membersStr = strjoin(membersStr, newline);
    classStr = replace(classTemplate, "{{enumerationMembers}}", membersStr);
    writeFile(fullfile(matnwbRootDir, '+matnwb', '+extension', 'CatalogExtension.m'), classStr)
end

function writeFile(filePath, text)
    fid = fopen(filePath, "wt");
    fwrite(fid, text);
    fclose(fid);
end
