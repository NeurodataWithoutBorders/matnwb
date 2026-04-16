function originalValue = rewrapValue(value, originalValue)

    originalValue = rewrapNestedValue(value, originalValue);
end

function wrappedValue = rewrapNestedValue(value, wrappedValue)

    if isa(wrappedValue, 'types.untyped.Anon')
        wrappedValue.value = rewrapNestedValue(value, wrappedValue.value);
    elseif isa(wrappedValue, 'types.untyped.DatasetClass') && isprop(wrappedValue, 'data')
        wrappedValue.data = value;
    else
        error('NWB:RewrapValue:UnsupportedType', ...
            'Can not unwrap value of type %s. Please report', class(wrappedValue))
    end
end
