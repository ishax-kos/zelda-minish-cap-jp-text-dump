module parsing.jp;

import types;
import data;

import std.format;
import std.mmfile;
import std.stdio;


enum OFFSET = 0x9B1A30;
// enum MAX_TABLES = 256;
enum MAX_ROWS = 256;
enum MAX_LENGTH = 1024;

// alias

Table[] parseTables(MmFile romFile) {
    import std.range: iota;
    static t = 0;
    Table[] tableList;
    /++ Get the offset from the beginning of the table to 
        the first subtable and read the data inbetween.+/
    immutable tableCount = romFile.take!uint(OFFSET) / uint.sizeof;
    foreach (tableNum; 0..tableCount) {
        immutable uint tableOffset =  romFile.take!uint(tableNum*4 + OFFSET) + OFFSET;
        // writefln!"%X"(tableOffset);
        uint val1 = romFile.take!uint(tableOffset);
        // writeln(t++);
        immutable uint messageCount = val1 / uint.sizeof;
        // writeln(t++);

        Table table;
        
        table.name = format!"Table %d"(tableNum);
        if (tableNum < tableDescriptions.length)
            table.description = tableDescriptions[tableNum];

        foreach (messageNum; 0..messageCount) {
            immutable stringOffset = romFile.take!uint(messageNum*4 + tableOffset) + tableOffset;
            table.messages ~= TextBox( 
                messageNum, 
                parseString(romFile, stringOffset) 
            );
        }
        tableList ~= table;
    }
    return tableList;
}



ColoredMsg[] parseString(MmFile romFile, uint offset) {
    
    ColoredMsg[] message = [ColoredMsg()];

    /// Adds text to the last ColoredMsg in the array.
    void addString(wstring text) {
        message[$-1].text ~= text;
    }
    void addChar(wchar cha) {
        message[$-1].text ~= cha;
    }

    ulong i = offset;
    
    foreach (_; 0..MAX_LENGTH) {
        if (i >= romFile.length) break;
        if (romFile[i] >= 16) {
            addChar (mapping1x2_Base[romFile[i++]]);
        }
        else final switch (romFile[i++]) {
            case 0x00: /// End
                return message;

            case 0x01:
                return message;

            case 0x02: /// Set color
                ubyte color = romFile[i++];
                message ~= ColoredMsg(color, "");
                break;

            case 0x03: /// Play sound?
                i += 2;
                break;

            case 0x04: /// Move text box
                i += 2;
                break;

            case 0x05: /// Choice
                ubyte b1 = romFile[i++];
                if (b1 == 0xFF)
                    addString ("❌▶");
                else {
                    ubyte b2 = romFile[i++]; //3
                    addString (
                        format!"🔎%d,%d▶"w(b1,b2)
                    );
                }
                break;

            case 0x06: /// Preset words
                ubyte lexiconIndex = romFile[i++];
                if (lexiconIndex == 0)
                    addString ("リンク");
                break;

            case 0x07: /// Terminating ellipsis
                addString ("...");
                return message;

            case 0x08, 0x09:
                i++;
                break;


            case 0x0A: /// Newline
                addString ("\n");
                break;

            case 0x0B: /// Wind hylian
                ubyte value2 = romFile[i++];
                addString (value2.format!"#%02X"w());
                break;

            case 0x0C: /// Button symbols
                uint value2 = mapping_0C + romFile[i++];
                if (value2 >= glyphs2x2.length)
                    addString (format!"[%02X]"w(value2 - glyphs2x2.length));
                else
                    addChar (glyphs2x2[value2]);
                break;

            case 0x0D: /// Kanji
                addChar (glyphs2x2[romFile[i++]]);
                break;

            case 0x0E: /// Kanji extra
                uint value2 = mapping_0E + romFile[i++];
                if (value2 >= glyphs2x2.length)
                    addString (format!"[%02X]"w(value2 - glyphs2x2.length));
                else 
                    addChar (glyphs2x2[value2]);
                break;

            case 0x0F: /// Punctuation
                ubyte value2 = romFile[i++];
                if (value2 >= mapping1x2_0F.length)
                    addString (value2.format!"[INVALID OFFSET %02X]"w());
                else if (mapping1x2_0F[value2] == '\0')
                    addString ("[BLANK_0F]");
                else
                    addChar (mapping1x2_0F[value2]);
                break;
        }
    }

    addString ("%%% hit the limit. Maybe increase? ###");
    return message;
}



T take(T)(MmFile file, ulong offset) {
    T[1] buffer = cast(T[]) file[offset..offset+T.sizeof];
    return buffer[0];
}


unittest {
    import std.mmfile;
    import std.encoding: BOM, bomTable;
    MmFile file = new MmFile("raw/rom.gba");
    File outputFile = File("output/test.txt", "wb");
    
    auto data = parseTables(file);
    outputFile.rawWrite(bomTable[BOM.utf16le].sequence);
    foreach(table; data) foreach(msg; table.messages) {
        outputFile.rawWrite(msg.text.plainText);
    }
    
}