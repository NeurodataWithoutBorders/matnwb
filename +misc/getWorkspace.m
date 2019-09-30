function path = getWorkspace()
%GETWORKSPACE Returns current workspace in MATLAB
[path, ~, ~] = fileparts(getenv('WORKSPACE'));
end