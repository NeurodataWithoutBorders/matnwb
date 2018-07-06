function set = parseAnon(type, varargin)
ikeys = 1:2:length(varargin);
set = types.untyped.Anon();
for i=ikeys+1
    if isa(varargin{i}, type)
        set.name = varargin{i-1};
        set.value = varargin{i};
        return;
    end
end
end