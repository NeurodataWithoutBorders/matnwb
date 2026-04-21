classdef IncludedTypedDatasetValidationTest < matlab.unittest.TestCase

    methods (Test)

        function testExpandFieldsInheritedByInclusionMarksMissingDtype(testCase)
            datasetSpec = containers.Map();
            datasetSpec('data_type_inc') = 'AnyData';

            node = containers.Map();
            node('datasets') = {datasetSpec};

            spec.internal.expandFieldsInheritedByInclusion(node)

            testCase.verifyFalse(isKey(datasetSpec, 'dtype'))
            testCase.verifyTrue(isKey(datasetSpec, 'skip_dtype_validation'))
            testCase.verifyTrue(datasetSpec('skip_dtype_validation'))
            testCase.verifyTrue(isKey(datasetSpec, 'shape'))
            testCase.verifyTrue(isnumeric(datasetSpec('shape')) && isnan(datasetSpec('shape')))
        end

        function testExpandFieldsInheritedByInclusionDoesNotMarkExplicitDtype(testCase)
            datasetSpec = containers.Map();
            datasetSpec('data_type_inc') = 'AnyData';
            datasetSpec('dtype') = 'text';

            node = containers.Map();
            node('datasets') = {datasetSpec};

            spec.internal.expandFieldsInheritedByInclusion(node)

            testCase.verifyFalse(isKey(datasetSpec, 'skip_dtype_validation'))
            testCase.verifyEqual(datasetSpec('dtype'), 'text')
        end

        function testDatasetReadsSkipDtypeValidationFlag(testCase)
            datasetSpec = containers.Map();
            datasetSpec('data_type_inc') = 'AnyData';
            datasetSpec('skip_dtype_validation') = true;

            datasetObj = file.Dataset(datasetSpec);

            testCase.verifyTrue(datasetObj.skipDtypeValidation)
            testCase.verifyEqual(datasetObj.dtype, 'any')
        end
    end
end
