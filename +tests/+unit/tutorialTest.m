function tests = tutorialTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
tutorialPath = fullfile(rootPath, 'tutorials');
addpath(tutorialPath);
testCase.TestData.listing = dir(tutorialPath);
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
generateCore('savedir', '.');
rehash();
end

function testTutorials(testCase)
skippedTutorials = {...
    'basicUsage.mlx', ...  % depends on external data
    'convertTrials.m', ... % depends on basicUsage output
    'formatStruct.m', ...  % Actually a utility script, not a tutorial
    'read_demo.mlx'};      % depends on external data
for i = 1:length(testCase.TestData.listing)
    listing = testCase.TestData.listing(i);
    if listing.isdir || any(strcmp(skippedTutorials, listing.name))
        continue;
    end
    try
        run(listing.name);
    catch ME
        error('NWB:Test:Tutorial', ...
            'Error while running test `%s`. Full error message:\n\n%s', listing.name, getReport(ME));
    end
end
end