classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
    SmokeTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setup(testCase)
            % This method runs before each test method.
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        %TODO rewrite namespace instantiation check
        function testSmokeInstantiateCore(testCase)
            % classes = fieldnames(testCase.TestData.registry);
            % for i = 1:numel(classes)
            %     c = classes{i};
            %     try
            %         types.(c);
            %     catch e
            %         testCase.verifyFail(['Could not instantiate types.' c ' : ' e.message]);
            %     end
            % end
        end

        function testSmokeReadWrite(testCase)
            % Create a TimeIntervals object
            epochs = types.core.TimeIntervals( ...
                'colnames', {'start_time'; 'stop_time'} , ...
                'id', types.hdmf_common.ElementIdentifiers('data', 1), ...
                'description', 'test TimeIntervals', ...
                'start_time', types.hdmf_common.VectorData('data', 0, 'description', 'start time'), ...
                'stop_time', types.hdmf_common.VectorData('data', 1, 'description', 'stop time'));

            % Create an NwbFile and export
            file = NwbFile( ...
                'identifier', 'st', ...
                'session_description', 'smokeTest', ...
                'session_start_time', datetime, ...
                'intervals_epochs', epochs, ...
                'timestamps_reference_time', datetime);
            nwbExport(file, 'epoch.nwb');

            % Read the file back
            readFile = nwbRead('epoch.nwb', 'ignorecache');

            tests.util.verifyContainerEqual(testCase, readFile, file);
        end
    end
end
