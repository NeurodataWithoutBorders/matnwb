classdef ListGroupNamesTest < matlab.unittest.TestCase
    properties
        TestFile
    end
    
    methods (TestClassSetup)
        function createTestFile(testCase)
            % Create a temporary test file
            testCase.TestFile = [tempname '.h5'];
            
            % Create test file with groups
            fileId = H5F.create(testCase.TestFile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create root level groups
            group1Id = H5G.create(fileId, '/group1', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            group2Id = H5G.create(fileId, '/group2', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create nested groups
            H5G.create(group1Id, 'subgroup1', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.create(group1Id, 'subgroup2', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            
            % Create a dataset (should not be listed as a group)
            space_id = H5S.create_simple(1, 1, []);
            dset_id = H5D.create(fileId, '/dataset1', 'H5T_NATIVE_INT', space_id, 'H5P_DEFAULT');
            
            % Close everything
            H5D.close(dset_id);
            H5S.close(space_id);
            H5G.close(group1Id);
            H5G.close(group2Id);
            H5F.close(fileId);
            
            % Add test file cleanup
            testCase.addTeardown(@delete, testCase.TestFile);
        end
    end
    
    methods (Test)
        function testRootLevelGroups(testCase)
            % Test listing groups at root level
            groups = io.internal.h5.listGroupNames(testCase.TestFile, "/");
            testCase.verifyEqual(sort(groups), sort({'group1', 'group2'}), ...
                'Root level groups not listed correctly');
        end
        
        function testNestedGroups(testCase)
            % Test listing nested groups
            groups = io.internal.h5.listGroupNames(testCase.TestFile, "/group1");
            testCase.verifyEqual(sort(groups), sort({'subgroup1', 'subgroup2'}), ...
                'Nested groups not listed correctly');
        end
        
        function testEmptyGroup(testCase)
            % Test listing groups in an empty group
            groups = io.internal.h5.listGroupNames(testCase.TestFile, "/group2");
            testCase.verifyEmpty(groups, 'Empty group should return empty cell array');
        end
        
        function testNonexistentLocation(testCase)
            % Test error when location doesn't exist
            testCase.verifyError(...
                @() io.internal.h5.listGroupNames(testCase.TestFile, "/nonexistent"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
        end
        
        function testDatasetLocation(testCase)
            % Test error when location is a dataset
            testCase.verifyError(...
                @() io.internal.h5.listGroupNames(testCase.TestFile, "/dataset1"), ...
                'MATLAB:imagesci:hdf5lib:libraryError');
        end
    end
end
