function tests = smokeTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
corePath = fullfile(rootPath, 'schema', 'core', 'nwb.namespace.yaml');
testCase.TestData.registry = generateCore(corePath);
end

function teardownOnce(testCase)
classes = fieldnames(testCase.TestData.registry);
files = strcat(fullfile('+types', classes), '.m');
delete(files{:});
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

function testSmokeInstantiateCore(testCase)
classes = fieldnames(testCase.TestData.registry);
for i = 1:numel(classes)
  c = classes{i};
  try
    types.(c);
  catch e
    testCase.verifyFail(['Could not instantiate types.' c ' : ' e.message]);
  end
end
end

function testSmokeReadWrite(testCase)
file = nwbfile();
file.epochs = types.untyped.Group();
file.epochs.stim = types.Epoch();
nwbExport(file, 'epoch.nwb');
readFile = nwbRead('epoch.nwb');
testCase.verifyEqual(readFile, file, ...
  'Could not write and then read a simple file');
end