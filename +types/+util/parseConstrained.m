function [set, ivarargin] = parseConstrained(obj, pname, type, varargin)
assert(mod(length(varargin),2) == 0, 'Malformed varargin.  Should be even');
ikeys = false(size(varargin));
defprops = properties(obj);
for i=1:2:length(varargin)
    arg = varargin{i+1};
    if any(strcmp(varargin{i}, defprops))
        if isa(arg, type)
            warning('MatNWB:ParseConstrained:AmbiguousKeywordArgument',...
                ['Found keyword argument for Constrained property `%s` with constrained type `%s`. '...
                'Please provide the argument as a name that does not match property `%s`'], pname, type);
        end
        continue;
    end
    
    if isa(arg, 'types.untyped.ExternalLink')
        ikeys(i) = isa(arg.deref(), type);
        continue;
    end
    
    ikeys(i) = isa(arg, type) || isa(arg, 'types.untyped.SoftLink');
end
ivals = circshift(ikeys,1);
if any(ikeys)
    map = containers.Map(varargin(ikeys), varargin(ivals));
    set = types.untyped.Set(map,...
        @(nm, val)types.util.checkConstraint(pname, nm, struct(), {type}, val));
else
    set = types.untyped.Set();
end
ivarargin = ikeys | ivals;
end