function class = fixSchemaInconsistencies(name, class, props, namespaceInfo)
    switch name
        case 'ScratchData'
            fixShapeForDataProp(props)

        case {'VectorData', 'VectorIndex'} % NWB v2.0.2 - v2.2.1
            if strcmp(namespaceInfo.name, 'core') && ...
                    ismember(namespaceInfo.version, {'2.0.2', '2.1.0'})
                fixShapeForDataProp(props)
                class = fixShapeForDataClass(class);
            elseif strcmp(namespaceInfo.name, 'hdmf_common') && ...
                    ismember(namespaceInfo.version, {'1.1.0', '1.1.2'})
                fixShapeForDataProp(props)
                class = fixShapeForDataClass(class);
            end
    end
end

function fixShapeForDataProp(props)
    dataProp = props('data');
    dataProp.shape = nan;
    dataProp.scalar = false;
    props('data') = dataProp; %#ok<NASGU> Map is a handle object
end
function class = fixShapeForDataClass(class)
    class.shape = nan;
    class.scalar = false;
end
