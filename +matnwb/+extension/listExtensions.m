function extensionTable = listExtensions(options)
    arguments
        options.Refresh (1,1) logical = false
    end

    persistent extensionRecords

    if isempty(extensionRecords) || options.Refresh
        catalogUrl = "https://raw.githubusercontent.com/nwb-extensions/nwb-extensions.github.io/refs/heads/main/data/records.json";
        extensionRecords = jsondecode(webread(catalogUrl));
        extensionRecords = consolidateStruct(extensionRecords);
                    
        extensionRecords = struct2table(extensionRecords);

        fieldsKeep = ["name", "version", "last_updated", "src", "license", "maintainers", "readme"];
        extensionRecords = extensionRecords(:, fieldsKeep);
    
        for name = fieldsKeep
            if ischar(extensionRecords.(name){1})
                extensionRecords.(name) = string(extensionRecords.(name));
            end
        end
    end
    extensionTable = extensionRecords;
end

function structArray = consolidateStruct(S)
    % Get all field names of S
    mainFields = fieldnames(S);
    
    % Initialize an empty struct array
    structArray = struct();
    
    % Iterate over each field of S
    for i = 1:numel(mainFields)
        subStruct = S.(mainFields{i}); % Extract sub-struct
        
        % Add all fields of the sub-struct to the struct array
        fields = fieldnames(subStruct);
        for j = 1:numel(fields)
            structArray(i).(fields{j}) = subStruct.(fields{j});
        end
    end
    
    % Ensure consistency by filling missing fields with []
    allFields = unique([fieldnames(structArray)]);
    for i = 1:numel(structArray)
        missingFields = setdiff(allFields, fieldnames(structArray(i)));
        for j = 1:numel(missingFields)
            structArray(i).(missingFields{j}) = [];
        end
    end
end
