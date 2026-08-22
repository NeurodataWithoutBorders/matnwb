function attributeName = getSpecLocAttributeName()
% getSpecLocAttributeName - Struct field name of hdmf-zarr's ".specloc".
%
% hdmf-zarr names the cached-specifications group in a root attribute called
% ".specloc". That is not a valid MATLAB identifier, so jsondecode renames it
% when zarr-matlab parses the store metadata into an attributes struct. This
% returns the renamed field, so the mangling is derived in one place rather
% than hardcoded wherever the attribute is read.

    attributeName = matlab.lang.makeValidName(".specloc");
end
