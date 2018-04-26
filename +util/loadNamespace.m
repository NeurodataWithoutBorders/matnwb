%name is the pregenerated namespace name
%loaded is a containers.Map containing preloaded namespace names (optional)
%extNamespaces is a merged containers.Map containing this namespace and its
%   parents
function extNamespaces = loadNamespace(name, loaded)
classesPath = fullfile('+types', ['+' name]);
schemaPath = fullfile('namespaces', [name '.mat']);

namespace = load(schemaPath);

if nargin > 1
    extNamespaces = loaded;
else
    extNamespaces = containers.Map;
end

deps = schemes.Namespace.empty(0,0); %create list of parent Namespaces to create Namespace object

dependencies=namespace.dependencies;
schema=namespace.schema;

for i=length(dependencies):-1:1
    depname = dependencies{i};
    if ~isKey(extNamespaces, depname)
        extNamespaces = [extNamespaces; util.loadNamespace(depname, extNamespaces)];
    end
    deps(i) = extNamespaces(depname);
end

extNamespaces(name) = schemes.Namespace(name, deps, schema);

end