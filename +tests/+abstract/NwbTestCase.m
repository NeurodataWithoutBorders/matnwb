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

        function clearExtension(testCase, extensionName)
            extensionName = char(extensionName);
            namespaceFolderName = strrep(extensionName, '-', '_');
            typesOutputFolder = testCase.getTypesOutputFolder();
            rmdir(fullfile(typesOutputFolder, '+types', ['+', namespaceFolderName]), 's')
            delete(fullfile(typesOutputFolder, 'namespaces', [extensionName '.mat']))
        end
    end
end