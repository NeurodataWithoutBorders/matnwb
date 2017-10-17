function unified = structUniqUnion(s1, s2)
validateattributes(s1, {'struct', 'util.StructMap'}, {'scalar'});
validateattributes(s2, {'struct', 'util.StructMap'}, {'scalar'});

%field names from both structs should be unique
s1fn = fieldnames(s1);
s2fn = fieldnames(s2);

if length(union(s1fn, s2fn)) < length(s1fn) + length(s2fn)
  s = dbstack;
  error('%s: fieldnames for both structs should be respectively unique.',...
    s(1).file);
else
  if length(s1fn) >= length(s2fn)
    greaterstruct = s1;
    lessernm = s2fn;
    lesserstruct = s2;
  else
    greaterstruct = s2;
    lessernm = s1fn;
    lesserstruct = s1;
  end
  unified = greaterstruct;
  for i=1:length(lessernm)
    nm = lessernm{i};
    unified.(nm) = lesserstruct.(nm);
  end
end
end