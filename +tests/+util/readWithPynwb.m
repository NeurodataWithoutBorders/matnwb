function [nwbFile, nwbFileCleanup] = readWithPynwb(nwbFilename)
    try
        io = py.pynwb.NWBHDF5IO(nwbFilename);
        nwbFile = io.read();
        nwbFileCleanup = onCleanup(@(x) closePyNwbObject(io));
    catch ME
        rethrow(ME)
    end

    function closePyNwbObject(io)
        io.close()
    end
end