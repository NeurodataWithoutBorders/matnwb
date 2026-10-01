function typeInfo = getNeurodataTypeInfo(attributeInfo)
% getNeurodataTypeInfo - Get neurodata type info from attribute info structure
%
% Syntax:
%   typeInfo = io.getNeurodataTypeInfo(attributeInfo) 
%
% Input Arguments:
%   attributeInfo - A struct containing attributes information from which to 
%                   extract neurodata type information.
%
% Output Arguments:
%   typeInfo - A struct containing 'namespace', 'name', and 'typename'
%              fields describing the neurodata type. Fields are empty
%              character vectors if neurodata type info is not present.

    % Todo: return empty structure instead. Requires updating functions that use output
    typeInfo = struct('namespace', '', 'name', '', 'typename', '');
    
    if isempty(attributeInfo)
        return
    end
    
    names = {attributeInfo.Name};
    
    % Get neurodata_type if present
    typeDefMask = strcmp(names, 'neurodata_type');
    hasTypeDef = any(typeDefMask);
    if hasTypeDef
        typeDef = attributeInfo(typeDefMask).Value;
        if iscellstr(typeDef) %#ok<ISCLSTR>
            typeDef = typeDef{1};
        end
        typeInfo.name = typeDef;
    end
    
    % Get namespace if present
    namespaceMask = strcmp(names, 'namespace');
    hasNamespace = any(namespaceMask);
    if hasNamespace
        namespace = attributeInfo(namespaceMask).Value;
        if iscellstr(namespace) %#ok<ISCLSTR>
            namespace = namespace{1};
        end
        typeInfo.namespace = namespace;
    end
    
    % Get full classname given a namespace and a neurodata type
    if hasTypeDef && hasNamespace
        typeInfo.typename = char( matnwb.common.composeFullClassName(...
            typeInfo.namespace, typeInfo.name) );

        if ~isClassName(typeInfo.typename)
            typeInfo = tryCorrectNamespace(typeInfo);
        end
    end
end

function typeInfo = tryCorrectNamespace(typeInfo)
% tryCorrectNamespace - Try to correct namespace if type class doesn't exist
%
% Some NWB files have incorrect namespace values written to them.
% This function attempts to find the correct namespace by checking
% if an equivalent class exists in hdmf_common.
%
% Known issues:
%   - hdmf-experimental instead of hdmf-common (https://github.com/hdmf-dev/hdmf/issues/1347)
%   - core instead of hdmf-common (https://github.com/NeurodataWithoutBorders/helpdesk/discussions/104)

    % Map of namespace values that might be incorrectly used instead of hdmf-common
    namespaceNames = {'hdmf-experimental', 'core'};
    packageNames = {'hdmf_experimental', 'core'}; % Corresponding MATLAB package names
    namespaceToPackage = containers.Map(namespaceNames, packageNames);
    
    if ~isKey(namespaceToPackage, typeInfo.namespace)
        return
    end
    
    currentPackage = namespaceToPackage(typeInfo.namespace);
    correctedTypename = strrep(typeInfo.typename, ...
        [currentPackage '.'], 'hdmf_common.');
    
    if isClassName(correctedTypename)
        typeInfo.typename = correctedTypename;
        typeInfo.namespace = 'hdmf-common';
    end
end

function tf = isClassName(className)
% isClassName - Check whether a name refers to a class on the MATLAB path.
%
% This runs once for every typed object in a file being read. exist searches
% the path on every call, whereas meta.class.fromName reuses class
% definitions MATLAB has already loaded.
    tf = ~isempty(meta.class.fromName(className));
end
