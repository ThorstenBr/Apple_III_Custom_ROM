;******************************************************************
;* APPLE /// ROM - DIAGNOSTIC ROUTINES
;* COPYRIGHT 1979 BY APPLE COMPUTER, INC.
;******************************************************************

           .setcpu "6502"
           .segment "CODE"

;           .ABSOLUTE
;           .PROC   SARATESTS

;******************************************************************
;
; SARA DIAGNOSTIC TEST ROUTINES
;
; DECEMBER 18,1979
;  BY
; W. BROEDNER & R. LASHLEY 0000
;
; COPYRIGHT 1979 BY APPLE COMPUTER, INC.
;
;******************************************************************

ROM        =    $01
ZRPG       =    $00
ZRPG1      =    $10
PTRLO      =    ZRPG1+$08
PTRHI      =    ZRPG1+$09
BNK        =    ZRPG1+$0A
IBCMD      =    $87
IBBUFP     =    $85
PREVTRK    =    $91
BLOCKIO    =    $F479
CV         =    $5D
STK0       =    $FF
IBNK       =    $1400+PTRHI
PHPR       =    $1800+ZRPG1
KYBD       =    $C000
KEYBD      =    $C008
KBDSTRB    =    $C010
PDLEN      =    $C058
ADRS       =    $C047
GRMD       =    $C050
TXTMD      =    $C051
ADTO       =    $C066
DISKOFF    =    $C0D0
ACIAST     =    $C0F1
ACIACM     =    $C0F2
ACIACN     =    $C0F3
SLT1       =    $C100
SLT2       =    $C200
SLT3       =    $C300
SLT4       =    $C400
EXPROM     =    $CFFF
ZPREG      =    $FFD0
SYSD1      =    $FFDF
SYSD2      =    $FFD2
SYSD3      =    $FFD3
SYSEO      =    $FFE0
BNKSW      =    $FFEF
SYSE2      =    $FFE2
SYSE3      =    $FFE3
COUT       =    $FC39
CROUT1     =    $FD07
KEYIN      =    $FD0F
SETCVH     =    $FBDB
CLDSTRT    =    $FD98
SETUP      =    $FD9D
MONITOR    =    $F901
;
; DAN][ / ProDOS interface registers
DAN2_COMMAND = $42
DAN2_UNIT    = $43
DAN2_BUFLO   = $44
DAN2_BUFHI   = $45
DAN2_BLKLO   = $46
DAN2_BLKHI   = $47
DAN2_DENT    = $48  ; device entry address as expected by SOSHDBOOT
;
           .ORG    $F4C5
RAMTBL:    .BYTE   $00,$B1,$B2,$BA,$B9,$10,$00,$13

CHPG       =    *
           .BYTE  "RA"
           .BYTE   $CD          ; M
           .BYTE  "RO"
           .BYTE   $CD          ; M
           .BYTE  "VI"
           .BYTE   $C1          ; A
           .BYTE  "ACI"
           .BYTE   $C1          ; A
           .BYTE  "A/"
           .BYTE   $C4          ; D
           .BYTE  "DIAGNOSTI"

           .BYTE   $C3          ; C
           .BYTE  "Z"
           .BYTE   $D0          ; P
           .BYTE  "RETR"
           .BYTE   $D9          ; Y
;
; SETUP SYSTEM
;
;
DIAGN:     LDA     #$52+ROM     ; TURN OFF SCREEN, SET 2MHZ SPEED
           STA     SYSD1        ; AND RUN OFF ROM
           LDX     #00          ; SET BANK SWITCH TO ZERO
           STX     SYSEO
           STX     BNKSW
           STX     ZPREG        ; AND SET ZERO PAGE SAME
           DEX
           STX     SYSD2        ; PROGRAM DDR'S
           STX     SYSD3
           TXS
           INX
           LDA     #$0F
           STA     SYSE3
           LDA     #$3F
           STA     SYSE2
           LDY     #$0E
DISK1:     LDA     DISKOFF,Y
           DEY
           DEY
           BPL     DISK1
           LDA     KEYBD        ; READ KEYBOARD MODIFIERS
           AND     #04          ; CTRL KEY PRESSED?
           BNE     NXBYT        ; RUN DIAGNOSTICS WHEN NOT PRESSED
           JMP     RECON        ; OTHERWISE BOOT IMMEDIATELY
;
; VERIFY ZERO PAGE
;
NXBYT:     LDA     #01          ; ROTATE A 1 THROUGH
NXBIT:     STA     ZRPG,X       ; EACH BIT IN THE 0 PG
           CMP     ZRPG,X       ; TO COMPLETELY TEST
NOGOOD:    BNE     NOGOOD       ; THE PAGE. HANG IF NOGOOD.
           ASL     A            ; TRY NEXT BIT OF BYTE
           BNE     NXBIT        ; UNTIL BYTE IS ZERO.
           INX                  ; CONTINUE UNTIL PAGE
           BNE     NXBYT        ; IS DONE.
CNTWR:     TXA                  ; PUSH A DIFFERENT
           PHA                  ; BYTE ONTO THE
           INX                  ; STACK UNTIL ALL
           BNE     CNTWR        ; STCK BYTES ARE FULL.
           DEX                  ; THEN PULL THEM
           STX     PTRLO        ; OFF AND COMPARE TO
PULBT:     PLA                  ; THE COUNTER GOING
           CMP     PTRLO        ; BACKWARDS. HANG IF
           BNE     NOGOOD       ; THEY DON'T AGREE.
           DEC     PTRLO        ; GET NEXT COUNTER BYTE
           BNE     PULBT        ; CONTINUE UNTIL STACK
           PLA                  ; IS DONE. TEST LAST BYTE
           BNE     NOGOOD       ; AGAINST ZERO.
;
; SIZE IN MEMORY
;
           LDX     #08          ; ZERO THE BYTES USED TO DISPLAY
NOMEM:     STA     ZRPG1,X      ; THE BAD RAM LOCATIONS
           DEX                  ; EACH BYTE= A CAS LINE
           BPL     NOMEM        ; ON THE SARA BOARD.
           LDX     #02          ; STARTING AT PAGE 2
NMEM1:     STX     PTRHI        ; TEST THE LAST BYTE
           LDA     #00          ; IN EACH MEM PAGE TO
           LDY     #$FF         ; SEE IF THE CHIPS ARE
           STA     (PTRLO),Y    ; THERE..(AVOID 0 & STK PAGES)
           CMP     (PTRLO),Y    ; CAN THE BYTE BE O'D?
           BEQ     NMEM2
           JSR     RAM          ; NO, FIND WHICH CAS IT IS.
           STY     ZRPG1,X      ; SET CORRES. BYTE TO $FF
           LDX     PTRHI        ; RESTORE X REGISTER
NMEM2:     INX                  ; AND INCREMENT TO NEXT
           CPX     #$C0         ; PAGE UNTIL I/O IS REACHED.
           BNE     NMEM1
           LDX     #$20         ; THEN RESET TO PAGE 20
           INC     BNKSW        ; AND GOTO NEXT BANK TO
           LDA     BNKSW        ; CONTINUE.(MASK INPUTS
           AND     #$0F         ; FROM BANKSWITCH TO SEE
           CMP     #03          ; WHAT SWITCH IS SET TO)
           BNE     NMEM1        ; CONTINUE UNTIL BANK '3'
;
; SETUP SCREEN
;
ERRLP:     JSR     SETUP        ; CALL SCRN SETUP ROUTINE
           LDX     #00          ; SETUP I/O AGAIN
           STX     SYSEO        ; FOR VIA TEST
           DEX                  ; PROGRAM DATA DIR
           STX     SYSD2        ; REGISTERS
           STX     SYSD3
           LDA     #$3F
           STA     SYSE2
           LDA     #$0F
           STA     SYSE3
           LDX     #$10         ; HEADING OF 'DIAGNOSTICS' WITH
           JSR     STRWT        ; THIS SUBROUTINE
ERRLP1:    LDX     #00          ; PRINT 'RAM'
           STX     CV           ; SET CURSOR TO 2ND LINE
           LDA     #04          ; SPACE CURSOR OUT 3
           JSR     SETCVH       ; (X STILL=0 ON RETURN)
           JSR     STRWT        ; THE SAME SUBROUTINE
           LDX     #07          ; FOR BYTES 7 - 0 IN
RAMWT1     =    *
           LDA     ZRPG1,X      ; OUT EACH BIT AS A
           LDY     #08          ; ' ' OR '1' FOR INDICATE BAD OR MISSING RAM
RAMWT2:    ASL     A            ; CHIPS SUBROUTINE 'RAM'        RAM
           PHA                  ; SETS UP THESE BYTES
           LDA     #$AE         ; LOAD A '.' TO ACC.
           BCC     RAMWT4
           LDA     #$31         ; LOAD A '1' TO ACC.
RAMWT4:    JSR     COUT         ; AND PRINT IT
           PLA                  ; RESTORE BYTE
           DEY                  ; AND ROTATE ALL 8
           BNE     RAMWT2       ; TIMES
           JSR     CROUT1       ; CLEAR TO END OF LINE.
           DEX
           BPL     RAMWT1
;
; ZPG & STK TEST
;
           TXS
           STY     BNKSW
ZP1:       TYA
           STA     ZPREG
           STA     STK0
           INY
           TYA
           PHA
           PLA
           INY
           CPY     #$20
           BNE     ZP1
           LDY     #00
           STY     ZPREG
           STX     PTRLO
ZP2:       INX
           STX     PTRHI
           TXA
           CMP     (PTRLO),Y
           BNE     ZP3
           CPX     #$1F
           BNE     ZP2
           BEQ     ROMTST
ZP3        =       *            ; CHIP IS THERE, BAD ZERO AND STACK
           LDX     #$1A         ; SO PRINT 'ZP' MESSAGE
           JSR     MESSERR      ; & SET FLAG (2MHZ MODE)
;
; ROM TEST ROUTINE
;
ROMTST:    LDA     #00          ; SET POINTERS TO
           TAY                  ; $F000
           LDX     #$F0
           STA     PTRLO
           STX     PTRHI        ; SET X TO $FF
           LDX     #$FF         ; FOR WINDOWING I/O
ROMTST1:   EOR     (PTRLO),Y    ; COMPUTE CHKSUM ON
           CPX     PTRHI
           BNE     ROMTST2      ; EACH ROM BYTE,
           CPY     #$BF         ; RANGES FFC0-FFEF
           BNE     ROMTST2
           LDY     #$EF
ROMTST2:   INY
           BNE     ROMTST1
           INC     PTRHI
           BNE     ROMTST1
           TAY                  ; TEST ACC. FOR 0
           BEQ     VIATST       ; YES, NEXT TEST
           LDX     #03          ; PRINT 'ROM' AND
           JSR     MESSERR      ; SET ERROR
;
; VIA TEST ROUTINE
;
VIATST:    CLC                  ; SET UP FOR ADDING BYTES
           CLD
           LDA     SYSEO        ; MASK OFF INPUT BITS
           AND     #$3F         ; AND STORE BYTE IN
           STA     PTRLO        ; TEMPOR. LOCATION
           LDA     BNKSW        ; MASK OFF INPUT BITS
           AND     #$4F         ; AND ADD TO STORED
           ADC     PTRLO        ; BYTE IN TEMP. LOC.
           ADC     ZPREG        ; ADD REMAINING
           STA     PTRLO        ; REGISTERS OF THE
           LDA     SYSD1        ; VIA'S
           AND     #$5F         ; (MASK THIS ONE)
           ADC     PTRLO        ; AND TEST
           ADC     SYSD2        ; TO SEE
           ADC     SYSD3        ; IF THEY AGREE
           ADC     SYSE2        ; WITH THE RESET
           ADC     SYSE3        ; CONDITION.
           CMP     #$E0+ROM     ;  =E1?
           BEQ     ACIA         ; YES, NEXT TEST
           LDX     #06          ; NO, PRINT 'VIA' MESS
           JSR     MESSERR      ; AND SET ERROR FLAG
;
; ACIA TEST
;
ACIA:      CLC                  ; SET UP FOR ADDITION
           LDA     #$9F         ; MASK INPUT BITS
           AND     ACIAST       ; FROM STATUS REG
           ADC     ACIACM       ; AND ADD DEFAULT STATES
           ADC     ACIACN       ; OIF CONTROL AND COMMAND
           CMP     #$10         ; REGS.        =10?
           BEQ     ATD          ; YES, NEXT TEST
           LDX     #09          ; NO,        'ACIA' MESSAGE AND
           JSR     MESSERR      ; THEN SET ERROR FLAG
.IFDEF ORIGINAL
;
; A/D TEST ROUTINE
;
ATD:       LDA     #$C0
           STA     $FFDC
           LDA     PDLEN+2
           LDA     PDLEN+6
           LDA     PDLEN+4
           LDY     #$20
ADCTST1:   DEY                  ; WAIT FOR 40 USEC
           BNE     ADCTST1
           LDA     PDLEN+5      ; SET A/D RAMP
ADCTST3:   INY                  ; COUNT FOR CONVERSION
           BEQ     ADCERR
           LDA     ADTO         ; IF BIT 7=1?
           BMI     ADCTST3      ; YES, CONTINUE
           TYA                  ; NO, MOVE COUNT TO ACC
           AND     #$E0         ; ACC<32
           BEQ     KEYPLUG
ADCERR     =       *            ; NO
           LDX     #$0D         ; PRINT 'A/D' MESS
           JSR     MESSERR      ; AND SET ERROR FLAG
;
; KEYBOARD PLUGIN TEST
;
KEYPLUG:   LDA     KEYBD        ; IS KYBD PLUGGED IN?
           ASL     A            ; (IS LIGHT CURRENT
           BPL     SEX          ; PRESENT?) NO, BRANCH
           LDA     SYSD1        ; IS ERROR FLAG SET?
           BMI     SEX          ; ERROR HANG
.ELSE
ATD:       LDA     SYSD1        ; IS ERROR FLAG SET? (1MHZ FLAG INDICATES AN ERROR)
HANG:      BMI     HANG         ; ERROR HANG
DAN2FIND:
           LDA     KEYBD        ; load keyboard modifiers
           AND     #$08         ; check "alpha lock" key pressed?
           BEQ     DISKBOOT     ; boot from disk if alpha lock is pressed
           LDX     #$05         ; start scanning at slot 4(=5-1)
           LDA     #DAN2IDOFS   ; prepare slot address (lower byte)
           STA     DAN2_DENT
DAN2NXSLOT:DEX                  ; calculate next slot
           BEQ     DISKBOOT     ; check slots 1-4, otherwise abort and boot from disk
           TXA                  ; prepare the upper address byte for the slot
           ORA     #$C0         ; I/O segment address ($C1-$C4)
           STA     DAN2_DENT+1  ; store upper address byte
           LDY     #DAN2IDLEN-1 ; load length of card ID
:          LDA     (DAN2_DENT),Y; load byte from slot ROM
           CMP     DAN2ID,Y     ; Compare with known DAN2 ROM signature
           BNE     DAN2NXSLOT   ; Not a DAN2 controller if bytes don't match: check next slot
           DEY                  ; count remaining bytes to check
           BPL     :-           ; check all bytes of the ID
           LDY     #$FF-DAN2IDOFS
           LDA     (DAN2_DENT),Y; load DAN][ ProDOS handler entry (lower byte)
           STA     DAN2_DENT    ; update slot address (now points to ProDOS handler entry)
           LDA     DAN2_DENT+1  ; load slot address (upper byte) and return
           BNE     DAN2BOOT     ; boot from DAN][
DAN2GO:    JMP     (DAN2_DENT)  ; jump to DAN][ controller handler

           SPACER1 = *
           .REPEAT $F686-SPACER1
           .BYTE $FF
           ;.BYTE $F686-SPACER1
           .ENDREP
;F686
.ENDIF
;
; RECONFIGURE THE SYSTEM
;
RECON:     LDA     #$77         ; TURN ON SCREEN
           STA     SYSD1
           JSR     CLDSTRT      ; INITIALIZE MONITOR AND DEFAULT CHARACTER SET
           BIT     KBDSTRB      ; CLEAR KEYBOARD
           LDA     EXPROM       ; DISABLE ALL SLOTS
           LDA     $C020
           LDA     #$10         ; TEST FOR "APPLE 1"
           AND     KEYBD
.IFDEF ORIGINAL
           BNE     DISKBOOT     ; NO, DO REGULAR BOOT
.ELSE
           BNE     DAN2FIND     ; check if DAN][ controller card present
.ENDIF
GOMONITOR: JSR     MONITOR      ; AND NEVER COME BACK
DISKBOOT:  LDX     #01          ; READ BLOCK 0
           STX     IBCMD
           DEX
           STX     IBBUFP       ; INTO RAM AT $AOOO
           LDA     #$A0
           STA     IBBUFP+1
           LSR     A            ; FOR TRACK 80
           STA     PREVTRK      ; MAKE IT RECALIBRATE TOO!
           TXA
           JSR     BLOCKIO
           BCC     GOBOOT       ; IF WE'VE SUCCEEDED. DO IT UP
           LDX     #$1C
           JSR     STRWT        ; 'RETRY'
           JSR     KEYIN
           BCS     DISKBOOT
GOBOOT:    JMP     $A000        ; GO TO IT FOOL...
;
; SYSTEM EXCERCISER
;
.IFDEF ORIGINAL
           ; This cycles through the slot area when no keyboard is plugged.
           ; This was added as a means to help with board repairs.
           ; => Disabled to make space for DAN][ boot support
SEX:       LDY     #$7F         ; TRY FROM
SEX1:      TYA                  ; $7F TO 0
           AND     #$FE         ; ADD.=
           EOR     #$4E         ; $4E OR $4F
           BEQ     SEX2         ; YES,        SKP
           LDA     KYBD,Y       ; NO, CONT
SEX2:      DEY                  ; NEXT ADD
           BNE     SEX1
           LDA     TXTMD        ; SET TXT
SEX3:      LDA     SLT1,Y       ; EXCERCISE
           LDA     SLT2,Y       ; ALL
           LDA     SLT3,Y       ; SLOTS
           LDA     SLT4,Y
           LDA     EXPROM       ; DISABLE EXPANSION ROM AREA
           INY
           BNE     SEX3
.ELSE
           ; NO SEX: the system excerciser is disabled to make space for the DAN][ boot support.
DAN2BOOT:
           ; enters with slot number of DANII card in A
           ASL     A            ; shift by 4
           ASL     A
           ASL     A
           ASL     A
           STA     DAN2_UNIT
           LDA     #$A3         ; load Apple /// boot block from the controller
           STA     DAN2_COMMAND ; command=$A3=load Apple 3 boot block
           LDA     #$A0
           STA     DAN2_BUFHI   ; set buffer address to $A0..
           LDA     #$00
           STA     DAN2_BUFLO   ; set buffer address to $..00
           STA     DAN2_BLKLO   ; read block 0
           STA     DAN2_BLKHI
           JSR     DAN2GO       ; call DANII handler to load boot block
           BCS     GOMONITOR    ; enter monitor when loading failed
           BCC     GOBOOT       ; unconditional branch to loaded boot program

DAN2IDLEN = $05                       ; check 5 bytes in ROM for card detection
DAN2IDOFS = $0A                       ; offset where to find the DAN2 card's ID
DAN2ID:    .BYTE $A9,$01,$9D,$FB,$BF  ; ROM bytes at offset $0A: "LDA #$01;STA $BFFB,X"

           SPACER2 = *
           .REPEAT $F6E5-SPACER2
           .BYTE $FF
           ;.BYTE $F6E5-SPACER2
           .ENDREP
           .BYTE $69 ; ROM CHECKSUM
;F6E6
.ENDIF
;
; RAM TEST ROUTINE
;
USRENTRY:  LDA     #$72+ROM
           STA     SYSD1
           LDA     #$18
           STA     ZPREG
           LDA     #00
           LDX     #07
RAMTSTO:   STA     ZRPG1,X
           DEX
           BPL     RAMTSTO
           JSR     RAMSET
           PHP
RAMTST1:   JSR     RAMWT
           JSR     RAMWT
           PLP
           ROR     A
           PHP
           JSR     PTRINC
           BNE     RAMTST1
           JSR     RAMSET
           PHP
RAMTST4:   JSR     RAMRD
           PHA
           LDA     #00
           STA     (PTRLO),Y
           PLA
           PLP
           ROR     A
           PHP
           JSR     PTRINC
           BNE     RAMTST4
;
; RETURN TO START
;
           LDA     #00
           STA     BNKSW
           STA     ZPREG
           LDX     #07
RAMTST6:   LDA     PHPR,X
           STA     ZRPG1,X
           DEX
           BPL     RAMTST6
           JSR     ERROR
           JMP     ERRLP
;
;******************************
; SARA TEST SUBROUTINES
;******************************
;
STRWT:     LDA     CHPG,X
           PHA
           ORA     #$80         ; NORMAL VIDEO
           JSR     COUT         ; & PRINT
           INX                  ; NXT
           PLA                  ; CHR
           BPL     STRWT
           JMP     CROUT1       ; CLR TO END OF LINE
;
; SUBROUTINE RAM
;
RAM:       PHA                  ; SV ACC
           TXA                  ; CONVRT
           LSR     A            ; ADD TO
           LSR     A            ; USE FOR
           LSR     A            ; 8 ENTRY
           LSR     A
           PHP
           LSR     A
           PLP
           TAX                  ; LOOKUP
           LDA     RAMTBL,X     ; IF VAL
           BPL     RAMO         ; <0, GET
           PHA                  ; WHICH
           LDA     BNKSW
           AND     #$0F
           TAX
           PLA
           CPX     #00
           BEQ     RAM1         ; BANK?
           LSR     A            ; SET
           LSR     A            ; PROPER
           LSR     A            ; RAM
           DEX                  ; VAL
           BNE     RAM1
           AND     #05          ; CONVERT
RAMO:      BNE     RAM1         ; TO VAL
           TXA
           BEQ     RAM00
           LDA     #03
RAM00:     BCC     RAM1
           EOR     #03
RAM1:      AND     #07          ; BANKSW
           TAX
           PLA
           RTS
;
; SUBROUTINE ERROR
;
MESSERR:   JSR     STRWT        ; PRINT MESSAGE FIRST
ERROR:     LDA     #$F2+ROM     ; SET 1
           STA     SYSD1        ; MHZ MO
           RTS
;
; SUBROUTINE RAMSET
;
RAMSET:    LDX     #01
           STX     BNK
           LDY     #00
           LDA     #$AA
           SEC
RAMSET1:   PHA
           PHP
           LDA     BNK
           ORA     #$80
           STA     IBNK
           LDA     #02
           STA     PTRHI
           LDX     #00
           STX     PTRLO
           PLP
           PLA
           RTS
;
; SUBROUTINE PTRINC
;
PTRINC:    PHA
           INC     PTRLO
           BNE     RETS
           LDA     BNK
           BPL     PINC1
           LDA     PTRHI
           CMP     #$13
           BEQ     PINC2
           CMP     #$17
           BNE     PINC1
           INC     PTRHI
PINC2:     INC     PTRHI
PINC1:     INC     PTRHI
           BNE     RETS
           DEC     BNK
           DEC     BNK
           JSR     RAMSET1
RETS:      PLA
           LDX     BNK
           CPX     #$FD
           RTS
;
; SUBROUTINE RAMERR
;
RAMERR:    PHA
           LDX     PTRHI
           LDY     BNK
           BMI     RAMERR4
           TXA
           BMI     RAMERR5
           CLC
           ADC     #$20
RAMERR2:   STY     BNKSW
           TAX
RAMERR3:   JSR     RAM
           PLA
           PHA
           LDY     #00
           EOR     (PTRLO),Y
           ORA     ZRPG1,X
           STA     ZRPG1,X
           PLA
           RTS
RAMERR4:   LDA     #00
           STA     BNKSW
           BEQ     RAMERR3
RAMERR5:   SEC
           SBC     #$60
           INY
           BNE     RAMERR2
;
; SUBROUTINE RAMWT
;
RAMWT:     EOR     #$FF
           STA     (PTRLO),Y
RAMRD:     CMP     (PTRLO),Y
           BNE     RAMERR

;           .END
; F7FE
