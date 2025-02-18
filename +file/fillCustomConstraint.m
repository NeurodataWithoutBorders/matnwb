function customConstraintStr = fillCustomConstraint(nwbType)
% fillCustomConstraint - Create functions to check custom constraints 
%   These are constraints that can not be inferred from the nwb-schema
%
%   Reference: https://github.com/NeurodataWithoutBorders/matnwb/issues/588

    customConstraintFunctionFile = fullfile(...
        fileparts(mfilename('fullpath')), ...
        'templates', ...
        'custom_constraints', ...
        [char(nwbType), '.m']);

    if isfile(customConstraintFunctionFile)
        customConstraintStr = fileread(customConstraintFunctionFile);
    else
        customConstraintStr = '';
    end
end
