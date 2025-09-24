function unwrapped = unwrapValue(wrapped, history)
    if nargin < 2
        history = {};
    end
    for iHistory = 1:length(history)
        assert(wrapped ~= history{iHistory}, ...
            'NWB:UnwrapValue:InfiniteLoop' ...
            , ['Infinite loop of a previously defined wrapped value detected. ' ...
            'Please ensure infinite loops do not occur with reference types like Links.']);
    end
    if isa(wrapped, 'types.untyped.DataStub')
        %grab first element and check
        if any(wrapped.dims == 0)
            unwrapped = [];
        else
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
