function wrapperPath = getZarrWrapperPath()
% getZarrWrapperPath - Resolve the path to the MathWorks Zarr wrapper.
%
%   wrapperPath = getZarrWrapperPath() returns the location of the MathWorks
%   Zarr wrapper (providing zarrinfo, zarrread, readZattrs). Resolution order:
%
%     1. The ZARR_WRAPPER_PATH environment variable, if set.
%     2. The default install location created by setup
%        (external_packages/MATLAB-support-for-Zarr-files).
%
%   Returns "" if no candidate folder exists, allowing callers to skip Zarr
%   tests gracefully.
%
%   See also setup

    wrapperPath = "";

    candidates = string.empty;
    envPath = string(getenv("ZARR_WRAPPER_PATH"));
    if strlength(envPath) > 0
        candidates(end+1) = envPath;
    end
    candidates(end+1) = fullfile(misc.getMatnwbDir(), ...
        "external_packages", "MATLAB-support-for-Zarr-files");

    for candidate = candidates
        if isfolder(candidate)
            wrapperPath = candidate;
            return
        end
    end
end
