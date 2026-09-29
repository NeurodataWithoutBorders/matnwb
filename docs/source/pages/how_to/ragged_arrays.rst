.. _how_to_ragged_arrays:

Storing Ragged and Doubly-Ragged Array Columns
===============================================

This guide shows you how to store columns of a :class:`types.hdmf_common.DynamicTable`
that hold a *variable* number of items per row.

.. contents::
   :local:
   :depth: 2

Overview
--------
Most :class:`types.hdmf_common.DynamicTable` columns have exactly one value per row.
Some columns instead need a *variable* number of values per row. NWB stores these as
**ragged arrays**:

- A **ragged array** stores a variable number of elements per row (for example, the
  spike times of each unit). It is backed by a :class:`types.hdmf_common.VectorData`
  column plus a companion :class:`types.hdmf_common.VectorIndex`
  (named ``<column>_index``) that marks each row's boundary.
- A **doubly-ragged array** adds a second level of variability: each row holds a
  variable number of sub-groups, and each sub-group holds a variable number of
  fixed-length elements. The canonical example is the :class:`types.core.Units`
  ``waveforms`` column: per unit, a variable number of spike events, each with one
  waveform per recording electrode. It is backed by a
  :class:`types.hdmf_common.VectorData` column plus two
  :class:`types.hdmf_common.VectorIndex` levels (``<column>_index`` over sub-groups
  and ``<column>_index_index`` over rows).

For a full description of how NWB represents these on disk — including a diagram of the
doubly-ragged layout — see the "Tables and ragged arrays" and "Doubly ragged arrays"
sections of the :nwb-format-description:`NWB format specification <tables-and-ragged-arrays>`.

MatNWB provides one :class:`types.hdmf_common.DynamicTable` method that builds and wires
these objects for you in a single call: ``addRaggedArray``. Its ``Depth`` argument sets
the number of index levels: 1 (the default) for a ragged column, 2 for a doubly-ragged
column. ``addDoublyRaggedArray`` is a shorthand for ``Depth`` 2. Its ``ElementsPerRow``
argument builds a ragged column from data that is already flat.

.. note::

   ``addRaggedArray`` builds a whole column in one call. ``addRow`` can also build a
   ragged column row by row once the column is listed in ``colnames``, or append rows to
   an existing one. Give a row of scalars as a column vector. For a doubly-ragged column,
   give each row as a cell with one matrix per sub-group, as in the nested form described
   below, without an extra enclosing cell: ``addRow`` does not accept a 3-D row, and it
   reads a ``[numSamples x n]`` matrix as one spike event on ``n`` electrodes.

Data orientation
----------------
Every array you pass to ``addRaggedArray`` uses the same orientation as the ``data``
property of any MatNWB dataset: the schema's dimensions reversed, so the ragged axis
comes **last**. For ``waveforms``, whose schema shape is ``[num_waveforms, num_samples]``,
that means ``[num_samples x num_waveforms]`` with one waveform per column. What you pass
for a row or a spike event is exactly the slice of ``waveforms.data`` that will hold it.
This is the same rule as for a :class:`types.core.TimeSeries` ``data`` array, and the same
rule that maps a PyNWB array to MatNWB: reverse its dimensions.

Ragged arrays
-------------
Pass a cell array with one cell per row; each cell holds that row's elements. For
example, to store the spike times of two units in the :class:`types.core.Units` table:

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: ragged-spike-times
   :end-before: % end snippet
   :dedent:

The ``spike_times`` column now holds all five values, and ``spike_times_index`` is
``[3 5]`` — marking that the first unit owns values 1-3 and the second owns values 4-5.

A row may also be an array whose elements are vectors or arrays rather than scalars:
give it as ``[elementDims x numElements]``, with the elements along the last dimension.
Rows are concatenated along that dimension, so the column's ``data`` is
``[elementDims x totalElements]``.

