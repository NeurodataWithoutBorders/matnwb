classdef IsConstant
    %ISCONSTANT This enum is a H5ML constant
    
    methods (Static)
        function Constant = from_constant(classname, value) 
            MSG_ID_CONTEXT = 'NWB:H5:Interface:IsConstant:FromConstant:';
            assert(ischar(classname), [MSG_ID_CONTEXT 'InvalidArgument'],...
                'classname must be a character array.');
            
            mc = meta.class.fromName(classname);
            assert(mc <= ?h5.interface.IsConstant,...
                [MSG_ID_CONTEXT 'InvalidSubClass'],...
                'classname must refer to a subclass of h5.interface.IsConstant');
            
            allConstants = enumeration(classname);
            
            valueMatchMask = value == [allConstants.constant];
            assert(any(valueMatchMask),...
                [MSG_ID_CONTEXT 'ConstantNotFound'],...
                'Value does not exist in `%s`', classname);
            Constant = allConstants(valueMatchMask);
        end
    end
    
    properties (SetAccess = immutable)
        constant;
    end
    
    methods
        function obj = IsConstant(name)
            obj.constant = H5ML.get_constant_value(name);
        end
    end
end

