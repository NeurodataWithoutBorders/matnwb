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
    'basicUsage.mlx', ...
    'convertTrials.m'};
for i = 1:length(testCase.TestData.listing)
    listing = testCase.TestData.listing(i);
    if listing.isdir || any(strcmp(skippedTutorials, listing.name))
        continue;
    end
    run(listing.name);
end
end