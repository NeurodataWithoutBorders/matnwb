function ensureAvailable()
% ensureAvailable - Validate that the zarr-matlab package is on path.
%
% See also: https://github.com/catalystneuro/zarr-matlab

    persistent isValidated

    if isequal(isValidated, true)
        return
    end

    % `exist(name, "file")` does not reliably resolve dotted package-function
    % names (it returns 0 even when the function is on the path), so
    % availability is checked with `which` instead.
    requiredFunctions = ["zarr.open", "zarr.create", "zarr.create_group"];
    isMissing = arrayfun(@(name) isempty(which(name)), requiredFunctions);

    if any(isMissing)
        error("NWB:Zarr3:DependencyMissing", ...
            "The `zarr-matlab` package is required on the MATLAB path. Missing function(s): %s", ...
            strjoin(requiredFunctions(isMissing), ", "))
    end

    isValidated = true;
end
