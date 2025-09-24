function [value, originalValue] = unwrapValue(value)

    originalValue = value;
    if isa(value, 'types.untyped.Anon')
        value = originalValue.value;
    elseif isa(value, 'types.untyped.DatasetClass') && isprop(value, 'data')
        value = originalValue.data;
    else
        error('NWB:UnwrapValue:UnsupportedType', ...
            'Can not unwrap value of type %s. Please report', class(originalValue))
    end
end
