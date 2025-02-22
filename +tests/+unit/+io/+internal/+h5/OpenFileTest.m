classdef OpenFileTest < matlab.unittest.TestCase
    properties
        TestFile
    end
    
    methods (TestClassSetup)
        function createTestFile(testCase)
            % Create a temporary test file
            testCase.TestFile = [tempname '.h5'];
            fileId = H5F.create(testCase.TestFile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(fileId);
            
            % Add test file cleanup
            testCase.addTeardown(@delete, testCase.TestFile);
        end
    end
    
    methods (Test)
        function testDefaultReadOnlyAccess(testCase)
            % Test default read-only access
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile); %#ok<*ASGLU>
            testCase.verifyTrue( logical(H5F.is_hdf5(testCase.TestFile)) );
            
            % Verify read-only by attempting to create a group (should fail)
            testCase.verifyError(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            % Clear cleanup object explicitly to close file
            clear cleanupObj;
        end
        
        function testExplicitReadOnlyAccess(testCase)
            % Test explicit read-only access
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile, "r");
            testCase.verifyTrue( logical(H5F.is_hdf5(testCase.TestFile)) );
            
            % Verify read-only by attempting to create a group (should fail)
            testCase.verifyError(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear cleanupObj;
        end
        
        function testWriteAccess(testCase)
            % Test write access
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile, "w");
            testCase.verifyTrue( logical(H5F.is_hdf5(testCase.TestFile)) );
            
            % Verify write access by creating a group
            testCase.verifyWarningFree(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'));
            
            clear cleanupObj;
        end
        
        function testFileCleanup(testCase)
            % Test that cleanup object properly closes file
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile);
                        
            % Clear cleanup object to close file
            clear cleanupObj;
                      
            testCase.assertClass(fileId, "H5ML.id")
            testCase.assertEqual(double(fileId), -1)
        end
        
        
        function testInvalidPermission(testCase)
            % Test invalid permission argument
            testCase.verifyError(...
                @() io.internal.h5.openFile(testCase.TestFile, "x"), ...
                'MATLAB:validators:mustBeMember');
        end
        
        function testMultipleOpens(testCase)
            % Test opening file multiple times
            [fileId1, cleanupObj1] = io.internal.h5.openFile(testCase.TestFile);
            [fileId2, cleanupObj2] = io.internal.h5.openFile(testCase.TestFile);
            
            % Verify both file IDs are valid and different
            testCase.verifyNotEqual(fileId1, fileId2, ...
                'Multiple opens should return different file IDs');
            
            clear cleanupObj1 cleanupObj2;
        end
        
        function testReadWriteOperations(testCase)
            % Test combined read/write operations
            % First write some data
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile, "w");
            
            % Create a group
            groupId = H5G.create(fileId, '/test_data', 'H5P_DEFAULT', ...
                'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.close(groupId);
            
            clear cleanupObj;
            
            % Then read it back
            [fileId, cleanupObj] = io.internal.h5.openFile(testCase.TestFile, "r");
            
            % Verify group exists
            existGroup = H5L.exists(fileId, '/test_data', 'H5P_DEFAULT');
            testCase.verifyTrue(logical(existGroup));
            
            clear cleanupObj;
        end
    end
end
