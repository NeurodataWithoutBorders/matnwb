function fixturePath = createZarr3TestFile(rootFolder)
% createZarr3TestFile - Build a small Zarr v3 NWB-like fixture for tests.
%
% fixturePath = createZarr3TestFile(rootFolder) creates a Zarr v3 store
% under rootFolder and returns the path to the store. Plain groups and
% arrays are written directly via the zarr-matlab package; the hdmf-zarr
% conventions (a soft link, an object reference in an attribute, a dataset
% of object references and the compound datasets) are written via
% hdmf-zarr-matlab's hdmf.zarr.File, whose output is validated against
% hdmf-zarr's storage layout in that package's own CI -- so
% io.backend.zarr3.Zarr3Reader is tested against the real on-disk
% conventions rather than against its own writer. The store follows the
% hdmf-zarr 0.14 layout, except for one dataset that carries the
% zarr_dtype:"scalar" marker of earlier versions, which the reader still
% honours.

    arguments
        rootFolder (1,1) string
    end

    fixturePath = fullfile(rootFolder, "fixture.zarr");

    % hdmf-zarr names the cached-specifications group in a root attribute
    % called ".specloc", a key only a dictionary can hold.
    rootAttributes = dictionary(["nwb_version", ".specloc"], {"2.7.0", "specifications"});
    root = zarr.create_group(fixturePath, Attributes=rootAttributes);

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
    % hdmf-zarr before 0.14 represented an NWB scalar property as a rank-1,
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
    ophysGroup.createGroup("PlaneSegmentation");

    intervalsGroup = root.createGroup("intervals");
    intervalsGroup.createGroup("trials");

    % hdmf-zarr conventions: links, object references and compound datasets.
    hdmfFile = hdmf.zarr.File(root.store);
    writePixelMask(hdmfFile, "processing/ophys/PlaneSegmentation/pixel_mask");
    writeEntities(hdmfFile, "processing/ophys/PlaneSegmentation/entities");
    writeTimeseriesReferences(hdmfFile, "intervals/trials/timeseries");
    hdmfFile.addLink("general/extracellular_ephys/shank0", "device", "general/devices/array");
    hdmfFile.setRefAttr("units/spike_times_index", "target", "units/spike_times");
    hdmfFile.writeRefs("general/extracellular_ephys/electrodes/group", ...
        repmat("general/extracellular_ephys/shank0", 4, 1));
    % An external link names another store; hdmf.zarr.File.addLink only
    % creates in-store links, so this record is encoded directly.
    externalLink = hdmf.zarr.Link("external_series", ...
        hdmf.zarr.Reference("/acquisition/es", Source="other_session.nwb.zarr"));
    acquisitionGroup.setAttr("_LINKS", externalLink.encode());

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
    % The relative source follows hdmf-zarr's convention: computed against
    % the STORE PATH itself, so ".." escapes the store directory and lands in
    % rootFolder, where external_target.zarr is a sibling. Resolving it
    % against the store's parent instead would climb one directory too high.
    scratchLinks = [ ...
        hdmf.zarr.Link("linked_data", ...
            hdmf.zarr.Reference("/data", Source=externalStorePath)), ...
        hdmf.zarr.Link("linked_group", ...
            hdmf.zarr.Reference("/plain_group", Source=externalStorePath)), ...
        hdmf.zarr.Link("linked_data_relative", ...
            hdmf.zarr.Reference("/data", Source="../external_target.zarr"))];
    scratchGroup.setAttr("_LINKS", scratchLinks.encode());

    zarr.consolidate_metadata(root.store);
end

function writePixelMask(hdmfFile, arrayPath)
% writePixelMask - Write a compound pixel_mask dataset.
%
% Writes a 3-record compound dataset (x uint32, y uint32, weight float32),
% matching a real hdmf-zarr PlaneSegmentation.pixel_mask column.

    records(1, 1) = struct('x', uint32(0), 'y', uint32(0), 'weight', single(0.5));
    records(2, 1) = struct('x', uint32(1), 'y', uint32(1), 'weight', single(0.6));
    records(3, 1) = struct('x', uint32(2), 'y', uint32(2), 'weight', single(0.7));
    hdmfFile.writeCompound(arrayPath, records);
end

function writeEntities(hdmfFile, arrayPath)
% writeEntities - Write a compound dataset with text fields.
%
% Writes a 2-record compound dataset whose fields are text
% ("fixed_length_utf32"), matching a real hdmf-zarr HERD.entities column.
% Text is the case where zarr-matlab's MATLAB class (string) differs from
% what the HDF5 backend reports and the generated type classes declare
% (char), so it is the fixture for that conversion.

    records(1, 1) = struct('entity_id', "NCBITaxon:10090", 'entity_uri', "https://example.org/10090");
    records(2, 1) = struct('entity_id', "MBA:385", 'entity_uri', "https://example.org/385");
    hdmfFile.writeCompound(arrayPath, records);
end

function writeTimeseriesReferences(hdmfFile, arrayPath)
% writeTimeseriesReferences - Write a compound dataset with a reference field.
%
% Writes a 2-record compound dataset shaped like a
% TimeSeriesReferenceVectorData column (idx_start int32, count int32,
% timeseries -> object reference). hdmf-zarr stores the reference field as
% text holding the target path and lists it in the dataset's
% _REFERENCE_FIELDS attribute (see io.internal.zarr3.getObjectReferenceFields),
% which is how it emulates an HDF5 compound with a reference member.

    target = hdmf.zarr.Reference("/acquisition/es");
    records(1, 1) = struct('idx_start', int32(0), 'count', int32(10), 'timeseries', target);
    records(2, 1) = struct('idx_start', int32(10), 'count', int32(5), 'timeseries', target);
    hdmfFile.writeCompound(arrayPath, records);
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
