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
            if ~isempty(value)
                testCase.verifyTrue( strcmp(value, 'TRUE'))
            else
                % Pass this test. h5readatt does not properly read enum
                % values in Releases <= R2022a. Also, in MatNWB attributes
                % are parsed using io.parseAttributes, so this verification is 
                % not critical.
            end

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
        
        function testWriteCompoundMap(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = containers.Map({'a', 'b'}, 1:2);
            io.writeCompound(fid, '/map_data', data)
            H5F.close(fid);
        end
        
        function testWriteCompoundEmpty(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = struct;
            testCase.verifyError(...
                @(varargin) io.writeCompound(fid, '/map_data', data), ...
                'MATLAB:imagesci:hdf5lib:libraryError')
            H5F.close(fid);
        end
        
        function testWriteCompoundScalar(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            fid = H5F.create('test.h5');
            data = struct('a','b');
            io.writeCompound(fid, '/map_data', data)
            H5F.close(fid);
        end

        function testWriteCompoundNonScalar(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
            
            numRows = 5;
            numericVector = rand(numRows, 1);
            charVector = char(randi([65 90], numRows, 1));
            %stringVector = string(char(randi([65 90], numRows, 1)));
            data = table(numericVector, charVector);
                        
            fid = H5F.create('test.h5');
            io.writeCompound(fid, '/map_data', data)
            H5F.close(fid);
        end

        function testWriteCompoundOverWrite(testCase)
                   
            % Create a temporary HDF5 file
            filename = 'temp_test_file.h5';
            fullPath = '/test_dataset';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));
            
            % Initial data to write (e.g., 10x10)
            initialData = struct('a', 1, 'b', true, 'c', 'test');
            io.writeCompound(fid, fullPath, initialData, 'forceArray');  % First write to create the dataset
            
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

        function testHDF5WriterDelegatesToWriteHelpers(testCase)
            filename = 'temp_writer_test.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));

            writer = io.backend.BackendFactory.createWriter(fid);
            testCase.verifyClass(writer, 'io.backend.hdf5.HDF5Writer')

            writer.writeGroup('/test_group');
            writer.writeValue('/test_group/test_dataset', uint8([1 2 3]));
            writer.writeAttribute('/test_group/test_dataset/unit', 'n/a');

            testCase.verifyEqual(h5read(filename, '/test_group/test_dataset'), uint8([1; 2; 3]))
            testCase.verifyEqual(h5readatt(filename, '/test_group/test_dataset', 'unit'), 'n/a')
        end

        function testGeneratedExportAcceptsWriterObject(testCase)
            filename = 'temp_generated_export_writer_test.nwb';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@(id) H5F.close(fid));

            writer = io.backend.BackendFactory.createWriter(fid);
            device = types.core.Device('description', 'device exported through writer');

            refs = device.export(writer, '/device', {});
            testCase.verifyEmpty(refs)

            deviceInfo = h5info(filename, '/device');
            attributeNames = {deviceInfo.Attributes.Name};

            testCase.verifyTrue(ismember('description', attributeNames))
            testCase.verifyTrue(ismember('namespace', attributeNames))
            testCase.verifyTrue(ismember('neurodata_type', attributeNames))
            testCase.verifyEqual(h5readatt(filename, '/device', 'description'), 'device exported through writer')
            testCase.verifyEqual(h5readatt(filename, '/device', 'neurodata_type'), 'Device')
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

        function testWriteObjectReferenceWithLeadingNull(testCase)
            % Regression test: a reference column whose first element is a
            % null (empty) reference must export. On HDF5 1.14+ (MATLAB
            % R2024a and newer) H5D.write rejects a leading null reference
            % when the whole buffer is written at once, so io.writeDataset
            % writes only the non-null references and leaves the null slots
            % as the dataset's zero fill value.
            filename = 'temp_leading_null_ref.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@() H5F.close(fid)); %#ok<NASGU>

            % Targets that the references point to.
            io.writeDataset(fid, '/target_one', rand(3, 1));
            io.writeDataset(fid, '/target_two', rand(3, 1));

            % References with a null in the first and a middle position.
            references = [ ...
                types.untyped.ObjectView(''); ...
                types.untyped.ObjectView('/target_one'); ...
                types.untyped.ObjectView(''); ...
                types.untyped.ObjectView('/target_two')];

            io.writeDataset(fid, '/references', references);

            % Null slots read back as null references; valid slots resolve.
            did = H5D.open(fid, '/references');
            didCleanupObj = onCleanup(@() H5D.close(did)); %#ok<NASGU>
            referenceBuffer = H5D.read(did);
            isNullReference = all(referenceBuffer == 0, 1);
            testCase.verifyEqual(isNullReference, logical([1 0 1 0]))
            testCase.verifyEqual( ...
                H5R.get_name(did, 'H5R_OBJECT', referenceBuffer(:, 2)), '/target_one')
            testCase.verifyEqual( ...
                H5R.get_name(did, 'H5R_OBJECT', referenceBuffer(:, 4)), '/target_two')
        end

        function testWriteObjectReferenceAllNull(testCase)
            % A reference column that is entirely null references should
            % export and read back as all null references.
            filename = 'temp_all_null_ref.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@() H5F.close(fid)); %#ok<NASGU>

            references = [types.untyped.ObjectView(''); types.untyped.ObjectView('')];
            io.writeDataset(fid, '/references', references);

            did = H5D.open(fid, '/references');
            didCleanupObj = onCleanup(@() H5D.close(did)); %#ok<NASGU>
            referenceBuffer = H5D.read(did);
            testCase.verifyTrue(all(referenceBuffer(:) == 0))
            testCase.verifyEqual(size(referenceBuffer, 2), 2)
        end

        function testWriteObjectReferenceNoNull(testCase)
            % A reference column with no null references (the common case)
            % must be written in full and resolve on read-back. Guards against
            % the non-null path being skipped when null slots are handled
            % separately.
            filename = 'temp_no_null_ref.h5';
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            fileCleanupObj = onCleanup(@() H5F.close(fid)); %#ok<NASGU>

            % Targets that the references point to.
            io.writeDataset(fid, '/target_one', rand(3, 1));
            io.writeDataset(fid, '/target_two', rand(3, 1));

            references = [ ...
                types.untyped.ObjectView('/target_one'); ...
                types.untyped.ObjectView('/target_two')];
            io.writeDataset(fid, '/references', references);

            did = H5D.open(fid, '/references');
            didCleanupObj = onCleanup(@() H5D.close(did)); %#ok<NASGU>
            referenceBuffer = H5D.read(did);
            % No slot is a null reference and both resolve to their targets.
            testCase.verifyFalse(any(all(referenceBuffer == 0, 1)))
            testCase.verifyEqual( ...
                H5R.get_name(did, 'H5R_OBJECT', referenceBuffer(:, 1)), '/target_one')
            testCase.verifyEqual( ...
                H5R.get_name(did, 'H5R_OBJECT', referenceBuffer(:, 2)), '/target_two')
        end
    end
end
