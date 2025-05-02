function configuration = flipChunkDimensions(configuration)
%FLIPCHUNKDIMENSIONS Reverses (flips left-right) the chunk dimension arrays 
%   in a structure.
%
%   configuration = flipChunkDimensions(configuration) locates the 
%   strategy_by_rank substructure in a configuration structure and flips the 
%   array for each rank field.
%
%   This is needed because MatNWB dimensions are flipped upon export to
%   hdf5 files and the specification is defined based on the dimension
%   ordering in NWB schemas / hdf5

    if isstruct(configuration)
        fields = fieldnames(configuration);
        for i = 1:length(fields)
            fieldName = fields{i};
            if strcmp(fieldName, 'strategy_by_rank')
                % Process the chunk_dimensions field
                configuration.(fieldName) = ...
                    processChunkDimensions(configuration.(fieldName));
            else
                % Otherwise, recursively process the field
                configuration.(fieldName) = ...
                    io.config.internal.flipChunkDimensions(configuration.(fieldName));
            end
        end
    else
        % Pass
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
