function keys = extractZarrMetadataKeys(zarrFile)
% extractZarrMetadataKeys Extract top-level keys from the "metadata" property
% of a Zarr consolidated metadata JSON file, preserving original names.
%
%   keys = extractZarrMetadataKeys(zarrFile)
%
%   Input
%   -----
%   jsonFile : string or char
%       Path to the Zarr consolidated metadata JSON file (typically .zmetadata).
%
%   Output
%   ------
%   keys : cell array of char
%       Top-level keys from the "metadata" section.

    jsonFile = fullfile(zarrFile, '.zmetadata');
    if ~isfile(jsonFile)
        error("MATLAB:zarrinfo:missingZmetadata",...
            "No .zmetadata file found in %s. Use zarrconsolidate() first.", zarrFile);
    end

    % Read file as string
    txt = fileread(jsonFile);

    % Locate "metadata" block
    metaStart = regexp(txt, '"metadata"\s*:\s*\{', 'end');
    if isempty(metaStart)
        error('No "metadata" section found in JSON file.');
    end

    % Find the matching closing brace for metadata
    count = 1; 
    i = metaStart + 1;
    while count > 0 && i <= length(txt)
        if txt(i) == '{'
            count = count + 1;
        elseif txt(i) == '}'
            count = count - 1;
        end
        i = i + 1;
    end
    metaBlock = txt(metaStart+1 : i-2);

    % --- Extract only top-level keys ---
    keys = {};
    level = 0;
    tokenExpr = '"([^"]+)"\s*:';
    [startIdx, endIdx, ~, matches] = regexp(metaBlock, tokenExpr, 'start', 'end', 'match', 'tokens');

    for k = 1:numel(startIdx)
        % Count braces up to the key
        subStr = metaBlock(1:startIdx(k));
        opens  = countchars(subStr, '{');
        closes = countchars(subStr, '}');
        level  = opens - closes;

        if level == 0  % only keep keys directly under metadata
            keys{end+1} = matches{k}{1}; %#ok<AGROW>
        end
    end
end

function n = countchars(str, ch)
    % helper: count occurrences of character ch in string
    n = sum(str == ch);
end
