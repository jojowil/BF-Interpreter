; 6502 version of BF designed to run
; in the 6502js web-based emulator.

define LESS  $3C ; < $3c
define GRTR  $3E ; > $3e
define DOT   $2E ; . $2e
define COM   $2C ; , $2c
define INC   $2B ; + $2b
define DEC   $2D ; - $2d
define OPEN  $5B ; [ $5b
define CLODE $5D ; ] $5d

define CP $20 ; $20/21 for code pointer
define AP $30 ; $30/31 for arena pointer

    ; let's get started
    JSR init ; setup our pointers

    ; get a command and process it
    JSR getcmd
    BEQ done    ; 0 means end of code.

done:
    BRK

;
; Subroutines below this line
;

    ; get command in A
getcmd:
    LDA $0000
    RTS

inccp:
    RTS

deccp:
    RTS

incap:
    RTS

decap:
    RTS

appp:
    RTS

apmm:
    RTS

apout:
    RTS

apin:
    RTS

matcho:
    RTS

matchc:
    RTS

init:
    LDA <code
    STA CP
    LDS >code
    STA CP+1

    LDA <arena
    STA AP
    LDA >arena
    STA AP+1

;
; data below this line
;

code:
    TXT ""
    TXT ""
    dcb 0 ; end of program

arena:
    dsb 30000