import std.mmfile;
import std.conv;
import std.format;
import std.path;
import std.file;
import std.stdio: File;
import std.encoding;
import std.stdio;

import data;
import parsing;
import output;

 
void main(string[] args) {
    string inputPath = "raw/rom.gba";
    string outName = "mcTextDump";
    
    if (args.length >= 2) {
        inputPath = args[1];
        outName = inputPath.baseName.stripExtension
            ~"_text"; 
    }

    /// add version to file name
    outName ~= dumpVersionf!'-'~".html";

    string outPath = args[0].dirName.buildPath("output");
    if (!outPath.exists) mkdir(outPath);


    MmFile inputFile = new MmFile(inputPath);

    File outFile = File(buildPath(outPath, outName), "wb");
    
    /// This is a "Byte order mark".
    // outFile.rawWrite(bomTable[BOM.utf16le].sequence);
    outFile.write(
        inputFile
            .parseTables()
            .formatHTML()
        // "output/aFile.html"
    );
    writeln("created ", buildPath(outPath, outName));
    // import data.jp;
    // outFile11.write();
}





// // +/