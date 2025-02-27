classdef ExtensionGenerationFixture < matlab.unittest.fixtures.Fixture
%EXTENSIONGENERATIONFIXTURE - Fixture for generating an NWB extension.
% 
% EXTENSIONGENERATIONFIXTURE provides a fixture for generating extension code 
% from an NWB specification's namespace file. When the testing framework
% sets up the fixture, it calls the generateExtension function to produce the 
% necessary code in the specified output folder. When the framework tears down
% the fixture, it removes the generated files and associated cache data, 
% ensuring that no artifacts remain from the test generation process.
%
% See also matlab.unittest.fixtures.Fixture generateExtension nwbClearGenerated

    properties
        % TypesOutputFolder - Folder to output generated types for test
        % classes that share this fixture
        TypesOutputFolder (1,1) string

        % NamespaceFilepath - Path name for extension's namespace file
        NamespaceFilepath (1,1) string
    end

    methods
        function fixture = ExtensionGenerationFixture(namespaceFilepath, outputFolder)
            fixture.NamespaceFilepath = namespaceFilepath;
            fixture.TypesOutputFolder = outputFolder;
        end
    end

    methods
        function setup(fixture)
            generateExtension(fixture.NamespaceFilepath, 'savedir', fixture.TypesOutputFolder);
            fixture.addTeardown(@fixture.clearGenerated)
        end
    end

    methods (Access = protected)
        function tf = isCompatible(fixtureA, fixtureB)
            tf = strcmp(fixtureA.NamespaceFilepath, fixtureB.NamespaceFilepath) ...
                 && strcmp(fixtureA.TypesOutputFolder, fixtureB.TypesOutputFolder);
        end
    end

    methods (Access = private)
        function clearGenerated(fixture)
            [~, namespaceFilename] = fileparts(fixture.NamespaceFilepath);
            namespaceName = extractBefore(namespaceFilename, '.');

            generatedTypesDirectory = fullfile(fixture.TypesOutputFolder, "+types", "+"+namespaceName);
            rmdir(generatedTypesDirectory, 's');

            cacheFile = fullfile(fixture.TypesOutputFolder, "namespaces", namespaceName+".mat");
            delete(cacheFile)
        end
    end
end
