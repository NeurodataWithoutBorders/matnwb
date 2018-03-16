function id = mat2hdf_typeid(def)
switch(def)
  case {'string', 'char'}
    id = H5T.copy('H5T_C_S1');
    H5T.set_size(id, 'H5T_VARIABLE');
  case 'single'
    id = H5T.copy('H5T_NATIVE_FLOAT');
  otherwise
    try
      id = H5T.copy(sprintf('H5T_NATIVE_%s', upper(def)));
    catch H5E
      switch(H5E.identifier)
        case 'MATLAB:imagesci:hdf5lib:constantNotFound'
          msg = sprintf('defineType: Invalid type definition (%s).', def);
          newcause = MException('MATLAB:h5helper:invalidTypeName', msg);
          H5E = addCause(H5E, newcause);
      end
      rethrow(H5E);
    end
end
end