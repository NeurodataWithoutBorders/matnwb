classdef DataTypesTest < tests.unit.abstract.SchemaTest
% DataTypesTest - Test case for the dtype specification key
%
%   This test case focuses on testing the following dtype validation
%   scenarios:
%
%   - Test basic dtype validation
%
%   - Test correct validation of the dtype spec under different dataset type 
%     reuse mechanisms (from nwb specification language docs):
%                       neurodata_type_inc  |  neurodata_type_def
%     - inheritance:            SET                 SET
%     - inclusion:              SET               NOT SET
%
%   - Test correct validation of compound types


    properties (Constant)
        SchemaFolder = "dataTypesSchema"
        SchemaNamespaceFileName = "dt.namespace.yaml"
    end

    properties (TestParameter)
        % An incomplete selection of data types to test dtype validation
        value = {'1', uint32(1), int8(1), int32(1), single(1.0), 1.0}
    end

    methods (Test)
        function testValidationOfAnyData(testCase, value)
        % testValidationOfAnyData - Any dtype should be allowed

            anyData = types.dt.AnyData('data', value);
            testCase.verifyEqual(anyData.data, value)
        end

        % The following tests tests that dtype validation / correction is 
        % handled correctly under the inheritance mechanism.

        function testValidationOfTextData(testCase, value)
            % Only text allowed, numbers will cause conversion error
            allowedValue = '1';
            if isequal(value, allowedValue)
                textData = types.dt.TextData('data', value);
                testCase.verifyEqual(textData.data, value)
            else
                testCase.verifyError(...
                    @() types.dt.TextData('data', value), ...
                    'NWB:CheckDataType:InvalidConversion', ...
                    'Reused (by inheritance) data should be text')
            end
        end

        function testValidationOfIntegerData(testCase, value)
            % For integer data, value will be "corrected" to an integer type
            % that is has a minimum bitsize of 32 (int32), but using a higher 
            % bitsize if data conversion could result in data loss.
            if ismember( class(value), {'char', 'uint32', 'double'} )
                % Conversion could cause data loss, int64 is used
                expectedValue = int64(1);
            else % int8, int32, single
                expectedValue = int32(1);
            end

            intData = types.dt.IntegerData('data', value);
            testCase.verifyEqual(intData.data, expectedValue)
        end

        function testValidationOFloatData(testCase, value)
            % For float data, value will be "corrected" to an integer type
            % that is has a minimum bitsize of 32 (float32, single in MATLAB),
            % but using a higher bitsize if data conversion could result in data 
            % loss.
            if ismember( class(value), {'char', 'uint32', 'int32', 'double'} )
                % Conversion could cause data loss, double is used
                expectedValue = double(1);
            else % int8,  single
                expectedValue = single(1);
            end

            floatData = types.dt.FloatData('data', value);
            testCase.verifyEqual(floatData.data, expectedValue)
        end

        % The following tests test that dtype validation is handled
        % correctly under the inclusion mechanism

        function testValidationOfTextDataByInclusion(testCase, value)
                
            ALLOWED_VALUE = '1';

            % Basic dataset can hold any dtype.
            anyData = types.dt.AnyData('data', value);

            % The "included_data_must_be_text" field of the InclusionContainer 
            % accepts the AnyData type, but the dtype is restricted to text.
            % Any value which is not char will fail to validate
            if isequal(value, ALLOWED_VALUE)
                incContainer = types.dt.InclusionContainer('included_data_must_be_text', anyData);
                testCase.verifyClass(incContainer.included_data_must_be_text, 'types.dt.AnyData')
                testCase.verifyClass(incContainer.included_data_must_be_text.data, 'char')
            else
                testCase.verifyError(...
                    @() types.dt.InclusionContainer('included_data_must_be_text', anyData), ...
                    'NWB:CheckDataType:InvalidConversion', ...
                    'Reused (by inclusion) data should be text')
            end
        end

        function testValidationOfIntegerDataByInclusion(testCase, value)
            % Verify that conversion logic works when a dataset type is
            % reused by inclusion when dtype is set to "int"

            if ismember( class(value), {'char', 'uint32', 'double'} )
                % Conversion could cause data loss, int64 is used
                expectedValue = int64(1);
            else % int8, int32, single
                expectedValue = int32(1);
            end

            anyData = types.dt.AnyData('data', value);
            incContainer = types.dt.InclusionContainer('included_data_must_be_integer', anyData);
            testCase.verifyEqual(incContainer.included_data_must_be_integer.data, expectedValue)
        end

        function testValidationOfFloatDataByInclusion(testCase, value)
            % Verify that conversion logic works when a dataset type is
            % reused by inclusion when dtype is set to "float"

            if ismember( class(value), {'char', 'uint32', 'int32', 'double'} )
                % Conversion could cause data loss, double is used
                expectedValue = double(1);
            else % int8,  single
                expectedValue = single(1);
            end

            anyData = types.dt.AnyData('data', value);
            incContainer = types.dt.InclusionContainer('included_data_must_be_float', anyData);
            testCase.verifyEqual(incContainer.included_data_must_be_float.data, expectedValue)
        end

        function testValidationOfCompoundDataByInclusion(testCase)
            validCompoundStruct = struct(...
                'integer', 1, ...
                'float', 1, ...
                'text', '1');
            compoundData = types.dt.AnyData('data', validCompoundStruct);

            incContainer = types.dt.InclusionContainer('included_data_must_be_compound', compoundData);
            includedCompound = incContainer.included_data_must_be_compound;

            testCase.verifyEqual(includedCompound.data.integer, int64(1))
            testCase.verifyEqual(includedCompound.data.float, double(1))
            testCase.verifyEqual(includedCompound.data.text, '1')

            invalidCompoundStruct = struct(...
                'a', 1, ...
                'b', 1, ...
                'c', '1');
            invalidCompoundData = types.dt.AnyData('data', invalidCompoundStruct);
            incContainer = types.dt.InclusionContainer('included_data_must_be_compound', compoundData);

            invalidCompoundStruct = struct(...
                'integer', 1, ...
                'float', 1, ...
                'text', 1);
            invalidCompoundData = types.dt.AnyData('data', invalidCompoundStruct);
            incContainer = types.dt.InclusionContainer('included_data_must_be_compound', compoundData);

        end

        % The following tests test validation of compound data types
        function testCompoundDataTypeValidation(testCase)
            
            % Test compound data type with struct
            compoundStruct = struct(...
                'integer', 1, ...
                'float', 1, ...
                'text', '1', ...
                'reference', types.untyped.ObjectView(types.dt.AnyData('data', 1))); % NB: Can not be set directly. Should fix
            
            compoundData = types.dt.CompoundData('data', compoundStruct);
            testCase.verifyClass(compoundData.data.integer, 'int64');
            testCase.verifyClass(compoundData.data.float, 'double');
            testCase.verifyClass(compoundData.data.text, 'char');
            testCase.verifyClass(compoundData.data.reference, 'types.untyped.ObjectView');
            testCase.verifyClass(compoundData.data.reference.target, 'types.dt.AnyData');
        end
        
        function testCompoundDataTypeWithTable(testCase)
            % Test compound data type with table % Todo: Not a schema test,
            % move to another unittest
            compoundTable = table(...
                [1; 2; 3], ...
                [1; 2; 3], ...
                {'1'; '2'; '3'}, ...
                [types.untyped.ObjectView(types.dt.AnyData('data', 1)); ...
                 types.untyped.ObjectView(types.dt.AnyData('data', 2)); ...
                 types.untyped.ObjectView(types.dt.AnyData('data', 3))], ...
                'VariableNames', {'integer', 'float', 'text', 'reference'});
            
            compoundData = types.dt.CompoundData('data', compoundTable);
            testCase.verifyClass(compoundData.data, 'table');
            testCase.verifyEqual(height(compoundData.data), 3);
        end
        
        function testCompoundDataTypeMissingField(testCase)
            % Test compound data type validation with missing field
            incompleteStruct = struct(...
                'integer', 1, ...
                'float', 1, ...
                'text', '1');
            % Missing 'reference' fields
            
            testCase.verifyError(...
                @() types.dt.CompoundData('data', incompleteStruct), ...
                'NWB:CheckDType:InvalidValue');
        end
        
        function testCompoundDataTypeWrongFieldOrder(testCase)
            % Test compound data type validation with wrong field order
            wrongOrderStruct = struct(...
                'integer', 1, ...
                'text', '1', ...
                'float', 1.0, ...
                'reference', types.untyped.ObjectView(types.dt.AnyData('data', 1)));
            
            testCase.verifyError(...
                @() types.dt.CompoundData('data', wrongOrderStruct), ...
                'NWB:CheckDType:InvalidValue');
        end
        
        function testCompoundDataTypeWrongFieldType(testCase)
            % Test compound data type validation with wrong field type
            wrongTypeStruct = struct(...
                'integer', 1, ... 
                'float', 1, ...
                'text', 1, ... % Should be char
                'reference', types.untyped.ObjectView(types.dt.AnyData('data', 1)));
            
            testCase.verifyError(...
                @() types.dt.CompoundData('data', wrongTypeStruct), ...
                'NWB:CheckDataType:InvalidConversion');
        end
        
        % Test round trip

        function testRoundtripValidation(testCase)
            % Test full roundtrip: create, export, read, validate

            % Create an NWB file object
            nwb = tests.factory.NWBFile();

            % Create a container that holds data types reused by inclusion
            anyData = types.dt.AnyData('data', uint8(1));
            textData = types.dt.AnyData('data', '1');
            integerData = types.dt.AnyData('data', int32(1));
            floatData = types.dt.AnyData('data', single(1));
            compoundData = types.dt.AnyData('data', struct('integer', 1, 'float', 1, 'text', '1'));

            incContainer = types.dt.InclusionContainer(...
                'any_data', anyData, ...
                'included_data_must_be_text', textData, ...
                'included_data_must_be_integer', integerData, ...
                'included_data_must_be_float', floatData, ...
                'included_data_must_be_compound', compoundData);
            
            nwb.acquisition.set('inc_container', incContainer);
            
            % Create a container that holds data types reused by inheritance
            anyData = types.dt.AnyData('data', uint8(1));
            textData = types.dt.TextData('data', '1');
            integerData = types.dt.IntegerData('data', int32(1));
            floatData = types.dt.FloatData('data', single(1));
            compoundData = types.dt.CompoundData('data', struct('integer', 1, 'float', 1, 'text', '1', 'reference', types.untyped.ObjectView(anyData)));

            inheritanceContainer = types.dt.InheritanceContainer(...
                'any_data', anyData, ...
                'text_data', textData, ...
                'integer_data', integerData, ...
                'float_data', floatData, ...
                'compound_data', compoundData);
            
            nwb.acquisition.set('inheritance_container', inheritanceContainer);

            % Export
            filename = 'dataTypesTest.nwb';
            nwbExport(nwb, filename);
            
            % Read back and verify
            nwbIn = nwbRead(filename, 'ignorecache');
            incContainerIn = nwbIn.acquisition.get('inc_container');
            inheritanceContainerIn = nwbIn.acquisition.get('inheritance_container');

            testCase.verifyEqual(incContainerIn.any_data.data.load(), uint8(1));
            testCase.verifyEqual(incContainerIn.included_data_must_be_text.data.load(), '1');
            testCase.verifyEqual(incContainerIn.included_data_must_be_integer.data.load(), int32(1));
            testCase.verifyEqual(incContainerIn.included_data_must_be_float.data.load(), single(1));
            testCase.verifyClass(incContainerIn.included_data_must_be_compound.load(), 'struct');

            testCase.verifyEqual(inheritanceContainerIn.any_data.data.load(), uint8(1));
            testCase.verifyEqual(inheritanceContainerIn.text_data.data.load(), '1');
            testCase.verifyEqual(inheritanceContainerIn.integer_data.data.load(), int32(1));
            testCase.verifyEqual(inheritanceContainerIn.float_data.data.load(), single(1));
            testCase.verifyClass(inheritanceContainerIn.compound_data.data.load(), 'struct');
        end
        
        % Misc data value checks

        function testDataTypeValidationWithEmptyValues(testCase)
            % Test data type validation with empty values
            anyData = types.dt.AnyData();
            testCase.verifyEmpty(anyData.data);
            
            % Setting data after construction should still validate
            anyData.data = single(1.0);
            testCase.verifyClass(anyData.data, 'single');
        end
        
        function testDataTypeValidationWithNullValues(testCase)
            % Test data type validation with null/NaN values
            nanData = types.dt.AnyData('data', single(NaN));
            testCase.verifyTrue(isnan(nanData.data));
            testCase.verifyClass(nanData.data, 'single');
        end
    end
end
 