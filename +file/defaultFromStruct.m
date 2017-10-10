function val = defaultFromStruct(s)
if isfield(s, 'default_value')
  val = file.dtype2val(s.dtype, s.default_value);
elseif strcmp(s.dtype, 'string')
  val = '{}';
else
  val = '[]';
end
end