classdef DecodeObjectReferencesTest < matlab.unittest.TestCase
% DecodeObjectReferencesTest - Unit tests for
% io.internal.zarr3.decodeObjectReferences.
%
% The in-store decoding paths are exercised through Zarr3ReaderTest and
% Zarr3LazyArrayTest; this class covers the rejection of references that
% cannot become a types.untyped.ObjectView.

    methods (TestClassSetup)
        function setupDependencyPaths(testCase)
            tests.util.assumeZarr3Support(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                tests.util.getZarr3DependencyPaths()));
        end
    end

    methods (Test)
        function externalReferenceIsRejected(testCase)
        % types.untyped.ObjectView can only address nodes within the file
        % being read, so a reference whose source names another store must
        % be rejected rather than silently mis-resolved.
            externalRecord = string(jsonencode(struct(...
                'source', 'other_session.nwb.zarr', ...
                'path', '/acquisition/es')));

            testCase.verifyError(...
                @() io.internal.zarr3.decodeObjectReferences(externalRecord), ...
                "NWB:Zarr3:UnsupportedExternalReference");
        end
    end
end
