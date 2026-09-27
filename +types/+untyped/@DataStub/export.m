function refs = export(obj, writer, fullpath, refs)
    writer = io.backend.base.Writer.ensure(writer);
    writer.copyDatasetFromFile(obj.filename, obj.path, fullpath);
end
