classdef AnonTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "anonSchema"
        SchemaNamespaceFileName = "anon.namespace.yaml"
    end

    methods (Test)
        function testAnonDataset(testCase)
            ag = types.anon.AnonGroup('ad', types.anon.AnonData('data', 0));
            nwbExpected = NwbFile(...
                'identifier', 'ANON',...
                'session_description', 'anonymous class schema testing',...
                'session_start_time', datetime());
            nwbExpected.acquisition.set('ag', ag);
            nwbExport(nwbExpected, 'testanon.nwb');
            
            tests.util.verifyContainerEqual(testCase, nwbRead('testanon.nwb', 'ignorecache'), nwbExpected);
        end
        
        function testAnonTypeWithNameValueInput(testCase)
            anon = types.untyped.Anon('a', 1);
            testCase.verifyEqual(anon.name, 'a')
            testCase.verifyEqual(anon.value, 1)
        end
    end
end
