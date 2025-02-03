classdef NwbClearGeneratedFixture < matlab.unittest.fixtures.Fixture
% NwbClearGeneratedFixture - Fixture for clearing generated NWB classes.
%
%   NwbClearGeneratedFixture provides a fixture for clearing all the
%   generated classes for NWB types from the matnwb folder. When the fixture is 
%   set up, all generated class files for NWB types are deleted. When the 
%   fixture is torn down, generateCore is called to regenerate the classes for 
%   NWB types of the latest NWB version
%
% See also matlab.unittest.fixtures.Fixture generateCore nwbClearGenerated

    properties
        TypesOutputFolder (1,1) string {mustBeFolder} = misc.getMatnwbDir
    end

    methods
        function fixture = NwbClearGeneratedFixture(outputFolder)
            arguments
                outputFolder (1,1) string {mustBeFolder} = misc.getMatnwbDir
            end
            fixture.TypesOutputFolder = outputFolder;
        end
    end
    
    methods
        function setup(fixture)
            fixture.addTeardown( ...
                @() generateCore('savedir', fixture.TypesOutputFolder) )
            nwbClearGenerated(fixture.TypesOutputFolder)
        end
    end

    methods (Access = protected)
        function tf = isCompatible(fixtureA, fixtureB)
            tf = strcmp(fixtureA.TypesOutputFolder, fixtureB.TypesOutputFolder);
        end
    end
end
