# MatNWB

A Matlab interface for reading and writing Neurodata Without Borders (NWB) files.

## How does it work

NWB files are HDF5 files with data stored according to the Neurodata Without Borders: Neurophysiology (NWB:N) [schema](https://github.com/NeurodataWithoutBorders/nwb-schema/tree/dev/core). The schema is described in a set of yaml documents. These define the various types and their attributes.

This package provides two functions `generateCore` and `generateExtension` that transform the yaml files that describe the schema into Matlab m-files. The generated code defines classes that reflect the types defined in the schema.  Object attributes, relationships, and documentation are automatically generated to reflect the schema where possible.

Once the code generation step is done, NWB objects can be read, constructed and written from Matlab.

## Sources

MatNWB is availbale online at https://github.com/NeurodataWithoutBorders/matnwb

## Caveats

The NWB:N schema is in a state of some evolution.  This package assumes a certain set of rules are used to define the schema.  As the schema is updated, some of the rules may be changed and these will break this package.

For those planning on using matnwb alongside pynwb, please the following in mind:
 - The ordering of dimensions in MATLAB are reversed compared to numpy (and pynwb).  Thus, a 3-D ```SpikeEventSeries```, which in pynwb would normally be indexed in order ```(num_samples, num_channels, num_events)```, would be indexed in form ```(num_events, num_channels, num_samples)``` in matnwb.
 - matnwb is dependent on the schema, which may not necessary correspond with the nwb-version.  In the future, the matnwb release will point to the most compatible pynwb commit, but at the current moment, please consider overwriting the contents within matnwb's **~/schema/core** directory with the generating pynwb's **~/src/pynwb/data directory** (`~` in this case referring to the installation directory of the application) and running generateCore.
 
The `master` branch in this repository is considered perpetually unstable.  If you desire matnwb's full functionality (full round-trip with nwb data), please consider downloading the more stable releases in the Releases tab.  Keep in mind that the Releases are generally only compatible with older versions of pynwb and may not supported newer data types supported by pynwb (such as data references or compound types).

## Setup

From the Matlab command line, generate code from a copy of the NWB schema.  The command also takes variable arguments from any extensions.

```matlab
generateCore('schema/core/nwb.namespace.yaml', .../my_extensions1.namespace.yaml,...);
```

You can also generate extensions without generating the core classes in this way:

```matlab
generateExtension('my_extension.namespace.yaml');
```

Generated Matlab code will be put a `+types` subdirectory.  This is a Matlab package.  When the `+types` folder is accessible to the Matlab path, the generated code will be used for reading NWBFiles.

```matlab
nwb=nwbRead('data.nwb');
```

## Tutorials

[Extracellular Electrophysiology](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ecephys.html)

[Calcium Imaging](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html)

[Intracellular Electrophysiology](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html)

## Examples

[Basic Data Retrieval](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/basicUsage.html)

[Conversion From Trial Data](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/convertTrials.html)


## third-party support
The `+contrib` folder contains tools for converting from other common data formats/specifications to NWB. Currently supported data types are TDT, MWorks, and Blackrock. We are interested in expanding this section to other data specifications and would greatly value your contribution!
