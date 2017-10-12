function writeExportFunction(fid, propType, nm, objnm, typenm, varargin)
validateattributes(fid, {'double'}, {'scalar'});
validateattributes(propType, {'char', 'string'}, {'scalartext'});
validateattributes(nm, {'char', 'string'}, {'scalartext'});
validateattributes(objnm, {'char', 'string'}, {'scalartext'});
validateattributes(typenm, {'char', 'string'}, {'scalartext'});

p = inputParser;
p.addParameter('spaces', 0);
p.addParameter('keepid', false);
p.addParameter('idname', 'loc_id');
p.parse(varargin{:});
fprintf(fid, file.spaces(p.Results.spaces));
if p.Results.keepid
  fprintf(fid, 'id = ');
end

if any(strcmp(typenm, {'string', 'any'}))
  fprintf(fid, ['h5util.write%s(%s, ''%s'', obj.%s, ''%s'');' newline],...
    propType, p.Results.idname, nm, objnm, typenm);
else
  fprintf(fid, ['h5util.write%s(%s, ''%s'', %s(obj.%s), ''%s'');' newline],...
    propType, p.Results.idname, nm, typenm, objnm, typenm);
end
end