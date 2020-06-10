/// @description  DerpXmlWrite_OpenTag(tagName)
/// @param tagName
//
//  Writes an open tag, e.g. <tagName>

var tagName = argument0;

with objDerpXmlWrite {
    if lastWriteType == DerpXmlType_OpenTag {
        currentIndent += 1
    }
    
    writeString += newlineString
    repeat currentIndent {
        writeString += indentString
    }
    
    writeString += "<"+tagName+">"
    lastWriteType = DerpXmlType_OpenTag
    ds_stack_push(tagNameStack, tagName)
    lastWriteEmptyElement = false
}
