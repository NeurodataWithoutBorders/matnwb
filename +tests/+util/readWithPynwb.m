function [nwbFile, nwbFileCleanup] = readWithPynwb(nwbFilename)
    try
        io = py.pynwb.NWBHDF5IO(nwbFilename);
        nwbFile = io.read();
        nwbFileCleanup = onCleanup(@(x) closePyNwbObject(io));
    catch ME
        error(ME.message)
    end

    function closePyNwbObject(io)
        io.close()
    end
end