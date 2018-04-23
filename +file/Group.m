classdef Group < handle
    properties
        doc;
        name;
        canRename;
        type;
        isConstrainedSet; %that is, a general list of objects constrained with a type
        hasAnonData; %holds datasets that don't have names (either constrained or not)
        hasAnonGroups; %holds groups that don't have names (either constrained or not)
        required;
        scalar;
        attributes;
        datasets;
        subgroups;
        links;
        elide; %this group can be skipped as a property
        defaultEmpty; %The schema has decided that this group must be empty.
    end
    
    methods
        function obj = Group(source)
            obj.doc = [];
            obj.name = '';
            obj.canRename = true;
            obj.type = [];
            obj.isConstrainedSet = false;
            obj.required = true;
            obj.scalar = true;
            obj.attributes = [];
            obj.datasets = [];
            obj.subgroups = [];
            obj.elide = false;
            obj.links = [];
            obj.defaultEmpty = false;
            obj.hasAnonData = false;
            obj.hasAnonGroups = false;
            
            if nargin < 1
                return;
            end
            
            obj.doc = source.get('doc');
            
            name = source.get('name');
            def_name = source.get('default_name');
            if isempty(name)
                obj.name = def_name;
            else
                obj.name = name;
                obj.canRename = false;
            end
            
            type = source.get('neurodata_type_def');
            parent = source.get('neurodata_type_inc');
            if isempty(type) && ~isempty(parent)
                obj.type = parent;
            else
                obj.type = type;
            end
            
            quantity = source.get('quantity');
            if isempty(quantity)
                if ~isempty(obj.type)
                    obj.required = false;
                    obj.scalar = false;
                end
            else
                switch quantity
                    case '?'
                        obj.required = false;
                        obj.scalar = true;
                    case '*'
                        obj.required = false;
                        obj.scalar = false;
                    case '+'
                        obj.required = true;
                        obj.scalar = false;
                end
            end
            
            obj.isConstrainedSet = ~obj.scalar && isempty(type) && ~isempty(parent);
            
            %do attributes
            attributes = source.get('attributes');
            if ~isempty(attributes)
                len = attributes.size();
                obj.attributes = repmat(file.Attribute, len, 1);
                attriter = attributes.iterator();
                for i=1:len
                    nextattr = file.Attribute(attriter.next());
                    if isempty(obj.type)
                        nextattr.dependent = obj.name;
                    end
                    obj.attributes(i) = nextattr;
                end
            end
            
            %do datasets
            datasets = source.get('datasets');
            anonDataCnt = 0;
            if ~isempty(datasets)
                len = datasets.size();
                datasetiter = datasets.iterator();
                obj.datasets = repmat(file.Dataset, len, 1);
                for i=1:len
                    ds = file.Dataset(datasetiter.next());
                    if isempty(ds.name)
                        anonDataCnt = anonDataCnt + 1;
                    end
                    obj.datasets(i) = ds;
                end
            end
            
            %do groups
            subgroups = source.get('groups');
            anonGroupCnt = 0;
            if ~isempty(subgroups)
                len = subgroups.size();
                subgroupiter = subgroups.iterator();
                obj.subgroups = repmat(file.Group, len, 1);
                for i=1:len
                    sg = file.Group(subgroupiter.next());
                    if isempty(sg.name)
                        anonGroupCnt = anonGroupCnt + 1;
                    end
                    obj.subgroups(i) = sg;
                end
            end
            
            %do links
            links = source.get('links');
            if ~isempty(links)
                len = links.size();
                obj.links = repmat(file.Link, len, 1);
                liter = links.iterator();
                for i=1:len
                    nextlink = liter.next();
                    obj.links(i) = file.Link(nextlink);
                end
            end
            
            obj.defaultEmpty = (length(obj.datasets) - anonDataCnt) == 0 &&...
                (length(obj.subgroups) - anonGroupCnt) == 0 &&...
                isempty(obj.links);
            
            obj.hasAnonData = anonDataCnt > 0;
            obj.hasAnonGroups = anonGroupCnt > 0;
            
            obj.elide = obj.scalar && isempty(obj.type) && isempty(obj.attributes)...
                && isempty(obj.links) && ~obj.hasAnonData && ~obj.hasAnonGroups...
                && ~obj.defaultEmpty;
        end
        
        function props = getProps(obj)
            props = containers.Map;
            %typed + constrained
            % return itself as lower(obj.type) -> self
            % only returns itself as type is defined elsewhere.
            if ~isempty(obj.type) && obj.isConstrainedSet
                props(lower(obj.type)) = obj;
                return;
            end
            
            %untyped
            % returns itself
            if isempty(obj.type) && ~obj.elide
                props(obj.name) = obj;
                return;
            end
            
            %typed
            % containersMap of properties -> types
            % can have links, groups, datasets, and attributes
            
            %untyped + elide
            % return next level's props but with this name prefixed.
            % has any subprops just not constrained sets
            
            if obj.elide
                prefix = obj.name;
            else
                prefix = '';
            end
            
            %subgroups
            props = [props; parseList(obj.subgroups, prefix)];
            
            %datasets
            props = [props; parseList(obj.datasets, prefix)];
            
            %attributes
            props = [props; parseList(obj.attributes, prefix)];
            
            %links
            props = [props; parseList(obj.links, prefix)];
            
            function props = parseList(l, prefix)
                props = containers.Map;
                for i=1:length(l)
                    subp = l(i).getProps();
                    if ~isempty(prefix)
                        subkeys = keys(subp);
                        for j=1:length(subkeys)
                            k = subkeys{j};
                            props([prefix '_' k]) = subp(k);
                        end
                    else
                        props = [props; subp];
                    end
                end
            end
        end
    end
end