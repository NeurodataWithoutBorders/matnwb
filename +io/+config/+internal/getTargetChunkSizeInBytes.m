function targetSizeInBytes = getTargetChunkSizeInBytes(chunkConfig)
% getTargetChunkSizeInBytes - Get target size in bytes from the chunking configuration
%
% This function converts the target chunk size from the specified unit to bytes.
% Supported units:
%   - bytes: No conversion needed
%   - kiB: 1 kiB = 2^10 bytes = 1,024 bytes
%   - MiB: 1 MiB = 2^20 bytes = 1,048,576 bytes
%   - GiB: 1 GiB = 2^30 bytes = 1,073,741,824 bytes
%
% Input Arguments:
%  - chunkConfig (struct) - 
%    The chunking configuration containing target_chunk_size and 
%    target_chunk_size_unit
%
% Output Arguments:
%  - targetSizeInBytes (double) - 
%    The target size converted to bytes

    arguments
        chunkConfig (1,1) struct ...
            {matnwb.common.mustHaveField(chunkConfig, "strategy_by_rank", "target_chunk_size", "target_chunk_size_unit")}
    end

    % Extract target size and unit from the configuration
    targetSize = chunkConfig.target_chunk_size;
    targetUnit = chunkConfig.target_chunk_size_unit;
    
    % Convert to bytes based on the unit
    switch targetUnit
        case 'bytes'
            targetSizeInBytes = targetSize;
        case 'kiB'
            targetSizeInBytes = targetSize * 2^10; % 1 kiB = 2^10 bytes
        case 'MiB'
            targetSizeInBytes = targetSize * 2^20; % 1 MiB = 2^20 bytes
        case 'GiB'
            targetSizeInBytes = targetSize * 2^30; % 1 GiB = 2^30 bytes
        otherwise
            error('Unsupported target_chunk_size_unit: %s', targetUnit);
    end
end
