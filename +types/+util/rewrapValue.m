function originalValue = rewrapValue(value, originalValue)

    if isa(originalValue, 'types.untyped.Anon')
        originalValue.value = value;
    elseif isa(originalValue, 'types.untyped.DatasetClass') && isprop(originalValue, 'data')
        originalValue.data = value;
    else
        error('NWB:UnwrapValue:UnsupportedType', ...
            'Can not unwrap value of type %s. Please report', class(originalValue))
    end
end
