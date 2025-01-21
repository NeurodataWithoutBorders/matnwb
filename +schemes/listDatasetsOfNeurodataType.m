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
    namespace = schemes.loadNamespace(namespaceName, misc.getMatnwbDir);
    
    neurodataTypeName = classNameSplit(typesIdx+2);
    typeScheme = namespace.registry(neurodataTypeName);
    
    datasetMaps = typeScheme('datasets');

    datasetNames = repmat("", size(datasetMaps));
    for i = 1:numel(datasetMaps)
        datasetNames(i) = datasetMaps{i}('name');
    end
end
