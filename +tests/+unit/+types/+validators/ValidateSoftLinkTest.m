classdef ValidateSoftLinkTest < matlab.unittest.TestCase
% ValidateSoftLinkTest - Unit tests for types.util.validateSoftLink.
%   A soft link that declares the wrong target type is an error on
%   construction and a warning (the link is kept) when reading a file.

    methods (Test)
        function testWrongTargetTypeErrorsInStrictContext(testCase)
            softLink = testCase.createSoftLinkWithTargetType('types.core.Device');
            testCase.verifyError( ...
                @() types.util.validateSoftLink( ...
                    'electrode_group', softLink, 'types.core.ElectrodeGroup'), ...
                'NWB:ValidateSoftLink:InvalidNeurodataType')
        end

        function testWrongTargetTypeWarnsInReadContext(testCase)
            softLink = testCase.createSoftLinkWithTargetType('types.core.Device');

            previousContext = matnwb.common.validation.internal.context("read");
            cleanup = onCleanup( ...
                @() matnwb.common.validation.internal.context(previousContext));

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
