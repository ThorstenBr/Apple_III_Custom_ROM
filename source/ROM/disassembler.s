; Disassembler - from the Apple II ROM.
; Adapted by Thorsten C. Brehm, 2023

; This was normally not part of the Apple III ROM, since it wouldn't fit in the Apple III default 4KB ROM.
; However, when an 8KB ROM is used, we can indeed can add the disassembler functionality.

; We have the area of $F4F3-$F7FE available: this ROM area normally contains the startup and diagnostics code.
; But this code only ever get's executed in the default ROM bank (bank 1). We install the custom monitor in the
; alternate ROM bank (bank 0), and this never executes the startup/diagnostics.

.IFDEF BANK0ROM
.ORG $F4F3
.ELSE
.ORG $A200  ; for testing only
.ENDIF

.EXPORT BANK0LIST  ; BANK0 variant of "LIST"
.EXPORT BANK0A1PC  ; BANK0 variant of "A1PC", restoring registers
.EXPORT SAVE       ; save registers
.EXPORT RESTORE    ; restore registers

.IFDEF BANK0ROM
.EXPORT BANK0RWERROR
.EXPORT BANK0IRQ   ; BANK0 variant of "IRQ" vector
.IMPORT MON
.IMPORT ERROR2
.ENDIF

; Apple III ROM routines
COUT       = $FC39
PRBYTE     = $F9AE
NOSTOP     = $FD07
CROUT      = NOSTOP
RDKEY      = $FD0C

ENVREG     = $FFDF ; Environment Register
BEEPER     = $C040 ; beep!

; Local zero page registers (non-standard, not normally used by Apple /// ROM)
DBGREGS    = $4F
ACC        = DBGREGS
XREG       = DBGREGS+1
YREG       = DBGREGS+2
STATUS     = DBGREGS+3
SPNT       = DBGREGS+4
LMNEM      = DBGREGS+5
RMNEM      = DBGREGS+6
FORMAT     = DBGREGS+7
LASTIN     = DBGREGS+8
LENGTH     = LASTIN

; Apple III zero page registers
SCRNLOC    =    $58
PCL        =    SCRNLOC+$1A
PCH        =    SCRNLOC+$1B
A1L        =    SCRNLOC+$1C
A1H        =    A1L+1
A2L        =    A1L+2
A2H        =    A1L+3
A3L        =    A1L+4
A3H        =    A1L+5
A4L        =    A1L+6
A4H        =    A1L+7
TEMP       =    A1L+$0C ; $80
; Registers >=$81... are used by diskio ROM routines!

; generate Apple-ASCII string (with MSB set)
.MACRO   ASCHI CH
.BYTE    CH | $80
.ENDMACRO

.IFNDEF BANK0ROM
; for testing only
ENTRY:          BIT BEEPER
                LDA ENVREG
                ORA #$73
                AND #$77
                STA ENVREG
                LDA #$F8
                STA PCH
                LDA #$00
                STA PCL
                JSR INSDS1
                JSR RGDSP1
:               LDX #$00
                JSR BANK0LIST
                JSR RDKEY
                CMP #' '+$80
                BEQ :-
                jmp $A000
.ENDIF

BANK0LIST:      jsr     A1PC              ;move A1 (2 bytes) to
                lda     #$14              ;  PC if spec'd and
LIST2:          pha                       ;  dissemble 20 instrs
                jsr     INSTDSP
                jsr     PCADJ             ;adjust PC after each instruction
                sta     PCL
                sty     PCH
                pla
                sec
                sbc     #$01              ;next of 20 instructions
                bne     LIST2
                jmp     CROUT

PRYX2:          jsr     CROUT
                jsr     PRNTYX
                ldy     #$00
                lda     #$ad              ;print '-'
                jmp     COUT

A1PC:           txa                       ;if user specified an address,
                beq     A1PCRTS           ;  copy it from A1 to PC
A1PCLP:         lda     A1L,x             ;yep, so copy it
                sta     PCL,x
                dex
                bpl     A1PCLP
A1PCRTS:        rts


SCRN2:          bcc     RTMSKZ            ;if even, use lo H
                lsr     A
                lsr     A
                lsr     A                 ;shift high half byte down
                lsr     A
RTMSKZ:         and     #$0f              ;mask 4-bits
                rts

INSDS1:         ldx     PCL               ;print PCL,H
                ldy     PCH
                jsr     PRYX2
                jsr     PRBLNK            ;followed by a blank
                lda     (PCL,x)           ;get opcode
INSDS2:         tay
                lsr     A                 ;even/odd test
                bcc     IEVEN
                ror     A                 ;bit 1 test
                bcs     ERR               ;XXXXXX11 invalid op
                cmp     #$a2
                beq     ERR               ;opcode $89 invalid
                and     #$87              ;mask bits
IEVEN:          lsr     A                 ;LSB into carry for L/R test
                tax
                lda     FMT1,x            ;get format index byte
                jsr     SCRN2             ;R/L H-byte on carry
                bne     GETFMT
ERR:            ldy     #$80              ;substitute $80 for invalid ops
                lda     #$00              ;set print format index to 0
GETFMT:         tax
                lda     FMT2,x            ;index into print format table
                sta     FORMAT            ;save for adr field formatting
                and     #$03              ;mask for 2-bit length (P=1 byte, 1=2 byte, 2=3 byte)
                sta     LENGTH
                tya                       ;opcode
                and     #$8f              ;mask for 1XXX1010 test
                tax                       ; save it
                tya                       ;opcode to A again
                ldy     #$03
                cpx     #$8a
                beq     MNNDX3
MNNDX1:         lsr     A
                bcc     MNNDX3            ;form index into mnemonic table
                lsr     A
MNNDX2:         lsr     A                 ;1) 1XXX1010=>00101XXX
                ora     #$20              ;2) XXXYYY01=>00111XXX
                dey                       ;3) XXXYYY10=>00110XXX
                bne     MNNDX2            ;4) XXXYY100=>00100XXX
                iny                       ;5) XXXXX000=>000XXXXX
