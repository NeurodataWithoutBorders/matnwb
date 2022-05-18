function isScalar = isShapeScalar(shape)
if ~iscell(shape)
    shape = {shape};
elseif iscell(shape{1})
    for iOption = 1:length(shape)
        shape{iOption} = cell2mat(shape{iOption});
    end
end

isScalar = true(size(shape));
for iOption = 1:length(shape)
    isScalar(iOption) = all(1 == shape{iOption});
end
end

