module output.html;


string formatHTML(string str) {return str~",,,";}


//+
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


