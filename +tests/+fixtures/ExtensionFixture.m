classdef ExtensionFixture < matlab.unittest.fixtures.Fixture
    
    properties
        % TypesOutputFolder - Folder to output generated types for test
        % classes that share this fixture
        TypesOutputFolder (1,1) string

        % NamespaceFilepath - Path name for extension's namespace file
        NamespaceFilepath (1,1) string
    end

    methods
        function fixture = ExtensionFixture(namespaceFilepath, outputFolder)
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
