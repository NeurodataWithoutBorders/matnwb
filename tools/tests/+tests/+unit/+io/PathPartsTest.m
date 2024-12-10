classdef PathPartsTest < matlab.unittest.TestCase
% PathPartsTest - Unit test for io.pathParts function.

% Todo: Function has confusing naming of outputs. Should be fixed
    methods (Test)
        function testRootPath(testCase)
            [stem, root] = io.pathParts('root');
            testCase.verifyEqual(root, 'root')
            testCase.verifyEmpty(stem)
        end

        function testRootWithStemPath(testCase)
            [stem, root] = io.pathParts('root/stem');
            testCase.verifyEqual(root, 'stem')
            testCase.verifyEqual(stem, 'root')
        end
           
        function testRootWithLongerStemPath(testCase)
            [stem, root] = io.pathParts('root/stem/leaf');
            testCase.verifyEqual(root, 'leaf')
            testCase.verifyEqual(stem, 'root/stem')
        end
    end 
end