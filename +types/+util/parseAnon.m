function [set, ikey] = parseAnon(type, varargin)
ikey = [];
ikeys = 1:2:length(varargin);
set = types.untyped.Anon();
for i=ikeys+1
    if isa(varargin{i}, type)
        set.name = varargin{i-1};
        set.value = varargin{i};
        ikey = i-1;
        return;
    end
end
end