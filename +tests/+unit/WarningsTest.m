classdef WarningsTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function setupClass(testCase)
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));

            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore('savedir', '.');
        end
    end

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
