function matnwb_generateRstFilesFromCode()
    generateRstForTutorials()
    generateRstForNwbFunctions()
    generateRstForNeurodataTypeClasses('core')
    generateRstForNeurodataTypeClasses('hdmf_common')
    generateRstForNeurodataTypeClasses('hdmf_experimental')
end