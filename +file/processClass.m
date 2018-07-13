function [processed, classprops, inherited] = processClass(name, namespace, pregen)
branch = [namespace.getClass(name) namespace.getRootBranch(name)];
rootname = branch(end).get('neurodata_type_def');
switch rootname
    case 'NWBContainer'
        isgroup = true;
    case {'NWBData', 'SpecFile', 'Image'}
        isgroup = false;
    otherwise
        warning('Unexpected root class `%s` found.  Skipping `%s`', rootname, name);
        return;
end
for i=length(branch):-1:1
    node = branch(i);
    nodename = node.get('neurodata_type_def');
    
    if ~isKey(pregen, nodename)
        if isgroup
            class = file.Group(node);
        else
            class = file.Dataset(node);
        end
        props = class.getProps();
        pregen(nodename) = struct('class', class, 'props', props);
    end
    
    processed(i) = pregen(nodename).class;
end
classprops = pregen(name).props;
names = keys(classprops);
inherited = {};
for i=2:length(processed)
    pname = processed(i).type;
    parentPropNames = keys(pregen(pname).props);
    inherited = union(inherited, intersect(names, parentPropNames));
end
end