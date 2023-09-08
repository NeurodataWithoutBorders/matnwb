function [dataName, indexName] = getVectorClassName()
    % GETVECTORCLASSNAME returns applicable class names from the MATLAB environment.
    % 
    % D = GETVECTORCLASSNAME() returns the correct VectorData class name, i.e.
    % 'types.hdmf_common.VectorData'
    %
    % [D, I] = GETVECTORCLASSNAME() returns the VectorData class name D and VectorIndex class name
    % I. i.e. 'types.hdmf_common.VectorData' and 'types.hdmf_common.VectorIndex'
    % 
    % Throws an error if no classes are found.
    % Emits a warning if the namespaces for VectorIndex and VectorData do not match.

    dataName = '';
    indexName = '';

    if 8 == exist('types.hdmf_common.VectorData', 'class')
        dataName = 'types.hdmf_common.VectorData';
    elseif 8 == exist('types.core.VectorData', 'class')
        dataName = 'types.core.VectorData';
    end

    if 8 == exist('types.hdmf_common.VectorIndex', 'class')
        indexName = 'types.hdmf_common.VectorIndex';
    elseif 8 == exist('types.core.VectorIndex', 'class')
        indexName = 'types.core.VectorIndex';
    end

    assert(~isempty(dataName) && ~isempty(indexName) ...
        , 'NWB:GetVectorClassName:MissingNamespace' ...
        , 'Could not find any useable VectorData or VectorIndex class names.');

    dataPackages = split(dataName, '.');
    dataNamespace = dataPackages{2};
    indexPackages = split(indexName, '.');
    indexNamespace = indexPackages{2};
    if ~strcmp(dataNamespace, indexNamespace)
        warning('NWB:GetVectorClassName:PotentiallyInvalidNamespace' ...
            , [ ...
            'VectorData namespace "%s" is not the same as VectorIndex namespace "%s". ' ...
            'Please ensure your generated namespace files are not from a previous error.'] ...
            , dataNamespace, indexNamespace);
    end
end

