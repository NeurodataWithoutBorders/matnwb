classdef IsBoolTest < matlab.unittest.TestCase
% IsBoolTest - Unit test for io.isBool function.

    methods (Test)
        function testInvalidInput(testCase)
            testCase.verifyError(@(x) io.isBool("string"), ...
                'NWB:IO:IsBool:InvalidArgument')
        end
    end 
end