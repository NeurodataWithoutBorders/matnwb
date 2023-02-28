classdef Namespace < handle
    properties (SetAccess=private)
        name; %name of this namespace
        dependencies; %parent namespaces by [Namespace]
        registry; %maps name to class
    end
    
    properties (Constant)
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
            
            obj.name = strrep(name, '-', '_');
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
        
        function fullClassName = getFullClassName(obj, classname)
            Namespace = obj.getNamespace(classname);
            
            assert(~isempty(Namespace),...
                'NWB:Scheme:Namespace:NotFound',...
                'Namespace for class `%s` not found.', classname);
            
            fullClassName = sprintf('types.%s.%s',...
                misc.str2validName(Namespace.name),...
                classname);
        end
        
        %gets namespace containing classname
        function namespace = getNamespace(obj, classname)
            namespace = [];
            
            if obj.registry.isKey(classname)
                namespace = obj;
                return;
            end
            
            for i=1:length(obj.dependencies)
                nparent = obj.dependencies(i);
                namespace = nparent.getNamespace(classname);
                if ~isempty(namespace)
                    return;
                end
            end
        end
        
        %gets this particular branch to root from class name
        %the returned value is a cell array of containers.Maps [parent -> root]
        function branch = getRootBranch(obj, classname)
            cursor = obj.getClass(classname);
            typeNames = {};
            branch = {};
            iHasTypeDef = isKey(cursor, obj.TYPEDEF_KEYS);
            typeName = cursor(obj.TYPEDEF_KEYS{iHasTypeDef});
            parent = obj.getParent(typeName);
            while ~isempty(parent)
                branch{end+1} = parent;
                typeNames{end+1} = typeName;
                assert(length(unique(typeNames)) == length(typeNames), ...
                    'NWB:Namespace:GetRootBranch:InfiniteLoopDetected', ...
                    ['Failed to find root branch. A lower-level definition override might be causing ' ...
                    'an infinite loop with parent name detection. If you are an extension developer, ' ...
                    'this is usually due to overwriting a "core" type name.']);
                cursor = parent;
                iHasTypeDef = isKey(cursor, obj.TYPEDEF_KEYS);
                typeName = cursor(obj.TYPEDEF_KEYS{iHasTypeDef});
                parent = obj.getParent(typeName);
            end
        end
    end
end
