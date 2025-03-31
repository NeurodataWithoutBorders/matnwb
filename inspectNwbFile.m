function result = inspectNwbFile(nwbFilepath, options)
% INSPECTNWBFILE - Run nwbinspector on the specified NWB file
%
% Syntax:
%  report = INSPECTNWBFILE(nwbFilepath) runs nwbinspector on the NWB file at 
%  nwbFilepath and returns a tabular report listing potential issues. 
%
%  report = INSPECTNWBFILE(nwbFilepath, Name, Value) runs nwbinspector using 
%  optional name-value pairs for customizing the report.
%
% Input Arguments:
%  - nwbFilepath (string) - 
%    Filepath pointing to an NWB file.
% 
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%  
%    - VariableOrder (string) -
%      Which order to arrange the variables in the tabular report.
% 
% Output Arguments:
%  - report (table) - A tabular report listing nwbinspector issues
%
% Usage:
%  Example 1 - Inspect an NWB file::
%
%    report = inspectNwbFile('my_nwb_file.nwb');
%
%  Example 2 - Inspect an NWB file and specify the order to display report variables::
%
%    variableOrder = ["importance", "message", "check_function_name", "object_name"];
%    nwb = inspectNwbFile('my_nwb_file.nwb', ...
%        'VariableOrder', variableOrder);
%
% .. note::
%  This function requires the python nwbinspector module to be
%  installed and available from MATLAB. From MATLAB R2019, it is possible to 
%  run python modules directly from MATLAB. Ensure nwbinspector is installed
%  in the python environment returned by running `pyenv` in MATLAB.
%  It is also possible to run the command line (CLI) version of nwbinspector. 
%  If the nwbinspector executable is not on your system's path, you can add the
%  executable to your MATLAB environment variables using the variable name
%  "NWBINSPECTOR_EXECUTABLE", for example 
%  `setenv("NWBINSPECTOR_EXECUTABLE", 'path/to/python/ver/bin/nwbinspector')`
%
% .. note::
%  This function is meant as a convenience method for running the nwbinspector
%  as part of an MatNWB workflow, and it does not expose more advanced 
%  functionality of the nwbinspector.
% 
% See also:
%   pyenv

    arguments
        nwbFilepath (1,1) string {matnwb.common.mustBeNwbFile}
        options.VariableOrder = [...
            "importance", ...
            "check_function_name", ...
            "object_name", ...
            "object_type", ...
            "message", ...
            "location", ...
            "file_path", ...
            "severity"];
        options.UseCLI (1,1) logical = false % Flag for forcing usage of the command line interface. Useful for testing
    end

    hasPyNwbInspector = isPyNwbInspectorAvailable();
    [hasCliNwbInspector, nwbInspectorExecutable] = isCliNwbInspectorAvailable();

    if hasPyNwbInspector && ~options.UseCLI
        pyResult = py.list(py.nwbinspector.inspect_nwbfile(nwbFilepath));
        result = convertNwbInspectorResultsToTable(pyResult);

    elseif hasCliNwbInspector
        reportFilePath = [tempname, '.json'];
        if isunix
            systemCommand = sprintf('%s %s --levels importance --json-file-path %s', ...
                nwbInspectorExecutable, nwbFilepath, reportFilePath);
        elseif ispc
            % Use double quotes in case there are spaces in the filepaths
            systemCommand = sprintf('"%s" "%s" --levels importance --json-file-path "%s"', ...
                nwbInspectorExecutable, nwbFilepath, reportFilePath);      
        end
        [status, m] = system(systemCommand);
        
        assert(status == 0, ...
            'NWB:InspectNwbFile:UnknownError', ...
            ['Failed to run nwbinspector using system command. ', ...
            'The following message was returned:\n%s'], m)

        cleanupObj = onCleanup( @() delete(reportFilePath));
        result = convertJsonReportToTable(reportFilePath);
    else
        error('NWB:InspectNwbFile:NwbInspectorNotFound', ...
            'Did not find nwbinspector. See `help inspectNwbFile` for more details')
    end
    result = result(:, options.VariableOrder);
