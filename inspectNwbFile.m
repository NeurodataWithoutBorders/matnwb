function result = inspectNwbFile(nwbFilepath, options)
% inspectNwbFile - Run nwbinspector on the specified NWB file
%
% Syntax:
%  report = INSPECTNWBFILE(nwbFilepath) runs nwbinspector on the NWB file at 
%  nwbFilepath and returns a tabular report listing potential issues. 
%
%  report = NWBREAD(nwbFilepath, Name, Value) runs nwbinspector using optional 
%  name-value pairs for customizing the report.
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
%    nwb = nwbRead('data.nwb', 'VariableOrder', ["importance", "message", "check_function_name", "object_name"]);
%
% Note 1: This function requires the python nwbinspector module to be
%  installed and available from MATLAB. From MATLAB R2019, it is possible to 
%  run python modules directly from MATLAB. Ensure nwbinspector is installed
%  in the python environment returned by running `pyenv` in MATLAB.
%  It is also possible to run the command line (CLI) version of nwbinspector. 
%  If the nwbinspector executable is not on your system's path, you can add the
%  executable to your MATLAB environment variables using the variable name
%  "NWBINSPECTOR_EXECUTABLE", for example 
%  `setenv("NWBINSPECTOR_EXECUTABLE", 'path/to/python/ver/bin/nwbinspector')`
%
% Note 2: This function is meant as a convenience method to run nwbinspector
%  as part of an MatNWB workflow, and does not expose moreadvanced functionality
%  of the nwbinspector.
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
        pyResult = py.list(py.nwbinspector.inspect_nwbfile(nwbfile_path=nwbFilepath));
        result = convertNwbInspectorResultsToTable(pyResult);

    elseif hasCliNwbInspector
        reportFilePath = [tempname, '.json'];
        systemCommand = sprintf('%s %s --levels importance --json-file-path %s', ...
            nwbInspectorExecutable, nwbFilepath, reportFilePath);
        
        [status, ~] = system(systemCommand);
        if status == 0
            cleanupObj = onCleanup( @() delete(reportFilePath));
            result = convertJsonReportToTable(reportFilePath);
        else
            error('NWB:InspectNwbFile:UnknownError', ...
                ['Failed to run nwbinspector using system command. ', ...
                'The following message was returned:\n%s'], m)
        end
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
            resultTable(i).location =  string(C{i}.location);
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
        try 
            py.importlib.metadata.version(distribution_name="nwbinspector");
            isNwbInspectorInstalled = true;
        catch ME
            if contains(ME.message, "PackageNotFoundError")
                S = pyenv();
                warning([...
                    'nwbinspector is not installed for MATLAB''s default ', ...
                    'python environment:\n%s'], S.Home)
            else
                throwAsCaller(ME)
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
        systemCommand = sprintf('where %s', nwbInspectorExecutable);
    else
        error('Unkown platform')
    end
    [status, ~] = system(systemCommand);
    isNwbInspectorInstalled = status == 0;
end
