package pulsar;

using StringTools;

using haxe.EnumTools;

class Parser {
    public function new() {}

    public static function ToMachineCode(statements:Array<Statement>):Array<Word16> {
        var machineCode:Array<Word16> = [];
        for (statement in statements) {
            machineCode.push(statement.wordA);
            machineCode.push(statement.wordB);
        }
        return machineCode;
    }

    public function parse(code:String, memOffset:Word16):Array<Statement> {
        // split by ; to determine number of statements
        var statements:Array<Statement> = [];
        var parts:Array<String> = code.replace("\n", " ").split(";");
        for (part in parts) {
            var trimmedPart = part.trim();
            if (trimmedPart.length == 0)
                continue; // skip empty parts

            var statement:Statement = {
                label: null,
                command: null,
                opcode: null,
                params: [],
                comment: null,
                pos: null,
                wordA: null,
                wordB: null
            };

            // Check for label
            var labelEnd = trimmedPart.indexOf(":");
            if (labelEnd != -1) {
                statement.label = trimmedPart.substring(0, labelEnd).trim();
                trimmedPart = trimmedPart.substring(labelEnd + 1).trim();
            }

            // Check for comment
            var commentStart = trimmedPart.indexOf("#");
            if (commentStart != -1) {
                statement.comment = trimmedPart.substring(commentStart + 1).trim();
                trimmedPart = trimmedPart.substring(0, commentStart).trim();
            }

            // Split command and parameters
            var commandParts:Array<String> = trimmedPart.split(" ");
            if (commandParts.length > 0) {
                statement.command = parseCommand(commandParts[0]);

                for (i in 1...commandParts.length) {
                    var param:String = commandParts[i].trim();
                    if (param.length > 0) {
                        statement.params.push(parseParam(param));
                    }
                }
            }

            statements.push(statement);
        }

        // addLabelAssignment(statements);
        handleLocations(statements, memOffset);
        replaceLabels(statements);
        getOpcodes(statements);
        buildWords(statements);

        return statements;
    }

