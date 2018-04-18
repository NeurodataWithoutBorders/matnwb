function festr = fillExport(name, propnames, props)
if strcmp(name, 'NWBFile')
%     keyboard;
end
festr = '';
% only export if your property is not inherited
% recreate elided properties
% links and refs require a hdf5 path to the object (object must be searchable)
% - Generate the paths here and associate them with all typed objects.
% - Store links and references separately
% - Do another pass writing locations ids to the write references
% tables => compound type
% 'region' and 'target' properties are linked and => region reference or object
% reference
end