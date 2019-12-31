classdef Dataset < h5.interface.HasId...
        & h5.interface.IsNamed...
        & h5.interface.IsHdfData...
        & h5.interface.HasAttributes
    %DATASET HDF5 Dataset for regular datatypes
    
    methods (Static)
        function Dataset = create(Parent, name, varargin)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            
            p = inputParser;
            p.PartialMatching = false;
            p.addParameter('data', []);
            p.addParameter('maxSize', []);
            p.addParameter('type', h5.PresetType.U8);
            p.addParameter('dcpl', h5.DatasetCreationPropertyList());
            p.parse(varargin{:});
            data = p.Results.data;
            maxSize = p.Results.maxSize;
            Type = p.Results.type;
            Dcpl = p.Results.dcpl;
            
            assert(xor(isempty(data), isempty(maxSize)),...
                'NWB:H5:Dataset:MissingArgument',...
                ['Create a dataset either using data to write, or a maximum size if '...
                'you wish to write the data later.']);
            
            assert(isa(Dcpl, 'h5.DatasetCreationPropertyList'),...
                'NWB:H5:Dataset:InvalidArgument',...
                '`dcpl` must be a valid h5.DatasetCreationPropertyList');
            
            if isempty(maxSize)
                Type = h5.Type.deriveFromMatlab(class(data));
                Space = h5.Space.deriveFromMatlab(Type, size(data));
            else
                Space = h5.Space.
            end
            
            pid = 'H5P_DEFAULT';
            did = H5D.create(Parent.get_id(), name,...
                Type.get_id(), Space.get_id(), pid, Dcpl.get_id(), pid);
            Dataset = h5.Dataset(did, name);
            Dataset.write(data);
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            did = H5D.open(Parent.get_id(), name);
            Dataset = h5.Dataset(did, name);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private)
        name;
    end
    
    properties (SetAccess = private, Dependent)
        space;
        dims;
        extents;
        type;
        isChunked;
    end
    
    methods % lifecycle
        function obj = Dataset(name, id)
            obj.name = name;
            obj.id = id;
        end
        
        function delete(obj)
            H5D.close(obj.id);
        end
    end
    
    methods % set/get
        function dims = get.dims(obj)
            Space = obj.space;
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(Space.get_id());
            dims = fliplr(h5_dims);
        end
        
        function extents = get.extents(obj)
            Space = obj.space;
            [~, ~, h5_maxdims] = H5S.get_simple_extent_dims(Space.get_id());
            maxSize = fliplr(h5_maxdims);
        end
        
        function Space = get.space(obj)
           Space = H5.Space(H5D.get_space(obj.id)); 
        end
        
        function Type = get.type(obj)
            Type = H5.Type(H5D.get_type(obj.id));
        end
        
        function tf = get.isChunked(obj)
            Dcpl = h5.DatasetCreationPropertyList(H5D.get_create_plist(obj.id));
            layout = H5P.get_layout(Dcpl.get_id());
            tf = layout == h5.DatasetCreationProperties.Chunking;
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
    
    methods % IsHdfData
        function write(obj, data)
            if isa(obj.type, 'h5.PresetType')
                data = obj.type.filter(data);
                
                if ismember(obj.type,...
                        [h5.PresetType.ObjectReference, h5.PresetType.DatasetRegionReference])
                    assert(~isa(data, 'types.untyped.ObjectView')...
                        && ~isa(data, 'types.untyped.RegionView'),...
                        'NWB:H5:Dataset:PreconversionRequired',...
                        ['Reference data must be converted by this point.  '...
                        'Use h5.File.filter_reference to convert the data.']);
                end
            end
            
            PLIST_ID = 'H5P_DEFAULT';
            H5D.write(obj.id,...
                Type.get_id(), obj.space.get_id(), obj.space.get_id(), PLIST_ID, data);
        end
        
        function data = read(obj)
            data = H5D.read(obj.id);
        end
    end
end