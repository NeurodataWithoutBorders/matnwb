.. _how_to_reading_data_in_units:

Reading TimeSeries Data in Units
================================

This guide shows you how to get the data of a :class:`types.core.TimeSeries` in the unit of measurement named by its ``data_unit`` property. The stored values are scaled into that unit by ``data_conversion`` and ``data_offset``, and for an :class:`types.core.ElectricalSeries` also by the per-channel ``channel_conversion``. The methods below apply them for you.

.. contents::
   :local:
   :depth: 2

Getting the whole dataset
-------------------------

``getDataInUnits`` reads the dataset and applies the conversion:

.. code-block:: MATLAB

    nwb = nwbRead('myfile.nwb');
    timeSeries = nwb.acquisition.raw_signal;

    volts = timeSeries.getDataInUnits();

The result is ``double``, or ``single`` when the stored data is ``single``. Integer data is promoted before the conversion is applied, so use this method rather than multiplying ``data`` by ``data_conversion`` yourself, which keeps the result in the integer type and saturates it. This reads the whole dataset into memory.

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

``'Channels'`` is only needed when the subset holds some of the channels. A subset that holds all of them, or a :class:`types.core.TimeSeries` with no ``channel_conversion``, does not need it.
