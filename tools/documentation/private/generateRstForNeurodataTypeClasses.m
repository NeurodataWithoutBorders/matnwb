function generateRstForNeurodataTypeClasses(namespaceName)
% generateRstForNeurodataTypeClasses Generate rst files for each Neurodata matnwb class
    
    arguments
        namespaceName (1,1) string
    end

    filenameToIgnore = {matnwb.common.constant.VERSIONFILE};

    namespaceName = char(namespaceName);

    rootDir = misc.getMatnwbDir();
    classFiles = dir(fullfile(rootDir, '+types', ['+', namespaceName], '*.m'));
    classFiles(ismember({classFiles.name}, filenameToIgnore)) = [];

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    exportDir = fullfile(docsSourceRootDir, 'pages', 'neurodata_types', namespaceName);
    if ~isfolder(exportDir); mkdir(exportDir); end

    functionTemplate = fileread( getRstTemplateFile('function') );
    classTemplate = fileread( getRstTemplateFile('neurodata_class') );

    for i = 1:numel(classFiles)
        iFile = fullfile(classFiles(i).folder, classFiles(i).name);
        [~, fileName] = fileparts(iFile);

        data.module_name = sprintf('types.%s', namespaceName);
        data.namespace_name = namespaceName;
        data.class_name = fileName;
        data.lower_class_name = lower(data.class_name);
        data.class_name_header_underline = repmat('=', 1, numel(data.class_name));
        data.full_class_name = sprintf('types.%s.%s', namespaceName, fileName);

        mc = meta.class.fromName(data.full_class_name);
        if isempty(mc)
            currentTemplate = functionTemplate;
        else
            currentTemplate = classTemplate;
        end

        thisRst = fillTemplate(currentTemplate, data);
        rstFilePath = fullfile(exportDir, [fileName, '.rst']);
        filewrite(rstFilePath, thisRst);
    end

    % Create index
    indexTemplate = fileread( getRstTemplateFile('index_nwb_types') );
    [~, functionNames] = fileparts(string({classFiles.name}));
    data.function_list = strjoin("   "+functionNames, newline);

    switch namespaceName
        case 'core'
            data.section_title = "Core Neurodata Types";
        case 'hdmf_common'
            data.section_title = "HDMF-Common Data Types";
        case 'hdmf_experimental'
            data.section_title = "HDMF-Experimental Data Types";     
    end
    data.section_title_underline = repmat('=', 1, strlength(data.section_title));
    
    thisRst = fillTemplate(indexTemplate, data);
    rstFilePath = fullfile(exportDir, ['index', '.rst']);
    filewrite(rstFilePath, thisRst);
end
