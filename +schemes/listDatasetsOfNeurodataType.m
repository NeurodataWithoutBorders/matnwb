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
    namespace = schemes.loadNamespace(namespaceName, misc.getMatnwbDir);
    
    neurodataTypeName = classNameSplit(typesIdx+2);
    typeScheme = namespace.registry(neurodataTypeName);
    
    switch typeScheme('class_type')
        case 'groups'
            if isKey(typeScheme, 'datasets')
                datasetMaps = typeScheme('datasets');
        
                datasetNames = repmat("", size(datasetMaps));
                for i = 1:numel(datasetMaps)
                    if isKey(datasetMaps{i}, 'name')
                        datasetNames(i) = datasetMaps{i}('name');
                    else
                        keyboard
                    end
                end
                datasetNames(datasetNames=="") = [];
            else
                datasetNames = string.empty;
            end

        case 'datasets'
            datasetNames = "data";
        otherwise
            error('Unexpected class type')
    end
end
