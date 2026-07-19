function assumeZarr3Support(testCase)
% assumeZarr3Support - Skip the calling test unless Zarr v3 support is available.
%
%   assumeZarr3Support(testCase) filters the calling test (via assumeTrue)
%   when the zarr-matlab package is not on a discoverable path.
%
%   See also tests.util.getZarr3MatlabPath

    arguments
        testCase (1,1) matlab.unittest.TestCase
    end

    testCase.assumeTrue(strlength(tests.util.getZarr3MatlabPath()) > 0, ...
        "zarr-matlab package not found (set ZARR3_MATLAB_PATH or run setup).")
end
