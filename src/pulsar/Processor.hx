package pulsar;

import pulsar.Stack.StackException;

import haxe.ds.StringMap;

class Processor {
    public var programCounter(default, null):Word16;
    public var addressStack(default, null):Stack;
    public var memories(default, null):Array<Memory>;
    public var registers(default, null):Array<Register>;
    public var buffers(default, null):Array<Buffer>;
    public var timers(default, null):Array<Word16>;

    public function new(stackDepth:Int, registerCount:Int, memoryCount:Int,
            bufferSizes:Array<Word16>, timerCount:Int) {
        if (stackDepth <= 0) {
            throw new PulsarException("Stack depth must be greater than 0");
        }

        if (registerCount <= 0) {
            throw new PulsarException("Register count must be greater than 0");
        }

        if (memoryCount <= 0) {
            throw new PulsarException("Memory count must be greater than 0");
        }

        if (bufferSizes.length == 0) {
            throw new PulsarException("At least one buffer size must be specified");
        }

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

    public function getMethodFromOpcode(opcode:Word16):Dynamic {
        var firstNibble = opcode.getFirstNibble();
        var secondNibble = opcode.getSecondNibble();

        switch (firstNibble) {
            case 0xA:
                switch (secondNibble) {
                    case 0x1: return instructionJump;
                    case 0x2: return instructionCall;
                    case 0xE: return instructionReturn;
                    case 0xA: return instructionJumpToAddress;
                    case 0xB: return instructionCallToAddress;
                    default: throw new PulsarException("Unknown subroutine instruction");
                }
            case 0xB:
                switch (secondNibble) {
                    case 0x1: return instructionMoveValue;
                    case 0x2: return instructionSetValue;
                    case 0x3: return instructionAddValue;
                    case 0x4: return instructionSubtractValue;
                    case 0x5: return instructionMultiplyValue;
                    case 0x6: return instructionDivideValue;
                    case 0x7: return instructionModuloValue;
                    case 0x8: return instructionOrValue;
                    case 0x9: return instructionAndValue;
                    case 0xA: return instructionXorValue;
                    case 0xB: return instructionNotValue;
                    case 0xC: return instructionShiftLeftValue;
                    case 0xD: return instructionShiftRightValue;
                    case 0xE: return instructionRandomize;
                    default: throw new PulsarException("Unknown arithmetic instruction");
                }
            case 0xC:
                switch (secondNibble) {
                    case 0x1: return instructionSkipIfEqual;
                    case 0x2: return instructionSkipIfNotEqual;
                    case 0x3: return instructionSkipIfGreaterThan;
                    case 0x4: return instructionSkipIfLessThan;
                    default: throw new PulsarException("Unknown logic instruction");
                }
            case 0xD:
                switch (secondNibble) {
                    case 0x1: return instructionPushToBuffer;
                    case 0x2: return instructionShiftFromBuffer;
                    case 0x3: return instructionPeekFromBuffer;
                    case 0xE: return instructionClearBuffer;
                    case 0x4: return instructionBufferSize;
                    default: throw new PulsarException("Unknown buffer instruction");
                }
            case 0xE:
                switch (secondNibble) {
                    case 0x1: return instructionWriteBufferToMemory;
                    case 0x2: return instructionReadBufferFromMemory;
                    default: throw new PulsarException("Unknown memory instruction");
                }
            case 0xF:
                switch (secondNibble) {
                    case 0x1: return instructionSetTimer;
                    case 0x2: return instructionGetTimer;
                    default: throw new PulsarException("Unknown timer instruction");
                }
            default:
                throw new PulsarException("Unknown opcode: " + opcode.toString());
        }
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

    public function reset():Void {
        programCounter = 0;
        addressStack.reset();
        for (memory in memories) {
            memory.reset();
        }
        for (register in registers) {
            register.setValue(0);
        }
        for (buffer in buffers) {
            buffer.clear();
        }
        for (i in 0...timers.length) {
            timers[i] = new Word16(0);
        }
    }

    // 0xAx subroutine instructions

    /**
     * Jump to an address specifeid in register a.
     * 0xA1a0 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionJump(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var register = getRegister(registerIndex);
        setProgramCounter(register.getValue());
    }

    /**
     * Jump to an address specified in word b.
     * 0xAA00 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionJumpToAddress(wordA:Word16, wordB:Word16):Void {
        setProgramCounter(wordB);
    }

    /**f
     * Call a subroutine at the address specified in register a.
     * 0xA2a0 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionCall(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var register = getRegister(registerIndex);
        addressStack.push(getProgramCounter());
        setProgramCounter(register.getValue());
    }

    /**
     * Call a subroutine at the address specified in word b.
     * 0xAB00 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionCallToAddress(wordA:Word16, wordB:Word16):Void {
        addressStack.push(getProgramCounter());
        setProgramCounter(wordB);
    }

    /**
     * Return from a subroutine, restoring the program counter to the address
     * stored in the address stack.
     * 0xAE00 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionReturn(wordA:Word16, wordB:Word16):Void {
        var returnAddress;
        try {
            returnAddress = addressStack.pop();
        } catch (e:StackException) {
            throw new ProgramException("End of program.");
        }
        setProgramCounter(returnAddress);
        programCounter += 2;
    }

    // 0xBx Arithmetic instructions

    /**
     * Set the value of register a to the value in register b.
     * 0xB1ab 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionMoveValue(wordA:Word16, wordB:Word16):Void {
        var registerAIndex = wordA.getThirdNibble();
        var registerBIndex = wordA.getFourthNibble();
        var registerA = getRegister(registerAIndex);
        var registerB = getRegister(registerBIndex);
        registerA.setValue(registerB.getValue());
        programCounter += 2;
    }

    /**
     * Set the value of register a to the value XXXX.
     * 0xB2a0 XXXX
     * @param wordA
     * @param wordB
    **/
    public function instructionSetValue(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var value = wordB;
        var register = getRegister(registerIndex);
        register.setValue(value);
        programCounter += 2;
    }

    /**
     * Add the values of registers x and y, and store the result in register z.
     * 0xB3zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionAddValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() + registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Subtract the value of register y from the value of register x,
     * and store the result in register z.
     * 0xB4zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionSubtractValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() - registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Multiply the values of registers x and y, and store the result in register z.
     * 0xB5zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionMultiplyValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() * registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Divide the value of register x by the value of register y,
     * and store the result in register z.
     * 0xB6zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionDivideValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        if (registerY.getValue() == 0) {
            throw new InstructionException("Division by zero");
        }

        var result = Math.floor(registerX.getValue() / registerY.getValue());
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Calculate the modulo of the value of register x by the value of register y,
     * and store the result in register z.
     * 0xB7zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionModuloValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        if (registerY.getValue() == 0) {
            throw new InstructionException("Division by zero");
        }

        var result = registerX.getValue() % registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise OR operation between the values of registers x and y,
     * and store the result in register z.
     * 0xB8zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionOrValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() | registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise AND operation between the values of registers x and y,
     * and store the result in register z.
     * 0xB9zx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionAndValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() & registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise XOR operation between the values of registers x and y,
     * and store the result in register z.
     * 0xBAzx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionXorValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() ^ registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise NOT operation on the value of register x,
     * and store the result in register z.
     * 0xBBzx 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionNotValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerZ = getRegister(registerZIndex);

        // Perform bitwise NOT operation
        var result = ~registerX.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Shift the value of register x left by one bit,
     * and store the result in register z.
     * 0xBCzx 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionShiftLeftValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerZ = getRegister(registerZIndex);

        // Shift left by one bit
        var result = registerX.getValue() << 1;
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Shift the value of register x right by one bit,
     * and store the result in register z.
     * 0xBDzx 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionShiftRightValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerZ = getRegister(registerZIndex);

        // Shift right by one bit
        var result = registerX.getValue() >> 1;
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Randomize the value of register z
     * by generating a random number between the values of registers x and y.
     * 0xBEzx y000
     * @param wordA
     * @param wordB
    **/
    public function instructionRandomize(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getThirdNibble();
        var registerXIndex = wordA.getFourthNibble();
        var registerYIndex = wordB.getFirstNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        // Generate a random number between the values of registers X and Y
        var minValue = Math.min(registerX.getValue(), registerY.getValue());
        var maxValue = Math.max(registerX.getValue(), registerY.getValue());
        var randomValue = Math.floor(Math.random() * (maxValue - minValue + 1)) + minValue;

        registerZ.setValue(cast randomValue);
        programCounter += 2;
    }

    // 0xCx Logic instructions

    /**
     * Skip the next instruction if the value in register x is equal to the value in register y.
     * 0xC1xy 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfEqual(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getThirdNibble();
        var registerYIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        if (registerX.getValue() == registerY.getValue()) {
            programCounter += 4;
        } else {
            programCounter += 2;
        }
    }

    /**
     * Skip the next instruction if the value in register x is not equal to the value in register y.
     * 0xC2xy 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfNotEqual(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getThirdNibble();
        var registerYIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);

        if (registerX.getValue() != registerY.getValue()) {
            programCounter += 4;
        } else {
            programCounter += 2;
        }
    }

    /**
     * Skip the next instruction if the value in register x is greater than the value in register y.
     * 0xC3xy 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfGreaterThan(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getThirdNibble();
        var registerYIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);

        if (registerX.getValue() > registerY.getValue()) {
            programCounter += 4;
        } else {
            programCounter += 2;
        }
    }

    /**
     * Skip the next instruction if the value in register x is less than the value in register y.
     * 0xC4xy 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfLessThan(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getThirdNibble();
        var registerYIndex = wordA.getFourthNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);

        if (registerX.getValue() < registerY.getValue()) {
            programCounter += 4;
        } else {
            programCounter += 2;
        }
    }

    // 0xDx Buffer instructions

    /**
     * Move the value from register x to buffer b.
     * 0xD1xb 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionPushToBuffer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);

        buffer.write(register.getValue());
        programCounter += 2;
    }

    /**
     * Move the value from buffer b to register x.
     * 0xD2xb 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionShiftFromBuffer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);
        register.setValue(buffer.read());
        programCounter += 2;
    }

    /**
     * Peek the first value from buffer b without removing it,
     * and store it in register x.
     * 0xD3xb 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionPeekFromBuffer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);

        // Peek the first value without removing it
        register.setValue(buffer.contents[0]);
        programCounter += 2;
    }

    /**
     * Clear the contents of buffer b.
     * 0xDEb0 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionClearBuffer(wordA:Word16, wordB:Word16):Void {
        var bufferIndex = wordA.getThirdNibble();
        var buffer = getBuffer(bufferIndex);

        buffer.clear();
        programCounter += 2;
    }

    /**
     * Store the size of buffer b in register r.
     * 0xD4xb 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionBufferSize(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);

        // Store the size of the buffer in the register
        register.setValue(buffer.size);
        programCounter += 2;
    }

    // 0xEx Memory instructions

    /**
     * Write the contents of buffer b to memory m at the address specified by x.
     * 0xE1mb x000
     * @param wordA
     * @param wordB
    **/
    public function instructionWriteBufferToMemory(wordA:Word16, wordB:Word16):Void {
        var memoryIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var startAddressRegisterIndex = wordB.getFirstNibble();
        var memory = getMemory(memoryIndex);
        var buffer = getBuffer(bufferIndex);
        var startAddress = getRegister(startAddressRegisterIndex).getValue();

        memory.writeBuffer(new Word16(startAddress), buffer);
        programCounter += 2;
    }

    /**
     * Read the contents of memory m at the address specified by x into buffer b.
     * 0xE2mb x000
     * @param wordA
     * @param wordB
    **/
    public function instructionReadBufferFromMemory(wordA:Word16, wordB:Word16):Void {
        var memoryIndex = wordA.getThirdNibble();
        var bufferIndex = wordA.getFourthNibble();
        var startAddressRegisterIndex = wordB.getFirstNibble();
        var memory = getMemory(memoryIndex);
        var buffer = getBuffer(bufferIndex);
        var startAddress = getRegister(startAddressRegisterIndex).getValue();

        memory.readToBuffer(new Word16(startAddress), buffer);
        programCounter += 2;
    }

    // 0xFx Timer instructions

    /**
     * Set a timer with the value from register r.
     * 0xF1rt 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionSetTimer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var timerIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var timerValue = register.getValue();

        setTimerValue(timerIndex, timerValue);
        programCounter += 2;
    }

    /**
     * Get the value of a timer and store it in register r.
     * 0xF2rt 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionGetTimer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getThirdNibble();
        var timerIndex = wordA.getFourthNibble();
        var register = getRegister(registerIndex);
        var timerValue = getTimerValue(timerIndex);

        register.setValue(timerValue);
        programCounter += 2;
    }

    public function runOnce():Void {
        var wordA = getMemory(0).getValue(programCounter);
        var wordB = getMemory(0).getValue(programCounter + 1);

        var instructionMethod;
        try {
            instructionMethod = getMethodFromOpcode(wordA);
        } catch (e:PulsarException) {
            throw new ProgramException("Invalid instruction at address " + programCounter + ": "
                + e.message
            );
        }

        instructionMethod(wordA, wordB);

        if (programCounter + 2 > 0xFFFF) {
            throw new ProgramException("Program counter at end of main memory space.");
        }
    }

    public function run():Void {
        while (true) {
            try {
                runOnce();
            } catch (e:ProgramException) {
                trace("Program terminated: " + e.message);
                return;
            } catch (e:PulsarException) {
                trace("Error during execution: " + e.message);
                return;
            }
        }
    }

    public function decrementTimers():Void {
        for (i in 0...timers.length) {
            if (timers[i] > 0) {
                timers[i]--;
            }
        }
    }
}

class InstructionException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}

class ProgramException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
