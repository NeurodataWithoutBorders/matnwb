classdef BaseLazyArrayTest < matlab.unittest.TestCase
% BaseLazyArrayTest - Smoke tests for base LazyArray class

    properties
        ClassName = "LazyArray"
        FullClassName (1,1) string = "io.backend.base.LazyArray"
    end

    properties (Constant)
        ExpectedMethods (1,:) string = [...
            "LazyArray", ...
            "load_h5_style", ...
            "load_mat_style", ...
            "refreshSizeInfo", ...
            "resolveDataType" ...
        ]
    end

    properties (TestParameter)
        MethodName = setdiff(cellstr(tests.unit.io.backend.BaseLazyArrayTest.ExpectedMethods), 'LazyArray')
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
            testCase.verifyEqual(actualMethods, testCase.ExpectedMethods')
        end

        function verifyMethodsNotImplemented(testCase, MethodName)
            baseInstance = feval(testCase.FullClassName);
            methodFunction = @() baseInstance.(MethodName);

            expectedErrorId = sprintf("NWB:Backend:%s:NotImplemented", testCase.ClassName);
            testCase.verifyError(methodFunction, expectedErrorId)
        end
    end
end
