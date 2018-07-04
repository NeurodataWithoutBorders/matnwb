function [sz, names] = procdims(dim, shape)
%check for optional dims
if isa(dim, 'java.util.ArrayList')
    dimlen = dim.size();
    names = cell(dimlen,1);
    
    for i=1:dimlen
        dimopt = dim.get(i-1);
        if isa(shape, 'java.util.ArrayList')
            shapeopt = shape.get(i-1);
        else
            shapeopt = shape;
        end
        
        [subsz, subnm] = file.Dataset.procdims(dimopt, shapeopt);
        if iscell(subsz)
            %nested declaration
            sz{i} = subsz;
        else
            %unnested
            sz(i) = subsz;
        end
        names{i} = subnm;
    end
    if ~iscell(sz)
        sz = {sz};
    end
else
    if strcmp(shape, 'null')
        sz = inf;
    else
        sz = str2double(shape);
    end
    names = dim;
end
end