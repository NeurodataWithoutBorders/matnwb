classdef MustBeNwbFileTest < matlab.unittest.TestCase
% MustBeNwbFileTest - Unit tests for matnwb.common.mustBeNwbFile.

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testAcceptsExistingFileWithAnyExtension(testCase)
            fileId = fopen("data.h5", "w");
            fclose(fileId);

            testCase.verifyWarningFree(@() matnwb.common.mustBeNwbFile("data.h5"));
        end

        function testAcceptsExistingFolder(testCase)
            mkdir("store.nwb.zarr")

            testCase.verifyWarningFree(@() matnwb.common.mustBeNwbFile("store.nwb.zarr"));
        end

        function testAcceptsS3Uri(testCase)
            testCase.verifyWarningFree( ...
                @() matnwb.common.mustBeNwbFile("s3://bucket/data.nwb"));
        end

        function testRejectsMissingLocation(testCase)
            testCase.verifyError(@() matnwb.common.mustBeNwbFile("missing.nwb"), ...
                'NWB:validators:mustBeNwbFile');
        end
    end
end
