function tf = isCatalogExtension(extensionNames)
% isCatalogExtension - Check whether extensions are in the extension catalog.
%
%   tf = matnwb.extension.internal.isCatalogExtension(extensionNames)
%   returns a logical array that is true for each name in extensionNames
%   that is an extension in the Neurodata Extensions Catalog.
%
%   matnwb.extension.CatalogExtension lists the catalog as of the last
%   update of matnwb. An extension added to the catalog since then is
%   found in the online catalog, which is read only when CatalogExtension
%   lacks a name.

    arguments
        extensionNames string
    end

    tf = ismember(extensionNames, matnwb.extension.CatalogExtension.listNames());
    if ~all(tf)
        onlineCatalog = matnwb.extension.listExtensions();
        tf = ismember(extensionNames, onlineCatalog.name);
    end
end
