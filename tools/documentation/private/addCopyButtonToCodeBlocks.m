function updatedHtmlContent = addCopyButtonToCodeBlocks(htmlContent)
% addCopyButtonToCodeBlocks - Updates HTML content to include a copy button for code blocks.
%
% Syntax:
%   updatedHtmlContent = addCopyButtonToCodeBlocks(htmlContent) 
%   This function reads the provided HTML content and injects a copy button
%   for each code block, along with the necessary JavaScript and CSS.
%
% Input Arguments:
%   htmlContent - A string containing the original HTML content that needs
%                 to be updated with copy buttons for code blocks.
%
% Output Arguments:
%   updatedHtmlContent - A string containing the modified HTML content 
%                        with copy buttons added to code blocks.

    currentFolder = fileparts(mfilename('fullpath'));
    htmlFolder = fullfile(currentFolder, 'html');

    % Add updated styles for codeblock and copy button
    codeblockCSS = fileread(fullfile(htmlFolder, 'copy_button_style_css.html'));
    CODEBLOCK_CSS = ".CodeBlock { background-color: #F5F5F5; margin: 10px 0 10px 0; }";
    updatedHtmlContent = regexprep(htmlContent, CODEBLOCK_CSS, codeblockCSS);
    
    % Add javascript for creating button and handling button click
    jsSnippet = fileread(fullfile(htmlFolder, 'copy_button_js.html'));
    updatedHtmlContent = strrep(updatedHtmlContent, '</body></html>', [jsSnippet '</body></html>']);
end

