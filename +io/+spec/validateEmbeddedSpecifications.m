function validateEmbeddedSpecifications(writer, expectedNamespaceNames)
% validateEmbeddedSpecifications - Validate the embedded specifications
%
% This function does two things:
%   1) Displays a warning if specifications of expected namespaces
%      are not embedded in the file.
%        E.g if cached namespaces were cleared prior to export.
%
%   2) Deletes specifications for unused namespaces that are embedded.
%      - E.g. If neurodata type from an embedded namespace was removed and the
%        file was re-exported
%
% Backend-agnostic: only uses the io.backend.base.Writer interface, so
% this works for any registered storage backend, not just HDF5.

    arguments
        writer (1,1) io.backend.base.Writer
        expectedNamespaceNames
    end

    specLocation = writer.getEmbeddedSpecLocation();
    embeddedNamespaceNames = writer.listChildGroupNames(specLocation);

    checkMissingNamespaces(expectedNamespaceNames, embeddedNamespaceNames)

    unusedNamespaces = checkUnusedNamespaces(...
        expectedNamespaceNames, embeddedNamespaceNames);

    if ~isempty(unusedNamespaces)
        deleteUnusedNamespaces(writer, unusedNamespaces, specLocation)
    end
end

function checkMissingNamespaces(expectedNamespaceNames, embeddedNamespaceNames)
% checkMissingNamespaces - Check if any namespace specs are missing from the file
    missingNamespaces = setdiff(expectedNamespaceNames, embeddedNamespaceNames);
    if ~isempty(missingNamespaces)
        missingNamespacesStr = strjoin("  " + string(missingNamespaces), newline);
        warning('NWB:validators:MissingEmbeddedNamespace', ...
            ['The following namespace specifications are not embedded in ' ...
             'the file:\n%s\n' ...
             'To facilitate reading and validating the file across systems, it is ' ...
             'recommended to embed the specifications for these namespaces. ' ...
             'Please generate the missing extensions (using generateCore or ' ...
             'generateExtension) and then re-export the file.'], missingNamespacesStr)
    end
end

function unusedNamespaces = checkUnusedNamespaces(expectedNamespaceNames, embeddedNamespaceNames)
% checkUnusedNamespaces - Check if any namespace specs in the file are unused
    unusedNamespaces = setdiff(embeddedNamespaceNames, expectedNamespaceNames);
end

function deleteUnusedNamespaces(writer, unusedNamespaces, specRootLocation)
    for i = 1:numel(unusedNamespaces)
        thisName = unusedNamespaces{i};
        namespaceSpecLocation = strjoin( {specRootLocation, thisName}, '/');
        writer.deleteNode(namespaceSpecLocation)
    end
end
