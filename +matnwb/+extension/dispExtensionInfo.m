function dispExtensionInfo(extensionName)
    arguments
        extensionName (1,1) string
    end

    T = matnwb.extension.listExtensions();
    isMatch = T.name == extensionName;
    extensionList = join( compose("  %s", [T.name]), newline );
    assert( ...
        any(isMatch), ...
        'NWB:DisplayExtensionMetadata:ExtensionNotFound', ...
        'Extension "%s" was not found in the extension catalog:\n%s', extensionName, extensionList)
    metadata = table2struct(T(isMatch, :));
    disp(metadata)
end
