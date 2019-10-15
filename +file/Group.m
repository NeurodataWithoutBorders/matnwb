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
            obj.doc = '';
            obj.name = '';
            obj.canRename = true;
            obj.type = '';
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
            
            docKey = 'doc';
            if isKey(source, docKey)
                obj.doc = source(docKey);
            end
            
            if isKey(source, 'name')
                obj.name = source('name');
                obj.canRename = false;
            elseif isKey(source, 'default_name')
                obj.name = source('default_name');
            end
            
            typeDefKey = 'neurodata_type_def';
            parentKey = 'neurodata_type_inc';
            if isKey(source, typeDefKey)
                obj.type = source(typeDefKey);
                obj.definesType = true;
            elseif isKey(source, parentKey)
                obj.type = source(parentKey);
            end
            
            if isKey(source, 'quantity')
                quantity = source('quantity');
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

            if isKey(source, 'attributes')
                sourceAttributes = source('attributes');
                obj.attributes = repmat(file.Attribute, length(sourceAttributes), 1);
                for i=1:length(sourceAttributes)
                    attribute = file.Attribute(sourceAttributes{i});
                    if isempty(obj.type)
                        attribute.dependent = obj.name;
                    end
                    obj.attributes(i) = attribute;
                end
            end
            
            anonDataCnt = 0;
            if isKey(source, 'datasets')
                sourceDatasets = source('datasets');
                obj.datasets = repmat(file.Dataset, length(sourceDatasets), 1);
                for i=1:length(sourceDatasets)
                    dataset = file.Dataset(sourceDatasets{i});
                    if isempty(dataset.name)
                        anonDataCnt = anonDataCnt + 1;
                    end
                    obj.datasets(i) = dataset;
                end
            end

            anonGroupCnt = 0;
            if isKey(source, 'groups')
                subGroups = source('groups');
                obj.subgroups = repmat(file.Group, length(subGroups), 1);
                for i=1:length(subGroups)
                    group = file.Group(subGroups{i});
                    if isempty(group.name)
                        anonGroupCnt = anonGroupCnt + 1;
                    end
                    obj.subgroups(i) = group;
                end
            end
            
            if isKey(source, 'links')
                sourceLinks = source('links');
                obj.links = repmat(file.Link, length(sourceLinks), 1);
                for i=1:length(sourceLinks)
                    obj.links(i) = file.Link(sourceLinks{i});
                end
            end
            
            allDatasetsAnon = length(obj.datasets) == anonDataCnt;
            allGroupsAnon = length(obj.subgroups) == anonGroupCnt;
            hasLinks = ~isempty(obj.links);
            obj.defaultEmpty = allDatasetsAnon && allGroupsAnon && ~hasLinks;
            
            obj.hasAnonData = anonDataCnt > 0;
            obj.hasAnonGroups = anonGroupCnt > 0;
            
            obj.elide = ~isempty(obj.name) && obj.scalar && isempty(obj.type) &&...
                isempty(obj.attributes);
        end
        
        function Prop_Map = getProps(obj)
            Prop_Map = containers.Map;
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
                SubData = obj.datasets(i);
                if isempty(SubData.type)
                    if ~isempty(SubData.attributes)
                        attr_names = {SubData.attributes.name};
                        attr_names = strcat(SubData.name, '_', attr_names);
                        Sub_Attribute_Map =...
                            containers.Map(attr_names, num2cell(SubData.attributes));
                        Prop_Map = [Prop_Map; Sub_Attribute_Map];
                    end
                    Prop_Map(SubData.name) = SubData;
                else
                    if isempty(SubData.name)
                        Prop_Map(lower(SubData.type)) = SubData;
                    else
                        Prop_Map(SubData.name) = SubData;
                    end
                end
            end
            
            %attributes
            if ~isempty(obj.attributes)
                Prop_Map = [Prop_Map;...
                    containers.Map({obj.attributes.name}, num2cell(obj.attributes))];
            end
            
            %links
            if ~isempty(obj.links)
                Prop_Map = [Prop_Map;...
                    containers.Map({obj.links.name}, num2cell(obj.links))];
            end
            
            %untyped
            % parse props and return.
            
            %typed
            % containersMap of properties -> types
            % parse props and return;
            
            %subgroups
            for i = 1:length(obj.subgroups)
                %if typed, check if constraint
                % if constraint, add its type and continue
                % otherwise, call getprops and assign to its name.
                %if untyped, check if elided
                % if elided, add to prefix and check all subgroups, attributes and datasets.
                % otherwise, call getprops and assign to its name.
                Sub_Group = obj.subgroups(i);
                group_name = Sub_Group.name;
                group_type = Sub_Group.type;
                if ~isempty(group_type)
                    if isempty(group_name)
                        Prop_Map(lower(group_type)) = Sub_Group;
                    else
                        Prop_Map(group_name) = Sub_Group;
                    end
                    continue;
                end
                
                if ~Sub_Group.elide
                    Prop_Map(group_name) = Sub_Group;
                    continue;
                end
                
                Descendant_Map = Sub_Group.getProps;
                descendant_names = keys(Descendant_Map);
                for sub_group_i = 1:length(descendant_names)
                    descendant_name = descendant_names{sub_group_i};
                    Descendant = Descendant_Map(descendant_name);
                    % hoist constrained sets to the current
                    % subname.
                    can_be_constrained =...
                        isa(Descendant, 'file.Group')...
                        || isa(Descendant, 'file.Dataset');
                    is_constrained = can_be_constrained...
                        && strcmpi(descendant_name, Descendant.type)...
                        && Descendant.isConstrainedSet;
                    if is_constrained
                        prop_name = group_name;
                    else
                        prop_name = [group_name '_' descendant_name];
                    end
                    
                    if isKey(Prop_Map, prop_name)
                        warning(['Generic group `%s` is currently unsupported '...
                            'in MatNwb and is ignored.'], prop_name);
                        continue;
                    end
                    
                    Prop_Map(prop_name) = Descendant_Map(descendant_name);
                end
            end
        end
    end
end