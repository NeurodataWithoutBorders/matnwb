function data = hdf2mat(datasetId, data)
% hdf2mat - Convert values read from an HDF5 dataset to MatNWB's types.
%
% Compound values become a struct (see io.parseCompound), enumerations
% logical or cellstr, and references ObjectView or RegionView objects.
    typeId = H5D.get_type(datasetId);

    % Check if compound type
    if H5T.get_class(typeId) == H5ML.get_constant_value('H5T_COMPOUND')
        data = io.parseCompound(datasetId, data);
    elseif H5T.get_class(typeId) == H5ML.get_constant_value('H5T_ENUM')
        if io.isBool(typeId)
            data = io.internal.h5.postprocess.toLogical(data);
        else
            data = io.internal.h5.postprocess.toEnumCellStr(data, typeId);
        end
    else
        matlabType = io.getMatType(typeId);
        switch matlabType
            case {'types.untyped.ObjectView', 'types.untyped.RegionView'}
                data = io.parseReference(datasetId, typeId, data);
            otherwise
                % no-op
        end
    end

    H5T.close(typeId);
end
