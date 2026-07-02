classdef ValidateSoftLinkTest < matlab.unittest.TestCase
% ValidateSoftLinkTest - Unit tests for types.util.validateSoftLink.

    methods (Test)
        function testWrongTargetTypeErrorsInEditContext(testCase)
            softLink = testCase.createSoftLinkWithTargetType('types.core.Device');
            testCase.verifyError( ...
                @() types.util.validateSoftLink( ...
                    'electrode_group', softLink, 'types.core.ElectrodeGroup'), ...
                'NWB:ValidateSoftLink:InvalidNeurodataType')
        end

        function testWrongTargetTypeWarnsInReadContext(testCase)
            softLink = testCase.createSoftLinkWithTargetType('types.core.Device');
            [~, cleanup] = matnwb.common.validation.internal.context("read"); %#ok<ASGLU>

            value = testCase.verifyWarning( ...
                @() types.util.validateSoftLink( ...
                    'electrode_group', softLink, 'types.core.ElectrodeGroup'), ...
                'NWB:ValidateSoftLink:InvalidNeurodataType');
            testCase.verifyClass(value, 'types.untyped.SoftLink')
        end
    end

    methods (Access = private)
        function softLink = createSoftLinkWithTargetType(testCase, targetType)
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'NWB:SoftLink:DeprecatedPath'));
            softLink = types.untyped.SoftLink('', targetType);
        end
    end
end
