function processed = getSourceInfo(classmap)
%given containers.Map of (file/module)->(string) returns (file/module)->HashMap
% representing the schema file.
processed = containers.Map;
schema = Schema();
classkeys = keys(classmap);

for i=1:length(classkeys)
    ck = classkeys{i};
    cval = classmap(ck);
    try
        processed(ck) = schema.read(cval);
    catch ME
        error('MATNWB:INVALIDFILE',...
            'Data for namespace source `%s` is invalid', ck);
    end
end
