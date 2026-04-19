function rstText = convertTutorialMCodeToRst(mCodeFilePath)
% convertTutorialMCodeToRst - Convert exported tutorial m-code to reStructuredText

    arguments
        mCodeFilePath (1,1) string {mustBeFile}
    end

    sourceLines = string(splitlines(fileread(mCodeFilePath)));

    rstLines = strings(0, 1);
    commentLines = strings(0, 1);
    codeLines = strings(0, 1);

    inBlockCommentCode = false;
    isFirstHeading = true;
    for i = 1:numel(sourceLines)
        thisLine = sourceLines(i);
        trimmedLine = strtrim(thisLine);

        if inBlockCommentCode
            if trimmedLine == "%}"
                rstLines = appendBlock(rstLines, renderCodeBlock(codeLines));
                codeLines = strings(0, 1);
                inBlockCommentCode = false;
            else
                codeLines(end+1, 1) = thisLine;
            end
            continue
        end

        if startsWith(trimmedLine, "%%")
            rstLines = appendBlock(rstLines, renderCommentBlock(commentLines));
            rstLines = appendBlock(rstLines, renderCodeBlock(codeLines));
            commentLines = strings(0, 1);
            codeLines = strings(0, 1);

            headingText = strtrim(extractAfter(trimmedLine, 2));
            if headingText == ""
                continue
            end

            if isFirstHeading
                isFirstHeading = false;
                continue
            end

            headingText = normalizeInlineMarkup(headingText);
            rstLines = appendBlock(rstLines, [ ...
                headingText
                string(repmat('-', 1, strlength(headingText))) ...
            ]);
            continue
        end

        if trimmedLine == "%{"
            rstLines = appendBlock(rstLines, renderCommentBlock(commentLines));
            rstLines = appendBlock(rstLines, renderCodeBlock(codeLines));
            commentLines = strings(0, 1);
            codeLines = strings(0, 1);
            inBlockCommentCode = true;
            continue
        end

        if trimmedLine == ""
            if ~isempty(codeLines)
                codeLines(end+1, 1) = "";
            elseif ~isempty(commentLines)
                commentLines(end+1, 1) = "";
            end
        elseif startsWith(trimmedLine, "%")
            if shouldKeepCommentAsCode(sourceLines, i)
                rstLines = appendBlock(rstLines, renderCommentBlock(commentLines));
                commentLines = strings(0, 1);
                codeLines(end+1, 1) = thisLine;
            else
                rstLines = appendBlock(rstLines, renderCodeBlock(codeLines));
                codeLines = strings(0, 1);
                commentLines(end+1, 1) = extractCommentText(thisLine);
            end
        else
            rstLines = appendBlock(rstLines, renderCommentBlock(commentLines));
            commentLines = strings(0, 1);
            codeLines(end+1, 1) = thisLine;
        end
    end

    rstLines = appendBlock(rstLines, renderCommentBlock(commentLines));
    rstLines = appendBlock(rstLines, renderCodeBlock(codeLines));
    rstLines = trimBlankLines(rstLines);

    rstText = join(rstLines, newline);
end

function rstLines = renderCommentBlock(commentLines)
    commentLines = trimBlankLines(commentLines);
    if isempty(commentLines)
        rstLines = strings(0, 1);
        return
    end

    rstLines = strings(0, 1);
    numLines = numel(commentLines);
    i = 1;

    while i <= numLines
        currentLine = strtrim(commentLines(i));

        if currentLine == ""
            if ~isempty(rstLines) && rstLines(end) ~= ""
                rstLines(end+1, 1) = "";
            end
            i = i + 1;
            continue
        end

        if currentLine == "<html>"
            [htmlTableLines, nextIndex] = renderHtmlTable(commentLines, i);
            rstLines = appendBlock(rstLines, htmlTableLines);
            i = nextIndex;
            continue
        end

        if isMetadataLine(currentLine)
            rstLines(end+1, 1) = renderMetadataLine(currentLine);
            i = i + 1;
            continue
        end

        [isListItem, listMarker, itemText] = parseListItem(currentLine);
        if isListItem
            j = i + 1;
            while j <= numLines
                nextLine = strtrim(commentLines(j));
                if nextLine == "" || isListItemLine(nextLine)
                    break
                end
                itemText = itemText + " " + nextLine;
                j = j + 1;
            end

            rstLines(end+1, 1) = listMarker + " " + normalizeInlineMarkup(itemText);
            i = j;
            continue
        end

        paragraphText = currentLine;
        j = i + 1;
        while j <= numLines
            nextLine = strtrim(commentLines(j));
            if nextLine == "" || isListItemLine(nextLine)
                break
            end
            paragraphText = paragraphText + " " + nextLine;
            j = j + 1;
        end

        rstLines(end+1, 1) = normalizeInlineMarkup(paragraphText);
        i = j;
    end

    rstLines = trimBlankLines(rstLines);
