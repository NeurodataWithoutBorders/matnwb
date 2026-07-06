function docsPageFilePath = generateDocsPageForTutorial(sourceFilePath, options)
% generateDocsPageForTutorial - Generate a docs page for a single tutorial source file.
%
% Live script (.mlx) tutorials are exported to markdown and rendered via
% myst-parser: the exported markdown is real CommonMark/GFM, so Sphinx
% parses headings, lists, tables, images and code fences natively, and only
% needs light preprocessing (see preprocessMlxMarkdownForMyst) to strip
% MATLAB's embedded table-of-contents markup and rewrite cross-tutorial
% links. Plain .m tutorials are still converted to reStructuredText, since
% they do not go through the live script export pipeline.

    arguments
        sourceFilePath (1,1) string {mustBeFile}
        options.SourceRepoPath (1,1) string = ""
    end

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    tutorialStaticRootDir = fullfile(docsSourceRootDir, '_static', 'tutorials', 'media');
    tutorialHtmlSourceDir = fullfile(docsSourceRootDir, '_static', 'html', 'tutorials');
    tutorialPageTargetDir = fullfile(docsSourceRootDir, 'pages', 'tutorials');
    if ~isfolder(tutorialPageTargetDir); mkdir(tutorialPageTargetDir); end
    if ~isfolder(tutorialStaticRootDir); mkdir(tutorialStaticRootDir); end

    tutorialConfigFilePath = fullfile(docsSourceRootDir, '_config', 'tutorial_config.json');
    tutorialConfig = jsondecode(fileread(tutorialConfigFilePath));

    [~, tutorialName, sourceExtension] = fileparts(sourceFilePath);
    tutorialName = string(tutorialName);
    sourceExtension = string(sourceExtension);
    isLivescript = sourceExtension == ".mlx";
    templateFormat = "rst";
    if isLivescript
        templateFormat = "md";
    end
    pageTemplate = fileread(getRstTemplateFile('tutorial', 'Format', templateFormat));

    assert(isfield(tutorialConfig.titles, tutorialName), ...
        'generateDocsPageForTutorial:MissingTutorialConfig', ...
        'Could not find tutorial configuration for `%s`.', tutorialName)

    sourceRepoPath = options.SourceRepoPath;
    if sourceRepoPath == ""
        sourceRepoPath = deriveSourceRepoPath(sourceFilePath);
    end

    htmlFilePath = fullfile(tutorialHtmlSourceDir, tutorialName + ".html");
    staticHtmlPath = strrep(htmlFilePath, docsSourceRootDir, '../..');
    title = tutorialConfig.titles.(tutorialName);

    pageOutput = replace(pageTemplate, '{{static_html_path}}', staticHtmlPath);
    pageOutput = replace(pageOutput, '{{tutorial_name}}', tutorialName);
    pageOutput = replace(pageOutput, '{{tutorial_source_path}}', sourceRepoPath);

    if isLivescript
        tutorialBody = convertMlxTutorialToMarkdown(sourceFilePath, tutorialName, htmlFilePath, tutorialStaticRootDir);
    else
        tutorialBody = convertTutorialMCodeToRst(sourceFilePath);
    end

    pageOutput = replace(pageOutput, '{{tutorial_body}}', tutorialBody);

    if isfield(tutorialConfig.youtube, tutorialName)
        youtubeBadge = fileread(getRstTemplateFile('youtube_badge', 'Format', templateFormat));
        youtubeBadge = replace(youtubeBadge, '{{youtube_url}}', tutorialConfig.youtube.(tutorialName));
        title = sprintf('%s 🎬', title);
    else
        youtubeBadge = '';
    end

    pageOutput = replace(pageOutput, '{{youtube_badge_block}}', youtubeBadge);
    pageOutput = replace(pageOutput, '{{tutorial_title}}', title);
    pageOutput = replace(pageOutput, '{{tutorial_title_underline}}', repmat('=', 1, numel(title)));

    outputExtension = "." + templateFormat;
    docsPageFilePath = fullfile(tutorialPageTargetDir, tutorialName + outputExtension);
    filewrite(char(docsPageFilePath), pageOutput)

    if ~nargout
        clear docsPageFilePath
    end
end

function tutorialBody = convertMlxTutorialToMarkdown(sourceFilePath, tutorialName, htmlFilePath, tutorialStaticRootDir)
    tempMarkdownRootDir = fullfile(tempdir, 'matnwbTutorialMarkdown', ...
        char(tutorialName), char(java.util.UUID.randomUUID));
    mkdir(tempMarkdownRootDir);
    cleanupDeleteTempMarkdown = onCleanup(@() safeRemoveDir(tempMarkdownRootDir));

    markdownFilePath = fullfile(tempMarkdownRootDir, tutorialName + ".md");
    export(char(sourceFilePath), char(markdownFilePath), "EmbedImages", false);

    sourceMediaDir = fullfile(tempMarkdownRootDir, tutorialName + "_media");
    targetMediaDir = fullfile(tutorialStaticRootDir, tutorialName);
    if isfolder(sourceMediaDir)
        syncMediaDir(sourceMediaDir, targetMediaDir);
    end

    [imageNames, imageDisplayWidths] = getTutorialImageDisplayWidths(markdownFilePath, htmlFilePath);
    assert(isempty(imageNames) || isfolder(sourceMediaDir), ...
        "generateDocsPageForTutorial:MissingMediaFolder", ...
        "Markdown export for '%s' references %d image(s) but produced no '_media' folder. " + ...
        "This usually means export() embedded images instead of externalizing them " + ...
        "(check the EmbedImages name-value argument).", tutorialName, numel(imageNames))

    mediaRelativePath = "../../_static/tutorials/media/" + tutorialName;
    tutorialBody = preprocessMlxMarkdownForMyst(markdownFilePath, tutorialName, ...
        "MediaRelativePath", mediaRelativePath, ...
        "ImageNames", imageNames, ...
        "ImageDisplayWidths", imageDisplayWidths);
