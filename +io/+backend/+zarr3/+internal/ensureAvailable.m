function ensureAvailable()
% ensureAvailable - Validate that Zarr v3 backend dependencies are on path.
%
% The Zarr v3 backend needs two external MATLAB packages, both listed in
% requirements.txt and installable with matbox.installRequirements:
%
% zarr-matlab      - the `zarr` namespace (Zarr v3 stores, arrays, groups),
%                      from github.com/catalystneuro/zarr-matlab
% hdmf-zarr-matlab - the `hdmf.zarr` namespace (hdmf-zarr's link, object
%                      reference and cached-specification conventions), from
%                      github.com/catalystneuro/hdmf-zarr-matlab
%
% Raises NWB:Zarr3:DependencyMissing naming the package and the functions that
% could not be resolved.
%
% See also:
% io.backend.zarr3.Zarr3Reader, io.backend.BackendFactory

    persistent isValidated

    if isequal(isValidated, true)
        return
    end

    requiredPackages = struct(...
        'Name', {"zarr-matlab", "hdmf-zarr-matlab"}, ...
        'Functions', {...
            ["zarr.open", "zarr.create", "zarr.create_group"], ...
            ["hdmf.zarr.open", "hdmf.zarr.Reference", "hdmf.zarr.Link", "hdmf.zarr.isReferenceArray"]});

    for iPackage = 1:numel(requiredPackages)
        package = requiredPackages(iPackage);
        % `exist(name, "file")` does not reliably resolve dotted package
        % names (it returns 0 even when the function or class is on the
        % path), so availability is checked with `which` instead.
        isMissing = arrayfun(@(name) isempty(which(name)), package.Functions);
        if any(isMissing)
            error("NWB:Zarr3:DependencyMissing", ...
                "The `%s` package is required on the MATLAB path. Missing: %s", ...
                package.Name, strjoin(package.Functions(isMissing), ", "))
        end
    end

    isValidated = true;
end
