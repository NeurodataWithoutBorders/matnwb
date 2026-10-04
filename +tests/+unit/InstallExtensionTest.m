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

        function testInstallExtensionInstallsPinnedDependency(testCase)
            % ndx-microscopy 0.3.0 requires ndx-ophys-devices==0.2.0, which
            % defines types that later versions removed.
            testCase.addTeardown(@() testCase.clearExtension("ndx-ophys-devices"))
            testCase.addTeardown(@() testCase.clearExtension("ndx-microscopy"))
            typesOutputFolder = testCase.getTypesOutputFolder();

            evalc('matnwb.extension.installExtension("ndx-microscopy", "0.3.0", "savedir", typesOutputFolder)');

            dependencyInfo = spec.loadCache("ndx-ophys-devices", "savedir", typesOutputFolder);
            testCase.verifyEqual(string(dependencyInfo.version), "0.2.0")
            testCase.verifyTrue(isfolder(fullfile(typesOutputFolder, "+types", "+ndx_microscopy")))
        end

        function testReplacingDependencyNamesInstalledDependents(testCase)
            % ndx-fiber-photometry 0.2.3 requires ndx-ophys-devices>=0.3.1, and
            % ndx-microscopy 0.3.0 requires ndx-ophys-devices==0.2.0.
            testCase.addTeardown(@() testCase.clearExtension("ndx-ophys-devices"))
            testCase.addTeardown(@() testCase.clearExtension("ndx-fiber-photometry"))
            testCase.addTeardown(@() testCase.clearExtension("ndx-microscopy"))
            typesOutputFolder = testCase.getTypesOutputFolder();
            evalc('matnwb.extension.installExtension("ndx-fiber-photometry", "0.2.3", "savedir", typesOutputFolder)');

            output = evalc('matnwb.extension.installExtension("ndx-microscopy", "0.3.0", "savedir", typesOutputFolder)');

            testCase.verifySubstring(output, 'Replacing extension "ndx-ophys-devices" version 0.3.1 with version 0.2.0')
            testCase.verifySubstring(output, 'may not work with version 0.2.0: ndx-fiber-photometry')
        end

        function testVersionChoicesListReleases(testCase)
            versions = matnwb.extension.internal.listVersionChoices("ndx-miniscope");
            testCase.verifyClass(versions, 'cell')
            testCase.verifyTrue(ismember('0.2.2', versions))
        end

        function testVersionChoicesAreEmptyWithoutOneKnownName(testCase)
            testCase.verifyEmpty(matnwb.extension.internal.listVersionChoices(["ndx-miniscope", "ndx-ecog"]))
            testCase.verifyEmpty(matnwb.extension.internal.listVersionChoices("ndx-no-such-extension-exists"))
            testCase.verifyEmpty(matnwb.extension.internal.listVersionChoices(42))
        end

        function testCatalogExtensionListsNames(testCase)
            names = matnwb.extension.CatalogExtension.listNames();
            testCase.verifyClass(names, 'string')
            testCase.verifyTrue(ismember("ndx-miniscope", names))
            testCase.verifyEqual(matnwb.extension.CatalogExtension.ndx_miniscope.Name, "ndx-miniscope")
        end

        function testUnknownExtensionNameFails(testCase)
            testCase.verifyError(@() nwbInstallExtension("ndx-not-in-the-catalog"), ...
                'NWB:InstallExtension:UnknownExtension')
        end

        function testInstallExtensionRejectsNameOutsideCatalog(testCase)
            testCase.verifyError( ...
                @() matnwb.extension.installExtension("ndx-not-in-the-catalog"), ...
                'NWB:InstallExtension:ExtensionNotFound')
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
