function fixturePath = createZarr3TestFile(rootFolder)
% createZarr3TestFile - Build a small Zarr v3 NWB-like fixture for tests.
%
% fixturePath = createZarr3TestFile(rootFolder) creates a Zarr v3 store
% under rootFolder and returns the path to the store. Plain groups and
% arrays are written directly via the zarr-matlab package; the hdmf-zarr
% conventions (a soft link, an external link, an object reference in an
% attribute, a dataset of object references and the root ".specloc"
% attribute) are written via hdmf-zarr-matlab's hdmf.zarr.File, whose
% output is validated against hdmf-zarr's storage spec in that package's
% own CI -- so io.backend.zarr3.Zarr3Reader is tested against the real
% on-disk conventions rather than against its own writer.
%
% The pixel_mask compound dataset is built via zarr.metadata.ArrayMetadata
% + a direct zarr.Array construction rather than zarr.create, because
% zarr.create's public API has no way to pass a "structured" data_type's
% field configuration (its dtype argument is a plain scalar string) --
% the only way to create a "structured" array today, matching how
% zarr-matlab's own test suite does it (see
% TestStructuredDtype>structuredArrayEndToEnd in zarr-matlab).

    arguments
        rootFolder (1,1) string
    end

    fixturePath = fullfile(rootFolder, "fixture.zarr");

    % hdmf-zarr names the cached-specifications group in a root attribute
    % called ".specloc". zarr-matlab stores attributes as a struct, which
    % cannot hold that field name, so the key is written under a placeholder
    % and renamed in the raw metadata by writeSpecLocAttribute below.
    specLocPlaceholder = 'SPECLOC_PLACEHOLDER';
    root = zarr.create_group(fixturePath, Attributes=struct(...
        'nwb_version', "2.7.0", ...
        specLocPlaceholder, "specifications"));

    root.createArray("identifier", [], "string").write("ZARR3_FIXTURE");
    root.createGroup("specifications");

    acquisitionGroup = root.createGroup("acquisition");
    esGroup = acquisitionGroup.createGroup("es");
    % Stored in numpy/row-major order ([29 4], i.e. timepoints x channels),
    % as a real Python NWB Zarr v3 writer would; io.backend.zarr3.Zarr3Reader
    % reverses rank->=2 shape/data back to the MatNWB-facing [4 29]
    % (channels x timepoints) dims read by Zarr3ReaderTest/Zarr3LazyArrayTest.
    esGroup.createArray("data", [29 4], "single").write(reshape(single(1:116), [4 29]).');

    % A rank-3 dataset (numpy order [4 3 2] -> MatNWB dims [2 3 4]), for the
    % rank >= 3 axis reversal (io.internal.zarr3.normalizeDatasetDimensions
    % uses permute rather than transpose there) and for selections naming
    % fewer subscripts than the rank.
    volumeGroup = acquisitionGroup.createGroup("vol");
    volumeGroup.createArray("data", [4 3 2], "double").write(reshape(1:24, [4 3 2]));

    unitsGroup = root.createGroup("units");
    unitsGroup.createArray("spike_times", 5, "double").write([1.1 2.2 3.3 4.4 5.5]);
    unitsGroup.createGroup("spike_times_index");

    generalGroup = root.createGroup("general");
    % hdmf-zarr represents a genuine NWB scalar property as a rank-1,
    % length-1 array tagged zarr_dtype:"scalar" -- indistinguishable by
    % shape from a one-row column, so the tag is what makes the reader
    % return a bare value (see io.internal.zarr3.buildNodeInfo).
    generalGroup.createArray("session_id", 1, "string", ...
        Attributes=struct('zarr_dtype', 'scalar')).write("sess-01");

    electrophysGroup = generalGroup.createGroup("extracellular_ephys");
    electrodesGroup = electrophysGroup.createGroup("electrodes");
    electrodesGroup.createArray("location", 4, "string").write(repmat("brain", 4, 1));
    electrodesGroup.createArray("id", 4, "int64").write(int64([0; 1; 2; 3]));

    devicesGroup = generalGroup.createGroup("devices");
    devicesGroup.createGroup("array");
    electrophysGroup.createGroup("shank0");

    processingGroup = root.createGroup("processing");
    ophysGroup = processingGroup.createGroup("ophys");
    planeSegmentationGroup = ophysGroup.createGroup("PlaneSegmentation");
    createPixelMaskArray(planeSegmentationGroup);
    createEntitiesArray(planeSegmentationGroup);

    intervalsGroup = root.createGroup("intervals");
    createTimeseriesReferenceArray(intervalsGroup.createGroup("trials"));

    % hdmf-zarr conventions: links and object references.
    hdmfFile = hdmf.zarr.File(root.store);
    hdmfFile.addLink("general/extracellular_ephys/shank0", "device", "general/devices/array");
    hdmfFile.setRefAttr("units/spike_times_index", "target", "units/spike_times");
    hdmfFile.writeRefs("general/extracellular_ephys/electrodes/group", ...
        repmat("general/extracellular_ephys/shank0", 4, 1));
    % An external link names another store; hdmf.zarr.File.addLink only
    % creates in-store links, so this record is encoded directly.
    externalLink = hdmf.zarr.Link("external_series", ...
        hdmf.zarr.Reference("/acquisition/es", Source="other_session.nwb.zarr"));
    acquisitionGroup.setAttr("zarr_link", externalLink.encode());

    % A second store, so that an external link can actually be followed
    % rather than only read as metadata. The link above records the relative
    % source hdmf-zarr writes; these record an absolute one, so following
    % them does not depend on the process working directory.
    externalStorePath = createExternalTargetStore(rootFolder);
    scratchGroup = root.createGroup("scratch");
    % A dataset with a zero-length dimension, which the reader returns as [].
    scratchGroup.createArray("empty", 0, "double");
    % A true rank-0 array of a type zarr-matlab reads back as a scalar cell
    % (variable_length_bytes), which the reader's eager path unwraps.
    scratchGroup.createArray("blob", [], "variable_length_bytes").write({uint8([1 2 3])});
    scratchLinks = [ ...
        hdmf.zarr.Link("linked_data", ...
            hdmf.zarr.Reference("/data", Source=externalStorePath)), ...
        hdmf.zarr.Link("linked_group", ...
            hdmf.zarr.Reference("/plain_group", Source=externalStorePath))];
    scratchGroup.setAttr("zarr_link", scratchLinks.encode());

    % Consolidate before renaming: consolidate_metadata re-encodes the root
    % attributes from their struct form, which would undo the rename.
    zarr.consolidate_metadata(root.store);
    writeSpecLocAttribute(root.store, specLocPlaceholder);
end

function writeSpecLocAttribute(store, placeholderName)
% writeSpecLocAttribute - Write hdmf-zarr's ".specloc" root attribute.
%
% Renames the root attribute placeholderName to ".specloc" in the raw root
% metadata (see createZarr3TestFile).

    rootMetadataKey = "zarr.json";
    rootMetadataText = native2unicode(store.get(rootMetadataKey), 'UTF-8');
    rootMetadataText = replace(rootMetadataText, ...
        """" + placeholderName + """", """.specloc""");
    store.set(rootMetadataKey, unicode2native(char(rootMetadataText), 'UTF-8'));
end

function createPixelMaskArray(parentGroup)
% createPixelMaskArray - Write a compound pixel_mask array.
%
% Writes a 3-record "structured" (compound) array (x uint32, y uint32, weight
% float32) as a child of parentGroup, matching a real hdmf-zarr
% PlaneSegmentation.pixel_mask column.

    info = zarr.internal.dtype_info(struct('name', "structured", 'configuration', struct( ...
        'fields', {{{'x', 'uint32'}; {'y', 'uint32'}; {'weight', 'float32'}}})));

    numRecords = 3;
    meta = zarr.metadata.ArrayMetadata();
    meta.shape = numRecords;
    meta.dataType = "structured";
    meta.dataTypeConfig = info.config;
    meta.chunkShape = numRecords;
    meta.fillValue = struct('x', uint32(0), 'y', uint32(0), 'weight', single(0));
    meta.codecs = {zarr.codecs.BytesCodec()};
    % hdmf-zarr tags a compound dataset with a zarr_dtype LIST of per-field
    % descriptors (not the scalar "object"/"scalar" markers), which the
    % reader must pass over without mistaking it for a reference dataset.
    meta.attributes = struct('zarr_dtype', ...
        struct('name', {'x', 'y', 'weight'}, 'dtype', {'uint32', 'uint32', 'float32'}));

    arrayPath = parentGroup.path + "/pixel_mask";
    parentGroup.store.set(arrayPath + "/zarr.json", unicode2native(char(meta.toJsonText()), 'UTF-8'));

    records(1, 1) = struct('x', uint32(0), 'y', uint32(0), 'weight', single(0.5));
    records(2, 1) = struct('x', uint32(1), 'y', uint32(1), 'weight', single(0.6));
    records(3, 1) = struct('x', uint32(2), 'y', uint32(2), 'weight', single(0.7));

    pixelMaskArray = zarr.Array(parentGroup.store, arrayPath, meta);
    pixelMaskArray.write(records);
end

function createEntitiesArray(parentGroup)
% createEntitiesArray - Write a compound array with a text field.
%
% Writes a 2-record "structured" array whose fields are text
% ("fixed_length_utf32"), matching a real hdmf-zarr HERD.entities column.
% Text is the case where zarr-matlab's MATLAB class (string) differs from
% what the HDF5 backend reports and the generated type classes declare
% (char), so it is the fixture for that conversion. Built the same way as
% createPixelMaskArray, for the reason documented there.

    textType = struct('name', "fixed_length_utf32", ...
        'configuration', struct('length_bytes', 128));
    info = zarr.internal.dtype_info(struct('name', "structured", 'configuration', struct( ...
        'fields', {{{'entity_id', textType}; {'entity_uri', textType}}})));

    numRecords = 2;
    meta = zarr.metadata.ArrayMetadata();
    meta.shape = numRecords;
    meta.dataType = "structured";
    meta.dataTypeConfig = info.config;
    meta.chunkShape = numRecords;
    meta.fillValue = struct('entity_id', "", 'entity_uri', "");
    meta.codecs = {zarr.codecs.BytesCodec()};
    % hdmf-zarr records a text field's dtype as "str_", distinguishing it
    % from the "object" marker used for reference fields.
    meta.attributes = struct('zarr_dtype', ...
        struct('name', {'entity_id', 'entity_uri'}, 'dtype', {'str_', 'str_'}));

    arrayPath = parentGroup.path + "/entities";
    parentGroup.store.set(arrayPath + "/zarr.json", unicode2native(char(meta.toJsonText()), 'UTF-8'));

    records(1, 1) = struct('entity_id', "NCBITaxon:10090", 'entity_uri', "https://example.org/10090");
    records(2, 1) = struct('entity_id', "MBA:385", 'entity_uri', "https://example.org/385");

    entitiesArray = zarr.Array(parentGroup.store, arrayPath, meta);
    entitiesArray.write(records);
end

function createTimeseriesReferenceArray(parentGroup)
% createTimeseriesReferenceArray - Write a compound array with a reference field.
%
% Writes a 2-record "structured" array shaped like a
% TimeSeriesReferenceVectorData column (idx_start int32, count int32,
% timeseries -> object reference). The reference field's storage type is
% text whose elements are hdmf.zarr.Reference JSON records, and the array's
% zarr_dtype attribute tags that field "object" (see
% io.internal.zarr3.getObjectReferenceFields), which is how hdmf-zarr
% emulates an HDF5 compound with a reference member. Built the same way as
% createPixelMaskArray, for the reason documented there.

    textType = struct('name', "fixed_length_utf32", ...
        'configuration', struct('length_bytes', 512));
    info = zarr.internal.dtype_info(struct('name', "structured", 'configuration', struct( ...
        'fields', {{{'idx_start', 'int32'}; {'count', 'int32'}; {'timeseries', textType}}})));

    numRecords = 2;
    meta = zarr.metadata.ArrayMetadata();
    meta.shape = numRecords;
    meta.dataType = "structured";
    meta.dataTypeConfig = info.config;
    meta.chunkShape = numRecords;
    meta.fillValue = struct('idx_start', int32(0), 'count', int32(0), 'timeseries', "");
    meta.codecs = {zarr.codecs.BytesCodec()};
    meta.attributes = struct('zarr_dtype', ...
        struct('name', {'idx_start', 'count', 'timeseries'}, ...
            'dtype', {'int32', 'int32', 'object'}));

    arrayPath = parentGroup.path + "/timeseries";
    parentGroup.store.set(arrayPath + "/zarr.json", unicode2native(char(meta.toJsonText()), 'UTF-8'));

    referenceJson = string(jsonencode(hdmf.zarr.Reference("/acquisition/es").encode()));
    records(1, 1) = struct('idx_start', int32(0), 'count', int32(10), 'timeseries', referenceJson);
    records(2, 1) = struct('idx_start', int32(10), 'count', int32(5), 'timeseries', referenceJson);

    referenceArray = zarr.Array(parentGroup.store, arrayPath, meta);
    referenceArray.write(records);
end

function externalStorePath = createExternalTargetStore(rootFolder)
% createExternalTargetStore - A second store for external links to point at.
%
% Holds the two node kinds types.untyped.ExternalLink.deref tells apart
% without any neurodata type having to be generated: a plain dataset, which
% dereferences to a lazy stub, and an untyped group, which deref rejects by
% name. Both are stored as a separate Zarr store so the link crosses a store
% boundary, as an external link does.

    externalStorePath = fullfile(rootFolder, "external_target.zarr");
    externalRoot = zarr.create_group(externalStorePath);
    externalRoot.createArray("data", 3, "int64").write(int64([7; 8; 9]));
    externalRoot.createGroup("plain_group");
    zarr.consolidate_metadata(externalRoot.store);
end
