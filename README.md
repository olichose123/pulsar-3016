# Pulsar-3016
An emulator for a fantasy 16-bit microprocessor

## Instructions



| Opcode | Parameters | Instruction                                                                              |
| ------ | ---------- | ---------------------------------------------------------------------------------------- |
| A1     | A1a0 0000  | jump to address stored in register a                                                     |
| A2     | A2a0 0000  | call subroutine at address stored in register a, push current counter to stack           |
| AA     | AA00 xxxx  | jump to specified address                                                                |
| AB     | AB00 xxxx  | call subroutine at specified address                                                     |
| AE     | AE00 0000  | return to last counter in stack or quit if stack empty                                   |
| B1     | B1ab 0000  | set register b to the value of register a                                                |
| B2     | B2a0 xxxx  | set register b to the value xxxx                                                         |
| B3     | B3zx y000  | set register z to register x + register y                                                |
| B4     | B4zx y000  | set register z toregister  x - register y                                                |
| B5     | B5zx y000  | set register z toregister  x * register y                                                |
| B6     | B6zx y000  | set register z to register x / register y                                                |
| B7     | B7zx y000  | set register z to register x % register y                                                |
| B8     | B8zx y000  | set register z to register x OR register y                                               |
| B9     | B9zx y000  | set register z to register x AND register y                                              |
| BA     | BAzx y000  | set register z to register x XOR register y                                              |
| BB     | BBzx 0000  | set register z to NOT register x                                                         |
| BC     | BCzx 0000  | set register z to register x SHIFTED left                                                |
| BD     | BDzx 0000  | set register z to register x SHIFTED right                                               |
| BE     | BEzx 0000  | set register z to random value between register x (inclusive) and register y (exclusive) |
| C1     | C1xy 0000  | skip next mem location if value or register x == value of register y                     |
| C2     | C2xy 0000  | skip next mem location if value or register x != value of register y                     |
| C3     | C3xy 0000  | skip next mem location if value of register x > value of register y                      |
| C4     | C4xy 0000  | skip next mem location if value of register x < value or register y                      |
| D1     | D1xb 0000  | push value or register x into buffer b                                                   |
| D2     | D2xb 0000  | shift value from buffer b into register x                                                |
| D3     | D3xb 0000  | write value of buffer b in register x without erasing b value                            |
| DE     | DEb0 0000  | clear buffer b                                                                           |
| D4     | D4xb 0000  | write buffer b size into register x                                                      |
| E1     | E1mb x000  | write content of buffer b in memory m at address in register r                           |
| E2     | E2mb x000  | read memory m at address in register r into buffer b                                     |
| F1     | F1rt 0000  | set timer t to value of register r                                                       |
| F2     | F2rt 0000  | put timer value t into register r                                                        |
