function generateRstForTutorials(options)
% generateRstForTutorials - Generate rst files for tutorial pages.

    arguments
        options.FileNames (1,:) string = string.empty
    end

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    tempMarkdownExportDir = fullfile(docsSourceRootDir, '_static', 'markdown');

    tutorialConfigFilePath = fullfile(docsSourceRootDir, '_config', 'tutorial_config.json');
    tutorialConfig = jsondecode(fileread(tutorialConfigFilePath));

    tutorialNames = string(fieldnames(tutorialConfig.titles));
    tutorialNames = sort(tutorialNames);

    if ~isempty(options.FileNames)
        tutorialNames = intersect(tutorialNames, options.FileNames, 'stable');
    end

    for i = 1:numel(tutorialNames)
        tutorialName = tutorialNames(i);
        [sourceFilePath, sourceRepoPath] = resolveTutorialSource(tutorialName);
        if sourceFilePath == ""
            warning('Could not find a tutorial source file for "%s"', tutorialName)
            continue
        end

        generateRstForTutorial(sourceFilePath, ...
            "SourceRepoPath", sourceRepoPath);
    end

    indexTemplate = fileread(getRstTemplateFile('index_tutorials'));
    data.file_list = strjoin("   " + tutorialNames, newline);

    thisRst = fillTemplate(indexTemplate, data); %#ok<NASGU>
    rstFilePath = fullfile(docsSourceRootDir, 'pages', 'tutorials', ['index', '.rst']); %#ok<NASGU>

    % Commented out because currently this index file is edited manually.
    %filewrite(rstFilePath, thisRst);

    safeRemoveDir(tempMarkdownExportDir)
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

function safeRemoveDir(folderPath)
    if isfolder(folderPath)
        rmdir(folderPath, 's');
    end
end
