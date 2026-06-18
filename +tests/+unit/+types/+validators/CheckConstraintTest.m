classdef CheckConstraintTest < matlab.unittest.TestCase
% CheckConstraintTest - Unit tests for types.util.checkConstraint.
%   A value whose type is not among the allowed constrained types is an
%   error on construction and a warning (the value is kept) when reading a
%   file.

    methods (Test)
        function testValueMatchingNoConstrainedTypeErrorsInStrictContext(testCase)
            testCase.verifyError( ...
                @() types.util.checkConstraint('group', 'item', struct(), ...
                    {'types.hdmf_common.VectorData'}, 5), ...
                'NWB:CheckConstraint:InvalidType')
        end

        function testValueMatchingNoConstrainedTypeWarnsInReadContext(testCase)
            previousContext = types.util.validationContext('read');
            cleanup = onCleanup( ...
                @() types.util.validationContext(previousContext));

            value = testCase.verifyWarning( ...
                @() types.util.checkConstraint('group', 'item', struct(), ...
                    {'types.hdmf_common.VectorData'}, 5), ...
                'NWB:CheckConstraint:InvalidType');
            testCase.verifyEqual(value, 5)
        end
    end
end
