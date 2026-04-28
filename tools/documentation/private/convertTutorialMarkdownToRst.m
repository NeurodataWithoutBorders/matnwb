function rstText = convertTutorialMarkdownToRst(markdownFilePath, options)
% convertTutorialMarkdownToRst - Convert exported tutorial markdown to reStructuredText

    arguments
        markdownFilePath (1,1) string {mustBeFile}
        options.MediaRelativePath (1,1) string = ""
        options.ImageNames (1,:) string = string.empty
        options.ImageDisplayWidths (1,:) double = double.empty
    end

    markdownLines = string(splitlines(fileread(markdownFilePath)));

    rstLines = strings(0, 1);
    inTableOfContents = false;
    isFirstHeading = true;

    i = 1;
    while i <= numel(markdownLines)
        thisLine = markdownLines(i);
        trimmedLine = normalizeBlockLine(thisLine);

        if trimmedLine == '<a name="beginToc"></a>'
            inTableOfContents = true;
            i = i + 1;
            continue
        elseif trimmedLine == '<a name="endToc"></a>'
            inTableOfContents = false;
            i = i + 1;
            continue
        elseif inTableOfContents || startsWith(trimmedLine, "<a name=")
            i = i + 1;
            continue
        end

        if trimmedLine == ""
            i = i + 1;
            continue
        end

        if startsWith(trimmedLine, "```")
            [blockLines, i] = readCodeBlock(markdownLines, i);
            rstLines = appendBlock(rstLines, blockLines);
            continue
        end

        if startsWith(trimmedLine, "|")
            [blockLines, i] = readTableBlock(markdownLines, i);
            rstLines = appendBlock(rstLines, blockLines);
            continue
        end

        if isImageLine(trimmedLine)
            [blockLines, i] = readImageBlock(markdownLines, i, options);
            rstLines = appendBlock(rstLines, blockLines);
            continue
        end

        headingMatch = regexp(trimmedLine, '^(#+)\s+(.*)$', 'tokens', 'once');
        if ~isempty(headingMatch)
            headingLevel = strlength(headingMatch{1});
            headingText = normalizeInlineMarkdown(string(headingMatch{2}));
            if isFirstHeading
                isFirstHeading = false;
            else
                blockLines = [
                    headingText
                    string(repmat(getHeadingUnderline(headingLevel), 1, strlength(headingText)))
                ];
                rstLines = appendBlock(rstLines, blockLines);
            end
            i = i + 1;
            continue
        end

        if isListLine(trimmedLine)
            [blockLines, i] = readListBlock(markdownLines, i, options);
            rstLines = appendBlock(rstLines, blockLines);
            continue
        end

        [blockLines, i] = readParagraphBlock(markdownLines, i);
        rstLines = appendBlock(rstLines, blockLines);
    end

    rstLines = trimBlankLines(rstLines);
    rstText = join(rstLines, newline);
end

function blockLines = createImageDirective(imagePath, imageAltText, imageDisplayWidth)
    blockLines = ".. image:: " + imagePath;
    blockLines(end+1, 1) = "   :class: tutorial-media";
    if ~isnan(imageDisplayWidth)
        blockLines(end+1, 1) = "   :width: " + string(round(imageDisplayWidth)) + "px";
    end
    if imageAltText ~= ""
        blockLines(end+1, 1) = "   :alt: " + normalizeInlineMarkdown(imageAltText);
    end
end

function [blockLines, nextIndex] = readCodeBlock(markdownLines, startIndex)
    openingLine = normalizeBlockLine(markdownLines(startIndex));
    blockLanguage = strtrim(extractAfter(openingLine, 3));

    blockLines = [
        ".. code-block:: " + getCodeBlockLanguage(blockLanguage)
        ""
    ];

    nextIndex = startIndex + 1;
    while nextIndex <= numel(markdownLines)
        thisLine = markdownLines(nextIndex);
        if startsWith(normalizeBlockLine(thisLine), "```")
            nextIndex = nextIndex + 1;
            return
        end

        blockLines(end+1, 1) = "   " + thisLine;
        nextIndex = nextIndex + 1;
    end
