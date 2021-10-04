function [matnwbDir] = getMatnwbDir(varargin)

try
    % Get the actual location of the matnwb directory. This assumes "getMatnwbDir" is
    % within the +misc matnwb package folder.
    fnLoc = dbstack('-completenames');
    fnLoc = fnLoc(1).file;
    [fnDir,~,~] = fileparts(fnLoc);
    [matnwbDir,~,~] = fileparts(fnDir);
    
    if 7 ~= exist(matnwbDir, 'dir')
        warning('NWB:GetMatnwbDir:NotFound',...
            'Did not find "matnwb" root directory at %s. Using defaults.',...
            matnwbDir);
    end
catch err
    atLine = repmat('@', 1, 7);
    fprintf('%s\n%s\n%s\n',...
        atLine,...
        getReport(err, 'extended', 'hyperlinks', 'on'),...
        atLine);
end
end