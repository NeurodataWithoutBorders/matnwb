function tf = isPythonModuleAvailable(moduleName)
% isPythonModuleAvailable - Check whether a Python module can be imported.
%
%   tf = isPythonModuleAvailable(moduleName) returns true if MATLAB's
%   configured Python interpreter (see pyenv) can locate moduleName. Used by
%   Zarr tests to skip gracefully when packages such as "hdmf_zarr" (fixture
%   generation) or "tensorstore" (reading) are not installed.

    arguments
        moduleName (1,1) string
    end

    try
        moduleSpec = py.importlib.util.find_spec(moduleName);
        tf = ~isequal(moduleSpec, py.None);
    catch
        % Importing or probing the module failed; treat it as unavailable.
        tf = false;
    end
end
