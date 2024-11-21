classdef TutorialTest <  matlab.unittest.TestCase
% TutorialTest - Unit test for testing the matnwb tutorials.
%
%   This test will test most tutorial files (while skipping tutorials with 
%   dependencies) If the tutorial creates an nwb file, the test will also try 
%   to open this with pynwb and run nwbinspector on the file.

%   Notes: 
%   - Requires MATLAB 2019b or later to run py.* commands.
%
%   - pynwb must be installed in the python environment returned by pyenv()
%
%   - Running NWBInspector as a Python package within MATLAB on GitHub runners 
%     currently encounters compatibility issues between the HDF5 library and 
%     h5py. As a workaround in this test, the CLI interface is used to run 
%     NWBInspector and the results are manually parsed. This approach is not 
%     ideal, and hopefully can be improved upon.

    properties
        MatNwbDirectory
    end

    properties (Constant)
        NwbInspectorSeverityLevel = 1
    end

    properties (TestParameter)
        % TutorialFile - A cell array where each cell is the name of a
        % tutorial file. testTutorial will run on each file individually
        tutorialFile = listTutorialFiles();
    end

    properties (Constant)
        SkippedTutorials = {...
            'basicUsage.mlx', ...  % depends on external data
            'convertTrials.m', ... % depends on basicUsage output
            'formatStruct.m', ...  % Actually a utility script, not a tutorial
            'read_demo.mlx', ...   % depends on external data
            'remote_read.mlx'};    % Uses nwbRead on s3 url, potentially very slow
        
        % SkippedFiles - Name of exported nwb files to skip reading with pynwb
        SkippedFiles = {'testFileWithDataPipes.nwb'} % does not produce a valid nwb file

        % PythonDependencies - Package dependencies for running pynwb tutorials
        PythonDependencies = {'nwbinspector'}
    end
    
    properties (Access = private)
        NWBInspectorMode = "python"
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            
            import tests.fixtures.ResetGeneratedTypesFixture

            % Get the root path of the matnwb repository
            rootPath = tests.util.getProjectDirectory();
            tutorialsFolder = fullfile(rootPath, 'tutorials');
            
            testCase.MatNwbDirectory = rootPath;

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(tutorialsFolder));
            
            % Check if it is possible to call py.nwbinspector.* functions.
            % When running these tests on Github Actions, calling 
            % py.nwbinspector does not work, whereas the CLI can be used instead.
            try 
                py.nwbinspector.is_module_installed('nwbinspector');
            catch
                testCase.NWBInspectorMode = "CLI";
            end

            testCase.applyFixture( ResetGeneratedTypesFixture );
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            generateCore('savedir', '.');
        end
    end
    
    methods (Test)
        function testTutorial(testCase, tutorialFile) %#ok<INUSD>
            % Intentionally capturing output, in order for tests to cover
            % code which overloads display methods for nwb types/objects.
            C = evalc( 'run(tutorialFile)' ); %#ok<NASGU>
            
            testCase.readTutorialNwbFileWithPynwb()
            testCase.inspectTutorialFileWithNwbInspector()
        end
    end

    methods 
        function readTutorialNwbFileWithPynwb(testCase)

            % Retrieve all files generated by tutorial
            nwbFileNameList = testCase.listNwbFiles();
            for nwbFilename = nwbFileNameList
                try
                    io = py.pynwb.NWBHDF5IO(nwbFilename);
                    nwbObject = io.read();
                    testCase.verifyNotEmpty(nwbObject, 'The NWB file should not be empty.');
                    io.close()
                catch ME
                    error(ME.message)
                end
            end
        end
    
        function inspectTutorialFileWithNwbInspector(testCase)
            % Retrieve all files generated by tutorial
            nwbFileNameList = testCase.listNwbFiles();
            for nwbFilename = nwbFileNameList
                if testCase.NWBInspectorMode == "python"
                    results = py.list(py.nwbinspector.inspect_nwbfile(nwbfile_path=nwbFilename));
                    results = testCase.convertNwbInspectorResultsToStruct(results);
                elseif testCase.NWBInspectorMode == "CLI"
                    [s, m] = system(sprintf('nwbinspector %s --levels importance', nwbFilename));
                    testCase.assertEqual(s,0, 'Failed to run NWB Inspector using system command.')
                    results = testCase.parseNWBInspectorTextOutput(m);
                end
                
                if isempty(results)
                    return
                end

                results = testCase.filterNWBInspectorResults(results);
                % T = struct2table(results); disp(T)

                for j = 1:numel(results)
                    testCase.verifyLessThan(results(j).importance, testCase.NwbInspectorSeverityLevel, ...
                        sprintf('Message: %s\nLocation: %s\n File: %s\n', ...
                        string(results(j).message), results(j).location, results(j).filepath))
                end
            end
        end
    end

    methods (Access = private)
        function nwbFileNames = listNwbFiles(testCase)
            nwbListing = dir('*.nwb');
            nwbFileNames = string( {nwbListing.name} );
            nwbFileNames = setdiff(nwbFileNames, testCase.SkippedFiles);
            assert(isrow(nwbFileNames), 'Expected output to be a row vector')
            if ~isscalar(nwbFileNames)
                if iscolumn(nwbFileNames)
                    nwbFileNames = transpose(nwbFileNames);
                end
            end
        end
    end

    methods (Static)
        function resultsOut = convertNwbInspectorResultsToStruct(resultsIn)
            
            resultsOut = tests.unit.TutorialTest.getEmptyNwbInspectorResultStruct();
                    
            C = cell(resultsIn);
            for i = 1:numel(C)
                resultsOut(i).importance = double( py.getattr(C{i}.importance, 'value') );
                resultsOut(i).severity = double( py.getattr(C{i}.severity, 'value') );
        
                try
                    resultsOut(i).location =  string(C{i}.location);
                catch
                    resultsOut(i).location = "N/A";
                end
        
                resultsOut(i).message = string(C{i}.message);
                resultsOut(i).filepath = string(C{i}.file_path);
                resultsOut(i).check_name = string(C{i}.check_function_name);
            end
        end
    
        function resultsOut = parseNWBInspectorTextOutput(systemCommandOutput)
            resultsOut = tests.unit.TutorialTest.getEmptyNwbInspectorResultStruct();
            
            importanceLevels = containers.Map(...
                ["BEST_PRACTICE_SUGGESTION", ...
                "BEST_PRACTICE_VIOLATION", ...
                "CRITICAL", ...
                "PYNWB_VALIDATION", ...
                "ERROR"], 0:4 );

            lines = splitlines(systemCommandOutput);
            count = 0;
            for i = 1:numel(lines)
                % Example line:
                % '.0  Importance.BEST_PRACTICE_VIOLATION: behavior_tutorial.nwb - check_regular_timestamps - 'SpatialSeries' object at location '/processing/behavior/Position/SpatialSeries'
                %                                        ^2                      ^1                         ^2                        ^ ^ ^ 3 
                %      [-----------importance------------]  [------filepath------]  [------check_name------]                                                                           [-----------------location----------------]   
                % Splitting and components is exemplified above. 
                
                if ~isempty(regexp( lines{i}, '^\.\d{1}', 'once' ) )
                    count = count+1;
                    % Split line into separate components
                    splitLine = strsplit(lines{i}, ':');
                    splitLine = [...
                        strsplit(splitLine{1}, ' '), ...
                        strsplit(splitLine{2}, '-') ...
                        ];
            
                    resultsOut(count).importance = importanceLevels( extractAfter(splitLine{2}, 'Importance.') );
                    resultsOut(count).filepath = string(strtrim( splitLine{3} ));
                    resultsOut(count).check_name = string(strtrim(splitLine{4} ));
                    try
                        locationInfo = strsplit(splitLine{end}, 'at location');
                        resultsOut(count).location = string(strtrim(eval(locationInfo{2})));
                    catch 
                        resultsOut(count).location = 'N/A';
                    end
                    resultsOut(count).message = string(strtrim(lines{i+1}));
                end
            end
        end

        function emptyResults = getEmptyNwbInspectorResultStruct()
            emptyResults = struct(...
                'importance', {}, ...
                'severity', {}, ...
                'location', {}, ...
                'filepath', {}, ...
                'check_name', {}, ...
                'ignore', {});
        end
    
        function resultsOut = filterNWBInspectorResults(resultsIn)
            CHECK_IGNORE = [...
                "check_image_series_external_file_valid", ...
                "check_regular_timestamps"
                ];
            
            for i = 1:numel(resultsIn)
                resultsIn(i).ignore = any(strcmp(CHECK_IGNORE, resultsIn(i).check_name));
            
                % Special cases to ignore
                if resultsIn(i).location == "/acquisition/ExternalVideos" && ...
                        resultsIn(i).check_name == "check_timestamps_match_first_dimension"
                    resultsIn(i).ignore = true;
                elseif resultsIn(i).location == "/acquisition/SpikeEvents_Shank0" && ...
                    resultsIn(i).check_name == "check_data_orientation"
                    % Data for this example is actually longer in another dimension
                    % than time.
                    resultsIn(i).ignore = true;
                end
            end
            resultsOut = resultsIn;
            resultsOut([resultsOut.ignore]) = [];
        end
    end
end

function tutorialNames = listTutorialFiles()
% listTutorialFiles - List names of all tutorial files (exclude skipped files)
    rootPath = tests.util.getProjectDirectory();
    L = cat(1, ...
        dir(fullfile(rootPath, 'tutorials', '*.mlx')), ...
        dir(fullfile(rootPath, 'tutorials', '*.m')) ...
        );

    L( [L.isdir] ) = []; % Ignore folders
    tutorialNames = setdiff({L.name}, tests.unit.TutorialTest.SkippedTutorials);
end
