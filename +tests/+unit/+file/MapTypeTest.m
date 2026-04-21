classdef MapTypeTest < matlab.unittest.TestCase

    methods (Test)

        function testMapBasicDtypes(testCase)
            testCase.verifyEqual(file.mapType('int'), 'int8')
            testCase.verifyEqual(file.mapType('uint'), 'uint8')
            testCase.verifyEqual(file.mapType('int32'), 'int32')
            testCase.verifyEqual(file.mapType('uint32'), 'uint32')
            testCase.verifyEqual(file.mapType('float32'), 'single')
            testCase.verifyEqual(file.mapType('text'), 'char')
            testCase.verifyEqual(file.mapType('bool'), 'logical')
            testCase.verifyEqual(file.mapType('isodatetime'), 'datetime')
        end

        function testMapAnyDtypes(testCase)
            testCase.verifyEqual(file.mapType(''), 'any')
            testCase.verifyEqual(file.mapType([]), 'any')
            testCase.verifyEqual(file.mapType('None'), 'any')
            testCase.verifyEqual(file.mapType('any'), 'any')
        end

        function testMapCompoundDtype(testCase)
            dtype = { ...
                containers.Map({'name', 'dtype'}, {'count', 'uint'}), ...
                containers.Map({'name', 'dtype'}, {'label', 'text'}) ...
            };

            matlabType = file.mapType(dtype);

            expectedType = struct('count', 'uint8', 'label', 'char');
            testCase.verifyEqual(matlabType, expectedType)
        end

        function testMapReferenceDtypeReturnsMap(testCase)
            dtype = containers.Map( ...
                {'target_type', 'reftype'}, ...
                {'TimeSeries', 'object'});

            matlabType = file.mapType(dtype);

            testCase.verifyClass(matlabType, 'containers.Map')
            testCase.verifyEqual(matlabType, dtype)
        end

        function testUnsupportedDtypeThrowsError(testCase)
            testCase.verifyError( ...
                @() file.mapType('unsupported_dtype'), ...
                'NWB:MapType:UnsupportedDtype')
        end

        function testInvalidDtypeSpecificationThrowsError(testCase)
            testCase.verifyError( ...
                @() file.mapType(1), ...
                'NWB:MapType:InvalidDtype')
        end
    end
end
