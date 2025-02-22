function locationName = validateLocation(locationName)
    arguments
        locationName (1,1) string
    end
    
    if ~startsWith(locationName, "/")
        locationName = "/" + locationName;
    end
end
