classdef Reference < matlab.mixin.Heterogeneous & h5.interface.Exportable
    %REFERENCE In-memory object stub representing a reference to an object or a dataset region.
    
    methods (Abstract)
        view = refresh(obj, Nwb); % expects an NwbFile.
        refData = serialize(obj, File); % expects an h5.File
    end
    
    methods (Sealed) % Exportable
        function MissingViews = export(obj, Parent, ~)
            MSG_ID_CONTEXT = 'NWB:Interface:Reference:Export:';
            assert(isa(Parent, 'h5.interface.IsHdfData'),...
                [MSG_ID_CONTEXT 'InvalidArgument'],...
                'Views must be written to Hdf5 Data objects.');
            
            try
                refData = obj.serialize(Parent.get_file());
            catch
                MissingViews = obj;
                return;
            end
            Parent.write(refData);
        end
    end
end

