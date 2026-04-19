function generateRstForTutorials(options)
% generateRstForTutorials - Generate rst files for tutorial pages

    arguments
        options.FileNames (1,:) string = string.empty
    end

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    tutorialStaticRootDir = fullfile(docsSourceRootDir, '_static', 'tutorials', 'media');
    tutorialHtmlSourceDir = fullfile(docsSourceRootDir, '_static', 'html', 'tutorials');
    tutorialRstTargetDir = fullfile(docsSourceRootDir, 'pages', 'tutorials');
    legacyTutorialStaticRootDir = fullfile(docsSourceRootDir, '_static', 'markdown');
    if ~isfolder(tutorialRstTargetDir); mkdir(tutorialRstTargetDir); end
    if ~isfolder(tutorialStaticRootDir); mkdir(tutorialStaticRootDir); end
    
    tutorialConfigFilePath = fullfile(docsSourceRootDir, '_config', 'tutorial_config.json');
    S = jsondecode(fileread(tutorialConfigFilePath));

    rstTemplate = fileread( getRstTemplateFile('tutorial') );
    tempMarkdownRootDir = fullfile(tempdir, 'matnwbTutorialMarkdown');
    safeRemoveDir(tempMarkdownRootDir)
    mkdir(tempMarkdownRootDir);
    cleanupDeleteTempMarkdown = onCleanup(@() safeRemoveDir(tempMarkdownRootDir)); %#ok<NASGU>

    tutorialNames = string(fieldnames(S.titles));
    tutorialNames = sort(tutorialNames);

    if ~isempty(options.FileNames)
        tutorialNames = intersect(tutorialNames, options.FileNames, 'stable');
    end

    for i = 1:numel(tutorialNames)
        name = tutorialNames(i);
        [sourceFilePath, sourceRepoPath] = resolveTutorialSource(name);
        if sourceFilePath == ""
            warning('Could not find a tutorial source file for "%s"', name)
            continue
        end

        htmlFilePath = fullfile(tutorialHtmlSourceDir, name + ".html");
        relPath = strrep(htmlFilePath, docsSourceRootDir, '../..');
        title = S.titles.(name);
    
        rstOutput = replace(rstTemplate, '{{static_html_path}}', relPath);
        rstOutput = replace(rstOutput, '{{tutorial_name}}', name);
        rstOutput = replace(rstOutput, '{{tutorial_source_path}}', sourceRepoPath);

        [~, ~, sourceExtension] = fileparts(sourceFilePath);
        if sourceExtension == ".mlx"
            markdownFilePath = fullfile(tempMarkdownRootDir, name + ".md");
            export(char(sourceFilePath), char(markdownFilePath));

            sourceMediaDir = fullfile(tempMarkdownRootDir, name + "_media");
            targetMediaDir = fullfile(tutorialStaticRootDir, name);
            safeRemoveDir(targetMediaDir)
            if isfolder(sourceMediaDir)
                copyfile(sourceMediaDir, targetMediaDir);
            end

            [imageNames, imageDisplayWidths] = getTutorialImageDisplayWidths( ...
                markdownFilePath, htmlFilePath );
            mediaRelativePath = "../../_static/tutorials/media/" + name;
            tutorialBody = convertTutorialMarkdownToRst(markdownFilePath, ...
                "MediaRelativePath", mediaRelativePath, ...
                "ImageNames", imageNames, ...
                "ImageDisplayWidths", imageDisplayWidths);
        else
            tutorialBody = convertTutorialMCodeToRst(sourceFilePath);
        end

        rstOutput = replace(rstOutput, '{{tutorial_body}}', tutorialBody);

        % Add the youtube badge block if the tutorial has a corresponding youtube video
        if isfield(S.youtube, name)
            youtubeBadge = fileread( getRstTemplateFile('youtube_badge') );
            youtubeBadge = replace(youtubeBadge, '{{youtube_url}}', S.youtube.(name));
            title = sprintf('%s 🎬', title); % Add emoji in the title if there is a video
        else
            youtubeBadge = '';
        end
        rstOutput = replace(rstOutput, '{{youtube_badge_block}}', youtubeBadge);
        rstOutput = replace(rstOutput, '{{tutorial_title}}', title);
        rstOutput = replace(rstOutput, '{{tutorial_title_underline}}', repmat('=', 1, numel(title)));
        rstOutputFile = fullfile(tutorialRstTargetDir, name + ".rst");
        filewrite(char(rstOutputFile), rstOutput)
    end

    % Create index
    indexTemplate = fileread( getRstTemplateFile('index_tutorials') );
    data.file_list = strjoin("   "+tutorialNames, newline);
    
    thisRst = fillTemplate(indexTemplate, data);
    rstFilePath = fullfile(tutorialRstTargetDir, ['index', '.rst']);

    % Commented out because currently this index file is edited manually.
    %filewrite(rstFilePath, thisRst);

    safeRemoveDir(legacyTutorialStaticRootDir)
end

function [sourceFilePath, sourceRepoPath] = resolveTutorialSource(tutorialName)
    tutorialRootDir = fullfile(misc.getMatnwbDir, 'tutorials');
    candidateFilePaths = [ ...
        fullfile(tutorialRootDir, tutorialName + ".mlx")
        fullfile(tutorialRootDir, tutorialName + ".m")
        fullfile(tutorialRootDir, 'private', 'mcode', tutorialName + ".m")
    ];
    candidateRepoPaths = [ ...
        fullfile('tutorials', tutorialName + ".mlx")
        fullfile('tutorials', tutorialName + ".m")
        fullfile('tutorials', tutorialName + ".mlx")
    ];

    sourceFilePath = "";
    sourceRepoPath = "";

    for i = 1:numel(candidateFilePaths)
        if isfile(candidateFilePaths(i))
            sourceFilePath = candidateFilePaths(i);
            sourceRepoPath = strrep(candidateRepoPaths(i), filesep, '/');
            return
        end
    end
end

function maybeRemovePath(folderPath)
    pathEntries = string(split(path, pathsep));
    if any(pathEntries == folderPath)
        rmpath(folderPath)
    end
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
