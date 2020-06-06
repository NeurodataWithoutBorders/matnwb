function path = getClassDir()
%GETWORKSPACE Returns current workspace in MATLAB
tmp = tempdir();
path = fullfile(tmp, 'matNWB');
if 7 ~= exist(path, 'dir')
    mkdir(path);
end
end