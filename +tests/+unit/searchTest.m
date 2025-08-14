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

        function testSearchWithoutTypeNamespace(testCase)
            nwb = NwbFile();
            nwb.acquisition.set('ts1', types.core.TimeSeries());
            nwb.acquisition.set('ts2', types.core.BehavioralTimeSeries());

            testCase.assertLength(nwb.searchFor('TimeSeries'), 2);
        end

        function testGetType(testCase)
            % Test that getTypeObjects method does exact type match,
            % contrary to searchFor
            nwb = NwbFile();
            nwb.acquisition.set('ts1', types.core.TimeSeries());
            nwb.acquisition.set('ts2', types.core.BehavioralTimeSeries());
            testCase.assertLength(nwb.getTypeObjects('TimeSeries'), 1);
        end

        function testGetTypeWithSubclasses(testCase)
            % Test that getTypeObjects method does exact type match and
            % includes subclasses
            nwb = NwbFile();
            nwb.acquisition.set('ts1', types.core.TimeSeries());
            nwb.acquisition.set('ts2', types.core.PatchClampSeries());
            nwb.acquisition.set('ts3', types.core.BehavioralTimeSeries());
            
            testCase.verifyLength(...
                nwb.getTypeObjects('TimeSeries', 'IncludeSubTypes', true), 2);
        end

        function testGetTypeVsSearchFor(testCase)
            % Test that getTypeObjects method does exact type match,
            % contrary to searchFor
            nwb = NwbFile();
            nwb.acquisition.set('im1', types.core.Images());
            nwb.acquisition.set('im2', types.core.ImageSeries());
            nwb.acquisition.set('im3', types.core.OpticalSeries());
            
            % GetTypeObjects should only match objects of "Images" type
            testCase.verifyLength(...
                nwb.getTypeObjects('Images'), 1);

            % searchFor should find both objects of "Images" and "ImageSeries" type
            testCase.verifyLength(...
                nwb.searchFor('Images'), 2);
           
            % GetTypeObjects with subclasses should only match objects of "Images" type
            testCase.verifyLength(...
                nwb.getTypeObjects('Images', 'IncludeSubTypes', true), 1);

            % searchFor with subclasses will also match OpticalSeries as it
            % is a subclass of ImageSeries.
            testCase.verifyLength(...
                nwb.searchFor('Images', 'includeSubClasses'), 3);
        end

        function testSameNameDifferentNamespace(testCase)

            schemaRootDirectory = fullfile(misc.getMatnwbDir(), '+tests', 'test-schema');

            import tests.fixtures.ExtensionGenerationFixture

            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.GenerateCoreFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;

            namespaceFilePath = fullfile( ...
                schemaRootDirectory, 'dupliNameSchema', 'dn.namespace.yaml');

            testCase.applyFixture( ...
                ExtensionGenerationFixture(namespaceFilePath, typesOutputFolder) )

            nwb = NwbFile();
            nwb.acquisition.set('im1', types.core.Images());
            nwb.acquisition.set('im2', types.dupliname.Images());

            testCase.verifyLength( nwb.getTypeObjects('Images'), 2 );

            testCase.verifyLength( nwb.getTypeObjects('types.core.Images'), 1 );
            testCase.verifyLength( nwb.getTypeObjects('types.dupliname.Images'), 1 );
        end
    end
end
