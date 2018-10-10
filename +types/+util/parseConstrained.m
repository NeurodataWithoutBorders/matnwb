function [set, ikeys] = parseConstrained(pname, type, varargin)
assert(mod(length(varargin),2) == 0, 'Malformed varargin.  Should be even');
ikeys = [];
for i=2:2:length(varargin)
    if isa(varargin{i}, type)
        ikeys(end+1) = i-1;
    end
end
if isempty(ikeys)
    set = types.untyped.Set();
else
    ivals = ikeys+1;
    map = containers.Map(varargin(ikeys), varargin(ivals));
    set = types.untyped.Set(map,...
        @(nm, val)types.util.checkConstraint(pname, nm, struct(), {type}, val));
end
end