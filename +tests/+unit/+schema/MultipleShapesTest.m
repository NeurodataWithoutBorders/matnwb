classdef MultipleShapesTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "multipleShapesSchema"
        SchemaNamespaceFileName = "mss.namespace.yaml"
    end

    methods (Test)
        function testMultipleShapesDataset(testCase)
            msd = types.mss.MultiShapeDataset('data', rand(3, 1));
            msd.data = rand(1, 5, 7);
            testCase.roundabout(msd);
        end
        
        function testNullShapeDataset(testCase)
            nsd = types.mss.NullShapeDataset;
            randiMax = intmax('int8') - 1;
            for i=1:100
                %test validation
                nsd.data = rand(randi(randiMax) + 1, 3);
            end
            testCase.roundabout(nsd);
        end
        
        function testMultipleNullShapesDataset(testCase)
            mnsd = types.mss.MultiNullShapeDataset;
            randiMax = intmax('int8');
            for i=1:100
                if rand() > 0.5
                    mnsd.data = rand(randi(randiMax), 1);
                else
                    mnsd.data = rand(randi(randiMax), randi(randiMax));
                end
            end
            testCase.roundabout(mnsd);
        end
        
        function testInheritedDtypeDataset(testCase)
            nid = types.mss.NarrowInheritedDataset;
            nid.data = 'Inherited Dtype Dataset';
            testCase.roundabout(nid);
        end
    end

    methods (Access = private)
        %% Convenience
        function roundabout(testCase, dataset)
            nwb = NwbFile('identifier', 'MSS', 'session_description', 'test',...
                'session_start_time', '2017-04-15T12:00:00.000000-08:00',...
                'timestamps_reference_time', '2017-04-15T12:00:00.000000-08:00');
            wrapper = types.mss.MultiShapeWrapper('shaped_data', dataset);
            nwb.acquisition.set('wrapper', wrapper);
            filename = 'multipleShapesTest.nwb';
            nwbExport(nwb, filename);
            tests.util.verifyContainerEqual(testCase, nwbRead(filename, 'ignorecache'), nwb);
        end
    end
end
