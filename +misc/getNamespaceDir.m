function [namespaceDir] = getNamespaceDir(varargin)
    % Get the location of the namespaces directory regardless of current MATLAB working directory.
    % started: 2020.07.02 [11:20:30]
    % inputs
        %
    % outputs
        %

    % changelog
        % 2020.07.02 [11:24:10] - Function created and added warning if namespaces directory could not be found. - Biafra Ahanonu.
    % TODO
        %

    try
       % Get the actual location of the matnwb directory.
       fnDir = misc.getMatnwbDir();

       % Get full path name to namespaces directory and list of files
       namespaceDir = fullfile(fnDir, 'namespaces');

       % Check directory exists else throw a warning letting the user know.
       dirExists = subfxnDirCheck(namespaceDir,1);
       if dirExists==0
            namespaceDir = subfxnDefaultNamespaces();
        elseif dirExists==1
            % Do nothing.
        end
    catch err
        % Attempt to load namespaces directory using prior methods.
        namespaceDir = subfxnDefaultNamespaces();
        disp(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        disp(repmat('@',1,7))
    end
end
function dirExists = subfxnDirCheck(namespaceDir,dispWarning)
   if exist(namespaceDir,'dir')==7
        dirExists = 1;
        fprintf('Found "namespaces" directory at: %s.\n',namespaceDir);
   else
        dirExists = 0;
        if dispWarning==1
            warning('Directory "namespaces" not found at %s. Using defaults.',namespaceDir)
        end
   end
end
function namespaceDir = subfxnDefaultNamespaces()
    try
        namespaceDir = fullfile(misc.getWorkspace(), 'namespaces');
        dirExists = subfxnDirCheck(namespaceDir,0);
        if dirExists==0
            namespaceDir = 'namespaces';
            subfxnDirCheck(namespaceDir,0);
        end
    catch
        namespaceDir = 'namespaces';
        subfxnDirCheck(namespaceDir,0);
    end
end