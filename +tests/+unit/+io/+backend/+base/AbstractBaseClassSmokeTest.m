classdef AbstractBaseClassSmokeTest < matlab.unittest.TestCase
% AbstractBaseClassSmokeTest - Smoke tests for base classes

    properties (Abstract, Constant)
        ClassName (1,1) string
        FullClassName (1,1) string
        ExpectedMethods (1,:) string
    end

    properties (Abstract, TestParameter)
        NotImplementedMethodName (1,:) cell
    end

    methods (Test)
        function verifyCreateInstanceWithNoInputArguments(testCase)
            baseInstance = feval(testCase.FullClassName);
            testCase.verifyClass(baseInstance, testCase.FullClassName)
        end

        function verifyHasExpectedMethods(testCase)
            actualMethods = setdiff( ...
                string(methods(testCase.FullClassName)), ...
                string(methods('handle')));
            testCase.verifyEqual(sort(actualMethods), sort(testCase.ExpectedMethods)')
        end

        function verifyMethodsNotImplemented(testCase, NotImplementedMethodName)
            baseInstance = feval(testCase.FullClassName);
            methodFunction = @() baseInstance.(NotImplementedMethodName);

            testCase.verifyError(...
                methodFunction, ...
                sprintf("NWB:Backend:%s:NotImplemented", testCase.ClassName))
        end
    end
end
