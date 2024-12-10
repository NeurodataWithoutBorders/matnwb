Writing a Properly Documented MATLAB Docstring
==============================================

A well-documented MATLAB function should be structured to provide all necessary details about its purpose, usage, inputs, outputs, and examples in a clear and consistent format. This guide outlines the key sections and formatting rules to follow when documenting MATLAB functions, using ``NWBREAD`` as an example.

1. Function Summary
-------------------

Provide a one-line summary of the function's purpose at the very beginning of the docstring. Use uppercase function names followed by a concise description.

**Example**::

   % NWBREAD - Read an NWB file.

2. Syntax Section
------------------

Document the different ways the function can be called (function signatures). Include all variations and briefly describe their purpose. Each syntax line should start with a code literal and describe what it does.

**Example**::

   % Syntax:
   %  nwb = NWBREAD(filename) Reads the nwb file at filename and returns an
   %  NWBFile object representing its contents.
   %
   %  nwb = NWBREAD(filename, flags) Reads the nwb file using optional 
   %  flags controlling the mode for how to read the file. See input
   %  arguments for a list of available flags.
   %
   %  nwb = NWBREAD(filename, Name, Value) Reads the nwb file using optional 
   %  name-value pairs controlling options for how to read the file.

3. Input Arguments
-------------------

Provide a detailed description of all input arguments. Use the following format for each input:
- Start with a ``-`` followed by the argument name.
- Add the argument type in parentheses (e.g., ``(string)``).
- Write a concise description on the same line or in an indented paragraph below.
- For optional or additional parameters, list their sub-arguments as indented items.

**Example**::

   % Input Arguments:
   %  - filename (string) - 
   %    Filepath pointing to an NWB file.
   % 
   %  - flags (string) -
   %    Flag for setting the mode for the NWBREAD operation. Available options are:
   %    'ignorecache'. If the 'ignorecache' flag is used, classes for NWB data types
   %    are not re-generated based on the embedded schemas in the file.
   % 
   %  - options (name-value pairs) -
   %    Optional name-value pairs. Available options:
   %  
   %    - savedir (string) -
   %      A folder to save generated classes for NWB types.

4. Output Arguments
--------------------

Document all outputs of the function. Use a similar format as the input arguments:
- Start with a ``-`` followed by the output name.
- Add the output type in parentheses.
- Provide a brief description.

**Example**::

   % Output Arguments:
   %  - nwb (NwbFile) - Nwb file object

5. Usage Examples
------------------

Provide practical examples of how to use the function. Each example should:
- Start with "Example X - Description" and be followed by a colon (``::``).
- Include MATLAB code blocks, indented with spaces.
- Add comments in the code to explain each step if necessary.

**Example**::

   % Usage:
   %  Example 1 - Read an NWB file::
   %
   %    nwb = nwbRead('data.nwb');
   %
   %  Example 2 - Read an NWB file without re-generating classes for NWB types::
   %
   %    nwb = nwbRead('data.nwb', 'ignorecache');
   %
   %  Note: This is a good option to use if you are reading several files
   %  which are created of the same version of the NWB schemas.
   %
   %  Example 3 - Read an NWB file and generate classes for NWB types in the current working directory::
   %
   %    nwb = nwbRead('data.nwb', 'savedir', '.');

6. See Also
-----------

Use the ``See also:`` section to reference related functions or objects. List each item separated by commas and include cross-references if applicable.

**Example**::

   % See also:
   %   generateCore, generateExtension, NwbFile, nwbExport

7. Formatting Tips
-------------------

- **Consistent Indentation**:
  - Indent descriptions or additional information using two spaces.

- **Bold Text**:
  - Use ``**`` around key elements like argument names in the rendered documentation.

- **Code Literals**:
  - Use double backticks (``) for MATLAB code snippets in descriptions.

- **Directives**:
  - Use Sphinx-compatible directives for linking (``:class:``, ``:func:``, etc.) when writing in RST.

8. Final Example
-----------------

**Complete Example**::

   % NWBREAD - Read an NWB file.
   %
   % Syntax:
   %  nwb = NWBREAD(filename) Reads the nwb file at filename and returns an
   %  NWBFile object representing its contents.
   %
   %  nwb = NWBREAD(filename, flags) Reads the nwb file using optional 
   %  flags controlling the mode for how to read the file. See input
   %  arguments for a list of available flags.
   %
   %  nwb = NWBREAD(filename, Name, Value) Reads the nwb file using optional 
   %  name-value pairs controlling options for how to read the file.
   %
   % Input Arguments:
   %  - filename (string) - 
   %    Filepath pointing to an NWB file.
   % 
   %  - flags (string) -
   %    Flag for setting the mode for the NWBREAD operation. Available options are:
   %    'ignorecache'. If the 'ignorecache' flag is used, classes for NWB data types
   %    are not re-generated based on the embedded schemas in the file.
   % 
   %  - options (name-value pairs) -
   %    Optional name-value pairs. Available options:
   %  
   %    - savedir (string) -
   %      A folder to save generated classes for NWB types.
   %
   % Output Arguments:
   %  - nwb (NwbFile) - Nwb file object
   %
   % Usage:
   %  Example 1 - Read an NWB file::
   %
   %    nwb = nwbRead('data.nwb');
   %
   %  Example 2 - Read an NWB file without re-generating classes for NWB types::
   %
   %    nwb = nwbRead('data.nwb', 'ignorecache');
   %
   %  Note: This is a good option to use if you are reading several files
   %  which are created of the same version of the NWB schemas.
   %
   %  Example 3 - Read an NWB file and generate classes for NWB types in the current working directory::
   %
   %    nwb = nwbRead('data.nwb', 'savedir', '.');
   %
   % See also:
   %   generateCore, generateExtension, NwbFile, nwbExport
