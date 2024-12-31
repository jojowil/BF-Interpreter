; 6502 version of BF designed to run
; in the 6502js web-based emulator.

;=========================
; give arbitrary names to the cmds
define LESS  $3C ; < $3c
define GRTR  $3E ; > $3e
define DOT   $2E ; . $2e
define COMMA $2C ; , $2c
define PLUS  $2B ; + $2b
define MINUS $2D ; - $2d
define OPEN  $5B ; [ $5b
define CLOSE $5D ; ] $5d

define CPLO $20 ; $20/21 for code pointer
define CPHI $21
define APLO $30 ; $30/31 for arena pointer
define APHI $31

    ; let's get started
    JSR init ; setup our pointers

main:
    ; get a command and process it
    JSR getcmd
    CMP #0
    BEQ mainend    ; 0 means end of code.
    JSR interpret  ; interpret next instruction
    JSR inccp      ; advance CP
    JMP main       ; do some more.

mainend:
    BRK

;
; Subroutines below this line
;

; interpret a command.
interpret:

idone:
    RTS

;=========================
; get command in A
getcmd:
    LDY #$00
    LDA (CPLO), Y
    RTS

;=========================
; increment CP if overflow, increment hi
inccp:
    INC CPLO
    BNE icdone
    INC CPHI
icdone:
    RTS

;=========================
; decrement CP. if would underflow, decrement hi
deccp:
    LDX CPLO
    BNE cpskip
    DEC CPHI
cpskip:
    DEC CPLO
    RTS

;=========================
; increment CP. if overflow, increment hi
incap:
    INC APLO
    BNE iadone
    INC APHI
iadone:
    RTS

;=========================
; decrement AP. if would underflow, decrement hi
decap:
    LDX APLO
    BNE apskip
    DEC APHI
apskip:
    DEC APLO
    RTS

;=========================
appp:
    RTS

;=========================
apmm:
    RTS

;=========================
apout:
    RTS

;=========================
apin:
    RTS

;=========================
matcho:
    RTS

;=========================
matchc:
    RTS

;=========================
; initialize our pointers!
init:
    LDA #<code
    STA CPLO
    LDA #>code
    STA CPHI

    LDA #<arena
    STA APLO
    LDA #>arena
    STA APHI
    RTS
;
; data below this line
;

;=========================
; source code for BF program
code:
    TXT ""
    TXT ""
    dcb 0 ; end of program

;=========================
; welcome to the arena...
arena:
    dsb 30000