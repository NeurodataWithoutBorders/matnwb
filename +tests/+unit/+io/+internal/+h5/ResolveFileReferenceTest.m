classdef ResolveFileReferenceTest < matlab.unittest.TestCase
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
        function testResolveFilePath(testCase)
            % Test resolving a file path
            [fileId, cleanupObj] = io.internal.h5.resolveFileReference(testCase.TestFile);
            
            % Verify file ID is valid
            testCase.verifyTrue(logical(H5I.is_valid(fileId)));
            % Verify cleanup object is created
            testCase.verifyNotEmpty(cleanupObj);
            
            clear cleanupObj;
        end
        
        function testResolveFileId(testCase)
            % Test resolving an existing file ID
            [originalId, originalCleanup] = io.internal.h5.openFile(testCase.TestFile); %#ok<*ASGLU>
            
            % Resolve the file ID
            [resolvedId, cleanupObj] = io.internal.h5.resolveFileReference(originalId);
            
            % Verify resolved ID matches original
            testCase.verifyEqual(resolvedId, originalId);
            % Verify no cleanup object is created
            testCase.verifyEmpty(cleanupObj);
            
            clear originalCleanup;
        end
        
        function testReadPermission(testCase)
            % Test resolving with read permission
            [fileId, cleanupObj] = io.internal.h5.resolveFileReference(testCase.TestFile, "r");
            
            % Verify read-only by attempting to create a group (should fail)
            testCase.verifyError(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear cleanupObj;
        end
        
        function testWritePermission(testCase)
            % Test resolving with write permission
            [fileId, cleanupObj] = io.internal.h5.resolveFileReference(testCase.TestFile, "w");
            
            % Verify write access by creating a group
            testCase.verifyWarningFree(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'));
            
            clear cleanupObj;
        end
        
        function testDefaultPermission(testCase)
            % Test default permission (should be read)
            [fileId, cleanupObj] = io.internal.h5.resolveFileReference(testCase.TestFile);
            
            % Verify read-only by attempting to create a group (should fail)
            testCase.verifyError(@() H5G.create(fileId, '/test_group', ...
                'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear cleanupObj;
        end
        
        function testNonexistentFile(testCase)
            % Test resolving nonexistent file
            nonexistentFile = 'nonexistent.h5';
            testCase.verifyError(...
                @() io.internal.h5.resolveFileReference(nonexistentFile), ...
                'MATLAB:validators:mustBeFile');
        end
        
        function testInvalidPermission(testCase)
            % Test invalid permission argument
            testCase.verifyError(...
                @() io.internal.h5.resolveFileReference(testCase.TestFile, "x"), ...
                'MATLAB:validators:mustBeMember');
        end

        function testNoCleanupWithFileId(testCase)
            % Test that no cleanup occurs when passing file ID
            [originalId, originalCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            % Resolve multiple times
            [resolvedId1, cleanup1] = io.internal.h5.resolveFileReference(originalId);
            [resolvedId2, cleanup2] = io.internal.h5.resolveFileReference(originalId);
            
            % Verify all IDs are the same
            testCase.verifyEqual(resolvedId1, originalId);
            testCase.verifyEqual(resolvedId2, originalId);
            
            % Verify no cleanup objects were created
            testCase.verifyEmpty(cleanup1);
            testCase.verifyEmpty(cleanup2);
            
            % Verify ID is still valid
            testCase.verifyTrue(logical(H5I.is_valid(originalId)));
            
            clear originalCleanup;
        end
    end
end
