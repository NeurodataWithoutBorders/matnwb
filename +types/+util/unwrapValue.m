function [value, originalValue] = unwrapValue(value)

    originalValue = value;
    value = unwrapNestedValue(value);
end

function value = unwrapNestedValue(value)

    if isa(value, 'types.untyped.Anon')
        value = unwrapNestedValue(value.value);
    elseif isa(value, 'types.untyped.DatasetClass') && isprop(value, 'data')
        value = value.data;
    else
        error('NWB:UnwrapValue:UnsupportedType', ...
            'Can not unwrap value of type %s. Please report', class(value))
    end
end
