classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        MustBeH5FileTest < matlab.unittest.TestCase
    
    properties (TestParameter)
        ValidFileName = {'test_file.h5', 'test_file.nwb'}
        InvalidFileName = {'test_file.txt'}
    end

    properties (Constant)
        CreateFileFunction = containers.Map(...
            {'.nwb', '.h5'}, {'createNwbFile','createH5File'} )
    end

    methods (TestClassSetup)
        function createTestFiles(testCase)

            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);

            % Create temporary test files
            h5FileName = testCase.ValidFileName{contains(testCase.ValidFileName, '.h5')};
            nwbFileName = testCase.ValidFileName{contains(testCase.ValidFileName, '.nwb')};

            testCase.createH5File(h5FileName)
            testCase.createNwbFile(nwbFileName)

            % Create file which is not h5  
            s = system( sprintf("touch %s", testCase.InvalidFileName{1}) );
            assert(s==0)
        end
    end
    
    methods (Test)
        function testValidCharPath(testCase, ValidFileName) %#ok<INUSD>
            io.internal.h5.mustBeH5File( char(ValidFileName) )
            io.internal.h5.mustBeH5FileReference( char(ValidFileName) )
        end
        
        function testValidStringPath(testCase, ValidFileName) %#ok<INUSD>
            io.internal.h5.mustBeH5FileReference( string(ValidFileName) )
        end
        
        function testValidH5MLId(testCase, ValidFileName) %#ok<INUSD>
            [fileId, fileCleanup] = io.internal.h5.openFile(ValidFileName); %#ok<ASGLU>
            io.internal.h5.mustBeH5FileReference(fileId)
        end
        
        function testInvalidFileExtension(testCase, InvalidFileName)
            testCase.verifyError(...
                @() io.internal.h5.mustBeH5FileReference(InvalidFileName), ...
                'NWB:validators:mustBeH5File');
        end
        
        function testNonexistentFile(testCase)
            nonexistentFile = 'nonexistent.h5';
            testCase.verifyError(...
                @() io.internal.h5.mustBeH5FileReference(nonexistentFile), ...
                'MATLAB:validators:mustBeFile');
        end
        
        function testInvalidInputType(testCase)
            % Test with invalid input type
            testCase.verifyError(...
                @() io.internal.h5.mustBeH5FileReference(123), ...
                'MATLAB:validators:mustBeA');
        end
        
        function testEmptyString(testCase)
            % Test with empty string
            testCase.verifyError(...
                @() io.internal.h5.mustBeH5FileReference(""), ...
                'MATLAB:validators:mustBeNonzeroLengthText');
        end
    end
    
    methods (Static)
        function createH5File(filePath)
            fileId = H5F.create(filePath, ...
                'H5F_ACC_TRUNC', ...
                'H5P_DEFAULT', ...
                'H5P_DEFAULT');
            H5F.close(fileId);
        end

        function createNwbFile(filePath)
            nwbFile = tests.factory.NWBFile();
            nwbExport(nwbFile, filePath)
        end
    end
end
