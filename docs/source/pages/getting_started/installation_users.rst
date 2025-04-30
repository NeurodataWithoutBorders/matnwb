Install MatNWB
==============

Download the current release of MatNWB from the 
`MatNWB releases page <https://github.com/NeurodataWithoutBorders/matnwb/releases>`_ 
or from the `MATLAB's FileExchange <https://www.mathworks.com/matlabcentral/fileexchange/67741-neurodatawithoutborders-matnwb>`_. 
You can also check out the latest development version via::

    git clone https://github.com/NeurodataWithoutBorders/matnwb.git

After downloading MatNWB, make sure to add it to MATLAB's search path:

.. code-block:: matlab

    addpath("path/to/matnwb")
    savepath() % Permanently add to search path

Requirements
------------
MatNWB requires MATLAB R2019b or newer. As a general rule, we strive to maintain 
compatibility with MATLAB releases from the past five years.

**Known exceptions**:

* Dynamically loaded filters for dataset compression are supported only in MATLAB R2022a or later.