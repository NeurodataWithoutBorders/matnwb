classdef (SharedTestFixtures = {tests.fixtures.SetEnvironmentVariableFixture}) ...
        PynwbTutorialTest < matlab.unittest.TestCase
% PynwbTutorialTest - Unit test for testing the pynwb tutorials.
%
%   This test will test most pynwb tutorial files (while skipping tutorials with 
%   dependencies) If the tutorial creates nwb file(s), the test will also try 
%   to open these with matnwb.

    properties
        MatNwbDirectory
        PyNwbDirectory
    end

    properties (TestParameter)
        % TutorialFile - A cell array where each cell is the name of a
        % tutorial file. testTutorial will run on each file individually
        tutorialFile = listTutorialFiles();
    end

    properties (Constant)
        % SkippedTutorials - Tutorials from pynwb to skip
        SkippedTutorials = {...
            'plot_read_basics.py', ...      % Downloads file from dandi archive, does not export nwb file
            'streaming.py', ...             % Requires that HDF5 library is installed with the ROS3 driver enabled which is not a given
            'object_id.py', ...             % Does not export nwb file
            'plot_configurator.py', ...     % Does not export nwb file
            'plot_zarr_io', ...             % Does not export nwb file in nwb format
            'brain_observatory.py', ...     % Requires allen sdk
            'extensions.py'};               % Discrepancy between tutorial and schema: https://github.com/NeurodataWithoutBorders/pynwb/issues/1952

        % SkippedFiles - Name of exported nwb files to skip reading with matnwb
        SkippedFiles = {'family_nwb_file_0.nwb'} % requires family driver from h5py
        
        % PythonDependencies - Package dependencies for running pynwb tutorials
        PythonDependencies = {'dataframe-image', 'matplotlib'}
    end

    properties (Access = private)
        PythonEnvironment % Stores the value of the environment variable 
        % "PYTHONPATH" to restore when test is finished.

        Debug (1,1) logical
    end

    methods (TestClassSetup)
        function setupClass(testCase)

            import tests.fixtures.NwbClearGeneratedFixture
            
            testCase.Debug = strcmp(getenv('NWB_TEST_DEBUG'), '1');

            % Get the root path of the matnwb repository
            rootPath = getMatNwbRootDirectory();
            testCase.MatNwbDirectory = rootPath;

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
            
            % Clear the generated schema classes
            testCase.applyFixture(NwbClearGeneratedFixture) 

            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
           
            % Download pynwb in the current (temp) directory and cd into pynwb
            testCase.PyNwbDirectory = downloadPynwb();
            cd( testCase.PyNwbDirectory )
            
            testCase.createVirtualPythonEnvironment()
            testCase.installPythonDependencies()

            % Add site-packages to python path
            testCase.PythonEnvironment = getenv('PYTHONPATH');
            L = dir('temp_venv/lib/python*/site-*'); % Find the site-packages folder
            pythonPath = fullfile(L.folder, L.name);
            setenv('PYTHONPATH', pythonPath)
            
            if testCase.Debug
                pythonExecutable = getenv("PYTHON_EXECUTABLE");
                [~, m] = system(sprintf('%s -m pip list', pythonExecutable)); disp(m)
            end
        end
    end

    methods (TestClassTeardown)
        function tearDownClass(testCase)
            % Restore environment variable
            setenv('PYTHONPATH', testCase.PythonEnvironment);
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase) %#ok<MANU>
            % pass
        end
    end

    methods (TestMethodTeardown)
        function teardownMethod(testCase) %#ok<MANU>
            % Clear/delete all nwb files
            L = dir('*.nwb');
            for i = 1:numel(L)
                delete(fullfile(L(i).folder, L(i).name))
            end

            % Consider whether to also run nwbClearGenerated here
        end
    end
    
    methods (Test)
        function testTutorial(testCase, tutorialFile)

            pythonExecutable = getenv("PYTHON_EXECUTABLE");
            cmd = sprintf('%s %s', pythonExecutable, tutorialFile);
            [status, cmdout] = system(cmd);

            if status == 1
                if contains( cmdout, "ModuleNotFoundError: No module named 'hdf5plugin'" )
                    % pass
                    %keyboard
                else
                    [~, tutorialName] = fileparts(tutorialFile);
                    error('Failed to run python tutorial named "%s" with error:\n %s', tutorialName, cmdout)
                end
            end

            testCase.testReadTutorialNwbFileWithMatNwb()
        end
    end

    methods
        function testReadTutorialNwbFileWithMatNwb(testCase)

            % Retrieve all files generated by the tutorial
            nwbListing = dir('*.nwb');
            
            for i = 1:numel(nwbListing)
                nwbFilename = nwbListing(i).name;
                if any(strcmp(nwbFilename, tests.system.tutorial.PynwbTutorialTest.SkippedFiles))
                    continue
                end

                try
                    %schemaVersion = util.getSchemaVersion(nwbFilename); %Debug

                    % NB: Need to specify savedir to current directory (.) in
                    % order to generate schema in working directory for test
                    nwbFile = nwbRead(nwbFilename, 'savedir', '.'); %#ok<NASGU>
                catch ME
                    error(ME.message)
                end
            end
        end
    end

    methods (Access = private) % Utility functions
        function createVirtualPythonEnvironment(testCase) %#ok<MANU>

            pythonExecutable = getenv("PYTHON_EXECUTABLE");

            cmd = sprintf("%s -m venv ./temp_venv", pythonExecutable );
            [status, cmdout] = system(cmd);

            if ~status == 0
                error("Failed to create virtual python environment with error:\n%s", cmdout)
            end

            % Activate virtual python environment
            if isunix
                system('source ./temp_venv/bin/activate'); 
            elseif ispc
                system('temp_venv\Scripts\activate')
            end
        end

        function installPythonDependencies(testCase)
            % Install python dependencies
            pipExecutable = './temp_venv/bin/pip3';
            for i = 1:numel(testCase.PythonDependencies)
                iName = testCase.PythonDependencies{i};
                installCmdStr = sprintf('%s install %s', pipExecutable, iName);

                if testCase.Debug
                    [~, m] = system(installCmdStr); disp(m)
                else
                    evalc( "system(installCmdStr)" ); % Install without command window output
                end
            end
        end
    end
