function postProcessLivescriptHtml(htmlFile)
    %POSTPROCESSLIVESCRIPHTML Postprocess livescript HTMLs for improved online functionality
    % 
    % This function performs the following actions:
    %   - Fix online livescript crosslinks when using iframes
    %   - Ensures all https links will open in top frame and not embedded iframe
    %   - Improve reactivity of embedded images
    %   - Add a copy button to all code blocks
    %
    % Syntax:
    %   postProcessLivescriptHtml(htmlFile)
    %
    % Input:
    %   htmlFile - (1,1) string: Path to the HTML file to process.
    %
    % Example:
    %   postProcessLivescriptHtml("example.html");
    %
    % This will ensure that links in "example.html" with href="https:" 
    % open in the top frame when clicked.

    arguments
        htmlFile (1,1) string {mustBeFile}
    end

    % Read the content of the HTML file
    htmlContent = fileread(htmlFile);

    % Add javascript to update all https links to have target=_top on
    % DOMContentLoaded. This is done because tutorial livescripts are
    % embedded in the documentation as iframes, and the default link
    % behavior is to open inside the iframe, which gets ugly.
    htmlContent = addUpdateScriptForLinkInIFrame(htmlContent);

    % Add css for imageNodes to improve reactivity in iframes
    htmlContent = updateImageNodeCss(htmlContent);
    
    htmlContent = addCopyButtonToCodeBlocks(htmlContent);

    % Write the modified content back to the HTML file
    try
        fid = fopen(htmlFile, 'wt');
        if fid == -1
            error('Could not open the file for writing: %s', htmlFile);
        end
        fwrite(fid, htmlContent, 'char');
        fclose(fid);
    catch
        error('Could not write to the file: %s', htmlFile);
    end
end

function htmlContent = updateImageNodeCss(htmlContent)
    if contains(htmlContent, 'imageNode')
        scriptFolder = fileparts(mfilename('fullpath'));
        imageNodeCss = fileread(fullfile(scriptFolder, 'html', 'image_node_css.html'));
        imageNodeCss = strrep(imageNodeCss, newline, ' ');
        htmlContent = insertBefore(htmlContent, '.S1 ', [imageNodeCss newline]);
    end
end

function htmlContent = addUpdateScriptForLinkInIFrame(htmlContent)
% This function adds a javscript element that updates all <a> tags that has a 
% href attribute starting with "https:" or ending with ".html" by adding or 
% updating the target attribute to "top".
%
% Additionally, it will update relative tutorial links to point to the main
% tutorial pages in the online documentation, instead of pointing to the
% static htmls (which are embedded as iframes in the main tutorial pages).
%
% The purpose of this function is to ensure links open in the top frame
% and not an iframe if tutorial htmls are embedded in an iframe.

    scriptFolder = fileparts(mfilename('fullpath'));
    str = fileread(fullfile(scriptFolder, 'html', 'update_iframe_links_js.html'));
    
    htmlContent = insertBefore(htmlContent, '</body></html>', str);
end
