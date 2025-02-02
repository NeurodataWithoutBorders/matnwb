classdef NwbTypeGeneratorFixture < matlab.unittest.fixtures.Fixture
% NwbTypeGeneratorFixture - Fixture for creating classes for NWB types in a temporary folder.
    
    properties
        % TypesOutputFolder - Folder to output generated types for test
        % classes that share this fixture
        TypesOutputFolder (1,1) string
    end

    methods
        function setup(fixture)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            fixture.addTeardown( @generateCore )
            nwbClearGenerated()
            
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the MatNWB folder to the search path
            fixture.applyFixture( PathFixture(rootPath) );

            % Use a fixture to create a temporary working directory
            F = fixture.applyFixture( TemporaryFolderFixture );
            
            % Generate core types in the temporary folder and add to path
            generateCore('savedir', F.Folder)
            fixture.applyFixture( PathFixture(F.Folder) );

            % Save the folder containing cached namespaces and types on the
            % fixture object
            fixture.TypesOutputFolder = F.Folder;
        end
    end
end
