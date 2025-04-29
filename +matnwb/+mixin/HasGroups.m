classdef HasGroups < matlab.mixin.CustomDisplay & matlab.mixin.indexing.RedefinesDot & handle
% HasGroups - Provides methods for retrieving group elements by their key names 
%
% This mixin class allows accessing elements in Set properties using dot notation.
% For example, instead of using obj.setProperty.get('keyName'), you can use obj.keyName.
%
% Classes that inherit from this mixin must implement the GroupPropertyNames property
% to specify which properties contain Sets.

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames % Cell array of property names that contain Sets
    end
    
    methods (Access = protected)
        function varargout = dotReference(obj, indexOp)
            % Handle dot indexing references
            propName = char(indexOp(1).Name);

            % First check if it's a method
            methodList = methods(obj);
            if any(strcmp(methodList, propName))
                % It's a method, use built-in behavior
                %[varargout{1:nargout}] = builtin('subsref', obj, substruct('.', propName));
                [varargout{1:nargout}] = obj.(indexOp);

                return;
            end
            
            % Then check if it's a property
            if isprop(obj, propName)
                % Use built-in behavior for direct properties
                %[varargout{1:nargout}] = builtin('subsref', obj, substruct('.', propName));
                [varargout{1:nargout}] = obj.(indexOp);
                return;
            end
            
            % Check if the property name matches a key in any of the Set properties
            for i = 1:length(obj.GroupPropertyNames)
                groupPropName = obj.GroupPropertyNames{i};
                if isprop(obj, groupPropName) && ~isempty(obj.(groupPropName))
                    % Check if this Set has the key
                    if obj.(groupPropName).isKey(propName)
                        % Get the value from the Set
                        [varargout{1:nargout}] = obj.(groupPropName).get(propName);
                        return;
                    end
                end
            end
            
            % If we get here, the property/method wasn't found
            error(['Reference to non-existent field or method ''' propName '''.']);
        end
        
        function obj = dotAssign(obj, indexOp, varargin)
            % Handle dot indexing assignments
            propName = char(indexOp(1).Name);
            
            % Check if the property exists directly in the object
            if isprop(obj, propName)
                % Use built-in behavior for direct properties
                subs = indexOp2subs(indexOp);
                obj = builtin('subsasgn', obj, substruct('.', propName), varargin{:});
                
                %obj = builtin('dotAssign', indexOp, varargin{:});
                %[obj.(propName)(indexOp(2:end))] = varargin{:};
                return;
            end
            
            % For now, we don't allow assigning to keys in the Sets
            % This could be extended if needed
            error(['Cannot assign to key ''' propName ''' in Set properties.']);
        end
        
        function n = dotListLength(obj, indexOp, indexContext)
            % Determine number of values to return
            propName = char(indexOp);
            
            % Check if it's a method
            methodList = methods(obj);
            if any(strcmp(methodList, propName))
                % It's a method, use built-in behavior
                value = builtin('subsref', obj, substruct('.', propName));
                if isnumeric(value) || islogical(value)
                    n = length(value);
                elseif iscell(value)
                    n = length(value);
                else
                    n = 1;
                end
                return;
            end
            
            % Check if it's a property
            if isprop(obj, propName)
                % Use built-in behavior for direct properties
                value = builtin('subsref', obj, substruct('.', propName));
                if isnumeric(value) || islogical(value)
                    n = length(value);
                elseif iscell(value)
                    n = length(value);
                else
                    n = 1;
                end
                return;
            end
            
            % Check if the property name matches a key in any of the Set properties
            for i = 1:length(obj.GroupPropertyNames)
                groupPropName = obj.GroupPropertyNames{i};
                if isprop(obj, groupPropName) && ~isempty(obj.(groupPropName))
                    % Check if this Set has the key
                    if obj.(groupPropName).isKey(propName)
                        % Get the value from the Set
                        value = obj.(groupPropName).get(propName);
                        if isnumeric(value) || islogical(value)
                            n = length(value);
                        elseif iscell(value)
                            n = length(value);
                        else
                            n = 1;
                        end
                        return;
                    end
                end
            end
            
            % If we get here, the property/method wasn't found
            error(['Reference to non-existent field or method ''' propName '''.']);
        end
        
        function groups = getPropertyGroups(obj)
            % Create property groups for display
            % Standard properties
            standardProps = properties(obj);
            
            % Remove the Set properties that we'll display separately
            for i = 1:length(obj.GroupPropertyNames)
                idx = strcmp(standardProps, obj.GroupPropertyNames{i});
                standardProps(idx) = [];
            end
            
            % Create a property group for standard properties
            groups = matlab.mixin.util.PropertyGroup(standardProps);
            
            % Create property groups for each Set property
            for i = 1:length(obj.GroupPropertyNames)
                groupPropName = obj.GroupPropertyNames{i};
                if isprop(obj, groupPropName) && ~isempty(obj.(groupPropName))
                    % Get all keys from the Set
                    keys = obj.(groupPropName).keys();
                    
                    % Create a title for this group
                    title = [groupPropName ' elements:'];
                    
                    % Add this group to the property groups
                    groups(end+1) = matlab.mixin.util.PropertyGroup(keys, title);
                end
            end
        end
    end
end
