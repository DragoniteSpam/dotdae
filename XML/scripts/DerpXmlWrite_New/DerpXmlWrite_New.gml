/// @description  DerpXmlWrite_New(filePath)
/// @param filePath
//
//  Starts a new empty xml string.

with objDerpXmlWrite {
    writeString = ""
    currentIndent = 0
    lastWriteType = DerpXmlType_StartOfFile
    lastWriteEmptyElement = false
}
