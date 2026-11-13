function namespaceFilePath = downloadRelease(release, targetRoot)
% downloadRelease - Download a release of an extension and locate its namespace file.
%
%   namespaceFilePath = matnwb.extension.internal.downloadRelease(release, targetRoot)
%   downloads the file described by release (see getPypiRelease), extracts
%   it into targetRoot/<name>-<version>, and returns the path of the
%   extension's namespace file. A release that was downloaded before is not
%   downloaded again, because the files of a published release do not change.

    arguments
        release (1,1) struct
        targetRoot (1,1) string
    end

    releaseFolder = fullfile(targetRoot, release.Name + "-" + release.Version);
    namespaceFilePath = findNamespaceFile(releaseFolder);
    if namespaceFilePath ~= ""
        return
    end

    downloadPath = fullfile(tempdir, release.Filename);
    websave(downloadPath, release.DownloadUrl);
    downloadCleanup = onCleanup(@() delete(downloadPath));

    if ~isfolder(releaseFolder)
        mkdir(releaseFolder)
    end
    if endsWith(release.Filename, [".tar.gz", ".tgz"])
        untar(downloadPath, releaseFolder);
    else
        % Wheels (.whl) are zip archives.
        unzip(downloadPath, releaseFolder);
    end

    namespaceFilePath = findNamespaceFile(releaseFolder);
    assert(namespaceFilePath ~= "", ...
        "NWB:InstallExtension:NamespaceNotFound", ...
        "No namespace file was found in release %s of extension ""%s"".", ...
        release.Version, release.Name)
end

function namespaceFilePath = findNamespaceFile(releaseFolder)
% findNamespaceFile - Find the namespace file of an extension, or "" if there is none.
%
%   A source distribution can hold the specification twice: in a spec
%   folder at its root and inside the Python package. The copy closest to
%   the root is used.

    namespaceFilePath = "";
    if ~isfolder(releaseFolder)
        return
    end
    fileList = dir(fullfile(releaseFolder, "**", "*namespace.yaml"));
    if isempty(fileList)
        return
    end
    filePaths = string(fullfile({fileList.folder}, {fileList.name}));
    [~, shortestIndex] = min(strlength(filePaths));
    namespaceFilePath = filePaths(shortestIndex);
end
