function installAll()
    T = matnwb.extension.listExtensions();
    for i = 1:height(T)
        matnwb.extension.installExtension( T.name(i) )
    end
end
