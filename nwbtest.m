function results = nwbtest(varargin)
    % NWBTEST Run MatNWB test suite.
    %
    %   The nwbtest function provides a simple way to run the MatNWB test
    %   suite. It writes a JUnit-style XML file containing the test results
    %   (testResults.xml) and a Cobertura-style XML file containing a code
    %   coverage report (coverage.xml).
    %
    %   EXITCODE = nwbtest() runs all tests in the MatNWB test suite and
    %   returns a logical 1 (true) if any tests failed, or a logical 0 (false)
    %   if all tests passed.
    %
    %   EXITCODE = nwbtest('Verbosity', VERBOSITY) runs the tests at the
    %   specified VERBOSITY level. VERBOSITY can be specified as either a
    %   numeric value (1, 2, 3, or 4) or a value from the
    %   matlab.unittest.Verbosity enumeration.
    %
    %   EXITCODE = nwbtest(NAME, VALUE, ...) also supports those name-value
    %   pairs of the matlab.unittest.TestSuite.fromPackage function.
    %
    %   Examples:
    %
    %     % Run all tests in the MatNWB test suite.
    %     nwbtest()
    %
    %     % Run all unit tests in the MatNWB test suite.
    %     nwbtest('Name', 'tests.unit.*')
    %
    %     % Run only tests that match the ProcedureName 'testSmoke*'.
    %     nwbtest('ProcedureName', 'testSmoke*')
    %
    %   See also: matlab.unittest.TestSuite.fromPackage
    
    import matlab.unittest.TestSuite;
    import matlab.unittest.TestRunner;

    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    
    try
        parser = inputParser;
        parser.KeepUnmatched = true;
        parser.addParameter('Verbosity', 1);
        parser.addParameter('Selector', [])
        parser.addParameter('Namespace', 'tests')
        parser.addParameter('ProduceCodeCoverage', true)
        parser.addParameter('ReportOutputFolder', '')

        parser.parse(varargin{:});
        
        if isempty(parser.Results.ReportOutputFolder)
            numReports = 1 + parser.Results.ProduceCodeCoverage;
            [reportOutputFolder, folderCleanupObject] = createReportsFolder(numReports); %#ok<ASGLU>
        else
            reportOutputFolder = parser.Results.ReportOutputFolder;
        end

        % Create test suite
        pvcell = struct2pvcell(parser.Unmatched);
        suite = TestSuite.fromPackage(parser.Results.Namespace, ...
            'IncludingSubpackages', true, pvcell{:});
        if ~isempty(parser.Results.Selector)
            suite = suite.selectIf(parser.Results.Selector);
        end
        suite = suite.sortByFixtures();

        % Configure test runner
        runner = TestRunner.withTextOutput('Verbosity', parser.Results.Verbosity);
        
        resultsFile = fullfile(reportOutputFolder, 'testResults.xml');
        runner.addPlugin(XMLPlugin.producingJUnitFormat(resultsFile));
                
        if parser.Results.ProduceCodeCoverage
            filesForCoverage = getFilesForCoverage();
            if ~verLessThan('matlab', '9.3') && ~isempty(filesForCoverage)
                coverageResultFile = fullfile(reportOutputFolder, 'coverage.xml');
                runner.addPlugin(CodeCoveragePlugin.forFile(filesForCoverage,...
                    'Producing', CoberturaFormat(coverageResultFile)));
            end
        end % add cobertura coverage

        % Run tests
        results = runner.run(suite);
        
        if ~nargout
            display(results)
        end
    catch e
        disp(e.getReport('extended'));
        results = [];
    end
end

function pv = struct2pvcell(s)
    p = fieldnames(s);
    v = struct2cell(s);
    n = 2*numel(p);
    
    pv = cell(1,n);
    pv(1:2:n) = p;
    pv(2:2:n) = v;
end

function filePaths = getFilesForCoverage()
    matnwbDir = misc.getMatnwbDir();
    
    coverageIgnoreFile = fullfile(matnwbDir, '+tests', '.coverageignore');
    ignorePatterns = string(splitlines( fileread(coverageIgnoreFile) ));
    ignorePatterns(ignorePatterns=="") = [];

    mFileListing = dir(fullfile(matnwbDir, '**', '*.m'));
    absoluteFilePaths = fullfile({mFileListing.folder}, {mFileListing.name});
    relativePaths = replace(absoluteFilePaths, [matnwbDir filesep], '');

    keep = ~startsWith(relativePaths, ignorePatterns);
    filePaths = fullfile(matnwbDir, relativePaths(keep));
end

function [reportOutputFolder, folderCleanupObject] = createReportsFolder(numReports)
    
    reportRootFolder = fullfile(misc.getMatnwbDir, 'docs', 'reports');
    timestamp = string(datetime("now", 'Format', 'uuuu_MM_dd_HHmm'));
    reportOutputFolder = fullfile(reportRootFolder, timestamp);
    if ~isfolder(reportOutputFolder); mkdir(reportOutputFolder); end

    folderCleanupObject = onCleanup(...
        @() deleteFolderIfCanceled(reportOutputFolder, numReports));

    function deleteFolderIfCanceled(folderPath, numReports)
        L = dir(fullfile(folderPath, '*.xml'));
        if ~isequal(numel(L), numReports)
            rmdir(folderPath, 's')
        end
    end
end
