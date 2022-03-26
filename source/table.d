module table;


struct Table {
    string name; 
    uint number; 
    TextBox[] messages;
}


struct ColoredMsg {
    uint color; 
    uint colorBg;
    dstring text;
}


struct TextBox {
    uint number; 
    ColoredMsg[] text;
    
    dstring plainText() {
        import std.algorithm: fold;
        import std.array: array;
        dstring accum;
        foreach (ColoredMsg msg; text) { accum ~= msg.text; }
        return accum;
    }
}


unittest {
    import std.stdio: writeln;
    TextBox msg = TextBox(0, [ColoredMsg(0,0,"foo"), ColoredMsg(0,0,"bar"), ColoredMsg(0,0,"baz")]);
    writeln(msg.plainText);
}
