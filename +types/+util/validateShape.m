function validateShape(propertyName, validShapes, value)
% validateShape - Validate the shape of a property value

% Todo: might want to refine error message if this fails on DataPipe

    enforceVector = false;

    if isa(value, 'types.untyped.DataStub')
        if value.ndims == 1
            valueShape = [value.dims 1];
        else
            valueShape = value.dims;
        end
    elseif isa(value, 'types.untyped.DataPipe')
        valueShape = value.internal.maxSize;
        enforceVector = true;
    elseif istable(value)
        valueShape = [height(value) 1];
    elseif ischar(value)
        valueShape = [size(value, 1) 1];
    else
        valueShape = size(value);
    end

    try
        types.util.checkDims(valueShape, validShapes, enforceVector);
    catch MECause
        ME = MException(MECause.identifier, ...
            'Invalid shape for property "%s".', propertyName);
        ME = ME.addCause(MECause);
        throw(ME)
    end
end
