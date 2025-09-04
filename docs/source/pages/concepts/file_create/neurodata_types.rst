Understanding MatNWB Neurodata Types
====================================

MatNWB neurodata types are specialized MATLAB classes that represent different kinds of neuroscience data. These types provide structured containers that hold your data along with the metadata and organizational information needed to interpret it correctly.

Why Specialized Types Instead of Standard Data Types?
-----------------------------------------------------

MatNWB's neurodata types have several advantages compared to using generic MATLAB arrays or structs for storing data:

**They encode domain knowledge**: Each type includes the specific requirements for neuroscience data. A :class:`types.core.ElectricalSeries` requires electrode information, sampling rates, and data units - enforcing these requirements automatically rather than relying on you to remember them.

**They prevent common mistakes**: The types guide you toward correct data organization. For example, you cannot store imaging data without specifying the imaging plane when using :class:`types.core.TwoPhotonSeries`.

**They ensure compatibility**: Data stored in these types will work with other NWB tools and can be shared with collaborators who use different analysis software.

The Foundation: TimeSeries
---------------------------

Most neuroscience data varies over time, so MatNWB builds around a fundamental concept: :class:`types.core.TimeSeries`. This isn't just a MATLAB array with timestamps - it's a structured way to represent any measurement that changes over time.

**What TimeSeries provides:**

- **Data with context**: Your measurements plus information about what they represent
- **Time handling**: Flexible ways to represent regular or irregular sampling
- **Metadata storage**: Data units, descriptions, and experimental details stay attached to the data
- **Relationship tracking**: Connections to other parts of your experiment

**When to use basic TimeSeries**: For any time-varying measurement that doesn't fit a more specific type - like custom behavioral metrics, environmental sensors, or novel measurement techniques.

Specialized TimeSeries Types
----------------------------

MatNWB provides specialized versions of TimeSeries for common neuroscience data types. These aren't just conveniences - they capture the specific requirements and relationships of different experimental approaches.

**ElectricalSeries: For Electrical Recordings**

Understanding electrical recordings requires knowing which electrodes recorded the data, their locations, and recording parameters. :class:`types.core.ElectricalSeries` handles these relationships automatically.

The key insight: electrical data isn't just voltages over time - it's voltages from specific spatial locations in the brain, recorded with particular methods and settings.

**TwoPhotonSeries and OnePhotonSeries: For Optical Data**  

Calcium imaging data has fundamentally different characteristics than electrical recordings. These types understand that optical data comes from specific imaging planes, uses particular indicators, and has unique technical parameters like excitation wavelengths.

The key insight: optical data represents neural activity indirectly through fluorescence changes, requiring different metadata and processing considerations.

**SpatialSeries: For Position and Movement**

Behavioral tracking data represents the subject's position or movement through space. :class:`types.core.SpatialSeries` understands spatial coordinates, reference frames, and the relationship between position and time.

The key insight: spatial data requires coordinate system information to be meaningful - the same X,Y coordinates mean different things in different reference frames.

Container Types: Organizing Related Data
----------------------------------------

Some neurodata types don't hold data directly - they organize other types into meaningful groups.

**ProcessingModule: Grouping Related Analyses**

Experiments often involve multiple processing steps that belong together. :class:`types.core.ProcessingModule` lets you group related processed data, maintaining the logical flow of your analysis pipeline.

The key insight: processed data gains meaning through its relationship to the raw data and processing steps that created it.

**Position, CompassDirection, BehavioralEvents: Behavioral Organization**

These container types organize different aspects of behavioral data. Rather than scattering behavioral measurements throughout your file, they provide structured locations that other researchers will recognize.

The key insight: behavioral experiments often involve multiple simultaneous measurements that need to be understood as a coordinated whole.


Table-Based Types: Structured Metadata
--------------------------------------

Some experimental information is naturally tabular rather than time-series based.

**Units Table: Spike Data Organization**

Sorted spike data doesn't fit well into TimeSeries because each unit has different spike times. The :class:`types.core.Units` table provides a structured way to store spike times, waveforms, and unit metadata together.

The key insight: spike sorting creates discrete events (spikes) rather than continuous measurements, requiring different organizational principles.

**Electrode Tables: Recording Site Information**

Information about recording electrodes (location, impedance, brain region) is relatively static but essential for interpreting electrical data. Electrode tables store this information once and allow multiple data types to reference it.

The key insight: experimental metadata often has different temporal characteristics than the data itself - electrode properties don't change during recording, but voltage measurements do.


How MatNWB Types Work in Practice
---------------------------------

- **Object-Oriented Organization**: Each neurodata type is a MATLAB class with specific properties. When you create an object, MATLAB ensures you provide the required information and validates the data types.

- **Automatic Relationships**: Types understand their relationships to other types. When you reference an electrode table from an ElectricalSeries, MatNWB maintains that connection automatically.

- **Flexible Extension**: While types have required properties, you can add additional information as needed. This lets you capture experiment-specific details while maintaining compatibility.

- **Validation and Error Prevention**: Types catch common errors before they become problems. Missing required properties, incorrect data shapes, or type mismatches generate helpful error messages.

Choosing the Right Type
-----------------------

The goal isn't to memorize every available type, but to understand the principle: **match your data to the type that best represents its experimental meaning**.

**Ask yourself:**

- What kind of measurement is this? (electrical, optical, behavioral, etc.)
- How does it relate to other parts of my experiment?
- What contextual information is needed to interpret it?
- Would another researcher understand this data organization?

**Start simple**: When in doubt, basic TimeSeries can represent any time-varying data. You can always use more specific types as you become familiar with them.

**Follow the data flow**: Raw measurements go in acquisition, processed results go in processing modules, final analyses go in analysis. This mirrors your experimental workflow.
