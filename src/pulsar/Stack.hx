package pulsar;

class Stack {
    public var contents(default, null):Array<Word16>;

    public function new(stack_depth:Int) {
        if (stack_depth <= 0) {
            throw "Stack depth must be greater than 0";
        }

        contents = new Array<Word16>();
        for (i in 0...stack_depth) {
            contents[i] = new Word16(0);
        }
    }

    public function push(value:Word16):Void {
        if (contents.length >= contents.length) {
            throw "Stack overflow";
        }
        contents.push(value);
    }

    public function pop():Word16 {
        if (contents.length == 0) {
            throw "Stack underflow";
        }
        return contents.pop();
    }
}
