package pulsar;

class Processor {
    public var programCounter(default, null):Word16;
    public var addressStack(default, null):Stack;
    public var memories(default, null):Array<Memory>;
    public var registers(default, null):Array<Register>;
    public var buffers(default, null):Array<Buffer>;
    public var timers(default, null):Array<Word16>;

    public function new(stackDepth:Int, registerCount:Int, memoryCount:Int,
            bufferSizes:Array<Int>, timerCount:Int) {
        if (stackDepth <= 0) {
            throw new PulsarException("Stack depth must be greater than 0");
        }

        if (registerCount <= 0) {
            throw new PulsarException("Register count must be greater than 0");
        }

        if (memoryCount <= 0) {
            throw new PulsarException("Memory count must be greater than 0");
        }

        if (bufferSizes.length == 0) {}

        this.programCounter = new Word16(0);
        this.addressStack = new Stack(stackDepth);
        this.memories = new Array<Memory>();
        for (i in 0...memoryCount) {
            this.memories.push(new Memory());
        }

        this.registers = new Array<Register>();
        for (i in 0...registerCount) {
            this.registers.push(new Register());
        }

        this.buffers = new Array<Buffer>();
        for (size in bufferSizes) {
            if (size <= 0) {
                throw new PulsarException("Buffer size must be greater than 0");
            }
            this.buffers.push(new Buffer(size));
        }

        this.timers = new Array<Word16>();
        this.timers.resize(timerCount);
    }

    public function getRegister(index:Word16):Register {
        if (index < 0 || index >= registers.length) {
            throw new PulsarException("Invalid register index: " + index);
        }
        return registers[index];
    }

    public function getProgramCounter():Word16 {
        return this.programCounter;
    }

    public function setProgramCounter(value:Word16):Void {
        this.programCounter = value;
    }

    public function getBuffer(index:Word16):Buffer {
        if (index < 0 || index >= buffers.length) {
            throw new PulsarException("Invalid buffer index: " + index);
        }
        return buffers[index];
    }

    public function getMemory(index:Word16):Memory {
        if (index < 0 || index >= memories.length) {
            throw new PulsarException("Invalid memory index: " + index);
        }
        return memories[index];
    }

    public function getTimerValue(index:Word16):Word16 {
        if (index < 0 || index >= timers.length) {
            throw new PulsarException("Invalid timer index: " + index);
        }
        return timers[index];
    }

    public function setTimerValue(index:Word16, value:Word16):Void {
        if (index < 0 || index >= timers.length) {
            throw new PulsarException("Invalid timer index: " + index);
        }
        timers[index] = value;
    }
}