end

function [blockLines, nextIndex] = readTableBlock(markdownLines, startIndex)
    tableLines = strings(0, 1);
    nextIndex = startIndex;

    while nextIndex <= numel(markdownLines)
        thisLine = normalizeBlockLine(markdownLines(nextIndex));
        if thisLine == "" || ~startsWith(thisLine, "|")
            break
        end

        tableLines(end+1, 1) = thisLine;
        nextIndex = nextIndex + 1;
    end

    if numel(tableLines) < 2
        blockLines = normalizeInlineMarkdown(tableLines);
        return
    end

    tableRows = cell(0, 1);
    for i = 1:numel(tableLines)
        if i == 2 && isMarkdownAlignmentRow(tableLines(i))
            continue
        end
        tableRows{end+1, 1} = splitTableRow(tableLines(i)); %#ok<AGROW>
    end

    blockLines = [
        ".. list-table::"
        "   :header-rows: 1"
        ""
    ];

    for i = 1:numel(tableRows)
        thisRow = tableRows{i};
        for j = 1:numel(thisRow)
            prefix = "     - ";
            if j == 1
                prefix = "   * - ";
            end
            blockLines(end+1, 1) = prefix + normalizeInlineMarkdown(thisRow(j));
        end
    end
end

function [blockLines, nextIndex] = readImageBlock(markdownLines, startIndex, options)
    blockLines = strings(0, 1);
    nextIndex = startIndex;

    while nextIndex <= numel(markdownLines)
        thisLine = normalizeBlockLine(markdownLines(nextIndex));
        if ~isImageLine(thisLine)
            break
        end

        imageTokens = regexp(thisLine, '!\[([^\]]*)\]\(([^)]+)\)', 'tokens', 'once');
        imageAltText = string(imageTokens{1});
        imagePath = resolveImagePath(string(imageTokens{2}), options.MediaRelativePath);
        imageDisplayWidth = resolveImageDisplayWidth( ...
            imagePath, options.ImageNames, options.ImageDisplayWidths);

        blockLines = [blockLines; createImageDirective(imagePath, imageAltText, imageDisplayWidth)]; %#ok<AGROW>
        blockLines(end+1, 1) = "";

        nextIndex = nextIndex + 1;
        while nextIndex <= numel(markdownLines) && normalizeBlockLine(markdownLines(nextIndex)) == ""
            nextIndex = nextIndex + 1;
        end
    end
end

function [blockLines, nextIndex] = readListBlock(markdownLines, startIndex, options)
    blockLines = strings(0, 1);
    nextIndex = startIndex;

    while nextIndex <= numel(markdownLines)
        thisLine = normalizeBlockLine(markdownLines(nextIndex));
        if ~isListLine(thisLine)
            break
        end

        tokens = regexp(thisLine, '^([-*]|\d+\.)\s+(.*)$', 'tokens', 'once');
        marker = string(tokens{1});
        itemText = string(tokens{2});
        childBlockLines = strings(0, 1);
        [itemText, inlineImageLines] = extractInlineImages(itemText, options);
        childBlockLines = [childBlockLines; inlineImageLines];

        nextIndex = nextIndex + 1;
        while nextIndex <= numel(markdownLines)
            continuationLine = normalizeBlockLine(markdownLines(nextIndex));
            if isListLine(continuationLine) || isSpecialBlockStart(continuationLine)
                break
            end

            if continuationLine == ""
                lookaheadIndex = nextIndex + 1;
                while lookaheadIndex <= numel(markdownLines) && normalizeBlockLine(markdownLines(lookaheadIndex)) == ""
                    lookaheadIndex = lookaheadIndex + 1;
                end

                if lookaheadIndex > numel(markdownLines) || isListLine(normalizeBlockLine(markdownLines(lookaheadIndex)))
                    nextIndex = lookaheadIndex;
                    break
                end

                nextBlockLine = normalizeBlockLine(markdownLines(lookaheadIndex));
                if isImageLine(nextBlockLine)
                    imageTokens = regexp(nextBlockLine, '!\[([^\]]*)\]\(([^)]+)\)', 'tokens', 'once');
                    imageAltText = string(imageTokens{1});
                    imagePath = resolveImagePath(string(imageTokens{2}), options.MediaRelativePath);
                    imageDisplayWidth = resolveImageDisplayWidth( ...
                        imagePath, options.ImageNames, options.ImageDisplayWidths);
                    childBlockLines = [childBlockLines; ""; createImageDirective(imagePath, imageAltText, imageDisplayWidth)]; %#ok<AGROW>
                    nextIndex = lookaheadIndex + 1;
                    continue
                end

                if startsWith(nextBlockLine, "```")
                    [nestedCodeBlock, lookaheadIndex] = readCodeBlock(markdownLines, lookaheadIndex);
                    childBlockLines = [childBlockLines; ""; indentBlock(nestedCodeBlock, "   ")]; %#ok<AGROW>
                    nextIndex = lookaheadIndex;
                    continue
                end

                nextIndex = lookaheadIndex;
                break
            end

            itemText = itemText + " " + continuationLine;
            nextIndex = nextIndex + 1;
        end

        [itemPrefix, itemBody] = getListMarkerPrefix(marker, itemText);
        blockLines(end+1, 1) = itemPrefix + normalizeInlineMarkdown(itemBody);
        if ~isempty(childBlockLines)
            blockLines(end+1, 1) = "";
            blockLines = [blockLines; indentBlock(trimBlankLines(childBlockLines), "   ")]; %#ok<AGROW>
        end
    end
