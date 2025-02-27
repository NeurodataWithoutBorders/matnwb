classdef GenerateCoreFixture < matlab.unittest.fixtures.Fixture
% GENERATECOREFIXTURE - Fixture for creating classes for NWB types in a temporary folder.
%        
% GENERATECOREFIXTURE provides a fixture for generating classes for neurodata 
% types from the from the core NWB specifications. When the testing framework
% sets up the fixture, it calls the generateCore function to produce the 
% necessary code in a temporary output folder and add it to MATLAB's path. When 
% the framework tears down the fixture, it clears all the classes and deletes 
% the temporary folder, ensuring that no artifacts remain from the test process.
%
% See also matlab.unittest.fixtures.Fixture generateCore
    properties
        % TypesOutputFolder - Folder to output generated types for test
        % classes that share this fixture
        TypesOutputFolder (1,1) string
    end

    methods
        function setup(fixture)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture
            import tests.fixtures.NwbClearGeneratedFixture
            
            % Use the NwbClearGeneratedFixture to clear all generated types
            % from the MatNWB root directory in order to preventing path 
            % conflicts when generating new types in a temporary directory
            fixture.applyFixture( NwbClearGeneratedFixture )
            
            % Use a fixture to add the MatNWB folder to the search path
            fixture.applyFixture( PathFixture( misc.getMatnwbDir() ) );

            % Use a fixture to create a temporary working directory
            F = fixture.applyFixture( TemporaryFolderFixture );
            
            % Generate core types in the temporary folder and add to path
            generateCore('savedir', F.Folder)
            fixture.applyFixture( PathFixture(F.Folder) );

            % Save the folder containing cached namespaces and NWB type classes
            % on the fixture object
            fixture.TypesOutputFolder = F.Folder;
        end
    end
end
