function tests = dataStubTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
generateCore();
end

function testRegionRead(testCase)
date = datetime(2018, 3, 1, 12, 0, 0);
session_start_time = datetime(date,'Format','yyyy-MM-dd''T''HH:mm:SSZZ',...
    'TimeZone','local');
nwb = NwbFile(...
    'session_description', 'a test NWB File', ...
    'identifier', 'mouse004_day4', ...
    'session_start_time', session_start_time);

data = reshape(1:5000, 125, 5, 4, 2);

timeseries = types.core.TimeSeries(...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', 200., ... % Hz
    'data', data,...
    'data_unit','na');

nwb.acquisition.set('data', timeseries);
%%

nwbExport(nwb, 'test_stub_read.nwb');
nwb2 = nwbRead('test_stub_read.nwb');

stub = nwb2.acquisition.get('data').data;

%%
% test subset/missing dimensions
testCase.verifyEqual(stub(2:4, 2:4, 2:4), data(2:4, 2:4, 2:4));

% test Inf
testCase.verifyEqual(stub(2:end, 2:end, 2:end, :), data(2:end, 2:end, 2:end, :));

% test stride
testCase.verifyEqual(stub(1:2:125, 1:2:4, :, :), data(1:2:125, 1:2:4, :, :));

% test flatten
testCase.verifyEqual(stub(1, 1, :), data(1, 1, :));

% test varying selection size
testCase.verifyEqual(stub(:, 1), data(:, 1));
end