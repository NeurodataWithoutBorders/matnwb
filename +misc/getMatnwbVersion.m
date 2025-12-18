function matnwbVersion = getMatnwbVersion()
% getMatnwbVersion - Get current version of MatNWB
    
    % Find name of MatNWB folder.
    [~, matnwbFolderName] = fileparts( misc.getMatnwbDir() );
    matnwbInfo = ver(matnwbFolderName);

    matnwbVersion = matnwbInfo.Version;
end
