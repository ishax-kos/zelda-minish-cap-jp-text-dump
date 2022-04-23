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
import types;

 
void main(string[] args) {
    string inputPath = "raw/rom.gba";
    string outName = "mcTextDump";
    string outputType = "html";
    if (args.length >= 2) {
        inputPath = args[1];
        outName = inputPath.baseName.stripExtension
            ~"_text"; 
    }
    if (args.length >= 3) {
        outputType = args[2];
        outName = inputPath.baseName.stripExtension
            ~"_text"; 
    }


     auto formatFunc = () {
        final switch (outputType) {
            case "html":
                outName ~= dumpVersionf!'-' ~ "." ~ outputType;
                return &formatHTML;
            case "csv":
                outName ~= dumpVersionf!'-' ~ "." ~ outputType;
                return &formatCSV;
        }
    }();
    /// add version to file name
    

    string outPath = args[0].dirName.buildPath("output");
    if (!outPath.exists) mkdir(outPath);


    MmFile inputFile = new MmFile(inputPath);

    string fullOutputPath = buildPath(outPath, outName);

    File outFile = File(fullOutputPath, "wb");
    
    /// This is a "Byte order mark".
    // outFile.rawWrite(bomTable[BOM.utf16le].sequence);
    outFile.write(
        formatFunc(inputFile.parseTables())
        // "output/aFile.html"
    );
    writeln("created ", fullOutputPath);
    // import data.jp;
    // outFile11.write();
}





// // +/