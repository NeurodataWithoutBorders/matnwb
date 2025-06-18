function validateShape(propertyName, validShapes, value)
% validateShape - Validate the shape of a property value

% Todo: might want to refine error message if this fails on DataPipe

    enforceScalarShape = false;

    if isa(value, 'types.untyped.DataStub')
        if value.ndims == 1
            valueShape = [value.dims 1];
        else
            valueShape = value.dims;
        end
    elseif isa(value, 'types.untyped.DataPipe')
        valueShape = value.internal.maxSize;
        % For data pipes, vectors can be exported to HDF5 files as 2D arrays
        % (columnar (n,1) or row (1,n)). The types.util.checkDims function allows
        % this, even if the valid shape specifies that the data should be 1D.
        % Use 'enforceScalarShape' to ensure that 2D-like vectors do not
        % pass validation when the valid shape specifies 1D data.
        enforceScalarShape = true;
    elseif istable(value)
        valueShape = [height(value) 1];
    elseif ischar(value)
        valueShape = [size(value, 1) 1];
    else
        valueShape = size(value);
    end

    try
        types.util.checkDims(valueShape, validShapes, enforceScalarShape);
    catch MECause
        ME = MException(MECause.identifier, ...
            'Invalid shape for property "%s".', propertyName);
        ME = ME.addCause(MECause);
        
        if isa(value, 'types.untyped.DataPipe')
            extraCause = MException('NWB:ValidateShape:InvalidMaxSize', ...
                ['For DataPipe objects, ensure the `maxSize` property ', ...
                'matches the valid shape.']);
            ME = ME.addCause(extraCause);
        end
        throw(ME)
    end

    % Check actual size of DataPipe and warn if it is not valid
    if isa(value, 'types.untyped.DataPipe')
        try
            valueShape = size(value);
            types.util.checkDims(valueShape, validShapes, enforceScalarShape);
        catch ME
            warning(...
                'NWB:ValidateShape:InvalidDataPipeSize', ...
                ['Invalid shape for property "%s". The maxSize of this ', ...
                'DataPipe has a valid shape but the actual size of the ', ...
                'dataPipe is not valid: %s'], propertyName, ME.message)
        end
    end
end
