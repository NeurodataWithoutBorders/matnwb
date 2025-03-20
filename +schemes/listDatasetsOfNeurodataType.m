function datasetNames = listDatasetsOfNeurodataType(typeClassName)
% listDatasetsOfNeurodataType - List names of datasets of a neurodata type
%
% Input Arguments:
%   - typeClassName (string) -
%     Full MatNWB class name for a neurodata type, i.e "types.core.TimeSeries"
%
% Output Arguments:
%   - datasetNames (string) - 
%     Names of datasets contained in the specified neurodata type

    arguments
        typeClassName (1,1) string
    end

    classNameSplit = string( split(typeClassName, '.') );
    typesIdx = find(classNameSplit == "types");
    
    assert(~isempty(typesIdx), 'Expected class name to contain "types"')
    namespaceName = classNameSplit(typesIdx+1);
    namespaceName = strrep(namespaceName, '_', '-');
    namespace = schemes.loadNamespace(namespaceName);
    
    neurodataTypeName = classNameSplit(typesIdx+2);
    typeScheme = namespace.registry(neurodataTypeName);
    
    % Verify that class_type is groups or datasets
    assert(ismember( typeScheme('class_type'), {'groups', 'datasets'} ), ...
        'NWB:ListDatasets:InvalidClassType', ...
        'Class type %s is invalid', typeScheme('class_type'))

    switch typeScheme('class_type')
        case 'groups'
            if isKey(typeScheme, 'datasets')
                datasetMaps = typeScheme('datasets');
                datasetNames = repmat("", size(datasetMaps));
                for i = 1:numel(datasetMaps)
                    if isKey(datasetMaps{i}, 'name')
                        datasetNames(i) = datasetMaps{i}('name');
                    elseif isKey(datasetMaps{i}, 'data_type_inc')
                        datasetNames(i) = lower( datasetMaps{i}('data_type_inc') );
                    elseif isKey(datasetMaps{i}, 'data_type_def')
                        datasetNames(i) = lower( datasetMaps{i}('data_type_def') );
                    else
                        % Should not occur. Every dataset must have either a 
                        % unique fixed name or a unique data type determined 
                        % by neurodata_type_def or neurodata_type_inc
                    end
                end
                datasetNames(datasetNames=="") = [];
            else
                datasetNames = string.empty;
            end

        case 'datasets'
            datasetNames = "data";
    end
end
