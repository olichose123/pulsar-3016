package pulsar;

class Buffer {
    public var contents(default, null):Array<Word16>;

    public var size(default, null):Int;

    public function new(bufferSize:Int) {
        if (bufferSize <= 0) {
            throw new BufferException("Buffer size must be greater than 0");
        }

        this.size = bufferSize;

        contents = new Array<Word16>();
    }

    public function write(value:Word16):Void {
        if (contents.length >= size) {
            throw new BufferException("Buffer overflow: Cannot write to full buffer");
        }
        contents.push(value);
    }

    public function read():Word16 {
        if (contents.length == 0) {
            throw new BufferException("Buffer underflow: No contents to read");
        }
        return contents.shift();
    }

    public function clear():Void {
        contents.resize(0);
    }
}

class BufferException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
