module output.html;

import std.sumtype;
import std.range: repeat;
import std.format;
import std.string;
import std.algorithm: map, all;
import std.array: array;
import std.conv;

import types;
import data;

wstring formatHTML(Table[] structuredData) {
    Tag[] doc;
    doc ~= 
        "head".tag(
            "style".tag(
                import("style.css").to!wstring
            )
        );

    doc ~= "body".tag(
        "p".tag(dumpVersion.to!wstring),
        "div id=allTables".tag(
            structuredData.map!(
                (Table t) {
                    uint i = 0;
                    return "div class=trTable".tag(
                        "h3".tag(t.name.to!wstring),
                        "h4".tag(t.description.to!wstring),
                        "table class=trTable".tag(
                            t.messages.map!(
                                (TextBox tb) => "tr".tag(
                                    "td".tag(format!"%d"w(i++)),
                                    "td class=trMessage".msgToTag(tb.text)
                                )
                            )//.array
                        )
                    );
                }
            )//.array
        )
    );
    
    

    return doc.map!(toStringHTML).array.join('\n');
}


struct Tag {
    string tag;
    Contents_t[] contents;
}
wstring toStringHTML(Tag thisTag) {
    with (thisTag) {
        static indent = 0;
        
        wstring ind() {return " "w.repeat(4*indent).join;}

        wstring outStr = ind ~ format!"<%s>\n"w(tag);
        outStr ~= contents.map!((a) {
            indent += 1; scope(exit) indent -= 1; 
            return a.match!(
                (Tag t) => t.toStringHTML,
                (wstring ws) => ws.lineSplitter.map!(a => ind~a).join('\n')
            );
        }).join('\n');
        outStr ~= "\n" ~ ind ~ format!"</%s>"w(tag);
        return outStr;
    }
}

// static assert(staticIndexOf!(wstring, TemplateArgsOf!Contents_t) != -1);

import std.traits: TemplateArgsOf;
import std.meta;
pragma(inline)
Tag tag(T...)(string name, T mixedContents)
// if (staticIndexOf!(T, TemplateArgsOf!Contents_t) != -1)
{
    import std.range: isInputRange, ElementType;

    Contents_t[] contents;
    

    foreach (c; mixedContents) {
        alias C = typeof(c);
        static if (staticIndexOf!(C, TemplateArgsOf!Contents_t) != -1) 
            contents ~= Contents_t(c);
        else {
            static assert (isInputRange!C);
            static assert (staticIndexOf!(ElementType!C, TemplateArgsOf!Contents_t) != -1);
            foreach (c_; c)
                contents ~= Contents_t(c_);
            
        }
    }

    return Tag(name, contents);
}

alias Contents_t = SumType!(Tag, wstring);


string tagPalette(uint val) {
    import std.format;
    if (val < 16) return format!"c%X"(val);
    else return "cERROR";
}
Tag msgToTag(string tagName, ColoredMsg[] colorMsgArray) {
    import std.functional: compose;
    import std.uni: isWhite;

    wstring brLines(ColoredMsg t) {
        return t.text
            .lineSplitter
            .join("\n<br>"w);
    }

    wstring outmsg;
    foreach(colmsg; colorMsgArray) {
        if (colmsg.text == "") {}
        else if (colmsg.text.all!isWhite) {
            outmsg ~= brLines(colmsg);
        }
        else {
            outmsg ~= colmsg.palette.format!"<span class=c%X>"w();
            outmsg ~= brLines(colmsg);
            outmsg ~= "</span>"w;
        }
        
    }
    return tag(tagName, outmsg.strip);
}


/+
string parseFile(string inputPath, uint offset, string outPath) {
    MmFile romFile = MmFile(inputPath);
    File outFile = File(outPath, "wb");
    if (!outPath.dirName.exists) mkdir(outPath.dirName);
    // writeln(outPath);

//\"color:white; background-color:black;\"
    outFile.writeln(import("include/style.css"));

    romFile.seek(offset);

    /++ Get the offset from the beginning of the table to 
        the first subtable and read the data inbetween.+/
    uint[] tableTableOffsets = new uint[romFile.peek!uint/uint.sizeof];
    romFile.rawRead(tableTableOffsets);

    outFile.writeln(format!"<p>version %(%s.%)</p>"(dumpVersion));
    outFile.writeln("<div class=allEntries>");
    scope(exit) outFile.writeln("</div>");

    string[][] stringTable;
    foreach (tableNum, uint ttoff; tableTableOffsets) {
        romFile.seek(offset + ttoff);
        uint[] stringTableOffsets = new uint[romFile.peek!uint/uint.sizeof];
        romFile.rawRead(stringTableOffsets);


        outFile.writeln("<div class=entry>");
        scope(exit) outFile.writeln("</div>");
        outFile.writefln("<h3>Table %s</h3>", tableNum);
        outFile.writeln("<table class=entry>");
        scope(exit) outFile.writeln("</table>");

        foreach (rowNum, uint stoff; stringTableOffsets) {
            import std.string;
            import std.algorithm;
            import std.array;
            romFile.seek(offset + ttoff + stoff);
            wstring msg = romFile.parseString()
                .strip("\n 　")
                .array()
                .lineSplitter().join("<br>\n");
            if (msg == "") {
                //skip the line
            }
            else {
                outFile.writefln("<tr><td>%s</td><td class=entry>", rowNum);
                outFile.writeln(msg, "\n");
                outFile.writeln("</td></tr>\n");
            }
        }
    }
    
    writeln("generated ", outPath);
    return "";
}
// +/

