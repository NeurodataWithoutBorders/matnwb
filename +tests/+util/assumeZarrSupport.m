function assumeZarrSupport(testCase)
% assumeZarrSupport - Skip the calling test unless Zarr support is available.
%
%   assumeZarrSupport(testCase) filters the calling test (via assumeTrue)
%   when the prerequisites for the Zarr v2 reader tests are missing:
%
%     * the MathWorks Zarr wrapper is not on a discoverable path, or
%     * the Python package `tensorstore` (required to read Zarr stores) or
%       `hdmf_zarr` (required to generate the test fixture) is not installed.
%
%   See also tests.util.getZarrWrapperPath, tests.util.isPythonModuleAvailable

    arguments
        testCase (1,1) matlab.unittest.TestCase
    end

    testCase.assumeTrue(strlength(tests.util.getZarrWrapperPath()) > 0, ...
        "MathWorks Zarr wrapper not found (set ZARR_WRAPPER_PATH or run setup).")
    testCase.assumeTrue(tests.util.isPythonModuleAvailable("tensorstore"), ...
        "Python package `tensorstore` is required to read Zarr stores.")
    testCase.assumeTrue(tests.util.isPythonModuleAvailable("hdmf_zarr"), ...
        "Python package `hdmf_zarr` is required to generate the Zarr test fixture.")
end