end

function [rstLines, nextIndex] = renderHtmlTable(commentLines, startIndex)
    tableRows = strings(0, 2);
    nextIndex = startIndex + 1;

    while nextIndex <= numel(commentLines)
        currentLine = strtrim(commentLines(nextIndex));
        if currentLine == "</html>"
            nextIndex = nextIndex + 1;
            break
        end

        rowTokens = regexp(currentLine, '<tr><td>(.*?)</td><td>(.*?)</td></tr>', 'tokens', 'once');
        if ~isempty(rowTokens)
            tableRows(end+1, :) = [ ...
                cleanHtmlTableCell(string(rowTokens{1}))
                cleanHtmlTableCell(string(rowTokens{2})) ...
            ];
        end

        nextIndex = nextIndex + 1;
    end

    if isempty(tableRows)
        rstLines = strings(0, 1);
        return
    end

    rstLines = [
        ".. list-table::"
        "   :widths: 25 75"
        ""
    ];

    for i = 1:size(tableRows, 1)
        rstLines(end+1, 1) = "   * - " + normalizeInlineMarkup(tableRows(i, 1));
        rstLines(end+1, 1) = "     - " + normalizeInlineMarkup(tableRows(i, 2));
    end
end

function rstLines = renderCodeBlock(codeLines)
    codeLines = trimBlankLines(codeLines);
    if isempty(codeLines)
        rstLines = strings(0, 1);
        return
    end

    rstLines = [".. code-block:: matlab"; ""];
    for i = 1:numel(codeLines)
        thisLine = codeLines(i);
        thisLine = replace(thisLine, sprintf('\t'), '    ');
        rstLines(end+1, 1) = "   " + thisLine;
    end
end

function rstLines = appendBlock(rstLines, blockLines)
    blockLines = trimBlankLines(blockLines);
    if isempty(blockLines)
        return
    end

    if ~isempty(rstLines) && rstLines(end) ~= ""
        rstLines(end+1, 1) = "";
    end

    rstLines = [rstLines; blockLines];
end

function text = extractCommentText(lineText)
    if startsWith(lineText, "% ")
        text = extractAfter(lineText, 2);
    else
        text = extractAfter(lineText, 1);
    end
end

function text = normalizeInlineMarkup(text)
    text = strtrim(text);
    text = convertLinks(text);

    text = replace(text, "|*.*|", ".");
    text = replace(text, "|.|", ".");
    text = replace(text, "|>|", ">");
    text = replace(text, "|>|.", ">.");

    text = regexprep(text, '\|\*([^|]+)\*\|', '``$1``');
    text = regexprep(text, '\|([^|]+)\|', '``$1``');
    text = regexprep(text, '(^|[^A-Za-z0-9])_([^_\n]+?)_([^A-Za-z0-9]|$)', '$1*$2*$3');
end

function text = convertLinks(text)
    arrowPlaceholder = "CODExLeftRightArrow";
    text = replace(text, "<->", arrowPlaceholder);

    expression = '<([^ <>\n]+)\s+([^>]+)>';
    [matches, tokens] = regexp(text, expression, 'match', 'tokens');

    for i = 1:numel(matches)
        url = string(tokens{i}{1});
        label = cleanLinkLabel(string(tokens{i}{2}));
        label = replace(label, arrowPlaceholder, "<->");
        if label == ""
            label = url;
        end

        if isTutorialLink(url)
            [~, targetName] = fileparts(url);
            replacement = "`" + label + " <" + targetName + ">`_";
        else
            replacement = "`" + label + " <" + url + ">`_";
        end

        text = replace(text, matches{i}, replacement);
    end

    text = replace(text, arrowPlaceholder, "<->");
