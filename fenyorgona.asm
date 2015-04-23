;***************************************************************
;* Feladat:
;* R�vid le�r�s:
;
;* Szerzok:
;* M�rocsoport: <merocsoport jele>
;
;***************************************************************
;* "AVR ExperimentBoard" port assignment information:
;***************************************************************
;*
;* LED0(P):PortC.0          LED4(P):PortC.4
;* LED1(P):PortC.1          LED5(P):PortC.5
;* LED2(S):PortC.2          LED6(S):PortC.6
;* LED3(Z):PortC.3          LED7(Z):PortC.7        INT:PortE.4
;*
;* SW0:PortG.0     SW1:PortG.1     SW2:PortG.4     SW3:PortG.3
;*
;* BT0:PortE.5     BT1:PortE.6     BT2:PortE.7     BT3:PortB.7
;*
;***************************************************************
;*
;* AIN:PortF.0     NTK:PortF.1    OPTO:PortF.2     POT:PortF.3
;*
;***************************************************************
;*
;* LCD1(VSS) = GND         LCD9(DB2): -
;* LCD2(VDD) = VCC         LCD10(DB3): -
;* LCD3(VO ) = GND         LCD11(DB4): PortA.4
;* LCD4(RS ) = PortA.0     LCD12(DB5): PortA.5
;* LCD5(R/W) = GND         LCD13(DB6): PortA.6
;* LCD6(E  ) = PortA.1     LCD14(DB7): PortA.7
;* LCD7(DB0) = -           LCD15(BLA): VCC
;* LCD8(DB1) = -           LCD16(BLK): PortB.5 (1=Backlight ON)
;*
;***************************************************************

.include "m128def.inc" ; Definition file for ATmega128
;* Program Constants
.equ const =$00 ; Generic Constant Structure example
;* Program Variables Definitions
.def temp      = r16
.def temp2     = r17
.def temp1     = r18
.def temp3     = r19
.def temp4     = r20
.def temp5     = r21
.def cnt       = r22
.def tim0delay = r23
.def tim2delay = r24

;***************************************************************
;* Reset & Interrupt Vectors
.cseg
.org $0000      ; Define start of Code segment
	jmp RESET     ; Reset Handler, jmp is 2 word instruction
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp BTN_IT	  ; Ext. INT4 Handler (INT gomb)
	jmp BTN_IT    ; Ext. INT5 Handler (BTN0)
	jmp BTN_IT    ; Ext. INT6 Handler (BTN1)
	jmp BTN_IT    ; Ext. INT7 Handler (BTN2)
	jmp TIMER2_IT	; Timer2 Compare Match Handler
	jmp DUMMY_IT	; Timer2 Overflow Handler
	jmp DUMMY_IT	; Timer1 Capture Event Handler
	jmp DUMMY_IT	; Timer1 Compare Match A Handler
	jmp DUMMY_IT	; Timer1 Compare Match B Handler
	jmp DUMMY_IT	; Timer1 Overflow Handler
	jmp INPUT_TIMER_IT	; Timer0 Compare Match Handler
	jmp DUMMY_IT	; Timer0 Overflow Handler
	jmp DUMMY_IT	; SPI Transfer Complete Handler
	jmp DUMMY_IT	; USART0 RX Complete Handler
	jmp DUMMY_IT	; USART0 Data Register Empty Hanlder
	jmp DUMMY_IT	; USART0 TX Complete Handler
	jmp DUMMY_IT	; ADC Conversion Complete Handler
	jmp DUMMY_IT	; EEPROM Ready Hanlder
	jmp DUMMY_IT	; Analog Comparator Handler
	jmp DUMMY_IT	; Timer1 Compare Match C Handler
	jmp DUMMY_IT	; Timer3 Capture Event Handler
	jmp DUMMY_IT	; Timer3 Compare Match A Handler
	jmp DUMMY_IT	; Timer3 Compare Match B Handler
	jmp DUMMY_IT	; Timer3 Compare Match C Handler
	jmp DUMMY_IT	; Timer3 Overflow Handler
	jmp DUMMY_IT	; USART1 RX Complete Handler
	jmp DUMMY_IT	; USART1 Data Register Empty Hanlder
	jmp DUMMY_IT	; USART1 TX Complete Handler
	jmp DUMMY_IT	; Two-wire Serial Interface Handler
	jmp DUMMY_IT	; Store Program Memory Ready Handler

