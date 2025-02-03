classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...        
    aberrantValuesTest < matlab.unittest.TestCase
% aberrantValuesTest - Unit test aberrant values

    properties
        TestFileName = 'extra.nwb';
    end

    methods (TestClassSetup)
        function setup(TestCase)
            TestCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            
            ExpectedFile = NwbFile(...
                'identifier', 'EXTRAVALUES' ...
                , 'session_description', 'test extra values/fields/datasets' ...
                , 'session_start_time', datetime() ...
                );
            ExpectedFile.acquisition.set('timeseries', types.core.TimeSeries('data', 1:100 ...
                , 'data_unit', 'unit' ...
                , 'starting_time', 0 ...
                , 'starting_time_rate', 1));
            nwbExport(ExpectedFile, TestCase.TestFileName);
        end
    end

    methods (Test)
        function testExtraAttribute(TestCase)    
            fid = H5F.open(TestCase.TestFileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            io.writeAttribute(fid, '/acquisition/timeseries/__expected_extra_attrib', 'extra_data');
            H5F.close(fid);
            
            TestCase.verifyWarning(...
                @() nwbRead(TestCase.TestFileName, 'ignorecache'), ...
                'NWB:CheckUnset:InvalidProperties')
        end
        
        function testInvalidConstraint(TestCase)
            % Add a fake valid dataset to force the constrained validation to fail.
            fid = H5F.open(TestCase.TestFileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            % add a fake valid dataset to force the constrained validation to fail.
            wrongData = types.hdmf_common.VectorData('data', rand(3,1), 'description', 'fake data');
            refs = wrongData.export(fid, '/acquisition/fakedata', {});
            TestCase.assertEmpty(refs);
            H5F.close(fid);
        
            file = TestCase.verifyWarning( ...
                @() nwbRead(TestCase.TestFileName, 'ignorecache'), ...
                'NWB:Set:FailedValidation');
            
            TestCase.verifyWarning( ...
                @() file.acquisition.set('wrong', wrongData), ...
                'NWB:Set:FailedValidation')
        
            TestCase.verifyTrue(~file.acquisition.isKey('wrong'));
        end
    end
end
