classdef DeleteGroupTest < matlab.unittest.TestCase
    properties
        TestFile
    end
    
    methods (TestClassSetup)
        function createTestFile(testCase)
            % Create a temporary test file with test groups
            testCase.TestFile = [tempname '.h5'];
            fileId = H5F.create(testCase.TestFile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create test groups
            H5G.create(fileId, '/group1', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');

            group2Id = H5G.create(fileId, '/group2', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.create(group2Id, 'subgroup', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.close(group2Id);
            
            H5G.create(fileId, '/group3', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');

            % Create a dataset (to test error case)
            space_id = H5S.create_simple(1, 1, []);
            dset_id = H5D.create(fileId, '/dataset1', 'H5T_NATIVE_INT', space_id, 'H5P_DEFAULT');
            H5D.close(dset_id);
            H5S.close(space_id);
            
            H5F.close(fileId);
            
            % Add test file cleanup
            testCase.addTeardown(@delete, testCase.TestFile);
        end
    end
    
    methods (Test)
        function testDeleteTopLevelGroup(testCase)
            % Test deleting a top-level group
            io.internal.h5.deleteGroup(testCase.TestFile, "/group1");

            testCase.verifyError(...
                @(varargin) h5info(testCase.TestFile, "/group1"), ...
                'MATLAB:imagesci:h5info:unableToFind')
        end
        
        function testDeleteNestedGroup(testCase)
            % Test deleting a nested group
            io.internal.h5.deleteGroup(testCase.TestFile, "/group2/subgroup");
            
            testCase.verifyError(...
                @(varargin) h5info(testCase.TestFile, "/group2/subgroup"), ...
                'MATLAB:imagesci:h5info:unableToFind')

            S = h5info(testCase.TestFile, "/group2");
            testCase.verifyClass(S, 'struct');
            testCase.verifyEqual(S.Name, '/group2');
        end
        
        function testDeleteNonexistentGroup(testCase)
            % Test deleting a nonexistent group
            testCase.verifyError(...
                @() io.internal.h5.deleteGroup(testCase.TestFile, "/nonexistent"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
        end
        
        function testDeleteDataset(testCase)
            % Test deleting a dataset using deleteGroup (should fail)
            testCase.verifyError(...
                @() io.internal.h5.deleteGroup(testCase.TestFile, "/dataset1"), ...
                'NWB:DeleteGroup:NotAGroup');
        end
        
        function testDeleteWithRelativePath(testCase)
            % Test deleting using a relative path
            io.internal.h5.deleteGroup(testCase.TestFile, "group3");
            
            % Verify group is deleted
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile); %#ok<ASGLU>
            
            testCase.verifyFalse(...
                logical(H5L.exists(fileId, '/group3', 'H5P_DEFAULT')), ...
                'Group should be deleted when using relative path');
            
            clear fileCleanup;
        end
    end
end
