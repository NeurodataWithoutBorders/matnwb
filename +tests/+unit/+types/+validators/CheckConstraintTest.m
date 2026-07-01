classdef CheckConstraintTest < matlab.unittest.TestCase
% CheckConstraintTest - Unit tests for types.util.checkConstraint.

    methods (Test)
        function testValueMatchingNoConstrainedTypeErrorsInEditContext(testCase)
            testCase.verifyError( ...
                @() types.util.checkConstraint('group', 'item', struct(), ...
                    {'types.hdmf_common.VectorData'}, 5), ...
                'NWB:CheckConstraint:InvalidType')
        end

        function testValueMatchingNoConstrainedTypeWarnsInReadContext(testCase)
            [~, cleanup] = matnwb.common.validation.internal.context("read"); %#ok<ASGLU>

            value = testCase.verifyWarning( ...
                @() types.util.checkConstraint('group', 'item', struct(), ...
                    {'types.hdmf_common.VectorData'}, 5), ...
                'NWB:CheckConstraint:InvalidType');
            testCase.verifyEqual(value, 5)
        end

        function testReadContextProbesConstrainedTypesStrictly(testCase)
            [~, cleanup] = matnwb.common.validation.internal.context("read"); %#ok<ASGLU>

            value = testCase.verifyWarningFree( ...
                @() types.util.checkConstraint('group', 'item', struct(), ...
                    {'types.hdmf_common.VectorData', 'double'}, 5));

            testCase.verifyEqual(value, 5)
        end
    end
end
