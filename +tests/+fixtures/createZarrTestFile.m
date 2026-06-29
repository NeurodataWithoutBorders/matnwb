function fixturePath = createZarrTestFile(outputFolder)
% createZarrTestFile - Generate a minimal NWB Zarr store for reader tests.
%
%   fixturePath = createZarrTestFile(outputFolder) writes a minimal
%   ".nwb.zarr" store into outputFolder using the committed Python generator
%   (pynwb + hdmf-zarr) and returns the absolute path to the store.
%
%   The Python generator runs in MATLAB's configured interpreter (see pyenv).
%   Callers are responsible for ensuring the required Python packages are
%   available; use tests.util.isZarrWriteSupported to check beforehand.
%
%   See also tests.util.isZarrWriteSupported, pyrunfile

    arguments
        outputFolder (1,1) string {mustBeFolder}
    end

    fixturePath = fullfile(outputFolder, "fixture.nwb.zarr");

    scriptPath = fullfile(fileparts(mfilename("fullpath")), "generateZarrTestFile.py");
    pyrunfile(scriptPath + " " + """" + fixturePath + """")
end
