function validateNumTimepoints(typeObj)
    
    if isa(typeObj, 'types.core.ImageSeries') && ~isempty(typeObj.external_file)
        return
    end

    if ~isempty(typeObj.data) && ~isempty(typeObj.timestamps)
        if isa(typeObj.timestamps, 'types.untyped.DataPipe')
            numTimepoints = prod(size(typeObj.timestamps)); %#ok<PSIZE>
        else
            numTimepoints = numel(typeObj.timestamps);
        end
        dataSize = size(typeObj.data);
        if numel(dataSize) == 2 && any(dataSize == 1)
            dataSize = max(dataSize);
        end

        if ~isequal(numTimepoints, dataSize(end))
            ME = MException('NWB:Type:InvalidTime', ...
                ['Expected number of timestamps (%d) to match the length ', ...
                'of the last data dimension (%d).'], numTimepoints, dataSize(end));
            throwAsCaller(ME)
        end
    end
end
