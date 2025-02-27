classdef MultipleConstrainedTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "multipleConstrainedSchema"
        SchemaNamespaceFileName = "mcs.namespace.yaml"
    end

    methods (Test)
        function testRoundabout(testCase)
            multiSet = types.mcs.MultiSetContainer();
            multiSet.something.set('A', types.mcs.ArbitraryTypeA());
            multiSet.something.set('B', types.mcs.ArbitraryTypeB());
            multiSet.something.set('Data', types.mcs.DatasetType('data', ones(3,3)));
            nwbExpected = NwbFile(...
                'identifier', 'MCS', ...
                'session_description', 'multiple constrained schema testing', ...
                'session_start_time', datetime());
            nwbExpected.acquisition.set('multiset', multiSet);
            nwbExport(nwbExpected, 'testmcs.nwb');
        
            tests.util.verifyContainerEqual(testCase, nwbRead('testmcs.nwb', 'ignorecache'), nwbExpected);
        end
    end
end
