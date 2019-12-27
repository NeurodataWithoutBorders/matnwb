classdef DatasetCreationPropertyList < h5.interface.HasId
    %DATASETCREATIONPROPERTYLIST Represents a H5P for dataset creation
    
    methods (Static)
        function Dcpl = create(varargin)
            if isempty(varargin)
                Dcpl = h5.DatasetCreationPropertyList('H5P_DEFAULT');
                return;
            end
            
            [Properties, propNames] = enumeration('h5.DatasetCreationProperties');
            keywords = varargin(1:2:end);
            stringKeywordMask = cellfun('isclass', keywords, 'char');
            filterKeywordMask = cellfun('isclass', keywords,...
                'h5.DatasetCreationProperties');
            
            assert(all(stringKeywordMask | filterKeywordMask)...
                && isempty(setdiff([keywords{filterKeywordMask}], Properties))...
                && isempty(setdiff(keywords(stringKeywordMask), propNames)),...
                'NWB:H5:Dataset:InvalidArgument',...
                'Property arguments must use valid keywords.');
            
            Dcpl = h5.DatasetCreationPropertyList(...
                H5P.create('H5P_DATASET_CREATE'));
            for i = 1:2:length(varargin)
                Word = h5.DatasetCreationProperties.(varargin{1});
                Word.processArguments(Dcpl, varargin{2});
            end
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        isChunked;
        isCompressed;
    end
    
    methods % lifecycle
        function obj = DatasetCreationPropertyList(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5P.delete(obj.id);
        end
    end
    
    methods % get/set
        function tf = get.isChunked(obj)
            H5P.get_layout();
            layout = H5P.get_layout(create_plist);
            tf =
        end
        
        function tf = get.isCompressed(obj)
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end