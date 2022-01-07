[![codecov](https://codecov.io/gh/NeurodataWithoutBorders/matnwb/branch/master/graph/badge.svg?token=apA7F24NsO)](https://codecov.io/gh/NeurodataWithoutBorders/matnwb) ![Azure DevOps tests](https://img.shields.io/azure-devops/tests/NeurodataWithoutBorders/matnwb/4)
# MatNWB

A Matlab interface for reading and writing Neurodata Without Borders (NWB) 2.0 files.

## Setup

### Step 1: Download MatNWB

Download the current release of MatNWB from the [MatNWB releases page](https://github.com/NeurodataWithoutBorders/matnwb/releases) or from the [![View NeurodataWithoutBorders/matnwb on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/67741-neurodatawithoutborders-matnwb). You can also check out the latest development version via 

```bash
git clone https://github.com/NeurodataWithoutBorders/matnwb.git
```

### Step 2: Generate the API

From the Matlab command line, add MatNWB to the Matlab path and generate the core classes for the NWB schema.

```matlab
cd matnwb
addpath(genpath(pwd));
generateCore(); % generate the most recent nwb-schema release.
```

### Optional: Generate MatNWB code for extensions

The `generateExtension` command generates extension classes given a file path to the extension's namespace.

```matlab
generateExtension('schema/core/nwb.namespace.yaml', '.../my_extensions1.namespace.yaml',...);
```

Generated Matlab code will be put into a `+types` subdirectory.
This is a Matlab package.  When the `+types` folder is accessible to the Matlab path, the generated code will be used for reading NWBFiles.

```matlab
nwb = nwbRead('data.nwb');
```

### Optional: Generate an older core schema

The `generateCore` command can generate older versions of the nwb schema.

```matlab
generateCore();
```

Currently, only schemas >= 2.2.0 are supported (2.1.0 and 2.0.1 are not supported at this time).

## Tutorials

[Intro to MatNWB](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/intro.html)

[Extracellular Electrophysiology](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ecephys.html) | [YouTube walkthrough](https://www.youtube.com/watch?v=W8t4_quIl1k&ab_channel=NeurodataWithoutBorders)

[Calcium Imaging](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/ophys.html) | [YouTube walkthrough](https://www.youtube.com/watch?v=OBidHdocnTc&ab_channel=NeurodataWithoutBorders)

[Intracellular Electrophysiology](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html)

[Advanced data write](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/dataPipe.html)  | [YouTube walkthrough](https://www.youtube.com/watch?v=PIE_F4iVv98&ab_channel=NeurodataWithoutBorders)

## API Documentation

For more information regarding the MatNWB API or any of the NWB Core types in MatNWB, visit the [MatNWB API Documentation pages](https://neurodatawithoutborders.github.io/matnwb/doc/index.html).


## How does it work

NWB files are HDF5 files with data stored according to the Neurodata Without Borders: Neurophysiology (NWB:N) [schema](https://github.com/NeurodataWithoutBorders/nwb-schema/tree/dev/core). The schema is described in a set of yaml documents. These define the various types and their attributes.

This package provides two functions `generateCore` and `generateExtension` that transform the yaml files that describe the schema into Matlab m-files. The generated code defines classes that reflect the types defined in the schema.  Object attributes, relationships, and documentation are automatically generated to reflect the schema where possible.

Once the code generation step is done, NWB objects can be read, constructed and written from Matlab.

PyNWB's cached schemas are also supported, bypassing the need to run `generateCore` or `generateExtension` if present.

## Sources

MatNWB is available online at https://github.com/NeurodataWithoutBorders/matnwb

## Data Dimensions

NWB files use the HDF5 format to store data. Due to differences in how MATLAB and HDF5 represent data, the dimensions of datasets are flipped when writing to/from file in MatNWB. This behavior differs depending on whether ```VectorData``` use ```DataPipe``` objects to contain the data. It's important to keep in mind the mappings below to make sure is written to and read from file as expected.

[without DataPipes](TODO)

| Shape <br /> in MatNWB| Shape<br />in HDF5|
| ------------ | ------------ |
|    (N, 1)    |     (N,)     |
|    (1, N)    |     (N,)     |
| (P, M, O, N) | (N, O, M, P) |

[with DataPipes](TODO)

| Shape <br /> in MatNWB| Shap e<br /> in HDF5|
| ------------ | ------------ |
|    (N, 1)    |    (1, N)    |
|    (N, 1)    |     (N,)     | ** 'maxSize' value must be 1D 
|    (1, N)    |    (N, 1)    |
| (P, M, O, N) | (N, O, M, P) |

## Warnings

The NWB:N schema is in a state of some evolution.  This package assumes a certain set of rules are used to define the schema.  As the schema is updated, some of the rules may be changed and these will break this package.

For those planning on using matnwb alongside pynwb, please keep the following in mind:
 - MatNWB is dependent on the schema, which may not necessary correspond with your PyNWB schema version.  Please consider overwriting the contents within MatNWB's **~/schema/core** directory with the generating PyNWB's **src/pynwb/data directory** and running generateCore to ensure compatibilty between systems.
 
The `master` branch in this repository is considered perpetually unstable.  If you desire matnwb's full functionality (full round-trip with nwb data), please consider downloading the more stable releases in the Releases tab.  Keep in mind that the Releases are generally only compatible with older versions of pynwb and may not supported newer data types supported by pynwb (such as data references or compound types).  Most releases will coincide with nwb-schema releases and contain compatibility with those features.

This package reads and writes NWB:N 2.0 files and does not support older formats.


## Examples

[Basic Data Retrieval](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/basicUsage.html)
| showcases how one would read and process converted NWB file data to display a raster diagram.

[Conversion of Real Electrophysiology/Optophysiology Data](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/convertTrials.html)
| converts Electrophysiology/Optophysiology Data recorded from:
>Li, Daie, Svoboda, Druckman (2016); Data and simulations related to: Robust neuronal dynamics in premotor cortex during motor planning. Li, Daie, Svoboda, Druckman, Nature. CRCNS.org
http://dx.doi.org/10.6080/K0RB72JW

## Third-party Support
The `+contrib` folder contains tools for converting from other common data formats/specifications to NWB. Currently supported data types are TDT, MWorks, and Blackrock. We are interested in expanding this section to other data specifications and would greatly value your contribution!

## Testing

Run the test suite with `nwbtest`.

## FAQ

1. "A class definition must be in an "@" directory."

Make sure that there are no "@" signs **anywhere** in your *full* file path.  This includes even directories that are not part of the matnwb root path and any "@" signs that are not at the beginning of the directory path.

Alternatively, this issue disappears after MATLAB version 2017b.  Installing this version may also resolve these issues.  Note that the updates provided with 2017b should also be installed.
