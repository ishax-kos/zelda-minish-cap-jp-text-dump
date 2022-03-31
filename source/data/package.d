module data;

public import data.jp;
public import data.headings;


enum dumpVersion = "1.3.0";


wchar opCode(ubyte id, ubyte data = 0) {
    assert(id < 0x18);
    ushort id16 = cast(ushort) id << 8;
    return cast(wchar) (0xE000 + id16 | data);
}

enum OpCodes {
    tableNumber,
    messageNumber
}