classdef ValidatorTest < matlab.unittest.TestCase
% ValidatorTest - Unit test for validators.

    methods (Test)
        function testInvalidVersionNumberFormat(testCase)            
            testCase.verifyError( ...
                @(vn) matnwb.common.mustBeValidSchemaVersion('1.0'), ...
                'NWB:VersionValidator:InvalidVersionNumber')
        end

        function testVectorDataValidator(testCase)
            
            % Verify that it passes on VectorData
            matnwb.common.validation.mustBeVectorData(types.hdmf_common.VectorData())
    
            % Verify that validation fails for DynamicTable
            testCase.verifyError( ...
                @(vn) matnwb.common.validation.mustBeVectorData(types.hdmf_common.DynamicTable()), ...
                'NWB:validators:mustBeVectorData')
        end

        function testDynamicTableValidator(testCase)
            
            % Verify that it passes on DynamicTable
            matnwb.common.validation.mustBeDynamicTable(types.hdmf_common.DynamicTable())
    
            % Verify that validation fails for VectorData
            testCase.verifyError( ...
                @(vn) matnwb.common.validation.mustBeDynamicTable(types.hdmf_common.VectorData()), ...
                'NWB:validators:mustBeDynamicTable')
        end
    end 
end