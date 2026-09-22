.. _how_to_reading_data_in_units:

Reading TimeSeries Data in Units
================================

This guide shows you how to get the data of a :class:`types.core.TimeSeries` in the unit of measurement named by its ``data_unit`` property.

.. contents::
   :local:
   :depth: 2

Stored values are not in ``data_unit``
--------------------------------------

The ``data`` of a :class:`types.core.TimeSeries` holds the values as the acquisition system produced them, which is often integer counts. ``data_unit`` names the unit those values are *meant to be read in*, and two further properties say how to get there:

.. code-block:: MATLAB

    data = rawData * data_conversion + data_offset

Both default to the identity (``data_conversion = 1``, ``data_offset = 0``), so a file whose writer stored calibrated values reads correctly as is. A file whose writer stored raw counts does not: the same array is off by whatever ``data_conversion`` is, and nothing in the array itself says so. An :class:`types.core.ElectricalSeries` may add a per-channel ``channel_conversion`` on top of the global one.

Getting the whole dataset
-------------------------

``getDataInUnits`` reads the dataset and applies the conversion for you:

.. code-block:: MATLAB

    nwb = nwbRead('myfile.nwb');
    timeSeries = nwb.acquisition.raw_signal;

    volts = timeSeries.getDataInUnits();

The result is ``double``, or ``single`` when the stored data is ``single``. This reads the whole dataset into memory.

Getting a subset of a large dataset
-----------------------------------

Data read from a file is a :ref:`DataStub <matnwb-read-untyped-datastub-datapipe>`, so indexing it loads only the part you ask for. Pass that part to ``applyConversion``, which scales it the same way:

.. code-block:: MATLAB

    rawSubset = timeSeries.data(1:1000);
    volts = timeSeries.applyConversion(rawSubset);

For an :class:`types.core.ElectricalSeries` with a per-channel ``channel_conversion``, name the channels the subset holds so that each one gets its own factor:

.. code-block:: MATLAB

    rawSubset = electricalSeries.data(3:5, 1:30000);
    volts = electricalSeries.applyConversion(rawSubset, 'Channels', 3:5);

Channels lie along the first dimension of the array in MatNWB, even though ``channel_conversion`` describes axis 1 of the dataset in the file; see :doc:`Dimension ordering </pages/concepts/dimension_ordering>` for why. ``'Channels'`` is only needed when the subset holds some of the channels. A subset that holds all of them, or a :class:`types.core.TimeSeries` with no ``channel_conversion``, does not need it.

Why not multiply by hand
------------------------

Integer arithmetic in MATLAB rounds and saturates instead of promoting, so scaling stored integers directly keeps them integers:

.. code-block:: MATLAB

    timeSeries = types.core.TimeSeries( ...
        'data', int16([-32768; 0; 32767]), ...
        'data_unit', 'volts', ...
        'data_conversion', 2.5/32768, ...
        'starting_time', 0, 'starting_time_rate', 30000);

.. code-block:: MATLAB

    >> timeSeries.data * timeSeries.data_conversion

       -3
        0
        2

    >> timeSeries.getDataInUnits()

       -2.5000
             0
        2.4999

Both methods cast the data to a floating point type before applying the conversion.
