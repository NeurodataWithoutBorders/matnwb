Generating Extension API
------------------------

If you have created a neurodata extension or have the files for a third-party 
extension locally, you can use the MatNWB function :func:`generateExtension` to 
create MATLAB classes for the extension (replace the path argument with the real
path name to the namespace.yaml file):

.. code-block:: MATLAB

    generateExtension("path/to/extension/namespace.yaml")

The class files will be generated under the ``+types/+<extension>`` namespace in
the matnwb root directory, and can be accessed via standard MATLAB class syntax.
For example, if we had an extension called ``ndx-example`` which defined a 
``TetrodeSeries`` neurodata type, we would call:

.. code-block:: MATLAB

    ts = types.ndx_example.TetrodeSeries(<arguments>);

.. important::
    Spaces are not allowed in Neurodata Extensions names, and ``-`` is used instead. 
    In MATLAB, any occurrence of ``-`` is converted to ``_``, and in general, MatNWB 
    will convert namespace names if they are not valid MATLAB identifiers. See 
    `Variable Names <https://www.mathworks.com/help/matlab/matlab_prog/variable-names.html>`_ 
    for more information. In most cases, the conversion conforms with MATLAB's approach 
    with `matlab.lang.makeValidName() <https://www.mathworks.com/help/matlab/ref/matlab.lang.makevalidname.html>`_

To generate MatNWB classes in a custom location, you can use the optional ``savedir`` argument:

.. code-block:: MATLAB

    generateExtension("path/to/ndx-example/namespace.yaml", ...
        "savedir", "my/temporary/folder")

.. note::
    Generating extensions in a custom location is generally not needed, 
    but is useful in advanced use cases like running tests or in other situations 
    where you need to better control the MATLAB search path.
