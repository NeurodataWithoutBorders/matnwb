function tests = linkTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

function testLinkConstructor(testCase)
l = types.untyped.Link('/mypath', 'myfile.nwb');
testCase.verifyEqual(l.path, '/mypath');
testCase.verifyEqual(l.filename, 'myfile.nwb');
end

function testLinkExport(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
l = types.untyped.Link('/mypath');
l.export(fid, 'l1');
info = h5info('test.nwb');
testCase.verifyEqual(info.Links.Name, 'l1');
testCase.verifyEqual(info.Links.Type, 'soft link');
testCase.verifyEqual(info.Links.Value, {'/mypath'});
end

function testLinkExportExternal(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
l = types.untyped.Link('/mypath', 'extern.nwb');
l.export(fid, 'l1');
info = h5info('test.nwb');
testCase.verifyEqual(info.Links.Name, 'l1');
testCase.verifyEqual(info.Links.Type, 'external link');
testCase.verifyEqual(info.Links.Value, {'extern.nwb';'/mypath'});
end
