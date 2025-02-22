classdef MetaClass < handle & matlab.mixin.CustomDisplay
    properties (Hidden, SetAccess = private)
        metaClass_fullPath;
    end

    properties (Constant, Transient, Access = protected)
        REQUIRED containers.Map = containers.Map
    end

    methods
        function obj = MetaClass(varargin)
        end
    end
    
    methods (Access = private)
        function refs = write_base(obj, fid, fullpath, refs)
            if isa(obj, 'types.untyped.GroupClass')
                io.writeGroup(fid, fullpath);
                return;
            end
            
            try
                if isa(obj.data, 'types.untyped.DataStub')...
                        || isa(obj.data, 'types.untyped.DataPipe')
                    refs = obj.data.export(fid, fullpath, refs);
                elseif istable(obj.data) || isstruct(obj.data) ||...
                        isa(obj.data, 'containers.Map')
                    io.writeCompound(fid, fullpath, obj.data);
                else
                    io.writeDataset(fid, fullpath, obj.data, 'forceArray');
                end
            catch ME
                refs = obj.captureReferenceErrors(ME, fullpath, refs);
            end
        end
        
        function refs = captureReferenceErrors(~, ME, fullpath, refs)
            if any(strcmp(ME.identifier, {...
                    'NWB:getRefData:InvalidPath',...
                    'NWB:ObjectView:MissingPath'}))
                refs(end+1) = {fullpath};
            else
                rethrow(ME);
            end
        end
    end
    
    methods
        function refs = export(obj, fid, fullpath, refs)
            % throwErrorIfCustomConstraintUnfulfilled is intentionally placed 
            % before throwErrorIfMissingRequiredProps. 
            % See file.fillCustomConstraint
            obj.throwErrorIfCustomConstraintUnfulfilled(fullpath)
            obj.throwErrorIfMissingRequiredProps(fullpath)
            obj.metaClass_fullPath = fullpath;
            %find reference properties
            propnames = properties(obj);
            props = cell(size(propnames));
            for i=1:length(propnames)
                props{i} = obj.(propnames{i});
            end
            
            refProps = cellfun('isclass', props, 'types.untyped.ObjectView') |...
                cellfun('isclass', props, 'types.untyped.RegionView');
            props = props(refProps);
            for i=1:length(props)
                try
                    io.getRefData(fid, props{i});
                catch ME
                    refs = obj.captureReferenceErrors(ME, fullpath, refs);
                end
            end
            
            refLen = length(refs);
            refs = obj.write_base(fid, fullpath, refs);
            if refLen ~= length(refs)
                return;
            end
            
            uuid = char(java.util.UUID.randomUUID().toString());
            if isa(obj, 'NwbFile')
                io.writeAttribute(fid, '/namespace', 'core');
                io.writeAttribute(fid, '/neurodata_type', 'NWBFile');
                io.writeAttribute(fid, '/object_id', uuid);
            else
                namespacePath = [fullpath '/namespace'];
                neuroTypePath = [fullpath '/neurodata_type'];
                uuidPath = [fullpath '/object_id'];
                dotparts = split(class(obj), '.');
                namespace = strrep(dotparts{2}, '_', '-');
                classtype = dotparts{3};
                io.writeAttribute(fid, namespacePath, namespace);
                io.writeAttribute(fid, neuroTypePath, classtype);
                io.writeAttribute(fid, uuidPath, uuid);
            end
        end
        
        function obj = loadAll(obj)
            propnames = properties(obj);
            for i=1:length(propnames)
                prop = obj.(propnames{i});
                if isa(prop, 'types.untyped.DataStub')
                    obj.(propnames{i}) = prop.load();
                end
            end
        end

        function warnIfAttributeDependencyMissing(obj, propName, dependencyPropName)
            % Skip warning if the value is equal to the default value for
            % the property (value was probably not set by the user).
            if obj.propertyValueEqualsDefaultValue(propName)
                return
            end

            warnState = warning('backtrace', 'off');
            cleanupObj = onCleanup(@(s) warning(warnState));
            warningId = 'NWB:AttributeDependencyNotSet';
            warningMessage = sprintf( [ ...
                'The property "%s" of type "%s" depends on the property "%s", ' ...
                'which is unset. If you do not set a value for "%s, the ' ...
                'value of "%s" will not be exported to file.'], ...
                propName, class(obj), dependencyPropName, dependencyPropName, propName);
            warning(warningId, warningMessage) %#ok<SPWRN>
        end

        function warnIfPropertyAttributeNotExported(obj, propName, depPropName, fullpath)
            % Skip warning if the value is equal to the default value for
            % the property (value was probably not set by the user).
            if obj.propertyValueEqualsDefaultValue(propName)
                return
            end

            warnState = warning('backtrace', 'off');
            cleanupObj = onCleanup(@(s) warning(warnState));
            warningId = 'NWB:DependentAttributeNotExported';
            warningMessage = sprintf( [ ...
                'The property "%s" of type "%s" was not exported to file ', ...
                'location "%s" because it depends on the property "%s" ', ...
                'which is unset.' ], propName, class(obj), fullpath, depPropName);
            warning(warningId, warningMessage) %#ok<SPWRN>
        end
    end

    methods (Access = protected) % Override matlab.mixin.CustomDisplay
        function str = getFooter(obj)
            obj.displayWarningIfMissingRequiredProps();
            str = '';
        end
    end

    methods (Access = protected)
        function missingRequiredProps = checkRequiredProps(obj)
            missingRequiredProps = {};
            requiredProps = obj.getRequiredProperties();

            for i = 1:numel(requiredProps)
                thisPropName = requiredProps{i};
                if isempty(obj.(thisPropName))
                    missingRequiredProps{end+1} = thisPropName; %#ok<AGROW>
                end
            end
        end

        function displayWarningIfMissingRequiredProps(obj)
            missingRequiredProps = obj.checkRequiredProps();

            % Exception: 'file_create_date' is automatically added by the 
            % matnwb API on export,  so no need to warn if it is missing.
            if isa(obj, 'types.core.NWBFile')
                missingRequiredProps = setdiff(missingRequiredProps, 'file_create_date', 'stable');
            end
            
            % Exception: 'id' of DynamicTable is automatically assigned if not 
            % specified, so no need to warn if it is missing.
            if isa(obj, 'types.hdmf_common.DynamicTable')
                missingRequiredProps = setdiff(missingRequiredProps, 'id', 'stable');
            end

            if ~isempty( missingRequiredProps )
                warnState = warning('backtrace', 'off');
                cleanerObj = onCleanup(@(s) warning(warnState));

                propertyListStr = obj.prettyPrintPropertyList(missingRequiredProps);
                warning('NWB:RequiredPropertyMissing', ...
                    ['The following required properties are missing for ', ...
                    'instance for type "%s":\n%s'], class(obj), propertyListStr)
            end
        end

        function throwErrorIfRequiredDependencyMissing(obj, propName, depPropName, fullpath)
            if isempty(fullpath); fullpath = 'root'; end
            errorId = 'NWB:DependentRequiredPropertyMissing';
            errorMessage = sprintf( [ ...
                'The property "%s" of type "%s" in file location "%s" is ' ...
                'required when the property "%s" is set. Please add a value ' ...
                'for "%s" and re-export.'], ...
                propName, class(obj), fullpath, depPropName, propName);
            error(errorId, errorMessage) %#ok<SPERR>
        end

        function throwErrorIfMissingRequiredProps(obj, fullpath)
            missingRequiredProps = obj.checkRequiredProps();
            if ~isempty( missingRequiredProps )
                propertyListStr = obj.prettyPrintPropertyList(missingRequiredProps);
                error('NWB:RequiredPropertyMissing', ...
                    ['The following required properties are missing for ', ...
                    'instance for type "%s" at file location "%s":\n%s' ], ...
                    class(obj), fullpath, propertyListStr)
            end
        end

        function throwErrorIfCustomConstraintUnfulfilled(obj, fullpath)
            try
                obj.checkCustomConstraint()
            catch ME
                error('NWB:CustomConstraintUnfulfilled', ...
                    ['The following error was caught when exporting type ', ...
                    '"%s" at file location "%s":\n%s'], ...
                    class(obj), fullpath, ME.message)
            end
        end
    end

    methods
        function checkCustomConstraint(obj) %#ok<MANU>
            % This method is meant to be overridden by subclasses that have 
            % custom constraints that can not be inferred from the nwb schema.
        end
    end

    methods (Access = private)
        function requiredProps = getRequiredProperties(obj)

            % Introspectively retrieve required properties and add to
            % persistent cache/map.

            typeClassName = class(obj);
            typeNamespaceVersion = getNamespaceVersionForType(typeClassName);

            typeKey = sprintf('%s_%s', typeClassName, typeNamespaceVersion);

            if isKey(obj.REQUIRED, typeKey)
                requiredProps = obj.REQUIRED( typeKey );
            else
                mc = metaclass(obj);
                propertyDescription = {mc.PropertyList.Description};
                isRequired = startsWith(propertyDescription, 'REQUIRED');
                requiredProps = {mc.PropertyList(isRequired).Name};
                obj.REQUIRED( typeKey ) = requiredProps;
            end
        end

        function tf = propertyValueEqualsDefaultValue(obj, propName)
        % propertyValueEqualsDefaultValue - Check if value of property is
        % equal to the property's default value
            
            mc = metaclass(obj);
            propInfo = mc.PropertyList(strcmp({mc.PropertyList.Name}, propName));
            if propInfo.HasDefault
                propValue = obj.(propName);
                tf = isequal(propValue, propInfo.DefaultValue);
            else
                tf = false;
            end
        end
    end

    methods (Static, Access = private)
        function propertyListStr = prettyPrintPropertyList(propertyNames)
            propertyListStr = compose('    %s', string(propertyNames));
            propertyListStr = strjoin(propertyListStr, newline);
        end
    end
end

function version = getNamespaceVersionForType(typeClassName)
    if strcmp(typeClassName, 'NwbFile')
        namespaceName = 'types.core';
    else
        classNameParts = strsplit(typeClassName, '.');
        namespaceName = strjoin(classNameParts(1:end-1), '.');
    end
    assert(startsWith(namespaceName, 'types.'), ...
        'Expected type to belong to namespace.') 
    
    version = feval( ...
        sprintf('%s.%s', namespaceName, matnwb.common.constant.VERSIONFUNCTION) ...
        );
end
