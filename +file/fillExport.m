function festr = fillExport(propertyNames, RawClass, parentName)
    exportHeader = 'function refs = export(obj, fid, fullpath, refs)';
    if isa(RawClass, 'file.Dataset')
        propertyNames = propertyNames(~strcmp(propertyNames, 'data'));
    end

    exportBody = {strjoin({...
        ['refs = export@' parentName '(obj, fid, fullpath, refs);']...
        'if any(strcmp(refs, fullpath))'...
        '    return;'...
        'end'...
        }, newline)};

    if isa(RawClass, 'file.Group') && strcmp(RawClass.type, 'NWBFile')
        %NWBFile is technically the root `group`, which in HDF5 is a single `/`
        % this messes with property creation so we reassign the path here to
        % empty string so concatenation looks right
        exportBody = [exportBody {'fullpath = '''';'}];
    end

    for i = 1:length(propertyNames)
        propertyName = propertyNames{i};
        pathProps = traverseRaw(propertyName, RawClass);
        if isempty(pathProps)
            keyboard;
        end
        prop = pathProps{end};
        elideProps = pathProps(1:end-1);
        elisions = cell(length(elideProps),1);
        % Construct elisions
        for j = 1:length(elideProps)
            elisions{j} = elideProps{j}.name;
        end

        elisions = strjoin(elisions, '/');
        if ~isempty(elideProps) && all(cellfun('isclass', elideProps, 'file.Group'))
            exportBody{end+1} = ['io.writeGroup(fid, [fullpath ''/' elisions ''']);'];
        end

        if strcmp(propertyName, 'unit') && strcmp(RawClass.type, 'VectorData')
            exportBody{end+1} = fillVectorDataUnitConditional();
        elseif strcmp(propertyName, 'sampling_rate') && strcmp(RawClass.type, 'VectorData')
            exportBody{end+1} = fillVectorDataSamplingRateConditional();
        elseif strcmp(propertyName, 'resolution') && strcmp(RawClass.type, 'VectorData')
            exportBody{end+1} = fillVectorDataResolutionConditional();
        else
            exportBody{end+1} = fillDataExport(propertyName, prop, elisions);
        end
    end

    festr = strjoin({ ...
        exportHeader ...
        , file.addSpaces(strjoin(exportBody, newline), 4) ...
        , 'end' ...
        }, newline);
end

function exportBody = fillVectorDataResolutionConditional()
    exportBody = strjoin({...
        'if ~isempty(obj.resolution) && any(endsWith(fullpath, ''units/spike_times''))' ...
        , '    io.writeAttribute(fid, [fullpath ''/resolution''], obj.resolution);' ...
        , 'end'}, newline);
end

function exportBody = fillVectorDataUnitConditional()
    exportBody = strjoin({...
          'validUnitPaths = strcat(''units/'', {''waveform_mean'', ''waveform_sd'', ''waveforms''});' ...
        , 'if ~isempty(obj.unit) && any(endsWith(fullpath, validUnitPaths))' ...
        , '    io.writeAttribute(fid, [fullpath ''/unit''], obj.unit);' ...
        , 'end'}, newline);
end

function exportBody = fillVectorDataSamplingRateConditional()
    exportBody = strjoin({...
          'validDataSamplingPaths = strcat(''units/'', {''waveform_mean'', ''waveform_sd'', ''waveforms''});' ...
        , 'if ~isempty(obj.sampling_rate) && any(endsWith(fullpath, validDataSamplingPaths))' ...
        , '    io.writeAttribute(fid, [fullpath ''/sampling_rate''], obj.sampling_rate);' ...
        , 'end'}, newline);
end

