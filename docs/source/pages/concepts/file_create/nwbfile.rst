.. _matnwb-create-nwbfile-intro:

Understanding the NwbFile Class
===============================

The :class:`NwbFile` class in MatNWB is your main interface for creating NWB files. This MATLAB object serves as the root container that holds all your experimental data and metadata, translating between MATLAB's data structures and the NWB format.

How the NwbFile Object Works
----------------------------

When you create an :class:`NwbFile` object, you're creating a MATLAB representation of what will eventually become an HDF5-based NWB file. The object:

- **Validates input** - ensures your data matches NWB schema requirements
- **Organizes content** - provides a structured way to add different types of data
- **Manages relationships** - maintains connections between related data elements
- **Handles export** - converts everything to proper NWB format when saved

Required Properties in MatNWB
-----------------------------

MatNWB enforces three required properties that must be present when exporting an :class:`NwbFile` object:

- **session_start_time** (:class:`datetime`) - 
  The time when your experiment began. MatNWB requires this as a MATLAB ``datetime`` object with timezone information.

- **identifier** (:class:`char` or :class:`string`) - 
  A unique identifier for this specific session/file. This should be unique across all your NWB files.

- **session_description** (:class:`char` or :class:`string`) - 
  A brief description of what happened in this experimental session.

MatNWB will allow you to create the object without these properties for you to add them later, but they must be set before exporting the file.


Automatic Properties
--------------------

MatNWB automatically handles some required NWB properties so you don't have to:

- **file_create_date** - 
  Set automatically when you export the file using :func:`nwbExport`

- **timestamps_reference_time** - 
  Defaults to match your ``session_start_time`` if not explicitly set

Object Structure and Organization
---------------------------------

The :class:`NwbFile` object provides specific properties for organizing different types of data:

- **acquisition** - 
  Raw data as it comes from your instruments (e.g., voltage recordings, behavioral videos)

- **processing** - 
  Processed or analyzed data, organized into processing modules

- **analysis** - 
  Results of analysis, like trial averages or population statistics

- **general_subject** - 
  Information about the experimental subject (requires a :class:`types.core.Subject` object)

**Additional metadata properties**
  Various ``general_*`` properties for experimenter, institution, lab, etc.



Validation and Error Handling
-----------------------------

MatNWB validates your :class:`NwbFile` object at different points:

1. **Property assignment**: Data types and shapes are checked when you create objects or set properties
2. **File export**: Required properties and complete schema validation

If validation fails, you'll get specific error messages explaining what needs to be fixed. This helps catch problems early rather than discovering them when trying to share or reuse your data.
