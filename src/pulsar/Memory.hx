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
            throw new MemoryException("Address out of bounds: " + address);
        }
        data[address] = value;
    }

    public function setValues(startAddress:Int, values:Array<Word16>):Void {
        for (i in 0...values.length) {
            if (startAddress + i < 0xFFFF) {
                data[startAddress + i] = values[i];
            }
        }
    }

    public function clearValues(startAddress:Int, count:Int):Void {
        for (i in 0...count) {
            if (startAddress + i < 0xFFFF) {
                data[startAddress + i] = new Word16(0);
            }
        }
    }

    public function reset():Void {
        for (i in 0...0xFFFF) {
            data[i] = new Word16(0);
        }
    }

    public function getValue(address:Int):Word16 {
        if (address < 0 || address >= 0xFFFF) {
            throw new MemoryException("Address out of bounds: " + address);
        }
        return data[address];
    }

    public function writeBuffer(startAddress:Word16, buffer:Buffer):Void {
        for (i in 0...buffer.contents.length) {
            if (startAddress + i < 0xFFFF) {
                data[startAddress + i] = buffer.contents[i];
            }
        }
    }

    public function readToBuffer(startAddress:Word16, buffer:Buffer):Void {
        for (i in 0...buffer.size) {
            if (startAddress + i < 0xFFFF) {
                buffer.contents[i] = data[startAddress + i];
            }
        }
    }
}

class MemoryException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
