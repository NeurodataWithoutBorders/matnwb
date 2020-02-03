function Class = processClass(name, Namespace, CacheMap)
inherited = {};
branch = [{Namespace.getClass(name)} Namespace.getRootBranch(name)];
branchNames = cell(size(branch));
TYPEDEF_KEYS = {'neurodata_type_def', 'data_type_def'};
for i = 1:length(branch)
    hasTypeDefs = isKey(branch{i}, TYPEDEF_KEYS);
    branchNames{i} = branch{i}(TYPEDEF_KEYS{hasTypeDefs});
end

for iAncestor=length(branch):-1:1
    node = branch{iAncestor};
    hasTypeDefs = isKey(node, TYPEDEF_KEYS);
    nodename = node(TYPEDEF_KEYS{hasTypeDefs});
    
    if ~isKey(CacheMap, nodename)
        switch node('class_type')
            case 'groups'
                class = file.Group(node);
            case 'datasets'
                class = file.Dataset(node);
            otherwise
                error('NWB:FileGen:InvalidClassType',...
                    'Class type %s is invalid', node('class_type'));
        end
        props = class.getProps();
        CacheMap(nodename) = struct('class', class, 'props', props);
    end
    try
    Processed(iAncestor) = CacheMap(nodename).class;
    catch
        keyboard;
    end
end
classprops = CacheMap(name).props;
names = keys(classprops);
for iAncestor=2:length(Processed)
    pname = Processed(iAncestor).type;
    parentPropNames = keys(CacheMap(pname).props);
    inherited = union(inherited, intersect(names, parentPropNames));
end
end