    function buildWords(statements:Array<Statement>):Void {
        for (statement in statements) {
            var wordA:Word16 = 0;
            var wordB:Word16 = 0;

            switch (statement.opcode) {
                case Opcode.Jump:
                    wordA.setFirstByte(Opcode.Jump);
                    if (statement.params.length != 1) {
                        throw new ParserException("Jump requires exactly one parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException("Jump parameter must be a register.");
                    }
                case Opcode.Call:
                    wordA.setFirstByte(Opcode.Call);
                    if (statement.params.length != 1) {
                        throw new ParserException("Call requires exactly one parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException("Call parameter must be a register.");
                    }

                case Opcode.Return:
                    wordA.setFirstByte(Opcode.Return);
                    if (statement.params.length != 0) {
                        throw new ParserException("Return does not take any parameters.");
                    }

                case Opcode.JumpTo:
                    wordA.setFirstByte(Opcode.JumpTo);
                    if (statement.params.length != 1) {
                        throw new ParserException("JumpTo requires exactly one parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Value(v):
                            wordB = v;
                        default:
                            throw new ParserException("JumpTo parameter must be a value.");
                    }

                case Opcode.CallTo:
                    wordA.setFirstByte(Opcode.CallTo);
                    if (statement.params.length != 1) {
                        throw new ParserException("CallTo requires exactly one parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Value(v):
                            wordB = v;
                        default:
                            throw new ParserException("CallTo parameter must be a value.");
                    }

                case Opcode.Move:
                    wordA.setFirstByte(Opcode.Move);
                    if (statement.params.length != 2) {
                        throw new ParserException("Move requires exactly two parameters.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException("Move first parameter must be a register.");
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException("Move second parameter must be a register.");
                    }

                case Opcode.Set:
                    wordA.setFirstByte(Opcode.Set);
                    if (statement.params.length != 2) {
                        throw new ParserException("Set requires exactly two parameters.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException("Set first parameter must be a register.");
                    }
                    switch (statement.params[1]) {
                        case ParamType.Value(v):
                            wordB = v;
                        default:
                            throw new ParserException("Set second parameter must be a value.");
                    }

                case Opcode.Add | Opcode.Subtract | Opcode.Multiply | Opcode.Divide | Opcode.Modulo | Opcode.Or | Opcode.And | Opcode.Xor:
                    trace(statement.opcode);
                    wordA.setFirstByte(statement.opcode);
                    if (statement.params.length != 3) {
                        throw new ParserException(
                            "Arithmetic operations require exactly three parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "Arithmetic first parameter must be a register."
                            );
                    }

                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "Arithmetic second parameter must be a register."
                            );
                    }

                    switch (statement.params[2]) {
                        case ParamType.Register(r):
                            wordB.setFirstNibble(r);
                        default:
                            throw new ParserException(
                                "Arithmetic third parameter must be a register."
                            );
                    }

                case Opcode.Not | Opcode.ShiftLeft | Opcode.ShiftRight:
                    wordA.setFirstByte(statement.opcode);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "Unary operations require exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException("Unary first parameter must be a register.");
                    }

                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordB.setFirstNibble(r);
                        default:
                            throw new ParserException(
                                "Unary second parameter must be a register."
                            );
                    }

                case Opcode.Randomize:
                    wordA.setFirstByte(Opcode.Randomize);
                    if (statement.params.length != 3) {
                        throw new ParserException("Randomize requires exactly three parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "Randomize first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "Randomize second parameter must be a register."
                            );
                    }
                    switch (statement.params[2]) {
                        case ParamType.Register(r):
                            wordB.setFirstNibble(r);
                        default:
                            throw new ParserException(
                                "Randomize third parameter must be a register."
                            );
                    }

                case Opcode.SkipIfEqual:
                    wordA.setFirstByte(Opcode.SkipIfEqual);
                    if (statement.params.length != 2) {
                        throw new ParserException("SkipIfEqual requires exactly two parameters.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfEqual first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfEqual second parameter must be a register."
                            );
                    }

                case Opcode.SkipIfNotEqual:
                    wordA.setFirstByte(Opcode.SkipIfNotEqual);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "SkipIfNotEqual requires exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfNotEqual first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfNotEqual second parameter must be a register."
                            );
                    }

                case Opcode.SkipIfGreaterThan:
                    wordA.setFirstByte(Opcode.SkipIfGreaterThan);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "SkipIfGreaterThan requires exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfGreaterThan first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfGreaterThan second parameter must be a register."
                            );
                    }

                case Opcode.SkipIfLessThan:
                    wordA.setFirstByte(Opcode.SkipIfLessThan);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "SkipIfLessThan requires exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfLessThan first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Register(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "SkipIfLessThan second parameter must be a register."
                            );
                    }

                case Opcode.PushToBuffer | Opcode.ShiftFromBuffer:
                    wordA.setFirstByte(statement.opcode);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "Buffer operations require exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "Buffer operation first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Buffer(b):
                            wordB = b;
                        default:
                            throw new ParserException(
                                "Buffer operation second parameter must be a buffer."
                            );
                    }

                case Opcode.PeekFromBuffer:
                    wordA.setFirstByte(Opcode.PeekFromBuffer);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "PeekFromBuffer requires exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "PeekFromBuffer first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Buffer(b):
                            wordB = b;
                        default:
                            throw new ParserException(
                                "PeekFromBuffer second parameter must be a buffer."
                            );
                    }

                case Opcode.ClearBuffer:
                    wordA.setFirstByte(Opcode.ClearBuffer);
                    if (statement.params.length != 1) {
                        throw new ParserException("ClearBuffer requires exactly one parameter.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Buffer(b):
                            wordB = b;
                        default:
                            throw new ParserException("ClearBuffer parameter must be a buffer.");
                    }

                case Opcode.GetBufferSize:
                    wordA.setFirstByte(Opcode.GetBufferSize);
                    if (statement.params.length != 2) {
                        throw new ParserException(
                            "GetBufferSize requires exactly two parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "GetBufferSize first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Buffer(b):
                            wordB = b;
                        default:
                            throw new ParserException(
                                "GetBufferSize second parameter must be a buffer."
                            );
                    }

                case Opcode.WriteToMemory:
                    wordA.setFirstByte(Opcode.WriteToMemory);
                    if (statement.params.length != 3) {
                        throw new ParserException(
                            "WriteToMemory requires exactly three parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Memory(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "WriteToMemory first parameter must be a memory location."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Buffer(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "WriteToMemory second parameter must be a buffer."
                            );
                    }
                    switch (statement.params[2]) {
                        case ParamType.Value(v):
                            wordB = v;
                        default:
                            throw new ParserException(
                                "WriteToMemory third parameter must be a value."
                            );
                    }

                case Opcode.ReadFromMemory:
                    wordA.setFirstByte(Opcode.ReadFromMemory);
                    if (statement.params.length != 3) {
                        throw new ParserException(
                            "ReadFromMemory requires exactly three parameters."
                        );
                    }
                    switch (statement.params[0]) {
                        case ParamType.Memory(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "ReadFromMemory first parameter must be a memory location."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Buffer(r):
                            wordA.setFourthNibble(r);
                        default:
                            throw new ParserException(
                                "ReadFromMemory second parameter must be a buffer."
                            );
                    }
                    switch (statement.params[2]) {
                        case ParamType.Register(r):
                            wordB.setFirstNibble(r);
                        default:
                            throw new ParserException(
                                "ReadFromMemory third parameter must be a register."
                            );
                    }
                case Opcode.SetTimer:
                    wordA.setFirstByte(Opcode.SetTimer);
                    if (statement.params.length != 2) {
                        throw new ParserException("SetTimer requires exactly two parameters.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "SetTimer first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Timer(t):
                            wordB = t;
                        default:
                            throw new ParserException(
                                "SetTimer second parameter must be a timer."
                            );
                    }

                case Opcode.GetTimer:
                    wordA.setFirstByte(Opcode.GetTimer);
                    if (statement.params.length != 2) {
                        throw new ParserException("GetTimer requires exactly two parameters.");
                    }
                    switch (statement.params[0]) {
                        case ParamType.Register(r):
                            wordA.setThirdNibble(r);
                        default:
                            throw new ParserException(
                                "GetTimer first parameter must be a register."
                            );
                    }
                    switch (statement.params[1]) {
                        case ParamType.Timer(t):
                            wordB = t;
                        default:
                            throw new ParserException(
                                "GetTimer second parameter must be a timer."
                            );
                    }
            }
            statement.wordA = wordA;
            statement.wordB = wordB;
        }
    }

    function getOpcodes(statements:Array<Statement>):Void {
        for (statement in statements) {
            if (statement.command != null) {
                statement.opcode = statement.command.toOpcode();
            } else {
                throw new ParserException("Command not found for statement: " + statement);
            }
        }
    }

    function parseParam(param:String):ParamType {
        // Check for register
        if (~/^R[0-9A-Fa-f]$/i.match(param)) {
            param = param.substr(1);
            return ParamType.Register(Std.parseInt(param));
        }
        // Check for value
        else if (~/^[0-9A-Fa-f]+$/i.match(param)) {
            param = "0x" + param; // prefix with 0x for hexadecimal
            return ParamType.Value(Std.parseInt(param));
        }
        // Check for buffer
        else if (~/^B[0-9A-Fa-f]$/i.match(param)) {
            param = param.substr(1);
            return ParamType.Buffer(Std.parseInt(param));
        }
        // Check for memory
        else if (~/^M[0-9A-Fa-f]$/i.match(param)) {
            param = param.substr(1);
            return ParamType.Memory(Std.parseInt(param));
        }
        // Check for timer
        else if (~/^T[0-9A-Fa-f]$/i.match(param)) {
            param = param.substr(1);
            return ParamType.Timer(Std.parseInt(param));
        }
        // Otherwise, treat as label
        else {
            return ParamType.Label(param);
        }
    }

    function parseCommand(command:String):Instruction {
        switch (command.toUpperCase()) {
            case Instruction.Jump:
                return Instruction.Jump;
            case Instruction.Call:
                return Instruction.Call;
            case Instruction.Return:
                return Instruction.Return;
            case Instruction.JumpTo:
                return Instruction.JumpTo;
            case Instruction.CallTo:
                return Instruction.CallTo;
            case Instruction.Move:
                return Instruction.Move;
            case Instruction.Set:
                return Instruction.Set;
            case Instruction.Add:
                return Instruction.Add;
            case Instruction.Subtract:
                return Instruction.Subtract;
            case Instruction.Multiply:
                return Instruction.Multiply;
            case Instruction.Divide:
                return Instruction.Divide;
            case Instruction.Modulo:
                return Instruction.Modulo;
            case Instruction.Or:
                return Instruction.Or;
            case Instruction.And:
                return Instruction.And;
            case Instruction.Xor:
                return Instruction.Xor;
            case Instruction.Not:
                return Instruction.Not;
            case Instruction.ShiftLeft:
                return Instruction.ShiftLeft;
            case Instruction.ShiftRight:
                return Instruction.ShiftRight;
            case Instruction.Randomize:
                return Instruction.Randomize;
            case Instruction.SkipIfEqual:
                return Instruction.SkipIfEqual;
            case Instruction.SkipIfNotEqual:
                return Instruction.SkipIfNotEqual;
            case Instruction.SkipIfGreaterThan:
                return Instruction.SkipIfGreaterThan;
            case Instruction.SkipIfLessThan:
                return Instruction.SkipIfLessThan;
            case Instruction.PushToBuffer:
                return Instruction.PushToBuffer;
            case Instruction.ShiftFromBuffer:
                return Instruction.ShiftFromBuffer;
            case Instruction.PeekFromBuffer:
                return Instruction.PeekFromBuffer;
            case Instruction.ClearBuffer:
                return Instruction.ClearBuffer;
            case Instruction.GetBufferSize:
                return Instruction.GetBufferSize;
            case Instruction.WriteToMemory:
                return Instruction.WriteToMemory;
            case Instruction.ReadFromMemory:
                return Instruction.ReadFromMemory;
            case Instruction.SetTimer:
                return Instruction.SetTimer;
            case Instruction.GetTimer:
                return Instruction.GetTimer;
            default:
                throw new ParserException("Unknown command: " + command);
        }
    }

    // function addLabelAssignment(statements:Array<Statement>):Void {
    //     var offset:Int = 0;
    //     for (i in 0...statements.length) {
    //         var statement = statements[i + offset];
    //         var c:Int = 0;
    //         for (param in statement.params) {
    //             switch (param) {
    //                 case ParamType.Label(label):
    //                     statements.insert(i + offset, {
    //                         label: null,
    //                         command: Instruction.Set,
    //                         opcode: null,
    //                         params: [Register(0xF),
    //                             Label(label)],
    //                         comment: "auto-added by parser",
    //                         pos: null,
    //                         wordA: null,
    //                         wordB: null
    //                     });
    //                     statement.params[c] = ParamType.Register(0xF);
    //                     offset++;
    //                 case _:
    //             }
    //             c++;
    //         }
    //     }
    // }

    function handleLocations(statements:Array<Statement>, offset:Word16):Void {
        var counter:Word16 = 0;
        for (statement in statements) {
            statement.pos = offset + counter;
            counter += 2;
        }
    }

    function replaceLabels(statements:Array<Statement>):Void {
        var labelMap:Map<String, Word16> = new Map();
        for (statement in statements) {
            if (statement.label != null) {
                if (labelMap.exists(statement.label)) {
                    throw new ParserException("Duplicate label: " + statement.label);
                }
                labelMap.set(statement.label, statement.pos);
            }
        }

        for (statement in statements) {
            for (i in 0...statement.params.length) {
                switch (statement.params[i]) {
                    case ParamType.Label(label):
                        if (labelMap.exists(label)) {
                            statement.params[i] = ParamType.Value(labelMap.get(label));
                        } else {
                            throw new ParserException("Undefined label: " + label);
                        }
                    case _:
                }
            }
        }
    }
}

