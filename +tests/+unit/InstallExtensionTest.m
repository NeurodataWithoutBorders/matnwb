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

        function testInstallSpecificVersion(testCase)
            typesOutputFolder = testCase.getTypesOutputFolder();
            evalc('matnwb.extension.installExtension("ndx-miniscope", "0.2.2", "savedir", typesOutputFolder)');

            namespaceInfo = spec.loadCache("ndx-miniscope", "savedir", typesOutputFolder);
            testCase.verifyEqual(string(namespaceInfo.version), "0.2.2")
        end

        function testInstallUnknownVersionFails(testCase)
            testCase.verifyError( ...
                @() matnwb.extension.installExtension("ndx-miniscope", "99.0.0", ...
                    "savedir", testCase.getTypesOutputFolder()), ...
                'NWB:InstallExtension:VersionNotFound')
        end

        function testVersionWithSeveralExtensionsFails(testCase)
            testCase.verifyError( ...
                @() nwbInstallExtension(["ndx-miniscope", "ndx-ecog"], "0.1.0"), ...
                'NWB:InstallExtension:VersionForMultipleExtensions')
        end

        function testInstallExtensionWithoutWheel(testCase)
            % ndx-ecg is published on PyPI as a source distribution only.
            testCase.addTeardown(@() testCase.clearExtension("ndx-ecg"))
            testCase.installExtension("ndx-ecg");

            extensionTypesFolder = fullfile(testCase.getTypesOutputFolder(), "+types", "+ndx_ecg");
            testCase.verifyTrue(isfolder(extensionTypesFolder), ...
                'Folder with extension types does not exist')
        end
    end
end
