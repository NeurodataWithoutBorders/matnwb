classdef TypeConversionTest < matlab.unittest.TestCase
% TypeConversionTest - Unit test for io.getMatType and io.getBaseType functions.
    
    properties (TestParameter)
        matlabType = {...
            'types.untyped.ObjectView', ...
            'types.untyped.RegionView', ...
            'char', ...
            'double', ...
            'single', ...
            'logical', ...
            'int8', 'int16', 'int32', 'int64', ...
            'uint8', 'uint16', 'uint32', 'uint64', ...
            }
    end

    methods (Test)

        function testRoundTrip(testCase, matlabType)
            tid = io.getBaseType(matlabType);
            testCase.verifyEqual(io.getMatType(tid), matlabType);
        end

        function testRoundTripCell(testCase)
            tid = io.getBaseType('cell');
            testCase.verifyEqual(io.getMatType(tid), 'char');
        end

        function testRoundTripDatetime(testCase)
            tid = io.getBaseType('datetime');
            testCase.verifyEqual(io.getMatType(tid), 'char');
        end
                
        function testRoundTripStruct(testCase)
            testCase.verifyError(@(type)io.getBaseType('struct'), ...
                'NWB:IO:UnsupportedBaseType');
        end
        
        function testDoubleType(testCase)
            tid = H5T.copy('H5T_IEEE_F64LE');
            testCase.verifyEqual(io.getMatType(tid), 'double');
        end
        
        function testSingleType(testCase)
            tid = H5T.copy('H5T_IEEE_F32LE');
            testCase.verifyEqual(io.getMatType(tid), 'single');
        end
        
        function testUint8Type(testCase)
            tid = H5T.copy('H5T_STD_U8LE');
            testCase.verifyEqual(io.getMatType(tid), 'uint8');
        end
        
        function testInt8Type(testCase)
            tid = H5T.copy('H5T_STD_I8LE');
            testCase.verifyEqual(io.getMatType(tid), 'int8');
        end
        
        function testUint16Type(testCase)
            tid = H5T.copy('H5T_STD_U16LE');
            testCase.verifyEqual(io.getMatType(tid), 'uint16');
        end
        
        function testInt16Type(testCase)
            tid = H5T.copy('H5T_STD_I16LE');
            testCase.verifyEqual(io.getMatType(tid), 'int16');
        end
        
        function testUint32Type(testCase)
            tid = H5T.copy('H5T_STD_U32LE');
            testCase.verifyEqual(io.getMatType(tid), 'uint32');
        end
        
        function testInt32Type(testCase)
            tid = H5T.copy('H5T_STD_I32LE');
            testCase.verifyEqual(io.getMatType(tid), 'int32');
        end
        
        function testUint64Type(testCase)
            tid = H5T.copy('H5T_STD_U64LE');
            testCase.verifyEqual(io.getMatType(tid), 'uint64');
        end
        
        function testInt64Type(testCase)
            tid = H5T.copy('H5T_STD_I64LE');
            testCase.verifyEqual(io.getMatType(tid), 'int64');
        end
        
        function testCharType(testCase)
            tid = io.getBaseType('char'); % Assuming io.getBaseType exists
            testCase.verifyEqual(io.getMatType(tid), 'char');
        end
        
        function testObjectViewType(testCase)
            tid = H5T.copy('H5T_STD_REF_OBJ');
            testCase.verifyEqual(io.getMatType(tid), 'types.untyped.ObjectView');
        end
        
        function testRegionViewType(testCase)
            tid = H5T.copy('H5T_STD_REF_DSETREG');
            testCase.verifyEqual(io.getMatType(tid), 'types.untyped.RegionView');
        end
        
        function testLogicalType(testCase)
            % Simulate or define a logical type ID for testing
            tid = H5T.enum_create('H5T_NATIVE_INT');
            H5T.enum_insert(tid, 'FALSE', 0);
            H5T.enum_insert(tid, 'TRUE', 1);
            
            testCase.verifyEqual(io.getMatType(tid), 'logical');
        end
        
        function testTableType(testCase)
            tid = H5T.create('H5T_COMPOUND', 10);
            testCase.verifyEqual(io.getMatType(tid), 'table');
        end
        
        function testUnknownType(testCase)
            tid = H5T.copy('H5T_NATIVE_B64'); % Example of an unknown type
            testCase.verifyError(@() io.getMatType(tid), 'NWB:IO:GetMatlabType:UnknownTypeID');
        end
    end
end
