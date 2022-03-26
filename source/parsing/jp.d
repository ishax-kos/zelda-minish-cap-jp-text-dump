module parsing.jp;

import table;

import std.mmfile;

TextBox parseStringJP(MmFile romFile) {
    string[][] output;


    
    enum MAX_LENGTH = 1024;
    bool terminate = false;
    ulong i;
    foreach (_; 0..MAX_LENGTH) {
        if (i >= romFile.length) break;
        if (terminate) break;
        ubyte value = romFile.pop!ubyte();
        switch (value) {
            case 0x00: /// End
                terminate = true; break;

            case 0x01:
                goto case 0x00;

            case 0x02: /// Set color
                auto color = romFile.pop!ubyte();
                // if (colorFlag) message ~= "</span>";
                message ~= parseColor(color);
                break;

            case 0x03: /// Play sound?
                romFile.pop!(ubyte[2])();
                break;

            case 0x04: /// Move text box
                romFile.pop!(ubyte[2])();
                break;

            case 0x05: /// Choice
                ubyte b1 = romFile.pop!(ubyte)();
                if (b1 == 0xFF) {message ~= " ❌ ▶";}
                else {
                    ubyte b2 = romFile.pop!(ubyte)(); //3
                    message ~= format!" 🔎%s, %s ▶"d( b1, b2 );
                }
                // message ~= "";
                break;

            case 0x06: /// Preset words
                if (romFile.pop!ubyte() == 0)
                    message ~= "リンク";
                break;

            case 0x07: /// Terminating ellipsis
                message ~= "...";
                terminate = true; break;

            case 0x08, 0x09:
                romFile.pop!(ubyte)();
                break;


            case 0x0A: /// Newline
                message ~= "\n";
                break;

            case 0x0B: /// Wind hylian
                ubyte value2 = romFile.pop!ubyte();
                // if (value2 >= windHylian.length) error = true;
                message ~= "#" ~ value2.format!"%02X"d();
                break;

            case 0x0C: /// Button symbols
                uint value2 = mapping_0C + romFile.pop!ubyte();
                if (value2 >= glyphs2x2.length) message ~= format!"[%02X]"d(value2 - glyphs2x2.length);
                else message ~= glyphs2x2[value2];
                break;

            case 0x0D: /// Kanji
                message ~= glyphs2x2[romFile.pop!ubyte()];
                break;

            case 0x0E: /// Kanji extra
                uint value2 = mapping_0E + romFile.pop!ubyte();
                if (value2 >= glyphs2x2.length) message ~= format!"[%02X]"d(value2 - glyphs2x2.length);
                else message ~= glyphs2x2[value2];
                break;

            case 0x0F: /// Punctuation
                ubyte value2 = romFile.pop!ubyte();
                if (value2 >= mapping1x2_0F.length)
                     message ~= value2.format!"[INVALID OFFSET %02X]"d();
                else if (mapping1x2_0F[value2] == '\0')
                    message ~= "[BLANK_0F]";
                else
                    message ~= mapping1x2_0F[value2];
                break;

            default: /// Base charset
                message ~= mapping1x2_Base[value];
                break;
        }
    }
    // if (colorFlag) message ~= "</span>";
    return message;

}


dstring parseColor(ubyte color) {
    color %= 16;
    switch (color) {
        case 0x0:
            goto default;
        case 0x1://red
            return `<color style="color:#f54242;">`;
        case 0x2://green
            return `<color style="color:#3cc932;">`;
        case 0x3://blue
            return `<color style="color:#4287f5;">`;
        case 0x4://black
            return `<color style="color:#000000;">`;
        case 0x5:
            return `<color style="color:#FFFFFF;`
             ~ `background:#444444">`;
        case 0x6:
            return `<color style="color:#FFFFFF;`
             ~ `background:#7a231c">`;
        case 0x7:
            return `<color style="color:#f54242;`
             ~ `background:#7a231c">`;

        case 0x8: goto case 0x0;
        case 0x9: goto case 0x1;
        case 0xA: goto case 0x2;
        case 0xB: goto case 0x3;
        case 0xC: goto case 0x4;
        case 0xD: goto case 0x5;

        case 0xE: goto case 0x2;
        case 0xF: goto case 0x5;
        default:
            return `</color>`;
    }
}
// +/