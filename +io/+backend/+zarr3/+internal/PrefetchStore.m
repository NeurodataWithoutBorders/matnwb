classdef PrefetchStore < zarr.stores.Store
% PrefetchStore - Store wrapper that answers reads from values fetched in advance.
%
% store = PrefetchStore(innerStore) wraps a zarr-matlab store. prefetch(keys)
% fetches the given keys in one call to the inner store's getMany, which an
% HTTP store serves with concurrent requests, and keeps the values. get and
% getMany answer prefetched keys from those values and pass every other read,
% including byte-range reads, to the inner store.
%
% io.backend.zarr3.Zarr3Reader uses it to fetch, together, the small arrays
% that nwbRead reads one after another while it parses a store; over HTTP each
% of those reads is otherwise a round trip of its own.

    properties (SetAccess = immutable)
        % InnerStore - The wrapped zarr-matlab store.
        InnerStore
    end

    properties (Access = private)
        % Values - containers.Map from key to a struct with the prefetched
        % value (Data) and whether the inner store holds the key (Found).
        % Created in the constructor: a handle default would be shared by
        % every instance.
        Values
    end

    methods
        function obj = PrefetchStore(innerStore)
            obj.InnerStore = innerStore;
            obj.Values = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function prefetch(obj, keys)
        % prefetch - Fetch keys together and keep their values.
            keys = reshape(string(keys), 1, []);
            keys = keys(~isKey(obj.Values, cellstr(keys)));
            if isempty(keys)
                return
            end
            [values, found] = obj.fetchMany(keys);
            for i = 1:numel(keys)
                obj.Values(char(keys(i))) = struct("Data", values{i}, "Found", found(i));
            end
        end

        function [data, found] = get(obj, key)
            if isKey(obj.Values, char(key))
                entry = obj.Values(char(key));
                data = entry.Data;
                found = entry.Found;
                return
            end
            [data, found] = obj.InnerStore.get(key);
        end

        function [values, found] = getMany(obj, keys)
            keys = reshape(string(keys), 1, []);
            values = cell(1, numel(keys));
            found = false(1, numel(keys));
            isPrefetched = isKey(obj.Values, cellstr(keys));
            for i = find(isPrefetched)
                [values{i}, found(i)] = obj.get(keys(i));
            end
            if any(~isPrefetched)
                [values(~isPrefetched), found(~isPrefetched)] = obj.fetchMany(keys(~isPrefetched));
            end
        end

        function [data, found] = getPartial(obj, key, offset, len)
            [data, found] = obj.InnerStore.getPartial(key, offset, len);
        end

        function [data, found] = getSuffix(obj, key, len)
            [data, found] = obj.InnerStore.getSuffix(key, len);
        end

        function tf = exists(obj, key)
            tf = obj.InnerStore.exists(key);
        end

        function set(obj, key, data)
            obj.forget(key);
            obj.InnerStore.set(key, data);
        end

        function erase(obj, key)
            obj.forget(key);
            obj.InnerStore.erase(key);
        end

        function keys = list(obj)
            keys = obj.InnerStore.list();
        end

        function [subdirs, files] = listDir(obj, prefix)
            [subdirs, files] = obj.InnerStore.listDir(prefix);
        end
    end

    methods (Access = private)
        function [values, found] = fetchMany(obj, keys)
        % fetchMany - Read keys through the inner store's getMany if it has one.
        %
        % zarr-matlab releases before getMany are read one key at a time.
            if ismethod(obj.InnerStore, "getMany")
                [values, found] = obj.InnerStore.getMany(keys);
                return
            end
            values = cell(1, numel(keys));
            found = false(1, numel(keys));
            for i = 1:numel(keys)
                [values{i}, found(i)] = obj.InnerStore.get(keys(i));
            end
        end

        function forget(obj, key)
            if isKey(obj.Values, char(key))
                remove(obj.Values, char(key));
            end
        end
    end
end
