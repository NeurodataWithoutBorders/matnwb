classdef DataTypesTest < tests.unit.abstract.SchemaTest

    properties (Constant)
        SchemaFolder = "dataTypesSchema"
        SchemaNamespaceFileName = "dt.namespace.yaml"
    end

    methods (TestClassSetup)
        function testSetup(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:FillValidators:ValidationNotImplemented'))
        end
    end

    methods (Test)
        function testExtendedDataTypeValidation(testCase)
            % Test direct data type specification
            textData = types.dt.ExtendedTextDataset('data', 'hello world');
            testCase.verifyClass(textData.data, 'char');
            testCase.verifyEqual(textData.description, 'no description'); % default value
            
            % Test with custom description
            textData.description = 'the very first script';
            testCase.verifyEqual(textData.description, 'the very first script');
        end
        
        function testExtendedDataTypeValidationFailure(testCase)
            % Test that wrong data type fails validation
            testCase.verifyError(...
                @() types.dt.ExtendedTextDataset('data', 1), ...
                'NWB:CheckDataType:InvalidConversion');
        end
        
        function testInheritedDataTypeOverride(testCase)
            % Test that inherited type correctly overrides parent dtype
            integerData = types.dt.ExtendedIntegerDataset('data', int32([1, 2, 3]));
            testCase.verifyClass(integerData.data, 'int32');
            
            % Should still inherit the description attribute from parent
            testCase.verifyEqual(integerData.description, 'no description');
        end
        
        function testInheritedDataTypeValidationCorrection(testCase)
            % Test that inherited type rejects parent's original dtype
            integerData = types.dt.ExtendedIntegerDataset('data', single([1.0, 2.0, 3.0]));
            testCase.assertClass(integerData.data, 'int32')
        end
        
        function testOverriddenDataTypeViaReusedDatasetWithCorrectDataType(testCase)
            % Test data type override via neurodata_type_inc
            basicDataset = types.dt.BasicDataset('data', 'hello world');
            dtContainer = types.dt.DataTypeContainer('reused_data', basicDataset);
            testCase.verifyClass(dtContainer.reused_data, 'types.dt.BasicDataset')
        end

        function testOverriddenDataTypeViaIncludeWithWrongDataType(testCase)
            % Test data type override via neurodata_type_inc
            basicDataset = types.dt.BasicDataset('data', 1);
            testCase.verifyError(...
                @() types.dt.DataTypeContainer('reused_data', basicDataset), ...
                'NWB:CheckDataType:InvalidConversion', ...
                'Overridden (reused) data should be text')
        end
        
        function testWrongTypeForInheritedDataset(testCase)
            basicDataset = types.dt.BasicDataset('data', 1);
            testCase.verifyError(...
                @() types.dt.DataTypeContainer('extended_text_data', basicDataset), ...
                'NWB:CheckType:InvalidNeurodataType', ...
                'Datatype should be ExtendedTextDataset')
        end
        
        function testCompoundDataTypeValidation(testCase)
            % Test compound data type with struct
            compoundStruct = struct(...
                'x', 2, ...
                'y', 5, ...
                'label', "test_point", ...  % NB: Can not be set as character vector, validation fails.
                'reference', types.untyped.ObjectView(types.dt.BasicDataset('data', 1))); % NB: Can not be set directly. Should fix
            
            compoundData = types.dt.CompoundDataset('data', compoundStruct);
            testCase.verifyClass(compoundData.data.x, 'int64');
            testCase.verifyClass(compoundData.data.label, 'string');
            testCase.verifyClass(compoundData.data.reference, 'types.untyped.ObjectView');
            testCase.verifyClass(compoundData.data.reference.target, 'types.dt.BasicDataset');
        end
        
        function testCompoundDataTypeWithTable(testCase)
            % Test compound data type with table
            compoundTable = table(...
                [1; 2; 3], ...
                [4; 5; 6], ...
                {'A'; 'B'; 'C'}, ...
                [types.untyped.ObjectView(types.dt.BasicDataset('data', 1)); ...
                 types.untyped.ObjectView(types.dt.BasicDataset('data', 2)); ...
                 types.untyped.ObjectView(types.dt.BasicDataset('data', 3))], ...
                'VariableNames', {'x', 'y', 'label', 'reference'});
            
            compoundData = types.dt.CompoundDataset('data', compoundTable);
            testCase.verifyClass(compoundData.data, 'table');
            testCase.verifyEqual(height(compoundData.data), 3);
        end
        
        function testCompoundDataTypeMissingField(testCase)
            % Test compound data type validation with missing field
            incompleteStruct = struct(...
                'x', 1, ...
                'y', 2, ...
                'label', "test");
            % Missing 'reference' fields
            
            testCase.verifyError(...
                @() types.dt.CompoundDataset('data', incompleteStruct), ...
                'NWB:CheckDType:InvalidValue');
        end
        
        function testCompoundDataTypeWrongFieldOrder(testCase)
            % Test compound data type validation with wrong field order
            wrongOrderStruct = struct(...
                'x', 1, ...
                'label', "test_point", ...
                'y', 2.7, ...
                'reference', types.untyped.ObjectView(types.dt.BasicDataset('data', 1)));
            
            testCase.verifyError(...
                @() types.dt.CompoundDataset('data', wrongOrderStruct), ...
                'NWB:CheckDType:InvalidValue');
        end
        
        function testCompoundDataTypeWrongFieldType(testCase)
            % Test compound data type validation with wrong field type
            wrongTypeStruct = struct(...
                'x', "not_an_integer", ... % Should be int32
                'y', 2, ...
                'label', "test_point", ...
                'reference', types.untyped.ObjectView(types.dt.BasicDataset('data', 1)));
            
            testCase.verifyError(...
                @() types.dt.CompoundDataset('data', wrongTypeStruct), ...
                'NWB:CheckDataType:InvalidConversion');
        end
        
        function testDataTypeContainer(testCase)
            % Test the container that holds all data types
            basicData = types.dt.BasicDataset('data', single([1.0, 2.0, 3.0]));
            extendedTextData = types.dt.ExtendedTextDataset('data', 'hello world');
            reusedData = types.dt.BasicDataset('data', 'hello world');

            compoundStruct = struct(...
                'x', 2, ...
                'y', 5, ...
                'label', "test_point", ...  % NB: Can not be set as character vector, validation fails.
                'reference', types.untyped.ObjectView(types.dt.BasicDataset('data', 1))); % NB: Can not be set directly. Should fix
            compoundData = types.dt.CompoundDataset('data', compoundStruct);
            
            container = types.dt.DataTypeContainer(...
                'basic_data', basicData, ...
                'extended_text_data', extendedTextData, ...
                'reused_data', reusedData, ...
                'compound_data', compoundData);
            
            testCase.verifyClass(container, 'types.dt.DataTypeContainer');
            testCase.verifyClass(container.basic_data, 'types.dt.BasicDataset');
            testCase.verifyClass(container.extended_text_data, 'types.dt.ExtendedTextDataset');
            testCase.verifyClass(container.reused_data, 'types.dt.BasicDataset');
            testCase.verifyClass(container.compound_data, 'types.dt.CompoundDataset');
        end
        
        function testRoundtripValidation(testCase)
            % Test full roundtrip: create, export, read, validate

            % Test the container that holds all data types
            basicData = types.dt.BasicDataset('data', single([1.0, 2.0, 3.0]));
            extendedTextData = types.dt.ExtendedTextDataset('data', 'hello world');
            reusedData = types.dt.BasicDataset('data', 'hello world');

            compoundStruct = struct(...
                'x', 2, ...
                'y', 5, ...
                'label', 'test_point', ...  % NB: Can not be set as character vector, validation fails.
                'reference', types.untyped.ObjectView(basicData)); % NB: Can not be set directly. Should fix
            compoundData = types.dt.CompoundDataset('data', compoundStruct);
            
            container = types.dt.DataTypeContainer(...
                'basic_data', basicData, ...
                'extended_text_data', extendedTextData, ...
                'reused_data', reusedData, ...
                'compound_data', compoundData);
            
            nwb = NwbFile(...
                'identifier', 'DT_TEST', ...
                'session_description', 'Data types test', ...
                'session_start_time', '2023-01-01T12:00:00.000000-08:00', ...
                'timestamps_reference_time', '2023-01-01T12:00:00.000000-08:00');
            
            nwb.acquisition.set('data_container', container);
            
            filename = 'dataTypesTest.nwb';
            nwbExport(nwb, filename);
            
            % Read back and verify
            readNwbFile = nwbRead(filename, 'ignorecache');
            readContainer = readNwbFile.acquisition.get('data_container');
            
            testCase.verifyClass(readContainer, 'types.dt.DataTypeContainer');
            testCase.verifyClass(readContainer.basic_data.data(1), 'single');
            extendedTextDataRead = readContainer.extended_text_data.data.load(); 
            testCase.verifyClass(extendedTextDataRead, 'char');
            compoundStructRead = readContainer.compound_data.data.load();
            testCase.verifyClass(compoundStructRead, 'struct');
            testCase.verifyClass(compoundStructRead.x, 'int64')
            testCase.verifyTrue(iscellstr(compoundStructRead.label))
        end
        
        function testDataTypeValidationWithEmptyValues(testCase)
            % Test data type validation with empty values
            basicData = types.dt.BasicDataset();
            testCase.verifyEmpty(basicData.data);
            
            % Setting data after construction should still validate
            basicData.data = single([1.0, 2.0, 3.0]);
            testCase.verifyClass(basicData.data, 'single');
        end
        
        function testDataTypeValidationWithNullValues(testCase)
            % Test data type validation with null/NaN values
            basicData = types.dt.BasicDataset('data', single(NaN));
            testCase.verifyTrue(isnan(basicData.data));
            testCase.verifyClass(basicData.data, 'single');
        end

        function testSubgroupUntypedDatasetWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('untyped_text_data', 'hello world');
            container = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(container.subgroup.get('untyped_text_data'), 'char')
        end

        function testSubgroupUntypedDatasetWithWrongType(testCase)
            % Add dataset of wrong dtype to basic_data (should be text)
            subGroup = types.untyped.Set();
            subGroup.set('untyped_text_data', 2);
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end
                
        function testSubgroupTypedDatasetWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('basic_data', types.dt.BasicDataset('data', 1));
            container = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(container.subgroup.get('basic_data'), 'types.dt.BasicDataset')
        end

        function testSubgroupTypedDatasetWithWrongType(testCase)
            % Add dataset of wrong type to basic_data (should be types.dt.BasicDataset)
            subGroup = types.untyped.Set();
            subGroup.set('basic_data', types.hdmf_common.VectorData('data', 1)); 
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end

        function testSubgroupConstrainedDatasetWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('constrained_a', types.dt.ExtendedTextDataset('data', 'hello'));
            subGroup.set('constrained_b', types.dt.ExtendedTextDataset('data', 'world'));
            container = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(container.subgroup.get('constrained_a'), 'types.dt.ExtendedTextDataset')
            testCase.verifyClass(container.subgroup.get('constrained_b'), 'types.dt.ExtendedTextDataset')
        end

        function testSubgroupConstrainedDatasetWithWrongType(testCase)
            % Add dataset of wrong type to constrained dataset (should be types.dt.ExtendedTextDataset)
            subGroup = types.untyped.Set();
            subGroup.set('constrained', types.dt.BasicDataset('data', 1)); 
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end

        function testSubgroupAttributeWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('description', 'a description');
            container = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(container.subgroup.get('description'), 'char')
        end

        function testSubgroupAttributeWithWrongType(testCase)
            % Set attribute with wrong type
            subGroup = types.untyped.Set();
            subGroup.set('description', 1); 
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end

        function testSubgroupLinkWithCorrectType(testCase)
            basicDataset = types.dt.BasicDataset('data', single([1.0, 2.0, 3.0]));
            subGroup = types.untyped.Set();
            subGroup.set('subgroup_link', types.untyped.SoftLink(basicDataset));
            nestedContainer = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            
            testCase.verifyClass(nestedContainer.subgroup.get('subgroup_link'), 'types.untyped.SoftLink')
        end

        function testSubgroupLinkWithWrongType(testCase)
            invalidLinkedDataset = types.hdmf_common.VectorData('data', 1);
            subGroup = types.untyped.Set();
            subGroup.set('subgroup_link', types.untyped.SoftLink(invalidLinkedDataset));
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end

        function testNestedSubgroupWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('nested_subgroup', types.hdmf_common.DynamicTable());
            nestedContainer = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(nestedContainer.subgroup.get('nested_subgroup'), 'types.hdmf_common.DynamicTable')
        end

        function testNestedSubgroupWithWrongType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('nested_subgroup', types.core.TimeSeries);
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end

        function testNestedConstrainedSubgroupWithCorrectType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('nested_constrained_subgroup', types.core.TimeSeries);
            nestedContainer = types.dt.NestedDataTypeContainer('subgroup', subGroup);
            testCase.verifyClass(nestedContainer.subgroup.get('nested_constrained_subgroup'), 'types.core.TimeSeries')
        end

        function testNestedConstrainedSubgroupWithWrongType(testCase)
            subGroup = types.untyped.Set();
            subGroup.set('nested_constrained_subgroup', types.hdmf_common.DynamicTable()); 
            testCase.verifyWarning(...
                @() types.dt.NestedDataTypeContainer('subgroup', subGroup), ...
                'NWB:Set:FailedValidation')
        end
    end
end
