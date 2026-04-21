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

        function testRejectsDatasetClassWhenRawDataIsExpected(testCase)
            vectorData = types.hdmf_common.VectorData(...
                'data', int8(1), ...
                'description', 'test');

            testCase.verifyError(...
                @() types.util.checkDtype('data', 'numeric', vectorData), ...
                'NWB:CheckDataType:InvalidConversion')
            testCase.verifyError(...
                @() types.core.Image('data', vectorData), ...
                'NWB:CheckDataType:InvalidConversion')
        end

        function testAnyDtypeAllowsBasicAndTextTypes(testCase)
            stringValue = "hello world";
            cellstrValue = {'hello world'};
            charValue = 'hello world';
            datetimeValue = datetime('now');
            numericValue = uint8(1);

            value = types.util.checkDtype('stringValue', 'any', stringValue);
            testCase.verifyClass(value, 'string')

            value = types.util.checkDtype('cellstrValue', 'any', cellstrValue);
            testCase.verifyTrue(iscellstr(value))

            value = types.util.checkDtype('charValue', 'any', charValue);
            testCase.verifyClass(value, 'char')

            value = types.util.checkDtype('datetimeValue', 'any', datetimeValue);
            testCase.verifyClass(value, 'datetime')

            value = types.util.checkDtype('numericValue', 'any', numericValue);
            testCase.verifyClass(value, 'uint8')
        end

        function testAnyDtypeAllowsCompoundValues(testCase)
            [testValueStruct, testValueTable, testValueMap] = ...
                testCase.getCompoundValues(...
                'a', 1, ...
                'b', 'hello world');

            value = types.util.checkDtype('structValue', 'any', testValueStruct);
            testCase.verifyClass(value, 'struct')

            value = types.util.checkDtype('tableValue', 'any', testValueTable);
            testCase.verifyClass(value, 'table')

            value = types.util.checkDtype('mapValue', 'any', testValueMap);
            testCase.verifyClass(value, 'containers.Map')
        end

        function testAnyDtypeAllowsWrappedValue(testCase)
            wrappedValue = types.untyped.Anon('test', uint8(1));

            value = types.util.checkDtype('wrappedValue', 'any', wrappedValue);

            testCase.verifyClass(value, 'types.untyped.Anon')
            testCase.verifyEqual(value.value, uint8(1))
        end

        function testAnyDtypeAllowsSoftLink(testCase)
            warningResetObj = types.untyped.SoftLink.disablePathDeprecationWarning(); %#ok<NASGU>

            softLinkValue = types.untyped.SoftLink('/some/path');

            value = types.util.checkDtype('softLinkValue', 'any', softLinkValue);

            testCase.verifyClass(value, 'types.untyped.SoftLink')
        end

        function testAnyDtypeRejectsInvalidCompoundFieldValue(testCase)
            invalidCompoundValue = struct('a', {{1, 2}});

            testCase.verifyError(...
                @() types.util.checkDtype('invalidCompoundValue', 'any', invalidCompoundValue), ...
                'NWB:CheckDType:InvalidType')
        end

        function testAnyDtypeRejectsNestedCompoundValue(testCase)
            nestedCompoundValue = struct('a', struct('b', 1));

            testCase.verifyError(...
                @() types.util.checkDtype('nestedCompoundValue', 'any', nestedCompoundValue), ...
                'NWB:CheckDType:NestedCompoundNotSupported')
        end

        function testAnyDtypeRejectsUnsupportedType(testCase)
            testCase.verifyError(...
                @() types.util.checkDtype('invalidValue', 'any', {struct()}), ...
                'NWB:CheckDType:InvalidType')
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
