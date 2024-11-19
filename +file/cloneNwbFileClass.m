function cloneNwbFileClass(typeFileName, fullTypeName)
%CLONENWBFILE Certain extensions can override the base NWBFile.  This cannot
% be dynamically adjusted as inheritance is generally static in MATLAB.
% So we go through path of least resistance and clone NwbFile.m

nwbFilePath = which('NwbFile');
installPath = fileparts(nwbFilePath);
nwbFileClassDef = fileread(nwbFilePath);

% Update superclass name
updatedNwbFileClassDef = strrep(nwbFileClassDef, ...
    'NwbFile < types.core.NWBFile', ...
    sprintf('NwbFile < %s', fullTypeName));

% Update call to superclass constructor
updatedNwbFileClassDef = strrep(updatedNwbFileClassDef, ...
    'obj = obj@types.core.NWBFile', ...
    sprintf('obj = obj@%s', fullTypeName));

fileId = fopen(fullfile(installPath, [typeFileName '.m']), 'W');
fwrite(fileId, updatedNwbFileClassDef);
fclose(fileId);

rehash();
end