MNNDX3:         dey
                bne     MNNDX1
                rts

                .byte   $ff,$ff,$ff

INSTDSP:        jsr     INSDS1            ;gen fmt, len bytes
                pha                       ;save mnemonic table index
PRNTOP:         lda     (PCL),y
                jsr     PRBYTE
                ldx     #$01              ;print 2 blanks
PRNTBL:         jsr     PRBL2
                cpy     LENGTH            ;print inst (1-3 bytes)
                iny                       ;in a 12 chr field
                bcc     PRNTOP
                ldx     #$03              ;char count for mnemonic print
                cpy     #$04
                bcc     PRNTBL
                pla                       ;recover mnemonic index
                tay
                lda     MNEML,y
                sta     LMNEM             ;fech 3-char mnemonic
                lda     MNEMR,y           ;  (packed in 2-bytes)
                sta     RMNEM
PRMN1:          lda     #$00
                ldy     #$05
PRMN2:          asl     RMNEM             ;shift 5 bits of character into A
                rol     LMNEM
                rol     A                 ;  (clears carry)
                dey
                bne     PRMN2
                adc     #$bf              ;add "?" offset
                jsr     COUT              ;output a char of MNEM
                dex
                bne     PRMN1
                jsr     PRBLNK            ;output 3 blanks
                ldy     LENGTH
                ldx     #$06              ;cnt for 6 format bits
PRADR1:         cpx     #$03
                beq     PRADR5            ;if X=3 then addr.
PRADR2:         asl     FORMAT
                bcc     PRADR3
                lda     CHAR1-1,x
                jsr     COUT
                lda     CHAR2-1,x
                beq     PRADR3
                jsr     COUT
PRADR3:         dex
                bne     PRADR1
                rts

PRADR4:         dey
                bmi     PRADR2
                jsr     PRBYTE
PRADR5:         lda     FORMAT
                cmp     #$e8              ;handle rel adr mode
                lda     (PCL),y           ;special (print target,
                bcc     PRADR4            ;  not offset)
RELADR:         jsr     PCADJ3
                tax                       ;PCL,PCH+OFFSET+1 to A,Y
                inx
                bne     PRNTYX            ;+1 to Y,X
                iny