Referencing another table
~~~~~~~~~~~~~~~~~~~~~~~~~~~
Provide the ``table`` argument to store a
:class:`types.hdmf_common.DynamicTableRegion` (a column of row references) instead of a
plain :class:`types.hdmf_common.VectorData`. For example, to record which electrodes
each unit was detected on (``electrodesTable`` is an existing electrodes table):

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: ragged-electrodes-region
   :end-before: % end snippet
   :dedent:

The values are 0-based row indices into the referenced table.

Text and compound columns
~~~~~~~~~~~~~~~~~~~~~~~~~~
A row can also hold text or compound elements. Each column holds one kind of element:
numeric, text or compound.

For text, give each row as a string vector or a cell vector of character vectors, with
one element per entry. A character vector is a single element. For example, to tag the
trials of a :class:`types.core.TimeIntervals` table:

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: text-column
   :end-before: % end snippet
   :dedent:

The ``tags`` column holds ``["go"; "rewarded"; "nogo"]`` and ``tags_index`` is ``[2 3]``.
The column is a string array when every row is a string array, and a cell array of
character vectors otherwise.

A compound element has named fields, such as the ``x``, ``y`` and ``weight`` of each pixel
in the ``pixel_mask`` column of a :class:`types.core.PlaneSegmentation`. Give each row as
a table with one table row per element:

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: compound-pixel-masks
   :end-before: % end snippet
   :dedent:

The ``pixel_mask`` column holds all five pixels in one table, and ``pixel_mask_index`` is
``[3 5]``. A row can also be a struct array with one struct per element, or a scalar
struct whose fields are equal-length columns. The column is a struct array when every row
is a struct array, and a table otherwise.

Flat data with ``ElementsPerRow``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Your data may already hold all rows in one array, such as the pixels of every ROI from a
segmentation tool, or the spike times of every unit sorted by unit. Instead of splitting
it into one cell per row, pass the whole array together with ``ElementsPerRow``, the
number of elements in each row:

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: flat-pixel-masks
   :end-before: % end snippet
   :dedent:

This builds the same ``pixel_mask`` column as the per-ROI tables above. The flat data can
be a numeric vector, a numeric ``[elementDims x numElements]`` array, text, or compound
data, with the elements of all rows in row order. It keeps its class: a string array gives
a string column, and a struct array a struct column. The sum of ``ElementsPerRow`` must
equal the number of elements. ``ElementsPerRow`` builds ragged columns only
(``Depth`` 1).

Doubly-ragged arrays
--------------------
Use ``addRaggedArray`` with ``Depth`` 2 for columns such as :class:`types.core.Units`
``waveforms``. There are three input forms, depending on how many electrodes contribute
a waveform per spike and whether that number is the same for every spike.

Single electrode (shortcut form)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When each spike has a single waveform (one electrode per unit), pass one
``[numSamples x numWaveforms]`` matrix per unit — one column per waveform, which for a
single electrode is one column per spike (here ``unit1`` is ``[40 x 3]`` and ``unit2`` is
``[40 x 4]``):

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: doubly-single-electrode
   :end-before: % end snippet
   :dedent:

This yields ``waveforms.data = [unit1, unit2]`` (``[40 x 7]``),
``waveforms_index = [1 2 3 4 5 6 7]`` (one waveform per spike) and
``waveforms_index_index = [3 7]`` (3 spikes, then 4 spikes).

Multiple channels (nested form)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When each spike is recorded across several electrodes, each spike has one waveform *per
electrode*. Use a nested cell array where ``data{unit}{spike}`` is a
``[numSamples x numWaveforms]`` matrix — one column per waveform, which here is one per
electrode. Here unit 1 has 2 spikes and unit 2 has 3 spikes, each recorded on 3
electrodes (``m1`` and ``m2`` are the two units' cell arrays of ``[40 x 3]`` per-spike
matrices):

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: doubly-multi-channel
   :end-before: % end snippet
   :dedent:

This yields ``waveforms.data`` of size ``[40 15]`` (``numSamples`` × ``numWaveforms``,
where ``numWaveforms`` = 5 spikes × 3 electrodes = 15), ``waveforms_index = [3 6 9 12
15]`` (3 electrodes per spike), and ``waveforms_index_index = [2 5]`` (2 spikes, then 3
spikes). The ``electrodes`` column is paired in the same order as the waveform columns
within each spike.

