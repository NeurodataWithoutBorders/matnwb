function val = dtype2val(type, val)
switch(type)
  case 'string'
    val = ['{''' val '''}'];
  case 'double'
  otherwise
    val = [type '(' val ')'];
end
end