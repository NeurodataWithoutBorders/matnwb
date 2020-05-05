%% Neurodata Without Borders: Neurophysiology (NWB:N), Compression using DataPipe
% How to utilize HDF5 compression using dataPipe
%
%  author: Ivan Smalianchuk
%  contact: smalianchuk.ivan@gmail.com
%  last edited: May 05, 2020
%%
% This tutorial will demonstate how to use DataPipe to compress data for
% storage in a NWB file.
%% Basic Implementation
% To compress experimental data (in this case a three dimensional matrix
% with the following dimensions [250 250 70]) one must assign it as a DataPipe type:
DataToCompress = randi(100,250,250,70);
maxSize = size(DataToCompress);
DataPipe=types.untyped.DataPipe(maxSize,...
    'data', DataToCompress,...
    'axis', 1);

%%
% To optimize compression, compressionLevel and chunkSize must be considered.
% compressionLevel ranges from 0 - 9 where 9 is the highest level of
% compression and 0 is the lowest. chunkSize is less intuitive to adjust;
% to implement compression, chunk size must be less than data size. The above
% example uses default chunk size and compression level.
%% Arguments
%
% <html>
% <table border=1>
% <tr><td><em>Data</em></td><td>The data to compress. Must be numerical data. This is a required argument.</td></tr>
% <tr><td><em>axis</em></td><td>Set which axis to increment when appending more data. This is a required argument.</td></tr>
% <tr><td><em>dataType</em></td><td>Sets the type of the experimental data. This must be a numeric data type. Useful to include when using iterative write to append data; as the appended data must be the same data type.</td></tr>
% <tr><td><em>chunkSize</em></td><td>Sets chunk size for the compression. Must be less than maxSize for any compression level >0. More on chunk size below. (link to section)</td></tr>
% <tr><td><em>compressionLevel</em></td><td>Level of compression ranging from 0-9 where 9 is the highest level of compression. Matlab usually uses compression level 3.</td></tr>
% <tr><td><em>maxSize</em></td><td>This sets the size of the compressed matrix. Unless using iterative writing, this should match the size of Data. To append data later, use the maxSize for the full dataset.</td></tr>
% <tr><td><em>offset</em></td><td>Axis offset of dataset to append. May be used to overwrite data.</td></tr></table>
% </html>
%% Iterative Writing
% If experimental data is close to, or exceeds the available system memory,
% performance issues may arise. To combat this effect of large data,
% dataPipe can utilize iterative writing, where only a portion of the data
% is first compressed and saved, and then additional portions are appended.
%
% To demonstrate, we can create a nwb file with a compressed time series data:
%%

dataPart1=randi(250,10000,1); % "load" 1/4 of the entire dataset
fullDataSize=[40000 1]; % this is the size of the TOTAL dataset

% create an nwb structure with required fields
nwb=NwbFile(...
    'session_start_time','2020-01-01 00:00:00',...
    'identifier','ident1',...
    'session_description','DataPipeTutorial');

ephys_module = types.core.ProcessingModule(...
    'description', 'holds processed ephys data');

nwb.processing.set('ephys', ephys_module);

% compress the data
fData_use=types.untyped.DataPipe(fullDataSize,...
    'data', dataPart1,...
    'axis', 1);

%Set the compressed data as a time series
fdataNWB=types.core.TimeSeries(...
    'data', fData_use,...
    'data_unit','mV');

ephys_module.nwbdatainterface.set('data', fdataNWB);
nwb.processing.set('ephys', ephys_module);

nwbExport(nwb, 'DataPipeTutorial_iterate.nwb');
%%
% To append the rest of the data, simply load the NWB file and use the
% append method:

nwb=nwbRead('DataPipeTutorial_iterate.nwb'); %load the nwb file with partial data

% "load" each of the remaining 1/4ths of the large dataset
for i=2:4 % iterating through parts of data
    dataPart_i=randi(250,10000,1); % faked data chunk as if it was loaded
    nwb.processing.get('ephys').nwbdatainterface.get('data').data.append(dataPart_i) % append the loaded data
end
%%
% The axis property defines the dimension in which additional data will be
% appended. In the above example, the resulting dataset will be 4000x1.
% However, if we set axis to 2 (and change fullDataSize appropriately),
% then the resulting dataset will be 1000x4.
%
%% Chunking
% If chunkSize is not explicitly specified, dataPipe will determine an
% appropriate chunk size. However, you can optimize the performance of the
% compression by manually specifying the chunk size using _chunkSize_ argument.
%
% We can demonstrate the benefit of chunking by exploring the following
% scenario. The following code utilizes dataPipe’s default chunk size:
%

