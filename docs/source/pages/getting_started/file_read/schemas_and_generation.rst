.. _matnwb-read-schemas-generation:

Schemas and Class Generation
============================

This page covers the advanced concepts behind how MatNWB works with NWB schemas and generates MATLAB classes. Understanding these concepts can help you troubleshoot issues and work with custom extensions.

What are NWB Schemas?
---------------------

NWB schemas are formal specifications that define:

- **Data types** and their properties
- **Relationships** between different data types  
- **Validation rules** for data integrity
- **File organization** standards

Think of schemas as blueprints that ensure all NWB files follow the same organizational principles, regardless of who created them or what software was used.

Schema Versions
~~~~~~~~~~~~~~~

NWB schemas evolve over time to add new features and fix issues. Each version is identified by a number (e.g., "2.6.0", "2.7.0"). When you read an NWB file, MatNWB automatically detects which schema version was used to create it.

You can check a file's schema version:

.. code-block:: MATLAB

    version = util.getSchemaVersion('path/to/file.nwb');
    fprintf('File uses NWB schema version: %s\n', version);

How MatNWB Generates Classes
----------------------------

When you call ``nwbRead``, MatNWB performs several steps behind the scenes:

1. **Reads the file's embedded schema** information
2. **Generates MATLAB classes** that correspond to the data types in the file
3. **Creates an object hierarchy** that matches the file's structure

This process ensures that the MATLAB objects you work with accurately represent the standardized NWB data types.

Embedded vs. External Schemas
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Embedded Schemas** (most common):
Modern NWB files contain their schema information embedded within the file itself. This makes the files self-contained and ensures compatibility.

**External Schemas** (older files):
Some older NWB files don't contain embedded schemas. For these files, you need to generate the appropriate classes manually before reading.

Automatic Class Generation
---------------------------

For files with embedded schemas, MatNWB handles class generation automatically:

.. code-block:: MATLAB

    % This automatically generates classes as needed
    nwb = nwbRead('modern_file.nwb');

The generated classes are saved in the MatNWB installation directory and reused for subsequent reads of files with the same schema.

Manual Class Generation
-----------------------

For older files or when working with specific schema versions, you may need to generate classes manually.

Generating Core Classes
~~~~~~~~~~~~~~~~~~~~~~~

Use :func:`generateCore` to create classes for the core NWB schema:

.. code-block:: MATLAB

    % Generate classes for the latest NWB version
    generateCore();
    
    % Generate classes for a specific version
    generateCore('2.6.0');
    
    % Generate classes in a custom directory
    generateCore('savedir', '/path/to/custom/directory');

Generating Extension Classes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a file uses custom extensions, use :func:`generateExtension`:

.. code-block:: MATLAB

    % Generate classes for a custom extension
    generateExtension('/path/to/extension.namespace.yaml');
    
    % Generate multiple extensions
    generateExtension('ext1.namespace.yaml', 'ext2.namespace.yaml');

Reading Files Without Regeneration
-----------------------------------

If you're reading multiple files with the same schema, you can skip class regeneration for faster loading:

.. code-block:: MATLAB

    % Skip automatic class generation
    nwb = nwbRead('file.nwb', 'ignorecache');

This is useful when:

- Reading many files from the same experiment
- You know the classes are already generated and current
- You want faster file loading

.. warning::
    Using 'ignorecache' with files that have different schemas than your generated classes can cause errors or incorrect data interpretation.

Custom Save Directories
------------------------

By default, MatNWB saves generated classes in its installation directory. You can specify a custom location:

.. code-block:: MATLAB

    % Generate classes in current working directory
    nwb = nwbRead('file.nwb', 'savedir', '.');
    
    % Generate classes in a specific directory
    nwb = nwbRead('file.nwb', 'savedir', '/path/to/classes');

This is useful when:

- Working with multiple schema versions simultaneously
- You don't have write permissions to the MatNWB installation directory
- You want to keep different projects' classes separate

Understanding Class Files
--------------------------

Generated classes are saved as MATLAB .m files in a ``+types`` package directory structure:

.. code-block:: text

    +types/
    ├── +core/           % Core NWB types
    │   ├── TimeSeries.m
    │   ├── ElectricalSeries.m
    │   └── ...
    ├── +hdmf_common/    % Common HDMF types
    │   ├── DynamicTable.m
    │   └── ...
    └── +extension_name/ % Custom extension types
        └── CustomType.m

These classes define the properties and methods for each NWB data type, enabling the object-oriented interface you use when working with NWB data.

Schema Validation
-----------------

MatNWB validates that the embedded schemas in a file match the generated classes. If there's a mismatch, you may see warnings or errors suggesting:

- Regenerating classes for the file's schema version
- Using ``generateCore`` with the correct version
- Checking for schema version conflicts

Working with Multiple Schema Versions
--------------------------------------

When working with files from different NWB versions or with different extensions, consider these strategies:

**Separate Directories:**

.. code-block:: MATLAB

    % Generate classes for different versions in separate directories
    generateCore('2.6.0', 'savedir', 'nwb_2_6_0_classes');
    generateCore('2.7.0', 'savedir', 'nwb_2_7_0_classes');
    
    % Add the appropriate directory to your path before reading
    addpath('nwb_2_6_0_classes');
    nwb_old = nwbRead('old_file.nwb', 'ignorecache');

**Project-Specific Classes:**

.. code-block:: MATLAB

    % Generate classes in your project directory
    project_dir = '/path/to/my/project';
    generateCore('savedir', project_dir);
    generateExtension('my_extension.yaml', 'savedir', project_dir);
    
    % Read files using project-specific classes
    nwb = nwbRead('project_file.nwb', 'savedir', project_dir);

Troubleshooting Schema Issues
-----------------------------

**Version Conflicts:**

If you see errors about incompatible classes or missing properties:

.. code-block:: MATLAB

    % Check the file's schema version
    file_version = util.getSchemaVersion('problematic_file.nwb');
    
    % Generate classes for that specific version
    generateCore(file_version);
    
    % Try reading again
    nwb = nwbRead('problematic_file.nwb');

**Missing Extensions:**

If a file uses custom extensions you don't have:

.. code-block:: MATLAB

    % Let MatNWB generate from embedded schemas
    nwb = nwbRead('file_with_extensions.nwb');
    
    % Or generate the extension manually if you have the schema file
    generateExtension('/path/to/extension.namespace.yaml');

**Class Path Issues:**

If MATLAB can't find the generated classes:

.. code-block:: MATLAB

    % Check if the types directory is on your path
    which types.core.TimeSeries
    
    % Add the directory containing +types to your path
    addpath('/path/to/directory/containing/types');
    
    % Refresh MATLAB's function cache
    rehash;

Best Practices
--------------

1. **Let MatNWB handle schema generation automatically** when possible
2. **Use 'ignorecache' only when you're sure about schema compatibility**
3. **Keep different schema versions in separate directories** if working with multiple versions
4. **Check schema versions** when troubleshooting read errors
5. **Use custom save directories** for project-specific work

Understanding these schema concepts will help you work more confidently with NWB files and troubleshoot issues when they arise. For most users, the automatic schema handling in ``nwbRead`` will be sufficient, but these advanced features provide flexibility for complex workflows.
