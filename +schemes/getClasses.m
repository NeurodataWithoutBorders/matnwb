% get type declarations from scheme
% a scheme object is the java hashmap object that was read in.
% classes is a map containing groups or datasets which in turn are cell arrays
% of the Java HashMaps which hold the class definition.
% nargin specifies by name which classes to list by name
function map = getClasses(scheme, varargin)
map = [];

if scheme.containsKey('datasets')
    map = [map; search(scheme.get('datasets'), varargin)];
end

if scheme.containsKey('groups')
    map = [map; search(scheme.get('groups'), varargin)];
    groups = scheme.get('groups');
    giter = groups.iterator();
    while giter.hasNext()
        g = giter.next();
        if g.containsKey('groups') || g.containsKey('datasets')
            map = [map; schemes.getClasses(g, varargin{:})];
        end
    end
end
end

function acc = search(list, filter)
acc = containers.Map;
iter = list.iterator();
while iter.hasNext()
    n = iter.next();
    if n.containsKey('neurodata_type_def') &&...
            (isempty(filter) || ismember(n.get('neurodata_type_def'), filter))
        acc(n.get('neurodata_type_def')) = n;
    end
end
end