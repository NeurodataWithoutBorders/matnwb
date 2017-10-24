% init
generateCore('schema\core\nwb.namespace.yaml', 'schema\extensions\crcnsret1\crcnsret1.namespace.yaml');
mkdir('testoutput');

%% Test 1: Read
nwb = nwbRead('testdata\20080516_R1.nwb');

%% Test 2: Write
nwb = nwbRead('testdata\20080516_R1.nwb');
nwbExport(nwb, 'testoutput\out.nwb');
nwbRead('testoutput\out.nwb');

%% Test 3: Create
nwb = nwbfile;
nwb.epochs = types.untyped.Group;
nwb.epochs.stim = types.Epoch;
nwbExport(nwb, 'testoutput\epoch.nwb');
nwbRead('testoutput\epoch.nwb');