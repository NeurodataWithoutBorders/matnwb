function nwbFilePath = getTutorialNwbFilePath(filename, options)
% getTutorialNwbFilePath - Get a filepath to save a tutorial nwb file.
%
%   nwbFilePath = getTutorialNwbFilePath(filename) creates an absolute
%   filepath to save a tutorial nwb file given a filename. 
%   The file is saved in <matnwb_root>/tutorials/tutorial_nwb_files

    arguments
        filename char
        options.ExportLocation (1,1) string ...
            {mustBeMember(options.ExportLocation, ["default", "workdir"])} = "default"
    end

    % Check if function is called from testing framework. If yes, ensure
    % file is saved to the current working directory.
    callingStackTrace = dbstack();
    if numel(callingStackTrace) >= 4 && ...
            strcmp(callingStackTrace(4).name, 'TutorialTest.testTutorial')
        options.ExportLocation = "workdir";
    end
    
    if options.ExportLocation == "default"
        saveFolder = fullfile(misc.getMatnwbDir, 'tutorials', 'tutorial_nwb_files');
    elseif options.ExportLocation == "workdir"
        saveFolder = pwd;
    end

    if ~isfolder(saveFolder); mkdir(saveFolder); end

    if ~endsWith(filename, '.nwb')
        filename = [filename, '.nwb'];
    end

    nwbFilePath = fullfile(saveFolder, filename);
end
