classdef CheckTypeTest < matlab.unittest.TestCase
% CheckTypeTest - Unit tests for types.util.checkType.
%   A value of the wrong neurodata type is an error on construction and a
%   warning (the value is kept) when reading a file. An unrecognized
%   expected type is an internal error and stays an error in both contexts.

    methods (Test)
        function testMatchingTypePasses(testCase)
            value = types.hdmf_common.VectorData( ...
                'description', 'a column', 'data', (1:3)');
            testCase.verifyWarningFree( ...
                @() types.util.checkType( ...
                    'col', 'types.hdmf_common.VectorData', value))
        end

        function testWrongTypeErrorsInStrictContext(testCase)
            value = types.hdmf_common.VectorData( ...
                'description', 'a column', 'data', (1:3)');
            testCase.verifyError( ...
                @() types.util.checkType( ...
                    'region', 'types.hdmf_common.DynamicTableRegion', value), ...
                'NWB:CheckType:InvalidNeurodataType')
        end

        function testWrongTypeWarnsInReadContext(testCase)
            value = types.hdmf_common.VectorData( ...
                'description', 'a column', 'data', (1:3)');

            previousContext = types.util.validationContext('read');
            cleanup = onCleanup( ...
                @() types.util.validationContext(previousContext));

            testCase.verifyWarning( ...
                @() types.util.checkType( ...
                    'region', 'types.hdmf_common.DynamicTableRegion', value), ...
                'NWB:CheckType:InvalidNeurodataType')
        end

        function testUnknownExpectedTypeAlwaysErrors(testCase)
            % An unrecognized expected type indicates an internal problem,
            % not a non-conforming file, so it stays an error on read.
            previousContext = types.util.validationContext('read');
            cleanup = onCleanup( ...
                @() types.util.validationContext(previousContext));

            testCase.verifyError( ...
                @() types.util.checkType('x', 'types.core.NotARealType', 5), ...
                'NWB:CheckType:UnknownNeurodataType')
        end
    end
end
