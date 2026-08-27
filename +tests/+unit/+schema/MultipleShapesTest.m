classdef MultipleShapesTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "multipleShapesSchema"
        SchemaNamespaceFileName = "mss.namespace.yaml"
    end

    methods (Test)
        function testShapeDatasetWithCorrectShape(testCase)
            numElements = 3;
            msd = types.mss.ShapeDataset('data', rand(numElements, 1));
            testCase.verifyClass(msd, 'types.mss.ShapeDataset');
            testCase.verifyEqual(size(msd.data), [numElements, 1]);
        end

        function testShapeDatasetWithWrongShape(testCase)
            numElements = 3;
            matrixData = rand(numElements, numElements);

            testCase.verifyError(...
                @() types.mss.ShapeDataset('data', matrixData), ...
                'NWB:CheckDims:InvalidDimensions');
        end

        function testMultipleShapesDataset(testCase)
            msd = types.mss.MultiShapeDataset('data', rand(3, 1));
            msd.data = rand(7, 5, 1); % NB: Reverse dimensions relative to schema due to MATLAB F-ordering
            testCase.roundabout(msd);
        end
        
        function testNullShapeDataset(testCase)
            nsd = types.mss.NullShapeDataset;
            randiMax = intmax('int8') - 1;
            for i=1:100
                %test validation
                nsd.data = rand(3, randi(randiMax) + 1); % NB: Reverse dimensions relative to schema due to MATLAB F-ordering
            end
            testCase.roundabout(nsd);
        end
        
        function testMultipleNullShapesDataset(testCase)
            % MultiNullShapeDataset accepts one-dimensional data of any length
            % and two-dimensional data of any size. Cover a scalar, a column
            % vector, a row vector and a matrix; assigning a shape the type does
            % not accept errors on assignment and fails the test.
            validShapes = {[1, 1], [23, 1], [1, 23], [7, 5]};

            mnsd = types.mss.MultiNullShapeDataset;
            for iShape = 1:numel(validShapes)
                mnsd.data = rand(validShapes{iShape});
            end

            % Export a matrix. One-dimensional data is written as a rank-1
            % dataset and read back as a column, so a row vector would not
            % compare equal after the round trip (see the dimension ordering
            % concept documentation).
            mnsd.data = rand(7, 5);
            testCase.roundabout(mnsd);
        end
        
        function testInheritedDtypeDataset(testCase)
            nid = types.mss.NarrowInheritedDataset;
            nid.data = 'Inherited Dtype Dataset';
            testCase.roundabout(nid);
        end

        function testInheritedDatasetWithWrongShape(testCase)
            % Should not fail for parent type that accepts data with shape 3
            types.mss.NullShapeDataset('data', {'A'; 'B'; 'C'});
    
            % Should fail for inherited type that accepts data with shape 1
            testCase.verifyError(...
                @() types.mss.NarrowInheritedDataset('data', {'A'; 'B'; 'C'}'), ...
                'NWB:CheckDims:InvalidDimensions');
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
