classdef SpaceTest < matlab.unittest.TestCase
% SpaceTest - Unit test for io.space.* namespace.

    methods (Test)
        function testEmptyInput(testCase)
            shape = io.space.findShapes([]);

            testCase.verifyClass(shape, 'cell')
            testCase.verifyLength(shape, 1)
            testCase.verifyClass(shape{1}, 'io.space.shape.Block')
        end

        function testSegmentSelection(testCase)
            shape = io.space.segmentSelection({1:10}, [1,100]);
            
            testCase.verifyClass(shape, 'cell')
        end

        function testPoint(testCase)
            point = io.space.shape.Point(1);
            
            testCase.verifyEqual(point.getMatlabIndex, 1)
        end
    end 
end