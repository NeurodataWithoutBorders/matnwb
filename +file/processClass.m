function [Processed, classprops, inherited] = processClass(name, namespace, pregen)
    inherited = {};
    branch = [{namespace.getClass(name)} namespace.getRootBranch(name)];
    branchNames = cell(size(branch));
    TYPEDEF_KEYS = {'neurodata_type_def', 'data_type_def'};

    % Resolve type hierarchy (class and superclasses)
    for i = 1:length(branch)
        hasTypeDefs = isKey(branch{i}, TYPEDEF_KEYS);
        branchNames{i} = branch{i}(TYPEDEF_KEYS{hasTypeDefs});
    end
    
    if strcmp(name, 'CurrentClampSeries')
        keyboard
    end

    for i = 2:length(branch)
        currentNode = branch{1};
        parentNode = branch{i};

        if isKey(currentNode, 'groups')
            %schemes.updateGroupFromParent(currentNode('groups'), parentNode('groups'))
        end

        if isKey(currentNode, 'datasets') && isKey(parentNode, 'datasets')
            schemes.updateDatasetFromParent(currentNode('datasets'), parentNode('datasets'))
        end
    end

    for iAncestor = 1:length(branch)
        node = branch{iAncestor};
        hasTypeDefs = isKey(node, TYPEDEF_KEYS);
        nodename = node(TYPEDEF_KEYS{hasTypeDefs});

        if ~isKey(pregen, nodename)
            switch node('class_type')
                case 'groups'
                    class = file.Group(node);
                case 'datasets'
                    class = file.Dataset(node);
                otherwise
                    error('NWB:FileGen:InvalidClassType',...
                        'Class type %s is invalid', node('class_type'));
            end
            if strcmp(nodename, 'VectorData') && strcmp(namespace.name, 'hdmf_common')
                class = patchVectorData(class);
            end
            props = class.getProps();

            pregen(nodename) = struct('class', class, 'props', props);
        end
        try
            Processed(iAncestor) = pregen(nodename).class;
        catch
            keyboard;
        end
    end
    classprops = pregen(name).props;
    names = keys(classprops);
    for iAncestor = 2:length(Processed)
        superclassName = Processed(iAncestor).type;
        superclassProps = pregen(superclassName).props;
        superclassPropNames = keys(superclassProps);
        inherited = union(inherited, intersect(names, superclassPropNames));

        % % Too late, because missing values are set to default
        % % % update props from superclass prop defs
        % % for iInheritedProp = 1:numel(inherited)
        % %     superclassProp = superclassProps(inherited{iInheritedProp})
        % % end
    end
end

function class = patchVectorData(class)
    %% Unit Attribute
    % derived from schema 2.6.0
    source = containers.Map();
    source('name') = 'unit';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'The value must be ''volts'''];
    source('dtype') = 'text';
    source('value') = 'volts';
    source('required') = false;
    class.attributes(end+1) = file.Attribute(source);

    %% Sampling Rate Attribute
    % derived from schema 2.6.0

    source = containers.Map();
    source('name') = 'sampling_rate';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'Must be Hertz'];
    source('dtype') = 'float32';
    source('required') = false;

    class.attributes(end+1) = file.Attribute(source);
    %% Resolution Attribute
    % derived from schema 2.6.0

    source = containers.Map();
    source('name') = 'resolution';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'The smallest possible difference between two spike times. ' ...
        'Usually 1 divided by the acquisition sampling rate from which spike times were extracted, ' ...
        'but could be larger if the acquisition time series was downsampled or smaller if the ' ...
        'acquisition time series was smoothed/interpolated ' ...
        'and it is possible for the spike time to be between samples.' ...
        ];
    source('dtype') = 'float64';
    source('required') = false;

    class.attributes(end+1) = file.Attribute(source);
end