function typeInfo = resolveNeurodataTypeInfo(typeInfo, nodePath)
% resolveNeurodataTypeInfo - Apply path-based corrections for legacy type info.

    arguments
        typeInfo (1,1) struct
        nodePath {mustBeTextScalar}
    end

    if strcmp(typeInfo.typename, 'types.hdmf_common.DynamicTable') ...
            && strcmp(char(nodePath), '/general/extracellular_ephys/electrodes') ...
            && exist('types.core.ElectrodesTable', 'class') == 8
        typeInfo.namespace = 'core';
        typeInfo.name = 'ElectrodesTable';
        typeInfo.typename = 'types.core.ElectrodesTable';
    end
end
