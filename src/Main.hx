package;

import pulsar.Parser;
import pulsar.Word16;

class Main {
    static final code = "
    SET R0 00 # set an inital value;
    SET R1 01 # set an increment value;
    SET R2 FFFF # set a limit value;
    BEGIN: ADD R0 R0 R1 # increment R0 by R1;
    IF_NEQ R0 R2 # while R0 != R2, loop;
    JUMP_TO BEGIN;
    RET # end of the program;
    ";

    static function main() {
        var processor = new pulsar.Processor(16, 16, 4, [0xF, 0xF, 0xFF, 0xFF], 2);
        var parser = new pulsar.Parser();

        var memory = processor.getMemory(0);

        var statements = parser.parse(code, 0);
        trace("Parsed Statements:");
        for (statement in statements) {
            trace(statement);
        }
        var code = Parser.ToMachineCode(statements);
        memory.setValues(0, code);
        var codeString = "";
        for (i in 0...code.length) {
            codeString += code[i].toHex() + " ";
        }
        trace(codeString);
        var before = Sys.time();

        for (i in 0...1000000) {
            // trace("Running iteration: " + i);
            try {
                processor.runOnce();
            } catch (e:Dynamic) {
                trace("Loop " + i + " ended with error: " + e);
                break;
            }

            // trace("PC: " + processor.programCounter);
            // trace(memory.data[processor.programCounter]);
            // trace(memory.data[processor.programCounter + 1]);
            // trace("R0: " + processor.getRegister(0).getValue());
            // trace("R1: " + processor.getRegister(1).getValue());
            // trace("R2: " + processor.getRegister(2).getValue());
            // trace("----");
        }
        var after = Sys.time();
        trace("Time taken: " + (after - before) + " seconds");

        trace(processor.getRegister(0).getValue());
        trace(processor.getRegister(0).getValue() == 0xFA);
    }
}
