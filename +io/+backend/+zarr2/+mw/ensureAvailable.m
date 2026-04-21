function ensureAvailable()
% ensureAvailable - Validate that the MathWorks Zarr wrapper is on path.

    persistent isValidated

    if isequal(isValidated, true)
        return
    end

    requiredFunctions = ["zarrinfo", "zarrread", "readZattrs"];
    isMissing = arrayfun(@(name) exist(name, "file") == 0, requiredFunctions);

    if any(isMissing)
        error("NWB:Zarr2:DependencyMissing", ...
            "The MathWorks Zarr wrapper is required on the MATLAB path. Missing function(s): %s", ...
            strjoin(requiredFunctions(isMissing), ", "))
    end

    isValidated = true;
end
