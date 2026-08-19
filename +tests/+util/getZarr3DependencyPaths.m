function packagePaths = getZarr3DependencyPaths()
% getZarr3DependencyPaths - Resolve the external packages the Zarr v3 backend needs.
%
%   packagePaths = getZarr3DependencyPaths() returns a string array with the
%   root folder of each external MATLAB package used by
%   io.backend.zarr3.Zarr3Reader (see io.backend.zarr3.internal.ensureAvailable):
%
%     1. zarr-matlab      - the `zarr` namespace
%     2. hdmf-zarr-matlab - the `hdmf.zarr` namespace (hdmf-zarr conventions)
%
%   Each package is resolved in this order:
%
%     1. Already resolvable on the MATLAB path (e.g. installed by
%        matbox.installRequirements, which places it in an add-ons folder
%        outside this repo and adds it to the path directly).
%     2. An environment variable, if set: ZARR3_MATLAB_PATH for zarr-matlab,
%        HDMF_ZARR_MATLAB_PATH for hdmf-zarr-matlab.
%     3. The default install location under external_packages/<package>.
%
%   An entry is "" if that package could not be found, allowing callers to
%   skip Zarr v3 tests gracefully (see tests.util.assumeZarr3Support).
%   Found entries can be passed directly to
%   matlab.unittest.fixtures.PathFixture.

    packagePaths = [...
        resolvePackagePath("zarr.open", "ZARR3_MATLAB_PATH", "zarr-matlab"), ...
        resolvePackagePath("hdmf.zarr.open", "HDMF_ZARR_MATLAB_PATH", "hdmf-zarr-matlab")];
end

function packagePath = resolvePackagePath(probeFunction, environmentVariable, folderName)
% resolvePackagePath - Locate one package root; "" if not found.
%   probeFunction is a dotted package function whose file lives at
%   <packageRoot>/+a/+b/name.m; its location on the path, if any, is
%   walked up to the package root.

    packagePath = "";

    % `exist(name, "file")` does not reliably resolve dotted package-function
    % names (see io.backend.zarr3.internal.ensureAvailable), so `which` is
    % used instead.
    probeLocation = which(probeFunction);
    if ~isempty(probeLocation)
        packagePath = string(fileparts(probeLocation));
        numPackageLevels = count(probeFunction, ".");
        for iLevel = 1:numPackageLevels
            packagePath = string(fileparts(packagePath));
        end
        return
    end

    candidates = string.empty;
    envPath = string(getenv(environmentVariable));
    if strlength(envPath) > 0
        candidates(end+1) = envPath;
    end
    candidates(end+1) = fullfile(misc.getMatnwbDir(), "external_packages", folderName);

    topLevelNamespace = "+" + extractBefore(probeFunction, ".");
    for candidate = candidates
        if isfolder(fullfile(candidate, topLevelNamespace))
            packagePath = candidate;
            return
        end
    end
end
