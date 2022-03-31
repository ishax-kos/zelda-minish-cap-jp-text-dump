module types;

import std.sumtype;
public import std.sumtype: match;

struct Table {
    string name; 
    string description;
    uint number; 
    TextBox[] messages;
}


struct TextBox {
    uint number; 
    ColoredMsg[] text;
}


wstring plainText(ColoredMsg[] text) {
    import std.algorithm: fold;
    import std.array: array;
    wstring accum;
    foreach (ColoredMsg msg; text) { accum ~= msg.text; }
    return accum;
}


struct ColoredMsg {
    ubyte palette;
    wstring text;
}




unittest {
    import std.stdio: writeln;
    TextBox msg = TextBox(0, [ColoredMsg(0,"foo"), ColoredMsg(0,"bar"), ColoredMsg(0,"baz")]);
    writeln(msg.text.plainText);
}
