function results = matnwb_testExtensionInstallation(summaryFile)
% matnwb_testExtensionInstallation - Install every catalog extension and report the result.
%
%   results = matnwb_testExtensionInstallation() installs the latest
%   release of every extension in the Neurodata Extensions Catalog, each in
%   its own folder with the core schema, and returns a table with the
%   catalog version, the latest release and the number of releases on PyPI,
%   and the installation result of each extension. It throws an error after
%   the report when an extension fails to install.
%
%   results = matnwb_testExtensionInstallation(summaryFile) also appends the
%   report as a Markdown table to summaryFile. The update_extension_list
%   workflow passes the file that GitHub shows as the job summary.
%
%   Each extension is installed in its own folder because +types holds one
%   version of each extension, and extensions can require different
%   versions of the same extension.

    arguments
        summaryFile (1,1) string = ""
    end

    extensionTable = matnwb.extension.listExtensions();
    extensionNames = extensionTable.name;
    extensionCount = numel(extensionNames);

    results = table( ...
        extensionNames, string(extensionTable.version), ...
        strings(extensionCount, 1), zeros(extensionCount, 1), strings(extensionCount, 1), ...
        'VariableNames', ["Name", "CatalogVersion", "LatestRelease", "ReleaseCount", "Installation"]);

    workFolder = tempname();
    mkdir(workFolder)
    workFolderCleanup = onCleanup(@() rmdir(workFolder, "s"));

    % Generate the core schema once and copy it into each extension's folder.
    coreFolder = fullfile(workFolder, "core");
    mkdir(coreFolder)
    evalc('generateCore("savedir", coreFolder)');

    for iExtension = 1:extensionCount
        extensionName = extensionNames(iExtension);
        fprintf("Installing %s (%d of %d)\n", extensionName, iExtension, extensionCount)

        try
            releaseVersions = matnwb.extension.internal.listPypiVersions(extensionName);
            results.ReleaseCount(iExtension) = numel(releaseVersions);
            latestRelease = matnwb.extension.internal.getPypiRelease(extensionName);
            results.LatestRelease(iExtension) = latestRelease.Version;
        catch ME
            results.Installation(iExtension) = "Failed: " + string(ME.message);
            continue
        end

        saveFolder = fullfile(workFolder, extensionName);
        copyfile(coreFolder, saveFolder)
        try
            evalc('matnwb.extension.installExtension(extensionName, "savedir", saveFolder)');
            results.Installation(iExtension) = "Installed";
        catch ME
            results.Installation(iExtension) = "Failed: " + string(ME.message);
        end
        rmdir(saveFolder, "s")
    end

    isFailed = startsWith(results.Installation, "Failed");
    report = createMarkdownReport(results, isFailed);
    fprintf("\n%s\n", report)
    if summaryFile ~= ""
        appendToFile(summaryFile, report)
    end

    if any(isFailed)
        error("NWB:ExtensionInstallationTest:InstallationFailed", ...
            "%d of %d extensions failed to install: %s.", ...
            nnz(isFailed), extensionCount, strjoin(results.Name(isFailed), ", "))
    end
end

function report = createMarkdownReport(results, isFailed)
    headerLines = [ ...
        "## Extension installation", ...
        "", ...
        sprintf("%d of %d extensions installed.", nnz(~isFailed), numel(isFailed)), ...
        "", ...
        "| Extension | Catalog version | Latest release | Releases on PyPI | Installation |", ...
        "|---|---|---|---|---|"];

    rowLines = strings(1, height(results));
    for iRow = 1:height(results)
        % A pipe or line break in an error message would break the table row.
        installation = replace(results.Installation(iRow), ["|", newline], ["\|", " "]);
        rowLines(iRow) = sprintf("| %s | %s | %s | %d | %s |", ...
            results.Name(iRow), results.CatalogVersion(iRow), results.LatestRelease(iRow), ...
            results.ReleaseCount(iRow), installation);
    end
    report = strjoin([headerLines, rowLines], newline) + newline;
end

function appendToFile(filePath, text)
    fileId = fopen(filePath, "a", "n", "UTF-8");
    fileCleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%s", text);
end
