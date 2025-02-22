function mustBeH5FileReference(value)
    arguments
        value {mustBeA(value, ["char", "string", "H5ML.id"])}
    end

    if isa(value, "char") || isa(value, "string")
        try
            io.internal.h5.mustBeH5File(value)
        catch ME
            throwAsCaller(ME)
        end
    else
        % value is a H5ML.id, ok!
    end
end
