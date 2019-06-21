function extNamespaces = loadNamespace(name, loaded)
%LOADNAMESPACE loads dependent class metadata
% name is the pregenerated namespace name
% loaded is a containers.Map containing preloaded namespace names (optional)
% extNamespaces is a merged containers.Map containing this namespace and its
%   parents

namespace = load(fullfile('namespaces', [name '.mat']));

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
        extNamespaces = [extNamespaces; schemes.loadNamespace(depname, extNamespaces)];
    end
    deps(i) = extNamespaces(depname);
end

extNamespaces(name) = schemes.Namespace(name, deps, schema);

end