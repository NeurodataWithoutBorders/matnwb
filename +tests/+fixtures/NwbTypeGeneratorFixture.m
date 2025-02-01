classdef NwbTypeGeneratorFixture < matlab.unittest.fixtures.Fixture
    % NwbTypeGeneratorFixture - Fixture for creating NWB classes in a temporary folder.
    
    methods
        function setup(fixture)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            fprintf("Setting up shared fixture\n")

            fixture.addTeardown( @generateCore )
            nwbClearGenerated()
            
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the MatNWB folder to the search path
            fixture.applyFixture( PathFixture(rootPath) );

            % Use a fixture to create a temporary working directory
            F = fixture.applyFixture( TemporaryFolderFixture );
            generateCore('savedir', F.Folder)
            
            fixture.applyFixture( PathFixture(F.Folder) );
        end
    end
end