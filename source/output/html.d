module output.html;

import std.sumtype;
import std.range: repeat;
import std.format;
import std.string;
import std.algorithm: map, all;
import std.array: array;
import std.conv;
import std.file;

import types;
import data;


String_t formatHTML(Table[] structuredData) {
    return 
    "<!DOCTYPE html>\n" ~
    "html".tag(
        "head".tag(
            "style".tag(
                readText!String_t("include/style.css").to!String_t
            )
        ),
        "body".tag(
            "div class=hideBarContainer".tag(
                // "<input class=hideBar type=checkbox>",
                "div class=hideBar".tag(
                    "ul class=vMenu".tag(
                        structuredData.map!(
                            table => "li".tag(
                                table.number.format!"a class=vMenu href=#t%s".tag(
                                    "h3".tag(table.name),
                                    "p class=hint".tag(table.description)
                                )
                            )
                        )
                    )
                )
            ),
            "div class=page".tag(
                "p".tag(dumpVersionf!'.'.to!String_t),
                "div id=allTables".tag(
                    structuredData.map!tableToTag
                )
            )
        )
    ).toStringHTML;
}

Tag tableToTag(Table table) {
    uint t = 0;
    return table.number.format!"div class=trTable id=table%s".tag(
        "h3".tag(table.name.to!String_t),
        "h4".tag(table.description.to!String_t),
        "table class=trTable".tag(
            table.messages.map!(
                (TextBox tb) {
                    uint m = 0;
                    return "tr".tag(
                        format!"td id=table%sm%s"(t,m++).tag(format!"%d"(t++)),
                        "td".msgToTag(tb.text)
                    );
                }
                    // : "tr".tag(`("tr".tag("td".tag(format!"%d <hr>"(i++))))`w)
            )//.array
        )
    );
}

 
struct Tag {
    string tag;
    Contents_t[] contents;
}


String_t toStringHTML(Tag thisTag) {
    with (thisTag) {
        static indent = 0;
        
        String_t ind() {return " ".repeat(4*indent).join;}

        String_t outStr = ind ~ format!"<%s>\n"(tag);
        outStr ~= contents.map!((a) {
            indent += 1; scope(exit) indent -= 1; 
            return a.match!(
                (Tag t) => t.toStringHTML,
                (String_t ws) => ws.lineSplitter.map!(a =>ind ~ a).join('\n'),
                (Pre p) => "<pre>"~p.text~"</pre>"

            );
        }).join('\n');
        outStr ~= "\n" ~ ind ~ format!"</%s>"(tag.split[0]);
        return outStr;
    }
}



import std.range: isInputRange, ElementType;

enum isContentsType(T) = __traits(compiles, {
    T t;
    Contents_t(t);
});
//staticIndexOf!(T, TemplateArgsOf!Contents_t) != -1;
enum isContentsRange(T) = 
    isInputRange!T && 
    isContentsType!(ElementType!T);
// enum isWhatever(T) = isContentsType!T || isContentsRange!T;


unittest {
    import std.stdio;
    assert(isContentsType!Pre);
    assert(isContentsType!String_t);
    assert(isContentsType!Tag);
    assert(!isContentsType!int);
}


import std.traits: TemplateArgsOf;
import std.meta;
pragma(inline)
Tag tag(T...)(string name, T mixedContents)
if (allSatisfy!(templateOr!(isContentsType,isContentsRange), T))
{

    Contents_t[] contents;
    

    foreach (c; mixedContents) {
        alias C = typeof(c);
        static if (isContentsType!C)
            contents ~= Contents_t(c);
        else static if (isContentsRange!C)
            foreach (c_; c)
                contents ~= Contents_t(c_);
        else assert(0);
    }

    return Tag(name, contents);
}

alias Contents_t = SumType!(Tag, String_t, Pre);


struct Pre {
    String_t text;
}


string tagPalette(uint val) {
    import std.format;
    if (val < 16) return format!"c%X"(val);
    else return "cERROR";
}


Tag msgToTag(string tagName, ColoredMsg[] colorMsgArray) {
    import std.functional: compose;
    import std.uni: isWhite;
    import std.algorithm: find;

    if (colorMsgArray.length == 0)
        return tag(tagName ~ " class=trNull","<hr>");
    else {
        String_t[] outmsg;
        foreach(colmsg; colorMsgArray) {
            // foreach (match; matchAll!"🔎[0-9]{1,3},[0-9]{1,3}▶") {
            //     auto rem = colmsg.find("🔎");
            //     if (rem == []) break;
            //     else {
            //         rem.find
            //     }
            // }

            String_t outm;
                if (colmsg.palette < 16) 
                    outm ~= colmsg.palette.format!"<span class=c%X>"();
                else 
                    outm ~= "<span class=cERROR>";
                outm ~= colmsg.text;
                outm ~= "</span>";
            // }
            outmsg ~= outm;
        }
        return tag(tagName ~ " class=trMessage", Pre(outmsg.join.strip));
    }
}