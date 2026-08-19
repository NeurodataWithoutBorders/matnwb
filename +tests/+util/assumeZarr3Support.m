function assumeZarr3Support(testCase)
% assumeZarr3Support - Skip the calling test unless Zarr v3 support is available.
%
%   assumeZarr3Support(testCase) filters the calling test (via assumeTrue)
%   when the zarr-matlab or hdmf-zarr-matlab package is not on a
%   discoverable path.
%
%   See also tests.util.getZarr3DependencyPaths

    arguments
        testCase (1,1) matlab.unittest.TestCase
    end

    testCase.assumeTrue(all(strlength(tests.util.getZarr3DependencyPaths()) > 0), ...
        "zarr-matlab and hdmf-zarr-matlab packages not found (set ZARR3_MATLAB_PATH / " + ...
        "HDMF_ZARR_MATLAB_PATH or run matbox.installRequirements).")
end
