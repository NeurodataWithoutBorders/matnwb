function MatlabObj = schema2matlab(Yaml)
% YAML2MATLAB given yaml object, convert to MATLAB types
MatlabObj = java2matlab(Yaml);
end

function MatlabObj = java2matlab(JavaObj)
if isa(JavaObj, 'java.util.LinkedHashMap')
    MatlabObj = hashMap2ContainersMap(JavaObj);
elseif isa(JavaObj, 'java.util.ArrayList')
    MatlabObj = array2Cell(JavaObj);
elseif any(strcmp(JavaObj, {'null', 'NaN'}))
    MatlabObj = NaN; % this translates to null in jsonencode
elseif strcmp(JavaObj, 'true')
    MatlabObj = true;
elseif strcmp(JavaObj, 'false')
    MatlabObj = false;
elseif ~isnan(str2double(JavaObj))
    MatlabObj = str2double(JavaObj);
else
    MatlabObj = JavaObj;
end
end

function Map = hashMap2ContainersMap(HashMap)
entries = HashMap.entrySet();
entriesIterator = entries.iterator();
Map = containers.Map;
for iKey = 1:entries.size()
    entry = entriesIterator.next();
    Map(char(entry.getKey())) = java2matlab(entry.getValue());
end
end

function Cell = array2Cell(Array)
arrayIterator = Array.iterator();
Cell = cell(Array.length, 1);
for iElem=1:Array.size()
   Cell{iElem} = java2matlab(arrayIterator.next());
end
end

