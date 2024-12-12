classdef InstallExtensionTest < matlab.unittest.TestCase

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
        function testInstallExtensionFailsWithNoInputArgument(testCase)
            testCase.verifyError(...
                @(varargin) nwbInstallExtension(), ...
                'NWB:InstallExtension:MissingArgument')
        end

        function testInstallExtension(testCase)
            nwbInstallExtension("ndx-miniscope", 'savedir', '.')

            testCase.verifyTrue(isfolder('./+types/+ndx_miniscope'), ...
                'Folder with extension types does not exist')
        end

        function testUseInstalledExtension(testCase)
            nwbObject = testCase.initNwbFile();
            
            miniscopeDevice = types.ndx_miniscope.Miniscope(...
                'deviceType', 'test_device', ...
                'compression', 'GREY', ...
                'frameRate', '30fps', ...
                'framesPerFile', int8(100) );

            nwbObject.general_devices.set('TestMiniscope', miniscopeDevice);
             
            testCase.verifyClass(nwbObject.general_devices.get('TestMiniscope'), ...
                'types.ndx_miniscope.Miniscope')
        end

        function testDisplayExtensionMetadata(testCase)
            extensionName = "ndx-miniscope";
            metadata = matnwb.extension.getExtensionInfo(extensionName);
            testCase.verifyClass(metadata, 'struct')
            testCase.verifyEqual(metadata.name, extensionName)
        end

        function testDownloadUnknownRepository(testCase)
            repositoryUrl = "https://www.unknown-repo.com/anon/my_nwb_extension";
            testCase.verifyError(...
                @() matnwb.extension.internal.downloadExtensionRepository(repositoryUrl, "", "my_nwb_extension"), ...
                 'NWB:InstallExtension:UnknownRepository');
        end
    end

    methods (Static)
        function nwb = initNwbFile()
            nwb = NwbFile( ...
                'session_description', 'test file for nwb extension', ...
                'identifier', 'export_test', ...
                'session_start_time', datetime("now", 'TimeZone', 'local') );
        end
    end
end
