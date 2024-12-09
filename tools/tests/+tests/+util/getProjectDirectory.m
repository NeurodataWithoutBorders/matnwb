function projectDirectory = getProjectDirectory()
    projectDirectory = fullfile(fileparts(mfilename('fullpath')), '..', '..');
end
