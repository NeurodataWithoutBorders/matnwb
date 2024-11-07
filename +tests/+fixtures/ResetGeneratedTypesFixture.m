classdef ResetGeneratedTypesFixture < matlab.unittest.fixtures.Fixture
    % ResetGeneratedTypesFixture - Fixture for resetting generated NWB classes.
    %
    %   ResetGeneratedTypesFixture clears all the generated classes for NWB
    %   types from the matnwb folder. When the fixture is set up, all generated
    %   class files for NWB types are deleted. When the fixture is torn down, 
    %   generateCore is called to regenerate the classes for NWB types of the 
    %   latest NWB version
    
    methods
        function setup(fixture)
            fixture.addTeardown( @generateCore )
            nwbClearGenerated()

            % Todo: Should get all generated namespaces and regenerate all
            % when tearing down.
        end
    end
end
