function checkSet(pname, namedprops, constraints, val)
    if isempty(val)
        return;
    end
    
    assert(isa(val, 'types.untyped.Set'),...
        'NWB:CheckSet:InvalidType',...
        'Property `%s` must be a `types.untyped.Set`', pname);
    
    validationFunction = @(nm, val) types.util.checkConstraint(...
            pname, nm, namedprops, constraints, val);

    val.setValidationFunction(validationFunction)
end
