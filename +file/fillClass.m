function template = fillClass(name, namespace, pregenprops)
%name is the name of the scheme
%namespace is the namespace context for this class

%% PROCESSING
[processed, classprop, inherited] = processClass(name, namespace, pregenprops);
class = processed(1);
validationlist = setdiff(keys(classprop.properties), {name});
propertylist = setdiff(validationlist, inherited);

%% CLASSDEF
if length(processed) <= 1
    depnm = 'types.untyped.MetaClass'; %WRITE
    parentname = depnm; %WRITE
else
    parentname = processed(2).type; %WRITE
    pnamespace = namespace.getNamespace(parentname);
    depnm = ['types.' pnamespace.name '.' parentname]; %WRITE
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
    elseif isstruct(prop)
        req_props.(propname) = ['table with properties {' strtrim(evalc('disp(fieldnames(prop))')) '}'];
    elseif prop.required
        req_props.(propname) = prop.doc;
    else
        opt_props.(propname) = prop.doc;
    end
end

%% return classfile string
classDef = [...
    'classdef ' name ' < ' depnm newline... %header, dependencies
    '% ' name ' ' class.doc]; %name, docstr
propsDef = strjoin({...
    file.fillProps(ro_props, 'READONLY', 'SetAccess=immutable')...%readonly properties
    file.fillProps(req_props, 'REQUIRED')... %required properties
    file.fillProps(opt_props, 'OPTIONAL')... %optional properties
    }, newline);
constructorBody = file.fillConstructor(name,...
    namespace.name,...
    depnm,...
    [fieldnames(ro_props); fieldnames(req_props)]',... %all required properties (readonly being a subset)
    fieldnames(opt_props)',...
    classprop);
setterFcns = file.fillSetters(propertylist);
validatorFcns = file.fillValidators(validationlist, classprop, namespace);
exporterFcns = file.fillExport(classprop, processed);
methodBody = strjoin({constructorBody...
    '%% SETTERS' setterFcns...
    '%% VALIDATORS' validatorFcns...
    '%% EXPORT' exporterFcns}, newline);
template = strjoin({classDef propsDef 'methods' file.addSpaces(methodBody, 4) 'end' 'end'}, newline);
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