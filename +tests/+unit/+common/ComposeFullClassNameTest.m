classdef ComposeFullClassNameTest < matlab.unittest.TestCase
% ComposeFullClassNameTest - Unit tests for matnwb.common.composeFullClassName.

    methods (Test)
        function testScalarInputs(testCase)
            fullClassName = matnwb.common.composeFullClassName('core', 'TimeSeries');
            testCase.verifyEqual(fullClassName, "types.core.TimeSeries")
        end

        function testHyphenInNamespaceIsReplaced(testCase)
            fullClassName = matnwb.common.composeFullClassName("hdmf-common", "VectorData");
            testCase.verifyEqual(fullClassName, "types.hdmf_common.VectorData")
        end

        function testInvalidNamesAreMadeValid(testCase)
            fullClassName = matnwb.common.composeFullClassName("ndx.test", "1Type");
            testCase.verifyEqual(fullClassName, "types.ndx_test.dyn_1Type")
        end

        function testVectorInputsReturnRow(testCase)
            fullClassName = matnwb.common.composeFullClassName( ...
                ["core"; "hdmf-common"], ["TimeSeries"; "VectorData"]);
            testCase.verifyEqual(fullClassName, ...
                ["types.core.TimeSeries", "types.hdmf_common.VectorData"])
        end

        function testEmptyInputsReturnEmpty(testCase)
            fullClassName = matnwb.common.composeFullClassName(strings(0, 1), strings(0, 1));
            testCase.verifyEmpty(fullClassName)
            testCase.verifyClass(fullClassName, 'string')
        end
    end
end