.org $0046

;****************************************************************
;* DUMMY_IT interrupt handler -- CPU hangup with LED pattern
;* (This way unhandled interrupts will be noticed)

;< t�bbi IT kezelo a f�jl v�g�re! >

DUMMY_IT:
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< t�bbi IT kezelo a f�jl v�g�re! >

;***************************************************************
;* MAIN program, Initialisation part
.org $004B;
RESET:
;* Stack Pointer init,
;  Set stack pointer to top of RAM
	ldi temp, LOW(RAMEND) ; RAMEND = "max address in RAM"
	out SPL, temp 	      ; RAMEND value in "m128def.inc"
	ldi temp, HIGH(RAMEND)
	out SPH, temp

M_INIT:

; LED-ek inicializ�l�sa
	ldi temp, 0xFF
	out DDRC, temp      ; �sszes LED kimenet
	ldi temp, 0x00
	out PORTC, temp     ; �sszes LED off

; BTN-k inicializ�l�sa (DDR eset�n 0-val inicializ�ljuk bemenetk�nt!)
	ldi temp, 0x00
	sts DDRG, temp      ; SW bemenetre allitas
	out DDRE, temp      ; BTN0, BTN1, BTN2, IT enged�nyez�se bemenetk�nt
	ldi temp, 0xF0
	out PORTE, temp
	ldi temp, 0x01
	sts PORTG, temp

; poti beallitasa
	ldi temp, 0b01100011 ; hasznaljuk a potit
	out ADMUX, temp
	ldi temp, 0b11100111 ; poti config
	out ADCSRA, temp

; SRAM
	ldi XL, LOW(SRAM_START) ; X regiszter alsó byte-ja
	ldi XH, HIGH(SRAM_START) ; felső byte-ja – X a SRAM kezdetére ($0100)
	ldi YL, LOW(SRAM_START) ; X regiszter alsó byte-ja
	ldi YH, HIGH(SRAM_START) ; felső byte-ja – X a SRAM kezdetére ($0100)

; Disable button interrupts
	ldi temp, 0x00
	out EIMSK, temp

; Timer inits
  ldi temp, 0b10000010     ; enable interrupts for timer
	out TIMSK, temp

	sei 								; glob�lis IT enged�lyezve


;***************************************************************
;* MAIN program, Endless loop part

M_LOOP:
	jmp RECORD_MODE
	jmp M_LOOP




; -------------------------------------------------------------
; -                             RECORD MODE                   -
; -------------------------------------------------------------
RECORD_MODE:                  ; -------------------------------
	ldi cnt, 0                  ; Give time for bouncing switches
RECORD_MODE_DELAY:            ;     <-------\
	inc cnt                     ;     | DELAY |
	cpi cnt, 0xFF               ;     ------->/
	brne RECORD_MODE_DELAY      ; -------------------------------
	ldi XL, LOW(SRAM_START)     ; init SRAM           --
	ldi tim0delay, 25           ; Input Timer init (stopped)
	ldi temp, 107               ; (11MHz/1024/107/25) ~= 4Hz
	out OCR0, temp              ;                     ~= 250ms
	ldi temp, 0b00001000        ;
	out TCCR0, temp             ;
	;                           ; -------------------------------
	ldi tim2delay, 25           ; LED Timer init / START
	ldi temp, 214               ; (11MHz/1024/214/25) ~= 2Hz
	out OCR2, temp              ;                     ~= 500ms
	ldi temp, 0b00001111        ;
	out TCCR2, temp             ;
	;                           ; -------------------------------
	ldi temp, 0xF0              ; Enable Button Interrupts
	out EIMSK, temp             ;
	RECORD_MODE_CYCLE:          ; -------------------------------
	lds cnt, PinG               ; Read switch for mode change
	andi cnt, 0x01              ;
	sbrs cnt, 0                 ;
	jmp REPLAY_MODE             ;
	jmp RECORD_MODE_CYCLE       ; -------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------



; -------------------------------------------------------------
; -                             REPLAY MODE                   -
; -------------------------------------------------------------
REPLAY_MODE:                  ; -------------------------------
	ldi cnt, 0                  ; Give time for bouncing switches
