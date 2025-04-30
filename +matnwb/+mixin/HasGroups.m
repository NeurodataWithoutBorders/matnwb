classdef HasGroups < matlab.mixin.CustomDisplay & matlab.mixin.indexing.RedefinesDot & handle
% HasGroups - Provides methods for retrieving group elements by their key names 
%
% This mixin class allows accessing elements in Set properties using parentheses notation.
% For example, instead of using obj.setProperty.get('keyName'), you can use obj('keyName').
%
% Classes that inherit from this mixin must implement the GroupPropertyNames property
% to specify which properties contain Sets.

    properties (Abstract, Access = protected, Transient)
        GroupPropertyNames % Cell array of property names that contain Sets
    end
    
    methods (Access = protected)
        function varargout = dotReference(obj, indexOp)
            % Handle parentheses indexing references
            % Check if the index is a string (key name)

            key = indexOp(1).Name;

            if ischar(key) || isstring(key)
                keyName = indexOp(1).Name;
                
                % Check if the key name matches a key in any of the Set properties
                for i = 1:length(obj.GroupPropertyNames)
                    groupPropName = obj.GroupPropertyNames{i};
                    if isprop(obj, groupPropName)
                        % Get the Set property
                        setObj = obj.(groupPropName);
                        assert(isa(setObj, 'types.untyped.Set'))
                        
                        % Check if the Set has the key
                        if setObj.isKey(keyName)
                            % Get the value from the Set
                            if isscalar(indexOp)
                                [varargout{1:nargout}] = setObj.get(keyName);
                            else
                                intermediateObj = setObj.get(keyName);
                                [varargout{1:nargout}] = intermediateObj.(indexOp(2:end));
                            end
                            return;
                        end
                    end
                end

                % If we get here, the key wasn't found
                error(['Key ''' keyName ''' not found in any Set property.']);
            else
                error('Unsupported indexing operation')
            end
        end
        
        function obj = dotAssign(obj, indexOp, varargin)
            % Handle parentheses indexing assignments
            % For now, we don't allow assigning to keys in the Sets
            % This could be extended if needed
            
            key = indexOp(1).Name;

            if isscalar(indexOp)
                obj.(indexOp(1).Name)
            else
                obj.(indexOp(1).Name).(indexOp(2:end)) = varargin{:};
                keyName = indexOp{1};
                error(['Cannot assign to key ''' keyName ''' in Set properties.']);
            end
        end

        function n = dotListLength(obj, indexOp, indexContext)
            % Determine number of values to return
            % Check if the index is a string (key name)
            if length(indexOp) > 1 && (ischar(indexOp(1).Name) || isstring(indexOp(1).Name))
                intermediateObj = obj.dotReference(indexOp(1));
                n = listLength(intermediateObj, indexOp(2:end), indexContext);
            else
                n = 1;
            end
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
                if isprop(obj, groupPropName)
                    % Get the Set property
                    setObj = obj.(groupPropName);
                    
                    % Check if the Set is not empty
                    if ~isempty(setObj) && ismethod(setObj, 'keys')
                        % Get all keys from the Set
                        keys = setObj.keys();

                        if ~isempty(keys)
                            propList = cell2struct(setObj.values(), keys, 2);
                        else
                            propList = struct;
                        end
                        
                        % Create a title for this group
                        title = [groupPropName ' elements:'];
                        
                        % Add this group to the property groups
                        groups(end+1) = matlab.mixin.util.PropertyGroup(propList, title);
                    end
                end
            end
        end
    end
end
