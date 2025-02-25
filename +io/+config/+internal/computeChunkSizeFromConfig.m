function chunkSize = computeChunkSizeFromConfig(A, datasetConfig)
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
%       chunkSize - A vector specifying the chunk size for each dimension.

    arguments
        A {mustBeNumeric}
        datasetConfig (1,1) struct
    end
    
    assert(isfield(datasetConfig, 'chunk_dimensions'), ...
        'Expected datasetConfig to have field "chunk_dimensions"')
    assert(isfield(datasetConfig, 'target_chunk_size'), ...
        'Expected datasetConfig to have field "target_chunk_size"')

    % Get dataset size
    dataSize = size(A);
    dataSize = fliplr(dataSize);  % matnwb quirk
    numDimensions = numel(dataSize);
    
    % Extract chunk dimensions configuration
    chunkDimensions = datasetConfig.chunk_dimensions;
    if ~iscell(chunkDimensions) 
        if isscalar(chunkDimensions)
            chunkDimensions = {chunkDimensions};
        else
            error('Unexpected chunk_dimensions format.');
        end
    end

    % Find the chunk dimensions specification matching the number of
    % dimensions of the input array A
    numChunkDimensions = cellfun(@numel, chunkDimensions);
    if any(ismember(numChunkDimensions, numDimensions))
        chunkDimensions = chunkDimensions{numChunkDimensions == numDimensions};
    elseif all(numDimensions > numChunkDimensions)
        chunkDimensions = chunkDimensions{end};
    else
        error('NWB:UnexpectedError', 'Unexpected chunk dimension size.')
    end

    if ~iscell(chunkDimensions)
        chunkDimensions = arrayfun(@(x) x, chunkDimensions, 'UniformOutput', false);
    end

    defaultChunkSize = datasetConfig.target_chunk_size.value; % in bytes
    dataByteSize = io.config.internal.getDataByteSize(A);

    elementSize = io.config.internal.getDataByteSize(A) / numel(A); % bytes per element

    % Determine the target number of elements per chunk.
    targetNumElements = defaultChunkSize / elementSize;

    % Initialize chunk size array
    chunkSize = zeros(1, numDimensions);
    flexDims = false(1, numDimensions);

    assert(iscell(chunkDimensions), "Something unexpected happened")

    isFlex = @(x) ischar(x) && strcmp(x, 'flex');
    isMax = @(x) ischar(x) && strcmp(x, 'max');

    % Calculate chunk size for each dimension
    for dim = 1:numDimensions
        if dim > numel(chunkDimensions)
            % Use full size for dimensions beyond the specification
            chunkSize(dim) = dataSize(dim);
        else
            dimSpec = chunkDimensions{dim};
            if isFlex(dimSpec)
                flexDims(dim) = true;
                % Leave chunkSize(dim) to be determined.
            elseif isnumeric(dimSpec)
                chunkSize(dim) = dimSpec;
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
    chunkSize = fliplr(chunkSize);
    chunkSize = min(chunkSize, dataSize);
end
