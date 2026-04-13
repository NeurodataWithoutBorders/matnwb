function mustBeDynamicTable(value)

    isValid = isa(value, 'types.hdmf_common.DynamicTable') || ...
        isa(value, 'types.core.DynamicTable');

    if ~isValid
        ME = MException(...
            'NWB:validators:mustBeDynamicTable', ...
            'Value must be a DynamicTable but was: %s.', class(value));
        throwAsCaller(ME)
    end
end
