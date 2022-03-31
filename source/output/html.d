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
    doc ~= "html".tag(
        "head".tag(
            "style".tag(
                import("style.css").to!wstring
            )
        ),
        "body".tag(
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
                                        // : "tr".tag(`("tr".tag("td".tag(format!"%d <hr>"w(i++))))`w)
                                )//.array11
                            )
                        );
                    }
                )//.array
            )
        )
    );
    
    

    return "<!DOCTYPE html>\n"w ~
    doc.map!(toStringHTML).array.join('\n');
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
                (wstring ws) => ws.lineSplitter.join("\n" ~ ind),
                (Pre p) => "<pre>"~p.text~"</pre>"

            );
        }).join('\n');
        outStr ~= "\n" ~ ind ~ format!"</%s>"w(tag.split[0]);
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

alias Contents_t = SumType!(Tag, wstring, Pre);


struct Pre {
    wstring text;
}


string tagPalette(uint val) {
    import std.format;
    if (val < 16) return format!"c%X"(val);
    else return "cERROR";
}


Tag msgToTag(string tagName, ColoredMsg[] colorMsgArray) {
    import std.functional: compose;
    import std.uni: isWhite;


    if (colorMsgArray.length == 0) return tagName.split[0].tag(Pre("<hr>"w));

    wstring outmsg;
    foreach(colmsg; colorMsgArray) {
        if (colmsg.text == "") {}
        else if (colmsg.text.all!isWhite) {
            outmsg ~= colmsg.text;
        }
        else {
            outmsg ~= colmsg.palette.format!"<span class=c%X>"w();
            outmsg ~= colmsg.text;
            outmsg ~= "</span>"w;
        }
        
    }
    return tagName.tag(Pre(outmsg.strip));
}