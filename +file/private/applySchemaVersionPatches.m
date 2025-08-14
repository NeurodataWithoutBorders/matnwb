function classSpec = applySchemaVersionPatches(className, classSpec, propSpecs, namespaceInfo)
% applySchemaVersionPatches - Applies patches to schema specifications for classes.

    switch className
        case 'ScratchData'
            % Spec does not define a shape, so it defaults to scalar, but
            % scratch data can be non-scalar
            fixShapeForDataProp(propSpecs)

        case {'VectorData', 'VectorIndex'} % NWB v2.0.2 - v2.2.1
            % Spec for older NWB versions did not define a shape, so it 
            % defaults to scalar, but these types support non-scalar data
            if strcmp(namespaceInfo.name, 'core') && ...
                    ismember(namespaceInfo.version, {'2.0.2', '2.1.0'})
                fixShapeForDataProp(propSpecs)
                classSpec = fixShapeForDataClass(classSpec);
            elseif strcmp(namespaceInfo.name, 'hdmf_common') && ...
                    ismember(namespaceInfo.version, {'1.1.0', '1.1.2'})
                fixShapeForDataProp(propSpecs)
                classSpec = fixShapeForDataClass(classSpec);
            end
    end
end

function fixShapeForDataProp(propSpecs)
    dataProp = propSpecs('data');
    dataProp.shape = nan;
    dataProp.scalar = false;
    propSpecs('data') = dataProp; %#ok<NASGU> Map is a handle object
end
function classSpec = fixShapeForDataClass(classSpec)
    classSpec.shape = nan;
    classSpec.scalar = false;
end
