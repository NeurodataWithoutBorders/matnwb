function release = getPypiRelease(packageName, version)
% getPypiRelease - Get the download information for a release of a PyPI package.
%
%   release = matnwb.extension.internal.getPypiRelease(packageName, version)
%   returns a struct with the fields Name, Version, DownloadUrl, Filename
%   and Requirements (the "requires_dist" entries) for the given release
%   of a package on the Python Package Index (PyPI). version is a version
%   string such as "0.2.1", or "latest" for the newest release.
%
%   NWB extensions published on PyPI include their specification files.
%   The wheel is preferred; a source distribution is used when a release
%   has no wheel.

    arguments
        packageName (1,1) string
        version (1,1) string = "latest"
    end

    if version == "latest"
        metadataUrl = sprintf("https://pypi.org/pypi/%s/json", packageName);
    else
        metadataUrl = sprintf("https://pypi.org/pypi/%s/%s/json", packageName, version);
    end

    try
        metadata = webread(metadataUrl, weboptions("ContentType", "json"));
    catch ME
        if strcmp(ME.identifier, "MATLAB:webservices:HTTP404StatusCodeError")
            throwNotFoundError(packageName, version)
        end
        rethrow(ME)
    end

    files = metadata.urls;
    if iscell(files)
        files = [files{:}];
    end
    isWheel = strcmp({files.packagetype}, "bdist_wheel");
    isSourceDistribution = strcmp({files.packagetype}, "sdist");
    if any(isWheel)
        selectedFile = files(find(isWheel, 1));
    elseif any(isSourceDistribution)
        selectedFile = files(find(isSourceDistribution, 1));
    else
        error("NWB:InstallExtension:NoDownloadableFile", ...
            "Release %s of ""%s"" on PyPI has no wheel or source distribution to download.", ...
            metadata.info.version, packageName)
    end

    requiresDist = metadata.info.requires_dist;
    if isempty(requiresDist)
        requiresDist = strings(1, 0);
    end

    release = struct( ...
        "Name", packageName, ...
        "Version", string(metadata.info.version), ...
        "DownloadUrl", string(selectedFile.url), ...
        "Filename", string(selectedFile.filename), ...
        "Requirements", reshape(string(requiresDist), 1, []));
end

function throwNotFoundError(packageName, version)
    availableVersions = matnwb.extension.internal.listPypiVersions(packageName);
    if isempty(availableVersions)
        error("NWB:InstallExtension:PackageNotFound", ...
            "No package named ""%s"" was found on PyPI.", packageName)
    end
    error("NWB:InstallExtension:VersionNotFound", ...
        "Version %s of ""%s"" was not found on PyPI. Available versions: %s.", ...
        version, packageName, strjoin(availableVersions, ", "))
end
