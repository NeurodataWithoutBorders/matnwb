function writeFunctionSignatures(saveDir)
% writeFunctionSignatures - Write the functionSignatures.json file for generated classes.
%
%   matnwb.internal.typecache.writeFunctionSignatures(saveDir) writes
%   saveDir/resources/functionSignatures.json with an entry for the
%   constructor of every class in saveDir/+types. MATLAB reads the file to
%   suggest name-value arguments while the user types a constructor call.
%
%   MATLAB reads functionSignatures.json only from the resources folder next
%   to the outermost namespace folder, +types. When saveDir is the matnwb
%   root directory, that folder also holds the signatures of the matnwb
%   functions, so the file combines the hand-written entries in
%   resources/function_templates/functionSignatures.json with the entries
%   of the generated classes.
%
%   Each generated namespace folder has a fragment with the entries of its
%   classes, written by file.writeNamespace. The file is rebuilt from the
%   fragments, so it always matches the namespaces in saveDir/+types.

    arguments
        saveDir (1,1) string
    end

    matnwbDir = string(misc.getMatnwbDir());
    if isSameFolder(saveDir, matnwbDir)
        templatePath = fullfile(matnwbDir, "resources", "function_templates", "functionSignatures.json");
        entryBlocks = getObjectContent(fileread(templatePath, "Encoding", "UTF-8"));
    else
        entryBlocks = """_schemaVersion"": ""1.0.0""";
    end

    fragmentList = dir(fullfile(saveDir, "+types", "+*", matnwb.common.constant.SIGNATUREFRAGMENTFILE));
    [~, sortIndex] = sort(string({fragmentList.folder}));
    fragmentList = fragmentList(sortIndex);
    for iFragment = 1:numel(fragmentList)
        fragmentPath = fullfile(fragmentList(iFragment).folder, fragmentList(iFragment).name);
        fragmentContent = getObjectContent(fileread(fragmentPath, "Encoding", "UTF-8"));
        if strlength(fragmentContent) > 0
            entryBlocks(end+1) = fragmentContent; %#ok<AGROW>
        end
    end

    resourcesFolder = fullfile(saveDir, "resources");
    if ~isfolder(resourcesFolder)
        mkdir(resourcesFolder)
    end
    fileText = "{" + newline + strjoin(entryBlocks, "," + newline) + newline + "}" + newline;
    fileId = fopen(fullfile(resourcesFolder, "functionSignatures.json"), "w", "n", "UTF-8");
    fileCleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%s", fileText);
end

function content = getObjectContent(jsonText)
% getObjectContent - Get the text between the outer braces of a JSON object.
%
%   The text is combined as text, not decoded, because the hand-written file
%   repeats a key to declare several signatures for one function, which
%   jsondecode does not keep.

    jsonText = string(jsonText);
    openIndex = strfind(jsonText, "{");
    closeIndex = strfind(jsonText, "}");
    content = strip(extractBetween(jsonText, openIndex(1) + 1, closeIndex(end) - 1));
end

function tf = isSameFolder(folderA, folderB)
    tf = strcmp(getCanonicalPath(folderA), getCanonicalPath(folderB));
end

function canonicalPath = getCanonicalPath(folderPath)
    canonicalPath = string(java.io.File(folderPath).getCanonicalPath());
end
