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
    outName ~= dumpVersionf!'-';

    string outPath = args[0].dirName.buildPath("output");
    if (!outPath.exists) mkdir(outPath);


    MmFile inputFile = new MmFile(inputPath);

    string fullOutputPath = buildPath(outPath, outName~".csv");

    File outFile = File(fullOutputPath, "wb");
    
    /// This is a "Byte order mark".
    // outFile.rawWrite(bomTable[BOM.utf16le].sequence);
    outFile.write(
        inputFile
            .parseTables()
            .formatCSV()
        // "output/aFile.html"
    );
    writeln("created ", fullOutputPath);
    // import data.jp;
    // outFile11.write();
}





// // +/