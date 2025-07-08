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

    htmlStaticDir = fileparts(htmlFile);

    % Add custom css for livescripts
    assert(isfile(fullfile(htmlStaticDir, 'css', 'livescript.css')))
    cssLinkElement = '<link rel="stylesheet" href="css/livescript.css">';
    htmlContent = insertAfter(htmlContent, '</title>', [cssLinkElement newline]);

    % Add a javascript function that updates all <a> tags that has a 
    % href attribute starting with "https:" or ending with ".html" by adding or 
    % updating the target attribute to "top".
    %
    % Additionally, it will update relative tutorial links to point to the main
    % tutorial pages in the online documentation, instead of pointing to the
    % static htmls (which are embedded as iframes in the main tutorial pages).
    %
    % The purpose of this function is to ensure links open in the top frame
    % and not an iframe for tutorial/livescript htmls which are embedded in an 
    % iframe.
    assert(isfile(fullfile(htmlStaticDir, 'js', 'iframe-link-handler.js')))
    htmlContent = appendJavascriptElement(htmlContent, 'js/iframe-link-handler.js');

    % Add JavaScript that creates and handles copy buttons for each code block
    assert(isfile(fullfile(htmlStaticDir, 'js', 'copy-buttons.js')))
    htmlContent = appendJavascriptElement(htmlContent, 'js/copy-buttons.js');

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

function htmlContent = appendJavascriptElement(htmlContent, jsFilename)
    jsElement = [newline, sprintf('<script src="%s"></script>', jsFilename)];
    htmlContent = insertBefore(htmlContent, '</body></html>', jsElement);
end
