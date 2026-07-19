function fixturePath = createZarr3TestFile(rootFolder)
% createZarr3TestFile - Build a small Zarr v3 NWB-like fixture for tests.
%
%   fixturePath = createZarr3TestFile(rootFolder) creates a Zarr v3 store
%   under rootFolder directly via the zarr-matlab package (independent of
%   io.backend.zarr3.Zarr3Writer, so io.backend.zarr3.Zarr3Reader tests are
%   not circularly validated only against the writer), and returns the path
%   to the store.
%
%   The pixel_mask compound dataset is built via zarr.metadata.ArrayMetadata
%   + a direct zarr.Array construction rather than zarr.create, because
%   zarr.create's public API has no way to pass a "structured" data_type's
%   field configuration (its dtype argument is a plain scalar string) --
%   the only way to create a "structured" array today, matching how
%   zarr-matlab's own test suite does it (see
%   TestStructuredDtype>structuredArrayEndToEnd in zarr-matlab).

    arguments
        rootFolder (1,1) string
    end

    fixturePath = fullfile(rootFolder, "fixture.zarr");

    root = zarr.create_group(fixturePath, Attributes=struct(...
        'nwb_version', "2.7.0", ...
        'x_specloc', "/specifications"));

    root.createArray("identifier", [], "string").write("ZARR3_FIXTURE");
    root.createGroup("specifications");

    acquisitionGroup = root.createGroup("acquisition");
    esGroup = acquisitionGroup.createGroup("es");
    % Stored in numpy/row-major order ([29 4], i.e. timepoints x channels),
    % as a real Python NWB Zarr v3 writer would; io.backend.zarr3.Zarr3Reader
    % reverses rank->=2 shape/data back to the MatNWB-facing [4 29]
    % (channels x timepoints) dims read by Zarr3ReaderTest/Zarr3LazyArrayTest.
    esGroup.createArray("data", [29 4], "single").write(reshape(single(1:116), [4 29]).');

    unitsGroup = root.createGroup("units");
    unitsGroup.createArray("spike_times", 5, "double").write([1.1 2.2 3.3 4.4 5.5]);
    spikeTimesIndexGroup = unitsGroup.createGroup("spike_times_index");
    spikeTimesIndexGroup.setAttr("target", ...
        struct('zarr_dtype', "object", 'value', struct('path', "/units/spike_times")));

    generalGroup = root.createGroup("general");
    electrophysGroup = generalGroup.createGroup("extracellular_ephys");
    electrodesGroup = electrophysGroup.createGroup("electrodes");
    electrodesGroup.createArray("location", 4, "string").write(repmat("brain", 4, 1));
    electrodesGroup.createArray("id", 4, "int64").write(int64([0; 1; 2; 3]));

    devicesGroup = generalGroup.createGroup("devices");
    devicesGroup.createGroup("array");

    shank0Group = electrophysGroup.createGroup("shank0");
    shank0Group.setAttr("zarr_link", ...
        {struct('name', "device", 'source', ".", 'path', "/general/devices/array")});

    processingGroup = root.createGroup("processing");
    ophysGroup = processingGroup.createGroup("ophys");
    planeSegmentationGroup = ophysGroup.createGroup("PlaneSegmentation");
    createPixelMaskArray(planeSegmentationGroup);

    zarr.consolidate_metadata(root.store);
end

function createPixelMaskArray(parentGroup)
% createPixelMaskArray - Write a 3-record "structured" (compound) pixel_mask
% array (x uint32, y uint32, weight float32) as a child of parentGroup,
% matching a real hdmf-zarr PlaneSegmentation.pixel_mask column.

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

    arrayPath = parentGroup.path + "/pixel_mask";
    parentGroup.store.set(arrayPath + "/zarr.json", unicode2native(char(meta.toJsonText()), 'UTF-8'));

    records(1, 1) = struct('x', uint32(0), 'y', uint32(0), 'weight', single(0.5));
    records(2, 1) = struct('x', uint32(1), 'y', uint32(1), 'weight', single(0.6));
    records(3, 1) = struct('x', uint32(2), 'y', uint32(2), 'weight', single(0.7));

    pixelMaskArray = zarr.Array(parentGroup.store, arrayPath, meta);
    pixelMaskArray.write(records);
end
