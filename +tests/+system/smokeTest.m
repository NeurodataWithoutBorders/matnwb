function tests = smokeTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
% corePath = fullfile(rootPath, 'schema', 'core', 'nwb.namespace.yaml');
% testCase.TestData.registry = generateCore(corePath);
end

function teardownOnce(testCase)
% classes = fieldnames(testCase.TestData.registry);
% files = strcat(fullfile('+types', classes), '.m');
% delete(files{:});
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

%TODO rewrite namespace instantiation check
function testSmokeInstantiateCore(testCase)
% classes = fieldnames(testCase.TestData.registry);
% for i = 1:numel(classes)
%     c = classes{i};
%     try
%         types.(c);
%     catch e
%         testCase.verifyFail(['Could not instantiate types.' c ' : ' e.message]);
%     end
% end
end

function testSmokeReadWrite(testCase)
file = nwbfile('source', 'smokeTest', 'identifier', 'st',...
    'session_description', 'smokeTest', 'session_start_time', datetime);
epochs = types.core.EpochTable;
md = types.core.DynamicTable(...
    'description', 'testDynamicTable',...
    'colnames', 'id',...
    'id', types.core.ElementIdentifiers('data', int64(1)),...
    'source', 'smokeTest');
ts = types.core.TimeSeriesIndex;
file.epochs = types.core.Epochs('epochs', epochs, 'metadata', md,...
    'timeseries_index', ts, 'source', 'smokeTest');
nwbExport(file, 'epoch.nwb');
readFile = nwbRead('epoch.nwb');
% testCase.verifyEqual(testCase, readFile, file, ...
%     'Could not write and then read a simple file');
tests.util.verifyContainerEqual(testCase, readFile, file);
end