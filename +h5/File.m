classdef File < h5.interface.HasSubObjects & h5.interface.HasAttributes & h5.interface.IsNamed
    %FILE HDF5 file
    
    methods (Static)
        function File = create(filename)
            PLIST_ID = 'H5P_DEFAULT';
            File = h5.File(H5F.create(filename, 'H5F_ACC_EXCL', PLIST_ID, PLIST_ID));
        end
        
        function File = open(filename, Access)
            assert(isa(Access, 'h5.FileAccess'),...
                'NWB:H5:File:InvalidArgument',...
                'File Access must use the h5.FileAccess enum.');
            File = h5.File(H5F.open(filename, Access.mode, 'H5P_DEFAULT'));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        filename;
    end
    
    methods % lifecycle
        function obj = File(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5F.close(obj.id);
        end
    end
    
    methods % set/get
        function name = get.filename(obj)
            name = H5F.get_name(obj.id);
        end
    end
    
    methods
        function data = filter_references(obj, ref)
            % defaults to -1 (H5ML.id) which works for H5R.create when using
            % Object References
            refspace = repmat(H5ML.id, size(ref));
            refpaths = {ref.path};
            validPaths = find(~cellfun('isempty', refpaths));
            if isa(ref, 'types.untyped.RegionView')
                for i=validPaths
                    did = H5D.open(fid, refpaths{i});
                    %by default, we use block mode.
                    refspace(i) = ref(i).get_selection(H5D.get_space(did));
                    H5D.close(did);
                end
            end
            typesize = H5T.get_size(ref(1).type);
            data = zeros([typesize size(ref)], 'uint8');
            for i=validPaths
                data(:, i) = H5R.create(obj.id, ref(i).path, ref(i).reftype, ...
                    refspace(i));
            end
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

