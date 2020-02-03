classdef Group < nwb.Class
    %GROUP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        name;
        sub_objects = nwb.class.Property.empty;
    end
    
    methods
        function obj = Group(inputArg1,inputArg2)
            %GROUP Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

