classdef Namespace < handle
    properties(SetAccess=private)
        name; %name of this namespace
        dependencies; %parent namespaces by [Namespace]
        registry; %maps name to class
    end
    
    properties (Constant, Access = private)
        TYPEDEF_KEYS = {'neurodata_type_def', 'data_type_def'};
        PARENT_KEYS = {'neurodata_type_inc', 'data_type_inc'};
    end
    
    methods
        function obj = Namespace(name, deplist, source)
            if nargin == 0
                obj.name = '';
                obj.dependencies = [];
                obj.registry = [];
                return;
            end
            
            obj.name = name;
            obj.dependencies = deplist;
            namespaceFiles = keys(source);
            obj.registry = [];
            for i=1:length(namespaceFiles)
                nmspcFile = namespaceFiles{i};
                scheme = source(nmspcFile);
                obj.registry = [obj.registry; schemes.getClasses(scheme)];
            end
        end
        
        function class = getClass(obj, classname)
            class = [];
            namespace = obj.getNamespace(classname);
            if ~isempty(namespace)
                class = namespace.registry(classname);
            end
        end

        function parent = getParent(obj, classname)
            class = obj.getClass(classname);
            if isempty(class)
                error('Could not find class %s', classname);
            end
            
            parent = [];
            hasParentKey = isKey(class, obj.PARENT_KEYS);
            if any(hasParentKey)
                parentName = class(obj.PARENT_KEYS{hasParentKey});
                parent = obj.getClass(parentName);
                assert(~isempty(parent),...
                    'Parent %s for class %s doesn''t exist!  Missing Dependency?',...
                    parentName,...
                    classname);
            end
        end
        
        %gets namespace containing classname
        function namespace = getNamespace(obj, classname)
            if isKey(obj.registry, classname)
                namespace = obj;
            else
                namespace = [];
                for i=1:length(obj.dependencies)
                    nparent = obj.dependencies(i);
                    namespace = nparent.getNamespace(classname);
                    if ~isempty(namespace)
                        return;
                    end
                end
            end
        end
        
        %gets this particular branch to root from class name
        %the returned value is a cell array of containers.Maps [parent -> root]
        function branch = getRootBranch(obj, classname)
            cursor = obj.getClass(classname);
            branch = {};
            hasTypeDef = isKey(cursor, obj.TYPEDEF_KEYS);
            parent = obj.getParent(cursor(obj.TYPEDEF_KEYS{hasTypeDef}));
            while ~isempty(parent)
                branch = [branch {parent}];
                cursor = parent;
                hasTypeDef = isKey(cursor, obj.TYPEDEF_KEYS);
                parent = obj.getParent(cursor(obj.TYPEDEF_KEYS{hasTypeDef}));
            end
        end
    end
end