enum ParamType {
    Register(value:Word16); // e.g. R1, R2, etc.
    Value(value:Word16); // e.g. FFFF, 0ABC, etc.
    Buffer(value:Word16); // e.g. B1, B2, etc.
    Memory(value:Word16); // e.g. M1, M2, etc.
    Timer(value:Word16); // e.g. T1, T2, etc.
    Label(value:String); // e.g. LABEL1, LABEL2, etc.
    // MY_LABEL: JUMP MY_OTHER_LABEL # this is a comment
}

typedef Statement = {
    var ?label:String;
    var ?command:Instruction;
    var ?opcode:Opcode;
    var ?params:Array<ParamType>;
    var ?comment:String;
    var ?pos:Word16;
    var ?wordA:Word16;
    var ?wordB:Word16;
}

enum abstract Opcode(Int) to Int {
    var Jump = 0xA1;
    var Call = 0xA2;
    var Return = 0xAE;
    var JumpTo = 0xAA;
    var CallTo = 0xAB;

    var Move = 0xB1;
    var Set = 0xB2;
    var Add = 0xB3;
    var Subtract = 0xB4;
    var Multiply = 0xB5;
    var Divide = 0xB6;
    var Modulo = 0xB7;
    var Or = 0xB8;
    var And = 0xB9;
    var Xor = 0xBA;
    var Not = 0xBB;
    var ShiftLeft = 0xBC;
    var ShiftRight = 0xBD;
    var Randomize = 0xBE;

