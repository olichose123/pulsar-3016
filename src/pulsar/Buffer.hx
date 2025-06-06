package pulsar;

class Buffer {
    public var contents(default, null):Array<Word16>;

    public function new(buffer_size:Int) {
        if (buffer_size <= 0) {
            throw "Buffer size must be greater than 0";
        }

        contents = new Array<Word16>();
        for (i in 0...buffer_size) {
            contents[i] = new Word16(0);
        }
    }

    public function write(value:Word16):Void {
        if (contents.length >= contents.length) {
            throw "Buffer overflow";
        }
        contents.push(value);
    }

    public function read():Word16 {
        if (contents.length == 0) {
            throw "Buffer underflow";
        }
        return contents.shift();
    }
}
