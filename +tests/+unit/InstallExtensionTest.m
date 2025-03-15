classdef InstallExtensionTest < tests.abstract.NwbTestCase
    
    methods (TestClassSetup)
        function setupClass(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            testCase.addTeardown(@() testCase.clearExtension("ndx-miniscope"))
        end
    end

    methods (Test)
        function testInstallExtensionFailsWithNoInputArgument(testCase)
            testCase.verifyError(...
                @(varargin) nwbInstallExtension(), ...
                'NWB:InstallExtension:MissingArgument')
        end

        function testInstallExtension(testCase)
            testCase.installExtension("ndx-miniscope");

            typesOutputFolder = testCase.getTypesOutputFolder();
            extensionTypesFolder = fullfile(typesOutputFolder, "+types", "+ndx_miniscope");
            testCase.verifyTrue(isfolder(extensionTypesFolder), ...
                'Folder with extension types does not exist')
        end

        function testUseInstalledExtension(testCase)
            nwbObject = tests.factory.NWBFile();

            miniscopeDevice = types.ndx_miniscope.Miniscope(...
                'deviceType', 'test_device', ...
                'compression', 'GREY', ...
                'frameRate', '30fps', ...
                'framesPerFile', int8(100) );

            nwbObject.general_devices.set('TestMiniscope', miniscopeDevice);
             
            testCase.verifyClass(nwbObject.general_devices.get('TestMiniscope'), ...
                'types.ndx_miniscope.Miniscope')
        end

        function testGetExtensionInfo(testCase)
            extensionName = "ndx-miniscope";
            metadata = matnwb.extension.getExtensionInfo(extensionName);
            testCase.verifyClass(metadata, 'struct')
            testCase.verifyEqual(metadata.name, extensionName)
        end

        function testDownloadUnknownRepository(testCase)
            repositoryUrl = "https://www.unknown-repo.com/anon/my_nwb_extension";
            testCase.verifyError(...
                @() matnwb.extension.internal.downloadExtensionRepository(repositoryUrl, "", "my_nwb_extension"), ...
                 'NWB:InstallExtension:UnsupportedRepository');
        end

        function testBuildRepoDownloadUrl(testCase)

            import matnwb.extension.internal.buildRepoDownloadUrl

            repoUrl = buildRepoDownloadUrl('https://github.com/user/test', 'main');
            testCase.verifyEqual(repoUrl, 'https://github.com/user/test/archive/refs/heads/main.zip')

            repoUrl = buildRepoDownloadUrl('https://github.com/user/test/', 'main');
            testCase.verifyEqual(repoUrl, 'https://github.com/user/test/archive/refs/heads/main.zip')

            repoUrl = buildRepoDownloadUrl('https://gitlab.com/user/test', 'main');
            testCase.verifyEqual(repoUrl, 'https://gitlab.com/user/test/-/archive/main/test-main.zip')

            testCase.verifyError(...
                @() buildRepoDownloadUrl('https://unsupported.com/user/test', 'main'), ...
                'NWB:BuildRepoDownloadUrl:UnsupportedRepository')
        end
    end
end
