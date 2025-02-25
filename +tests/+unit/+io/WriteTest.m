classdef WriteTest < matlab.unittest.TestCase
% WriteTest - Unit test for io.write* functions.

    methods (TestMethodSetup)
        function setup(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        
        function testWriteBooleanAttribute(testCase)
            filename = 'temp_test_file.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
    
            targetPath = '/';
            io.writeGroup(fid, targetPath);

            % Define target dataset path and create it in the HDF5 file
            io.writeAttribute(fid, '/test', true);  % First write to create the dataset
            
            % Read using h5readatt and confirm value
            value = h5readatt(filename, '/', 'test');
            testCase.verifyTrue( strcmp(value, 'TRUE'))

            % Read using io.parseAttributes and confirm value
            blackList = struct(...
                'attributes', {{'.specloc', 'object_id'}},...
                'groups', {{}});   
            
            S = h5info(filename);
            [attributeProperties, ~] =...
                io.parseAttributes(filename, S.Attributes, S.Name, blackList);
            testCase.verifyTrue(attributeProperties('test'))
        end
        
        function testWriteDatasetOverwrite(testCase)
                   
            % Create a temporary HDF5 file
            filename = 'temp_test_file.h5';
            fullPath = '/test_dataset';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));

            % Initial data to write (e.g., 10x10)
            initialData = rand(10, 10);
            io.writeDataset(fid, fullPath, initialData);  % First write to create the dataset
            
            % Attempt to write data of a different size (e.g., 5x5)
            newData = rand(5, 5);
            testCase.verifyWarning(...
                @(varargin) io.writeDataset(fid, fullPath, newData), ...
                'NWB:WriteDataset:ContinuousDatasetResize' ...
                )
        end

        function testWriteCompound(testCase)
            % Create a temporary HDF5 file
            filename = 'temp_test_file.h5';
            fullPath = '/test_dataset';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
            
            % Data to write
            data = struct('a', {1,2}, 'b', {true, false}, 'c', {'test', 'new test'});
            io.writeCompound(fid, fullPath, data);  % First write to create the dataset
            
            loadedData = h5read(filename, '/test_dataset');
            tempT = struct2table(loadedData);
            % Booleans are loaded as int8, need to manually fix
            tempT.b = logical( tempT.b );
            loadedData = table2struct(tempT)';
            testCase.verifyEqual(data, loadedData);

            % Use parse compound
            did = H5D.open(fid, '/test_dataset');
            fsid = H5D.get_space(did);
            loadedData = H5D.read(did, 'H5ML_DEFAULT', fsid, fsid,...
                'H5P_DEFAULT');
            parsedData = io.parseCompound(did, loadedData);
            H5S.close(fsid);
            H5D.close(did);

            parsedData = table2struct( struct2table(parsedData) )';
            testCase.verifyEqual(data, parsedData);
        end

        function testWriteCompoundOverWrite(testCase)
                   
            % Create a temporary HDF5 file
            filename = 'temp_test_file.h5';
            fullPath = '/test_dataset';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
            
            % Initial data to write (e.g., 10x10)
            initialData = struct('a', 1, 'b', true, 'c', 'test');
            io.writeCompound(fid, fullPath, initialData);  % First write to create the dataset
            
            % Attempt to write data of a different size (e.g., 5x5)
            newData = cat(1, initialData, struct('a', 2, 'b', false, 'c', 'new test'));
            testCase.verifyWarning(...
                @(varargin) io.writeCompound(fid, fullPath, newData), ...
                'NWB:WriteCompund:ContinuousCompoundResize' ...
                )
        end

        function testWriteGroupWithPathThatEndsWithSlash(testCase)
            filename = 'temp_test_file.h5';
            fullPath = '/test_group/';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
            groupExists = io.writeGroup(fid, fullPath);
            testCase.verifyFalse(groupExists)

            S = h5info(filename);
            testCase.verifyEqual(S.Groups.Name, '/test_group')
        end

        function testWriteSoftLink(testCase)
            % Create a temporary HDF5 file
            filename = 'temp_test_file.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
            
            % Define target dataset path and create it in the HDF5 file
            targetPath = '/dataset';
            initialData = rand(10, 10);
            io.writeDataset(fid, targetPath, initialData);  % First write to create the dataset
            
            % Define soft link name and use writeSoftLink to create it
            linkName = 'soft_link_to_dataset';
            io.writeSoftLink(targetPath, fid, linkName);
            
            S = h5info(filename);
            testCase.verifyTrue(strcmp(S.Links.Name, linkName))
            testCase.verifyTrue(strcmp(S.Links.Type, 'soft link'))
            testCase.verifyTrue(strcmp(S.Links.Value{1}, targetPath))
        end
    end 
end