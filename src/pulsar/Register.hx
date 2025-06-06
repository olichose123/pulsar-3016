package pulsar;

class Register {
    public var value(default, null):Word16;

    public function new() {
        this.value = 0;
    }

    public function setValue(newValue:Word16):Void {
        this.value = newValue;
    }

    public function getValue():Word16 {
        return this.value;
    }
}
