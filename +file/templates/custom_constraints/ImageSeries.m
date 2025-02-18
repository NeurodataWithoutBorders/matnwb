function checkCustomConstraint(obj)
% checkCustomConstraint - Check custom constraint of ImageSeries
% If external_file is set, it does not make sense to fill out the
% data property. However, data is a required property, so this 
% method will add a nan-array to the data property so that it passes 
% the requirement check on file export.
    if ~isempty(obj.external_file) && isempty(obj.data), ...
        obj.data = zeros(0,0,0);
    end
end