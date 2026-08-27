%% Linking to External Resources
% HERD, the HDMF External Resources Data Structure, lets you map terms used 
% in your data to entities defined in external, web-accessible resources such 
% as ontologies. For example, you may store a species name |Mus musculus| on a 
% |Subject| and want to link it to the corresponding NCBI Taxonomy term, so that 
% the value is standardised and easy to query.
% 
% From a user's point of view a HERD can be treated as a single table that associates 
% a *key*, a term used on an *object* in the file, with an *entity*, a term in 
% an external resource identified by an |entity_id| and an |entity_uri|. Internally 
% HERD stores this in six linked tables (|keys|, |files|, |entities|, |entity_keys|, 
% |objects| and |object_keys|), and provides methods so you rarely need to work 
% with those tables directly.
% 
% This tutorial creates a file, annotates two values in it, writes the file, 
% and reads the annotations back.
%% Create a file to annotate
% Start with an |NwbFile| describing a mouse. The species is the first value 
% we will annotate.

nwb = NwbFile( ...
    'session_description', 'a demonstration of external resources', ...
    'identifier', 'HERD_TUTORIAL', ...
    'session_start_time', datetime(2018, 4, 25, 2, 30, 3, 'TimeZone', 'local'), ...
    'general_experimenter', 'Lastname, Firstname', ...
    'general_institution', 'My University', ...
    'general_experiment_description', 'annotating values with external resources', ...
    'general_keywords', {'external resources', 'ontology'});
nwb.general_subject = types.core.Subject( ...
    'subject_id', '001', ...
    'description', 'a mouse used in this session', ...
    'species', 'Mus musculus', ...
    'sex', 'M', ...
    'age', 'P90D');
%% Record a reference
% |NwbFile.addRef| records that an object in the file refers to an external 
% entity. A file has at most one HERD, so the first call creates and attaches 
% one and later calls add to it. The object being annotated must already be part 
% of the file, because a reference records which file the object belongs to.
% 
% An entity is identified by an |entity_id| and an |entity_uri|. The |entity_id| 
% is a compact URI of the form |prefix:identifier| whose prefix is registered 
% with <https://bioregistry.io/ bioregistry>, such as |NCBITaxon| for the NCBI 
% Taxonomy. The |entity_uri| is the URL that identifier resolves to, which you 
% can look up at |https://bioregistry.io/<entity_id>|.
% 
% Here the subject's species is linked to the NCBI Taxonomy entry for _Mus musculus_. 
% The object being annotated is the subject, and the key is the value stored on 
% it.

nwb.addRef(nwb.general_subject, ...
    Key = nwb.general_subject.species, ...
    EntityId = "NCBITaxon:10090", ...
    EntityUri = "http://purl.obolibrary.org/obo/NCBITaxon_10090");
%% Reference a column of a table
% A reference can also point at a column of a table rather than at a whole object. 
% Below, a set of electrodes records the brain region each one sits in, and that 
% region is linked to the corresponding structure in the <https://atlas.brain-map.org/ 
% Allen Mouse Brain Atlas>.
% 
% Build the electrodes table first. Every electrode needs a group, and every 
% group needs a device.

device = types.core.Device('description', 'a recording probe');
nwb.general_devices.set('probe', device);
electrodeGroup = types.core.ElectrodeGroup( ...
    'description', 'a shank of the recording probe', ...
    'location', 'VISp', ...
    'device', types.untyped.SoftLink(device));
nwb.general_extracellular_ephys.set('shank0', electrodeGroup);
electrodes = types.core.ElectrodesTable( ...
    'colnames', {'location', 'group', 'group_name'}, ...
    'description', 'electrodes on the recording probe');
nwb.general_extracellular_ephys_electrodes = electrodes;
for iElectrode = 1:4
    electrodes.addRow( ...
        'location', 'VISp', ...
        'group', types.untyped.ObjectView(electrodeGroup), ...
        'group_name', 'shank0');
end
% Annotate the column
% Pass the table as the object and the column name as |Attribute|. The reference 
% is attached to the column itself, which is the object that holds the values, 
% rather than to the table. A ragged column works the same way: |Attribute| names 
% the column holding the values, and the index that groups them into rows is a 
% separate property.

nwb.addRef(nwb.general_extracellular_ephys_electrodes, ...
    Attribute = "location", ...
    Key = "VISp", ...
    EntityId = "MBA:385", ...
    EntityUri = "https://purl.brain-bican.org/ontology/mbao/MBA_385");
%% Inspect the references
% |getExternalResources| returns the file's HERD, creating and attaching an 
% empty one if the file does not have one yet, and returning the existing one 
% otherwise, for example when the file was read from disk. The |general_external_resources| 
% property returns the HERD without creating one, and is empty when the file has 
% no external resources.
% 
% Displaying a HERD shows how many keys, entities, objects and files it holds, 
% followed by every reference it records.

herd = nwb.getExternalResources()
% As a table
% |toTable| returns the same flattened view as a MATLAB table, one row per object, 
% key and entity association, with the internal row indices already resolved into 
% the values they point at.

references = herd.toTable()
% The underlying tables
% The six tables are available individually when you want to see how the associations 
% are stored. The |keys| table holds the terms used in the file.

herd.keys.data
%% Look up what an object refers to
% |getObjectEntities| returns the entities annotated on one object.

herd.getObjectEntities(nwb, nwb.general_subject)
% Everything annotated on one type
% |getObjectType| returns every reference recorded on objects of a given type, 
% which is useful when the same kind of value is annotated in several places.

herd.getObjectType("Subject")
%% Write and read the file
% Writing the file stores the HERD inside it, under |/general/external_resources|. 
% Reading the file back makes the annotations available again.

nwbExport(nwb, 'externalResources.nwb');
readFile = nwbRead('externalResources.nwb', 'ignorecache');
readFile.general_external_resources.toTable()
% Look up an annotation from the file that was read
% The lookups work the same way on a HERD read from disk. Object identity survives 
% the round trip, so the subject read back from the file matches the reference 
% recorded for it.

readFile.general_external_resources.getObjectEntities(readFile, readFile.general_subject)
%% Notes
% A few things are worth knowing when annotating your own files.
%% 
% * Reusing an entity is normal. The first reference stores its URI, and later 
% references to the same |entity_id| reuse it.
% * The same term used on two different objects is recorded once per object, 
% so each object keeps its own association.
% * |Attribute| currently accepts properties that are themselves neurodata types, 
% such as a column of a table.
%% 
% For the concepts behind HERD and the equivalent Python API, see the <https://hdmf.readthedocs.io/en/stable/tutorials/plot_external_resources.html 
% HDMF documentation>.