classdef FunctionTests < matlab.unittest.TestCase
% FunctionTests - Unit test for functions.

    methods (Test)
        function testString2ValidName(testCase)
            testCase.verifyWarning( ...
                @(n,p) misc.str2validName('Time-Series', "test-a"), ...
                'NWB:CreateValidPropertyName:InvalidPrefix' )

            validName = misc.str2validName('@id', 'at');
            testCase.verifyEqual(string(validName), "at_id")
        end

        
    end 
end