    var SkipIfEqual = 0xC1;
    var SkipIfNotEqual = 0xC2;
    var SkipIfGreaterThan = 0xC3;
    var SkipIfLessThan = 0xC4;

    var PushToBuffer = 0xD1;
    var ShiftFromBuffer = 0xD2;
    var PeekFromBuffer = 0xD3;
    var ClearBuffer = 0xDE;
    var GetBufferSize = 0xD4;

    var WriteToMemory = 0xE1;
    var ReadFromMemory = 0xE2;

    var SetTimer = 0xF1;
    var GetTimer = 0xF2;
}

enum abstract Instruction(String) to String {
    var Jump = "JUMP";
    var Call = "CALL";
    var Return = "RET";
    var JumpTo = "JUMP_TO";
    var CallTo = "CALL_TO";

    var Move = "MOVE";
    var Set = "SET";
    var Add = "ADD";
    var Subtract = "SUB";
    var Multiply = "MUL";
    var Divide = "DIV";
    var Modulo = "MOD";
    var Or = "OR";
    var And = "AND";
    var Xor = "XOR";
    var Not = "NOT";
    var ShiftLeft = "SHL";
    var ShiftRight = "SHR";
    var Randomize = "RND";

    var SkipIfEqual = "IF_NEQ";
    var SkipIfNotEqual = "IF_EQ";
    var SkipIfGreaterThan = "IF_LT";
    var SkipIfLessThan = "IF_GT";