function path = traverseRaw(propertyName, RawClass)
    % returns a cell array of named tokens which may or may not indicate an identifier.
    % these tokens are relative to the Raw class
    path = {}; 

    if isa(RawClass, 'file.Dataset')
        if isempty(RawClass.attributes)
            return;
        end
        matchesAttribute = strcmp({RawClass.attributes.name}, propertyName);
        path = {RawClass.attributes(matchesAttribute)};
        return;
    end

    % probably a file.Group

    % get names of both subgroups and datasets
    subgroupNames = {};
    datasetNames = {};
    linkNames = {};
    attributeNames = {};

    if ~isempty(RawClass.attributes)
        attributeNames = {RawClass.attributes.name};
    end

    if ~isempty(RawClass.subgroups)
        subgroupNames = {RawClass.subgroups.name};
        lowerGroupTypes = lower({RawClass.subgroups.type});
        useLower = [RawClass.subgroups.isConstrainedSet] | cellfun('isempty', subgroupNames);
        subgroupNames(useLower) = lowerGroupTypes(useLower);
    end

    if ~isempty(RawClass.datasets)
        datasetNames = {RawClass.datasets.name};
        lowerDsTypes = lower({RawClass.datasets.type});
        useLower = [RawClass.datasets.isConstrainedSet] | cellfun('isempty', datasetNames);
        datasetNames(useLower) = lowerDsTypes(useLower);
    end

    if ~isempty(RawClass.links)
        linkNames = {RawClass.links.name};
    end

    if any(strcmp([attributeNames subgroupNames datasetNames linkNames], propertyName))
        isAttribute = strcmp(attributeNames, propertyName);
        isGroup = strcmp(subgroupNames, propertyName);
        isDataset = strcmp(datasetNames, propertyName);
        isLink = strcmp(linkNames, propertyName);
        if any(isAttribute)
            path = {RawClass.attributes(isAttribute)};
        elseif any(isGroup)
            path = {RawClass.subgroups(isGroup)};
        elseif any(isDataset)
            path = {RawClass.datasets(isDataset)};
        elseif any(isLink)
            path = {RawClass.links(isLink)};
        end
        return;
    end

    % find true path for elided property
    if startsWith(propertyName, datasetNames) || startsWith(propertyName, subgroupNames)
        for i=1:length(subgroupNames)
            name = subgroupNames{i};
            suffix = propertyName(length(name)+2:end);
            if startsWith(propertyName, name)
                res = traverseRaw(suffix, RawClass.subgroups(i));
                if ~isempty(res)
                    path = [{RawClass.subgroups(i)} res];
                    return;
                end
            end
        end
        for i=1:length(datasetNames)
            name = datasetNames{i};
            suffix = propertyName(length(name)+2:end);
            if startsWith(propertyName, name)
                res = traverseRaw(suffix, RawClass.datasets(i));
                if ~isempty(res)
                    path = [{RawClass.datasets(i)} res];
                    return;
                end
            end
        end
    end
end

function dataExportString = fillDataExport(name, prop, elisions)
    if isempty(elisions)
        fullpath = ['[fullpath ''/' prop.name ''']'];
        elisionpath = 'fullpath';
    else
        fullpath = ['[fullpath ''/' elisions '/' prop.name ''']'];
        elisionpath = ['[fullpath ''/' elisions ''']'];
    end

    if (isa(prop, 'file.Group') || isa(prop, 'file.Dataset')) && prop.isConstrainedSet
        % is a sub-object (with an export function)
        dataExportString = ['refs = obj.' name '.export(fid, ' elisionpath ', refs);'];
    elseif isa(prop, 'file.Link') || isa(prop, 'file.Group') ||...
            (isa(prop, 'file.Dataset') && ~isempty(prop.type))
        % obj, loc_id, path, refs
        dataExportString = ['refs = obj.' name '.export(fid, ' fullpath ', refs);'];
    elseif isa(prop, 'file.Dataset') %untyped dataset
        options = {};

        % special case due to unique behavior of file_create_date
        if strcmp(name, 'file_create_date')
            options = [options {'''forceChunking''', '''forceArray'''}];
        elseif ~prop.scalar
            options = [options {'''forceArray'''}];
        end

        % untyped compound
        if isstruct(prop.dtype)
            writerStr = 'io.writeCompound';
        else
            writerStr = 'io.writeDataset';
        end

        % just to guarantee optional arguments are correct syntax
        nameProp = sprintf('obj.%s', name);
        nameArgs = [{nameProp} options];
        nameArgs = strjoin(nameArgs, ', ');
        dataExportString = strjoin({...
            ['if startsWith(class(obj.' name '), ''types.untyped.'')']...
            ['    refs = obj.' name '.export(fid, ' fullpath ', refs);']...
            ['elseif ~isempty(obj.' name ')']...
            [sprintf('    %s(fid, %s, %s);', writerStr, fullpath, nameArgs)]...
            'end'...
            }, newline);
    else
        if prop.scalar
            forceArrayFlag = '';
        else
            forceArrayFlag = ', ''forceArray''';
        end
        dataExportString = sprintf('io.writeAttribute(fid, %1$s, obj.%2$s%3$s);',...
            fullpath, name, forceArrayFlag);
    end

    propertyChecks = {};

    if isa(prop, 'file.Attribute') && ~isempty(prop.dependent)
        %if attribute is dependent, check before writing
        if isempty(elisions) || strcmp(elisions, prop.dependent)
            depPropname = prop.dependent;
        else
            flattened = strfind(elisions, '/');
            flattened = strrep(elisions(1:flattened(end)), '/', '_');
            depPropname = [flattened prop.dependent];
        end
        propertyReference = sprintf('obj.%s', depPropname);
        propertyChecks{end+1} = sprintf(['~isempty(%1$s) ' ...
        '&& ~isa(%1$s, ''types.untyped.SoftLink'') ' ...
        '&& ~isa(%1$s, ''types.untyped.ExternalLink'')'], propertyReference);
    end

    if ~prop.required
        propertyChecks{end+1} = ['~isempty(obj.' name ')'];
    end

    if ~isempty(propertyChecks)
        dataExportString = sprintf('if %s\n%s\nend' ...
            , strjoin(propertyChecks, ' && '), file.addSpaces(dataExportString, 4) ...
            );
    end
end