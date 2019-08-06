function template = fillClass(name, namespace, processed, classprops, inherited)
%name is the name of the scheme
%namespace is the namespace context for this class

%% PROCESSING
class = processed(1);

allprops = keys(classprops);
required = {};
optional = {};
readonly = {};
defaults = {};
dependent = {};
%separate into readonly, required, and optional properties
for i=1:length(allprops)
    pnm = allprops{i};
    prop = classprops(pnm);
    
    if ischar(prop) || isa(prop, 'java.util.HashMap') || isstruct(prop) || prop.required
        required = [required {pnm}];
    else
        optional = [optional {pnm}];
    end
    
    if isa(prop, 'file.Attribute')
        if prop.readonly
            readonly = [readonly {pnm}];
        end
        
        if ~isempty(prop.value)
            defaults = [defaults {pnm}];
        end
       
        if ~isempty(prop.dependent)
            %extract prefix
            parentname = strrep(pnm, ['_' prop.name], '');
            parent = classprops(parentname);
            if ~parent.required
                dependent = [dependent {pnm}];
            end
        end
    end
end
non_inherited = setdiff(allprops, inherited);
ro_unique = intersect(readonly, non_inherited);
req_unique = intersect(required, non_inherited);
opt_unique = intersect(optional, non_inherited);

%% CLASSDEF
if length(processed) <= 1
    depnm = 'types.untyped.MetaClass'; %WRITE
else
    parentname = processed(2).type; %WRITE
    pnamespace = namespace.getNamespace(parentname);
    depnm = ['types.' pnamespace.name '.' parentname]; %WRITE
end

%% return classfile string
classDef = [...
    'classdef ' name ' < ' depnm newline... %header, dependencies
    '% ' upper(name) ' ' class.doc]; %name, docstr
propgroups = {...
    @()file.fillProps(classprops, ro_unique, 'SetAccess=protected')...
    @()file.fillProps(classprops, setdiff([req_unique opt_unique], ro_unique))...
    };
docsep = {...
    '% READONLY'...
    '% PROPERTIES'...
    };
propsDef = '';
for i=1:length(propgroups)
    pg = propgroups{i};
    pdef = pg();
    if ~isempty(pdef)
        propsDef = strjoin({propsDef docsep{i} pdef}, newline);
    end
end

constructorBody = file.fillConstructor(...
    name,...
    depnm,...
    defaults,... %all defaults, regardless of inheritance
    [req_unique opt_unique],...
    classprops,...
    namespace);
setterFcns = file.fillSetters(setdiff(non_inherited, ro_unique));
validatorFcns = file.fillValidators(allprops, classprops, namespace);
exporterFcns = file.fillExport(non_inherited, class, depnm);
methodBody = strjoin({constructorBody...
    '%% SETTERS' setterFcns...
    '%% VALIDATORS' validatorFcns...
    '%% EXPORT' exporterFcns}, newline);
fullMethodBody = strjoin({'methods' ...
    file.addSpaces(methodBody, 4) 'end'}, newline);
template = strjoin({classDef propsDef fullMethodBody 'end'}, ...
    [newline newline]);
end

