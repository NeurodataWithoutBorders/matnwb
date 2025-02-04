function generateRstForNwbFunctions()
% generateRstForNwbFunctions 

    % List, filter and sort files to generate. Todo: simplify
    rootDir = misc.getMatnwbDir();
    rootFiles = dir(rootDir);
    rootFileNames = {rootFiles.name};
    rootWhitelist = {'nwbRead.m', 'NwbFile.m', 'nwbExport.m', 'generateCore.m', 'generateExtension.m', 'nwbClearGenerated.m', 'nwbInstallExtension.m'};
    isWhitelisted = ismember(rootFileNames, rootWhitelist);
    
    rootFiles(~isWhitelisted) = [];

    [~, ~, iC] = intersect(rootWhitelist, {rootFiles.name}, 'stable');
    rootFiles = rootFiles(iC);
    
    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    exportDir = fullfile(docsSourceRootDir, 'pages', 'functions');
    if ~isfolder(exportDir); mkdir(exportDir); end

    functionTemplate = fileread( getRstTemplateFile('function') );
    classTemplate = fileread( getRstTemplateFile('class') );

    for i = 1:numel(rootFiles)
        iFile = fullfile(rootFiles(i).folder, rootFiles(i).name);
        [~, functionName] = fileparts(iFile);

        mc = meta.class.fromName(functionName);
        if isempty(mc)
            currentTemplate = functionTemplate;
        else
            currentTemplate = classTemplate;
        end

        data.function_name = functionName;
        data.module_name = '.';
        data.function_header_underline = repmat('=', 1, numel(functionName));
        data.full_function_name = functionName;
    
        thisRst = fillTemplate(currentTemplate, data);
        rstFilePath = fullfile(exportDir, [functionName, '.rst']);
        filewrite(rstFilePath, thisRst);
    end

    % Create index
    indexTemplate = fileread( getRstTemplateFile('index_functions') );
    [~, functionNames] = fileparts(string({rootFiles.name}));
    data.function_list = strjoin("   "+functionNames, newline);
    
    thisRst = fillTemplate(indexTemplate, data);
    rstFilePath = fullfile(exportDir, ['index', '.rst']);
    filewrite(rstFilePath, thisRst);
end