    var PushToBuffer = "PUSH_BUF";
    var ShiftFromBuffer = "SHIFT_BUF";
    var PeekFromBuffer = "PEEK_BUF";
    var ClearBuffer = "CLEAR_BUF";
    var GetBufferSize = "SIZE_BUF";

    var WriteToMemory = "WRITE_MEM";
    var ReadFromMemory = "READ_MEM";

    var SetTimer = "SET_TIMER";
    var GetTimer = "GET_TIMER";

    public inline function toOpcode():Opcode {
        return switch (this) {
            case Jump:
                Opcode.Jump;
            case Call:
                Opcode.Call;
            case Return:
                Opcode.Return;
            case JumpTo:
                Opcode.JumpTo;
            case CallTo:
                Opcode.CallTo;

            case Move:
                Opcode.Move;
            case Set:
                Opcode.Set;
            case Add:
                Opcode.Add;
            case Subtract:
                Opcode.Subtract;
            case Multiply:
                Opcode.Multiply;
            case Divide:
                Opcode.Divide;
            case Modulo:
                Opcode.Modulo;
            case Or:
                Opcode.Or;
            case And:
                Opcode.And;
            case Xor:
                Opcode.Xor;
            case Not:
                Opcode.Not;
            case ShiftLeft:
                Opcode.ShiftLeft;
            case ShiftRight:
                Opcode.ShiftRight;
            case Randomize:
                Opcode.Randomize;

            case SkipIfEqual:
                Opcode.SkipIfEqual;
            case SkipIfNotEqual:
                Opcode.SkipIfNotEqual;
            case SkipIfGreaterThan:
                Opcode.SkipIfGreaterThan;
            case SkipIfLessThan:
                Opcode.SkipIfLessThan;

            case PushToBuffer:
                Opcode.PushToBuffer;
            case ShiftFromBuffer:
                Opcode.ShiftFromBuffer;
            case PeekFromBuffer:
                Opcode.PeekFromBuffer;
            case ClearBuffer:
                Opcode.ClearBuffer;
            case GetBufferSize:
                Opcode.GetBufferSize;

            case WriteToMemory:
                Opcode.WriteToMemory;
            case ReadFromMemory:
                Opcode.ReadFromMemory;

            case SetTimer:
                Opcode.SetTimer;
            case GetTimer:
                Opcode.GetTimer;

            case _:
                throw new ParserException("Unknown instruction: " + this);
        }
    }
}

class ParserException extends PulsarException {
    public function new(message:String) {
        super(message);
    }
}
