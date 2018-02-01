function tests = groupTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

function testGroupConstructor(testCase)
s.attributes.a1 = {'attr1'};
s.datasets.d1 = [1 2 3];
s.links.l1 = types.untyped.Link('');
s.groups.g1 = types.untyped.Group();
s.classes.c1 = types.untyped.Group();
g = types.untyped.Group(s);
testCase.verifyEqual(g.attributes, s.attributes);
testCase.verifyEqual(g.datasets, s.datasets);
testCase.verifyEqual(g.links, s.links);
testCase.verifyEqual(g.groups, s.groups);
testCase.verifyEqual(g.classes, s.classes);
end

function testGroupConstructorDoesNotCarryState(testCase)
g1 = types.untyped.Group();
testCase.verifyTrue(isempty(g1.groups));
g1.g2 = types.untyped.Group();

g3 = types.untyped.Group();
testCase.verifyTrue(isempty(g3.groups));
end

function testGroupConstructorThrowsOnUnknownArgument(testCase)
testCase.assumeFail('Group constructor does not currently throw with unknown field');
s.unknownField = [1 2 3];
testCase.verifyError(@()types.untyped.Group(s), ?MException);
end

function testGroupDotSubsref(testCase)
s = util.StructMap('datasets', util.StructMap('d1', [1 2 3]));
% s.datasets.d1 = [1 2 3];
g = types.untyped.Group(s);
testCase.verifyEqual(g.datasets.d1, [1 2 3]);
testCase.verifyEqual(g.d1, [1 2 3]);
end

function testGroupNestedDotSubsref(testCase)
s1 = util.StructMap('datasets', util.StructMap('d1', [1 2 3]));
g1 = types.untyped.Group(s1);
s2 = util.StructMap('groups', util.StructMap('g1', g1));
% s2.groups.g1.datasets.d1 = [1 2 3];
g2 = types.untyped.Group(s2);
testCase.verifyEqual(g2.groups.g1.datasets.d1, [1 2 3]);
testCase.verifyEqual(g2.g1.datasets.d1, [1 2 3]);
testCase.verifyEqual(g2.groups.g1.d1, [1 2 3]);
testCase.verifyEqual(g2.g1.d1, [1 2 3]);
end

function testGroupDotSubsasgnGroup(testCase)
g1 = types.untyped.Group();
g2 = types.untyped.Group();
g3 = types.untyped.Group();
g3.groups.g1 = g1;
g3.g2 = g2;
testCase.verifyEqual(g3.groups.g1, g1);
testCase.verifyEqual(g3.groups.g2, g2);
end

function testGroupDotSubsasgnLink(testCase)
l1 = types.untyped.Link('/a');
l2 = types.untyped.Link('/b');
g = types.untyped.Group();
g.links.l1 = l1;
g.l2 = l2;
testCase.verifyEqual(g.links.l1, l1);
testCase.verifyEqual(g.links.l2, l2);
end

function testGroupProperties(testCase)
s.attributes.a1 = {'attr1'};
s.datasets.d1 = [1 2 3];
s.links.l1 = types.untyped.Link('');
s.groups.g1 = types.untyped.Group();
s.classes.c1 = types.untyped.Group();
g = types.untyped.Group(s);
testCase.verifyTrue(all(ismember({'a1','d1','l1','g1','c1'}, properties(g))));
end

function testGroupExportWithGroups(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
s = util.StructMap('groups', ...
  util.StructMap({'g1', 'g2'}, {types.untyped.Group(), types.untyped.Group()}));
% s.groups.g1 = types.untyped.Group();
% s.groups.g1 = types.untyped.Group();
g = types.untyped.Group(s);
g.export(fid);
info = h5info('test.nwb');
testCase.verifyTrue(all(ismember({'/g1', '/g2'}, {info.Groups(:).Name})));
end

function testGroupExportWithLinks(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
s = util.StructMap('links', ...
  util.StructMap({'l1', 'l2'}, {types.untyped.Link('/a'), types.untyped.Link('/b')}));
% s.links.l1 = types.untyped.Link();
% s.links.l1 = types.untyped.Link();
g = types.untyped.Group(s);
g.export(fid);
info = h5info('test.nwb');
testCase.verifyTrue(all(ismember({'l1', 'l2'}, {info.Links(:).Name})));
end
