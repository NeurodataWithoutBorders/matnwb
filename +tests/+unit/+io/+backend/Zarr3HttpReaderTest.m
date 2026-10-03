classdef Zarr3HttpReaderTest < matlab.unittest.TestCase
% Zarr3HttpReaderTest - Read the Zarr v3 fixture store over HTTP.
%
% The fixture folder is served by tests.fixtures.HttpServerFixture, and the
% store is read from its URL. Zarr3ReaderTest covers what is read; this class
% covers the parts that differ when the store is a URL: backend detection,
% opening nodes through an HTTP store, partial reads with Range requests, and
% resolving a relative external link against a URL.

    properties (Access = private)
        StoreUrl (1,1) string
        Server
    end

    methods (TestClassSetup)
        function serveFixtureStore(testCase)
            tests.util.assumeZarr3Support(testCase)

            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.TemporaryFolderFixture

            testCase.applyFixture(PathFixture(tests.util.getZarr3DependencyPaths()));
            folderFixture = testCase.applyFixture(TemporaryFolderFixture);
            tests.fixtures.createZarr3TestFile(folderFixture.Folder);

            testCase.Server = testCase.applyFixture( ...
                tests.fixtures.HttpServerFixture(folderFixture.Folder));
            testCase.StoreUrl = testCase.Server.BaseUrl + "/fixture.zarr";
        end
    end

    methods (Test)
        function backendFactoryRecognisesStoreUrl(testCase)
            reader = io.backend.BackendFactory.createReader(testCase.StoreUrl);

            testCase.verifyClass(reader, "io.backend.zarr3.Zarr3Reader");
        end

        function detectingStoreUrlRequestsOnlyItsRootMetadata(testCase)
        % isfile is true for a store URL that the server redirects to a
        % folder listing, so detection that tried HDF5 first would request
        % the store folder and pass the URL to H5F.open.
            requestsBefore = numel(testCase.Server.readRequestLog());

            io.backend.BackendFactory.createReader(testCase.StoreUrl);

            requests = testCase.Server.readRequestLog();
            testCase.verifyEqual(requests(requestsBefore+1:end), ...
                "200 /fixture.zarr/zarr.json");
        end

        function urlWithoutStoreIsRejected(testCase)
            missingUrl = testCase.Server.BaseUrl + "/missing.zarr";

            testCase.verifyError(@() io.backend.BackendFactory.createReader(missingUrl), ...
                "NWB:BackendFactory:UnsupportedFormat");
        end

        function readsRootAndLinksOverHttp(testCase)
        % Browsing the hierarchy of a store that cannot be listed works
        % through its consolidated metadata.
            reader = io.backend.zarr3.Zarr3Reader(testCase.StoreUrl);

            testCase.verifyEqual(reader.getSchemaVersion(), "2.7.0");
            testCase.verifyEqual(reader.getEmbeddedSpecLocation(), "/specifications");
            nodeInfo = reader.readNodeInfo("/general/extracellular_ephys/shank0");
            testCase.verifyEqual(nodeInfo.Links(1).Name, 'device');
        end

        function readsDataStubPartiallyWithRangeRequests(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.StoreUrl);
            datasetInfo = reader.readNodeInfo("/acquisition/es/data");
            dataStub = reader.readDatasetValue(datasetInfo, "/acquisition/es/data");
            expected = reshape(single(1:116), [4 29]);

            testCase.verifyClass(dataStub, "types.untyped.DataStub");
            testCase.verifyEqual(dataStub(2, 3:5), expected(2, 3:5));
            testCase.verifyEqual(dataStub.load(), expected);
        end

        function readsReferencesOverHttp(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.StoreUrl);
            columnPath = "/general/extracellular_ephys/electrodes/group";
            datasetInfo = reader.readNodeInfo(columnPath);

            references = reader.readDatasetValue(datasetInfo, columnPath);

            testCase.verifyTrue(all(string({references.path}) == "/general/extracellular_ephys/shank0"));
        end

        function externalLinkBaseIsTheStoreUrl(testCase)
            reader = io.backend.zarr3.Zarr3Reader(testCase.StoreUrl + "/");

            testCase.verifyEqual(reader.getExternalLinkBase(), testCase.StoreUrl);
        end

        function relativeExternalLinkResolvesAgainstStoreUrl(testCase)
        % hdmf-zarr writes a relative source against the store path, so
        % "../external_target.zarr" names a sibling of the store on the same
        % server, which must be fetched over HTTP too.
            reader = io.backend.zarr3.Zarr3Reader(testCase.StoreUrl);
            nodeInfo = reader.readNodeInfo("/scratch");
            record = nodeInfo.Links(strcmp({nodeInfo.Links.Name}, 'linked_data_relative'));
            link = types.untyped.ExternalLink(record.Value{1}, record.Value{2}, ...
                reader.getExternalLinkBase());

            target = link.deref();

            testCase.verifyClass(target, "types.untyped.DataStub");
            testCase.verifyEqual(target.load(), int64([7; 8; 9]));
            requests = testCase.Server.readRequestLog();
            testCase.verifyTrue(any(startsWith(requests, "200 /external_target.zarr/")), ...
                "The linked store was not read from the server.");
        end
    end
end
