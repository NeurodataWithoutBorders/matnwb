classdef EnsureAvailableTest < matlab.unittest.TestCase
% EnsureAvailableTest - Unit test for io.backend.zarr3.internal.ensureAvailable.

    methods (Test)
        function missingDependencyErrorNamesThePackage(testCase)
        % ensureAvailable caches a successful validation in a persistent
        % variable, so provoking the missing-dependency error takes both
        % hiding a dependency from the path and clearing the function.
            tests.util.assumeZarr3Support(testCase)
            dependencyPaths = tests.util.getZarr3DependencyPaths();
            testCase.applyFixture(...
                matlab.unittest.fixtures.PathFixture(dependencyPaths));

            hdmfZarrRoot = dependencyPaths(2);
            rmpath(hdmfZarrRoot);
            testCase.addTeardown(@addpath, hdmfZarrRoot);

            % Reset the persistent validation cache, and leave it reset on
            % teardown so later tests revalidate against the restored path.
            clear ensureAvailable
            testCase.addTeardown(@clear, "ensureAvailable");

            % If some other path entry still resolves the package, the
            % error cannot fire; skip rather than fail in that environment.
            testCase.assumeTrue(isempty(which("hdmf.zarr.Reference")), ...
                "hdmf.zarr is still resolvable after removing its root from the path.")

            testCase.verifyError(...
                @() io.backend.zarr3.internal.ensureAvailable(), ...
                "NWB:Zarr3:DependencyMissing");
        end
    end
end
