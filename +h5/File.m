classdef File < h5.interface.HasSubObjects & h5.interface.HasAttributes & h5.interface.IsNamed
    %FILE HDF5 file
    
    methods (Static)
        function File = create(filename)
            PLIST_ID = 'H5P_DEFAULT';
            File = h5.File(H5F.create(filename, 'H5F_ACC_EXCL', PLIST_ID, PLIST_ID));
        end
        
        function File = open(filename, varargin)
            p = inputParser;
            p.addParameter('access', h5.const.FileAccess.ReadOnly);
            p.parse(varargin{:});
            Access = p.Results.access;
            assert(isa(Access, 'h5.const.FileAccess'),...
                'NWB:H5:File:InvalidArgument',...
                'File Access must use the h5.FileAccess enum.');
            assert(H5F.is_hdf5(filename),...
                'NWB:H5:File:InvalidFile',...
                'File must be a valid HDF5 file.')
            File = h5.File(H5F.open(filename, Access.constant, 'H5P_DEFAULT'));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        filename;
        isValidH5;
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
        function refData = get_reference_data(obj, View)
            assert(isa(View, 'types.untyped.ObjectView')...
                || isa(View, 'types.untyped.RegionView'),...
                'NWB:H5:File:GetReferenceData:InvalidArgument',...
                '`View` must be an ObjectView or RegionView');

            if isa(View, 'types.untyped.ObjectView')
                refType = h5.const.ReferenceType.Object.constant;
                Selection = -1;
            else
                refType = h5.const.ReferenceType.DatasetRegion.constant;
                Selection = h5.Dataset.open(obj, View.path).make_selection(View.region);
            end
            refData = H5R.create(obj.id, View.path, refType, Selection.get_id());
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

