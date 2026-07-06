function markdownText = preprocessMlxMarkdownForMyst(markdownFilePath, tutorialName, options)
% preprocessMlxMarkdownForMyst - Adapt exported live script markdown for MyST/Sphinx
%
% MATLAB's Live Editor markdown export embeds a table of contents and heading
% anchors as raw HTML, and points cross-tutorial links at the .mlx/.m source
% files rather than the published doc pages. This function strips the
% embedded ToC (Sphinx generates its own via the {contents} directive),
% scopes the anchor tags into page-unique MyST targets, rewrites internal
% tutorial links to bare document names, and resolves image paths/sizing.
%
% The rest of the markdown is left untouched: it is real CommonMark/GFM, so
% myst-parser handles headings, lists, tables, links and code fences natively
% -- no custom block parser is needed here, unlike the reStructuredText
% converter this replaces.

    arguments
        markdownFilePath (1,1) string {mustBeFile}
        tutorialName (1,1) string
        options.MediaRelativePath (1,1) string = ""
        options.ImageNames (1,:) string = string.empty
        options.ImageDisplayWidths (1,:) double = double.empty
    end

    markdownText = string(fileread(markdownFilePath));

    markdownText = stripEmbeddedToc(markdownText);
    markdownText = stripDuplicateDocumentTitle(markdownText);
    markdownText = shiftHeadingLevelsDownOneStep(markdownText);
    markdownText = resolveAnchorsAndSamePageLinks(markdownText, tutorialName);
    markdownText = rewriteTutorialLinks(markdownText);
    markdownText = renameCapturedOutputFence(markdownText);
    markdownText = rewriteImages(markdownText, options.MediaRelativePath, ...
        options.ImageNames, options.ImageDisplayWidths);

    assertNoUnhandledHtmlMarkup(markdownText, markdownFilePath)
    assertNoUnrecognizedFenceLanguage(markdownText, markdownFilePath)
end

function text = stripEmbeddedToc(text)
% MATLAB has used two ToC marker conventions across releases: HTML comments
% (current) and named anchors (older). Strip whichever is present so a
% release change here does not leak raw markup into the page.
    text = regexprep(text, "<!--\s*Begin Toc\s*-->.*?<!--\s*End Toc\s*-->\n?", "", "once", "ignorecase");
    text = regexprep(text, '<a name="beginToc"></a>.*?<a name="endToc"></a>\n?', "", "once");
end

function text = resolveAnchorsAndSamePageLinks(text, tutorialName)
% Preserve MATLAB's per-heading anchor ids as MyST explicit targets rather
% than deleting them: tutorial prose sometimes links to another section on
% the same page via that id (e.g. "see External files (#H_9b57) below").
%
% Sphinx's target namespace is global across the whole documentation site,
% not scoped per page, and MATLAB's short anchor ids are not even
% guaranteed unique within a single export (two identically-worded headings
% hash to the same id). Every anchor is therefore rewritten to
% "<tutorialName>-<id>-<occurrence>", and same-page links are pointed at
% the first heading that used their id -- the same one a duplicate id
% would resolve to in MATLAB's own Live Editor.
    tagPattern = '<a (?:id|name)="([^"]*)"></a>';
    [tagStarts, tagEnds, tagTokens] = regexp(text, tagPattern, 'start', 'end', 'tokens');

    seenIds = strings(0, 1);
    seenOccurrenceCounts = double.empty(0, 1);
    firstUniqueIdForId = strings(0, 1);

    textParts = strings(0, 1);
    cursor = 1;
    for i = 1:numel(tagStarts)
        thisId = string(tagTokens{i}{1});

        seenIndex = find(seenIds == thisId, 1);
        if isempty(seenIndex)
            seenIds(end+1, 1) = thisId; %#ok<AGROW>
            seenOccurrenceCounts(end+1, 1) = 1; %#ok<AGROW>
            seenIndex = numel(seenIds);
        else
            seenOccurrenceCounts(seenIndex) = seenOccurrenceCounts(seenIndex) + 1;
        end
        uniqueId = tutorialName + "-" + thisId + "-" + string(seenOccurrenceCounts(seenIndex));
        if seenOccurrenceCounts(seenIndex) == 1
            firstUniqueIdForId(end+1, 1) = uniqueId; %#ok<AGROW>
        end

        textParts(end+1, 1) = extractSpan(text, cursor, tagStarts(i) - 1); %#ok<AGROW>
        textParts(end+1, 1) = "(" + uniqueId + ")="; %#ok<AGROW>
        cursor = tagEnds(i) + 1;
    end
    textParts(end+1, 1) = extractSpan(text, cursor, strlength(text));
    text = strjoin(textParts, "");

    for i = 1:numel(seenIds)
        text = replace(text, "(#" + seenIds(i) + ")", "(#" + firstUniqueIdForId(i) + ")");
    end
end

function part = extractSpan(text, startIndex, endIndex)
    if endIndex < startIndex
        part = "";
    else
        part = extractBetween(text, startIndex, endIndex);
    end
end

function text = stripDuplicateDocumentTitle(text)
% The exported markdown's own top-level heading duplicates the tutorial
% title the page template already renders (from tutorial_config.json), so
% drop the first heading line -- and its anchor tag, if any -- once the
% embedded ToC has been removed.
    lines = splitlines(text);
    lines = trimLeadingBlankLines(lines);
    lines = dropLeadingLineIfMatches(lines, @(line) startsWith(line, "<a "));
    lines = trimLeadingBlankLines(lines);
    lines = dropLeadingLineIfMatches(lines, @(line) startsWith(line, "#"));
    text = strjoin(lines, newline);
