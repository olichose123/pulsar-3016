package pulsar;

class Memory {
    public var data(default, null):Array<Word16>;

    public function new() {
        data = new Array<Word16>();
        for (i in 0...0xFFFF) {
            data[i] = new Word16(0);
        }
    }

    public function setValue(address:Int, value:Word16):Void {
        if (address < 0 || address >= 0xFFFF) {
            throw "Address out of bounds: " + address;
        }
        data[address] = value;
    }

    public function getValue(address:Int):Word16 {
        if (address < 0 || address >= 0xFFFF) {
            throw "Address out of bounds: " + address;
        }
        return data[address];
    }
}
