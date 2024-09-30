function matnwbDir = getMatnwbDir(varargin)
% Get the absolute path for the matnwb directory.
     
    % This assumes "getMatnwbDir" is within the +misc matnwb package folder.
    miscFolder = fileparts(mfilename('fullpath'));
    matnwbDir = fileparts(miscFolder);
end