classdef OpenGroupTest < matlab.unittest.TestCase
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
        function testOpenRootGroup(testCase)
            % Test opening root group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile); %#ok<*ASGLU>
            [groupId, groupCleanup] = io.internal.h5.openGroup(fileId, "/");
            
            % Verify group is valid
            testCase.verifyTrue(logical(H5I.is_valid(groupId)));
            
            clear groupCleanup fileCleanup;
        end
        
        function testOpenTopLevelGroup(testCase)
            % Test opening a top-level group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            [groupId, groupCleanup] = io.internal.h5.openGroup(fileId, "/group1");
            
            % Verify group is valid
            testCase.verifyTrue(logical(H5I.is_valid(groupId)));
            
            clear groupCleanup fileCleanup;
        end
        
        function testOpenNestedGroup(testCase)
            % Test opening a nested group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            [groupId, groupCleanup] = io.internal.h5.openGroup(fileId, "/group2/subgroup");
            
            % Verify group is valid
            testCase.verifyTrue(logical(H5I.is_valid(groupId)));
            
            clear groupCleanup fileCleanup;
        end
        
        function testGroupCleanup(testCase)
            % Test that cleanup object properly closes group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            % Get group ID before cleanup
            [groupId, groupCleanup] = io.internal.h5.openGroup(fileId, "/group1");
            originalId = groupId;
            
            % Clear cleanup object to close group
            clear groupCleanup;
            
            % Verify group is no longer valid
            testCase.verifyFalse(logical(H5I.is_valid(originalId)));
            
                      
            testCase.assertClass(originalId, "H5ML.id")
            testCase.assertEqual(double(originalId), -1)

            clear fileCleanup;
        end
        
        function testNonexistentGroup(testCase)
            % Test opening nonexistent group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            testCase.verifyError(...
                @() io.internal.h5.openGroup(fileId, "/nonexistent"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear fileCleanup;
        end
        
        function testOpenDatasetAsGroup(testCase)
            % Test attempting to open a dataset as a group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            testCase.verifyError(...
                @() io.internal.h5.openGroup(fileId, "/dataset1"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear fileCleanup;
        end
        
        function testMultipleOpens(testCase)
            % Test opening same group multiple times
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            [groupId1, groupCleanup1] = io.internal.h5.openGroup(fileId, "/group1");
            [groupId2, groupCleanup2] = io.internal.h5.openGroup(fileId, "/group1");
            
            % Verify both group IDs are valid and different
            testCase.verifyTrue(logical(H5I.is_valid(groupId1)));
            testCase.verifyTrue(logical(H5I.is_valid(groupId2)));
            testCase.verifyNotEqual(groupId1, groupId2);
            
            clear groupCleanup1 groupCleanup2 fileCleanup;
        end
        
        function testLocationNormalization(testCase)
            % Test that different path formats work
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            % Test various path formats
            paths = {"/group1", "group1", "/group1/", "//group1", "group1/"};
            
            for i = 1:length(paths)
                [groupId, groupCleanup] = io.internal.h5.openGroup(fileId, paths{i});
                testCase.verifyTrue(logical(H5I.is_valid(groupId)));
                clear groupCleanup;
            end
            
            clear fileCleanup;
        end
    end
end
