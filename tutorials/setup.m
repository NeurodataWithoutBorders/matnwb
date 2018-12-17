%% Installing matnwb
% To get matnwb on your computer, clone it with the terminal command
% |git clone https://github.com/NeurodataWithoutBorders/matnwb.git|
% You can run this directly from the MATLAB prompt by preceding with a |!|:
!git clone https://github.com/NeurodataWithoutBorders/matnwb.git
% Then add matnwb to your path
addpath(genpath(matnwb));
% You can make this a permanent change by adding the above line to your
% |startup.m| file. You can edit this file with 
edit startup
%% Setting up matnwb
% matnwb dynamically builds MATLAB(R) classes corresponding to the nwb-schema
% and any extensions you will be using. You will need to generate these
% classes once during setup and then again every time you update matnwb or
% the nwb-schema. To generate the core schema, run
