function generateRstForNwbTypeClasses()
% generateRstForNwbTypeClasses Generate rst files for each Neurodata matnwb class

    rootDir = misc.getMatnwbDir();
    coreTypeFiles = dir(fullfile(rootDir, '+types', '+core', '*.m'));

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    exportDir = fullfile(docsSourceRootDir, 'pages', 'neurodata_types', 'core');
    if ~isfolder(exportDir); mkdir(exportDir); end

    functionTemplate = fileread( getRstTemplateFile('function') );
    classTemplate = fileread( getRstTemplateFile('class') );

    for i = 1:numel(coreTypeFiles)
        iFile = fullfile(coreTypeFiles(i).folder, coreTypeFiles(i).name);
        [~, functionName] = fileparts(iFile);

        data.function_name = functionName;
        data.module_name = 'types.core';
        data.function_header_underline = repmat('=', 1, numel(functionName));
        data.full_function_name = sprintf('types.core.%s', functionName);

        mc = meta.class.fromName(data.full_function_name);
        if isempty(mc)
            currentTemplate = functionTemplate;
        else
            currentTemplate = classTemplate;
        end

        thisRst = fillTemplate(currentTemplate, data);
        rstFilePath = fullfile(exportDir, [functionName, '.rst']);
        filewrite(rstFilePath, thisRst);
    end

    % Create index
    indexTemplate = fileread( getRstTemplateFile('index_core_types') );
    [~, functionNames] = fileparts(string({coreTypeFiles.name}));
    data.function_list = strjoin("   "+functionNames, newline);
    
    thisRst = fillTemplate(indexTemplate, data);
    rstFilePath = fullfile(exportDir, ['index', '.rst']);
    filewrite(rstFilePath, thisRst);
end
