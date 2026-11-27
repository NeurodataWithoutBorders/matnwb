function constant = DESCRIPTION_PLACEHOLDER()
% DESCRIPTION_PLACEHOLDER - Description that MatNWB writes when none is given.
%
% A DynamicTable and each of its columns must have a description. When the
% user gives none, MatNWB writes this text. The check_description check of
% NWB Inspector reports this text as a placeholder, so a table or column
% that nobody described is reported when the file is inspected.

    constant = 'no description';
end
