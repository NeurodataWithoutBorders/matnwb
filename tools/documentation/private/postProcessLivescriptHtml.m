function postProcessLivescriptHtml(htmlFile)
    %POSTPROCESSLIVESCRIPHTML Update links in an HTML file to open in the top frame
    % 
    % This function reads an HTML file and updates all <a> tags with an 
    % href attribute starting with "https:" by adding or updating the 
    % target attribute to "top". The modified HTML content is written 
    % back to the same file.
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

    % The purpose of this function is to ensure links open in the top frame
    % and not an iframe if tutorial htmls are embedded in an iframe.

    arguments
        htmlFile (1,1) string {mustBeFile}
    end

    % Read the content of the HTML file
    htmlContent = fileread(htmlFile);

    % % Add target="top" to links with href starting with https
    % updatedHtmlContent = regexprep(htmlContent, ...
    %     '<a href="https://', ...
    %     '<a target="top" href="https://');
    % updatedHtmlContent = regexprep(updatedHtmlContent, ...
    %     '<a href = "https://', ...
    %     '<a target = "top" href = "https://');
    str = fileread('update_link_target_js.html');
    updatedHtmlContent = regexprep(htmlContent, ...
        "</div></body></html>", ...
        sprintf("</div>%s</body></html>", str));

    % Write the modified content back to the HTML file
    try
        fid = fopen(htmlFile, 'wt');
        if fid == -1
            error('Could not open the file for writing: %s', htmlFile);
        end
        fwrite(fid, updatedHtmlContent, 'char');
        fclose(fid);
    catch
        error('Could not write to the file: %s', htmlFile);
    end
end
