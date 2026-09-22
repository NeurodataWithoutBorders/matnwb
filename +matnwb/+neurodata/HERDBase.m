classdef (Abstract) HERDBase < handle & matlab.mixin.CustomDisplay
% HERDBase - Non-generated base class for HERD behavior.
%
% This class owns handwritten HERD (HDMF External Resources Data Structure)
% behavior that the generated schema class cannot express: adding external
% resource references and querying them back.
%
% A HERD records that a term used somewhere in an NWB file corresponds to an
% entity in an external resource, such as an ontology. The associations are
% held in six tables that reference each other by row index:
%
%   keys         The term as used in the file, e.g. "Mus musculus".
%   entities     The external term: an identifier and the URI it resolves to.
%   files        The object id of each file that holds an annotated object.
%   objects      The annotated object and the file it belongs to.
%   object_keys  Which objects use which keys.
%   entity_keys  Which keys resolve to which entities.
%
% Row indices are stored zero-based to match HDMF and PyNWB. They are
% converted to and from MATLAB one-based indexing inside this class, so no
% method here takes or returns a zero-based index.
%
% Keys are scoped to an object rather than shared across the file: the same
% term used on two different objects is stored as two key rows, matching
% HDMF. A single key may resolve to more than one entity.
%
% Note: Method names mirror the HDMF/PyNWB HERD API
%
% NwbFile.addRef and NwbFile.getExternalResources are the usual entry
% points: they lazily attach and reuse the one HERD a file may hold.
%
% See also:
%   NwbFile.addRef
%   NwbFile.getExternalResources
%   types.hdmf_common.HERD

    properties (Abstract)
        keys
        files
        entities
        objects
        object_keys
        entity_keys
    end

    properties (Constant, Access = private)
        TableNames = ["keys", "files", "entities", "objects", "object_keys", "entity_keys"]
    end

    methods
        function addRef(obj, file, container, options)
        % addRef - Record that an object in a file refers to an external entity.
        %
        % NwbFile.addRef calls this method and is the more convenient way to
        % add a reference when working from the file. Call this method
        % directly when working with the HERD object itself, for example
        % before it has been assigned to a file.
        %
        % Syntax:
        %  herd.addRef(file, container, EntityId=entityId, EntityUri=entityUri)
        %  records that container, which belongs to file, refers to the
        %  external entity identified by entityId.
        %
        %  herd.addRef(__, Attribute=attribute) attaches the reference to a
        %  neurodata object held by container rather than to container itself,
        %  for example a column of a DynamicTable.
        %
        % Input Arguments:
        %  - file (NwbFile) -
        %    The file that container belongs to.
        %
        %  - container -
        %    The neurodata object the reference is attached to, for example a
        %    types.core.Subject or a column of a table.
        %
        % Name-Value Arguments:
        %  - EntityId (string) -
        %    Identifier of the entity in the external resource, given as a
        %    compact URI (CURIE) of the form prefix:identifier, for example
        %    "NCBITaxon:10090".
        %
        %  - EntityUri (string) -
        %    The URL that EntityId resolves to. Required the first time an
        %    entity is added; ignored afterwards, since the stored URI is kept.
        %
        %  - Key (string) -
        %    The term as it is used in the file, for example "Mus musculus".
        %
        %  - Attribute (string) -
        %    Name of a property of container holding the neurodata object the
        %    reference belongs to. Only properties that are themselves
        %    neurodata types are supported, such as a column of a table.
        %
        %  - Field (string) -
        %    Field of a compound data type the reference applies to. Leave
        %    unset unless the target is a compound dataset.
        %
        % Usage:
        %  Example 1 - Annotate a subject's species::
        %
        %    herd.addRef(nwb, nwb.general_subject, ...
        %        Key="Mus musculus", ...
        %        EntityId="NCBITaxon:10090", ...
        %        EntityUri="http://purl.obolibrary.org/obo/NCBITaxon_10090")
        %
        %  Example 2 - Annotate a column of a table::
        %
        %    herd.addRef(nwb, nwb.general_extracellular_ephys_electrodes, ...
        %        Attribute="location", Key="VISp", ...
        %        EntityId="MBA:385", ...
        %        EntityUri="https://purl.brain-bican.org/ontology/mbao/MBA_385")

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
                file (1,1) NwbFile
                container {matnwb.common.validation.mustBeNeurodataObject}
                options.EntityId (1,1) string = ""
                options.EntityUri (1,1) string = ""
                options.Key (1,1) string = ""
                options.Attribute (1,1) string = ""
                options.Field (1,1) string = ""
            end

            if strlength(options.EntityId) == 0
                error('NWB:HERD:MissingEntityId', ...
                    ['An external reference needs an EntityId. Provide the ', ...
                    'identifier of the entity in the external resource, for ', ...
                    'example EntityId="NCBITaxon:10090".'])
            end

            if strlength(options.Key) == 0
                error('NWB:HERD:MissingKey', ...
                    ['An external reference needs a Key. Provide the term as it ', ...
                    'is used in the file, for example Key="Mus musculus".'])
            end
            keyName = options.Key;

            [target, relativePath] = obj.resolveTarget(container, options.Attribute);
            obj.assertContainerInFile(file, target)
            obj.ensureTablesInitialized()

            % Resolve the entity before anything is written, so a reference that
            % cannot be completed leaves the tables untouched.
            entityTable = obj.getTable("entities");
            entityRow = find(strcmp(entityTable.entity_id, char(options.EntityId)), 1);
            if isempty(entityRow)
                if strlength(options.EntityUri) == 0
                    error('NWB:HERD:MissingEntityUri', ...
                        ['Entity "%s" is not in this HERD yet, so it needs an ', ...
                        'EntityUri. Provide the URL the identifier resolves to, ', ...
                        'which can be looked up at https://bioregistry.io/%s'], ...
                        options.EntityId, options.EntityId)
                end
            else
                storedUri = entityTable.entity_uri{entityRow};
                if strlength(options.EntityUri) > 0 && ~strcmp(storedUri, options.EntityUri)
                    warning('NWB:HERD:EntityUriMismatch', ...
                        ['Entity "%s" is already stored with the URI "%s", so the ', ...
                        'URI "%s" was ignored. Remove one of the two references if ', ...
                        'they were meant to be different entities.'], ...
                        options.EntityId, storedUri, options.EntityUri)
                end
            end

            % The file is part of an object's identity because object ids are not
            % unique across files: a file can be copied and edited while keeping
            % its object ids, so the same id may appear under a different file.
            fileRow = obj.findOrAddRow("files", {file.object_id});
            objectRow = obj.findOrAddRow("objects", ...
                obj.createObjectRowValues(fileRow, target, relativePath, options.Field));

            keyRow = obj.findKeyForObject(keyName, objectRow);
            if isempty(keyRow)
                keyRow = obj.appendRow("keys", {char(keyName)});
            end
            obj.findOrAddRow("object_keys", {uint32(objectRow - 1), uint32(keyRow - 1)});

            if isempty(entityRow)
                entityRow = obj.appendRow("entities", ...
                    {char(options.EntityId), char(options.EntityUri)});
            end
            obj.findOrAddRow("entity_keys", {uint32(entityRow - 1), uint32(keyRow - 1)});
        end

        function entity = getEntity(obj, entityId)
        % getEntity - Get the entity stored under an identifier.
        %
        % Syntax:
        %  entity = herd.getEntity(entityId) returns the entity stored for
        %  entityId.
        %
        % Input Arguments:
        %  - entityId (string) -
        %    Identifier of the entity in the external resource, for example
        %    "NCBITaxon:10090".
        %
        % Output Arguments:
        %  - entity (table) -
        %    A one-row table with the entity_id and entity_uri stored for
        %    entityId, or a table with no rows if the identifier is not in
        %    this HERD.

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
                entityId (1,1) string
            end

            entityTable = obj.getTable("entities");
            rowIndex = find(strcmp(entityTable.entity_id, char(entityId)), 1);
            entity = entityTable(rowIndex, :);
        end

        function keys = getKey(obj, keyName)
        % getKey - Get the keys stored under a term.
        %
        % Syntax:
        %  keys = herd.getKey(keyName) returns the key rows matching keyName.
        %
        % Input Arguments:
        %  - keyName (string) -
        %    The term as it is used in the file, for example "Mus musculus".
        %
        % Output Arguments:
        %  - keys (table) -
        %    The key rows whose key equals keyName. The same term used on
        %    different objects is stored once per object, so this can hold
        %    more than one row.

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
                keyName (1,1) string
            end

            keyTable = obj.getTable("keys");
            keys = keyTable(strcmp(keyTable.key, keyName), :);
        end

        function entities = getObjectEntities(obj, file, container, options)
        % getObjectEntities - Get the entities annotated on a single object.
        %
        % Syntax:
        %  entities = herd.getObjectEntities(file, container) returns the
        %  entities annotated on container. An object with no references
        %  stored raises an error rather than returning an empty table.
        %
        %  entities = herd.getObjectEntities(__, Attribute=attribute) resolves
        %  the target the same way addRef does, so a reference added with an
        %  attribute is retrieved with the same attribute.
        %
        % Input Arguments:
        %  - file (NwbFile) -
        %    The file that container belongs to.
        %
        %  - container -
        %    The annotated neurodata object, for example a types.core.Subject.
        %
        % Name-Value Arguments:
        %  - Attribute (string) -
        %    Name of a property of container holding the annotated object, as
        %    in addRef.
        %
        %  - Field (string) -
        %    Field of a compound data type the reference applies to, as in
        %    addRef.
        %
        % Output Arguments:
        %  - entities (table) -
        %    One row per entity annotated on the object, with the entity_id
        %    and entity_uri columns of the entities table.

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
                file (1,1) NwbFile
                container {matnwb.common.validation.mustBeNeurodataObject}
                options.Attribute (1,1) string = ""
                options.Field (1,1) string = ""
            end

            [target, relativePath] = obj.resolveTarget(container, options.Attribute);
            fileRow = obj.findRowInTable(obj.getTable("files"), {file.object_id});
            objectRow = [];
            if ~isempty(fileRow)
                objectRow = obj.findRowInTable(obj.getTable("objects"), ...
                    obj.createObjectRowValues(fileRow, target, relativePath, options.Field));
            end
            if isempty(objectRow)
                error('NWB:HERD:ObjectNotFound', ...
                    ['No external references are stored for this object. Add one ', ...
                    'with addRef before looking it up.'])
            end

            objectKeyTable = obj.getTable("object_keys");
            entityKeyTable = obj.getTable("entity_keys");
            keyIndices = objectKeyTable.keys_idx(objectKeyTable.objects_idx == uint32(objectRow - 1));
            entityIndices = entityKeyTable.entities_idx(ismember(entityKeyTable.keys_idx, keyIndices));
            entityTable = obj.getTable("entities");
            entities = entityTable(double(unique(entityIndices)) + 1, :);
        end

        function references = getObjectType(obj, objectType, options)
        % getObjectType - Get every reference recorded on objects of one type.
        %
        % Syntax:
        %  references = herd.getObjectType(objectType) returns the rows of
        %  toTable whose object_type matches objectType, for example
        %  "Subject", and whose relative_path and field are empty.
        %
        %  references = herd.getObjectType(__, RelativePath=relativePath, Field=field)
        %  matches the given relative_path and field instead of empty ones.
        %
        %  references = herd.getObjectType(__, AllInstances=true) returns
        %  every row of the type regardless of relative_path and field,
        %  which are ignored.
        %
        % Input Arguments:
        %  - objectType (string) -
        %    The unqualified neurodata type name a reference is recorded
        %    under, for example "Subject" or "VectorData".
        %
        % Name-Value Arguments:
        %  - RelativePath (string) -
        %    The relative_path a row must hold. References added by MatNWB
        %    currently always store an empty relative path.
        %
        %  - Field (string) -
        %    The field a row must hold, as in addRef.
        %
        %  - AllInstances (logical) -
        %    Return the rows of every instance of the type, ignoring
        %    RelativePath and Field. Matches HDMF's all_instances.
        %
        % Output Arguments:
        %  - references (table) -
        %    The matching rows of toTable.

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
                objectType (1,1) string
                options.RelativePath (1,1) string = ""
                options.Field (1,1) string = ""
                options.AllInstances (1,1) logical = false
            end

            references = obj.toTable();
            if isempty(references)
                return
            end
            references = references(strcmp(references.object_type, objectType), :);
            if options.AllInstances
                return
            end
            references = references( ...
                strcmp(references.relative_path, options.RelativePath) ...
                & strcmp(references.field, options.Field), :);
        end

        function references = toTable(obj)
        % toTable - Flatten the six HERD tables into one table of references.
        %
        % Syntax:
        %  references = herd.toTable() returns one row per object, key and
        %  entity association, with the internal row indices resolved into the
        %  values they point at.
        %
        % Output Arguments:
        %  - references (table) -
        %    One row per association, with the columns file_object_id,
        %    object_id, object_type, relative_path, field, key, entity_id
        %    and entity_uri.

            arguments
                obj (1,1) matnwb.neurodata.HERDBase
            end

            keyTable = obj.getTable("keys");
            fileTable = obj.getTable("files");
            entityTable = obj.getTable("entities");
            objectTable = obj.getTable("objects");
            objectKeyTable = obj.getTable("object_keys");
            entityKeyTable = obj.getTable("entity_keys");

            columnNames = {'file_object_id', 'object_id', 'object_type', ...
                'relative_path', 'field', 'key', 'entity_id', 'entity_uri'};
            rows = cell(0, numel(columnNames));
            for iObjectKey = 1:height(objectKeyTable)
                objectRow = double(objectKeyTable.objects_idx(iObjectKey)) + 1;
                keyRow = double(objectKeyTable.keys_idx(iObjectKey)) + 1;
                fileRow = double(objectTable.files_idx(objectRow)) + 1;
                entityRows = double(entityKeyTable.entities_idx( ...
                    entityKeyTable.keys_idx == objectKeyTable.keys_idx(iObjectKey))) + 1;
                for iEntity = 1:numel(entityRows)
                    rows(end+1, :) = { ...
                        fileTable.file_object_id{fileRow}, ...
                        objectTable.object_id{objectRow}, ...
                        objectTable.object_type{objectRow}, ...
                        objectTable.relative_path{objectRow}, ...
                        objectTable.field{objectRow}, ...
                        keyTable.key{keyRow}, ...
                        entityTable.entity_id{entityRows(iEntity)}, ...
                        entityTable.entity_uri{entityRows(iEntity)}}; %#ok<AGROW>
                end
            end
            references = cell2table(rows, 'VariableNames', columnNames);
        end
    end

    methods (Access = protected) % Override matlab.mixin.CustomDisplay
        function header = getHeader(obj)
            header = sprintf('  %s with %s', ...
                obj.getTypeShortName(), obj.referenceCountSummary());
        end

        function displayScalarObject(obj)
            disp(obj.getHeader())
            references = obj.toTable();
            if isempty(references)
                fprintf('    No external resource references.\n');
            else
                disp(references)
            end
            % Preserve the missing-required-property warning that
            % types.untyped.MetaClass.getFooter triggers as a side effect.
            obj.getFooter();
        end
    end

    methods (Hidden)
        function ensureTablesInitialized(obj)
        % ensureTablesInitialized - Give every unset table an empty value.
        %
        % All six tables are required by the schema, so an unset one would make
        % the HERD fail to export. The generated constructor calls this so
        % that every HERD can be written even if no reference is ever added
        % to it.
            for tableName = obj.TableNames
                if isempty(obj.(tableName))
                    obj.setTable(tableName, obj.createEmptyTable(tableName));
                end
            end
        end
    end

    methods (Access = private)
        function summary = referenceCountSummary(obj)
        % referenceCountSummary - One-line summary of the table sizes.
            summary = sprintf('%d key(s), %d entity(ies), %d object(s), %d file(s)', ...
                height(obj.getTable("keys")), height(obj.getTable("entities")), ...
                height(obj.getTable("objects")), height(obj.getTable("files")));
        end

        function [target, relativePath] = resolveTarget(~, container, attribute)
        % resolveTarget - Resolve a container and attribute to the annotated object.
        %
        % relativePath is currently always "": HDMF records a relative path
        % for attributes that are not neurodata types, which MatNWB does not
        % support yet, and the output is kept so a row of the objects table
        % is built with the same shape HDMF writes.
            relativePath = "";
            if strlength(attribute) == 0
                target = container;
                return
            end
            if ~isprop(container, attribute)
                error('NWB:HERD:UnknownAttribute', ...
                    'Attribute "%s" is not a property of %s.', attribute, class(container))
            end
            attributeValue = container.(attribute);
            if ~isa(attributeValue, 'types.untyped.MetaClass')
                % HDMF also supports attributes that are not neurodata types by
                % recording a relative path to them. MatNWB does not resolve
                % those paths yet.
                error('NWB:HERD:UnsupportedAttribute', ...
                    ['Attribute "%s" of %s holds a `%s`, which cannot be ', ...
                    'referenced yet. Reference a property that is itself a ', ...
                    'neurodata type, such as a column of a table.'], ...
                    attribute, class(container), class(attributeValue))
            end
            target = attributeValue;
        end

        function assertContainerInFile(~, file, container)
        % assertContainerInFile - Verify a container belongs to a file.
        %
        % A reference to an object that is not in the file would be written as a
        % dangling object id, so this is checked before anything is recorded.
            if container == file
                return
            end
            if matnwb.utility.containsObject(file, container)
                return
            end
            error('NWB:HERD:ContainerNotInFile', ...
                ['The %s being referenced is not part of this file. Add it to ', ...
                'the file before adding an external reference to it.'], ...
                container.getTypeShortName())
        end

        function tableData = getTable(obj, tableName)
        % getTable - Read one HERD table as a MATLAB table.
            storedData = obj.(tableName);
            if isempty(storedData)
                tableData = obj.createEmptyTable(tableName);
                return
            end
            tableData = storedData.data;
            if isa(tableData, 'types.untyped.DataStub')
                % Keep the loaded dataset. Every lookup reads its table
                % through this method, so leaving the stub in place would
                % read the file from disk once per lookup.
                tableData = tableData.load();
                storedData.data = tableData;
            end
            tableData = obj.normalizeToTable(tableName, tableData);
        end

        function setTable(obj, tableName, tableData)
        % setTable - Write one HERD table back onto the generated property.
            existing = obj.(tableName);
            if isa(existing, 'types.hdmf_common.Data')
                % Reuse the existing Data so that its object id survives editing.
                existing.data = tableData;
            else
                existing = types.hdmf_common.Data('data', tableData);
            end
            % Assigning through the property runs the generated schema validation.
            obj.(tableName) = existing;
        end

        function rowIndex = findOrAddRow(obj, tableName, rowValues)
        % findOrAddRow - Return the row matching rowValues, appending it if absent.
            rowIndex = obj.findRowInTable(obj.getTable(tableName), rowValues);
            if isempty(rowIndex)
                rowIndex = obj.appendRow(tableName, rowValues);
            end
        end

        function rowIndex = appendRow(obj, tableName, rowValues)
        % appendRow - Append one row and return its one-based index.
            tableData = obj.getTable(tableName);
            tableData = [tableData; obj.createRow(tableName, rowValues)];
            obj.setTable(tableName, tableData);
            rowIndex = height(tableData);
        end

        function keyRow = findKeyForObject(obj, keyName, objectRow)
        % findKeyForObject - Find a key already used by an object.
        %
        % Keys are scoped to an object, so a term already recorded against this
        % object is reused while the same term on another object is not.
            keyTable = obj.getTable("keys");
            objectKeyTable = obj.getTable("object_keys");
            candidateRows = find(strcmp(keyTable.key, keyName));
            usedRows = double(objectKeyTable.keys_idx( ...
                objectKeyTable.objects_idx == uint32(objectRow - 1))) + 1;
            keyRow = intersect(candidateRows, usedRows);
            if ~isempty(keyRow)
                keyRow = keyRow(1);
            end
        end
    end

    methods (Access = private) % Build and match rows from the table specification
        function [columnNames, isIndexColumn] = getTableSpecification(~, tableName)
        % getTableSpecification - Column names and kinds of one HERD table.
        %
        % The names and their order have to match the compound type declared by
        % the schema, which the generated class validates against.
            switch tableName
                case "keys"
                    columnNames = "key";
                    isIndexColumn = false;
                case "files"
                    columnNames = "file_object_id";
                    isIndexColumn = false;
                case "entities"
                    columnNames = ["entity_id", "entity_uri"];
                    isIndexColumn = [false, false];
                case "objects"
                    columnNames = ["files_idx", "object_id", "object_type", ...
                        "relative_path", "field"];
                    isIndexColumn = [true, false, false, false, false];
                case "object_keys"
                    columnNames = ["objects_idx", "keys_idx"];
                    isIndexColumn = [true, true];
                case "entity_keys"
                    columnNames = ["entities_idx", "keys_idx"];
                    isIndexColumn = [true, true];
                otherwise
                    error('NWB:HERD:UnknownTable', ...
                        '"%s" is not a HERD table.', tableName)
            end
        end

        function tableData = createEmptyTable(obj, tableName)
        % createEmptyTable - Build a row-less table with the right column types.
            [columnNames, isIndexColumn] = obj.getTableSpecification(tableName);
            columns = cell(1, numel(columnNames));
            for iColumn = 1:numel(columnNames)
                if isIndexColumn(iColumn)
                    columns{iColumn} = zeros(0, 1, 'uint32');
                else
                    columns{iColumn} = cell(0, 1);
                end
            end
            tableData = table(columns{:}, 'VariableNames', cellstr(columnNames));
        end

        function rowTable = createRow(obj, tableName, rowValues)
        % createRow - Build a one-row table from a cell array of column values.
            [columnNames, isIndexColumn] = obj.getTableSpecification(tableName);
            assert(numel(rowValues) == numel(columnNames), ...
                'NWB:HERD:InvalidRow', ...
                'A row of the %s table needs %d values.', tableName, numel(columnNames))
            columns = cell(1, numel(columnNames));
            for iColumn = 1:numel(columnNames)
                if isIndexColumn(iColumn)
                    columns{iColumn} = uint32(rowValues{iColumn});
                else
                    columns{iColumn} = {char(rowValues{iColumn})};
                end
            end
            rowTable = table(columns{:}, 'VariableNames', cellstr(columnNames));
        end

        function tableData = normalizeToTable(obj, tableName, tableData)
        % normalizeToTable - Coerce stored compound data into a MATLAB table.
        %
        % Compound datasets are read back as a scalar struct of columns, while
        % data written in this session is already a table. Both are brought to
        % the column order and types the schema declares.
            [columnNames, isIndexColumn] = obj.getTableSpecification(tableName);

            if ~istable(tableData) && ~isstruct(tableData) && isempty(tableData)
                % A row-less compound dataset is read back as an empty array,
                % which carries no column information.
                tableData = obj.createEmptyTable(tableName);
            elseif isstruct(tableData) && ~isscalar(tableData)
                % A struct array holds one element per row. AsArray only
                % applies to a scalar struct and is rejected here.
                tableData = struct2table(tableData);
            elseif isstruct(tableData)
                % A scalar struct of empty columns converts to a zero-row
                % table, so no separate empty case is needed, and a struct
                % with the wrong fields fails the column check below.
                tableData = struct2table(tableData, 'AsArray', false);
            end
            assert(istable(tableData), 'NWB:HERD:InvalidTable', ...
                'The %s table holds a `%s`, which is not a table.', ...
                tableName, class(tableData))

            storedNames = string(tableData.Properties.VariableNames);
            columns = cell(1, numel(columnNames));
            for iColumn = 1:numel(columnNames)
                name = columnNames(iColumn);
                assert(any(storedNames == name), 'NWB:HERD:MissingColumn', ...
                    'The %s table is missing the column "%s".', tableName, name)
                column = tableData.(char(name));
                if isIndexColumn(iColumn)
                    columns{iColumn} = uint32(column(:));
                elseif isempty(column)
                    columns{iColumn} = cell(0, 1);
                else
                    columns{iColumn} = cellstr(string(column(:)));
                end
            end
            tableData = table(columns{:}, 'VariableNames', cellstr(columnNames));
        end

        function rowIndex = findRowInTable(~, tableData, rowValues)
        % findRowInTable - Find the row of an already read table whose columns
        % all equal rowValues.
        %
        % rowValues holds one entry per column, in the order
        % getTableSpecification declares, which is the order createRow builds
        % a row in.
            assert(numel(rowValues) == width(tableData), 'NWB:HERD:InvalidRow', ...
                'A lookup needs one value per column, but got %d for %d columns.', ...
                numel(rowValues), width(tableData))
            columnNames = tableData.Properties.VariableNames;
            isMatch = true(height(tableData), 1);
            for iColumn = 1:numel(rowValues)
                column = tableData.(columnNames{iColumn});
                if iscell(column)
                    isMatch = isMatch & strcmp(column, rowValues{iColumn});
                else
                    isMatch = isMatch & (column == rowValues{iColumn});
                end
            end
            rowIndex = find(isMatch, 1);
        end

        function rowValues = createObjectRowValues(~, fileRow, target, relativePath, field)
        % createObjectRowValues - Identity of a row of the objects table.
        %
        % The values are ordered to match the columns getTableSpecification
        % declares for the objects table. Adding a reference and looking one
        % up build the same identity, so both take it from here.
        %
        % object_type holds the unqualified type name HDMF records, e.g.
        % "VectorData", which is the same name MetaClass.export writes as the
        % neurodata_type attribute.
            rowValues = {uint32(fileRow - 1), target.object_id, ...
                target.getTypeShortName(), ...
                char(relativePath), char(field)};
        end
    end
end
