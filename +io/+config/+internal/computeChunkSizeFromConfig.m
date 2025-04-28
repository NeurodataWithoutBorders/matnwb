function chunkSize = computeChunkSizeFromConfig(A, configuration)
% computeChunkSizeFromConfig - Compute the chunk size for a dataset using the provided configuration.
%   This function determines the chunk size for a dataset based on the chunk
%   constraints/strategies provided in the configuration structure. It adjusts
%   dimensions according to rules: 'max' uses the dataset size, fixed numbers 
%   use their value, and 'flex' calculates the dimension size to approximate the 
%   target chunk size in bytes.
%
%   Inputs:
%       A - A numeric dataset whose chunk size is to be computed.
%       configuration (1,1) struct - Struct defining chunking strategy for
%       different ranks of a dataset. 
%
%   Output:
%       chunkSize - A vector specifying the chunk size for each dimension of A.

    arguments
        A {mustBeNumeric}
        configuration (1,1) struct ...
            {matnwb.common.mustHaveField(configuration, "strategy_by_rank", "target_chunk_size", "target_chunk_size_unit")}
    end

    % Get dataset size
    dataSize = size(A);
    numDimensions = numel(dataSize);

    % NWB / H5 supports true 1D vectors. If the data is a vector, represent
    % dataSize as a scalar for computation of chunkSize.
    if numDimensions == 2 && any(dataSize==1)
        numDimensions = 1;
        originalDataSize = dataSize;
        dataSize(dataSize==1) = [];
    end

    % Retrieve constraints for current rank.
    strategy = configuration.strategy_by_rank;
    rankFieldName = sprintf('x%d', numDimensions); % Adjust for quirk in MATLAB where fieldname of numeric value is prepended with "x" when reading from json 
    if ~isfield(strategy, rankFieldName)
        error('NWB:ComputeChunkSizeFromConfig:MatchingRankNotFound', ...
              'Configuration for %d dimensions is missing.', numDimensions)
    end
    constraints = strategy.(rankFieldName);
    assert(iscell(constraints), ...
        'Expected constraints for dimensions to be provided as a cell array, got %s.', class(constraints))

    % Determine the target number of array elements per chunk.
    targetChunkSizeBytes = io.config.internal.getTargetChunkSizeInBytes(configuration);
    elementSizeBytes = io.config.internal.getDataByteSize(A) / numel(A); % bytes per element
    targetNumElements = targetChunkSizeBytes / elementSizeBytes; % Per chunk

    % Preallocate arrays.
    chunkSize = zeros(1, numDimensions);
    isFlexDim = false(1, numDimensions);

    isFlex = @(x) ischar(x) && strcmp(x, 'flex');
    isMax = @(x) ischar(x) && strcmp(x, 'max');

    % Calculate chunk size for each dimension
    for dim = 1:numDimensions
        if dim > numel(constraints)
            % Use full size for dimensions beyond the specification
            chunkSize(dim) = dataSize(dim);
        else
            thisDimensionConstraint = constraints{dim};
            if isFlex(thisDimensionConstraint)
                isFlexDim(dim) = true;
                % Leave chunkSize(dim) to be determined.
            elseif isMax(thisDimensionConstraint)
                chunkSize(dim) = dataSize(dim);
            elseif isnumeric(thisDimensionConstraint)
                chunkSize(dim) = min([thisDimensionConstraint, dataSize(dim)]);
                % thisDimensionConstraint is upper bound
            else
                error('NWB:ComputeChunkSizeFromConfig:InvalidConstraint', ...
                    'Invalid chunk constraint for dimension %d.', dim);
            end
        end
    end

    % Compute the product of fixed dimensions (number of elements per chunk).
    if any(~isFlexDim)
        fixedProduct = prod(chunkSize(~isFlexDim));
    else
        fixedProduct = 1;
    end

    % For flex dimensions, compute the remaining number of elements
    % and allocate them equally in the exponent space.
    nFlex = sum(isFlexDim);
    if nFlex > 0
        remainingElements = targetNumElements / fixedProduct;
        % Ensure remainingElements is at least 1.
        remainingElements = max(remainingElements, 1);
        % Compute an equal allocation factor for each flex dimension.
        elementsPerFlexDimension = nthroot(remainingElements, nFlex);
        % Assign computed chunk size for each flex dimension.
        for dim = find(isFlexDim)
            proposedSize = max(1, round(elementsPerFlexDimension));
            % Do not exceed the full dimension size.
            chunkSize(dim) = min(proposedSize, dataSize(dim));
        end
    end

    % Ensure chunk size does not exceed dataset size in any dimension
    chunkSize = min(chunkSize, dataSize);

    if numDimensions == 1
        originalDataSize(originalDataSize~=1) = chunkSize;
        chunkSize = originalDataSize;
    end

    actualBytesPerChunk = prod(chunkSize) * elementSizeBytes;
    if actualBytesPerChunk > targetChunkSizeBytes
        warning('NWB:ComputeChunkSizeFromConfig:TargetSizeExceeded', ...
            ['The provided dataset configuration produces chunks that have a ', ...
            'larger bytesize than the specified target chunk size.'])
    end
end
