function validateShape(propertyName, validShapes, value)
% validateShape - Validate the shape of a property value

% Todo: might want to refine error message if this fails on DataPipe

    enforceScalarShape = false;

    if isa(value, 'types.untyped.DatasetClass')
        types.util.validateShape(propertyName, validShapes, value.data)
        return
    elseif isa(value, 'types.untyped.DataStub')
        if value.ndims == 1
            valueShape = [value.dims 1];
        else
            valueShape = value.dims;
        end
    elseif isa(value, 'types.untyped.DataPipe')
        valueShape = value.internal.maxSize;
        % For DataPipe objects, vectors can be exported to HDF5 files as 2D arrays
        % with shape [n,1] (column) or [1,n] (row). By default, types.util.checkDims 
        % allows these 2D shapes to pass validation even when the valid shape 
        % specifies 1D data (e.g., [Inf]). However, for DataPipe, the maxSize 
        % property determines the actual shape in the exported file, so we need 
        % stricter validation. Set 'enforceScalarShape' to true to ensure that 
        % shapes like [n,1] or [1,n] are not accepted when [Inf] is specified.
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
            if enforceScalarShape
                % Reset enforceScalarShape to false when validating the current 
                % data size. Strict validation is only needed for maxSize, which 
                % determines the final shape of the dataset in the exported file. 
                % The current data size is allowed to be more flexible (e.g., 
                % [n,1] can match [Inf]).
                enforceScalarShape = false;
            end

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
