function tests = searchTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
generateCore('savedir', '.');
rehash();
end

function testSearch(testCase)
nwb = NwbFile();
testCase.assertEmpty(nwb.searchFor('types.core.TimeSeries'));

nwb.acquisition.set('ts1', types.core.TimeSeries());
testCase.assertNotEmpty(nwb.searchFor('types.core.TimeSeries'));
testCase.assertNotEmpty(nwb.searchFor('types.core.timeseries'));
nwb.acquisition.set('pc1', types.core.PatchClampSeries());

% default search does NOT include subclasses
testCase.assertLength(nwb.searchFor('types.core.TimeSeries'), 1);

% use includeSubClasses keyword
testCase.assertLength(nwb.searchFor('types.core.TimeSeries', 'includeSubClasses'), 2);
end