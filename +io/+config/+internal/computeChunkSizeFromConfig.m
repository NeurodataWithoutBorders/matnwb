function chunkSize = computeChunkSizeFromConfig(A, chunkingConfig)
% computeChunkSizeFromConfig - Compute the chunk size for a dataset using the provided configuration.
%   This function determines the chunk size for a dataset based on the chunk
%   dimensions provided in the datasetConfig structure. It adjusts dimensions 
%   according to rules: 'max' uses the dataset size, fixed numbers use their 
%   value, and 'flex' calculates the dimension size to approximate the target 
%   chunk size in bytes.
%
%   Inputs:
%       A - A numeric dataset whose chunk size is to be computed.
%       datasetConfig (1,1) struct - Struct defining chunk dimensions and chunk target size.
%
%   Output:
%       chunkSize - A vector specifying the chunk size for each dimension of A.

    arguments
        A {mustBeNumeric}
        chunkingConfig (1,1) struct
    end
    
    assert(isfield(chunkingConfig, 'strategy_by_rank'), ...
        'Expected datasetConfig to have field "strategy_by_rank"')
    assert(isfield(chunkingConfig, 'target_chunk_size'), ...
        'Expected datasetConfig to have field "target_chunk_size"')

    % Get dataset size
    dataSize = size(A);
    numDimensions = numel(dataSize);

    isDimensionReduced = false;
    if numDimensions == 2 && any(dataSize==1)
        isDimensionReduced = true;
        numDimensions = 1;
        dataSizeOrig = dataSize;
        dataSize(dataSize==1) = [];
    end

    % Extract chunk dimensions configuration
    chunkDimensionsConstraints = chunkingConfig.strategy_by_rank;
    
    rankFieldName = sprintf('x%d', numDimensions); % Adjust for quirk in MATLAB where fieldname of numeric value is prepended with "x" when reading from json 
    if ~isfield(chunkDimensionsConstraints, rankFieldName)
        error("NWB:ComputeChunkSizeFromConfig:MatchingRankNotFound")
    end

    chunkDimensionsConstraint = chunkDimensionsConstraints.(rankFieldName);


    % if isnumeric(chunkDimensionsConstraints)
    %     chunkDimensionsConstraints = arrayfun(@(x) x, chunkDimensionsConstraints, 'UniformOutput', false);
    % elseif ~iscell(chunkDimensionsConstraints) && ischar(chunkDimensionsConstraints)
    %     chunkDimensionsConstraints = {chunkDimensionsConstraints};
    % end

    defaultChunkSize = chunkingConfig.target_chunk_size; % in bytes
    %dataByteSize = io.config.internal.getDataByteSize(A);

    elementSize = io.config.internal.getDataByteSize(A) / numel(A); % bytes per element

    % Determine the target number of elements per chunk.
    targetNumElements = defaultChunkSize / elementSize;

    % Initialize chunk size array
    chunkSize = zeros(1, numDimensions);
    flexDims = false(1, numDimensions);

    assert(iscell(chunkDimensionsConstraint), "Something unexpected happened")

    isFlex = @(x) ischar(x) && strcmp(x, 'flex');
    isMax = @(x) ischar(x) && strcmp(x, 'max');

    % Calculate chunk size for each dimension
    for dim = 1:numDimensions
        if dim > numel(chunkDimensionsConstraint)
            % Use full size for dimensions beyond the specification
            chunkSize(dim) = dataSize(dim);
        else
            dimSpec = chunkDimensionsConstraint{dim};
            if isFlex(dimSpec)
                flexDims(dim) = true;
                % Leave chunkSize(dim) to be determined.
            elseif isnumeric(dimSpec)
                chunkSize(dim) = min( [dimSpec, dataSize(dim)] ) ; % dimSpec is upper bound
            elseif isMax(dimSpec)
                chunkSize(dim) = dataSize(dim);
            else
                error('Invalid chunk specification for dimension %d.', dim);
            end
        end
    end

    % Compute the product of fixed dimensions (number of elements per chunk).
    if any(~flexDims)
        fixedProduct = prod(chunkSize(~flexDims));
    else
        fixedProduct = 1;
    end

    % For flex dimensions, compute the remaining number of elements
    % and allocate them equally in the exponent space.
    nFlex = sum(flexDims);
    if nFlex > 0
        remainingElements = targetNumElements / fixedProduct;
        % Ensure remainingElements is at least 1.
        remainingElements = max(remainingElements, 1);
        % Compute an equal allocation factor for each flex dimension.
        elementsPerFlexDimension = nthroot(remainingElements, nFlex);
        % Assign computed chunk size for each flex dimension.
        for dim = find(flexDims)
            proposedSize = max(1, round(elementsPerFlexDimension));
            % Do not exceed the full dimension size.
            chunkSize(dim) = min(proposedSize, dataSize(dim));
        end
    end

    % Ensure chunk size does not exceed dataset dimensions
    %chunkSize = fliplr(chunkSize);
    chunkSize = min(chunkSize, dataSize);

    if isDimensionReduced
        dataSizeOrig(dataSizeOrig~=1)=chunkSize;
        chunkSize = dataSizeOrig;
    end
end