end

function sourceRepoPath = deriveSourceRepoPath(sourceFilePath)
    repoRootDir = misc.getMatnwbDir;
    sourceRepoPath = string(sourceFilePath);
    sourceRepoPath = erase(sourceRepoPath, string(repoRootDir) + filesep);
    sourceRepoPath = replace(sourceRepoPath, filesep, '/');
end

function [imageNames, imageDisplayWidths] = getTutorialImageDisplayWidths(markdownFilePath, htmlFilePath)
    imageNames = string.empty(1, 0);
    imageDisplayWidths = double.empty(1, 0);

    markdownText = fileread(markdownFilePath);
    markdownMatches = regexp(markdownText, '!\[[^\]]*\]\(([^)]+)\)', 'tokens');
    if isempty(markdownMatches)
        return
    end

    imagePaths = strings(numel(markdownMatches), 1);
    for i = 1:numel(markdownMatches)
        imagePaths(i) = string(markdownMatches{i}{1});
    end
    imageNames = cellfun(@extractImageName, cellstr(imagePaths), 'UniformOutput', false);
    imageNames = string(imageNames);

    if ~isfile(htmlFilePath)
        imageDisplayWidths = nan(size(imageNames));
        return
    end

    htmlText = fileread(htmlFilePath);
    widthTokens = regexp(htmlText, '<img class = "imageNode"[^>]*width = "(\d+)"', 'tokens');
    if isempty(widthTokens)
        imageDisplayWidths = nan(size(imageNames));
        return
    end

    htmlWidths = nan(numel(widthTokens), 1);
    for i = 1:numel(widthTokens)
        htmlWidths(i) = str2double(widthTokens{i}{1});
    end

    imageDisplayWidths = nan(size(imageNames));
    numMatches = min(numel(imageNames), numel(htmlWidths));
    imageDisplayWidths(1:numMatches) = htmlWidths(1:numMatches);
end

function imageName = extractImageName(imagePath)
    [~, baseName, extension] = fileparts(imagePath);
    imageName = string(baseName) + string(extension);
end

function syncMediaDir(sourceDir, targetDir)
% syncMediaDir - Copy media files, but only overwrite tracked files whose
% pixel content actually changed. Re-exporting an unchanged figure can
% still produce different bytes (PNG re-encoding, embedded metadata), so
% overwriting unconditionally would create git diff noise on every export
% even when nothing visually changed.
    if ~isfolder(targetDir)
        mkdir(targetDir)
    end

    sourceFiles = dir(sourceDir);
    sourceFiles = sourceFiles(~[sourceFiles.isdir]);
    sourceNames = string({sourceFiles.name});

    for i = 1:numel(sourceFiles)
        sourceFilePath = fullfile(sourceFiles(i).folder, sourceFiles(i).name);
        targetFilePath = fullfile(targetDir, sourceFiles(i).name);
        if ~isfile(targetFilePath) || ~isImageContentEqual(sourceFilePath, targetFilePath)
            copyfile(sourceFilePath, targetFilePath);
        end
    end

    targetFiles = dir(targetDir);
    targetFiles = targetFiles(~[targetFiles.isdir]);
    for i = 1:numel(targetFiles)
        if ~ismember(string(targetFiles(i).name), sourceNames)
            delete(fullfile(targetFiles(i).folder, targetFiles(i).name));
        end
    end
end

function tf = isImageContentEqual(pathA, pathB)
% Byte-identical files are trivially equal. Otherwise decode as images and
% compare pixel data, since re-encoding can change bytes without changing
% the rendered image. Non-image files (or decode failures) are treated as
% changed, so they fall back to a plain overwrite.
    if isequal(readBytes(pathA), readBytes(pathB))
        tf = true;
        return
    end

    try
        [imageA, ~, alphaA] = imread(pathA);
        [imageB, ~, alphaB] = imread(pathB);
        tf = isequal(imageA, imageB) && isequal(alphaA, alphaB);
    catch
        tf = false;
    end
end

function bytes = readBytes(filePath)
    fid = fopen(filePath, 'rb');
    cleanupCloseFile = onCleanup(@() fclose(fid));
    bytes = fread(fid, Inf, 'uint8=>uint8');
end

function safeRemoveDir(folderPath)
    if isfolder(folderPath)
        maybeRemovePath(folderPath)
        rmdir(folderPath, 's');
    end
end

function maybeRemovePath(folderPath)
    pathEntries = string(split(path, pathsep));
    if any(pathEntries == folderPath)
        rmpath(folderPath)
    end
end
