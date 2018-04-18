classdef Group < handle
    properties(SetAccess=private)
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
            
            obj.isConstrainedSet = ~obj.scalar && ~isempty(obj.type);
            
            %do attributes
            attributes = source.get('attributes');
            if ~isempty(attributes)
                len = attributes.size();
                obj.attributes = struct();
                attriter = attributes.iterator();
                for i=1:len
                    nextattr = file.Attribute(attriter.next());
                    obj.attributes.(nextattr.name) = nextattr;
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
                    obj.datasets(i) = file.Dataset(datasetiter.next());
                    if isempty(obj.datasets(i).name)
                        anonDataCnt = anonDataCnt + 1;
                    end
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
                    obj.subgroups(i) = file.Group(subgroupiter.next());
                    if isempty(obj.subgroups(i).name)
                        anonGroupCnt = anonGroupCnt + 1;
                    end
                end
            end
            
            %do links
            links = source.get('links');
            if ~isempty(links)
                len = links.size();
                obj.links = struct();
                liter = links.iterator();
                for i=1:len
                    nextlink = liter.next();
                    obj.links.(nextlink.get('name')) = file.Link(nextlink);
                end
            end
            
            obj.defaultEmpty = (length(obj.datasets) - anonDataCnt) == 0 &&...
                (length(obj.subgroups) - anonGroupCnt) == 0 &&...
                isempty(obj.links);
            
            obj.hasAnonData = anonDataCnt > 0;
            obj.hasAnonGroups = anonGroupCnt > 0;
            
            obj.elide = obj.scalar && isempty(obj.type) && isempty(obj.attributes)...
                && ~obj.hasAnonData && ~obj.hasAnonGroups;
        end
        
        function [props, varargs] = getProps(obj)
            props = containers.Map;
            varargs = {};
            
            if ~isempty(obj.type)
                propertyname = obj.type;
            else
                propertyname = obj.name;
            end
            
            if ~obj.elide
                if obj.isConstrainedSet
                    varargs = {obj};
                else
                    props(propertyname) = obj;
                end
            end
            
            if ~obj.hasAnonData && ~obj.hasAnonGroups 
                if ~isempty(obj.attributes)
                    names = fieldnames(obj.attributes);
                    for i=1:length(names)
                        nm = names{i};
                        if obj.elide
                            propnm = [propertyname '_' nm];
                        else
                            propnm = nm;
                        end
                        props(propnm) = obj.attributes.(nm);
                    end
                end
                
                if obj.elide
                    prefix = obj.name;
                else
                    prefix = '';
                end
                [props, varargs] = processLists(prefix, obj.datasets, props, varargs);
                [props, varargs] = processLists(prefix, obj.subgroups, props, varargs);
                
                if ~isempty(obj.links)
                    names = fieldnames(obj.links);
                    for i=1:length(names)
                        nm = names{i};
                        props(nm) = obj.links.(nm);
                    end
                end
            end
            
            function [subp, subv] = processLists(prefix, l, subp, subv)
                for j=1:length(l)
                    [sp, sv] = l(j).getProps();
                    
                    %map prop names to add prefix
                    if ~isempty(prefix)
                        tempsp = containers.Map;
                        pkeys = keys(sp);
                        for k=1:length(pkeys)
                            pk = pkeys{k};
                            tempsp([prefix '_' pk]) = sp(pk);
                        end
                        sp = tempsp;
                    end
                    subp = [subp; sp];
                    subv = [subv sv];
                end
            end
        end
    end
end