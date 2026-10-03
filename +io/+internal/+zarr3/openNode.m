function node = openNode(location, nodePath)
% openNode - Open a node of a Zarr v3 store held locally or on a web server.
%
% node = openNode(location) opens the root of the store at location, a path
% to a store directory or an http(s) URL of a store. node = openNode(location,
% nodePath) opens the node at nodePath within that store.
%
% zarr.open treats any text as a local path, so a URL is wrapped in a
% zarr.stores.HttpStore first. A store read over HTTP cannot be listed, so
% browsing its hierarchy relies on the consolidated metadata hdmf-zarr writes.

    arguments
        location (1,1) string
        nodePath (1,1) string = ""
    end

    if matnwb.common.isUrl(location)
        store = zarr.stores.HttpStore(location);
    else
        store = location;
    end
    node = zarr.open(store, Path=nodePath);
end
