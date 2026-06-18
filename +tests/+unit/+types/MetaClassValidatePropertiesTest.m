classdef MetaClassValidatePropertiesTest < matlab.unittest.TestCase
% MetaClassValidatePropertiesTest - Unit tests for MetaClass.validateProperties,
% the export-time guard that re-runs property validators so that values which
% bypassed strict validation cannot be written back out to a file.

    methods (Test)
        function testInvalidPropertyValueRaisesError(testCase)
            testType = tests.unit.types.doubles.TypeWithFailingValidator();
            testType.invalidProperty = 1;

            testCase.verifyError( ...
                @() testType.runValidateProperties('/some/path'), ...
                'NWB:Export:InvalidPropertyValue')
        end

        function testErrorIncludesPropertyLocationAndCause(testCase)
            testType = tests.unit.types.doubles.TypeWithFailingValidator();
            testType.invalidProperty = 1;

            try
                testType.runValidateProperties('/some/path')
                testCase.verifyFail('Expected an error for the invalid property value.')
            catch exception
                testCase.verifyEqual( ...
                    exception.identifier, 'NWB:Export:InvalidPropertyValue')
                testCase.verifyTrue(contains(exception.message, 'invalidProperty'))
                testCase.verifyTrue(contains(exception.message, '/some/path'))
                % The original validator error is preserved as a cause.
                testCase.verifyNotEmpty(exception.cause)
                testCase.verifyEqual( ...
                    exception.cause{1}.identifier, 'NWB:Test:InvalidPropertyValue')
            end
        end

        function testEmptyPropertyIsNotValidated(testCase)
            % An unset (empty) property is skipped even though its validator
            % would fail, because empty optional properties are not exported.
            testType = tests.unit.types.doubles.TypeWithFailingValidator();

            testCase.verifyWarningFree( ...
                @() testType.runValidateProperties('/some/path'))
        end

        function testValidPropertyValuePasses(testCase)
            testType = tests.unit.types.doubles.TypeWithFailingValidator();
            testType.validProperty = 42;

            testCase.verifyWarningFree( ...
                @() testType.runValidateProperties('/some/path'))
        end

        function testCoercingValidatorRaisesError(testCase)
            % A validator that changes (coerces) the value must produce an
            % error, because the exported value would differ from what the
            % validator accepted.
            testType = tests.unit.types.doubles.TypeWithFailingValidator();
            testType.coercingProperty = int32(5);  % int32 -> double on validate

            testCase.verifyError( ...
                @() testType.runValidateProperties('/some/path'), ...
                'NWB:Export:InvalidPropertyValue')
        end
    end
end
