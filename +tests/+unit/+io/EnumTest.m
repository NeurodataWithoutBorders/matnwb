classdef EnumTest < matlab.unittest.TestCase
% ParseDatasetEnumTest - Unit test for enum handling in io.parseDataset function.
%
% This test class verifies the correct parsing of HDF5 enum datasets,
% particularly focusing on boolean enums and unknown enum types.

    methods (TestMethodSetup)
        function setup(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        
        function testParseBooleanEnumScalarDataset(testCase)
            % Test that boolean enum scalar datasets are correctly parsed to logical values
            
            filename = 'test_bool_enum.h5';
            datasetPath = '/boolean_data';
            
            % Create HDF5 file with boolean enum dataset
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create boolean enum type (h5py style)
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'FALSE', 0);
            H5T.enum_insert(enumType, 'TRUE', 1);
            
            % Create scalar dataspace
            sid = H5S.create('H5S_SCALAR');

            % Create dataset
            did = H5D.create(fid, datasetPath, enumType, sid, 'H5P_DEFAULT');
            
            % Write data (TRUE value)
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', int8(1));
            
            % Clean up HDF5 handles
            H5D.close(did);
            H5S.close(sid);
            H5T.close(enumType);
            clear fileCleanup;
            
            % Parse the dataset
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            parsed = io.parseDataset(filename, info, datasetPath, blacklist);
            data = parsed('boolean_data');

            % Verify the data is converted to logical
            testCase.verifyClass(data, 'logical');
            testCase.verifyEqual(data, true);
        end
        
        function testParseBooleanEnumArrayDataset(testCase)
            % Test that boolean enum arrays are correctly parsed to logical arrays
            
            filename = 'test_bool_enum_array.h5';
            datasetPath = '/boolean_array';
            
            % Create HDF5 file with boolean enum dataset
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create boolean enum type
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'FALSE', 0);
            H5T.enum_insert(enumType, 'TRUE', 1);
            
            % Create 1D dataspace with multiple elements
            dims = 5;
            sid = H5S.create_simple(1, dims, dims);
            
            % Create dataset
            did = H5D.create(fid, datasetPath, enumType, sid, 'H5P_DEFAULT');
            
            % Write mixed boolean data
            testData = int8([1, 0, 1, 1, 0]);
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', testData);
            
            % Clean up HDF5 handles
            H5D.close(did);
            H5S.close(sid);
            H5T.close(enumType);
            clear fileCleanup;
            
            % Parse the dataset
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            parsed = io.parseDataset(filename, info, datasetPath, blacklist);
            
            data = parsed('boolean_array');

            % Verify the data is converted to logical array
            testCase.verifyEqual(data.dataType, 'logical');
            testCase.verifyEqual(data.load(), logical([1, 0, 1, 1, 0]'));

            testCase.verifyEqual(data.load(':'), logical([1, 0, 1, 1, 0]'));
        end
        
        function testParseUnknownEnumScalarDataset(testCase)
            % Test that unknown enum datasets trigger a warning and return cell array
            
            filename = 'test_unknown_enum.h5';
            datasetPath = '/color_data';
            
            % Create HDF5 file with custom enum dataset
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create custom enum type (not boolean)
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'RED', 0);
            H5T.enum_insert(enumType, 'GREEN', 1);
            H5T.enum_insert(enumType, 'BLUE', 2);
            
            % Create scalar dataspace
            sid = H5S.create('H5S_SCALAR');

            % Create dataset
            did = H5D.create(fid, datasetPath, enumType, sid, 'H5P_DEFAULT');
            
            % Write data (GREEN value)
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', int8(1));
            
            % Clean up HDF5 handles
            H5D.close(did);
            H5S.close(sid);
            H5T.close(enumType);
            clear fileCleanup;
            
            % Parse the dataset and verify warning is issued
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            
            % Verify that a warning is issued
            parsed = testCase.verifyWarning(...
                @() io.parseDataset(filename, info, datasetPath, blacklist), ...
                'NWB:Dataset:UnknownEnum');
            data = parsed('color_data');
            
            testCase.verifyClass(data, 'cell'); % Todo: should be cell, is int8
        end
        
        function testParseUnknownEnumArray(testCase)
            % Test that unknown enum arrays trigger warning and return cell array
            
            filename = 'test_unknown_enum_array.h5';
            datasetPath = '/color_array';
            
            % Create HDF5 file with custom enum dataset
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create custom enum type
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'RED', 0);
            H5T.enum_insert(enumType, 'GREEN', 1);
            H5T.enum_insert(enumType, 'BLUE', 2);
            
            % Create 1D dataspace
            dims = 3;
            sid = H5S.create_simple(1, dims, dims);
            
            % Create dataset
            did = H5D.create(fid, datasetPath, enumType, sid, 'H5P_DEFAULT');
            
            % Write data
            testData = int8([0, 1, 2]);
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', testData);
            
            % Clean up HDF5 handles
            H5D.close(did);
            H5S.close(sid);
            H5T.close(enumType);
            clear fileCleanup;
            
            % Parse the dataset and verify warning
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            
            testCase.verifyWarning(...
                @() io.parseDataset(filename, info, datasetPath, blacklist), ...
                'NWB:Dataset:UnknownEnum');
            
            parsed = testCase.verifyWarning(...
                @() io.parseDataset(filename, info, datasetPath, blacklist), ...
                'NWB:Dataset:UnknownEnum');
            data = parsed('color_array');
            loadedData = data.load();
            
            % Should return cell array of strings
            testCase.verifyClass(loadedData, 'cell');

            loadedDataMatStyle = data.load(':'); % load_mat_style
            testCase.verifyClass(loadedDataMatStyle, 'cell'); % Todo: should be cell, is int8
        end
        
        function testParseBooleanWithFalseValue(testCase)
            % Test that FALSE enum value is correctly parsed to false
            
            filename = 'test_bool_false.h5';
            datasetPath = '/false_data';
            
            % Create HDF5 file
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create boolean enum type
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'FALSE', 0);
            H5T.enum_insert(enumType, 'TRUE', 1);
            
            % Create scalar dataspace
            dims = 1;
            sid = H5S.create_simple(1, dims, dims);
            
            % Create dataset
            did = H5D.create(fid, datasetPath, enumType, sid, 'H5P_DEFAULT');
            
            % Write data (FALSE value)
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', int8(0));
            
            % Clean up HDF5 handles
            H5D.close(did);
            H5S.close(sid);
            H5T.close(enumType);
            clear fileCleanup;
            
            % Parse the dataset
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            parsed = io.parseDataset(filename, info, datasetPath, blacklist);
            data = parsed('false_data');

            % Verify the data is false
            testCase.verifyEqual(data.dataType, 'logical');
            testCase.verifyEqual(data.load(), false);
        end


        function testParseUnknownEnumAttribute(testCase)
            % Test that unknown enum attributes trigger a warning and are saved as cell array
            
            filename = 'test_unknown_enum_attr.h5';
            datasetPath = '/test_dataset';
            
            % Create HDF5 file with dataset containing custom enum attribute
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fid));
            
            % Create a simple dataset
            dims = 1;
            sid = H5S.create_simple(1, dims, dims);
            did = H5D.create(fid, datasetPath, 'H5T_NATIVE_INT', sid, 'H5P_DEFAULT');
            H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', int32(42));
            
            % Create custom enum type (RED, GREEN, BLUE)
            enumType = H5T.enum_create('H5T_STD_I8LE');
            H5T.enum_insert(enumType, 'RED', 0);
            H5T.enum_insert(enumType, 'GREEN', 1);
            H5T.enum_insert(enumType, 'BLUE', 2);
            
            % Create attribute with enum type
            attrSpace = H5S.create_simple(1, 1, 1);
            aid = H5A.create(did, 'color', enumType, attrSpace, 'H5P_DEFAULT');
            
            % Write enum attribute (GREEN value)
            H5A.write(aid, enumType, int8(1));
            
            % Clean up HDF5 handles
            H5A.close(aid);
            H5S.close(attrSpace);
            H5T.close(enumType);
            H5D.close(did);
            H5S.close(sid);
            clear fileCleanup;
            
            % Parse attributes and verify warning is issued
            info = h5info(filename, datasetPath);
            blacklist = struct('attributes', {{}}, 'groups', {{}});
            
            % Verify that a warning is issued when parsing attributes
            [attrProps, ~] = testCase.verifyWarning(...
                @() io.parseAttributes(filename, info.Attributes, datasetPath, blacklist), ...
                'NWB:Attribute:UnknownEnum');
            
            % The attribute should exist in the returned properties
            testCase.verifyTrue(isKey(attrProps, 'color'));
            
            % The value should be a cell array of strings (enum member names)
            attrValue = attrProps('color');
            testCase.verifyClass(attrValue, 'cell');
        end
    end
end
