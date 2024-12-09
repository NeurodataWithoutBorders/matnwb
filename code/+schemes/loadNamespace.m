function Namespace = loadNamespace(name, saveDir)
%LOADNAMESPACE loads dependent class metadata
% name is the pregenerated namespace name
% Namespaces a schemes.Namespace object with dependency graph

Cache = spec.loadCache(name, 'savedir', saveDir);
assert(~isempty(Cache), 'NWB:Namespace:CacheMissing',...
    ['No cache found for namespace `%s`.  '...
    'Please generate any missing dependencies before generating this namespace.'], name);
ancestry = schemes.Namespace.empty(length(Cache.dependencies), 0);

for i=length(Cache.dependencies):-1:1
    ancestorName = Cache.dependencies{i};
    ancestry(i) = schemes.loadNamespace(ancestorName, saveDir);
end

Namespace = schemes.Namespace(name, ancestry, Cache.schema);
end