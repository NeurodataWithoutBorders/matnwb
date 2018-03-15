function writeClass(path, name, namespace, pregenprops)
%path is full path to where the file is written
%name is the name of the scheme
%namespace is the namespace context for this class

%% PROCESSING
fullpath = fullfile(path, [name '.m']);

[processed, classprop, inherited] = processClass(name, namespace, pregenprops);
class = processed(1);
propertylist = setdiff(keys(classprop.properties), [inherited; {name}]);

%% CLASSDEF
if length(processed) <= 1
    depnm = 'types.untyped.MetaClass'; %WRITE
    pname = depnm; %WRITE
else
    pname = processed(2).type; %WRITE
    pnamespace = namespace.getNamespace(pname);
    depnm = ['types.' pnamespace.name '.' pname]; %WRITE
end

%% PROPERTIES
%in format <name> -> <docstring>
ro_props = struct();
req_props = struct();
opt_props = struct();
for i=1:length(propertylist)
    propname = propertylist{i};
    prop = classprop.properties(propname);
    if isa(prop, 'file.Attribute') && prop.readonly
        ro_props.(propname) = prop.doc;
    elseif ischar(prop)
        req_props.(propname) = ['property of type ' prop];
    elseif isa(prop, 'java.util.HashMap')
        req_props.(propname) = ['reference to type ' prop.get('target_type')];
    elseif prop.required
        req_props.(propname) = prop.doc;
    else
        opt_props.(propname) = prop.doc;
    end
end

%% EXPORT BODY

%% WRITE CLASS FILE
template = [...
    'classdef ' name ' < ' depnm newline... %header, dependencies
    '%% ' name ' ' class.doc newline... %name, docstr
    file.fillProps(ro_props, 'READONLY', 'SetAccess=immutable') newline... %readonly properties
    file.fillProps(req_props, 'REQUIRED') newline... %required properties
    file.fillProps(opt_props, 'OPTIONAL') newline... %optional properties
    'methods' newline...
    file.addSpaces([file.fillConstructor(name,... %constructor
    namespace.name,...
    pname,...
    fieldnames(ro_props)',...
    fieldnames(req_props)',...
    fieldnames(opt_props)',...
    classprop) newline...
    file.fillSetters(propertylist) newline... %setters
    file.fillDynamicSetters(classprop.varargs) newline... %dynamic setters
    file.fillValidators(propertylist, classprop) newline...%validators
    file.fillDynamicValidators(classprop.varargs) newline... %dynamic validators
    file.fillExport(classprop, processed) newline... %exporters
    ], 4) newline...
    'end' newline...
    'end'];
return;
fid = fopen(fullpath, 'W');
fwrite(fid, template, 'char');
fclose(fid);
end

function [processed, classprop, inherited] = processClass(name, namespace, pregenprops)
branch = [namespace.getClass(name) namespace.getRootBranch(name)];
rootname = branch(end).get('neurodata_type_def');
switch rootname
    case 'NWBContainer'
        isgroup = true;
    case {'NWBData', 'SpecFile'}
        isgroup = false;
    otherwise
        error('Unexpected root class %s', rootname);
end
for i=length(branch):-1:1
    node = branch(i);
    nodename = node.get('neurodata_type_def');
    if isgroup
        parsed = file.Group(node);
    else
        parsed = file.Dataset(node);
    end
    processed(i) = parsed;
    if ~isKey(pregenprops, nodename)
        [parentprops, parentvarargs] = parsed.getProps();
        pregenprops(nodename) = struct('properties', parentprops,...
            'varargs', {parentvarargs});
    end
end
classprop = pregenprops(name);
propnames = keys(classprop.properties);
inherited = {};
for i=2:length(processed)
    pname = processed(i).type;
    parentprops = keys(pregenprops(pname).properties);
    inherited = union(inherited, intersect(propnames, parentprops));
end
end