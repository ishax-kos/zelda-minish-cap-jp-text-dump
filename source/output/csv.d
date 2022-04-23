module output.csv;

import types;

import std.format;
import std.algorithm: map;
import std.array;
import std.string;

String_t formatCSV (Table[] structuredData) {
    return 
    "Name,Context,Japanese or Original Text,Translation\n" ~
    structuredData.map!((Table table) =>
        table.name ~ "\n" ~
        table.messages.map!((MessageEntry meEn) {
            auto text = meEn.text.plainText().strip();
            if (text.length != 0) {
                return ",,\"" ~ meEn.text.plainText().strip().replace("\"","'") ~ "\"\n";
            }
            else {return "";}
        }).join()
    ).join();
}