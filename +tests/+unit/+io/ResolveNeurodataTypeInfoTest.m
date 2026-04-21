classdef ResolveNeurodataTypeInfoTest < matlab.unittest.TestCase

    methods (Test)
        function resolveElectrodesTableFromLegacyDynamicTable(testCase)
            typeInfo = struct( ...
                'namespace', 'hdmf-common', ...
                'name', 'DynamicTable', ...
                'typename', 'types.hdmf_common.DynamicTable');

            resolvedTypeInfo = io.resolveNeurodataTypeInfo( ...
                typeInfo, '/general/extracellular_ephys/electrodes');

            testCase.verifyEqual(resolvedTypeInfo.namespace, 'core');
            testCase.verifyEqual(resolvedTypeInfo.name, 'ElectrodesTable');
            testCase.verifyEqual(resolvedTypeInfo.typename, 'types.core.ElectrodesTable');
        end

        function keepOtherDynamicTablesUnchanged(testCase)
            typeInfo = struct( ...
                'namespace', 'hdmf-common', ...
                'name', 'DynamicTable', ...
                'typename', 'types.hdmf_common.DynamicTable');

            resolvedTypeInfo = io.resolveNeurodataTypeInfo(typeInfo, '/units');

            testCase.verifyEqual(resolvedTypeInfo, typeInfo);
        end
    end
end
