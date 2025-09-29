Understanding MatNWB Neurodata Types
====================================

MatNWB neurodata types are MATLAB classes designed to represent different kinds of neuroscience data in a structured and interoperable way. They combine data, metadata, and contextual information, enabling consistent organization, interpretation, and sharing across tools and research environments.

Why Use Specialized Neurodata Types?
------------------------------------

Standard MATLAB data structures like arrays or structs are flexible but lack domain-specific constraints. MatNWB types provide additional structure and semantics that are essential for reliable data handling in neuroscience:

- **Domain-specific structure**: Each type encodes the metadata and relationships required for a particular data modality. For example, a :class:`types.core.ElectricalSeries` requires electrode metadata, sampling information, and data units.
- **Built-in validation**: Types enforce the presence of essential information, reducing the likelihood of common errors. For instance, :class:`types.core.TwoPhotonSeries` cannot be created without specifying the imaging plane.
- **Interoperability**: Data stored using these types is compatible with NWB-compliant tools and workflows, making it easier to share and reuse across different software ecosystems.

The Central Concept: TimeSeries
-------------------------------

Many experimental signals in neuroscience change over time. The :class:`types.core.TimeSeries` type provides a standardized structure for representing these signals together with their temporal context.

A TimeSeries object combines:

- **Data and meaning**: The recorded measurements alongside descriptions of what they represent.
- **Temporal information**: Flexible handling of regular or irregular sampling, timestamps, and time references.
- **Metadata**: Units, descriptions, and experiment-specific context stored together with the data.
- **Relationships**: References to other objects, such as stimulus definitions or behavioral events.

Use a basic TimeSeries when the data varies over time but does not require the additional structure of a specialized type. Examples include custom behavioral metrics, environmental sensor data, or novel measurement modalities.

Specialized TimeSeries Variants
-------------------------------

MatNWB builds on the TimeSeries concept with specialized types tailored to common experimental data. These types capture modality-specific metadata, constraints, and relationships.

**ElectricalSeries: Electrical Recordings**

Electrophysiological recordings require metadata about the electrodes, their positions, and acquisition parameters. :class:`types.core.ElectricalSeries` links time-varying voltage data with this contextual information, allowing downstream tools to interpret the signals accurately.

**TwoPhotonSeries and OnePhotonSeries: Optical Recordings**

Optical recordings, such as calcium imaging, differ fundamentally from electrical recordings. These types include metadata about imaging planes, indicators, and acquisition parameters (e.g., excitation wavelength), reflecting the experimental conditions required to interpret fluorescence-based signals.

**SpatialSeries: Positional and Movement Data**

Behavioral tracking data records spatial coordinates over time. :class:`types.core.SpatialSeries` includes information about reference frames, coordinate systems, and spatial dimensions, which are necessary for interpreting positional measurements correctly.

Container Types: Organizing Related Data
----------------------------------------

Some MatNWB types act as containers for other data objects, structuring them into logical groupings.

**ProcessingModule: Analysis Grouping**

Experiments often produce multiple derived datasets from different processing steps. :class:`types.core.ProcessingModule` groups these results, preserving their relationships to raw data and to each other within an analysis workflow.

**Behavioral Containers: Position, CompassDirection, BehavioralEvents**

Behavioral experiments frequently generate multiple types of measurements. Container types provide a consistent organizational structure for these related datasets, making it easier for collaborators and tools to understand their relationships.

Table-Based Types: Structured Metadata
--------------------------------------

Not all experimental information is time-series based. Some metadata is better represented in tabular form, particularly when it describes static properties or discrete events.

**Units Table: Discrete Spike Data**

Sorted spike data consists of discrete events (spikes) that occur at variable times. The :class:`types.core.Units` table organizes spike times, waveforms, and unit metadata in a structured and queryable way.

**Electrode Tables: Recording Site Metadata**

Metadata describing recording sites—such as electrode position, impedance, and brain region—is typically static during an experiment. Electrode tables store this information once and allow it to be referenced by multiple data types.

Working with MatNWB Types
-------------------------

MatNWB neurodata types use object-oriented design principles to integrate structure, validation, and relationships directly into the data model:

- **Object properties**: Each type defines a fixed set of properties, ensuring required metadata is always present and validated when objects are created.
- **Automatic linking**: References between related objects (e.g., an ElectricalSeries referencing an electrode table) are handled automatically.
- **Extensibility**: While core properties are fixed, additional metadata can be attached as needed to capture experiment-specific details.
- **Error prevention**: Structural validation reduces errors by detecting missing information, type mismatches, or inconsistent shapes early.

Selecting the Appropriate Type
------------------------------

Choosing the right type depends on the nature of the data and how it fits into the broader experimental context. Consider the following questions:

- What is being measured? (e.g., electrical activity, fluorescence, position)
- How is it related to other parts of the experiment?
- What metadata is required to interpret the measurement?
- Would another researcher understand the data structure without additional explanation?

A practical approach is to begin with the general :class:`types.core.TimeSeries` for any time-varying data. As familiarity increases, adopt more specialized types that better capture the semantics and constraints of specific experimental modalities.

Organize data to reflect the experimental workflow: raw measurements in acquisition, processed results in processing modules, and analysis outputs in analysis groups. This structure aligns the data model with the scientific process and supports reproducibility and interoperability.
