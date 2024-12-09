function generateRstForTutorials()
% generateRstForTutorials - Generate rst files for all the tutorial HTML files

    docsSourceRootDir = fullfile(misc.getMatnwbDir, 'docs', 'source');
    
    tutorialHtmlSourceDir = fullfile(docsSourceRootDir, '_static', 'html', 'tutorials');
    tutorialRstTargetDir = fullfile(docsSourceRootDir, 'pages', 'tutorials');
    if ~isfolder(tutorialRstTargetDir); mkdir(tutorialRstTargetDir); end
    
    tutorialConfigFilePath = fullfile(docsSourceRootDir, '_config', 'tutorial_config.json');
    S = jsondecode(fileread(tutorialConfigFilePath));

    rstTemplate = fileread( getRstTemplateFile('tutorial') );

    % List all html files in source dir
    L = dir(fullfile(tutorialHtmlSourceDir, '*.html'));
    
    for i = 1:numel(L)
        thisFilePath = fullfile(L(i).folder, L(i).name);
        relPath = strrep(thisFilePath, docsSourceRootDir, '../..');
    
        [~, name] = fileparts(relPath);
        title = S.titles.(name);
    
        rstOutput = replace(rstTemplate, '{{static_html_path}}', relPath);
        rstOutput = replace(rstOutput, '{{tutorial_name}}', name);
        rstOutput = replace(rstOutput, '{{tutorial_title}}', title);
        rstOutput = replace(rstOutput, '{{tutorial_title_underline}}', repmat('=', 1, numel(title)));

        % Add the youtube badge block if the tutorial has a corresponding youtube video
        if isfield(S.youtube, name)
            youtubeBadge = fileread( getRstTemplateFile('youtube_badge') );
            youtubeBadge = replace(youtubeBadge, '{{youtube_url}}', S.youtube.(name));
        else
            youtubeBadge = '';
        end
        rstOutput = replace(rstOutput, '{{youtube_badge_block}}', youtubeBadge);
        
        rstOutputFile = fullfile(tutorialRstTargetDir, [name, '.rst']);
        fid = fopen(rstOutputFile, 'wt');
        fwrite(fid, rstOutput);
        fclose(fid);
    end

    % Create index
    indexTemplate = fileread( getRstTemplateFile('index_tutorials') );
    [~, fileNames] = fileparts(string({L.name}));
    data.file_list = strjoin("   "+fileNames, newline);
    
    thisRst = fillTemplate(indexTemplate, data);
    rstFilePath = fullfile(tutorialRstTargetDir, ['index', '.rst']);
    %filewrite(rstFilePath, thisRst);
end