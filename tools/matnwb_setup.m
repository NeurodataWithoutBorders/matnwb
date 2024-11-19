% This setup script is meant for developers of the matnwb project
%
%   Install git hooks
%   Download developer dependencies

currentFolder = fileparts(mfilename('fullpath'));
addpath(genpath(currentFolder))

matnwb_installGitHooks()

matnwb_installm2html(fileparts(currentFolder))
