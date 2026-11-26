function store = createStore(location)
% createStore - The zarr-matlab store for a Zarr v3 store held locally or on a web server.
%
% store = createStore(location) returns a zarr.stores.HttpStore for an
% http(s) URL and a zarr.stores.LocalStore for a path to a store directory.
% zarr.open treats any text as a local path, so a URL has to be wrapped in an
% HttpStore before it is opened.

    arguments
        location (1,1) string
    end

    if matnwb.common.isUrl(location)
        store = zarr.stores.HttpStore(location);
    else
        store = zarr.stores.LocalStore(location);
    end
end
