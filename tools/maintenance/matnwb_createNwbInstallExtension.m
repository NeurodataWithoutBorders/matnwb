function matnwb_createNwbInstallExtension()
% matnwb_createNwbInstallExtension - Create nwbInstallExtension from template
%
%   This function can be run to update the list of available extension
%   names in the function's arguments block based on the neurodata
%   extensions catalog

    matnwbRootDir = misc.getMatnwbDir();
    fcnTemplate = fileread(fullfile(matnwbRootDir, ...
        'resources', 'function_templates', 'nwbInstallExtension.txt'));

    extensionTable = matnwb.extension.listExtensions();
    extensionNames = extensionTable.name;

    indentStr = repmat(' ', 1, 12);
    extensionNamesStr = compose("%s""%s""", indentStr, extensionNames);
    extensionNamesStr = strjoin(extensionNamesStr, ", ..." + newline);
    fcnStr = replace(fcnTemplate, "{{extensionNames}}", extensionNamesStr);
        
    extensionNamesStr = compose("%%  - ""%s""", extensionNames);
    extensionNamesStr = strjoin(extensionNamesStr, newline);
    fcnStr = replace(fcnStr, "{{extensionNamesDoc}}", extensionNamesStr);


    fid = fopen(fullfile(matnwbRootDir, 'nwbInstallExtension.m'), "wt");
    fwrite(fid, fcnStr);
    fclose(fid);
end
