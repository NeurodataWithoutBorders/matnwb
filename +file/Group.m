classdef Group < handle
    properties
        doc;
        name;
        canRename;
        type;
        definesType;
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
            obj.definesType = false;
            
            if nargin < 1
                return;
            end
            
            obj.doc = char(source.get('doc'));
            
            name = char(source.get('name'));
            def_name = char(source.get('default_name'));
            if isempty(name)
                obj.name = def_name;
            else
                obj.name = name;
                obj.canRename = false;
            end
            
            type = char(source.get('neurodata_type_def'));
            parent = char(source.get('neurodata_type_inc'));
            
            if isempty(type)
                obj.type = parent;
            else
                obj.definesType = true;
                obj.type = type;
            end
            
            quantity = source.get('quantity');
            if ~isempty(quantity)
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
            
            obj.elide = ~isempty(obj.name) && obj.scalar && isempty(obj.type) &&...
                isempty(obj.attributes);
        end
        
        function props = getProps(obj)
            props = containers.Map;
            %typed + constrained
            %should never happen
            
            if obj.isConstrainedSet && ~obj.definesType
                error('getProps shouldn''t be called on a constrained set.');
            end
            
            %datasets
            for i=1:length(obj.datasets)
                %if typed, check if constraint
                % if constraint, add its type and continue
                % otherwise, call getprops and assign to its name.
                %if untyped, assign data to its dtype and process attributes
                sub = obj.datasets(i);
                if isempty(sub.type)
                    if ~isempty(sub.attributes)
                        subattrnames = {sub.attributes.name};
                        newSubNames = strcat(sub.name, '_', subattrnames);
                        props = [props;
                            containers.Map(newSubNames, num2cell(sub.attributes))];
                    end
                    props(sub.name) = sub;
                else
                    if isempty(sub.name)
                        props(lower(sub.type)) = sub;
                    else
                        props(sub.name) = sub;
                    end
                end
            end
            
            %attributes
            if ~isempty(obj.attributes)
                props = [props;...
                    containers.Map({obj.attributes.name}, num2cell(obj.attributes))];
            end
            
            %links
            if ~isempty(obj.links)
                props = [props;...
                    containers.Map({obj.links.name}, num2cell(obj.links))];
            end
            
            %untyped
            % parse props and return.
            
            %typed
            % containersMap of properties -> types
            % parse props and return;
            
            %subgroups
            for i=1:length(obj.subgroups)
                %if typed, check if constraint
                % if constraint, add its type and continue
                % otherwise, call getprops and assign to its name.
                %if untyped, check if elided
                % if elided, add to prefix and check all subgroups, attributes and datasets.
                % otherwise, call getprops and assign to its name.
                sub = obj.subgroups(i);
                if isempty(sub.type)
                    if sub.elide
                        subprops = sub.getProps;
                        epkeys = keys(subprops);
                        for j=1:length(epkeys)
                            epk = epkeys{j};
                            epval = subprops(epk);
                            % hoist constrained sets to the current 
                            % subname.
                            if (isa(epval, 'file.Group') ||...
                                    isa(epval, 'file.Dataset')) &&...
                                    strcmpi(epk, epval.type) &&...
                                    epval.isConstrainedSet
                                propname = sub.name;
                            else
                                propname = [sub.name '_' epk];
                            end
                            if isKey(props, propname)
                                keyboard;
                                props(propname) = {props(propname); subprops(epk)};
                            else
                                props(propname) = subprops(epk);
                            end
                        end
                    else
                        props(sub.name) = sub;
                    end
                else
                    if isempty(sub.name)
                        props(lower(sub.type)) = sub;
                    else
                        props(sub.name) = sub;
                    end
                end
            end
        end
    end
end