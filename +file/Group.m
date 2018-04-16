classdef Group < handle
    properties(SetAccess=private)
        doc;
        name;
        canRename;
        type;
        isConstrainedSet; %that is, a general list of objects constrained with a type
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
            constrainedDataCnt = 0;
            if ~isempty(datasets)
                len = datasets.size();
                datasetiter = datasets.iterator();
                obj.datasets = repmat(file.Dataset, len, 1);
                for i=1:len
                    obj.datasets(i) = file.Dataset(datasetiter.next());
                    if obj.datasets(i).isConstrainedSet
                        constrainedDataCnt = constrainedDataCnt + 1;
                    end
                end
            end
            
            %do groups
            subgroups = source.get('groups');
            constrainedGroupCnt = 0;
            if ~isempty(subgroups)
                len = subgroups.size();
                subgroupiter = subgroups.iterator();
                obj.subgroups = repmat(file.Group, len, 1);
                for i=1:len
                    obj.subgroups(i) = file.Group(subgroupiter.next());
                    if obj.subgroups(i).isConstrainedSet
                        constrainedGroupCnt = constrainedGroupCnt + 1;
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
            
            obj.defaultEmpty = (length(obj.datasets) - constrainedDataCnt) == 0 &&...
                (length(obj.subgroups) - constrainedGroupCnt) == 0 &&...
                isempty(obj.links);
            
            obj.elide = obj.scalar && isempty(obj.type) &&...
                isempty(obj.attributes) && ~obj.defaultEmpty;
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
            [props, varargs] = processLists(obj.datasets, props, varargs);
            [props, varargs] = processLists(obj.subgroups, props, varargs);
            
            if ~isempty(obj.links)
                names = fieldnames(obj.links);
                for i=1:length(names)
                    nm = names{i};
                    props(nm) = obj.links.(nm);
                end
            end
            
            function [subp, subv] = processLists(l, subp, subv)
                for j=1:length(l)
                    [sp, sv] = l(j).getProps();
                    subp = [subp; sp];
                    subv = [subv sv];
                end
            end
        end
    end
end