classdef ReportSchemaViolationTest < matlab.unittest.TestCase
% ReportSchemaViolationTest - Unit tests for schema violation reporting.

    methods (TestMethodTeardown)
        function resetValidationContext(~)
            matnwb.common.validation.internal.context("edit");
            matnwb.common.validation.internal.reportingSource([]);
        end
    end

    methods (Test)
        function testEditContextRaisesErrorByDefault(testCase)
            matnwb.common.validation.internal.context("edit");
            cause = MException( ...
                'NWB:Test:Cause', 'The nested validation failed.');

            try
                matnwb.common.validation.reportSchemaViolation( ...
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
            matnwb.common.validation.internal.context("read");
            cause = MException( ...
                'NWB:Test:Cause', 'The nested validation failed.');

            lastwarn('')
            testCase.verifyWarning( ...
                @() matnwb.common.validation.reportSchemaViolation( ...
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
                warningMessage, 'The non-conforming value is kept.')
            testCase.verifyFalse(contains(warningMessage, 'While reading object'))
        end

        function testReadContextWarnsWithReportingSource(testCase)
            matnwb.common.validation.internal.context("read");
            source.TypeName = 'types.core.TimeSeries';
            source.Path = '/acquisition/bad_ts';
            matnwb.common.validation.internal.reportingSource(source);

            lastwarn('')
            testCase.verifyWarning( ...
                @() matnwb.common.validation.reportSchemaViolation( ...
                    'NWB:Test:SchemaViolation', ...
                    "The value does not match the schema."), ...
                'NWB:Test:SchemaViolation')

            [warningMessage, warningId] = lastwarn;
            testCase.verifyEqual(warningId, 'NWB:Test:SchemaViolation')
            testCase.verifySubstring(warningMessage, ...
                ['While reading object of type "types.core.TimeSeries" ' ...
                'at file location "/acquisition/bad_ts".'])
        end

        function testWarnInsteadOfErrorWarnsInEditContext(testCase)
            matnwb.common.validation.internal.context("edit");
            source.TypeName = 'types.core.TimeSeries';
            source.Path = '/acquisition/bad_ts';
            matnwb.common.validation.internal.reportingSource(source);

            testCase.verifyWarning( ...
                @() matnwb.common.validation.reportSchemaViolation( ...
                    'NWB:Test:SchemaViolation', ...
                    "The value does not match the schema.", ...
                    WarnInsteadOfError=true), ...
                'NWB:Test:SchemaViolation')

            [warningMessage, warningId] = lastwarn;
            testCase.verifyEqual(warningId, 'NWB:Test:SchemaViolation')
            testCase.verifyFalse(contains(warningMessage, 'While reading object'))
        end

        function testWriteContextRaisesErrorWithWarnInsteadOfError(testCase)
            matnwb.common.validation.internal.context("write");

            testCase.verifyError( ...
                @() matnwb.common.validation.reportSchemaViolation( ...
                    'NWB:Test:SchemaViolation', ...
                    "The value does not match the schema.", ...
                    WarnInsteadOfError=true), ...
                'NWB:Test:SchemaViolation')
        end
    end
end
