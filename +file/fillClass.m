function template = fillClass(name, namespace, pregen)
%name is the name of the scheme
%namespace is the namespace context for this class

%% PROCESSING
[processed, classprops, inherited] = processClass(name, namespace, pregen);
class = processed(1);
validationlist = setdiff(keys(classprops.named), {name});
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
    prop = classprops.named(propname);
    
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
    classprops);
setterFcns = file.fillSetters(propertylist);
validatorFcns = file.fillValidators(validationlist, classprops, namespace);
exporterFcns = file.fillExport(classprops, processed);
methodBody = strjoin({constructorBody...
    '%% SETTERS' setterFcns...
    '%% VALIDATORS' validatorFcns...
    '%% EXPORT' exporterFcns}, newline);
template = strjoin({classDef propsDef 'methods' file.addSpaces(methodBody, 4) 'end' 'end'}, newline);
end

function [processed, classprops, inherited] = processClass(name, namespace, pregen)
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

    if ~isKey(pregen, nodename)
        if isgroup
            class = file.Group(node);
        else
            class = file.Dataset(node);
        end
        [namedprops, varargs] = class.getProps();
        allprops = struct('named', namedprops,'varargs', {varargs});
        pregen(nodename) = struct('class', class, 'props', allprops);
    end
    
    processed(i) = pregen(nodename).class;
end
classprops = pregen(name).props;
names = keys(classprops.named);
inherited = {};
for i=2:length(processed)
    pname = processed(i).type;
    parentPropNames = keys(pregen(pname).props.named);
    inherited = union(inherited, intersect(names, parentPropNames));
end
end