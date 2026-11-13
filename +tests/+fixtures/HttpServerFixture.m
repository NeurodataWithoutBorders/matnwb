classdef HttpServerFixture < matlab.unittest.fixtures.Fixture
% HttpServerFixture - Serve a folder over HTTP on localhost for the duration of a test.
%
% Starts serve_directory.py (next to this file), which binds a free port on
% 127.0.0.1 and answers Range requests with partial content, so code that
% reads over HTTP is tested the way it reads from S3 or a CDN. The test is
% skipped by assumption when no Python 3 interpreter can be found.
%
% Usage:
%   server = testCase.applyFixture(tests.fixtures.HttpServerFixture(folder));
%   url = server.BaseUrl + "/store.zarr";

    properties (SetAccess = immutable)
        % Folder - Folder whose contents are served.
        Folder (1,1) string
    end

    properties (SetAccess = private)
        % BaseUrl - URL of the served folder, without a trailing slash.
        BaseUrl (1,1) string = ""

        % RequestLog - File the server appends "<status> <path>" to per request.
        RequestLog (1,1) string = ""
    end

    properties (Access = private)
        Process = []
    end

    properties (Constant, Access = private)
        StartupTimeoutSeconds = 15
        PollIntervalSeconds = 0.1
    end

    methods
        function fixture = HttpServerFixture(folder)
            arguments
                folder (1,1) string {mustBeFolder}
            end
            fixture.Folder = folder;
        end

        function setup(fixture)
            python = findPython();
            fixture.assumeNotEmpty(python, ...
                "Serving a folder over HTTP needs a Python 3 interpreter on the system path.");

            scriptPath = fullfile(fileparts(mfilename("fullpath")), "serve_directory.py");
            portFile = string(tempname) + ".port";
            fixture.RequestLog = string(tempname) + ".log";

            % A Java process can be stopped on every platform, unlike a shell
            % job started with "&".
            builder = java.lang.ProcessBuilder(cellfun(@char, ...
                {python, scriptPath, fixture.Folder, portFile, fixture.RequestLog}, ...
                "UniformOutput", false));
            fixture.Process = builder.start();
            fixture.addTeardown(@() fixture.Process.destroy());

            elapsed = 0;
            while ~isfile(portFile) && elapsed < fixture.StartupTimeoutSeconds
                pause(fixture.PollIntervalSeconds)
                elapsed = elapsed + fixture.PollIntervalSeconds;
            end
            fixture.assertTrue(isfile(portFile), ...
                "The HTTP server did not start within " + fixture.StartupTimeoutSeconds + " s.");
            fixture.addTeardown(@() delete(portFile));

            port = strtrim(string(fileread(portFile)));
            fixture.BaseUrl = "http://127.0.0.1:" + port;
            fixture.SetupDescription = "Serve " + fixture.Folder + " at " + fixture.BaseUrl;
        end

        function lines = readRequestLog(fixture)
        % readRequestLog - The requests served so far, one "<status> <path>" per line.
            lines = strings(0, 1);
            if isfile(fixture.RequestLog)
                lines = splitlines(strtrim(string(fileread(fixture.RequestLog))));
                lines(lines == "") = [];
            end
        end
    end

    methods (Access = protected)
        function tf = isCompatible(fixture, other)
            tf = fixture.Folder == other.Folder;
        end
    end
end

function python = findPython()
% findPython - Path or name of a Python 3 interpreter, or "" if there is none.
    python = "";
    for candidate = ["python3", "python"]
        [status, output] = system(candidate + " -c ""import sys; print(sys.version_info[0])""");
        if status == 0 && strtrim(string(output)) == "3"
            python = candidate;
            return
        end
    end
end