end

function lines = trimLeadingBlankLines(lines)
    while ~isempty(lines) && strtrim(lines(1)) == ""
        lines(1) = [];
    end
end

function lines = dropLeadingLineIfMatches(lines, predicate)
    if ~isempty(lines) && predicate(strtrim(lines(1)))
        lines(1) = [];
    end
end

function text = shiftHeadingLevelsDownOneStep(text)
% The page template already renders the tutorial title as an H1. MATLAB
% exports the tutorial's own top-level sections as "#" too (the same
% level), which produces multiple sibling H1 sections on one page instead
% of a single nested document tree. That breaks two things at once: the
% sidebar navigation promotes every tutorial section as if it were its own
% page, and the {contents} directive -- which can only enumerate a
% section's descendants -- has nothing to list, so the on-page ToC renders
% empty. Shifting every heading down one level (H1->H2, H2->H3, ...) nests
% the body under the page title as intended. Fenced code blocks are left
% untouched, since a captured command-window output line could
% coincidentally start with "#".
    lines = splitlines(text);
    inFence = false;
    for i = 1:numel(lines)
        trimmedLine = strtrim(lines(i));
        if startsWith(trimmedLine, "```")
            inFence = ~inFence;
            continue
        end
        if inFence
            continue
        end
        if ~isempty(regexp(trimmedLine, "^#+(\s|$)", 'once'))
            lines(i) = "#" + lines(i);
        end
    end
    text = strjoin(lines, newline);
end

function text = rewriteTutorialLinks(text)
% Rewrite links to other tutorials' source files, e.g. "(./ophys.mlx)" or
% "(convertTrials.m)", to bare document names. Sphinx/MyST resolves a bare
% relative link to whichever page exists for that document, regardless of
% whether it was generated as .md or .rst, so this does not need to know or
% guess the target tutorial's output format.
    text = regexprep(text, '\((\./)?([A-Za-z0-9_]+)\.(mlx|m)\)', "($2)");
end

function text = renameCapturedOutputFence(text)
    text = replace(text, "```matlabTextOutput", "```text");
end

function text = rewriteImages(text, mediaRelativePath, imageNames, imageDisplayWidths)
    pattern = '!\[([^\]]*)\]\(([^)]+)\)';
    [matches, tokens] = regexp(text, pattern, 'match', 'tokens');

    for i = 1:numel(matches)
        altText = string(tokens{i}{1});
        imagePath = resolveImagePath(string(tokens{i}{2}), mediaRelativePath);
        imageDisplayWidth = resolveImageDisplayWidth(imagePath, imageNames, imageDisplayWidths);

        imageAttributes = ".tutorial-media";
        if ~isnan(imageDisplayWidth)
            imageAttributes = imageAttributes + " width=" + string(round(imageDisplayWidth)) + "px";
        end

        % MyST's attrs_inline extension attaches the class/width to the image
        % without pulling it out of surrounding prose, so images referenced
        % inline mid-sentence (e.g. "click <icon>") stay inline instead of
        % being forced onto their own block as the old rst converter did.
        replacement = "![" + altText + "](" + imagePath + "){" + imageAttributes + "}";
        text = replace(text, matches{i}, replacement);
    end
end

function imagePath = resolveImagePath(imagePath, mediaRelativePath)
    imagePath = strtrim(imagePath);

    if mediaRelativePath == "" || ~contains(imagePath, "_media/")
        return
    end

    pathParts = split(imagePath, "/");
    imagePath = mediaRelativePath + "/" + pathParts(end);
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

function assertNoUnhandledHtmlMarkup(markdownText, markdownFilePath)
% Fail loudly if raw HTML markup from the live script export (anchor tags,
% TOC comment markers, etc.) leaked through unconverted. MATLAB's Live
% Editor markdown export is an internal, undocumented format that has
% already changed its anchor/TOC syntax across releases, so a future format
% change should surface as a build failure here rather than as silently
% broken published documentation.
    lines = splitlines(markdownText);
    offendingLine = "";
    for i = 1:numel(lines)
        thisLine = strtrim(lines(i));
        if startsWith(thisLine, "<a ") || contains(thisLine, "<!--")
            offendingLine = thisLine;
            break
        end
    end

    assert(offendingLine == "", ...
        "preprocessMlxMarkdownForMyst:UnhandledHtmlMarkup", ...
        "Unhandled HTML markup leaked into the generated markdown from '%s':\n  %s\n" + ...
        "This likely means MATLAB's markdown export syntax (anchor tags or TOC " + ...
        "markers) changed and is no longer recognized by this preprocessor.", ...
        markdownFilePath, offendingLine)
end

function assertNoUnrecognizedFenceLanguage(markdownText, markdownFilePath)
% Fail loudly on a code-fence language this preprocessor does not know
% about, e.g. a new captured-output block variant introduced by a future
% MATLAB release, rather than silently emitting an unhighlighted block.
    tokens = regexp(markdownText, "(?m)^```(\S*)", "tokens");
    knownLanguages = ["", "matlab", "text"];

    for i = 1:numel(tokens)
        language = string(tokens{i}{1});
        assert(ismember(language, knownLanguages), ...
            "preprocessMlxMarkdownForMyst:UnrecognizedFenceLanguage", ...
            "Unrecognized code-fence language '%s' in markdown exported from '%s'.\n" + ...
            "This likely means MATLAB's Live Editor markdown export introduced a new " + ...
            "output-block variant that this preprocessor does not yet handle.", ...
            language, markdownFilePath)
    end
end
