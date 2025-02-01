function pythonPath = getPythonPath()
    envPath = fullfile(misc.getMatnwbDir, '+tests', 'env.mat');
    
    try
        S = pyenv();
        pythonPath = S.Executable;
    catch
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
end
