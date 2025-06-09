package pulsar;

using StringTools;

abstract Word16(Int) to Int {
    static var reg_16bit:EReg = ~/^(0x)?([0-9a-fA-F]{4})$/i;
    static var reg_8bit:EReg = ~/^(0x)?([0-9a-fA-F]{2})$/i;

    public function new(value:Int) {
        this = value & 0xFFFF;
    }

    @:from
    static public function fromInt(value:Int):Word16 {
        return new Word16(value);
    }

    @:to
    public inline function toInt():Int {
        return this;
    }

    @:op(A + B)
    private inline function add(other:Word16):Word16 {
        return new Word16(this + cast other);
    }

    @:op(A - B)
    private inline function subtract(other:Word16):Word16 {
        return new Word16(this - cast other);
    }

    @:op(A * B)
    private inline function multiply(other:Word16):Word16 {
        return new Word16(this * cast other);
    }

    @:op(A / B)
    private inline function divide(other:Word16):Word16 {
        return new Word16(Std.int(this / cast other));
    }

    @:op(A % B)
    private inline function modulo(other:Word16):Word16 {
        return new Word16(cast(this % cast other));
    }

    @:op(A == B)
    private inline function equals(other:Word16):Bool {
        return this == cast other;
    }

    @:op(A != B)
    private inline function notEquals(other:Word16):Bool {
        return this != cast other;
    }

    @:op(A < B)
    private inline function lessThan(other:Word16):Bool {
        return this < cast other;
    }

    @:op(A <= B)
    private inline function lessThanOrEqual(other:Word16):Bool {
        return this <= cast other;
    }

    @:op(A > B)
    private inline function greaterThan(other:Word16):Bool {
        return this > cast other;
    }

    @:op(A >= B)
    private inline function greaterThanOrEqual(other:Word16):Bool {
        return this >= cast other;
    }

    @:op(A & B)
    private inline function bitwiseAnd(other:Word16):Word16 {
        return new Word16(this & cast other);
    }

    @:op(A | B)
    private inline function bitwiseOr(other:Word16):Word16 {
        return new Word16(this | cast other);
    }

    @:op(A ^ B)
    private inline function bitwiseXor(other:Word16):Word16 {
        return new Word16(this ^ cast other);
    }

    @:op(A << B)
    private inline function leftShift(other:Int):Word16 {
        return new Word16(this << (other & 0xF));
    }

    @:op(A >> B)
    private inline function rightShift(other:Int):Word16 {
        return new Word16(this >> (other & 0xF));
    }

    @:op(A >>> B)
    private inline function unsignedRightShift(other:Int):Word16 {
        return new Word16(this >>> (other & 0xF));
    }

    @:op(~a)
    private inline function bitwiseNot():Word16 {
        return new Word16(~this);
    }

    @:op(++a)
    private inline function increment():Word16 {
        return new Word16(++this);
    }

    @:op(a++)
    private inline function postIncrement():Word16 {
        var oldValue = this;
        this = new Word16(this + 1);
        return oldValue;
    }

    @:op(--a)
    private inline function decrement():Word16 {
        return new Word16(--this);
    }

    @:op(a--)
    private inline function postDecrement():Word16 {
        var oldValue = this;
        this = new Word16(this - 1);
        return oldValue;
    }

    public static function fromHex(hex:String):Word16 {
        if (reg_16bit.match(hex) || reg_8bit.match(hex)) {
            if (!hex.startsWith("0x") || !hex.startsWith("0X")) {
                hex = "0x" + hex;
            }
            var value = Std.parseInt(hex);
            return new Word16(value);
        }
        throw "Invalid hex format for Word16: " + hex;
    }

    public inline function toHex():String {
        return StringTools.hex(this, 4);
    }

    public inline function toString():String {
        return "Word16(" + toHex() + ")";
    }

    public inline function getFourthNibble():Int {
        return this & 0x0F;
    }

    public inline function getThirdNibble():Int {
        return (this >> 4) & 0x0F;
    }

    public inline function getSecondNibble():Int {
        return (this >> 8) & 0x0F;
    }

    public inline function getFirstNibble():Int {
        return (this >> 12) & 0x0F;
    }

    public inline function getSecondByte():Int {
        return this & 0xFF;
    }

    public inline function getFirstByte():Int {
        return (this >> 8) & 0xFF;
    }

    public inline function setFourthNibble(value:Int):Void {
        this = (this & 0xFFF0) | (value & 0x0F);
    }

    public inline function setThirdNibble(value:Int):Void {
        this = (this & 0xFF0F) | ((value & 0x0F) << 4);
    }

    public inline function setSecondNibble(value:Int):Void {
        this = (this & 0xF0FF) | ((value & 0x0F) << 8);
    }

    public inline function setFirstNibble(value:Int):Void {
        this = (this & 0x0FFF) | ((value & 0x0F) << 12);
    }

    public inline function setSecondByte(value:Int):Void {
        this = (this & 0xFF00) | (value & 0xFF);
    }

    public inline function setFirstByte(value:Int):Void {
        this = (this & 0x00FF) | ((value & 0xFF) << 8);
    }

    public inline function getBit(index:Int):Bool {
        if (index < 0 || index > 15) {
            throw "Index out of bounds for Word16: " + index;
        }
        return ((this >> index) & 1) == 1;
    }

    public inline function setBit(index:Int, value:Bool):Void {
        if (index < 0 || index > 15) {
            throw "Index out of bounds for Word16: " + index;
        }
        if (value) {
            this = this | (1 << index);
        } else {
            this = this & ~(1 << index);
        }
    }
}
