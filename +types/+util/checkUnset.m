function checkUnset(obj, argin)
% CHECKUNSET used for validating keyword arguments for nested property types.
% note related to types.util.checkSet.
props = properties(obj);
anonNames = {};
for i=1:length(props)
    p = obj.(props{i});
    if isa(p, 'types.untyped.Anon')
        anonNames = [anonNames;{p.name}];
    elseif isa(p, 'types.untyped.Set')
        anonNames = [anonNames;keys(p) .'];
    end
end
dropped = setdiff(argin, [props;anonNames]);
assert(isempty(dropped),...
    'Propertyes {%s} are not valid property names.',...
        misc.cellPrettyPrint(dropped));
end