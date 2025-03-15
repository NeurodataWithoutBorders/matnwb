function result = inspectNwbFile(nwbFilename, options)
    arguments
        nwbFilename (1,1) string {matnwb.common.mustBeNwbFile}
        options.VariableOrder = [...
            "importance", ...
            "check_function_name", ...
            "object_name", ...
            "object_type", ...
            "message", ...
            "location", ...
            "file_path", ...
            "severity"];
    end

    if false % isPyNwbInspectorAvailable()
        pyResult = py.list(py.nwbinspector.inspect_nwbfile(nwbfile_path=nwbFilename));
        result = convertNwbInspectorResultsToTable(pyResult);
    else
        nwbInspectorExecutable = getenv("NWBINSPECTOR_EXECUTABLE");
        if isempty(nwbInspectorExecutable)
            % Trying with default nwbinspector binary
            nwbInspectorExecutable = "nwbinspector";
        end

        reportFilePath = [tempname, '.json'];
        [s, ~] = system(sprintf('%s %s --levels importance --json-file-path %s', nwbInspectorExecutable, nwbFilename, reportFilePath));
        if s == 0
            cleanupObj = onCleanup( @() delete(reportFilePath));
            result = convertJsonReportToTable(reportFilePath);
        else
            error('NWB:InspectNwbFile:UnknownError', 'Failed to run nwbinspector using system command. The following message was returned: %s', m)
        end        
        % error('NWB:InspectNwbFile:NwbInspectorNotFound', 'Did not find nwbinspector. See `help inspectNwbFile` for more details')
    end

    result = result(:, options.VariableOrder);
end

function resultTable = convertNwbInspectorResultsToTable(resultsIn)
    
    resultTable = getEmptyNwbInspectorResultStruct();
     
    C = cell(resultsIn);
    for i = 1:numel(C)
        resultTable(i).importance = double( py.getattr(C{i}.importance, 'value') );
        resultTable(i).severity = double( py.getattr(C{i}.severity, 'value') );

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
        try py.importlib.metadata.version(distribution_name="nwbinspector")
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
