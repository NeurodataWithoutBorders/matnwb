function extensionTable = listExtensions(options)
% listExtensions - List available extensions in the Neurodata Extension Catalog
%
% Syntax:
%  extensionTable = matnwb.extension.LISTEXTENSIONS() returns a table where
%  each row holds information about a registered extension.
%
% Output Arguments:  
%  - extensionTable (table) - 
%    Table of metadata / information for each registered extension. The table 
%    has the following columns:
%  
%    - name - The name of the extension.
%    - version - The current version of the extension.
%    - last_updated - A timestamp indicating when the extension was last updated.
%    - src - The URL to the source repository or homepage of the extension.
%    - license - The license type under which the extension is distributed.
%    - maintainers - A cell array or array of strings listing the maintainers.
%    - readme - A string containing the README documentation or description.
%
% Usage:
%  Example 1 - List and display extensions::
% 
%    T = matnwb.extension.listExtensions();
%    disp(T)
%
% See also: 
%   matnwb.extension.getExtensionInfo

    arguments
        % Refresh - Flag to refresh the catalog (Only relevant if the
        % remote catalog has been updated).
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
