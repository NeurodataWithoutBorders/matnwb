function node = openNode(location, nodePath)
% openNode - Open a node of a Zarr v3 store held locally or on a web server.
%
% node = openNode(location) opens the root of the store at location, a path
% to a store directory or an http(s) URL of a store. node = openNode(location,
% nodePath) opens the node at nodePath within that store.
%
% A store read over HTTP cannot be listed, so browsing its hierarchy relies on
% the consolidated metadata hdmf-zarr writes.

    arguments
        location (1,1) string
        nodePath (1,1) string = ""
    end

    node = zarr.open(io.internal.zarr3.createStore(location), Path=nodePath);
end
