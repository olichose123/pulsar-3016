package pulsar;

class Stack {
    public var contents(default, null):Array<Word16>;

    var stackDepth:Int;

    public function new(stackDepth:Int) {
        if (stackDepth <= 0) {
            throw new StackException("Stack depth must be greater than 0");
        }

        this.stackDepth = stackDepth;

        contents = new Array<Word16>();
    }

    public function push(value:Word16):Void {
        if (contents.length >= stackDepth) {
            throw new StackException("Stack overflow: Cannot push to full stack");
        }
        contents.push(value);
    }

    public function pop():Word16 {
        if (contents.length == 0) {
            throw new StackException("Stack underflow: No contents to pop");
        }
        return contents.pop();
    }

    public function reset():Void {
        contents.resize(0);
    }
}

class StackException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
