function versions = listPypiVersions(packageName)
% listPypiVersions - List the released versions of a package on PyPI.
%
%   versions = matnwb.extension.internal.listPypiVersions(packageName)
%   returns the versions of the package as a string array, or an empty
%   array when PyPI has no package with that name.
%
%   The JSON form of the PyPI simple index lists versions as an array.
%   The release list of the JSON API is keyed by version, which webread
%   would turn into struct field names.

    arguments
        packageName (1,1) string
    end

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
