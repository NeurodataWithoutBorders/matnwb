function t = schema2matlabTypes(s)
switch(lower(s))
  case {'text', 'str'}
    t = 'string';
  case {'float32'}
    t = 'single';
  case {'float', 'float32!', 'float64', 'float64!', 'number', 'double'}
    t = 'double';
  case {'any', 'binary', 'none'}
    t = 'any';
  case 'int'
    t = 'int32';
  otherwise
    if endsWith(s, '!')
      if startsWith(s, 'uint')
        t = 'uint64';
      elseif startsWith(s, 'int')
        t = 'int64';
      end
      disp(s);
    else
      t = s;
    end
end
end