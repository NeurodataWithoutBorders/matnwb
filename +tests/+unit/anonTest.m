function tests = anonTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
generateCore('savedir', '.');
schemaPath = fullfile(misc.getMatnwbDir(),...
    '+tests', '+unit', 'anonSchema', 'anon.namespace.yaml');
generateExtension(schemaPath, 'savedir', '.');
rehash();
end

function testAnonDataset(testCase)
ag = types.anon.AnonGroup('ad', types.anon.AnonData());
nwbExpected = NwbFile(...
    'identifier', 'ANON',...
    'session_description', 'anonymous class schema testing',...
    'session_start_time', datetime());
nwbExpected.acquisition.set('ag', ag);
nwbExport(nwbExpected, 'testanon.nwb');

tests.util.verifyContainerEqual(testCase, nwbRead('testanon.nwb', 'ignorecache'), nwbExpected);
end
