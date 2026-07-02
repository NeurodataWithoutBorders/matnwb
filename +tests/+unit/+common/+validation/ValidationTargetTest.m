classdef ValidationTargetTest < matlab.unittest.TestCase
% ValidationTargetTest - Unit tests for the schema-validation target state.

    methods (TestMethodTeardown)
        function resetValidationTarget(~)
            matnwb.common.validation.internal.validationTarget([]);
        end
    end

    methods (Test)
        function testExplicitEmptyResetsState(testCase)
            % Passing an explicit empty target must clear the stored state,
            % not be treated as a no-op getter.
            target.TypeName = 'types.core.TimeSeries';
            target.Path = '/acquisition/bad_ts';
            matnwb.common.validation.internal.validationTarget(target);
            testCase.verifyNotEmpty( ...
                matnwb.common.validation.internal.validationTarget())

            matnwb.common.validation.internal.validationTarget([]);
            testCase.verifyEmpty( ...
                matnwb.common.validation.internal.validationTarget())
        end

        function testCleanupRestoresEmptyTarget(testCase)
            % When a scope sets a target from the initial empty state, its
            % cleanup handle must restore the state back to empty on exit.
            target.TypeName = 'types.core.TimeSeries';
            target.Path = '/acquisition/bad_ts';

            % The cleanup handle is scoped to the helper, so it fires when the
            % helper returns, mimicking how a read scope exits.
            testCase.setScopedTarget(target)

            testCase.verifyEmpty( ...
                matnwb.common.validation.internal.validationTarget())
        end
    end

    methods (Access = private)
        function setScopedTarget(testCase, target)
            [~, cleanup] = matnwb.common.validation.internal ...
                .validationTarget(target); %#ok<NASGU>
            testCase.verifyEqual( ...
                matnwb.common.validation.internal.validationTarget().TypeName, ...
                target.TypeName)
        end
    end
end
