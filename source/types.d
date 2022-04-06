module types;

import std.sumtype;
public import std.sumtype: match;


alias String_t = string;
alias Char_t = char;


struct Table {
    string name; 
    string description;
    uint number; 
    MessageEntry[] messages;
}


struct MessageEntry {
    uint number; 
    ColorText[] text;
}

struct ColorText {
    ubyte palette;
    Text[] text;
    this(T)(ubyte b, T stuff) {
        palette = b;
        static if (is(T == Text)) {
            text ~= stuff;
        }
        else {
            text ~= Text(stuff);
        }
    }

    void append(String_t str) {
        import std.stdio;
        
        if (text.length == 0) {text ~= Text(str);}
        else {
            text[$-1].match!(
                (ref String_t myStr) {
                    // writeln("string ",str);
                    myStr ~= str;},
                (ref TextOption) {
                    // writeln("option ",str);
                    text ~= Text(str);
                }
            );
        }
    }
}
struct TextOption {
    immutable ubyte table;
    immutable ubyte message;
    enum close = TextOption(0xFF, 0xFF);
}

String_t plainText(ColorText[] text) {
    import std.algorithm: fold;
    import std.array: array;
    String_t accum;
    foreach (colT; text) {
        foreach (Text msg; colT.text) {
            accum ~= msg.match!(
                (String_t s) => s,
                (TextOption t) => cast(String_t)""
            );
        }
    }
    return accum;
}


alias Text = SumType!(TextOption, String_t);


unittest {
    import std.stdio: writeln;
    MessageEntry msg = MessageEntry(0, [
        ColorText(0,Text("foo")), 
        ColorText(0,Text("bar")), 
        ColorText(0,Text("baz"))
    ]);
    writeln(msg.text.plainText);
}


unittest {
    ColorText ct;
    ct.append("foo");
    ct.append("bar");
    ct.append("baz");
    assert([ct].plainText == "foobarbaz", [ct].plainText);
}