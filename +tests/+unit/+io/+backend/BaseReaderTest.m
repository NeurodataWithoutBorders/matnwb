classdef BaseReaderTest < matlab.unittest.TestCase

    properties (Constant)
        ExpectedMethods (1,:) string = [...
            "Reader", ...
            "getEmbeddedSpecLocation", ...
            "getSchemaVersion", ...
            "readAttributeValue", ...
            "readDatasetValue", ...
            "readNodeInfo", ...
            "readRootInfo" ...
        ]
    end

    properties (TestParameter)
        MethodName = setdiff(cellstr(tests.unit.io.backend.BaseReaderTest.ExpectedMethods), 'Reader')
    end

    methods (Test)
        function verifyCreateInstanceWithNoInputArguments(testCase)
            baseReader = io.backend.base.Reader();
            testCase.verifyClass(baseReader, 'io.backend.base.Reader')
        end

        function verifyHasExpectedMethods(testCase)
            actualMethods = setdiff( ...
                string(methods('io.backend.base.Reader')), ...
                string(methods('handle')));
            testCase.verifyEqual(actualMethods, testCase.ExpectedMethods')
        end

        function verifyMethodsNotImplemented(testCase, MethodName)
            baseReader = io.backend.base.Reader();
            methodFunction = @() baseReader.(MethodName);

            testCase.verifyError(...
                methodFunction, ...
                'NWB:Backend:Reader:NotImplemented')
        end
    end
end
