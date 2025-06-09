package pulsar;

class InstructionSet {
    var processor:Processor;

    public function new(processor:Processor) {
        this.processor = processor;
    }
}

class InstructionException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}

class SubroutineInstructionSet extends InstructionSet {
    public function new(processor:Processor) {
        super(processor);
    }

    public function jumpTo(registerIndex:Word16):Void {
        var register = processor.getRegister(registerIndex);
        processor.setProgramCounter(register.getValue());
    }

    public function subroutineTo(registerIndex:Word16):Void {
        var register = processor.getRegister(registerIndex);
        var returnAddress = processor.getProgramCounter();
        processor.setProgramCounter(register.getValue());
        processor.addressStack.push(returnAddress);
    }

    public function returnFromSubroutine():Void {
        var returnAddress = processor.addressStack.pop();
        processor.setProgramCounter(returnAddress);
    }
}

class ArithmeticInstructionSet extends InstructionSet {
    public function new(processor:Processor) {
        super(processor);
    }

    public function moveValue(fromRegisterIndex:Word16, toRegisterIndex:Word16):Void {
        var from_register = processor.getRegister(fromRegisterIndex);
        var to_register = processor.getRegister(toRegisterIndex);
        to_register.setValue(from_register.getValue());
    }

    public function setValue(registerIndex:Word16, value:Word16):Void {
        var register = processor.getRegister(registerIndex);
        register.setValue(value);
    }

    public function addValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var sum = regA.getValue() + regB.getValue();
        resultRegister.setValue(sum);
    }

    public function subtractValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var difference = regA.getValue() - regB.getValue();
        resultRegister.setValue(difference);
    }

    public function multiplyValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var product = regA.getValue() * regB.getValue();
        resultRegister.setValue(product);
    }

    public function divideValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        if (regB.getValue() == 0) {
            throw new InstructionException("Division by zero");
        }
        var quotient = regA.getValue() / regB.getValue();
        resultRegister.setValue(quotient);
    }

    public function moduloValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        if (regB.getValue() == 0) {
            throw new InstructionException("Modulo by zero");
        }
        var remainder = regA.getValue() % regB.getValue();
        resultRegister.setValue(remainder);
    }

    public function orValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var orResult = regA.getValue() | regB.getValue();
        resultRegister.setValue(orResult);
    }

    public function andValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var andResult = regA.getValue() & regB.getValue();
        resultRegister.setValue(andResult);
    }

    public function xorValues(registerIndexA:Word16, registerIndexB:Word16,
            resultRegisterIndex:Word16):Void {
        var regA = processor.getRegister(registerIndexA);
        var regB = processor.getRegister(registerIndexB);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var xorResult = regA.getValue() ^ regB.getValue();
        resultRegister.setValue(xorResult);
    }

    public function notValue(registerIndex:Word16, resultRegisterIndex:Word16):Void {
        var reg = processor.getRegister(registerIndex);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var notResult = ~reg.getValue();
        resultRegister.setValue(notResult);
    }

    public function shiftLeft(registerIndex:Word16, resultRegisterIndex:Word16):Void {
        var reg = processor.getRegister(registerIndex);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var shiftedValue = reg.getValue() << 1;
        resultRegister.setValue(shiftedValue);
    }

    public function shiftRight(registerIndex:Word16, resultRegisterIndex:Word16):Void {
        var reg = processor.getRegister(registerIndex);
        var resultRegister = processor.getRegister(resultRegisterIndex);
        var shiftedValue = reg.getValue() >> 1;
        resultRegister.setValue(shiftedValue);
    }

    public function randomize(registerIndex_min:Word16, registerIndex_max:Word16,
            resultRegisterIndex:Word16):Void {
        var regMin = processor.getRegister(registerIndex_min);
        var regMax = processor.getRegister(registerIndex_max);
        var resultRegister = processor.getRegister(resultRegisterIndex);

        if (regMin.getValue() > regMax.getValue()) {
            throw new InstructionException("Invalid range for randomize: min > max");
        }

        var min = regMin.getValue();
        var max = regMax.getValue();
        var random_value = Math.floor(Math.random() * (max - min + 1)) + min;
        resultRegister.setValue(random_value);
    }
}

class BufferInstructionSet extends InstructionSet {
    public function new(processor:Processor) {
        super(processor);
    }

    public function moveToBuffer(registerIndexA:Word16, bufferTarget:Word16):Void {
        processor.getBuffer(bufferTarget).write(processor.getRegister(registerIndexA).getValue());
    }

    public function moveFromBuffer(bufferSource:Word16, registerTarget:Word16):Void {
        var buffer = processor.getBuffer(bufferSource);
        if (buffer.contents.length == 0) {
            throw new InstructionException("Buffer underflow: No contents to read");
        }
        var value = buffer.read();
        processor.getRegister(registerTarget).setValue(value);
    }

    public function clearBuffer(bufferIndex:Word16):Void {
        var buffer = processor.getBuffer(bufferIndex);
        buffer.clear();
    }

    public function readBufferLength(bufferIndex:Word16, registerTarget:Word16):Void {
        var buffer = processor.getBuffer(bufferIndex);
        var length = buffer.contents.length;
        processor.getRegister(registerTarget).setValue(length);
    }
}

class MemoryInstructionSet extends InstructionSet {
    public function new(processor:Processor) {
        super(processor);
    }

    public function writeBufferToMemory(bufferIndex:Word16, memoryIndex:Word16,
            startAddressRegisterIndex:Word16):Void {
        var buffer = processor.getBuffer(bufferIndex);
        var memory = processor.getMemory(memoryIndex);
        var start_address = processor.getRegister(startAddressRegisterIndex).getValue();
        memory.writeBuffer(start_address, buffer);
    }

    public function readMemoryToBuffer(memoryIndex:Word16, bufferIndex:Word16,
            startAddressRegisterIndex:Word16):Void {
        var memory = processor.getMemory(memoryIndex);
        var buffer = processor.getBuffer(bufferIndex);
        var start_address = processor.getRegister(startAddressRegisterIndex).getValue();
        memory.readToBuffer(start_address, buffer);
    }
}

class TimerInstructionSet extends InstructionSet {
    public function new(processor:Processor) {
        super(processor);
    }

    public function setTimer(timerIndex:Word16, value:Word16):Void {
        processor.setTimerValue(timerIndex, value);
    }

    public function getTimer(timerIndex:Word16, registerTarget:Word16):Void {
        var timerValue = processor.getTimerValue(timerIndex);
        processor.getRegister(registerTarget).setValue(timerValue);
    }
}
