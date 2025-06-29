classdef NameRegistry < handle
% NameRegistry - Mapping between original NWB names and MATLAB-valid names
%
%   Ensures unique, reversible (bi-directional) mapping from original names
%   used for data objects in NWB files to valid MATLAB identifiers.

    properties (Access = private)
        % Map from valid MATLAB names to original names
        ValidToOriginalMap
        
        % Map from original names to valid MATLAB names
        OriginalToValidMap
    end

    methods
        function obj = NameRegistry()
            obj.ValidToOriginalMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
            obj.OriginalToValidMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
        end
        
        function validName = addMapping(obj, originalName, validName)
            % Add a mapping between an original name and a MATLAB-valid name
            % If validName is not provided, it will be generated

            arguments
                obj matnwb.utility.NameRegistry
                originalName (1,1) string
                validName (1,1) string = missing
            end
            
            if ismissing(validName)
                validName = obj.createValidName(originalName);
            end

            assert(~obj.existOriginalName(originalName), ...
                'NWB:NameRegistry:DuplicateOriginalName', ...
                'The original name "%s" is already mapped', originalName);
            
            assert(~obj.existValidName(validName), ...
                'NWB:NameRegistry:DuplicateValidName', ...
                'The valid name "%s" is already mapped', validName);

            % Add the mapping
            obj.ValidToOriginalMap(validName) = originalName;
            obj.OriginalToValidMap(originalName) = validName;
        end

        function removeMapping(obj, nameToRemove)
            % Remove a mapping by either valid or original name
            
            if obj.existValidName(nameToRemove)
                originalName = obj.getOriginalName(nameToRemove);
                obj.ValidToOriginalMap.remove(nameToRemove);
                obj.OriginalToValidMap.remove(originalName);
            elseif obj.existOriginalName(nameToRemove)
                validName = obj.getValidName(nameToRemove);
                obj.ValidToOriginalMap.remove(validName);
                obj.OriginalToValidMap.remove(nameToRemove);
            else
                error('NWB:NameRegistry:UnknownName', ...
                    'No mapping exists for name "%s"', nameToRemove);
            end
        end
        
        function validName = getValidName(obj, originalName)
            % Get the valid MATLAB name for an original name
            assert(obj.existOriginalName(originalName), ...
                'NWB:NameRegistry:UnknownOriginalName', ...
                'No mapping exists for original name "%s"', originalName);
            validName = obj.OriginalToValidMap(originalName);
        end
        
        function originalName = getOriginalName(obj, validName)
            % Get the original name for a valid MATLAB name
            assert(obj.existValidName(validName), ...
                'NWB:NameRegistry:UnknownValidName', ...
                'No mapping exists for valid name "%s"', validName);
            originalName = obj.ValidToOriginalMap(validName);
        end
        
        function tf = existValidName(obj, validName)
            % Check if a valid MATLAB name exists in the mapping
            tf = obj.ValidToOriginalMap.isKey(validName);
        end
        
        function tf = existOriginalName(obj, originalName)
            % Check if an original name exists in the mapping
            tf = obj.OriginalToValidMap.isKey(originalName);
        end
        
        function validNames = getAllValidNames(obj)
            % Return all valid MATLAB names as a 1xn cell array
            validNames = obj.ValidToOriginalMap.keys();
        end

        function originalNames = getAllOriginalNames(obj)
            % Return all original names as a 1xn cell array
            originalNames = obj.OriginalToValidMap.keys();
        end

        function T = getNameMappingTable(obj)
            % Return a table showing all name mappings
            validNames = obj.ValidToOriginalMap.keys();
            originalNames = obj.ValidToOriginalMap.values();

            tableVariableNames = {'ValidIdentifier', 'OriginalName'};

            T = table(string(validNames'), string(originalNames'), ...
                'VariableNames', tableVariableNames);
        end
    end

    methods (Access = private)
        function validName = createValidName(obj, originalName)
            % Create a valid MATLAB name from an original name
            baseName = matlab.lang.makeValidName(originalName);

            % Ensure uniqueness
            if obj.existValidName(baseName)
                counter = 1;
                while obj.existValidName(sprintf('%s_%d', baseName, counter))
                    counter = counter + 1;
                end
                validName = sprintf('%s_%d', baseName, counter);
            else
                validName = baseName;
            end
        end
    end
end