.. warning::

   For a multi-channel unit, the order of the waveform columns within each spike must
   match the order of the electrodes listed in that unit's ``electrodes`` row, and each
   spike of a given unit should have the same number of electrodes.

Multiple channels (array shortcut)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When every spike of a unit was recorded on the same electrodes, the nested cell array
can be replaced by one ``[numSamples x numElectrodes x numSpikes]`` array per unit. This
is the ``(numSpikes, numElectrodes, numSamples)`` array PyNWB's ``Units.add_unit`` takes,
with its dimensions reversed, and it produces the same column as the nested form: each
spike becomes one sub-group holding one waveform per electrode. Here ``a1`` is
``[40 x 3 x 2]`` and ``a2`` is ``[40 x 3 x 3]``:

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: doubly-multi-channel-array
   :end-before: % end snippet
   :dedent:

This yields the same ``waveforms.data`` size ``[40 15]``, ``waveforms_index = [3 6 9 12
15]`` and ``waveforms_index_index = [2 5]`` as the nested form above. Dimensions before
the last two, if there are more than one, are kept as part of each element.

Units with different electrode counts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MATLAB drops a trailing dimension of 1, so a ``[numSamples x n]`` matrix fits two forms:
``n`` spikes on one electrode (the single-electrode form), or one spike on ``n``
electrodes (the array shortcut for a unit with one spike). ``addRaggedArray`` reads a
whole column one way:

- If any unit is given as a 3-D ``[numSamples x numElectrodes x numSpikes]`` array, every
  unit is read as the array shortcut. A ``[numSamples x n]`` matrix is then a unit with
  one spike on ``n`` electrodes, and a unit recorded on one electrode must be given as
  ``[numSamples x 1 x numSpikes]``: MATLAB keeps a dimension of 1 that is not the last.
- Otherwise every ``[numSamples x n]`` matrix is the single-electrode form.

The nested form is read the same way in both cases. Here ``b1`` holds 2 spikes on 3
electrodes (``[40 x 3 x 2]``), ``b2`` holds 4 spikes on one electrode (``[40 x 1 x 4]``)
and ``b3`` holds a single spike on 3 electrodes (``[40 x 3]``, its trailing 1 dropped):

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: doubly-mixed-electrode-counts
   :end-before: % end snippet
   :dedent:

This yields ``waveforms_index = [3 6 7 8 9 10 13]`` (3 waveforms for each spike of
``b1``, 1 for each spike of ``b2``, 3 for the spike of ``b3``) and
``waveforms_index_index = [2 6 7]`` (2 spikes, then 4, then 1).

Understanding the two index levels
----------------------------------
For the multi-channel example above:

- ``waveforms.data`` (``[numSamples x numWaveforms]`` = ``[40 x 15]``) holds all 15
  individual waveforms concatenated, one per column, with samples down the rows.
- ``waveforms_index`` (``[3 6 9 12 15]``) has one entry per spike event and marks where
  each spike's waveforms end, so spike 1 owns waveforms 1-3, spike 2 owns 4-6, and so on.
- ``waveforms_index_index`` (``[2 5]``) has one entry per unit and marks where each
  unit's spike events end, so unit 1 owns spikes 1-2 and unit 2 owns spikes 3-5.

Building columns without adding them to a table
-----------------------------------------------
If you need the underlying objects (for example, to pass them to a constructor), use the
helper function that ``addRaggedArray`` builds on: ``util.create_indexed_column`` returns
a :class:`types.hdmf_common.VectorData` (or :class:`types.hdmf_common.DynamicTableRegion`)
followed by one :class:`types.hdmf_common.VectorIndex` per index level, innermost first.
It takes the same ``Depth`` and ``ElementsPerRow`` arguments and the same input forms,
including text and compound rows.

.. literalinclude:: examples/ragged_arrays_examples.m
   :language: matlab
   :start-after: % snippet: helper-functions
   :end-before: % end snippet
   :dedent:
