function release = getPypiRelease(packageName, version)
% getPypiRelease - Get the download information for a release of a PyPI package.
%
%   release = matnwb.extension.internal.getPypiRelease(packageName, version)
%   returns a struct with the fields Name, Version, DownloadUrl and
%   Filename for the given release of a package on the Python Package Index
%   (PyPI). version is a version string such as "0.2.1", or "latest" for
%   the newest release.
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

    release = struct( ...
        "Name", packageName, ...
        "Version", string(metadata.info.version), ...
        "DownloadUrl", string(selectedFile.url), ...
        "Filename", string(selectedFile.filename));
end

function throwNotFoundError(packageName, version)
    availableVersions = listPypiVersions(packageName);
    if isempty(availableVersions)
        error("NWB:InstallExtension:PackageNotFound", ...
            "No package named ""%s"" was found on PyPI.", packageName)
    end
    error("NWB:InstallExtension:VersionNotFound", ...
        "Version %s of ""%s"" was not found on PyPI. Available versions: %s.", ...
        version, packageName, strjoin(availableVersions, ", "))
end

function versions = listPypiVersions(packageName)
% listPypiVersions - List the released versions of a package, or none if it does not exist.
%
%   The JSON form of the PyPI simple index lists versions as an array.
%   The release list of the JSON API is keyed by version, which webread
%   would turn into struct field names.

    simpleIndexUrl = sprintf("https://pypi.org/simple/%s/", packageName);
    options = weboptions("ContentType", "json", ...
        "HeaderFields", ["Accept", "application/vnd.pypi.simple.v1+json"]);
    try
        index = webread(simpleIndexUrl, options);
        versions = string(index.versions);
    catch ME
        if strcmp(ME.identifier, "MATLAB:webservices:HTTP404StatusCodeError")
            versions = strings(0, 1);
        else
            rethrow(ME)
        end
    end
end
