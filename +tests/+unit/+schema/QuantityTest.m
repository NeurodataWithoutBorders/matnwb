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

        function testInvalidTextQuantitySpecification(testCase)
            % Simulate a dataset specification with an invalid quantity value
            specMap = containers.Map('quantity', 'none');
            testCase.verifyError(...
                @() file.Dataset(specMap), ...
                'NWB:Schema:UnsupportedQuantity')
        end

        function testInvalidNumericQuantitySpecification(testCase)
            % Simulate a dataset specification with an invalid numeric quantity value
            specMap = containers.Map('quantity', 1.5);

            testCase.verifyError(...
                @() file.Dataset(specMap), ...
                'NWB:Schema:UnsupportedQuantity')
        end
               
        function testInvalidArrayQuantitySpecification(testCase)
            % Simulate a dataset specification with an invalid numeric quantity value
            specMap = containers.Map('quantity', {{'*', '+'}});

            testCase.verifyError(...
                @() file.Dataset(specMap), ...
                'NWB:Schema:UnsupportedQuantity')
        end
    end
end
