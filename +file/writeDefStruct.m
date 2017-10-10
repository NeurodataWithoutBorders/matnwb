function writeDefStruct(fid, def_struct, svalue, varargin)
validateattributes(fid, {'double'}, {'scalar'});
validateattributes(def_struct, {'struct'}, {'scalar'});
validateattributes(svalue, {'string', 'char'}, {'scalartext'});
p = inputParser;
p.addParameter('spaces', 0, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
p.parse(varargin{:});

names = fieldnames(def_struct);
if ~isempty(names)
  for i=1:length(names)
    nm = names{i};
    fprintf(fid, repmat(' ', 1, p.Results.spaces));
    fprintf(fid, [svalue newline], nm, def_struct.(nm));
  end
end
end