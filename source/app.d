import std.mmfile;
import std.conv;
import std.format;
import std.path;
import std.file;

// import data;

immutable dumpVersion = [1, 2, 0];
 
void main(string[] args) {
    string inputPath = "raw/rom.gba";
    string outName = "mcTextDump"
                        ~dumpVersion.format!"_v%(%s-%)" // add version to file name
                        ~".html";
    uint textAddress = 0x9B1A30;
    
    if (args.length >= 2) {
        inputPath = args[1];
        outName = inputPath.baseName.stripExtension
            ~"_text"
            ~dumpVersion.format!"_v%(%s-%)"
            ~".html";    
    }
    if (args.length >= 3) textAddress = args[2].parse!uint;
    string outPath = args[0].dirName.buildPath("output");
    if (!outPath.exists) mkdir(outPath);


    MmFile inputFile = new MmFile(inputPath);

    write(
        buildPath(outPath, outName),
        inputFile
            .parseStringJP()
            .formatHTML()
    );
}





// // +/