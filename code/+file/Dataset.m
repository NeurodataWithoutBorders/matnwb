classdef Dataset < file.interface.HasProps
    properties
        name;
        doc;
        type;
        dtype;
        isConstrainedSet;
        required;
        value;
        readonly; %determines whether value can be changed or not
        scalar;
        shape;
        dimnames;
        attributes;
        linkable;
        definesType;
    end
    
    methods
        function obj = Dataset(source)
            obj.name = '';
            obj.doc = '';
            obj.isConstrainedSet = false;
            obj.type = '';
            obj.dtype = 'any';
            obj.required = true;
            obj.value = [];
            obj.readonly = false;
            obj.scalar = true;
            obj.definesType = false;
            
            obj.shape = {};
            obj.dimnames = {};
            obj.attributes = [];

            
            if nargin < 1
                return;
            end
            
            docKey = 'doc';
            if isKey(source, docKey)
                obj.doc = source(docKey);
            end
            
            nameKey = 'name';
            if isKey(source, nameKey)
                obj.name = source(nameKey);
            end

            % Todo: same as for attribute, should consolidate
            valueKey = 'value';
            defaultKey = 'default_value';
            if isKey(source, defaultKey)
                obj.value = source(defaultKey);
                obj.readonly = false;
            elseif isKey(source, valueKey)
                obj.value = source(valueKey);
                obj.readonly = true;
            else
                obj.value = [];
                obj.readonly = false;
            end
            
            typeKeys = {'neurodata_type_def', 'data_type_def'};
            parentKeys = {'neurodata_type_inc', 'data_type_inc'};
            hasTypeKeys = isKey(source, typeKeys);
            hasParentKeys = isKey(source, parentKeys);
            if any(hasTypeKeys)
                obj.type = source(typeKeys{hasTypeKeys});
                obj.definesType = true;
            elseif any(hasParentKeys)
                obj.type = source(parentKeys{hasParentKeys});
            end
            
            dataTypeKey = 'dtype';
            if isKey(source, dataTypeKey)
                obj.dtype = file.mapType(source(dataTypeKey));
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
            
            obj.isConstrainedSet = ~isempty(obj.type) && ~obj.scalar;
            
            if isKey(source, 'dims')
                obj.dimnames = source('dims');
            else
                obj.dimnames = {obj.name};
            end
            
            if isKey(source, 'shape')
                obj.shape = file.formatShape(source('shape'));
                obj.scalar = file.isShapeScalar(obj.shape);
            else
                obj.shape = 1;
            end
            
            attributeKey = 'attributes';
            if isKey(source, attributeKey)
                sourceAttributes = source(attributeKey);
                numAttributes = length(sourceAttributes);
                obj.attributes = repmat(file.Attribute, numAttributes, 1);
                for i=1:numAttributes
                    attribute = file.Attribute(sourceAttributes{i});
                    if isempty(obj.type)
                        attribute.dependent = obj.name;
                    end
                    obj.attributes(i) = attribute;
                end
            end
            
            %linkable if named and has no attributes
            hasNoAttributes = isempty(obj.attributes) || isempty(fieldnames(obj.attributes));
            obj.linkable = ~isempty(obj.name) && hasNoAttributes;
        end
        
        %% HasProps
        function props = getProps(obj)
            props = containers.Map;
            
            %typed
            % return props as typed props with custom `data`
            % types
            
            %untyped
            % error, untyped should not hold any data.
            
            %constrained
            % error unless it defines the object.

            assert(...
                ~isempty(obj.type), ...
                'NWB:Dataset:UnsupportedOperation', ...
                'The method `getProps` should not be called on an untyped dataset.' ...
                );
            
            assert( ...
                ~obj.isConstrainedSet || obj.definesType, ...
                'NWB:Dataset:UnsupportedOperation', ...
                'The method `getProps` should not be called on constrained dataset.' ...
                );

            if ~isempty(obj.dtype)
                props('data') = obj.dtype;
            end
            
            if ~isempty(obj.attributes)
                props = [props;...
                    containers.Map({obj.attributes.name}, num2cell(obj.attributes))];
            end
        end
    end
end