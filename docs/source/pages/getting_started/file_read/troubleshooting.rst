.. _matnwb-read-troubleshooting-intro:

Troubleshooting File Reads in MatNWB
====================================

Outlined below are the most common issues reported by users when they read a NWB file as well as common troubleshooting approaches to resolve them.

.. _matnwb-read-troubleshooting-version-conflict:

Schema Version Conflicts
~~~~~~~~~~~~~~~~~~~~~~~~

If you run into an error where reading a file appears to expect the wrong properties, you should first check if your MATLAB path is not pointing to other environments with the same packages. MATLAB's internal `which command <https://www.mathworks.com/help/matlab/ref/which.html>`_ to check for unexpected class locations.

.. _matnwb-read-troubleshooting-multiple-env:

Multiple Schema Environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, MatNWB generates all class files in its own installation directory. However, if your work requires you to manipulate multiple different schema versions or extension environments, you may want to generate the class files in a local directory so that MATLAB will default to those classes instead.

To do this, you can use the optional ``savedir`` keyword argument with ``nwbRead`` which allows you to specify a directory location within which your generated class files will be saved.

.. code-block:: MATLAB

    nwb = nwbRead('/path/to/matnwb/file.nwb', 'savedir', '.'); % write class files to current working directory.

.. note::

    Other generation functions ``generateCore`` and ``generateExtension`` also support the ``savedir`` option.

.. _matnwb-read-troubleshooting-missing-schema:

Missing Embedded Schemata
~~~~~~~~~~~~~~~~~~~~~~~~~

Some older NWB files do not have an embedded schema. To read from these files you will need the API generation functions ``generateCore`` and ``generateExtension`` to generate the class files before calling ``nwbRead`` on them. You can also use the utility function ``util.getSchemaVersion`` to retrieve the correct Core schema for the file you are trying to read:

.. code-block:: MATLAB

    schemaVersion = util.getSchemaVersion('/path/to/matnwb/file.nwb');
    generateCore(schemaVersion);
    generateExtension(path/to/extension/namespace.yaml);

.. _matnwb-read-troubleshooting-ignorecache:

Avoiding Class Regeneration
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you wish to read your file multiple times, you may not want to regenerate your files every time since you know that your current environment is correct. For this case, you can use ``nwbRead``'s optional argument ``ignorecache`` which will ignore the embedded schema and attempt to read your file with the class files accessible from your MATLAB path or current working directory.

.. code-block:: MATLAB
    
    nwb = nwbRead('path/to/matnwb/file.nwb', 'ignorecache');

.. _matnwb-read-troubleshooting-bottom:

Bottom of the Barrel
~~~~~~~~~~~~~~~~~~~~

If you're here, you've probably reached your wit's end and wish for more specific help. In such times, you can always contact the NWB team either as a message on our `NWB HelpDesk <https://github.com/NeurodataWithoutBorders/helpdesk/discussions>`_, `Slack Workspace <https://join.slack.com/t/nwb-users/shared_invite/enQtNzMwOTcwNzQ2MDM5LWMyZDUwODJjYjM3MzMzYzZiNDk4ZTU3ZjQ3MmMxMmY5MDUyNzc0ZDI5ZjViYmJjYTQ5NjljOGFjZmMwOGIwZmQ>`_ or as an issue on `Github <https://github.com/NeurodataWithoutBorders/matnwb>`_.