end

function tf = isTutorialLink(url)
    [~, ~, extension] = fileparts(url);
    tf = ismember(extension, [".mlx", ".m", ".rst"]);
end

function label = cleanLinkLabel(label)
    label = strtrim(label);
    label = replace(label, "|*.*|", ".");
    label = replace(label, "|.|", ".");
    label = replace(label, "|", "");
    label = regexprep(label, '^\*+', '');
    label = regexprep(label, '\*+$', '');
    label = regexprep(label, '^_+', '');
    label = regexprep(label, '_+$', '');
    label = strtrim(label);
end

function tf = isMetadataLine(lineText)
    tf = ~isempty(regexp(lineText, '^(authors?|contact|last edited|last updated):', 'once'));
end

function lineText = renderMetadataLine(lineText)
    tokens = regexp(lineText, '^([^:]+):(.*)$', 'tokens', 'once');
    label = strtrim(string(tokens{1}));
    value = strtrim(string(tokens{2}));
    label = formatMetadataLabel(label);
    lineText = "**" + label + ":** " + normalizeInlineMarkup(value);
end

function cellText = cleanHtmlTableCell(cellText)
    cellText = replace(cellText, "<em>", "|");
    cellText = replace(cellText, "</em>", "|");
    cellText = regexprep(cellText, '<[^>]+>', '');
    cellText = strtrim(cellText);
end

function label = formatMetadataLabel(label)
    words = split(lower(label), " ");
    for i = 1:numel(words)
        if words(i) == ""
            continue
        end
        words(i) = upper(extractBefore(words(i), 2)) + extractAfter(words(i), 1);
    end
    label = strjoin(words, " ");
end

function [tf, listMarker, itemText] = parseListItem(lineText)
    itemText = "";
    listMarker = "";

    if startsWith(lineText, "* ")
        tf = true;
        listMarker = "*";
        itemText = strtrim(extractAfter(lineText, 2));
        return
    end

    if startsWith(lineText, "# ")
        tf = true;
        listMarker = "1.";
        itemText = strtrim(extractAfter(lineText, 2));
        return
    end

    match = regexp(lineText, '^(\d+\.)\s+(.*)$', 'tokens', 'once');
    if isempty(match)
        tf = false;
        return
    end

    tf = true;
    listMarker = string(match{1});
    itemText = string(match{2});
end

function tf = isListItemLine(lineText)
    [tf, ~, ~] = parseListItem(lineText);
end

function tf = shouldKeepCommentAsCode(sourceLines, lineIndex)
    commentText = strtrim(extractCommentText(sourceLines(lineIndex)));
    if commentText == ""
        tf = false;
        return
    end

    tf = ~isMetadataLine(commentText) && ...
        isProbablyCodeComment(commentText) && ...
        nextNoncommentLineLooksLikeCode(sourceLines, lineIndex + 1);
end

function tf = isProbablyCodeComment(commentText)
    startsLowercase = ~isempty(regexp(commentText, '^[a-z]', 'once'));
    endsLikeSentence = ~isempty(regexp(commentText, '[\.\:\!\?]$', 'once'));
    hasSentencePunctuation = ~isempty(regexp(commentText, '[\.\,\;\:]', 'once'));
    hasManyWords = numel(split(commentText)) > 8;

    tf = startsLowercase && ~endsLikeSentence && ~hasSentencePunctuation && ~hasManyWords;
end

function tf = nextNoncommentLineLooksLikeCode(sourceLines, startIndex)
    tf = false;

    for i = startIndex:numel(sourceLines)
        trimmedLine = strtrim(sourceLines(i));
        if trimmedLine == ""
            continue
        end

        if startsWith(trimmedLine, "%")
            continue
        else
            tf = true;
        end
        return
    end
end

function lines = trimBlankLines(lines)
    if isempty(lines)
        return
    end

    while ~isempty(lines) && strtrim(lines(1)) == ""
        lines(1) = [];
    end

    while ~isempty(lines) && strtrim(lines(end)) == ""
        lines(end) = [];
    end
end
