classdef CheckDtypeTest < matlab.unittest.TestCase
% CheckDtypeTest - Unit test for functions in +types namespace.

    methods (Test)

        function testCompoundTypes(testCase)
            typeDescriptor = struct(...
                'a', 'uint8', ...
                'b', 'char');

            [testValueStruct, testValueTable, testValueMap] = ...
                testCase.getCompoundValues(...
                    'a', 1, ...
                    'b', 'hello world');
            
            val = types.util.checkDtype('struct', typeDescriptor, testValueStruct);
            testCase.verifyClass(val, 'struct');

            val = types.util.checkDtype('table', typeDescriptor, testValueTable);
            testCase.verifyClass(val, 'table');

            val = types.util.checkDtype('map', typeDescriptor, testValueMap);
            testCase.verifyClass(val, 'containers.Map');
        end

        function testCompoundTypeWithMissingFields(testCase)
            typeDescriptor = struct(...
                'a', 'uint8', ...
                'b', 'char');

            [testValueStruct, testValueTable, testValueMap] = ...
                testCase.getCompoundValues(...
                    'a', 1);

            testCase.verifyError(...
                @() types.util.checkDtype('struct', typeDescriptor, testValueStruct), ...
                'NWB:CheckDType:InvalidValue')
            testCase.verifyError(...
                @() types.util.checkDtype('map', typeDescriptor, testValueMap), ...
                'NWB:CheckDType:InvalidValue')
            testCase.verifyError(...
                @() types.util.checkDtype('table', typeDescriptor, testValueTable), ...
                'NWB:CheckDType:InvalidValue')
        end

        function testCompoundTypeWithTooManyFields(testCase)
            typeDescriptor = struct(...
                'a', 'uint8', ...
                'b', 'char');

            [testValueStruct, testValueTable, testValueMap] = ...
                testCase.getCompoundValues(...
                    'a', 1, ...
                    'b', 2, ...
                    'c', 3);

            testCase.verifyError(...
                @() types.util.checkDtype('struct', typeDescriptor, testValueStruct), ...
                'NWB:CheckDType:InvalidValue')
            testCase.verifyError(...
                @() types.util.checkDtype('map', typeDescriptor, testValueMap), ...
                'NWB:CheckDType:InvalidValue')
            testCase.verifyError(...
                @() types.util.checkDtype('table', typeDescriptor, testValueTable), ...
                'NWB:CheckDType:InvalidValue')
        end
        
        function checkEmptyValues(testCase)
            % Test various combinations of typeDescriptors and values. 
            % The typeDescriptor specifies the minimum byte-size type to use for
            % a value, but if the value is using a larger byte-size value,
            % that type should be returned.

            value = types.util.checkDtype('shouldBeSingle', 'single', single([]));
            testCase.verifyClass(value, 'single')

            value = types.util.checkDtype('shouldBeDouble', 'single', double([]));
            testCase.verifyClass(value, 'double')

            % Minimum byte-size type is double, single should be converted to double
            value = types.util.checkDtype('shouldBeDouble', 'double', single([]));
            testCase.verifyClass(value, 'double')
            
            value = types.util.checkDtype('shouldBeUint8', 'uint8', uint8([]));
            testCase.verifyClass(value, 'uint8')

            % Minimum byte-size type is uint64, uint8 should be converted to uint64
            value = types.util.checkDtype('shouldBeUint64', 'uint64', uint8([]));
            testCase.verifyClass(value, 'uint64')

            % Minimum byte-size type is uint32, uint8 should be converted to uint32
            value = types.util.checkDtype('shouldBeUint32', 'uint32', uint8([]));
            testCase.verifyClass(value, 'uint32')

            % Uint64 can not be represented as uint8 without precision
            % loss, value will be uint64
            value = types.util.checkDtype('shouldBeUint64', 'uint8', uint64([]));
            testCase.verifyClass(value, 'uint64')

            value = types.util.checkDtype('shouldBeChar', 'char', []);
            testCase.verifyClass(value, 'char')

            value = types.util.checkDtype('shouldBeLogical', 'logical', []);
            testCase.verifyClass(value, 'logical')
        end

        function testPrecisionLossError(testCase)
            testCase.verifyError(...
                @() types.util.checkDtype('precisionLossError', 'uint64', single(realmax('single'))), ...
                'NWB:CheckDataType:InvalidConversion')
        end



    end

    methods (Static)
        function [structVal, tableVal, mapVal] = getCompoundValues(varargin)

            structVal = struct(varargin{:});

            tableVal = struct2table(structVal);

            mapVal = containers.Map(...
                fieldnames(structVal), ...
                struct2cell(structVal));
        end
    end
end
