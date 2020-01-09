classdef IsHdfData < h5.interface.HasSpace & h5.interface.HasType
    %ISFILEDATA This object is associated with readable/writable data.
    
    methods (Abstract)
        data = read(obj, varargin);
        write(obj, data, varargin);
    end
    
    methods
        function serialized = serialize_data(obj, data, varargin)
            if isa(data, 'nwb.interface.Reference')
                serialized = data.serialize(obj.get_file());
            else
                serialized = h5.data.serialize_matlab(data);
            end
        end
    end
end

