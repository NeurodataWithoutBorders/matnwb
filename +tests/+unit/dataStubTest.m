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

data = reshape(1:5000, 25, 5, 4, 2, 5);

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
testCase.verifyEqual(stub(1:2:25, 1:2:4, :, :), data(1:2:25, 1:2:4, :, :));

% test flatten
testCase.verifyEqual(stub(1, 1, :), data(1, 1, :));

% test non-dangling `:`
testCase.verifyEqual(stub(:, 1), data(:, 1));

% test arbitrary indices
primeInd = primes(25);
testCase.verifyEqual(stub(primeInd), data(primeInd));
testCase.verifyEqual(stub(primeInd, 2:4, :), data(primeInd, 2:4, :));
testCase.verifyEqual(stub(primeInd, :, 1), data(primeInd, :, 1));
testCase.verifyEqual(stub(primeInd, [1 2 5]), data(primeInd, [1 2 5]));
testCase.verifyEqual(stub([1 25], [1 5], [1 4], [1 2], [1 5]), data([1 25], [1 5], [1 4], [1 2], [1 5]));

% test duplicate indices
testCase.verifyEqual(stub([1 1 1 1]), data([1 1 1 1]));

% test out of order indices
testCase.verifyEqual(stub([5 4 3 2 2]), data([5 4 3 2 2]));
end

function testObjectCopy(testCase)
unitTestLocation = fullfile(misc.getMatnwbDir(), '+tests', '+unit');
generateExtension(fullfile(unitTestLocation, 'regionReferenceSchema', 'rrs.namespace.yaml'));
generateExtension(fullfile(unitTestLocation, 'compoundSchema', 'cs.namespace.yaml'));
rehash();
nwb = NwbFile(...
    'identifier', 'DATASTUB',...
    'session_description', 'test datastub object copy',...
    'session_start_time', datetime());
rc = types.rrs.RefContainer('data', rand(100, 100));
rcPath = '/acquisition/rc';
rcDataPath = [rcPath '/data'];
rcRef = types.cs.CompoundRefData('data', table(...
    rand(),...
    rand(),...
    types.untyped.ObjectView(rcPath),...
    types.untyped.RegionView(rcDataPath, 1:2, 99:100),...
    'VariableNames', {'a', 'b', 'objref', 'regref'}));

nwb.acquisition.set('rc', rc);
nwb.analysis.set('rcRef', rcRef);
nwbExport(nwb, 'original.nwb');
nwb = nwbRead('original.nwb');
nwbExport(nwb, 'new.nwb');
end