function tests = aberrantValuesTest()
    tests = functiontests(localfunctions);
end

function setup(TestCase)
    TestCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
    generateCore('savedir', '.');
    rehash();
    TestCase.TestData.Filename = 'extra.nwb';
    ExpectedFile = NwbFile(...
        'identifier', 'EXTRAVALUES' ...
        , 'session_description', 'test extra values/fields/datasets' ...
        , 'session_start_time', datetime() ...
        );
    ExpectedFile.acquisition.set('timeseries', types.core.TimeSeries('data', 1:100 ...
        , 'data_unit', 'unit' ...
        , 'starting_time', 0 ...
        , 'starting_time_rate', 1));
    nwbExport(ExpectedFile, TestCase.TestData.Filename);
end

function testExtraAttribute(TestCase)
    warning('off', 'NWB:Debug:ErrorStub');
    warning('NWB:Debug:ErrorStub', ''); % ensures `lastwarn` returns this id if called
    warning('on', 'NWB:Debug:ErrorStub');
    
    fid = H5F.open(TestCase.TestData.Filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    io.writeAttribute(fid, '/acquisition/timeseries/__expected_extra_attrib', 'extra_data');
    H5F.close(fid);
    nwbRead(TestCase.TestData.Filename, 'ignorecache');
    [~,warnId] = lastwarn();
    TestCase.verifyEqual(warnId, 'NWB:CheckUnset:InvalidProperties');
end

function testInvalidConstraint(TestCase)
    warning('off', 'NWB:Debug:ErrorStub');
    warning('NWB:Debug:ErrorStub', ''); % ensures `lastwarn` returns this id if called
    warning('on', 'NWB:Debug:ErrorStub');
    
    fid = H5F.open(TestCase.TestData.Filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    % add a fake valid dataset to force the constrained validation to fail.
    wrongData = types.hdmf_common.VectorData('data', rand(3,1));
    refs = wrongData.export(fid, '/acquisition/fakedata', {});
    TestCase.assertEmpty(refs);
    H5F.close(fid);
    file = nwbRead(TestCase.TestData.Filename, 'ignorecache');
    [~,warnId] = lastwarn();
    TestCase.verifyEqual(warnId, 'NWB:Set:FailedValidation');
    
    warning('off', 'NWB:Debug:ErrorStub');
    warning('NWB:Debug:ErrorStub', ''); % ensures `lastwarn` returns this id if called
    warning('on', 'NWB:Debug:ErrorStub');
    
    file.acquisition.set('wrong', wrongData);
    [~,warnId] = lastwarn();
    TestCase.verifyEqual(warnId, 'NWB:Set:FailedValidation');
    TestCase.verifyTrue(~file.acquisition.isKey('wrong'));
end