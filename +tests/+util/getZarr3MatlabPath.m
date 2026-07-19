function packagePath = getZarr3MatlabPath()
% getZarr3MatlabPath - Resolve the path to the zarr-matlab package.
%
%   packagePath = getZarr3MatlabPath() returns the location of the
%   zarr-matlab package (providing the `zarr` namespace used by
%   io.backend.zarr3.Zarr3Reader / Zarr3Writer: zarr.open, zarr.create,
%   zarr.create_group, ...). Resolution order:
%
%     1. Already resolvable on the MATLAB path (e.g. installed by
%        matbox.installRequirements, which places it in an add-ons folder
%        outside this repo and adds it to the path directly).
%     2. The ZARR3_MATLAB_PATH environment variable, if set.
%     3. The default install location created by setup
%        (external_packages/zarr-matlab).
%
%   Returns "" if no candidate folder exists, allowing callers to skip
%   Zarr v3 tests gracefully.
%
%   See also setup

    packagePath = "";

    % `exist(name, "file")` does not reliably resolve dotted package-function
    % names (see io.backend.zarr3.internal.ensureAvailable), so `which` is
    % used instead. zarr.open.m lives at <packageRoot>/+zarr/open.m.
    zarrOpenLocation = which("zarr.open");
    if ~isempty(zarrOpenLocation)
        packagePath = string(fileparts(fileparts(zarrOpenLocation)));
        return
    end

    candidates = string.empty;
    envPath = string(getenv("ZARR3_MATLAB_PATH"));
    if strlength(envPath) > 0
        candidates(end+1) = envPath;
    end
    candidates(end+1) = fullfile(misc.getMatnwbDir(), ...
        "external_packages", "zarr-matlab");

    for candidate = candidates
        if isfolder(fullfile(candidate, "+zarr"))
            packagePath = candidate;
            return
        end
    end
end
