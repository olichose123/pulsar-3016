package;

import pulsar.Word16;

class Main {
    static function main() {
        trace("hello world");
        trace(new Word16(0x1234));
        trace(new Word16(0x12FF));
        var a:Word16 = 0x1111;
        trace(a);
        a.setFirstNibble(0xF);
        a.setSecondNibble(0xA);
        a.setThirdNibble(0xB);
        a.setFourthNibble(0xC);
        trace(a);
        a.setFirstByte(0x12);
        a.setSecondByte(0x34);
        trace(a);
        var b:Word16 = new Word16(0);
        b.setBit(3, true);
        trace(b);
    }
}
