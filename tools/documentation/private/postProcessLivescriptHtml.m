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

    scriptFolder = fileparts(mfilename('fullpath'));
    str = fileread(fullfile(scriptFolder, 'update_link_target_js.html'));
    updatedHtmlContent = regexprep(htmlContent, ...
        "</div></body></html>", ...
        sprintf("</div>%s</body></html>", str));

    % Update links: type classes
    for namespaceName = ["core", "hdmf_common", "hdmf_experimental"]
        updatedHtmlContent = strrep(updatedHtmlContent, ...
            sprintf('https://neurodatawithoutborders.github.io/matnwb/doc/+types/+%s/',namespaceName), ...
            sprintf('https://matnwb.readthedocs.io/en/latest/pages/neurodata_types/%s/',namespaceName) );
    end

    % Update links: Nwb functions
    for functionName = ["NwbFile", "nwbExport", "nwbRead", "generateCore", "generateExtension"]
        updatedHtmlContent = strrep(updatedHtmlContent, ...
            sprintf('https://neurodatawithoutborders.github.io/matnwb/doc/%s.html', functionName), ...
            sprintf('https://matnwb.readthedocs.io/en/latest/pages/functions/%s.html', functionName) );
    end

    % Update links: tutorials
    updatedHtmlContent = strrep(updatedHtmlContent, ...
        'https://neurodatawithoutborders.github.io/matnwb/tutorials/html/', ...
        'https://matnwb.readthedocs.io/en/latest/pages/tutorials/' );

    % Update links: api documentation
    updatedHtmlContent = strrep(updatedHtmlContent, ...
        'https://neurodatawithoutborders.github.io/matnwb/doc/index.html', ...
        'https://matnwb.readthedocs.io/en/latest/index.html' );
 

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
