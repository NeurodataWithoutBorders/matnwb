classdef Namespace < handle
    properties(SetAccess=private)
        name; %name of this namespace
        dependencies; %parent namespaces by [Namespace]
        registry; %maps name to class
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
        
        %list of values that do not have a dependency (ignoring parents)
        function roots = getRoots(obj)
            classnames = keys(obj.registry);
            roots = [];
            for i=1:length(classnames)
                class = obj.registry(classnames{i});
                if ~class.containsKey('neurodata_type_inc')
                    roots = [roots class];
                end
            end
        end
        
        function parent = getParent(obj, classname)
            class = obj.getClass(classname);
            if isempty(class)
                error('Could not find class %s', classname);
            end
            
            parent = [];
            if isKey(class, 'neurodata_type_inc')
                parentName = class('neurodata_type_inc');
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
        
        function namespace = getParentNamespace(obj, classname)
            class = obj.getClass(classname);
            namespace = [];
            pname = class.get('neurodata_type_inc');
            if ~isempty(pname)
                namespace = obj.getNamespace(pname);
            end
        end
        
        %gets root to this classname
        function root = getRoot(obj, classname)
            root = obj.getClass(classname);
            while root.containsKey('neurodata_type_inc')
                root = obj.getClass(root.get('neurodata_type_inc'));
            end
        end
        
        %gets this particular branch to root from class name
        %the returned value is a cell array of coantainers.Maps [parent -> root]
        function branch = getRootBranch(obj, classname)
            cursor = obj.getClass(classname);
            branch = {};
            parent = obj.getParent(cursor('neurodata_type_def'));
            while ~isempty(parent)
                branch = [branch {parent}];
                cursor = parent;
                parent = obj.getParent(cursor('neurodata_type_def'));
            end
        end
    end
end
