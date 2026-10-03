function assumeZarr3Support(testCase)
% assumeZarr3Support - Skip the calling test unless Zarr v3 support is available.
%
% assumeZarr3Support(testCase) filters the calling test when the MATLAB
% release is older than zarr-matlab supports, or when the zarr-matlab or
% hdmf-zarr-matlab package is not on a discoverable path.
%
% See also tests.util.getZarr3DependencyPaths

    arguments
        testCase (1,1) matlab.unittest.TestCase
    end

    % Track the release zarr-matlab states it supports, not the oldest one
    % the tests happen to pass on. A release the dependency disclaims may
    % work today and stop working well within its own contract, which would
    % surface here as an unexplained MatNWB regression. Checked before the
    % packages, so an unsupported release reports itself as the reason.
    minimumRelease = "R2022b";
    testCase.assumeFalse(isMATLABReleaseOlderThan(minimumRelease), ...
        "zarr-matlab requires MATLAB " + minimumRelease + " or newer.")

    testCase.assumeTrue(all(strlength(tests.util.getZarr3DependencyPaths()) > 0), ...
        "zarr-matlab and hdmf-zarr-matlab packages not found (set ZARR3_MATLAB_PATH / " + ...
        "HDMF_ZARR_MATLAB_PATH or run matbox.installRequirements).")
end
