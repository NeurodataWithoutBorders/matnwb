function rstOutputFilePath = generateRstForTutorial(sourceFilePath, options)
% generateRstForTutorial - Generate rst for a single tutorial source file.

    arguments
        sourceFilePath (1,1) string {mustBeFile}
        options.SourceRepoPath (1,1) string = ""
    end

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    tutorialStaticRootDir = fullfile(docsSourceRootDir, '_static', 'tutorials', 'media');
    tutorialHtmlSourceDir = fullfile(docsSourceRootDir, '_static', 'html', 'tutorials');
    tutorialRstTargetDir = fullfile(docsSourceRootDir, 'pages', 'tutorials');
    if ~isfolder(tutorialRstTargetDir); mkdir(tutorialRstTargetDir); end
    if ~isfolder(tutorialStaticRootDir); mkdir(tutorialStaticRootDir); end

    tutorialConfigFilePath = fullfile(docsSourceRootDir, '_config', 'tutorial_config.json');
    tutorialConfig = jsondecode(fileread(tutorialConfigFilePath));
    rstTemplate = fileread(getRstTemplateFile('tutorial'));

    [~, tutorialName, sourceExtension] = fileparts(sourceFilePath);
    tutorialName = string(tutorialName);

    assert(isfield(tutorialConfig.titles, tutorialName), ...
        'generateRstForTutorial:MissingTutorialConfig', ...
        'Could not find tutorial configuration for `%s`.', tutorialName)

    sourceRepoPath = options.SourceRepoPath;
    if sourceRepoPath == ""
        sourceRepoPath = deriveSourceRepoPath(sourceFilePath);
    end

    htmlFilePath = fullfile(tutorialHtmlSourceDir, tutorialName + ".html");
    staticHtmlPath = strrep(htmlFilePath, docsSourceRootDir, '../..');
    title = tutorialConfig.titles.(tutorialName);

    rstOutput = replace(rstTemplate, '{{static_html_path}}', staticHtmlPath);
    rstOutput = replace(rstOutput, '{{tutorial_name}}', tutorialName);
    rstOutput = replace(rstOutput, '{{tutorial_source_path}}', sourceRepoPath);

    if string(sourceExtension) == ".mlx"
        tutorialBody = convertMlxTutorialToRst(sourceFilePath, tutorialName, htmlFilePath, tutorialStaticRootDir);
    else
        tutorialBody = convertTutorialMCodeToRst(sourceFilePath);
    end

    rstOutput = replace(rstOutput, '{{tutorial_body}}', tutorialBody);

    if isfield(tutorialConfig.youtube, tutorialName)
        youtubeBadge = fileread(getRstTemplateFile('youtube_badge'));
        youtubeBadge = replace(youtubeBadge, '{{youtube_url}}', tutorialConfig.youtube.(tutorialName));
        title = sprintf('%s 🎬', title);
    else
        youtubeBadge = '';
    end

    rstOutput = replace(rstOutput, '{{youtube_badge_block}}', youtubeBadge);
    rstOutput = replace(rstOutput, '{{tutorial_title}}', title);
    rstOutput = replace(rstOutput, '{{tutorial_title_underline}}', repmat('=', 1, numel(title)));

    rstOutputFilePath = fullfile(tutorialRstTargetDir, tutorialName + ".rst");
    filewrite(char(rstOutputFilePath), rstOutput)

    if ~nargout
        clear rstOutputFilePath
    end
end

function tutorialBody = convertMlxTutorialToRst(sourceFilePath, tutorialName, htmlFilePath, tutorialStaticRootDir)
    tempMarkdownRootDir = fullfile(tempdir, 'matnwbTutorialMarkdown', ...
        char(tutorialName), char(java.util.UUID.randomUUID));
    mkdir(tempMarkdownRootDir);
    cleanupDeleteTempMarkdown = onCleanup(@() safeRemoveDir(tempMarkdownRootDir));

    markdownFilePath = fullfile(tempMarkdownRootDir, tutorialName + ".md");
    export(char(sourceFilePath), char(markdownFilePath));

    sourceMediaDir = fullfile(tempMarkdownRootDir, tutorialName + "_media");
    targetMediaDir = fullfile(tutorialStaticRootDir, tutorialName);
    safeRemoveDir(targetMediaDir)
    if isfolder(sourceMediaDir)
        copyfile(sourceMediaDir, targetMediaDir);
    end

    [imageNames, imageDisplayWidths] = getTutorialImageDisplayWidths(markdownFilePath, htmlFilePath);
    mediaRelativePath = "../../_static/tutorials/media/" + tutorialName;
    tutorialBody = convertTutorialMarkdownToRst(markdownFilePath, ...
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
