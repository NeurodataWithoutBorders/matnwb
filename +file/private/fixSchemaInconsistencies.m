function fixSchemaInconsistencies(name, props, namespaceInfo)

    switch name
        case 'ScratchData'
            fixShapeForDataProp(props)

        case 'VectorData'
            if strcmp(namespaceInfo.name, 'core') && ...
                    ismember(namespaceInfo.version, {'2.0.2', '2.1.0'})
                fixShapeForDataProp(props)
            elseif strcmp(namespaceInfo.name, 'hdmf_common') && ...
                    ismember(namespaceInfo.version, {'1.1.0', '1.1.2'})
                fixShapeForDataProp(props)
            end
    end
end

function fixShapeForDataProp(props)
    dataProp = props('data');
    dataProp.shape = nan;
    props('data') = dataProp; %#ok<NASGU> Map is a handle object
end
