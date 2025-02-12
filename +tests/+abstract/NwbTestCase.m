classdef (Abstract, SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        NwbTestCase < matlab.unittest.TestCase
% NwbTestCase - Abstract class providing a shared fixture, and utility
% methods for running tests dependent on generating neurodata type classes

    methods (Access = protected)
        function typesOutputFolder = getTypesOutputFolder(testCase)
            F = testCase.getSharedTestFixtures();
            isMatch = arrayfun(@(x) isa(x, 'tests.fixtures.GenerateCoreFixture'), F);
            F = F(isMatch);
            
            typesOutputFolder = F.TypesOutputFolder;
        end

        function installExtension(testCase, extensionName)
            typesOutputFolder = testCase.getTypesOutputFolder();
            
            % Use evalc to suppress output while running tests.
            matlabExpression = sprintf(...
                'nwbInstallExtension("%s", "savedir", "%s")', ...
                extensionName, typesOutputFolder);
            evalc(matlabExpression);
        end

        function clearExtension(testCase, extensionName)
            extensionName = char(extensionName);
            namespaceFolderName = strrep(extensionName, '-', '_');
            typesOutputFolder = testCase.getTypesOutputFolder();
            rmdir(fullfile(typesOutputFolder, '+types', ['+', namespaceFolderName]), 's')
            delete(fullfile(typesOutputFolder, 'namespaces', [extensionName '.mat']))
        end
    end

    methods (Static, Access = protected)
        function [nwbFile, nwbFileCleanup] = readNwbFileWithPynwb(nwbFilename)
            try
                io = py.pynwb.NWBHDF5IO(nwbFilename);
                nwbFile = io.read();
                nwbFileCleanup = onCleanup(@(x) closePyNwbObject(io));
            catch ME
                error(ME.message)
            end

            function closePyNwbObject(io)
                io.close()
            end
        end
    end
end