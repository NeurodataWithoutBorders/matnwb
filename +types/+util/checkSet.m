function checkSet(pname, namedprops, constraints, val)
if isempty(val)
    return;
end

assert(isa(val, 'types.untyped.Set'),...
    'MatNWB:TypeUtil:CheckSet:InvalidType',...
    'Property `%s` must be a `types.untyped.Set`', pname);

val.setValidationFcn(...
    @(nm, val)types.util.checkConstraint(pname, nm, namedprops, constraints, val));
val.validateAll();
end