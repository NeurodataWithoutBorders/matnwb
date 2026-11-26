classdef BaseLazyArrayTest < tests.unit.io.backend.base.AbstractBaseClassSmokeTest
% BaseLazyArrayTest - Smoke tests for base LazyArray class

    properties (Constant)
        ClassName = "LazyArray"
        FullClassName = "io.backend.base.LazyArray"
        ExpectedMethods = [...
            "LazyArray", ...
            "loadSelections", ...
            "load_h5_style", ...
            "load_mat_style", ...
            "refreshSizeInfo", ...
            "resolveDataType" ...
        ]
    end

    properties (TestParameter)
        % loadSelections has a default implementation, tested below.
        NotImplementedMethodName = cellstr( setdiff( ...
            tests.unit.io.backend.base.BaseLazyArrayTest.ExpectedMethods, ...
            [tests.unit.io.backend.base.BaseLazyArrayTest.ClassName, "loadSelections"]) ) % Exclude constructor
    end

    methods (Test)
        function verifyLoadSelectionsCallsLoadMatStyle(testCase)
            data = reshape(1:12, 3, 4);
            selections = {{':', 1:2}, {2, ':'}, {[1 3], 4}};
            lazyArray = tests.unit.io.backend.doubles.LazyArrayFake(data);

            actual = lazyArray.loadSelections(selections);

            testCase.verifyEqual(lazyArray.LoadMatStyleCount, numel(selections), ...
                'Expected one load_mat_style call per selection.');
            testCase.verifyEqual(lazyArray.Selections, selections, ...
                'Expected load_mat_style to be called with each selection, in order.');
            testCase.verifyEqual(actual, {data(:, 1:2), data(2, :), data([1 3], 4)});
        end
    end
end
