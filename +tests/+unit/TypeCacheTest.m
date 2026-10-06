classdef TypeCacheTest < matlab.unittest.TestCase
% TypeCacheTest - Tests for reusing generated classes from the type cache.
%
%   The tests generate small namespaces into a temporary save folder that is
%   not on the MATLAB path, with the cache in another temporary folder. To
%   tell a cache hit from a fresh generation, a test appends a marker line
%   to a class file in the cache entry: the marker reaches the save folder
%   only if the class was copied from the cache.

    properties (Constant)
        Marker = "% marker added to the cache entry by TypeCacheTest"
    end

    properties
        SchemaFolder (1,1) string
        SaveFolder (1,1) string
        CacheFolder (1,1) string
    end

    methods (TestMethodSetup)
        function setupFolders(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            testCase.SchemaFolder = testCase.applyFixture(TemporaryFolderFixture).Folder;
            testCase.SaveFolder = testCase.applyFixture(TemporaryFolderFixture).Folder;
            testCase.CacheFolder = testCase.applyFixture(TemporaryFolderFixture).Folder;

            testCase.applyFixture(tests.fixtures.PreferenceFixture( ...
                "matnwb", "GeneratedTypesCacheFolder", testCase.CacheFolder))
        end
    end

    methods (Test)
        function testRepeatedGenerationCopiesFromCache(testCase)
            parentInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");
            testCase.generate(parentInfo)
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")

            testCase.generate(parentInfo)

            testCase.verifyTrue(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected the class to be copied from the cache.")
        end

        function testCopyFromCacheRestoresSpecification(testCase)
            parentInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");
            testCase.generate(parentInfo)
            delete(fullfile(testCase.SaveFolder, "namespaces", "test-cache.mat"))

            testCase.generate(parentInfo)

            cachedInfo = spec.loadCache("test-cache", "savedir", testCase.SaveFolder);
            testCase.verifyEqual(string(cachedInfo.version), "0.1.0")
        end

        function testChangedSpecificationIsRegenerated(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc."))
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")

            testCase.generate(testCase.parseParentNamespace("0.1.0", "Changed parent doc."))

            testCase.verifyFalse(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected the class to be generated again after the specification changed.")
            classText = fileread(testCase.getSavedClassPath("test-cache", "CacheParent"));
            testCase.verifySubstring(classText, "Changed parent doc.")
        end

        function testChangedDependencyInvalidatesDependent(testCase)
            parentInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");
            childInfo = testCase.parseChildNamespace();
            testCase.generate([parentInfo, childInfo])
            testCase.addMarkerToCacheEntry("test-cache-child", "0.1.0", "CacheChild")

            changedParentInfo = testCase.parseParentNamespace("0.1.0", "Changed parent doc.");
            testCase.generate([changedParentInfo, childInfo])

            testCase.verifyFalse(testCase.hasMarker("test-cache-child", "CacheChild"), ...
                "Expected the dependent class to be generated again after its dependency changed.")
        end

        function testDependencyFromSaveFolderIsUsedForCacheKey(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc."))
            childInfo = testCase.parseChildNamespace();
            testCase.generate(childInfo)
            testCase.addMarkerToCacheEntry("test-cache-child", "0.1.0", "CacheChild")

            % The parent is not passed in, so its key comes from the save folder.
            testCase.generate(childInfo)

            testCase.verifyTrue(testCase.hasMarker("test-cache-child", "CacheChild"), ...
                "Expected the dependent class to be copied from the cache.")
        end

        function testDependentsAreProcessedAfterDependencies(testCase)
            parentInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");
            childInfo = testCase.parseChildNamespace();

            % Embedded specifications list namespaces in no particular order.
            testCase.generate([childInfo, parentInfo])

            testCase.verifyTrue(isfile(testCase.getSavedClassPath("test-cache-child", "CacheChild")))
        end

        function testMissingDependencyThrows(testCase)
            testCase.verifyError(@() testCase.generate(testCase.parseChildNamespace()), ...
                "NWB:Namespace:DependencyMissing")
        end

        function testEntryWithoutRecordIsRegenerated(testCase)
            parentInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");
            testCase.generate(parentInfo)
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")
            delete(fullfile(testCase.getMostRecentEntryFolder("test-cache", "0.1.0"), "record.json"))

            testCase.generate(parentInfo)

            testCase.verifyFalse(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected an entry without a record to be treated as incomplete.")
        end

        function testSwitchingVersionRemovesClassesOfPreviousVersion(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc.", ...
                IncludeExtraType=true))
            extraClassPath = testCase.getSavedClassPath("test-cache", "CacheExtra");
            testCase.assertTrue(isfile(extraClassPath))

            testCase.generate(testCase.parseParentNamespace("0.2.0", "Parent doc."))
            testCase.verifyFalse(isfile(extraClassPath), ...
                "Expected a class missing from the new version to be removed.")

            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc.", ...
                IncludeExtraType=true))
            testCase.verifyTrue(isfile(extraClassPath), ...
                "Expected switching back to restore the class.")
        end

        function testVariantsOfOneVersionAreKeptSideBySide(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc."))
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Changed parent doc."))

            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc."))

            testCase.verifyTrue(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected the first variant to be copied from the cache after the second was generated.")
            testCase.verifyNumElements(testCase.listEntryFolders("test-cache", "0.1.0"), 2)
        end

        function testAtMostThreeEntriesPerVersion(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc 1."))
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")
            for iVariant = 2:4
                testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc " + iVariant + "."))
            end
            testCase.verifyNumElements(testCase.listEntryFolders("test-cache", "0.1.0"), 3)

            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc 1."))

            testCase.verifyFalse(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected the least recently used entry to have been removed.")
            testCase.verifyNumElements(testCase.listEntryFolders("test-cache", "0.1.0"), 3)
        end

        function testCopyFromCacheCountsAsUse(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc A."))
            testCase.addMarkerToCacheEntry("test-cache", "0.1.0", "CacheParent")
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc B."))
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc C."))
            % Use A again, so B becomes the least recently used entry.
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc A."))

            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc D."))
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc A."))

            testCase.verifyTrue(testCase.hasMarker("test-cache", "CacheParent"), ...
                "Expected the entry used most recently before the fourth variant to be kept.")
        end

        function testCachedClassesAreNotAddedByGenpath(testCase)
            testCase.generate(testCase.parseParentNamespace("0.1.0", "Parent doc."))

            pathFolders = split(string(genpath(testCase.CacheFolder)), pathsep);
            pathFolders(pathFolders == "") = [];

            testCase.verifyEqual(pathFolders, string(testCase.CacheFolder), ...
                "Expected genpath to skip the folders that hold cached classes.")
        end

        function testSpecHashIsIndependentOfSourceFormat(testCase)
            yamlInfo = testCase.parseParentNamespace("0.1.0", "Parent doc.");

            % Embedded specifications are JSON, and their namespace
            % declaration lists sources without the .yaml extension.
            namespaceJson = jsonencode(struct("namespaces", {{struct( ...
                "name", "test-cache", ...
                "version", "0.1.0", ...
                "doc", "Namespace for testing the type cache.", ...
                "schema", {{struct("source", "test-cache.extensions")}})}}));
            schemaJson = jsonencode(struct("groups", {{struct( ...
                "neurodata_type_def", "CacheParent", ...
                "doc", "Parent doc.")}}));
            jsonInfo = spec.generate(namespaceJson, ...
                containers.Map({'test-cache.extensions'}, {schemaJson}));

            testCase.verifyEqual( ...
                matnwb.internal.typecache.computeSpecHash(jsonInfo), ...
                matnwb.internal.typecache.computeSpecHash(yamlInfo))
        end
    end

    methods (Access = private)
        function generate(testCase, namespaceInfoList)
            matnwb.internal.typecache.generateNamespaces(namespaceInfoList, testCase.SaveFolder)
        end

        function namespaceInfo = parseParentNamespace(testCase, version, typeDoc, options)
            arguments
                testCase
                version (1,1) string
                typeDoc (1,1) string
                options.IncludeExtraType (1,1) logical = false
            end

            schemaLines = [
                "groups:"
                "- neurodata_type_def: CacheParent"
                "  doc: " + typeDoc
                ];
            if options.IncludeExtraType
                schemaLines = [schemaLines; [
                    "- neurodata_type_def: CacheExtra"
                    "  doc: A type that only one version defines."
                    ]];
            end
            namespaceLines = [
                "namespaces:"
                "- name: test-cache"
                "  version: " + version
                "  doc: Namespace for testing the type cache."
                "  schema:"
                "  - source: test-cache.extensions.yaml"
                ];
            namespaceInfo = testCase.parseNamespace("test-cache", namespaceLines, schemaLines);
        end

        function namespaceInfo = parseChildNamespace(testCase)
            schemaLines = [
                "groups:"
                "- neurodata_type_def: CacheChild"
                "  neurodata_type_inc: CacheParent"
                "  doc: Child doc."
                ];
            namespaceLines = [
                "namespaces:"
                "- name: test-cache-child"
                "  version: 0.1.0"
                "  doc: Namespace that depends on test-cache."
                "  schema:"
                "  - namespace: test-cache"
                "  - source: test-cache-child.extensions.yaml"
                ];
            namespaceInfo = testCase.parseNamespace("test-cache-child", namespaceLines, schemaLines);
        end

        function namespaceInfo = parseNamespace(testCase, name, namespaceLines, schemaLines)
            namespaceFolder = fullfile(testCase.SchemaFolder, name);
            if ~isfolder(namespaceFolder)
                mkdir(namespaceFolder)
            end
            writeText(fullfile(namespaceFolder, name + ".extensions.yaml"), strjoin(schemaLines, newline), "w")
            namespaceText = strjoin(namespaceLines, newline);
            namespaceInfo = spec.generate(char(namespaceText), namespaceFolder);
        end

        function entryFolders = listEntryFolders(testCase, namespaceName, version)
            listing = dir(fullfile(testCase.CacheFolder, "resources", namespaceName, version));
            listing = listing([listing.isdir] & ~ismember({listing.name}, {'.', '..'}));
            entryFolders = string(fullfile({listing.folder}, {listing.name}));
        end

        function entryFolder = getMostRecentEntryFolder(testCase, namespaceName, version)
            entryFolders = testCase.listEntryFolders(namespaceName, version);
            lastUsedTimes = arrayfun(@(folder) str2double(fileread(fullfile(folder, "last-used.txt"))), ...
                entryFolders);
            [~, newestIndex] = max(lastUsedTimes);
            entryFolder = entryFolders(newestIndex);
        end

        function addMarkerToCacheEntry(testCase, namespaceName, version, className)
        % addMarkerToCacheEntry - Mark the class in the most recently used entry.
            classPath = fullfile(testCase.getMostRecentEntryFolder(namespaceName, version), ...
                "+types", "+" + misc.str2validName(char(namespaceName)), className + ".m");
            testCase.assertTrue(isfile(classPath), "Expected a cache entry for " + className + ".")
            writeText(classPath, newline + testCase.Marker + newline, "a")
        end

        function tf = hasMarker(testCase, namespaceName, className)
            classText = fileread(testCase.getSavedClassPath(namespaceName, className));
            tf = contains(classText, testCase.Marker);
        end

        function classPath = getSavedClassPath(testCase, namespaceName, className)
            classPath = fullfile(testCase.SaveFolder, "+types", ...
                "+" + misc.str2validName(char(namespaceName)), className + ".m");
        end
    end
end

function writeText(filePath, text, permission)
% writeText - Write or append text to a file.
    fileId = fopen(filePath, permission);
    fileCleanup = onCleanup(@() fclose(fileId));
    fwrite(fileId, char(text), "char");
end
