function id = defineSpace(dim)
if all(dim == 1) %scalar
  id = H5S.create('H5S_SCALAR');
elseif any(dim == 0) %empty
  id = H5S.create_simple(1, 0, 0);
else %multidimensional
  cstyle = fliplr(dim);
  id = H5S.create_simple(ndims(dim), cstyle, cstyle);
end
end