classdef SoftLink < h5.Link
    %SOFTLINK Link to internal file object using only string paths.
    methods (Static)
        function SoftLink = create(Parent, name, varargin)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:SoftLink:Create:InvalidArgument',...
                '`Parent` object must have an ID.');
            assert(ischar(name),...
                'NWB:H5:SoftLink:Create:InvalidArgument',...
                '`name` must be a character array.');
            
            p = inputParser;
            p.addParameter('path', '');
            p.parse(varargin{:});
            
            path = p.Results.path;
            
            assert(~isempty(obj.path),...
                'NWB:H5:SoftLink:Create:MissingArgument',...
                'External Links require a path to the object in the other file');
            
            lcpl = 'H5P_DEFAULT';
            lapl = 'H5P_DEFAULT';
            H5L.create_soft(path, Parent.get_id(), name, lcpl, lapl);
            lid = H5O.open(Parent.get_id(), name, lapl);
            SoftLink = h5.link.SoftLink(Parent, name, lid);
        end
        
        function SoftLink = open(Parent, name)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:SoftLink:Open:InvalidArgument',...
                '`Parent` object must have an ID.');
            assert(ischar(name),...
                'NWB:H5:SoftLink:Open:InvalidArgument',...
                '`name` must be a character array.');
            
            lapl = 'H5P_DEFAULT';
            lid = H5O.open(Parent.get_id(), name, lapl);
            ObjInfo = H5O.get_info(lid);
            assert(ObjInfo.type == h5.const.ObjectType.Link,...
                'NWB:H5:SoftLink:Open:InvalidObject',...
                '`%s` doesn''t refer to a valid Link.', name);
            SoftLink = h5.link.SoftLink(Parent, name, lid);
        end
    end
    
    properties (SetAccess = private, Dependent)
        path;
    end
    
    methods % set/get
        function path = get.path(obj)
            data = H5L.get_val(obj.parent.get_id(), obj.name, 'H5P_DEFAULT');
            path = data{1};
        end
    end
end