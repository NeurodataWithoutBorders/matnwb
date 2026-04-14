classdef ValidatorTest < matlab.unittest.TestCase
% ValidatorTest - Unit test for validators.

    methods (Test)
        function testInvalidVersionNumberFormat(testCase)            
            testCase.verifyError( ...
                @(vn) matnwb.common.mustBeValidSchemaVersion('1.0'), ...
                'NWB:VersionValidator:InvalidVersionNumber')
        end

        function testDynamicTableValidator(testCase)
            
            % Verify that validation passes for DynamicTable object
            try
                dynamicTable = types.hdmf_common.DynamicTable();
                matnwb.common.validation.mustBeDynamicTable(dynamicTable)
            catch exception
                diagnosticMessage = sprintf(...
                    ['Unexpected validation failure for DynamicTable. ', ...
                    'Reason: %s'], exception.message);
                testCase.verifyFail(diagnosticMessage)
            end

            % Verify that validation fails for non-DynamicTable object
            vectorData = types.hdmf_common.VectorData();
            testCase.verifyError(...
                @() matnwb.common.validation.mustBeDynamicTable(vectorData), ...
                'NWB:validators:mustBeDynamicTable')
        end
    end 
end