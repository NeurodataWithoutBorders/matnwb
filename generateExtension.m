function generateExtension(namespaceFilePath, options)
% GENERATEEXTENSION - Generate Matlab classes from NWB extension schema file
%
% Syntax:
%  GENERATEEXTENSION(extension_path...) Generate classes (Matlab m-files) 
%  from one or more NWB schema extension namespace files. A registry of 
%  already generated core types is used to resolve dependent types.
%
%  A cache of schema data is generated in the ``namespaces`` subdirectory in
%  the matnwb root directory.  This is for allowing cross-referencing
%  classes between multiple namespaces.
%
%  Output files are placed in a ``+types`` subdirectory in the
%  matnwb root directory directory.
%
%  Generated classes are also kept in a cache folder, one entry per
%  namespace version. When classes for the same specification were
%  generated before, by the same version of the generator and against the
%  same dependencies, they are copied from the cache instead of being
%  generated again. See generateCore for where the cache folder is.
%
% Input Arguments:
%  - namespaceFilePath (string) - 
%    Filepath pointing to a schema extension namespace file. This is a
%    repeating argument, so multiple filepaths can be provided
% 
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%  
%    - savedir (string) -
%      A folder to save generated classes for NWB/extension types.
%
% Usage:
%  Example 1 - Generate classes for custom schema extensions::
%
%    generateExtension('schema\myext\myextension.namespace.yaml', 'schema\myext2\myext2.namespace.yaml');
%
% See also:
%   generateCore

    arguments (Repeating)
        namespaceFilePath (1,1) string {mustBeYamlFile}
    end
    arguments
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    assert( ...
        ~isempty(namespaceFilePath), ...
        'NWB:GenerateExtension:NamespaceMissing', ...
        'Please provide the file path to at least one namespace specification file.' ...
        )

    namespaceInfoList = cell(size(namespaceFilePath));
    for iNamespaceFiles = 1:length(namespaceFilePath)
        source = namespaceFilePath{iNamespaceFiles};
        namespaceText = fileread(source);
        [namespaceRootFolder, ~, ~] = fileparts(source);
        namespaceInfoList{iNamespaceFiles} = spec.generate(namespaceText, namespaceRootFolder);
    end
    matnwb.internal.typecache.generateNamespaces([namespaceInfoList{:}], options.savedir)
end

function mustBeYamlFile(filePath)
    arguments
        filePath (1,1) string {matnwb.common.compatibility.mustBeFile}
    end
    
    assert(endsWith(filePath, [".yaml", ".yml"], "IgnoreCase", true), ...
        'NWB:GenerateExtension:MustBeYaml', ...
        'Expected file to point to a yaml file', filePath)
end
