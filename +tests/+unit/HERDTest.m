classdef (SharedTestFixtures = {tests.fixtures.SetEnvironmentVariableFixture}) ...
        HERDTest < tests.abstract.NwbTestCase
% HERDTest - Unit tests for the HERD external resources API.

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testAddRefRoundTrip(testCase)
            [nwb, table] = testCase.createFile(); %#ok<ASGLU>
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="Mus musculus", ...
                EntityId="NCBITaxon:10090", EntityUri="http://purl.obolibrary.org/obo/NCBITaxon_10090");
            nwb.general_external_resources = herd;

            filename = testCase.getRandomFilename();
            nwbExport(nwb, filename);
            readFile = nwbRead(filename, 'ignorecache');

            expected = herd.toTable();
            actual = readFile.general_external_resources.toTable();
            testCase.verifyEqual(actual, expected)
            testCase.verifyEqual(actual.key{1}, 'Mus musculus')
            testCase.verifyEqual(actual.entity_id{1}, 'NCBITaxon:10090')
            testCase.verifyEqual(actual.object_type{1}, 'Subject')
        end

        function testIndicesAreWrittenAsUnsignedIntegers(testCase)
            % The schema declares the cross-reference columns as `uint`, which
            % HDMF resolves to uint32.
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="Mus musculus", ...
                EntityId="NCBITaxon:10090", EntityUri="http://x/1");
            nwb.general_external_resources = herd;

            filename = testCase.getRandomFilename();
            nwbExport(nwb, filename);

            objectKeys = h5read(filename, '/general/external_resources/object_keys');
            testCase.verifyClass(objectKeys.objects_idx, 'uint32')
            testCase.verifyClass(objectKeys.keys_idx, 'uint32')
        end

        function testAddRefIsIdempotent(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            for i = 1:3
                herd.addRef(nwb, nwb.general_subject, Key="Mus musculus", ...
                    EntityId="NCBITaxon:10090", EntityUri="http://x/1");
            end
            testCase.verifyEqual(height(herd.toTable()), 1)
            testCase.verifyEqual(height(herd.keys.data), 1)
            testCase.verifyEqual(height(herd.object_keys.data), 1)
            testCase.verifyEqual(height(herd.entity_keys.data), 1)
        end

        function testKeysAreScopedToObject(testCase)
            % The same term used on two objects is stored once per object.
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="shared", ...
                EntityId="X:1", EntityUri="http://x/1");
            herd.addRef(nwb, table, Attribute="location", Key="shared", ...
                EntityId="X:1", EntityUri="http://x/1");

            testCase.verifyEqual(height(herd.keys.data), 2)
            testCase.verifyEqual(height(herd.objects.data), 2)
            testCase.verifyEqual(height(herd.entities.data), 1)
            testCase.verifyEqual(height(herd.toTable()), 2)
        end

        function testKeyResolvesToMultipleEntities(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="term", ...
                EntityId="X:1", EntityUri="http://x/1");
            herd.addRef(nwb, nwb.general_subject, Key="term", ...
                EntityId="Y:2", EntityUri="http://y/2");

            testCase.verifyEqual(height(herd.keys.data), 1)
            testCase.verifyEqual(height(herd.entities.data), 2)
            testCase.verifyEqual(height(herd.entity_keys.data), 2)
            testCase.verifyEqual(height(herd.toTable()), 2)
        end

        function testAddRefWithAttributeTargetsColumn(testCase)
            % An attribute naming a neurodata type annotates that object, so a
            % table column is recorded as the VectorData holding the values.
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, table, Attribute="location", Key="VISp", ...
                EntityId="MBA:385", EntityUri="http://mba/385");

            references = herd.toTable();
            testCase.verifyEqual(references.object_type{1}, 'VectorData')
            testCase.verifyEqual(references.object_id{1}, table.vectordata.get('location').object_id)
        end

        function testExistingEntityUriIsKept(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://original");

            testCase.verifyWarning( ...
                @() herd.addRef(nwb, nwb.general_subject, Key="b", ...
                    EntityId="X:1", EntityUri="http://different"), ...
                'NWB:HERD:EntityUriMismatch')
            testCase.verifyEqual(herd.entities.data.entity_uri{1}, 'http://original')
            testCase.verifyEqual(height(herd.entities.data), 1)
        end

        function testAddRefRequiresContainerInFile(testCase)
            nwb = testCase.createFile();
            orphan = types.core.Subject('subject_id', '999');
            testCase.verifyError( ...
                @() herdOf().addRef(nwb, orphan, Key="a", ...
                    EntityId="X:1", EntityUri="http://x"), ...
                'NWB:HERD:ContainerNotInFile')

            function herd = herdOf()
                herd = types.hdmf_common.HERD();
            end
        end

        function testAddRefRequiresKeyAndEntity(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            subject = nwb.general_subject;

            testCase.verifyError( ...
                @() herd.addRef(nwb, subject, EntityId="X:1", EntityUri="http://x"), ...
                'NWB:HERD:MissingKey')
            testCase.verifyError( ...
                @() herd.addRef(nwb, subject, Key="a"), ...
                'NWB:HERD:MissingEntityId')
            testCase.verifyError( ...
                @() herd.addRef(nwb, subject, Key="a", EntityId="BRAND:NEW"), ...
                'NWB:HERD:MissingEntityUri')
        end

        function testFailedAddRefLeavesTablesUnchanged(testCase)
            % A reference that cannot be completed must not half-write itself.
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");
            before = herd.toTable();

            testCase.verifyError( ...
                @() herd.addRef(nwb, nwb.general_subject, Key="new", EntityId="BRAND:NEW"), ...
                'NWB:HERD:MissingEntityUri')

            testCase.verifyEqual(herd.toTable(), before)
            testCase.verifyEqual(height(herd.keys.data), 1)
            testCase.verifyEqual(height(herd.objects.data), 1)
            testCase.verifyEqual(height(herd.entities.data), 1)
        end

        function testAddRefRejectsUnusableAttribute(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            subject = nwb.general_subject;

            testCase.verifyError( ...
                @() herd.addRef(nwb, subject, Attribute="not_a_property", ...
                    Key="a", EntityId="X:1", EntityUri="http://x"), ...
                'NWB:HERD:UnknownAttribute')
            % `species` holds text rather than a neurodata type. Referencing it
            % needs the relative path support that MatNWB does not have yet.
            testCase.verifyError( ...
                @() herd.addRef(nwb, subject, Attribute="species", ...
                    Key="a", EntityId="X:1", EntityUri="http://x"), ...
                'NWB:HERD:UnsupportedAttribute')
        end

        function testGetKeyReturnsEveryMatch(testCase)
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="shared", ...
                EntityId="X:1", EntityUri="http://x/1");
            herd.addRef(nwb, table, Attribute="location", Key="shared", ...
                EntityId="X:1", EntityUri="http://x/1");

            testCase.verifyEqual(height(herd.getKey("shared")), 2)
            testCase.verifyEmpty(herd.getKey("absent"))
        end

        function testGetEntity(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");

            entity = herd.getEntity("X:1");
            testCase.verifyEqual(height(entity), 1)
            testCase.verifyEqual(entity.entity_uri{1}, 'http://x/1')
            testCase.verifyEmpty(herd.getEntity("absent"))
        end

        function testGetObjectEntities(testCase)
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="Y:2", EntityUri="http://y/2");
            herd.addRef(nwb, table, Attribute="location", Key="VISp", ...
                EntityId="Z:3", EntityUri="http://z/3");

            entities = herd.getObjectEntities(nwb, nwb.general_subject);
            testCase.verifyEqual(height(entities), 2)
            testCase.verifyEqual(sort(entities.entity_id), {'X:1'; 'Y:2'})

            columnEntities = herd.getObjectEntities(nwb, table, Attribute="location");
            testCase.verifyEqual(height(columnEntities), 1)
            testCase.verifyEqual(columnEntities.entity_id{1}, 'Z:3')
        end

        function testGetObjectEntitiesRejectsUnannotatedObject(testCase)
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");
            testCase.verifyError( ...
                @() herd.getObjectEntities(nwb, nwb.scratch.get('mytable')), ...
                'NWB:HERD:ObjectNotFound')
        end

        function testGetObjectType(testCase)
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");
            herd.addRef(nwb, table, Attribute="location", Key="VISp", ...
                EntityId="Z:3", EntityUri="http://z/3");

            subjects = herd.getObjectType("Subject");
            testCase.verifyEqual(height(subjects), 1)
            testCase.verifyEqual(subjects.entity_id{1}, 'X:1')
            testCase.verifyEmpty(herd.getObjectType("TimeSeries"))
        end

        function testEmptyHerdRoundTrip(testCase)
            % A HERD without references still has to write its six tables.
            nwb = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="a", ...
                EntityId="X:1", EntityUri="http://x/1");
            for tableName = ["keys", "files", "entities", "objects", "object_keys", "entity_keys"]
                herd.(tableName).data(:, :) = [];
            end
            nwb.general_external_resources = herd;

            filename = testCase.getRandomFilename();
            nwbExport(nwb, filename);
            readFile = nwbRead(filename, 'ignorecache');

            testCase.verifyEmpty(readFile.general_external_resources.toTable())
            objectKeys = h5read(filename, '/general/external_resources/object_keys');
            testCase.verifyClass(objectKeys.objects_idx, 'uint32')
        end
    end

    methods (Test, TestTags = {'UsesPython'})
        function testPynwbReadsHerd(testCase)
            [nwb, table] = testCase.createFile();
            herd = types.hdmf_common.HERD();
            herd.addRef(nwb, nwb.general_subject, Key="Mus musculus", ...
                EntityId="NCBITaxon:10090", EntityUri="http://purl.obolibrary.org/obo/NCBITaxon_10090");
            herd.addRef(nwb, table, Attribute="location", Key="VISp", ...
                EntityId="MBA:385", EntityUri="http://mba/385");
            nwb.general_external_resources = herd;

            filename = testCase.getRandomFilename();
            nwbExport(nwb, filename);

            [pyNwbFile, pyNwbFileCleanup] = testCase.readNwbFileWithPynwb(filename); %#ok<ASGLU>
            pyHerd = pyNwbFile.get_external_resources();
            testCase.verifyEqual(double(py.len(pyHerd.keys)), 2)
            testCase.verifyEqual(double(py.len(pyHerd.entities)), 2)
            testCase.verifyEqual(double(py.len(pyHerd.objects)), 2)

            entities = pyHerd.get_object_entities(pyargs('container', pyNwbFile.subject));
            testCase.verifyEqual(double(py.len(entities)), 1)
        end
    end

    methods (Access = private)
        function [nwb, table] = createFile(~)
        % createFile - Build a file holding a subject and a one column table.
            nwb = NwbFile( ...
                'session_description', 'a test NWB File', ...
                'identifier', 'TEST123', ...
                'session_start_time', '2018-12-02T12:57:27.371444-08:00');
            nwb.general_subject = types.core.Subject( ...
                'subject_id', '001', 'species', 'Mus musculus');
            table = types.hdmf_common.DynamicTable( ...
                'description', 'a table with a location column', ...
                'colnames', {'location'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([0; 1])), ...
                'location', types.hdmf_common.VectorData( ...
                    'description', 'brain region', 'data', {'VISp'; 'VISp'}));
            nwb.scratch.set('mytable', table);
        end
    end
end
