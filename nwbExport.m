function nwbExport(matnwb, filenames)
validateattributes(matnwb, {'matnwb'}, {});
validateattributes(filenames, {'cell', 'string', 'char'}, {});

for i=1:length(matnwb)
  if iscellstr(filenames)
    fn = filenames{i};
  elseif isstring(filenames)
    fn = filenames(i);
  else
    fn = filenames;
  end
  if length(matnwb) > 1
    mnwb = matnwb(i);
  else
    mnwb = matnwb;
  end
  export(mnwb, fn);
end
end