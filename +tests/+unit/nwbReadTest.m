classdef nwbReadTest < tests.abstract.NwbTestCase
% nwbReadTest - Unit tests for testing the nwbRead function.
%
% Important: When using nwbRead in tests, do one of the following:
%   • pass the "ignorecache" flag, **or**
%   • set the "savedir" option to your test’s temp folder
%
% If you don’t, MatNWB will write type definitions into its default
% (root) directory, causing path conflicts with the test suite’s own
% temp location.

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (TestMethodSetup)
        % No method setup
    end

    methods (Test)
        function readFileWithUnsupportedVersion(testCase)
            nwbFile = tests.factory.NWBFile();
            fileName = 'testReadFileWithUnsupportedVersion.nwb';
            nwbExport(nwbFile, fileName)

            % Override the version attribute with an unsupported version number  
            testCase.changeVersionNumberInFile(fileName, '1.0.0')

            testCase.verifyWarning(...
                @(fn) nwbRead(fileName, "ignorecache"), ...
                'NWB:Read:UnsupportedSchemaVersion')
        end

        function readFileWithoutEmbeddedSpecs(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);

            nwbFile = tests.factory.NWBFile();

            fileName = 'testReadFileWithoutSpec.nwb';
            nwbExport(nwbFile, fileName)

            io.internal.h5.deleteGroup(fileName, 'specifications')

            nwbRead(fileName, "savedir", pwd);

            % Should generate types even if specifications are not embedded
            testCase.verifyTrue( isfolder(fullfile(pwd, "+types")) )
        end

        function readFileWithoutSpecLoc(testCase)
            nwbFile = tests.factory.NWBFile();
            fileName = 'testReadFileWithoutSpecLoc.nwb';
            nwbExport(nwbFile, fileName)

            io.internal.h5.deleteAttribute(fileName, '/', '.specloc')

            % When specloc is missing, the specifications are not added to
            % the blacklist, so it will get passed as an input to NwbFile.
            testCase.verifyError(@(fn) nwbRead(fileName, "ignorecache"), 'MATLAB:TooManyInputs');
        end

        function readFileWithUnsupportedVersionAndNoSpecloc(testCase)
            % Todo: Is this different from readFileWithoutEmbeddedSpecsAndWithUnsupportedVersion
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('NWB:Read:UnsupportedSchemaVersion'))
            testCase.applyFixture(SuppressedWarningsFixture('NWB:Read:AttemptReadWithVersionMismatch'))
            
            nwbFile = tests.factory.NWBFile();
            fileName = 'testReadFileWithUnsupportedVersionAndNoSpecloc.nwb';
            nwbExport(nwbFile, fileName)
            
            io.internal.h5.deleteAttribute(fileName, '/', '.specloc')
            
            % Override the version attribute with an unsupported version number  
            testCase.changeVersionNumberInFile(fileName, '1.0.0')

            % When specloc is missing, the specifications are not added to
            % the blacklist, so it will get passed as an input to NwbFile.
            testCase.verifyError(@(fn) nwbRead(fileName, "ignorecache"), 'MATLAB:TooManyInputs');
        end

        function testWasGeneratedByProperty(testCase)
            nwb = tests.factory.NWBFile();
            nwbFilename = testCase.getRandomFilename();
            nwbExport(nwb, nwbFilename);

            nwbIn = nwbRead(nwbFilename, 'ignorecache');
            testCase.verifyTrue(any(contains(nwbIn.general_was_generated_by.load(), 'matnwb')))

            % Export again
            nwbFilename2 = testCase.getRandomFilename();
            nwbExport(nwbIn, nwbFilename2);

            nwbIn2 = nwbRead(nwbFilename2, 'ignorecache');

            % Verify that was_generated_by still has one entry (i.e not getting duplicate entries)
            testCase.verifyEqual(size(nwbIn2.general_was_generated_by.load()), [2,1])
        end
    
        function testLoadAll(testCase)
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('ts', tests.factory.TimeSeriesWithTimestamps);
            fileName = 'testLoadAll.nwb';
            nwbExport(nwbFile, fileName)
            
            nwbIn = nwbRead(fileName, "ignorecache");
            testCase.verifyClass(nwbIn.session_start_time, 'types.untyped.DataStub')

            nwbIn.loadAll();
            testCase.verifyTrue(isa(nwbIn.session_start_time, 'datetime'))

            % Todo: Acquisition (But, loadAll is currently not recursive.)
        end

        function readWithStringFilenameArg(testCase)
            fileName = "testReadWithStringArg.nwb";
            nwbExport(tests.factory.NWBFile(), fileName)
            nwb = nwbRead(fileName, "ignorecache");

            testCase.verifyTrue(~isempty(nwb));
            testCase.verifyClass(nwb, 'NwbFile');
        end

        function testIgnoreCacheFlagForFileWithOtherNWBVersion(testCase)
            
            % Temporarily remove the generated types from path.
            currentTypesFolder = testCase.getTypesOutputFolder();
            testCase.addTeardown(@() addpath(currentTypesFolder))
            rmpath(currentTypesFolder)

            % Generate type classes using older version of NWB schemas
            generateCore('2.1.0', 'savedir', pwd())
            nwbFile = tests.factory.NWBFile();
            fileNameOldVersion = 'file_v2_1_0.nwb';
            nwbExport(nwbFile, fileNameOldVersion)
            clear nwbFile % Important to clear, otherwise test will fail with 
            % error tested for in readFileWithIncompatibleVersion

            nwbClearGenerated(pwd, "ClearCache", true)
            
            % Generate type classes using latest version of NWB schemas
            generateCore('latest', 'savedir', pwd())
            
            % Should see a warning about version mismatch if reading file with 
            % older NWB version using ignorecache flag when the latest
            % version is active in MatNWB
            expectedWarningId = 'NWB:Read:AttemptReadWithVersionMismatch';
            testCase.verifyWarning( ...
                @() nwbRead(fileNameOldVersion, 'ignorecache'), ...
                expectedWarningId)
        end

        function readFileWithIncompatibleVersion(testCase)

            import matlab.unittest.fixtures.SuppressedWarningsFixture
            expectedWarningIdentifier = 'NWB:Read:AttemptReadWithVersionMismatch';
            testCase.applyFixture(SuppressedWarningsFixture(expectedWarningIdentifier))

            % Temporarily remove the generated types from path.
            currentTypesFolder = testCase.getTypesOutputFolder();
            testCase.addTeardown(@() addpath(currentTypesFolder))
            rmpath(currentTypesFolder)

            % Generate type classes using older version of NWB schemas
            generateCore('2.1.0', 'savedir', pwd())
            nwbFile = tests.factory.NWBFile();
            fileNameOldVersion = 'file_v2_1_0.nwb';
            nwbExport(nwbFile, fileNameOldVersion)
            
            % Generate type classes using latest version of NWB schemas.
            % Some older classes are still loaded in memory.
            nwbClearGenerated(pwd, "ClearCache", true)
            generateCore('latest', 'savedir', pwd())

            expectedErrorId = 'NWB:Read:VersionConflict';

            try
                % Simulate reading a file with the latest schema version
                % when a file using an older schema version is on path
                nwbRead(fileNameOldVersion, 'ignorecache');
                testCase.verifyFail('Expected nwbRead to trigger an error.')
            catch ME
                testCase.verifyEqual(ME.cause{1}.identifier, expectedErrorId)
            end
        end
    end

    methods (Access = private, Static)
        function changeVersionNumberInFile(fileName, newVersionNumber)
            % Override the version attribute with an unsupported version number   
            [fileId, fileCleanupObj] = io.internal.h5.openFile(fileName, 'w'); %#ok<ASGLU>
            io.internal.h5.deleteAttribute(fileId, '/', 'nwb_version')
            io.writeAttribute(fileId, '/nwb_version', newVersionNumber)
        end
    end
end