end

function resultTable = convertNwbInspectorResultsToTable(resultsIn)
    
    resultTable = getEmptyNwbInspectorResultStruct();
     
    C = cell(resultsIn);
    for i = 1:numel(C)
        resultTable(i).importance = string( py.getattr(C{i}.importance, 'name') );
        resultTable(i).severity = string( py.getattr(C{i}.severity, 'name') );
        try
            resultTable(i).location = string(C{i}.location);
        catch
            resultTable(i).location = "N/A";
        end
        resultTable(i).message = string(C{i}.message);
        resultTable(i).object_name = string(C{i}.object_name);
        resultTable(i).object_type = string(C{i}.object_type);
        resultTable(i).file_path = string(C{i}.file_path);
        resultTable(i).check_function_name = string(C{i}.check_function_name);
    end
    resultTable = struct2table(resultTable);
end

function resultTable = convertJsonReportToTable(reportFilePath)
    S = jsondecode(fileread(reportFilePath));
    varNames = fieldnames(S.messages);
    T = struct2table(S.messages);

    for i = 1:numel(varNames)
        try
            T.(varNames{i}) = string(T.(varNames{i}));
        catch MECause
            switch MECause.identifier
                case 'MATLAB:string:MustBeConvertibleCellArray'
                    data = T.(varNames{i});
                    isNumericEmpty = cellfun(@(c) isnumeric(c) && isempty(c), data);
                    if any(isNumericEmpty)
                        data(isNumericEmpty) = {""};
                        T.(varNames{i}) = string(data);
                    end

                otherwise 
                    ME = MException(...
                        'NWB:InspectNwbFile:ResultConversionFailed', ...
                        'Something went wrong when converting nwbinspector results to a MATLAB table.');
                    ME.addCause(MECause)
                    throw(ME)
            end
        end
    end
    resultTable = T;
end

function emptyResults = getEmptyNwbInspectorResultStruct()
    emptyResults = struct(...
        'importance', {}, ...
        'check_function_name', {}, ...
        'object_name', {}, ...
        'object_type', {}, ...
        'message', {}, ...
        'location', {}, ...
        'file_path', {}, ...
        'severity', {} );
end
    
function isNwbInspectorInstalled = isPyNwbInspectorAvailable()
    isNwbInspectorInstalled = false;
    if exist("pyenv", "builtin") == 5
        pythonEnv = pyenv();
        if pythonEnv.Executable == ""
            return
        else
            try 
                py.importlib.metadata.version("nwbinspector");
                isNwbInspectorInstalled = true;
            catch ME
                if contains(ME.message, "PackageNotFoundError")
                    warning([...
                        'nwbinspector is not installed for MATLAB''s default ', ...
                        'python environment:\n%s'], pyenv().Home)
                else
                    throwAsCaller(ME)
                end
            end
        end
    end
end

function [isNwbInspectorInstalled, nwbInspectorExecutable] = isCliNwbInspectorAvailable()
    nwbInspectorExecutable = getenv("NWBINSPECTOR_EXECUTABLE");
    if isempty(nwbInspectorExecutable)
        % Trying with default nwbinspector binary
        nwbInspectorExecutable = "nwbinspector";
    end

    if isunix
        systemCommand = sprintf('which %s', nwbInspectorExecutable);
    elseif ispc
        if isfile([nwbInspectorExecutable, '.exe'])
            % If the nwbexecutable exists as a file, we have the absolute
            % path and don't need to check with the where command
            isNwbInspectorInstalled = true;
            return
        else
            systemCommand = sprintf('where "%s"', nwbInspectorExecutable);
        end
    end
    assert(logical(exist('systemCommand', 'var')), ...
        'Unknown platform, could not generate system command. Please report!')
    [status, ~] = system(systemCommand);
    
    isNwbInspectorInstalled = status == 0;
end
