function setup()
% setup - Install optional dependencies for MatNWB.
%
%   setup() installs the dependencies required to read NWB files stored in the
%   Zarr v2 format. MATLAB has no native Zarr support, so reading a Zarr-backed
%   NWB file requires:
%
%     1. The MathWorks Zarr wrapper (provides zarrinfo, zarrread, readZattrs),
%        cloned into external_packages and added to the MATLAB search path.
%     2. The Python package "tensorstore", installed into the interpreter
%        configured for MATLAB (see pyenv).
%
%   Reading and writing NWB files in the default HDF5 format does not require
%   this setup.
%
%   See also pyenv, io.backend.zarr2.Zarr2Reader

    matnwbDir = misc.getMatnwbDir();

    fprintf("Setting up optional MatNWB Zarr support...\n\n");
    installZarrWrapper(matnwbDir)
    fprintf("\n");
    installTensorStore()
    fprintf("\nSetup complete.\n");
end

function installZarrWrapper(matnwbDir)
% installZarrWrapper - Clone the MathWorks Zarr wrapper and add it to the path.

    % The wrapper currently resolves to a fork that adds functionality not yet
    % available upstream. Pinned to a specific commit for reproducibility.
    repoUrl = "https://github.com/ehennestad/MATLAB-support-for-Zarr-files.git";
    pinnedRef = "a55a3f2a20551cd761de1a8a57fc46144d03a241";
    targetFolder = fullfile(matnwbDir, "external_packages", "MATLAB-support-for-Zarr-files");

    if isfolder(targetFolder)
        fprintf("Zarr wrapper already present at %s\n", targetFolder);
    else
        fprintf("Cloning Zarr wrapper into %s...\n", targetFolder);
        [status, output] = system(sprintf('git clone %s "%s"', repoUrl, targetFolder));
        assert(status == 0, "NWB:Setup:CloneFailed", ...
            "Failed to clone the Zarr wrapper:\n%s", output)
        [status, output] = system(sprintf('git -C "%s" checkout --quiet %s', targetFolder, pinnedRef));
        assert(status == 0, "NWB:Setup:CheckoutFailed", ...
            "Failed to check out pinned Zarr wrapper revision %s:\n%s", pinnedRef, output)
    end

    addpath(targetFolder)
    savepath()
    fprintf("Zarr wrapper added to the MATLAB path.\n");
end

function installTensorStore()
% installTensorStore - Install the tensorstore package into MATLAB's Python.

    pythonEnvironment = pyenv();
    if strlength(pythonEnvironment.Version) == 0
        error("NWB:Setup:PythonNotConfigured", ...
            ["No Python interpreter is configured for MATLAB. Install Python " ...
             "and configure it with pyenv before running setup."])
    end

    fprintf("Installing tensorstore into %s...\n", pythonEnvironment.Executable);
    [status, output] = system(sprintf('"%s" -m pip install tensorstore', ...
        pythonEnvironment.Executable));
    if status ~= 0
        error("NWB:Setup:PipInstallFailed", ...
            "Failed to install tensorstore:\n%s", output)
    end
    fprintf("tensorstore installed.\n");
end