fData=randi(250,1000,1000); % Create fake data

% create an nwb structure with required fields
nwb=NwbFile(...
    'session_start_time','2020-01-01 00:00:00',...
    'identifier','ident1',...
    'session_description','DataPipeTutorial');

ephys_module = types.core.ProcessingModule(...
    'description', 'holds processed ephys data');

nwb.processing.set('ephys', ephys_module);

fData_compressed=types.untyped.DataPipe(size(fData),...
    'data', fData,...
    'axis', 1);

fdataNWB=types.core.TimeSeries(...
    'data', fData_compressed,...
    'data_unit','mV');

ephys_module.nwbdatainterface.set('data', fdataNWB);
nwb.processing.set('ephys', ephys_module);

nwbExport(nwb, 'DefaultChunks.nwb');
%%
% This results in a file size of 47MB (too large), but the process takes
% 11 seconds (far too long).Setting the chunk size manually as in the
% example code below resolves these issues:

fData_compressed=types.untyped.DataPipe(size(fData),...
    'data', fData,...
    'chunkSize', [1,1000],...
    'axis', 1);
%%
% This change results in the operation completing in 0.7 seconds and
% resulting file size of 1.1MB. The chunk size was chosen such that it
% spans each individual row of the set; however, the performance will
% increase for any value such that ‘size(fData)’ is a multiple of chunk size.
%
%% Examples
%% Calcium imaging data
% Following is an example of how to compress and add calcium imaging data
% to an NWB file:
%

fData=randi(250,250,10000); % create fake data; for example ROI response series
n_rois=250;

%create an nwb structure with required fields
nwb=NwbFile(...
    'session_start_time','2020-01-01 00:00:00',...
    'identifier','ident1',...
    'session_description','DataPipeTutorial');

%start and set an ophys module to work with your data
ophys_module = types.core.ProcessingModule(...
    'description', 'holds processed imaging data');
nwb.processing.set('ophys', ophys_module);

%Set appropriate parameters for your RoiResponseSeries data
fluorescence = types.core.Fluorescence();

object_view = types.untyped.ObjectView( ...
    '/processing/ophys/fluorescence/exampleData');

roi_table_region = types.hdmf_common.DynamicTableRegion( ...
    'description', 'all_rois', ...
    'table',plane_seg_object_view,...
    'data', [0 n_rois-1]');

% Compress the data:
fData_compressed=types.untyped.DataPipe(size(fData),...
    'data', fData,...
    'dataType', 'uint8',...
    'compressionLevel', 3,...
    'chunkSize', [10 250],...
    'axis', 1);

% Assign your fake data
roi_fData=types.core.RoiResponseSeries(...
    'data',fData_compressed,...
    'description','test',...
    'data_unit', 'lumens',...
    'rois',roi_table_region);

fluorescence.roiresponseseries.set('exampleData',roi_fData);   ophys_module.nwbdatainterface.set('fluorescence', fluorescence); %set to the appropriate place in nwb structure

%assign the whole thing to the nwb structure
nwb.processing.set('ophys', ophys_module);

%write the file
nwbExport(nwb, 'Compressed.nwb');

%% Electrophysiology timeseries
% Following is an example of how to compress and add calcium imaging data
% to an NWB file:

fData=randi(250,10000,1); % create fake data;

%assign data without compression
nwb=NwbFile(...
    'session_start_time','2020-01-01 00:00:00',...
    'identifier','ident1',...
    'session_description','DataPipeTutorial');

ephys_module = types.core.ProcessingModule(...
    'description', 'holds processed ephys data');

nwb.processing.set('ephys', ephys_module);

% compress the data
fData_compressed=types.untyped.DataPipe(size(fData),...
    'data', fData,...
    'dataType', 'uint8',...
    'compressionLevel', 3,...
    'chunkSize', [100 1],...
    'axis', 1);

% Assign the data to appropriate module and write the NWB file
fdataNWB=types.core.TimeSeries(...
    'data', fData_compressed,...
    'data_unit','mV');

ephys_module.nwbdatainterface.set('data', fdataNWB);
nwb.processing.set('ephys', ephys_module);

%write the file
nwbExport(nwb, 'Compressed.nwb');