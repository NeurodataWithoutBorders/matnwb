classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    FunctionTests < matlab.unittest.TestCase
% FunctionTests - Unit test for functions.

    methods (TestClassSetup)
        function setupClass(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    
    methods (Test)
        function testString2ValidName(testCase)
            testCase.verifyWarning( ...
                @(n,p) misc.str2validName('Time-Series', "test-a"), ...
                'NWB:CreateValidPropertyName:InvalidPrefix' )

            validName = misc.str2validName('@id', 'at');
            testCase.verifyEqual(string(validName), "at_id")
        end

        function testWriteCompoundMap(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = containers.Map({'a', 'b'}, 1:2);
            io.writeCompound(fid, '/map_data', data)
            H5F.close(fid);
        end
        function testWriteCompoundEmpty(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = struct;
            testCase.verifyError(...
                @(varargin) io.writeCompound(fid, '/map_data', data), ...
                'MATLAB:imagesci:hdf5lib:libraryError')
            H5F.close(fid);
        end
        function testWriteCompoundScalar(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = struct('a','b');
            io.writeCompound(fid, '/map_data', data)
            H5F.close(fid);
        end
        function testIsNeurodatatype(testCase)
            timeSeries = types.core.TimeSeries();
            testCase.verifyTrue(matnwb.utility.isNeurodataType(timeSeries))
            
            dataPipe = types.untyped.DataPipe('data', rand(10,10));
            testCase.verifyFalse(matnwb.utility.isNeurodataType(dataPipe))
        end
    end 
end