classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    searchTest < matlab.unittest.TestCase
    
    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testSearch(testCase)
            nwb = NwbFile();
            testCase.assertEmpty(nwb.searchFor('types.core.TimeSeries'));
            
            nwb.acquisition.set('ts1', types.core.TimeSeries());
            testCase.assertNotEmpty(nwb.searchFor('types.core.TimeSeries'));
            testCase.assertNotEmpty(nwb.searchFor('types.core.timeseries'));
            nwb.acquisition.set('pc1', types.core.PatchClampSeries());
            
            % default search does NOT include subclasses
            testCase.assertLength(nwb.searchFor('types.core.TimeSeries'), 1);
            
            % use includeSubClasses keyword
            testCase.assertLength(nwb.searchFor('types.core.TimeSeries', 'includeSubClasses'), 2);
        end
    end
end
