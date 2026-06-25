classdef ReportSchemaViolationTest < matlab.unittest.TestCase
% ReportSchemaViolationTest - Unit tests for types.util.reportSchemaViolation.

    methods (TestMethodTeardown)
        function resetValidationContext(~)
            types.util.validationContext('strict');
        end
    end

    methods (Test)
        function testStrictContextRaisesErrorWithCauses(testCase)
            types.util.validationContext('strict');
            cause = MException( ...
                'NWB:Test:Cause', 'The nested validation failed.');

            try
                types.util.reportSchemaViolation( ...
                    'NWB:Test:SchemaViolation', ...
                    "The value does not match the schema.", cause)
                testCase.verifyFail( ...
                    'Expected reportSchemaViolation to throw an error.')
            catch exception
                testCase.verifyEqual( ...
                    exception.identifier, 'NWB:Test:SchemaViolation')
                testCase.verifyEqual( ...
                    exception.message, 'The value does not match the schema.')
                testCase.verifyNumElements(exception.cause, 1)
                testCase.verifyEqual( ...
                    exception.cause{1}.identifier, 'NWB:Test:Cause')
            end
        end

        function testReadContextWarnsWithGuidanceAndCauseMessages(testCase)
            types.util.validationContext('read');
            cause = MException( ...
                'NWB:Test:Cause', 'The nested validation failed.');

            lastwarn('')
            testCase.verifyWarning( ...
                @() types.util.reportSchemaViolation( ...
                    'NWB:Test:SchemaViolation', ...
                    "The value does not match the schema.", cause), ...
                'NWB:Test:SchemaViolation')

            [warningMessage, warningId] = lastwarn;
            testCase.verifyEqual(warningId, 'NWB:Test:SchemaViolation')
            testCase.verifySubstring( ...
                warningMessage, 'The value does not match the schema.')
            testCase.verifySubstring( ...
                warningMessage, 'The nested validation failed.')
            testCase.verifySubstring( ...
                warningMessage, 'The value read from the file is kept')
        end
    end
end
