classdef SingletonDatasetTest < tests.abstract.NwbTestCase

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testNonScalarDataIO(testCase)
            % Test NonScalarData type - should create a non-scalar dataspace
            
            % Generate the singleton test schema using fixture
            testCase.applyTestSchemaFixture('singleton');

            % Set up file with NonScalarData
            nwb = tests.factory.NWBFile();

            % Create NonScalarData with vector data
            data = 1.0;
            nonScalarData = types.singleton.NonScalarData('data', data);
            nwb.analysis.set('NonScalarData', nonScalarData);
            
            nwbExport(nwb, 'test.nwb');
            nwbIn = nwbRead('test.nwb', 'ignorecache');
            
            % Read back and check dataspace
            nonScalarDataIn = nwbIn.analysis.get('NonScalarData');
            
            % Check using HDF5 directly to verify dataspace type
            fileId = H5F.open('test.nwb', 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            datasetId = H5D.open(fileId, '/analysis/NonScalarData/data');
            spaceId = H5D.get_space(datasetId);
            spaceType = H5S.get_simple_extent_type(spaceId);
            
            % Should be H5S_SIMPLE (not H5S_SCALAR)
            testCase.verifyEqual(spaceType, H5ML.get_constant_value('H5S_SIMPLE'), ...
                'NonScalarData should have SIMPLE dataspace');
            
            H5S.close(spaceId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end

        function testScalarDataInheritedIO(testCase)
            % Test ScalarDataInherited type - inherits from NonScalarData but should create scalar dataspace
            
            % Generate the singleton test schema using fixture
            testCase.applyTestSchemaFixture('singleton');
                        
            % Set up file with ScalarDataInherited
            nwb = tests.factory.NWBFile();

            % Create ScalarDataInherited with scalar data (shape [1])
            data = 42.0;
            scalarDataInherited = types.singleton.ScalarDataInherited('data', data);
            nwb.analysis.set('ScalarDataInherited', scalarDataInherited);
            
            nwbExport(nwb, 'test.nwb');
            nwbIn = nwbRead('test.nwb', 'ignorecache');
            
            % Read back and check dataspace
            scalarDataInheritedIn = nwbIn.analysis.get('ScalarDataInherited');
            
            % Check using HDF5 directly to verify dataspace type
            fileId = H5F.open('test.nwb', 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            datasetId = H5D.open(fileId, '/analysis/ScalarDataInherited/data');
            spaceId = H5D.get_space(datasetId);
            spaceType = H5S.get_simple_extent_type(spaceId);
            
            % Should be H5S_SCALAR
            testCase.verifyEqual(spaceType, H5ML.get_constant_value('H5S_SCALAR'), ...
                'ScalarDataInherited should have SCALAR dataspace');
            
            H5S.close(spaceId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end

        function testScalarDataIO(testCase)
            % Test ScalarData type - should create scalar dataspace
            
            % Generate the singleton test schema using fixture
            testCase.applyTestSchemaFixture('singleton');

            % Set up file with ScalarData
            nwb = tests.factory.NWBFile();

            % Create ScalarData with scalar data (shape [1])
            data = 3.14159;
            scalarData = types.singleton.ScalarData('data', data);
            nwb.analysis.set('ScalarData', scalarData);
            
            nwbExport(nwb, 'test.nwb');
            nwbIn = nwbRead('test.nwb', 'ignorecache');
            
            % Read back and check dataspace
            scalarDataIn = nwbIn.analysis.get('ScalarData');
            
            % Check using HDF5 directly to verify dataspace type
            fileId = H5F.open('test.nwb', 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            datasetId = H5D.open(fileId, '/analysis/ScalarData/data');
            spaceId = H5D.get_space(datasetId);
            spaceType = H5S.get_simple_extent_type(spaceId);
            
            % Should be H5S_SCALAR
            testCase.verifyEqual(spaceType, H5ML.get_constant_value('H5S_SCALAR'), ...
                'ScalarData should have SCALAR dataspace');
            
            H5S.close(spaceId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end
    end
end