PRNTYX:         tya
PRNTAX:         jsr     PRBYTE            ;output target adr
PRNTX:          txa                       ;  of branch and return
                jmp     PRBYTE

PRBLNK:         ldx     #$03              ;blank count
PRBL2:          lda     #$a0              ;load a space
PRBL3:          jsr     COUT              ;output a blank
                dex
                bne     PRBL2             ;loop until count=0
                rts

PCADJ:          sec                       ;0=1 byte, 1=2 byte,
PCADJ2:         lda     LASTIN            ;  2=3 byte
PCADJ3:         ldy     PCH
                tax                       ;test displacement sign
                bpl     PCADJ4            ;  (for rel branch)
                dey                       ;extend neg by decr PCH
PCADJ4:         adc     PCL
                bcc     RTS2              ;PCL+LENGTH(or DISPL)+1 to A
                iny                       ;  carry into Y (PCH)
RTS2:           rts

                   ; FMT1 bytes:  XXXXXXY0 instrs
                   ; if Y=0       then left half byte
                   ; if Y=1       then right half byte
                   ;                   (x=index)
FMT1:           .byte   $04,$20,$54,$30,$0d,$80,$04,$90,$03,$22,$54,$33,$0d,$80,$04,$90
                .byte   $04,$20,$54,$33,$0d,$80,$04,$90,$04,$20,$54,$3b,$0d,$80,$04,$90
                .byte   $00,$22,$44,$33,$0d,$c8,$44,$00,$11,$22,$44,$33,$0d,$c8,$44,$a9
                .byte   $01,$22,$44,$33,$0d,$80,$04,$90,$01,$22,$44,$33,$0d,$80,$04,$90
                .byte   $26,$31,$87,$9a
                   ; ZZXXXY01 instr's
FMT2:           .byte   $00               ;err
                .byte   $21               ;imm
                .byte   $81               ;z-page
                .byte   $82               ;abs
                .byte   $00               ;implied
                .byte   $00               ;accumulator
                .byte   $59               ;(zpag,x)
                .byte   $4d               ;(zpag),y
                .byte   $91               ;zpag,x
                .byte   $92               ;abs,x
                .byte   $86               ;abs,y
                .byte   $4a               ;(abs)
                .byte   $85               ;zpag,y
                .byte   $9d               ;relative
CHAR1:          ASCHI   ','
                ASCHI   ')'
                ASCHI   ','
                ASCHI   '#'
                ASCHI   '('
                ASCHI   '$'
CHAR2:          ASCHI   'Y'
                .byte   $00
                ASCHI   'X'
                ASCHI   '$'
                ASCHI   '$'
                .byte   $00
                   ; (From original ROM listing)
                   ; MNEML is of form:
                   ; (A) XXXXX000
                   ; (B) XXXYY100
                   ; (C) 1XXX1010
                   ; (D) XXXYYY10
                   ; (E) XXXYYY01
                   ;     (X=index)
MNEML:          .byte   $1c
                .byte   $8a
                .byte   $1c
                .byte   $23
                .byte   $5d
                .byte   $8b
                .byte   $1b
                .byte   $a1
                .byte   $9d
                .byte   $8a
                .byte   $1d
                .byte   $23
                .byte   $9d
                .byte   $8b
                .byte   $1d
                .byte   $a1
                .byte   $00
                .byte   $29
                .byte   $19
                .byte   $ae
                .byte   $69
                .byte   $a8
                .byte   $19
                .byte   $23
                .byte   $24
                .byte   $53
                .byte   $1b
                .byte   $23
                .byte   $24
                .byte   $53
                .byte   $19               ;(A) format above
                .byte   $a1
                .byte   $00
                .byte   $1a
                .byte   $5b
                .byte   $5b
                .byte   $a5
                .byte   $69
                .byte   $24               ;(B) format
                .byte   $24
                .byte   $ae
                .byte   $ae
                .byte   $a8
                .byte   $ad
                .byte   $29
                .byte   $00
                .byte   $7c               ;(C) format
                .byte   $00
                .byte   $15
                .byte   $9c
                .byte   $6d
                .byte   $9c
                .byte   $a5
                .byte   $69
                .byte   $29               ;(D) format
                .byte   $53
                .byte   $84
                .byte   $13
                .byte   $34
                .byte   $11
                .byte   $a5
                .byte   $69
                .byte   $23               ;(E) format
                .byte   $a0
