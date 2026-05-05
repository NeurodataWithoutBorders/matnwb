function mustBeVectorData(value)

    isValid = isa(value, 'types.hdmf_common.VectorData') || ...
        isa(value, 'types.core.VectorData');

    if ~isValid
        ME = MException(...
            'NWB:validators:mustBeVectorData', ...
            'Value must be a VectorData but was: %s.', class(value));
        throwAsCaller(ME)
    end
end
