function datasetConfiguration = flipChunkDimensions(datasetConfiguration)
%FLIPCHUNKDIMENSIONS Reverses (flips left-right) the chunk dimension arrays 
%   in a structure.
%
%   sOut = flipChunkDimensions(sIn) locates the strategy_by_rank
%   substructure in a structure and flips the array for each rank field.
%
%   This is needed because MatNWB dimensions are flipped upon export to the
%   h5 file and the specification is defined based on the dimension
%   ordering in schema / h5

    fields = fieldnames(datasetConfiguration);
    for i = 1:length(fields)
        fieldName = fields{i};
        if strcmp(fieldName, 'strategy_by_rank')
            % Process the chunk_dimensions field
            datasetConfiguration.(fieldName) = ...
                processChunkDimensions(datasetConfiguration.(fieldName));
        else
            % Otherwise, recursively process the field
            datasetConfiguration.(fieldName) = ...
                io.config.internal.flipChunkDimensions(datasetConfiguration.(fieldName));
        end
    end
end

function cd = processChunkDimensions(cd)
    % Process the chunk_dimensions field.
    rankFieldNames = fieldnames(cd);

    for i = 1:numel(rankFieldNames)
        thisRank = rankFieldNames{i};
        cd.(thisRank) = flipud(cd.(thisRank));
    end
end
