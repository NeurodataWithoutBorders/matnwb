function nwbExport(nwb, filenames)
%NWBEXPORT Writes an NWB file.
%  nwbRead(nwb,filename) Writess the nwb object to a file at filename.
%    
%  Example: 
%    %Generate Matlab code for the NWB objects from the core schema.
%    %This only needs to be done once.
%    generateCore('schema\core\nwb.namespace.yaml');
%    %Create some fake fata and write 
%    nwb = nwbfile;
%    nwb.epochs = types.untyped.Group;
%    nwb.epochs.stim = types.Epoch;
%    nwbExport(nwb, 'epoch.nwb');
%  
%  See also GENERATECORE, GENERATEEXTENSIONS, NWBFILE, NWBREAD
validateattributes(nwb, {'nwbfile'}, {});
validateattributes(filenames, {'cell', 'string', 'char'}, {});

for i=1:length(nwb)
  if iscellstr(filenames)
    fn = filenames{i};
  elseif isstring(filenames)
    fn = filenames(i);
  else
    fn = filenames;
  end
  if length(nwb) > 1
    mnwb = nwb(i);
  else
    mnwb = nwb;
  end
  export(mnwb, fn);
end
end