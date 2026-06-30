function tf = isReadContext()
    import matnwb.common.validation.internal.ValidationContext
    tf = matnwb.common.validation.internal.context() == ValidationContext.READ;
end
