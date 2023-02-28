function tests = multipleConstrainedTest()
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
        '+tests', '+unit', 'multipleConstrainedSchema', 'mcs.namespace.yaml');
    generateExtension(schemaPath, 'savedir', '.');
    rehash();
end

function testRoundabout(testCase)
    MultiSet = types.mcs.MultiSetContainer();
    MultiSet.something.set('A', types.mcs.ArbitraryTypeA());
    MultiSet.something.set('B', types.mcs.ArbitraryTypeB());
    MultiSet.something.set('Data', types.mcs.DatasetType());
    nwbExpected = NwbFile(...
        'identifier', 'MCS', ...
        'session_description', 'multiple constrained schema testing', ...
        'session_start_time', datetime());
    nwbExpected.acquisition.set('multiset', MultiSet);
    nwbExport(nwbExpected, 'testmcs.nwb');

    tests.util.verifyContainerEqual(testCase, nwbRead('testmcs.nwb', 'ignorecache'), nwbExpected);
end