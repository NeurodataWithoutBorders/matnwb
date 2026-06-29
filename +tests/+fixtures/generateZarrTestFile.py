"""Generate a minimal NWB Zarr (v2) store for MatNWB Zarr reader tests.

Writes a small ``.nwb.zarr`` store using pynwb + hdmf-zarr. The store is
intentionally minimal but exercises every structure the Zarr2 reader tests
rely on:

* root attributes (``nwb_version``, ``.specloc``) and consolidated metadata
* embedded specifications under ``/specifications``
* a scalar string dataset (``/identifier``)
* a soft link (electrode group -> device)
* an object-reference attribute (``/units/spike_times_index`` -> target)
* a 1-D string dataset (``/general/extracellular_ephys/electrodes/location``)
* a 1-D integer dataset (``/general/extracellular_ephys/electrodes/id``, auto-generated)
* a 1-D float64 dataset (``/units/spike_times``)
* a 2-D float32 dataset (``/acquisition/es/data``) for lazy/partial reads
* a compound dataset (``/processing/ophys/PlaneSegmentation/pixel_mask``)
  with fields x (uint32), y (uint32), weight (float32) — the canonical NWB
  compound use case

Usage:
    python generateZarrTestFile.py <output_path.nwb.zarr>
"""

import sys
from datetime import datetime
from dateutil.tz import tzutc

import numpy as np
from pynwb import NWBFile
from pynwb.ecephys import ElectricalSeries
from pynwb.ophys import PlaneSegmentation, ImagingPlane, OpticalChannel
from hdmf_zarr.nwb import NWBZarrIO

# Fixed values asserted by the MATLAB tests. Keep these in sync with
# Zarr2ReaderTest / Zarr2LazyArrayTest.
IDENTIFIER = "ZARR_FIXTURE"
NUM_ELECTRODES = 4
NUM_SAMPLES = 29
ELECTRODE_LOCATION = "brain"
SPIKE_TIMES = [1.0, 2.0, 3.0, 4.0, 5.0]
NUM_SPIKE_TIMES = len(SPIKE_TIMES)
# pixel_mask compound dataset: NUM_ROIS ROIs each with NUM_PIXELS_PER_ROI pixels.
# Stored as a 1-D compound array of (x uint32, y uint32, weight float32) records.
NUM_ROIS = 3
NUM_PIXELS_PER_ROI = 4


def build_nwbfile():
    nwbfile = NWBFile(
        session_description="MatNWB Zarr reader test fixture",
        identifier=IDENTIFIER,
        session_start_time=datetime(2020, 1, 1, tzinfo=tzutc()),
    )

    device = nwbfile.create_device(name="array")
    electrode_group = nwbfile.create_electrode_group(
        name="shank0",
        description="electrode group",
        location="brain",
        device=device,
    )
    for _ in range(NUM_ELECTRODES):
        nwbfile.add_electrode(
            location=ELECTRODE_LOCATION,
            group=electrode_group,
            group_name="shank0",
        )
    electrode_region = nwbfile.create_electrode_table_region(
        region=list(range(NUM_ELECTRODES)),
        description="all electrodes",
    )

    # 2-D dataset (samples x channels) for lazy-array / partial-read tests.
    # Read into MATLAB (column-major) the dimensions appear transposed.
    data = np.arange(NUM_SAMPLES * NUM_ELECTRODES, dtype="float32")
    data = data.reshape(NUM_SAMPLES, NUM_ELECTRODES)
    electrical_series = ElectricalSeries(
        name="es",
        data=data,
        electrodes=electrode_region,
        rate=1000.0,
    )
    nwbfile.add_acquisition(electrical_series)

    # An indexed column creates /units/spike_times_index with a 'target'
    # object reference pointing at /units/spike_times.
    # SPIKE_TIMES split across two units so the index dataset is non-trivial.
    nwbfile.add_unit(spike_times=SPIKE_TIMES[:3])
    nwbfile.add_unit(spike_times=SPIKE_TIMES[3:])

    # Compound dataset: pixel_mask PlaneSegmentation.
    # Stored as a 1-D array of (x uint32, y uint32, weight float32) records.
    # Path: /processing/ophys/PlaneSegmentation/pixel_mask
    optical_channel = OpticalChannel(
        name="OpticalChannel",
        description="optical channel",
        emission_lambda=500.0,
    )
    device_ophys = nwbfile.create_device(name="microscope")
    imaging_plane = nwbfile.create_imaging_plane(
        name="ImagingPlane",
        optical_channel=optical_channel,
        description="imaging plane",
        device=device_ophys,
        excitation_lambda=600.0,
        indicator="GCaMP",
        location="V1",
    )
    plane_segmentation = PlaneSegmentation(
        name="PlaneSegmentation",
        description="ROI segmentation",
        imaging_plane=imaging_plane,
    )
    for roi_idx in range(NUM_ROIS):
        pixel_mask = [
            (roi_idx * NUM_PIXELS_PER_ROI + px, px, float(roi_idx + 1))
            for px in range(NUM_PIXELS_PER_ROI)
        ]
        plane_segmentation.add_roi(pixel_mask=pixel_mask)

    ophys_module = nwbfile.create_processing_module(name="ophys", description="ophys")
    ophys_module.add(plane_segmentation)

    return nwbfile


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: generateZarrTestFile.py <output_path.nwb.zarr>")
    output_path = sys.argv[1]

    nwbfile = build_nwbfile()
    with NWBZarrIO(output_path, mode="w") as io:
        io.write(nwbfile)


if __name__ == "__main__":
    main()
