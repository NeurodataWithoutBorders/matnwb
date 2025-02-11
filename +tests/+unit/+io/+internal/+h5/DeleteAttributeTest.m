classdef DeleteAttributeTest < matlab.unittest.TestCase
    properties
        TestFile
    end

    properties (Constant)
        GroupLocation = "/test_group"
        GroupAttributName = ["group_attr1", "group_attr2"]
        DatasetLocation = "/test_dataset"
        DatasetAttributName = ["dataset_attr1", "dataset_attr2"]
    end
    
    methods (TestClassSetup)
        function createTestFile(testCase)
            % Create a temporary test file with test objects and attributes
            testCase.TestFile = [tempname '.h5'];
            fileId = H5F.create(testCase.TestFile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create a group with attributes
            groupId = H5G.create(fileId, '/test_group', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5A.create(groupId, 'group_attr1', 'H5T_NATIVE_INT', H5S.create('H5S_SCALAR'), 'H5P_DEFAULT');
            H5A.create(groupId, 'group_attr2', 'H5T_NATIVE_INT', H5S.create('H5S_SCALAR'), 'H5P_DEFAULT');
            H5G.close(groupId);
            
            % Create a dataset with attributes
            space_id = H5S.create_simple(1, 1, []);
            dset_id = H5D.create(fileId, '/test_dataset', 'H5T_NATIVE_INT', space_id, 'H5P_DEFAULT');
            H5A.create(dset_id, 'dataset_attr1', 'H5T_NATIVE_INT', H5S.create('H5S_SCALAR'), 'H5P_DEFAULT');
            H5A.create(dset_id, 'dataset_attr2', 'H5T_NATIVE_INT', H5S.create('H5S_SCALAR'), 'H5P_DEFAULT');
            H5D.close(dset_id);
            H5S.close(space_id);
            
            H5F.close(fileId);
            
            % Add test file cleanup
            testCase.addTeardown(@delete, testCase.TestFile);
        end
    end
    
    methods (Test)
        function testDeleteGroupAttribute(testCase)
        % Test deleting an attribute from a group
            
            groupLocation = "/test_group";
            attributeName = ["group_attr1", "group_attr2"];

            io.internal.h5.deleteAttribute(...
                testCase.TestFile, groupLocation, attributeName(1));
            
            % Verify that first attribute is deleted
            testCase.verifyError(@(varargin) h5readatt(...
                    testCase.TestFile, groupLocation, attributeName(1)), ...
                'MATLAB:imagesci:hdf5lib:libraryError' )

            attrValue = h5readatt(...
                testCase.TestFile, groupLocation, attributeName(2));
            
            % Verify that second attribute still exists
            testCase.verifyEqual(attrValue, int32(0))
        end
        
        function testDeleteDatasetAttribute(testCase)
            % Test deleting an attribute from a dataset

            datasetLocation = "/test_dataset";
            datasetAttributName = ["dataset_attr1", "dataset_attr2"];

            io.internal.h5.deleteAttribute(...
                testCase.TestFile, datasetLocation, datasetAttributName(1));
            
            % Verify that first attribute is deleted
            testCase.verifyError( ...
                @(varargin) h5readatt(...
                    testCase.TestFile, datasetLocation, datasetAttributName(1)), ...
                'MATLAB:imagesci:hdf5lib:libraryError' )

            attrValue = h5readatt(...
                testCase.TestFile, datasetLocation, datasetAttributName(2));
            
            % Verify that second attribute still exists
            testCase.verifyEqual(attrValue, int32(0))
        end
        
        function testDeleteNonexistentAttribute(testCase)
            % Test deleting a nonexistent attribute
            testCase.verifyError(...
                @() io.internal.h5.deleteAttribute( ...
                    testCase.TestFile, "/test_group", "nonexistent_attr"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
        end
        
        function testDeleteFromNonexistentObject(testCase)
            % Test deleting attribute from nonexistent object
            testCase.verifyError(...
                @() io.internal.h5.deleteAttribute( ...
                    testCase.TestFile, "/nonexistent", "attr"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
        end
        
        function testDeleteWithInvalidFile(testCase)
            % Test deleting from a nonexistent file
            nonexistentFile = 'nonexistent.h5';
            testCase.verifyError(...
                @() io.internal.h5.deleteAttribute( ...
                    nonexistentFile, "/test_group", "group_attr1"), ...
                'MATLAB:validators:mustBeFile');
        end
    end
end
