function clearedNamespaceNames = nwbClearGenerated(targetFolder, options)
% NWBCLEARGENERATED - Clear generated class files.
%
% Syntax:
%  NWBCLEARGENERATED() Clear generated class files from the ``+types``
%  folder in the matnwb root directory.
%
% Input Arguments:
%  - targetFolder (string) - 
%    Path name for folder containing generated classes in a ``+types``
%    namespace folder. Default value is the matnwb root directory
% 
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%  
%    - ClearCache (logical) -
%      Whether to clear the cached schema data in the ``namespaces`` folder.
%      Default is ``false``
%
% Usage:
%  Example 1 - Clear all generated classes in the matnwb root directory::
%
%    nwbClearGenerated();
%
% See also:
%   generateCore, generateExtension
    
    arguments
        targetFolder (1,1) string  {mustBeFolder} = misc.getMatnwbDir()
        options.ClearCache (1,1) logical = false
    end

    typesPath = fullfile(targetFolder, '+types');
    listing = dir(typesPath);
    moduleNames = setdiff({listing.name}, {'+untyped', '+util', '.', '..'});
    generatedPaths = fullfile(typesPath, moduleNames);
    for i=1:length(generatedPaths)
        if isfolder(generatedPaths{i})
            rmdir(generatedPaths{i}, 's');
        end
    end

    if options.ClearCache
        cachePath = fullfile(targetFolder, 'namespaces');
        listing = dir(fullfile(cachePath, '*.mat'));
        generatedPaths = fullfile(cachePath, {listing.name});
        for i=1:length(generatedPaths)
            delete(generatedPaths{i});
        end
    end

    if nargout == 1 % Return names of cleared namespaces
        [~, clearedNamespaceNames] = fileparts(generatedPaths);
        clearedNamespaceNames = strrep(clearedNamespaceNames, '+', '');
        clearedNamespaceNames = string(clearedNamespaceNames);
    end
end
