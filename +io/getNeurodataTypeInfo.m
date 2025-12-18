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
        typeInfo.typename = matnwb.common.composeFullClassName(...
            typeInfo.namespace, typeInfo.name);

        if strcmp(typeInfo.namespace, 'hdmf-experimental') && ~exist(typeInfo.typename, 'class')
            typeInfo = correctNamespaceIfShouldBeHdmfCommon(typeInfo);
        end 
    end
end

function typeInfo = correctNamespaceIfShouldBeHdmfCommon(typeInfo)
% correctNamespaceIfShouldBeHdmfCommon - Correct namespace if value in file is wrong.
%
% This function provides a workaround for a bug where the namespace of a 
% neurodata type was wrongly written to file as hdmf-experimental instead
% of hdmf-common.
% 
% If the namespace of a type is hdmf-experimental, and the corresponding type 
% class does not exist in MATLAB, but the equivalent hdmf_common class exists, 
% the namespace is changed from hdmf-experimental to hdmf-common.
%
% The bug is described in this issue: 
% https://github.com/hdmf-dev/hdmf/issues/1347#issuecomment-3662210800

    if strcmp(typeInfo.namespace, 'hdmf-experimental') && ~exist(typeInfo.typename, 'class')
        correctedTypename = replace(typeInfo.typename, 'hdmf_experimental', 'hdmf_common');
        if exist(correctedTypename, 'class') == 8
            typeInfo.typename = correctedTypename;
            typeInfo.namespace = 'hdmf-common';
        end
    end
end
