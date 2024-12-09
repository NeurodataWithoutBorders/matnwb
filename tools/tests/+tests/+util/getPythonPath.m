function pythonPath = getPythonPath()
    envPath = fullfile('+tests', 'env.mat');
    
    if isfile(fullfile(misc.getMatnwbDir, envPath))
        Env = load(envPath, '-mat');
        if isfield(Env, 'pythonPath')
            pythonPath = Env.pythonPath;
        else
            pythonPath = fullfile(Env.pythonDir, 'python');
        end
    else
        pythonPath = 'python';
    end
end
