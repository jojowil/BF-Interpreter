; 6502 version of BF designed to run
; in the 6502js web-based emulator.

;=========================
; I/O
define CHROUT $FFD2
define CHRIN  $FFCF

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

;=========================
; define our code and arena pointers
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

;=========================
; interpret a command.
interpret:
    TAX     ; save the cmd
    CMP #GRTR
    BNE mnext1
    JMP incap
mnext1:
    CMP #LESS
    BNE mnext2
    JMP decap
mnext2:
    CMP #PLUS
    BNE mnext3
    JMP appp
mnext3:
    CMP #MINUS
    BNE mnext4
    JMP apmm
mnext4:
    CMP #DOT
    BNE mnext5
    JMP apin
mnext5:
    CMP #COMMA
    BNE mnext6
    JMP apin
mnext6:
    CMP #OPEN
    LDY #0
    LDA (APLO), Y
    BNE mnext7
    JMP matchc
mnext7:
    TXA     ; retrieve saved!
    CMP #CLOSE
    LDY #0  ; prolly redundant
    LDA (APLO), Y
    BEQ idone
    JMP matcho
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
    LDY #0
    LDA (APLO), Y
    TAX
    INX
    TXA
    STA (APLO), Y
    RTS

;=========================
apmm:
    LDY #0
    LDA (APLO), Y
    TAX
    DEX
    TXA
    STA (APLO), Y
    RTS

;=========================
apout:
    LDY #0
    LDA (APLO), Y
    JSR CHROUT
    RTS

;=========================
apin:
    JSR CHRIN
    CMP #0
    BEQ apin
    LDY #0
    STA (APLO), Y
    RTS

;=========================
; find maching open
matcho:
    LDX #1
oloop:
    JSR deccp
    CPX #0      ; >255 ] would be an issue. ;-)
    BEQ odone
    JSR getcmd
    CMP #CLOSE
    BNE onext
    INX
    JMP oloop
onext:
    CMP #OPEN
    BNE oloop
    DEX
    JMP oloop
odone:
    RTS

;=========================
matchc:
    LDX #1
cloop:
    JSR inccp
    CPX #0      ; >255 ] would be an issue. ;-)
    BEQ cdone
    JSR getcmd
    CMP #OPEN
    BNE cnext
    INX
    JMP cloop
cnext:
    CMP #CLOSE
    BNE cloop
    DEX
    JMP cloop
cdone:
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
    ; taken from hello3.v
    TXT "+++++++++++[>++++++>+++++++++>++++++++>++++>+++>+<<<<<<-]>+++"
    TXT "+++.>++.+++++++..+++.>>.>-.<<-.<.+++.------.--------.>>>+.>-."
    dcb 0 ; end of program

;=========================
; welcome to the arena...
arena:
    dsb 30000