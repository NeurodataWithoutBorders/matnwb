Installing Published Extensions
-------------------------------

In MatNWB, use the function :func:`nwbInstallExtension` to download and generate classes
for published Neurodata Extensions:

.. code-block:: MATLAB

    nwbInstallExtension("ndx-extension")

Replace ``ndx-extension`` with the name of an actual extension. For a complete 
list of published extensions, use the function :func:`matnwb.extension.listExtensions` or 
visit the `Neurodata Extension Catalog <https://nwb-extensions.github.io>`_.
