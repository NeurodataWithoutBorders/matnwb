function nwbExport(nwb, filenames)
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