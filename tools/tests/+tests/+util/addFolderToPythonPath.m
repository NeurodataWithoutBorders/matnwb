function addFolderToPythonPath(folderPath)
    pythonPath = getenv('PYTHONPATH');
    if isempty(pythonPath)
        updatedPythonPath = folderPath;
    else
        if ~contains(pythonPath, folderPath)
            updatedPythonPath = strjoin({pythonPath, folderPath}, pathsep);
        else
            return
        end
    end
    setenv('PYTHONPATH', updatedPythonPath);
end
