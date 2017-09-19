function id = defineSpace(dim)
validateattributes(dim, {'numeric'}, {'vector', '>', 0});
if all(dim == 1) %scalar
  id = H5S.create('H5S_SCALAR');
else %multidimensional
  cstyle = fliplr(dim);
  id = H5S.create_simple(length(num), cstyle, cstyle);
end
end