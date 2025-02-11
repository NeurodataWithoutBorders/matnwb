function matnwb_createNwbInstallExtension()
% matnwb_createNwbInstallExtension - Create nwbInstallExtension from template
%
%   Running this function will update the nwbInstallExtension function in
%   the root directory of the matnwb package. It will update the list of 
%   available extension names in the nwbInstallExtension function's arguments 
%   block and docstring based on the available records in the neurodata 
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
