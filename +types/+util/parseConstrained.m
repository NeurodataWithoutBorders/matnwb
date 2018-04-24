function set = parseConstrained(pname, name, type, varargin)
ikeys = 1:2:length(varargin);
for i=ikeys+1
    if ~isa(varargin{i}, type)
        ikeys(i/2) = 0;
    end
end
ikeys(ikeys == 0) = [];
ivals = ikeys+1;
if isempty(ikeys)
    set = types.untyped.Set();
else
    map = containers.Map(varargin(ikeys), varargin(ivals));
    set = types.untyped.Set(map,...
        @(val)types.util.checkConstraint(pname, name, struct(), {type}, val));
end
end