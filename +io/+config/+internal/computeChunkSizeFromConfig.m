function chunkSize = computeChunkSizeFromConfig(A, datasetConfig)
% computeChunkSizeFromConfig - Compute the chunk size for a dataset using the provided configuration.
%   This function determines the chunk size for a dataset based on the chunk
%   dimensions provided in the datasetConfig structure. It adjusts dimensions 
%   according to rules: 'max' uses the dataset size, fixed numbers use their 
%   value, and 'null' calculates the dimension size to approximate the target 
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
    
    % Extract relevant configuration parameters
    chunkDimensions = datasetConfig.chunk_dimensions;
    if iscell(chunkDimensions)
        numChunkDimensions = cellfun(@numel, chunkDimensions);
        chunkDimensions = chunkDimensions{numChunkDimensions == numDimensions};
    end

    defaultChunkSize = datasetConfig.target_chunk_size.value; % in bytes
    dataByteSize = io.config.internal.getDataByteSize(A);

    % Initialize chunk size array
    chunkSize = zeros(1, numDimensions);

    % Calculate chunk size for each dimension
    for dim = 1:numDimensions
        if dim > numel(chunkDimensions)
            % Use full size for dimensions beyond the specification
            chunkSize(dim) = dataSize(dim);
        else
            dimSpec = chunkDimensions{dim};
            if isempty(dimSpec)
                % Compute chunk size for 'null' dimensions
                % Estimate proportional size based on remaining chunk size
                remainingChunkSize = defaultChunkSize / dataByteSize; % scale factor for all dimensions
                nullDimensions = find(cellfun(@isempty, chunkDimensions));
                proportionalSize = nthroot(remainingChunkSize, numel(nullDimensions));
                chunkSize(dim) = max(1, round(proportionalSize*dataSize(dim)));
            elseif isnumeric(dimSpec)
                % Fixed chunk size
                chunkSize(dim) = dimSpec;
            elseif ischar(dimSpec) && strcmp(dimSpec, 'max')
                % Use full dimension size
                chunkSize(dim) = dataSize(dim);
            else
                error('Invalid chunk specification for dimension %d.', dim);
            end
        end
    end

    % Ensure chunk size does not exceed dataset dimensions
    chunkSize = min(chunkSize, dataSize);
    chunkSize = fliplr(chunkSize);
end
