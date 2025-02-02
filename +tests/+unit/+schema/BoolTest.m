classdef BoolTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "boolSchema"
        SchemaNamespaceFileName = "bool.namespace.yaml"
    end

    methods (Test)
        function testIo(testCase)
            nwb = NwbFile(...
                'identifier', 'BOOL',...
                'session_description', 'test bool',...
                'session_start_time', datetime());
            boolContainer = types.bool.BoolContainer(...
                'data', logical(randi([0,1], 100, 1)), ...
                'attribute', false);
            scalarBoolContainer = types.bool.BoolContainer(...
                'data', false, ...
                'attribute', true);
            nwb.acquisition.set('bool', boolContainer);
            nwb.acquisition.set('scalarbool', scalarBoolContainer);
            nwb.export('test.nwb');
            nwbActual = nwbRead('test.nwb', 'ignorecache');
            tests.util.verifyContainerEqual(testCase, nwbActual, nwb);
        end
    end
end