MNEMR:          .byte   $d8
                .byte   $62
                .byte   $5a
                .byte   $48
                .byte   $26
                .byte   $62
                .byte   $94
                .byte   $88
                .byte   $54
                .byte   $44
                .byte   $c8
                .byte   $54
                .byte   $68
                .byte   $44
                .byte   $e8
                .byte   $94
                .byte   $00
                .byte   $b4
                .byte   $08
                .byte   $84
                .byte   $74
                .byte   $b4
                .byte   $28
                .byte   $6e
                .byte   $74
                .byte   $f4
                .byte   $cc
                .byte   $4a
                .byte   $72
                .byte   $f2
                .byte   $a4               ;(A) format
                .byte   $8a
                .byte   $00
                .byte   $aa
                .byte   $a2
                .byte   $a2
                .byte   $74
                .byte   $74
                .byte   $74               ;(B) format
                .byte   $72
                .byte   $44
                .byte   $68
                .byte   $b2
                .byte   $32
                .byte   $b2
                .byte   $00
                .byte   $22               ;(C) format
                .byte   $00
                .byte   $1a
                .byte   $1a
                .byte   $26
                .byte   $26
                .byte   $72
                .byte   $72
                .byte   $88               ;(D) format
                .byte   $c8
                .byte   $c4
                .byte   $ca
                .byte   $26
                .byte   $48
                .byte   $44
                .byte   $44
                .byte   $a2               ;(E) format
                .byte   $c8

; register display (A/X/Y/P/S)
RGDSP1:         lda     #$45
                sta     A3L
                lda     #$00
                sta     A3H
                ldx     #$fb
RDSP1:          lda     #$a0
                jsr     COUT
                lda     RTBL-251,x
                jsr     COUT
                lda     #$bd
                jsr     COUT
                lda     ACC+5,x         ;(this is DFB $B5,$4A in listing)
                jsr     PRBYTE
                inx
                bmi     RDSP1
                jmp     CROUT

RTBL:           ASCHI 'A'
                ASCHI 'X'
                ASCHI 'Y'
                ASCHI 'P'
                ASCHI 'S'

; save registers and flags when breaking execution
SAVE:           sta     ACC
SAV1:           stx     XREG
                sty     YREG
                php
                pla
                sta     STATUS
                tsx
                stx     SPNT
                cld
                rts

; restore registers and flags before continuing execution
RESTORE:        lda     STATUS
                pha
                lda     ACC
RESTR1:         ldx     XREG
                ldy     YREG
                plp
                rts

BANK0A1PC:      JSR     A1PC         ; STUFF PROGRAM COUNTER
                JMP     RESTORE      ; restore registers and flags, then return

.IFDEF BANK0ROM
; we needed to remove a few bytes behind CMDTAB/CMDVEC, since we extended the tables for the
; new "LIST" command. The following routine was moved to here instead...
.export NXTA4
.import NXTA1
NXTA4:          INC     A4L          ; BUMP 16 BIT POINTERS
                BNE     BANK0NXTA1
                INC     A4H
BANK0NXTA1:     JMP     NXTA1

BANK0RWERROR:   JSR     PRBYTE       ; PRINT THE OFFENDER
                LDA     #$A1         ; FOLLOWED BY A "!"
                JSR     COUT
                JMP     ERROR2

BANK0IRQ:       STA     ACC
                PLA
                pha
                asl     A
                asl     A
                asl     A
                bmi     BREAK
                jmp     $FFCD        ; default APPLE /// IRQ vector in RAM

BREAK:          plp
                jsr     SAV1
                pla
                sta     PCL
                pla
                sta     PCH
OLDBRK:         jsr     INSDS1
                jsr     RGDSP1
                jmp     MON

                SPACER3 = *
                ; fill the ROM area up to $F7FE
                .REPEAT $F7FE-SPACER3
                .BYTE $FF
                .ENDREP
.ENDIF

