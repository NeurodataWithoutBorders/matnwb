function attributeName = getSpecLocAttributeName()
% getSpecLocAttributeName - Name of hdmf-zarr's ".specloc" root attribute.
%
% hdmf-zarr names the cached-specifications group in a root attribute called
% ".specloc". The name is kept in one place because both the reader, which
% follows it, and io.internal.zarr3.convertAttributes, which keeps it out of
% the schema attributes, need it.

    attributeName = ".specloc";
end
