function tests = linkTest()
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

function testExternLinkConstructor(testCase)
l = types.untyped.ExternalLink('myfile.nwb', '/mypath');
testCase.verifyEqual(l.path, '/mypath');
testCase.verifyEqual(l.filename, 'myfile.nwb');
end

function testSoftLinkConstructor(testCase)
l = types.untyped.SoftLink('/mypath');
testCase.verifyEqual(l.path, '/mypath');
end

function testLinkExportSoft(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
l = types.untyped.SoftLink('/mypath');
l.export(fid, 'l1');
info = h5info('test.nwb');
testCase.verifyEqual(info.Links.Name, 'l1');
testCase.verifyEqual(info.Links.Type, 'soft link');
testCase.verifyEqual(info.Links.Value, {'/mypath'});
end

function testLinkExportExternal(testCase)
fid = H5F.create('test.nwb');
close = onCleanup(@()H5F.close(fid));
l = types.untyped.ExternalLink('extern.nwb', '/mypath');
l.export(fid, 'l1');
info = h5info('test.nwb');
testCase.verifyEqual(info.Links.Name, 'l1');
testCase.verifyEqual(info.Links.Type, 'external link');
testCase.verifyEqual(info.Links.Value, {'extern.nwb';'/mypath'});
end

function testSoftResolution(testCase)
nwb = NwbFile;
dev = types.core.Device;
nwb.general_devices.set('testDevice', dev);
nwb.general_extracellular_ephys.set('testEphys',...
    types.core.ElectrodeGroup('device',...
    types.untyped.SoftLink('/general/devices/testDevice')));
testCase.verifyEqual(dev,...
    nwb.general_extracellular_ephys.get('testEphys').device.deref(nwb));
end

function testExternalResolution(testCase)
nwb = NwbFile('identifier', 'EXTERNAL',...
    'session_description', 'external link test',...
    'session_start_time', datetime());

expectedData = rand(100,1);
stubDtr = types.hdmf_common.DynamicTableRegion(...
    'table', types.untyped.ObjectView('/acquisition/es1'),...
    'description', 'dtr stub that points to electrical series illegally'); % do not do this at home.
expected = types.core.ElectricalSeries('data', expectedData,...
    'data_unit', 'unit',...
    'electrodes', stubDtr);
nwb.acquisition.set('es1', expected);
nwb.export('test1.nwb');

externalLink = types.untyped.ExternalLink('test1.nwb', '/acquisition/es1');
tests.util.verifyContainerEqual(testCase, externalLink.deref(), expected);
externalDataLink = types.untyped.ExternalLink('test1.nwb', '/acquisition/es1/data');
% for datasets, a Datastub is returned.
testCase.verifyEqual(externalDataLink.deref().load(), expectedData);

nwb.acquisition.clear();
nwb.acquisition.set('lfp', types.core.LFP('eslink', externalLink));
nwb.export('test2.nwb');

metaExternalLink = types.untyped.ExternalLink('test2.nwb', '/acquisition/lfp/eslink');
% for links, deref() should return its own link.
tests.util.verifyContainerEqual(testCase, metaExternalLink.deref().deref(), expected);
end