end

function tutorialNames = listTutorialFiles()
% listTutorialFiles - List names of all tutorial files (exclude skipped files)

    % Note: Without a token, github api requests are limited to 60 per
    % hour. The listFilesInRepo will make 4 requests per call
    if isenv('GITHUB_TOKEN')
        token = getenv('GITHUB_TOKEN');
    else
        token = '';
    end
    
    allFilePaths = listFilesInRepo(...
        'NeurodataWithoutBorders', 'pynwb', 'docs/gallery/', token);
    
    % Exclude files that are not .py files.
    [~, fileNames, fileExt] = fileparts(allFilePaths);
    keep = strcmp(fileExt, '.py');
    allFilePaths = allFilePaths(keep);

    % Exclude skipped files.
    fileNames = strcat(fileNames(keep), '.py');
    [~, iA] = setdiff(fileNames, tests.system.tutorial.PynwbTutorialTest.SkippedTutorials, 'stable');
    tutorialNames = allFilePaths(iA);
end

function folderPath = getMatNwbRootDirectory()
    folderPath = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
end

function pynwbFolder = downloadPynwb()
    githubUrl = 'https://github.com/NeurodataWithoutBorders/pynwb/archive/refs/heads/dev.zip';
    pynwbFolder = downloadZippedGithubRepo(githubUrl, '.'); % Download in current directory
end

function repoFolder = downloadZippedGithubRepo(githubUrl, targetFolder)
%downloadZippedGithubRepo Download addon to a specified addon folder
    
    % Create a temporary path for storing the downloaded file.
    [~, ~, fileType] = fileparts(githubUrl);
    tempFilepath = [tempname, fileType];
    
    % Download the file containing the repository
    try
        tempFilepath = websave(tempFilepath, githubUrl);
        fileCleanupObj = onCleanup( @(fname) delete(tempFilepath) );
    catch ME
        if throwErrorIfFails
            rethrow(ME)
        end
    end
    
    fileNames = unzip(tempFilepath, targetFolder);
    
    % Delete the temp zip file
    clear fileCleanupObj

    repoFolder = fullfile(targetFolder, fileNames{1});
end

function allFiles = listFilesInRepo(owner, repo, path, token)
    % This function lists all files in a GitHub repository, including subfolders.
    % Inputs:
    %   - owner: GitHub username or organization name
    %   - repo: Repository name
    %   - path: Folder path in the repository (use '' for root)
    %   - token: Personal Access Token for GitHub API (use '' for public repos)
    % Outputs:
    %   - allFiles: Cell array of file paths
    
    if nargin < 3
        path = '';
    end
    if nargin < 4
        token = '';
    end

    % Construct the API URL
    url = ['https://api.github.com/repos/' owner '/' repo '/contents/' path];

    % Set up HTTP headers, including authentication if provided
    headers = matlab.net.http.HeaderField.empty;
    if ~isempty(token)
        headers(end+1) = matlab.net.http.HeaderField('Authorization', ['token ' token]);
    end
    headers(end+1) = matlab.net.http.HeaderField('Accept', 'application/vnd.github.v3+json');

    % Send the HTTP GET request
    request = matlab.net.http.RequestMessage('GET', headers);
    response = request.send(url);

    % Check if the request was successful
    if response.StatusCode == matlab.net.http.StatusCode.OK
        contents = response.Body.Data;
    else
        error('Failed to fetch data: %s', response.StatusLine);
    end

    % Initialize the output
    allFiles = {};

    % Process the contents
    for i = 1:numel(contents)
        item = contents(i);
        if strcmp(item.type, 'file')
            % If it's a file, add its path to the list
            allFiles{end+1} = item.path; %#ok<AGROW>
        elseif strcmp(item.type, 'dir')
            % If it's a directory, recursively fetch its contents
            subfolderFiles = listFilesInRepo(owner, repo, item.path, token);
            allFiles = [allFiles, subfolderFiles]; %#ok<AGROW>
        end
    end
end
