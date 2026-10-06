function versions = listPypiVersions(packageName, options)
% listPypiVersions - List the released versions of a package on PyPI.
%
%   versions = matnwb.extension.internal.listPypiVersions(packageName)
%   returns the versions of the package as a string array, or an empty
%   array when PyPI has no package with that name.
%
%   versions = matnwb.extension.internal.listPypiVersions(packageName, Timeout=seconds)
%   waits at most the given number of seconds for PyPI to answer. The
%   default is 5 seconds.
%
%   The JSON form of the PyPI simple index lists versions as an array.
%   The release list of the JSON API is keyed by version, which webread
%   would turn into struct field names.

    arguments
        packageName (1,1) string
        options.Timeout (1,1) double {mustBePositive} = 5
    end

    simpleIndexUrl = sprintf("https://pypi.org/simple/%s/", packageName);
    requestOptions = weboptions("ContentType", "json", "Timeout", options.Timeout, ...
        "HeaderFields", ["Accept", "application/vnd.pypi.simple.v1+json"]);
    try
        index = webread(simpleIndexUrl, requestOptions);
        versions = string(index.versions);
    catch ME
        if strcmp(ME.identifier, "MATLAB:webservices:HTTP404StatusCodeError")
            versions = strings(0, 1);
        else
            rethrow(ME)
        end
    end
end
