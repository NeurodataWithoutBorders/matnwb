classdef OpenObjectTest < matlab.unittest.TestCase
    properties
        TestFile
    end
    
    methods (TestClassSetup)
        function createTestFile(testCase)
            % Create a temporary test file with test objects
            testCase.TestFile = [tempname '.h5'];
            fileId = H5F.create(testCase.TestFile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create test group
            H5G.create(fileId, '/test_group', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create nested group
            nestedGroupId = H5G.create(fileId, '/test_group/nested_group', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.close(nestedGroupId);
            
            % Create test dataset
            space_id = H5S.create_simple(1, 1, []);
            dset_id = H5D.create(fileId, '/test_dataset', 'H5T_NATIVE_INT', space_id, 'H5P_DEFAULT');
            H5D.close(dset_id);
            H5S.close(space_id);
            
            % Create dataset in group
            space_id = H5S.create_simple(1, 1, []);
            dset_id = H5D.create(fileId, '/test_group/group_dataset', 'H5T_NATIVE_INT', space_id, 'H5P_DEFAULT');
            H5D.close(dset_id);
            H5S.close(space_id);
            
            H5F.close(fileId);
            
            % Add test file cleanup
            testCase.addTeardown(@delete, testCase.TestFile);
        end
    end
    
    methods (Test)
        function testOpenGroup(testCase)
            % Test opening a group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile); %#ok<*ASGLU>
            [objectId, objectCleanup] = io.internal.h5.openObject(fileId, "/test_group");
            
            % Verify object is valid and is a group
            testCase.verifyTrue(logical(H5I.is_valid(objectId)));
            objInfo = H5O.get_info(objectId);
            testCase.verifyEqual(objInfo.type, H5ML.get_constant_value('H5O_TYPE_GROUP'));
            
            clear objectCleanup fileCleanup;
        end
        
        function testOpenDataset(testCase)
            % Test opening a dataset
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            [objectId, objectCleanup] = io.internal.h5.openObject(fileId, "/test_dataset");
            
            % Verify object is valid and is a dataset
            testCase.verifyTrue(logical(H5I.is_valid(objectId)));
            objInfo = H5O.get_info(objectId);
            testCase.verifyEqual(objInfo.type, H5ML.get_constant_value('H5O_TYPE_DATASET'));
            
            clear objectCleanup fileCleanup;
        end
        
        function testOpenNestedGroup(testCase)
            % Test opening a nested group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            [objectId, objectCleanup] = io.internal.h5.openObject(fileId, "/test_group/nested_group");
            
            % Verify object is valid and is a group
            testCase.verifyTrue(logical(H5I.is_valid(objectId)));
            objInfo = H5O.get_info(objectId);
            testCase.verifyEqual(objInfo.type, H5ML.get_constant_value('H5O_TYPE_GROUP'));
            
            clear objectCleanup fileCleanup;
        end
        
        function testOpenDatasetInGroup(testCase)
            % Test opening a dataset inside a group
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            [objectId, objectCleanup] = io.internal.h5.openObject(fileId, "/test_group/group_dataset");
            
            % Verify object is valid and is a dataset
            testCase.verifyTrue(logical(H5I.is_valid(objectId)));
            objInfo = H5O.get_info(objectId);
            testCase.verifyEqual(objInfo.type, H5ML.get_constant_value('H5O_TYPE_DATASET'));
            
            clear objectCleanup fileCleanup;
        end
        
        function testObjectCleanup(testCase)
            % Test that cleanup object properly closes object
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            % Get object ID before cleanup
            [objectId, objectCleanup] = io.internal.h5.openObject(fileId, "/test_group");
            originalId = objectId;
            
            % Clear cleanup object to close object
            clear objectCleanup;
            
            % Verify object is no longer valid
            testCase.verifyFalse(logical(H5I.is_valid(originalId)));
            testCase.assertClass(originalId, "H5ML.id")
            testCase.assertEqual(double(originalId), -1)

            clear fileCleanup;
        end
        
        function testOpenNonexistentObject(testCase)
            % Test opening nonexistent object
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            testCase.verifyError(...
                @() io.internal.h5.openObject(fileId, "/nonexistent"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
            
            clear fileCleanup;
        end
        
        function testMultipleOpens(testCase)
            % Test opening same object multiple times
            [fileId, fileCleanup] = io.internal.h5.openFile(testCase.TestFile);
            
            [objectId1, objectCleanup1] = io.internal.h5.openObject(fileId, "/test_group");
            [objectId2, objectCleanup2] = io.internal.h5.openObject(fileId, "/test_group");
            
            % Verify both object IDs are valid and different
            testCase.verifyTrue(logical(H5I.is_valid(objectId1)));
            testCase.verifyTrue(logical(H5I.is_valid(objectId2)));
            testCase.verifyNotEqual(objectId1, objectId2);
            
            clear objectCleanup1 objectCleanup2 fileCleanup;
        end
    end
end