end

function [blockLines, nextIndex] = readParagraphBlock(markdownLines, startIndex)
    paragraphParts = strings(0, 1);
    nextIndex = startIndex;

    while nextIndex <= numel(markdownLines)
        thisLine = normalizeBlockLine(markdownLines(nextIndex));
        if thisLine == "" || isSpecialBlockStart(thisLine)
            break
        end

        paragraphParts(end+1, 1) = thisLine;
        nextIndex = nextIndex + 1;
    end

    blockLines = normalizeInlineMarkdown(strjoin(paragraphParts, " "));
end

function tf = isSpecialBlockStart(lineText)
    tf = startsWith(lineText, "```") || ...
        startsWith(lineText, "|") || ...
        isImageLine(lineText) || ...
        isListLine(lineText) || ...
        ~isempty(regexp(lineText, '^(#+)\s+', 'once')) || ...
        startsWith(lineText, "<a name=");
end

function tf = isListLine(lineText)
    tf = ~isempty(regexp(lineText, '^([-*]|\d+\.)\s+', 'once'));
end

function tf = isImageLine(lineText)
    tf = ~isempty(regexp(lineText, '^!\[[^\]]*\]\(([^)]+)\)$', 'once'));
end

function tf = isMarkdownAlignmentRow(lineText)
    cells = splitTableRow(lineText);
    tf = ~isempty(cells);
    for i = 1:numel(cells)
        tf = tf && ~isempty(regexp(cells(i), '^:?-+:?$', 'once'));
    end
end

function cells = splitTableRow(lineText)
    cells = split(lineText, "|");
    if ~isempty(cells) && cells(1) == ""
        cells(1) = [];
    end
    if ~isempty(cells) && cells(end) == ""
        cells(end) = [];
    end
    cells = strtrim(cells);
end

function imagePath = resolveImagePath(imagePath, mediaRelativePath)
    imagePath = strtrim(imagePath);

    if mediaRelativePath == "" || ~contains(imagePath, "_media/")
        return
    end

    pathParts = split(imagePath, "/");
    imagePath = mediaRelativePath + "/" + pathParts(end);
end

function [text, imageBlockLines] = extractInlineImages(text, options)
    imageBlockLines = strings(0, 1);
    imagePattern = '!\[([^\]]*)\]\(([^)]+)\)';
    imageTokens = regexp(text, imagePattern, 'tokens');

    for i = 1:numel(imageTokens)
        imageAltText = string(imageTokens{i}{1});
        imagePath = resolveImagePath(string(imageTokens{i}{2}), options.MediaRelativePath);
        imageDisplayWidth = resolveImageDisplayWidth( ...
            imagePath, options.ImageNames, options.ImageDisplayWidths);
        imageBlockLines = [imageBlockLines; ""; createImageDirective(imagePath, imageAltText, imageDisplayWidth)]; %#ok<AGROW>
    end

    text = strtrim(regexprep(text, imagePattern, ''));
