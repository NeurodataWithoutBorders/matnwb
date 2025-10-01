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
    end
end
