function namespace = loadNamespace(namespaceName, generatedTypesDirectory)
%LOADNAMESPACE - Load cached specifications for a namespace with dependency graph
%
% Input Arguments:
%   namespaceName (string) : Name of a format specification namespace, i.e "core"
%   generatedTypesDirectory (string) : Optional, path name of directory
%       where generated classes for neurodata types are located
%   
% Output Arguments:
%   namespace (schemes.Namespace) - Namespace object with a dependency graph

    arguments
        namespaceName (1,1) string
        generatedTypesDirectory (1,1) string {matnwb.common.compatibility.mustBeFolder} = ...
            schemes.utility.findRootDirectoryForGeneratedTypes()
    end

    cachedNamespaceSpecification = spec.loadCache(namespaceName, 'savedir', generatedTypesDirectory);
    assert( ~isempty(cachedNamespaceSpecification), ...
        'NWB:Namespace:CacheMissing',...
        ['No cache found for namespace `%s`.\nPlease use generateCore or ' ...
        'generateExtension to initialize a cache for the `%s` namespace.'], ...
        namespaceName, namespaceName);
    
    ancestry = schemes.Namespace.empty(length(cachedNamespaceSpecification.dependencies), 0);
    for i = length(cachedNamespaceSpecification.dependencies):-1:1
        ancestorName = cachedNamespaceSpecification.dependencies{i};
        ancestry(i) = schemes.loadNamespace(ancestorName, generatedTypesDirectory);
    end
    
    namespace = schemes.Namespace(...
        namespaceName, ...
        cachedNamespaceSpecification.version, ...
        ancestry, ...
        cachedNamespaceSpecification.schema);
end
