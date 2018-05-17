function writeExternalLink(filename, target, loc_id, name)
lcpl = 'H5P_DEFAULT';
lapl = 'H5P_DEFAULT';
H5L.create_external(filename, target, loc_id, name, lcpl, lapl);
end