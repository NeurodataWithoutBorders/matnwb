function generateExtension(namespaceFilePath, options)
    % GENERATEEXTENSION Generate Matlab classes from NWB extension schema file
    %   GENERATEEXTENSION(extension_path...)  Generate classes
    %   (Matlab m-files) from one or more NWB schema extension namespace
    %   files.  A registry of already generated core types is used to resolve
    %   dependent types.
    %
    %   A cache of schema data is generated in the 'namespaces' subdirectory in
    %   the current working directory.  This is for allowing cross-referencing
    %   classes between multiple namespaces.
    %
    %   Output files are generated placed in a '+types' subdirectory in the
    %   current working directory.
    %
    %   Example:
    %      generateExtension('schema\myext\myextension.namespace.yaml', 'schema\myext2\myext2.namespace.yaml');
    %
    %   See also GENERATECORE
    
    arguments (Repeating)
        namespaceFilePath (1,1) string {mustBeYamlFile}
    end
    arguments
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    if isempty(namespaceFilePath)
        error('NWB:GenerateExtension:NamespaceMissing', ...
            'Please provide the file path to at least one namespace specification file.')
    end

    for iNamespaceFiles = 1:length(namespaceFilePath)

        source = namespaceFilePath{iNamespaceFiles};
        namespaceText = fileread(source);
                
        [namespaceRootFolder, ~, ~] = fileparts(source);
        parsedNamespaceList = spec.generate(namespaceText, namespaceRootFolder);
        
        for iNamespace = 1:length(parsedNamespaceList)
            parsedNamespace = parsedNamespaceList(iNamespace);
            spec.saveCache(parsedNamespace, options.savedir);
            file.writeNamespace(parsedNamespace.name, options.savedir);
        end
    end
    rehash()
end

function mustBeYamlFile(filePath)
    arguments
        filePath (1,1) string {mustBeFile}
    end
    
    assert(endsWith(filePath, [".yaml", ".yml"], "IgnoreCase", true), ...
        'NWB:GenerateExtension:MustBeYaml', ...
        'Expected file to point to a yaml file', filePath)
end