end

function imageDisplayWidth = resolveImageDisplayWidth(imagePath, imageNames, imageDisplayWidths)
    imageDisplayWidth = nan;
    if isempty(imageNames) || isempty(imageDisplayWidths)
        return
    end

    [~, baseName, extension] = fileparts(imagePath);
    imageName = string(baseName) + string(extension);
    matchIndex = find(imageNames == imageName, 1);
    if isempty(matchIndex)
        return
    end

    if matchIndex <= numel(imageDisplayWidths)
        imageDisplayWidth = imageDisplayWidths(matchIndex);
    end
end

function [itemPrefix, itemBody] = getListMarkerPrefix(marker, itemText)
    if endsWith(marker, ".")
        itemPrefix = marker + " ";
    else
        itemPrefix = "* ";
    end
    itemBody = itemText;
end

function language = getCodeBlockLanguage(blockLanguage)
    if blockLanguage == "matlab"
        language = "matlab";
    else
        language = "text";
    end
end

function underlineCharacter = getHeadingUnderline(headingLevel)
    if headingLevel <= 1
        underlineCharacter = '-';
    elseif headingLevel == 2
        underlineCharacter = '~';
    elseif headingLevel == 3
        underlineCharacter = '^';
    else
        underlineCharacter = '"';
    end
end

function text = normalizeInlineMarkdown(text)
    text = replace(text, "&nbsp;", " ");
    text = replace(text, "&emsp;", " ");
    text = replace(text, "\_", "_");
    text = replace(text, "\-", "-");
    text = replace(text, "\>", ">");
    text = replace(text, "\*", "*");
    text = replace(text, "\(", "(");
    text = replace(text, "\)", ")");
    text = replace(text, "\[", "[");
    text = replace(text, "\]", "]");

    text = regexprep(text, '`([^`]+)`', '``$1``');
    text = convertMarkdownLinks(text);
    text = regexprep(text, '\*\*``([^`]+)``\*\*', '``$1``');
end

function text = convertMarkdownLinks(text)
    expression = '\[([^\]]+)\]\(([^)]+)\)';
    [matches, tokens] = regexp(text, expression, 'match', 'tokens');

    for i = 1:numel(matches)
        label = normalizeLinkLabel(string(tokens{i}{1}));
        url = string(tokens{i}{2});

        if isTutorialLink(url)
            [~, targetName] = fileparts(url);
            replacement = "`" + label + " <" + targetName + ">`_";
        else
            replacement = "`" + label + " <" + url + ">`_";
        end

        text = replace(text, matches{i}, replacement);
    end
end

function label = normalizeLinkLabel(label)
    label = strtrim(label);
    label = replace(label, "**", "");
    label = replace(label, "*", "");
    label = replace(label, "``", "");
    label = regexprep(label, '`([^`]+)`', '$1');
    label = replace(label, "\_", "_");
end

function tf = isTutorialLink(url)
    [~, ~, extension] = fileparts(url);
    tf = ismember(extension, [".mlx", ".m", ".rst"]);
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

function blockLines = indentBlock(blockLines, indentation)
    blockLines = string(blockLines);
    for i = 1:numel(blockLines)
        if blockLines(i) == ""
            continue
        end
        blockLines(i) = indentation + blockLines(i);
    end
    blockLines = reshape(blockLines, [], 1);
end

function lines = trimBlankLines(lines)
    while ~isempty(lines) && strtrim(lines(1)) == ""
        lines(1) = [];
    end

    while ~isempty(lines) && strtrim(lines(end)) == ""
        lines(end) = [];
    end
end

function lineText = normalizeBlockLine(lineText)
    lineText = strtrim(replace(lineText, "&nbsp;", " "));
end
