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
        table.number = cast(uint) tableNum;

        foreach (messageNum; 0..messageCount) {
            immutable stringOffset = romFile.take!uint(messageNum*4 + tableOffset) + tableOffset;
            table.messages ~= MessageEntry( 
                messageNum, 
                parseString(romFile, stringOffset) 
            );
        }
        tableList ~= table;
    }
    return tableList;
}

import std.range.primitives;

ColorText[] parseString(T)(T romFile, uint offset)
if (is(typeof(romFile[0]) == ubyte)) {
    
    if (romFile[offset] == 0) return []; 
    ColorText[] message = [ColorText()];

    /// Adds text to the last ColoredMsg in the array.
    void addString(String_t text) {
        message[$-1].append(text);
    }

    ulong i = offset;
    
    foreach (_; 0..MAX_LENGTH) {
        // writeln(_);
        if (i >= romFile.length) {
            addString ("%%% End of file reached. Something went wrong. ###");
            return message;
        }
        if (romFile[i] >= 16) {
            addString (mapping1x2_Base[romFile[i++]]);
        }
        else final switch (romFile[i++]) {
            case 0x00: /// End
                return message;

            case 0x01:
                return message;

            case 0x02: /// Set color
                ubyte color = romFile[i++];
                message ~= ColorText(color, "");
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
                    message[$-1].text ~= Text(TextOption.close);
                else {
                    ubyte b2 = romFile[i++]; //3
                    message[$-1].text ~= Text(TextOption(b1, b2));
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
                addString (value2.format!"#%02X"());
                break;

            case 0x0C: /// Button symbols
                uint value2 = mapping_0C + romFile[i++];
                if (value2 >= glyphs2x2.length)
                    addString (format!"[%02X]"(value2 - glyphs2x2.length));
                else
                    addString (glyphs2x2[value2]);
                break;

            case 0x0D: /// Kanji
                addString (glyphs2x2[romFile[i++]]);
                break;

            case 0x0E: /// Kanji extra
                uint value2 = mapping_0E + romFile[i++];
                if (value2 >= glyphs2x2.length)
                    addString (format!"[%02X]"(value2 - glyphs2x2.length));
                else 
                    addString (glyphs2x2[value2]);
                break;

            case 0x0F: /// Punctuation
                ubyte value2 = romFile[i++];
                if (value2 >= mapping1x2_0F.length)
                    addString (value2.format!"[INVALID OFFSET %02X]"());
                else if (mapping1x2_0F[value2] == "\0")
                    addString ("[BLANK_0F]");
                else
                    addString (mapping1x2_0F[value2]);
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
    import std.conv;
    import std.file;
    import std.stdio;
    auto result = parseString([ubyte(16), ubyte(17), ubyte(18), ubyte(0)], 0);
    std.file.write("test.result.txt", result.plainText);
    stdout.writeln(result);
    assert(result.plainText == "あアい", result.length.to!string);
    
    
}