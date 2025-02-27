classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
    WarningsTest < matlab.unittest.TestCase

    methods (Test)
        function testWarningIfAttributeDependencyMissing(testCase)
        % Test that warning is displayed when setting the value of a
        % property which depends on another property which is unset,
        % (typically an attribute of an untyped group or dataset)
            
            imaging_plane = types.core.ImagingPlane( ...
                'device', types.untyped.SoftLink( types.core.Device() ), ...
                'excitation_lambda', 600., ...
                'indicator', 'GFP', ...
                'location', 'my favorite brain location');

            % Same as "imaging_plane.grid_spacing_unit = 'micrometer'":
            testCase.verifyWarning(...
                @() setProperty(imaging_plane, 'grid_spacing_unit', 'micrometer'), ...
                'NWB:AttributeDependencyNotSet' ...
                )

            function setProperty(nwbObject, propName, propValue)
                nwbObject.(propName) = propValue;
            end
        end
    end
end
