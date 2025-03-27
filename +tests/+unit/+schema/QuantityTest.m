classdef QuantityTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "quantitySchema"
        SchemaNamespaceFileName = "quantity.namespace.yaml"
    end

    methods (Test)
        function testValidQuantitySpecifications(testCase)
            quantContainer = types.quantity.QuantityContainer();

            expectedRequiredProperties = [ ...
                "data_required_array", ...
                "data_required_array_long_form", ...
                "data_required_array_short_form", ...
                "data_required_scalar" ...
            ];
            expectedOptionalProperties = [ ...
                "data_optional_array_long_form", ...
                "data_optional_array_short_form", ...
                "data_optional_scalar_long_form", ...
                "data_optional_scalar_short_form"
            ];

            actualRequiredProperties = string(quantContainer.getRequiredProperties());
            testCase.verifyEqual(actualRequiredProperties, expectedRequiredProperties)

            allProperties = properties(quantContainer)';
            actualOptionalProperties = string(setdiff(allProperties, actualRequiredProperties));
            testCase.verifyEqual(actualOptionalProperties, expectedOptionalProperties)
        end
    end
end
