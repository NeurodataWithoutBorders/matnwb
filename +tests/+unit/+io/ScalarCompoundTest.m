classdef ScalarCompoundTest < tests.abstract.NwbTestCase
% ScalarCompoundTest - Test that a scalar compound dataset is imported correctly
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testScalarCompoundIO(testCase)
            
            % Generate the compound test schema using fixture
            testCase.applyTestSchemaFixture('rrs');
            testCase.applyTestSchemaFixture('cs');
            
            % Set up file with scalar compound dataset
            nwb = tests.factory.NWBFile();

            ts = tests.factory.TimeSeriesWithTimestamps();
            nwb.acquisition.set('timeseries', ts);

            % Create a structure matching the compound type definition.
            data = struct(...
                'integer', int32(0), ...
                'float', 0, ...
                'text', 'test', ...
                'boolean', false, ...
                'reference', types.untyped.ObjectView(ts));

            % Create data type and add to nwb object
            scalarCompound = types.cs.ScalarCompoundMixedData('data', data);
            nwb.analysis.set('ScalarCompound', scalarCompound);
            
            % Export
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            % Read
            nwbIn = nwbRead(fileName, 'ignorecache');
            scalarCompoundIn = nwbIn.analysis.get('ScalarCompound');
            
            % Verify that dataset was stored as scalar/singleton dataset
            info = h5info(fileName, '/analysis/ScalarCompound/data');
            testCase.verifyEqual(info.Dataspace.Type, 'scalar', ...
                'Expected compound dataset to be saved as scalar/singleton dataset (H5S_SCALAR)')

            % Verify that subtypes were properly postprocessed on read
            testCase.verifyClass(scalarCompoundIn.data.float, 'double')
            testCase.verifyClass(scalarCompoundIn.data.text, 'char')
            testCase.verifyClass(scalarCompoundIn.data.boolean, 'logical')
            testCase.verifyClass(scalarCompoundIn.data.reference, 'types.untyped.ObjectView')
            testCase.verifyEqual(scalarCompoundIn.data.text, 'test')
        end
    end
end