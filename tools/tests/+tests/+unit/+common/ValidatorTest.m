classdef ValidatorTest < matlab.unittest.TestCase
% ValidatorTest - Unit test for validators.

    methods (Test)
        function testInvalidVersionNumberFormat(testCase)            
            testCase.verifyError( ...
                @(vn) matnwb.common.mustBeValidSchemaVersion('1.0'), ...
                'NWB:VersionValidator:InvalidVersionNumber')
        end
    end 
end