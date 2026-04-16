function configuration = flipChunkDimensions(configuration)
%FLIPCHUNKDIMENSIONS Reverses (flips up-down) the chunk dimension arrays
%   in a configuration structure, when operating in matlab_style mode.
%
%   configuration = flipChunkDimensions(configuration) locates the
%   strategy_by_rank substructure in a configuration structure and, when
%   the active dimension ordering preference is matlab_style, flips the
%   chunk dimension array for each rank field.
%
%   Flipping is needed in matlab_style mode because matnwb dimensions are
%   reversed upon export to HDF5, while the configuration JSON specifies
%   chunk dimensions in NWB schema / HDF5 order. In schema_style mode the
%   configuration arrays already match the user-facing order, so no flip
%   is applied.

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
    if ~matnwb.preference.shouldFlipDimensions()
        return
    end
    rankFieldNames = fieldnames(cd);
    for i = 1:numel(rankFieldNames)
        thisRank = rankFieldNames{i};
        cd.(thisRank) = flipud(cd.(thisRank));
    end
end
