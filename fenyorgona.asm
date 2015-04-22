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
.def temp = r16 ; Temporary Register example
.def buttonsbits = r17
.def temp1 = r18
.def szamlal = r19
.def masodperc = r20
.def tick = r21
.def cnt = r22;

;***************************************************************
;* Reset & Interrupt Vectors
.cseg
.org $0000 ; Define start of Code segment
	jmp RESET ; Reset Handler, jmp is 2 word instruction
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp DUMMY_IT	; Ext. INT4 Handler (INT gomb)
	jmp DUMMY_IT	; Ext. INT5 Handler (BTN0)
	jmp DUMMY_IT	; Ext. INT6 Handler (BTN1)
	jmp DUMMY_IT	; Ext. INT7 Handler (BTN2)
	jmp DUMMY_IT	; Timer2 Compare Match Handler
	jmp DUMMY_IT	; Timer2 Overflow Handler
	jmp DUMMY_IT	; Timer1 Capture Event Handler
	jmp DUMMY_IT	; Timer1 Compare Match A Handler
	jmp DUMMY_IT	; Timer1 Compare Match B Handler
	jmp DUMMY_IT	; Timer1 Overflow Handler
	jmp DUMMY_IT	; Timer0 Compare Match Handler
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
;< ki- �s bemenetek inicializ�l�sa stb >

; LED-ek inicializ�l�sa
	ldi temp, 0xFF
	out DDRC, temp ; �sszes LED kimenet
	ldi temp, 0x01
	out PORTC, temp ; �sszes LED off

; BTN-k inicializ�l�sa (DDR eset�n 0-val inicializ�ljuk bemenetk�nt!)
	ldi temp, 0x00	; BTN3 enged�lyez�se bemenetk�nt
	out DDRB, temp
	out DDRG, temp
	ldi temp, 0x80
	out PORTB, temp
	ldi temp, 0x00	; BTN0, BTN1, BTN2, IT enged�nyez�se bemenetk�nt
	out DDRE, temp
	ldi temp, 0xF0
	out PORTE, temp

; buttonsbits inicializ�l�sa
	ldi buttonsbits, 0x00


;******** Timer inicializ�l�sa *******
	ldi temp, 107						; kompar�land� �rt�k (0�107 = 108)
	out OCR0, temp
	ldi temp, 0b00001111 				; TCCR0: CTC m�d, 1024-es elooszt�
										; 0.00.... ; FOC=0 COM=00 (kimenet tiltva)
										; .0..1... ; WGM=10 (CTC m�d)
										; .....111 ; CS0=111 (CLK/1024)
	out TCCR0, temp
	ldi temp, 0b00000010				; TIMSK: Output Compare Match IT enged�lyez�s
										; ......1. ; OCIE0=1: ha TCNT0 == OCR0, akkor IT
										; .......0 ; TOIE0=0 (nincs IT t�lcsordul�s eset�n)
	out TIMSK, temp
	ldi temp, 0xFF
	out DDRC, temp
;********** sz�ml�l�k be�ll�t�sa **********
	ldi szamlal, 25
	ldi tick, 0
	ldi masodperc, 0
	sei 								; glob�lis IT enged�lyezve


;***************************************************************
;* MAIN program, Endless loop part

M_LOOP:

;< fociklus >

/*
	in temp, PinE	 ; BTN0
	andi temp, 0x20
	sbrc temp, 5	 ; Skip if Bit in Reg. Cleared
	call CHANGE

	in temp, PinE	 ; BTN1
	andi temp, 0x40
	sbrc temp, 6	 ; Skip if Bit in Reg. Cleared
	call CHANGE

	in temp, PinE	 ; BTN2
	andi temp, 0x80
	sbrc temp, 7	 ; Skip if Bit in Reg. Cleared
	call CHANGE

	in temp, PinB	 ; BTN3
	andi temp, 0x80
	sbrc temp, 7	 ; Skip if Bit in Reg. Cleared
	call CHANGE

	in temp, PinE	 ; IT
	andi temp, 0x10
	call CHANGE

	jmp M_LOOP ; Endless Loop


CHANGE:
	or buttonsbits, temp
	ret


TIMER_IT:
	push temp 			;
	in temp, SREG 		;
	push temp           ;
	dec szamlal			; cs�kkentj�k a sz�zadm�sodpercek sz�m�t
	brne NEM_JART_LE 	; ha nem �rte el 0-t, kil�p�nk
	ldi tick, 1 		; k�l�nben jelezz�k a foprogramnak
	ldi szamlal, 25 	; �s �jrakezdj�k a sz�ml�l�s


NEM_JART_LE:
	pop temp
	out SREG, temp
	pop temp			 ; visszat�ltj�k SREG-et �s temp-et a verembol
	reti
	*/

jmp RECORD_MODE
jmp MAIN_LOOP


; *************** RECORD MODE ***************
RECORD_MODE:
	ldi cnt, 0;
RECORD_MODE_DELAY:
	inc cnt;
	cpi cnt, 0xFF;
	brne RECORD_MODE_DELAY
	; TIMER RESET
	; Init Input timer
	; Init LED timer
	; Start LED timer
	; Enable BTN interrupts
	RECORD_MODE_CYCLE:
	lds cnt, PinG
	andi cnt, 0x01
	sbrs cnt, 0
	jmp REPLAY_MOD
	jmp RECORD_MODE_CYCLE

; **************** REPLAY MOD ***************
REPLAY_MODE:
	ldi cnt, 0
REPLAY_MODE_DELAY:
	inc cnt
	cpi cnt, 0xFF
	brne REPLAY_MODE_DELAY
	; Disable BTN interrupts
	; TIMER RESET
	; Init Replay timer
	; Start Replay timer
REPLAY_MODE_CYCLE:
	lds cnt, PinG
	andi cnt, 0x01
	sbrc cnt, 0
	jmp MINTAVETELI_MOD
	jmp VISSZAJATSZASI_MOD_CYCLE

; ********* Button Interrupt Handler ********
BTN_IT:
	; Start Input Timer
	; Disable BTN Interrupts
	; Read state of BTNs
	; Save pressed BTNs to SRAM
	reti

; ********* Input Timer Interrupt Handler ***
INPUT_TIMER_IT:
	; Enable BTN Interrupts
	reti

; ********* Led Timer Interrupt Handler *****
LED_TIMER_IT:
	; Negate LED value
	; Restart LED Timer
	reti
; ********* Replay Timer Interrupt Handler **
REPLAY_TIMER_IT:
	; Set LED value from SRAM
	; Read pot value
	; Init Replay timer with pot value
	; Start Replay timer
	reti
