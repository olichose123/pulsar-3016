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

    // 0xAx subroutine instructions

    /**
     * Jump to an address specifeid in register RX.
     * 0xA1RX 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionJump(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var register = getRegister(registerIndex);
        setProgramCounter(register.getValue());
    }

    /**
     * Call a subroutine at the address specified in register RX.
     * 0xA2RX 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionCall(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var register = getRegister(registerIndex);
        addressStack.push(getProgramCounter());
        setProgramCounter(register.getValue());
    }

    /**
     * Return from a subroutine, restoring the program counter to the address
     * stored in the address stack.
     * 0xAE00 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionReturn(wordA:Word16, wordB:Word16):Void {
        var returnAddress = addressStack.pop();
        setProgramCounter(returnAddress);
        programCounter += 2;
    }

    // 0xBx Arithmetic instructions

    /**
     * Set the value of register RX to the value in register RY.
     * 0xB1RX RY00
     * @param wordA
     * @param wordB
    **/
    public function instructionMoveValue(wordA:Word16, wordB:Word16):Void {
        var originRegisterIndex = wordA.getSecondNibble();
        var destinationRegisterIndex = wordB.getFirstNibble();
        var originRegister = getRegister(originRegisterIndex);
        var destinationRegister = getRegister(destinationRegisterIndex);
        destinationRegister.setValue(originRegister.getValue());
        programCounter += 2;
    }

    /**
     * Set the value of register RX to the value AAAA.
     * 0xB2RX AAAA
     * @param wordA
     * @param wordB
    **/
    public function instructionSetValue(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var value = wordB;
        var register = getRegister(registerIndex);
        register.setValue(value);
        programCounter += 2;
    }

    /**
     * Add the values of registers RX and RY, and store the result in register RZ.
     * 0xB3RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionAddValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() + registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Subtract the value of register RY from the value of register RX,
     * and store the result in register RZ.
     * 0xB4RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionSubtractValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();

        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() - registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Multiply the values of registers RX and RY, and store the result in register RZ.
     * 0xB5RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionMultiplyValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() * registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Divide the value of register RX by the value of register RY,
     * and store the result in register RZ.
     * 0xB6RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionDivideValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        if (registerY.getValue() == 0) {
            throw new InstructionException("Division by zero");
        }

        var result = registerX.getValue() / registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Calculate the modulo of the value of register RX by the value of register RY,
     * and store the result in register RZ.
     * 0xB7RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionModuloValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
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
     * Perform a bitwise OR operation between the values of registers RX and RY,
     * and store the result in register RZ.
     * 0xB8RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionOrValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() | registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise AND operation between the values of registers RX and RY,
     * and store the result in register RZ.
     * 0xB9RZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionAndValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() & registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise XOR operation between the values of registers RX and RY,
     * and store the result in register RZ.
     * 0xBARZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionXorValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        var result = registerX.getValue() ^ registerY.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Perform a bitwise NOT operation on the value of register RX,
     * and store the result in register RZ.
     * 0xBBRZ RX00
     * @param wordA
     * @param wordB
    **/
    public function instructionNotValue(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerZ = getRegister(registerZIndex);

        var result = ~registerX.getValue();
        registerZ.setValue(result);
        programCounter += 2;
    }

    /**
     * Shift the value of register RX left by one bit,
     * and store the result in register RY.
     * 0xBCRY RX00
     * @param wordA
     * @param wordB
    **/
    public function instructionShiftLeftValue(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var targetRegisterIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var targetRegister = getRegister(targetRegisterIndex);

        var result = register.getValue() << 1;
        targetRegister.setValue(result);
        programCounter += 2;
    }

    /**
     * Shift the value of register RX right by one bit,
     * and store the result in register RY.
     * 0xBDRY RX00
     * @param wordA
     * @param wordB
    **/
    public function instructionShiftRightValue(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var targetRegisterIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var targetRegister = getRegister(targetRegisterIndex);

        var result = register.getValue() >> 1;
        targetRegister.setValue(result);
        programCounter += 2;
    }

    /**
     * Randomize the value of register RZ
     * by generating a random number between the values of registers RX and RY.
     * 0xBERZ RXRY
     * @param wordA
     * @param wordB
    **/
    public function instructionRandomize(wordA:Word16, wordB:Word16):Void {
        var registerZIndex = wordA.getSecondNibble();
        var registerXIndex = wordB.getFirstNibble();
        var registerYIndex = wordB.getSecondNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        var registerZ = getRegister(registerZIndex);

        // Generate a random number between the values of RX and RY
        var min = Math.min(registerX.getValue(), registerY.getValue());
        var max = Math.max(registerX.getValue(), registerY.getValue());
        var randomValue = Math.floor(Math.random() * (max - min + 1)) + min;

        registerZ.setValue(cast randomValue);
        programCounter += 2;
    }

    // 0xCx Logic instructions

    /**
     * Skip the next instruction if the value in register RX is equal to the value in register RY.
     * 0xC1RX RY00
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfEqual(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getSecondNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        if (registerX.getValue() == registerY.getValue()) {
            programCounter += 2;
        } else {
            programCounter += 4;
        }
    }

    /**
     * Skip the next instruction if the value in register RX is not equal to the value in register RY.
     * 0xC2RX RY00
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfNotEqual(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getSecondNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);
        if (registerX.getValue() != registerY.getValue()) {
            programCounter += 2;
        } else {
            programCounter += 4;
        }
    }

    /**
     * Skip the next instruction if the value in register RX is greater than the value in register RY.
     * 0xC3RX RY00
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfGreaterThan(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getSecondNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);

        if (registerX.getValue() > registerY.getValue()) {
            programCounter += 2;
        } else {
            programCounter += 4;
        }
    }

    /**
     * Skip the next instruction if the value in register RX is less than the value in register RY.
     * 0xC4RX RY00
     * @param wordA
     * @param wordB
    **/
    public function instructionSkipIfLessThan(wordA:Word16, wordB:Word16):Void {
        var registerXIndex = wordA.getSecondNibble();
        var registerYIndex = wordB.getFirstNibble();
        var registerX = getRegister(registerXIndex);
        var registerY = getRegister(registerYIndex);

        if (registerX.getValue() < registerY.getValue()) {
            programCounter += 2;
        } else {
            programCounter += 4;
        }
    }

    // 0xDx Buffer instructions

    /**
     * Move the value from register RX to buffer B0.
     * 0xD1RX BX00
     * @param wordA
     * @param wordB
    **/
    public function instructionMoveToBuffer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var bufferIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);

        buffer.write(register.getValue());
        programCounter += 2;
    }

    /**
     * Move the value from buffer B0 to register RX.
     * 0xD2RX BX00
     * @param wordA
     * @param wordB
    **/
    public function instructionMoveFromBuffer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var bufferIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var buffer = getBuffer(bufferIndex);

        register.setValue(buffer.read());
        programCounter += 2;
    }

    /**
     * Clear the contents of buffer B0.
     * 0xD3BX 0000
     * @param wordA
     * @param wordB
    **/
    public function instructionClearBuffer(wordA:Word16, wordB:Word16):Void {
        var bufferIndex = wordA.getSecondNibble();
        var buffer = getBuffer(bufferIndex);

        buffer.clear();
        programCounter += 2;
    }

    /**
     * Store the size of buffer BX in register RX.
     * 0xD4BX RX00
     * @param wordA
     * @param wordB
    **/
    public function instructionBufferSize(wordA:Word16, wordB:Word16):Void {
        var bufferIndex = wordA.getSecondNibble();
        var registerIndex = wordB.getFirstNibble();
        var buffer = getBuffer(bufferIndex);
        var register = getRegister(registerIndex);

        register.setValue(buffer.size);
        programCounter += 2;
    }

    // 0xEx Memory instructions

    /**
     * Write the contents of buffer BX to memory MX at the address specified by RX.
     * 0xE1MX BXRX
     * @param wordA
     * @param wordB
    **/
    public function instructionWriteBufferToMemory(wordA:Word16, wordB:Word16):Void {
        var memoryIndex = wordA.getSecondNibble();
        var bufferIndex = wordB.getFirstNibble();
        var startAddressRegisterIndex = wordB.getSecondNibble();
        var memory = getMemory(memoryIndex);
        var buffer = getBuffer(bufferIndex);
        var startAddress = getRegister(startAddressRegisterIndex).getValue();

        memory.writeBuffer(startAddress, buffer);
        programCounter += 2;
    }

    /**
     * Read the contents of memory MX at the address specified by RX into buffer BX.
     * 0xE2MX BXRX
     * @param wordA
     * @param wordB
    **/
    public function instructionReadBufferFromMemory(wordA:Word16, wordB:Word16):Void {
        var memoryIndex = wordA.getSecondNibble();
        var bufferIndex = wordB.getFirstNibble();
        var startAddressRegisterIndex = wordB.getSecondNibble();
        var memory = getMemory(memoryIndex);
        var buffer = getBuffer(bufferIndex);
        var startAddress = getRegister(startAddressRegisterIndex).getValue();

        memory.readToBuffer(startAddress, buffer);
        programCounter += 2;
    }

    // 0xFx Timer instructions

    /**
     * Set a timer with the value from register RX.
     * 0xF1TX RX00
     * @param wordA
     * @param wordB
    **/
    public function instructionSetTimer(wordA:Word16, wordB:Word16):Void {
        var timerIndex = wordA.getSecondNibble();
        var registerIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var timerValue = register.getValue();

        setTimerValue(timerIndex, timerValue);
        programCounter += 2;
    }

    /**
     * Get the value of a timer and store it in register RX.
     * 0xF2RX TX00
     * @param wordA
     * @param wordB
    **/
    public function instructionGetTimer(wordA:Word16, wordB:Word16):Void {
        var registerIndex = wordA.getSecondNibble();
        var timerIndex = wordB.getFirstNibble();
        var register = getRegister(registerIndex);
        var timerValue = getTimerValue(timerIndex);

        register.setValue(timerValue);
        programCounter += 2;
    }
}

class InstructionException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
