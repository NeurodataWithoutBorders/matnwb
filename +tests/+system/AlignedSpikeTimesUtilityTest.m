classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        AlignedSpikeTimesUtilityTest < matlab.unittest.TestCase

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    methods (Test)
        function psthTest(testCase)
            % Define parameters
            % data generation params
            sampling_rate = 1000;  
            num_units = 10;
            num_events = 15;
            before_time = 1;
            after_time = 1;
            window_length = before_time+after_time;
            % test params
            select_unit = 5;
            select_cond = 1;
            % Create file
            file = NwbFile( ...
                'session_start_time', '2021-01-01 00:00:00', ...
                'identifier', 'ident1', ...
                'session_description', 'test file' ...
            );
            % Create trials table
            % regularly-spaced events
            ev_times = ((before_time)*sampling_rate :(window_length)*sampling_rate:(window_length)*sampling_rate*num_events)'/sampling_rate;
            % event condition (1 or 2)
            ev_cond = randi(2,num_events,1);
            file.intervals_trials = types.core.TimeIntervals(...
                            'description', 'test dynamic table column',...
                            'colnames',{'start_time', 'stop_time','cond'}, ...
                            'start_time', types.hdmf_common.VectorData( ...
                                'description', 'start_times column', ...
                                'data', ev_times ...
                                 ), ...
                            'stop_time', types.hdmf_common.VectorData( ...
                                'description', 'stop_times column', ...
                                'data', ev_times+.1 ... %stimulus duration not relevant for tst
                                 ), ...
                            'cond', types.hdmf_common.VectorData( ...
                                'description', 'condition column', ...
                                'data', ev_cond ... %condition
                                 ), ...
                            'id', types.hdmf_common.ElementIdentifiers( ...
                                'data', (0:num_events-1)' ...
                                ) ...
            );
            % Assemble units table
            file.units = types.core.Units( ...
                'description', 'test Units', ...
                'colnames', {'spike_times'} ...
            );
            psth_test = cell(num_events,1); %empty array
            for unit = 1:num_units
                spike_times_unit = [];
                for ev = 1:num_events
                    % randomly select a firing rate for each event
                    fr = randi(100);
                    % generate random spike times for event, open interval to avoid double-counting 
                    st_ev = (sort(randperm((window_length*sampling_rate)-1,fr*window_length))/sampling_rate)';
                    % store spike times for test unit
                    if unit == select_unit
                        psth_test{ev} = st_ev-before_time; % relative to event
                    end
                    % append to growing spike train
                    spike_times_unit = [spike_times_unit; st_ev+(window_length*(ev-1))];
                end
                % add spike times to table
                file.units.addRow( ...
                    'spike_times', spike_times_unit ...
                );
            end
            % Export file
            filename = 'MatNWB.psthTest.nwb';
            nwbExport(file, filename);
            % Read in file
            read_file = nwbRead(filename, 'ignorecache');
            % Get spike times array for file
            psth_read = util.loadTrialAlignedSpikeTimes(read_file, select_unit, ...
                'before_time', before_time, ...
                'after_time', after_time, ...
                'align_to', 'start_time' ...
            );
            % Verify it's the same as stored spike times for selected unit
            testCase.verifyEqual( ...
                psth_read, ...
                psth_test, ...
                'AbsTol', 1e-10 ...
            );
            % Get spike times array for file for a subset of conditions
            psth_read = util.loadTrialAlignedSpikeTimes(read_file, select_unit, ...
                'before_time', before_time, ...
                'after_time', after_time, ...
                'align_to', 'start_time', ...
                'conditions', containers.Map({'cond'}, {select_cond}) ...
            );
            % verify it's the same as subspabled stored spike times
            testCase.verifyEqual( ...
                psth_read, ...
                psth_test(ev_cond == select_cond), ...
                'AbsTol', 1e-10 ...
            )
        end
    end
end