REPLAY_MODE_DELAY:            ;     <-------\
	inc cnt                     ;     | DELAY |
	cpi cnt, 0xFF               ;     ------->/
	brne REPLAY_MODE_DELAY      ; -------------------------------
	ldi temp, 0x00              ; Disable Button Interrupts
	out EIMSK, temp             ; -------------------------------
	ldi YL, LOW(SRAM_START)         ; init SRAM           --
	in tim2delay, ADCH          ; Replay Timer init / START
	ldi temp, 214               ;
	out OCR2, temp              ;
	ldi temp, 0b00001111        ;
	out TCCR2, temp             ;
REPLAY_MODE_CYCLE:            ; -------------------------------
	lds cnt, PinG               ; Read switch for mode change
	andi cnt, 0x01              ;
	sbrc cnt, 0                 ;
	jmp RECORD_MODE             ;
	jmp REPLAY_MODE_CYCLE       ; -------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------



; -------------------------------------------------------------
; -                             Button Interrupt Handler      -
; -------------------------------------------------------------
BTN_IT:                       ; -------------------------------
	push temp                   ;
	in temp, SREG               ;
	push temp                   ;
	ldi temp, 0b00001111        ; Start the Input Timer
	out TCCR0, temp             ; -------------------------------
	ldi temp, 0x00              ; Disable Button Interrupts
	out EIMSK, temp             ; -------------------------------
	in temp, PinE               ; Read buttons and save to SRAM
	lsr temp                    ;
	lsr temp                    ;
	lsr temp                    ;
	lsr temp                    ;
	andi temp, 0xF0             ;
	st X, temp                  ;
  	inc XL                      ; -------------------------------
	pop temp                    ;
	out SREG, temp              ;
	pop temp                    ;
	reti                        ; -------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------



; -------------------------------------------------------------
; -                            Input Timer Interrupt Handler  -
; -------------------------------------------------------------
INPUT_TIMER_IT:               ; -------------------------------
	push temp                   ;
	in temp, SREG               ;
	push temp                   ;
	dec tim0delay               ;
	cpi tim0delay, 0            ;
	breq INPUT_TIMER_IT_BR      ;
	pop temp                    ;
	out SREG, temp              ;
	pop temp                    ;
	reti                        ;
INPUT_TIMER_IT_BR:            ; -------------------------------
  ldi temp, 0b00001000        ; Stop the Input Timer
	out TCCR0, temp             ;
	ldi tim0delay, 25           ; Reset counter delay
	ldi temp, 0xF0              ; Enable Button Interrupts
	pop temp                    ; -------------------------------
	out SREG, temp              ;
	pop temp                    ;
	reti                        ; -------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------


; ********* Led Timer Interrupt Handler *****
LED_TIMER:
	in temp, PinC
	com temp
	andi temp, 0xF0
	out PortC, temp
	ldi tim2delay, 25           ; LED Timer init / START
	ldi temp, 214               ; (11MHz/1024/214/25) ~= 2Hz
	out OCR2, temp              ;                     ~= 500ms
	ldi temp, 0b00001111        ;
	out TCCR2, temp             ;
	ret

; ********* Replay Timer Interrupt Handler **
REPLAY_TIMER:
	ld temp, Y
	out PortC, temp
	cp XL, YL
	breq REPLAY_TIMER_RST
	inc YL                      ; n�velj�k a pointert
	jmp REPLAY_TIMER_CONT
REPLAY_TIMER_RST:
	ldi YL, LOW(SRAM_START)     ; RST counter
REPLAY_TIMER_CONT:
	in tim2delay, ADCH          ; Replay Timer init / START
	ldi temp, 214               ;
	out OCR2, temp              ;
	ldi temp, 0b00001111        ;
	out TCCR2, temp             ;
	ret


; -------------------------------------------------------------
; -                            Timer2 Interrupt Handler       -
; -------------------------------------------------------------
TIMER2_IT:                    ; -------------------------------
	push temp                   ;
	in temp, SREG               ;
	push temp                   ;
	dec tim2delay               ;
	cpi tim2delay, 0            ;
	breq TIMER2_IT_BR           ;
	pop temp                    ;
	out SREG, temp              ;
	pop temp                    ;
	reti                        ;
TIMER2_IT_BR:                 ; -------------------------------
	lds cnt, PinG               ; Read switch for mode
	andi cnt, 0x01              ;
	sbrc cnt, 0                 ;
	call LED_TIMER              ; INT from RECORD MODE
	call REPLAY_TIMER           ; INT from REPLAY MODE
	pop temp                    ;
	out SREG, temp              ;
	pop temp                    ;
	reti                        ; -------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
