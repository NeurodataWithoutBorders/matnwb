%% Reading NWB Data in MATLAB (DandiHub edition)
% Authors: Ryan Ly, with modification by Lawrence Niu
% 
% DandiHub edition* authors: Thomas Kuenzel & Vijay Iyer
% 
% Last Updated: 2023-09-05
% 
% (*) minimally modified to utilize |dandi| package for download and to skip 
% the MatNWB installation 
%% Introduction
% In this tutorial, we will read single neuron spiking data that is in the NWB 
% standard format and do a basic visualization of the data. More thorough documentation 
% regarding reading files as well as the |NwbFile| class, can be found in the 
% <https://nwb-overview.readthedocs.io/en/latest/file_read/file_read.html#reading-with-matnwb 
% NWB Overview Documentation>
%% Download the Dataset
% Use the pre-installed |dandi| Python package to download the dataset to the 
% user-local dandisets folder:

environment = "Local";
switch environment
    case "DandiHub"
        targetFolder = "/home/jovyan/dandisets/000004";
    case "Local"
        targetFolder = fullfile(userpath(), "dandisets", "000004");
end
py.dandi.download.download("dandi://dandi/000004/sub-P11HMH/", targetFolder, existing='overwrite')
%% Read the NWB file
% You can read any NWB file using |nwbRead|. You will find that the print out 
% for this shows a summary of the data within.

nwb = nwbRead(fullfile(targetFolder, "sub-P11HMH", "sub-P11HMH_ses-20061101_ecephys+image.nwb"))
% Stimulus
% Now lets take a look at the visual stimuli presented to the subject. They 
% will be in |nwb.stimulus_presentation|

nwb.stimulus_presentation
%% 
% This results shows us that |nwb.stimulus_presentation| is a |Set| object that 
% contains a single data object called |StimulusPresentation|, which is an |OpticalSeries| 
% neurodata type. Use the |get| method to return this |OpticalSeries|. |Set| objects 
% store a collection of other NWB objects.

nwb.stimulus_presentation.get('StimulusPresentation')
%% 
% |OpticalSeries| is a neurodata type that stores information about visual stimuli 
% presented to subjects. This print out shows all of the attributes in the |OpticalSeries| 
% object named |StimulusPresentation|. The images are stored in |StimulusPresentation.data|

StimulusImageData = nwb.stimulus_presentation.get('StimulusPresentation').data
%% 
% When calling a data object directly, the data is not read but instead a |DataStub| 
% is returned. This is because data is read "lazily" in MatNWB. Instead of reading 
% the entire dataset into memory, this provides a "window" into the data stored 
% on disk that allows you to read only a section of the data. In this case, the 
% last dimension indexes over images. You can index into any |DataStub| as you 
% would any MATLAB matrix.

% get the image and display it
% the dimension order is provided as follows:
% [rgb, y, x, image index]
img = StimulusImageData(1:3, 1:300, 1:400, 32);
%% 
% A bit of manipulation allows us to display the image using MATLAB's |imshow|.

img = permute(img,[3, 2, 1]);  % fix orientation
img = flip(img, 3); % reverse color order
F = figure();
imshow(img, 'InitialMagnification', 'fit');
daspect([3, 5, 5]);
%% 
% To read an entire dataset, use the |DataStub.load| method without any input 
% arguments. We will use this approach to read all of the image display timestamps 
% into memory.

stimulus_times = nwb.stimulus_presentation.get('StimulusPresentation').timestamps.load();
%% Quick PSTH and raster
% Here, I will pull out spike times of a particular unit, align them to the 
% image display times, and finally display the results.
% 
% First, let us show the first row of the NWB Units table representing the first 
% unit.

nwb.units.getRow(1)
%% 
% Let us specify some parameters for creating a cell array of spike times aligned 
% to each stimulus time. 

%% Align spikes by stimulus presentations

unit_ind =8;
before =1;
after =3;
%% 
% |getRow| provides a convenient method for reading this data out.

unit_spikes = nwb.units.getRow(unit_ind, 'columns', {'spike_times'}).spike_times{1}
%% 
% Spike times from this unit are aligned to each stimulus time and compiled 
% in a cell array

results = cell(1, length(stimulus_times));
for itime = 1:length(stimulus_times)
    stimulus_time = stimulus_times(itime);
    spikes = unit_spikes - stimulus_time;
    spikes = spikes(spikes > -before);
    spikes = spikes(spikes < after);
    results{itime} = spikes;
end
%% Plot results
% Finally, here is a (slightly sloppy) peri-stimulus time histogram

figure();
hold on
for i = 1:length(results)
    spikes = results{i};
    yy = ones(length(spikes)) * i;

    plot(spikes, yy, 'k.');
end
hold off
ylabel('trial');
xlabel('time (s)');
axis('tight')
%%
figure();
all_spikes = cat(1, results{:});
histogram(all_spikes, 30);
ylabel('count')
xlabel('time (s)');
axis('tight')
%% Conclusion
% This is an example of how to get started with understanding and analyzing 
% public NWB datasets. This particular dataset was published with an extensive 
% open analysis conducted in both MATLAB and Python, which you can find <https://github.com/rutishauserlab/recogmem-release-NWB 
% here>. For more datasets, or to publish your own NWB data for free, check out 
% the DANDI archive <http://dandiarchive.org/ here>. 
% 
%