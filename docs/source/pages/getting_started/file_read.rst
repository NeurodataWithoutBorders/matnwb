Reading with MatNWB
===================

For most files, MatNWB only requires the :func:`nwbRead` call:

.. code-block:: MATLAB

    nwb = nwbRead('path/to/filename.nwb');

This call will read the file, create the necessary NWB schema class files, as well as any extension schemata that is needed for the file itself. This is because both PyNWB and MatNWB embed a copy of the schema environment into the NWB file when it is written.


The returned object above is an :class:`NwbFile` object which serves as the root object with which you can use to browse the contents of the file. More detail about the NwbFile class can be found here: :ref:`matnwb-read-nwbfile-intro`.

.. toctree::
    :maxdepth: 2

    file_read/nwbfile
    file_read/dynamictable
    file_read/untyped
    file_read/troubleshooting