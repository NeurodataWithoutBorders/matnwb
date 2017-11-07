# MatNWB

A Matlab interface for reading and writing NWB files.

## How does it work

NWB files are HDF5 files with data stored according to the NWB:N schema. The schema is described in a set of yaml documents. These define the various types and their attributes.

This package provides two functions `generateCore` and `generateExtensions` that transform the yaml files that describe the schema into Matlab m-files. The generated code defines classes that reflect the types defined in the schema.  Object attributes, relationships, and documentation are automatically generated to reflect the schema where possible.

Once the code generation step is done, NWB objects can be read, constructed and written from Matlab.

## Caveats

The NWB:N schema is in a state of some evolution.  This package assumes a certain set of rules are used to define the schema.  As the schema is updated, some of the rules may be changed and these will break this package.

## Examples

From the Matlab command line, generate code from a copy of the NWB schema.

```matlab
registry=generateCode('schema/core/nwb.namespace.yaml');
```

The `registry` is a collection of defined types and is used when adding extension schemas:

```matlab
registry=generateExtensions('my_extension.namespace.yaml');
```

Generated Matlab code will be put a `+types` subdirectory.  This is a Matlab package.  When the `+types` folder is accessible to the Matlab path, the generated code will be used for reading NWBFiles,

```matlab
nwb=nwbRead('data.nwb');
```

and for generating NWB objects for export:

```matlab
%Create some fake fata and write 
nwb = nwbfile;
nwb.epochs = types.untyped.Group;
nwb.epochs.stim = types.Epoch;
nwbExport(nwb, 'epoch.nwb');
```




