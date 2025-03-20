function generateRstForNwbFunctions(functionList, namespace, rstPageTitle, description)
% generateRstForNwbFunctions Recursively generate rst files for MATLAB functions and classes.
%
%   generateRstForNwbFunctions(functionList, namespace) partitions the
%   functionList into functions that belong to the current namespace and those in deeper
%   namespaces, processes the current functions by generating rst files and an index,
%   and then recursively calls itself on the deeper namespaces.

    if nargin < 3; rstPageTitle = namespace; end
    if nargin < 4; description = ''; end

    % Get root directories for the repository and the rst export location.
    codeRootDir = misc.getMatnwbDir();
    docsSourceRootDir = fullfile(codeRootDir, 'docs', 'source');
    exportBaseDir = fullfile(docsSourceRootDir, 'pages', 'functions');

    % Convert current namespace into a relative path for output.
    relativePathName = namespaceToPathName(namespace);
    exportDir = fullfile(exportBaseDir, relativePathName);
    if ~isfolder(exportDir)
        mkdir(exportDir);
    end

    % Read in the rst templates.
    functionTemplate = fileread(getRstTemplateFile('function'));
    classTemplate    = fileread(getRstTemplateFile('class'));
    indexTemplate    = fileread(getRstTemplateFile('index_functions'));

    % Partition functionList into current-level functions and subnamespace functions
    [namespaceMap, currentFunctions] = groupFunctionsByNamespace(functionList, namespace);

    for i = 1:numel(currentFunctions)

        fullFunctionName = currentFunctions(i);
        mc = meta.class.fromName(fullFunctionName);
        if isempty(mc)
            currentTemplate = functionTemplate;
        else
            currentTemplate = classTemplate;
        end
        
        % Prepare data for template filling.
        pattern = '[^.]+$';
        shortFunctionName = regexp(fullFunctionName, pattern, 'match', 'once');
        data.function_name = shortFunctionName;

        if isempty(char(namespace))
            data.module_name = '.';
        else
            data.module_name = namespace;
        end
        data.function_header_underline = repmat('=', 1, strlength(shortFunctionName));
        data.full_function_name = fullFunctionName;
        
        % Fill in the template.
        thisRst = fillTemplate(currentTemplate, data);
        rstFilePath = fullfile(exportDir, fullFunctionName + ".rst");
        filewrite(rstFilePath, thisRst);
    end

    % Create index file for the current namespace.
    % List current-level functions:
    if isempty(currentFunctions)
        funcListStr = "";
    else
        % Each element in the index.rst is indented by 3 spaces.
        funcListStr = strjoin("   " + currentFunctions, newline);
    end
    
    % Also, if there are subnamespaces, include them in the index.
    subNamespaces = keys(namespaceMap);
    subNamespaces = subNamespaces + "/index";
    if ~isempty(subNamespaces)
        subNamespaceListStr = strjoin("   " + string(subNamespaces), newline);
    else
        subNamespaceListStr = "";
    end

    % Combine the two lists for the index.
    data.function_list = funcListStr + newline + subNamespaceListStr;
    
    if ~isempty(char(namespace))
        rstPageTitle = sprintf("+%s", rstPageTitle);
    end

    data.title = rstPageTitle;
    data.title_underline = repmat('=', 1, strlength(rstPageTitle));
    data.module_description = description;

    thisRst = fillTemplate(indexTemplate, data);
    rstIndexFilePath = fullfile(exportDir, "index.rst");
    filewrite(rstIndexFilePath, thisRst);
    
    % Now recursively process each subnamespace:
    subNamespaces = keys(namespaceMap);
    for k = 1:numel(subNamespaces)
        subNamespaceK = subNamespaces{k};
        subFunctions = namespaceMap(subNamespaceK);
        % Build new namespace string. If current namespace is empty, new 
        % namespace is subNamespaceK otherwise, append with dot.
        if isempty(namespace)
            newNamespace = subNamespaceK;
        else
            newNamespace = namespace + "." + subNamespaceK;
        end
        generateRstForNwbFunctions(subFunctions, newNamespace);
    end
end

%% Helper functions
function pathName = namespaceToPathName(namespace)
    if isempty(namespace)
        pathName = "";
    else
        namespaceParts = strsplit(namespace, '.');
        pathName = fullfile(namespaceParts{:});
    end
end

function [namespaceMap, currentFunctions] = groupFunctionsByNamespace(functionList, rootNamespace)

    % Partition functionList into current-level functions and sub-namespace functions
    currentFunctions = string.empty;
    namespaceMap = containers.Map(); % keys: immediate subnamespace, values: cell array of function names
    
    % Determine the parts that define the current namespace.
    if isempty(rootNamespace)
        currentNamespaceParts = {};
    else
        currentNamespaceParts = strsplit(rootNamespace, '.');
    end
    
    % Loop over the function list and partition.
    for i = 1:numel(functionList)
        fullFunctionName = char(functionList(i));
        functionParts = strsplit(fullFunctionName, '.');
        
        % Check if the function belongs to the current namespace.
        if numel(currentNamespaceParts) > numel(functionParts)
            % The function does not have enough namespace parts to match.
            continue;
        end
        
        % Compare the functions's initial parts to currentNamespaceParts.
        if ~isempty(currentNamespaceParts)
            if ~isequal(functionParts(1:numel(currentNamespaceParts)), currentNamespaceParts)
                % Not part of this namespace.
                continue;
            end
        end
        
        if numel(functionParts) == numel(currentNamespaceParts) + 1
            % Function is defined in this namespace.
            currentFunctions(end+1) = string(fullFunctionName); %#ok<AGROW>
        elseif numel(functionParts) > numel(currentNamespaceParts) + 1
            % Function belongs to a subnamespace.
            subKey = functionParts{numel(currentNamespaceParts)+1};
            if ~namespaceMap.isKey(subKey)
                namespaceMap(subKey) = string.empty;
            end
            subNamespaceFunctions = namespaceMap(subKey);
            subNamespaceFunctions(end+1) = string(fullFunctionName); %#ok<AGROW>
            namespaceMap(subKey) = subNamespaceFunctions;
        end
    end
end
