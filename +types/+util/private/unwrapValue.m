function unwrapped = unwrapValue(wrapped, history)
    if nargin < 2
        history = {};
    end
    for iHistory = 1:length(history)
        assert(wrapped ~= history{iHistory}, ...
            'NWB:UnwrapValue:InfiniteLoop', ...
            ['Infinite loop of a previously defined wrapped value detected. ' ...
            'Please ensure infinite loops do not occur with reference types like Links.']);
    end
    if isa(wrapped, 'types.untyped.DataStub')
        if any(wrapped.dims == 0)
            unwrapped = [];
        elseif isNumericOrLogicalType(wrapped.dataType)
            % Validating a numeric or logical value depends only on its
            % class, which the stub records.
            unwrapped = cast([], wrapped.dataType);
        else
            % Validating text can depend on the value, so check a sample.
            unwrapped = wrapped.load(1);
        end
    elseif isa(wrapped, 'types.untyped.DataPipe')
        unwrapped = cast([], wrapped.dataType);
    elseif isa(wrapped, 'types.untyped.Anon')
        history{end+1} = wrapped;
        unwrapped = unwrapValue(wrapped.value, history);
    elseif isa(wrapped, 'types.untyped.ExternalLink')
        history{end+1} = wrapped;
        unwrapped = unwrapValue(wrapped.deref(), history);
    else
        unwrapped = wrapped;
    end
end

function tf = isNumericOrLogicalType(dataType)
    numericOrLogicalTypes = ["single", "double", "int8", "uint8", "int16", ...
        "uint16", "int32", "uint32", "int64", "uint64", "logical"];
    tf = ischar(dataType) && any(strcmp(dataType, numericOrLogicalTypes));
end
