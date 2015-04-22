;*************************************************************** 
;* Feladat: 
;* Rövid leírás:
; 
;* Szerzõk: 
;* Mérõcsoport: <merocsoport jele>
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
.def pressing = r22

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
	jmp DUMMY_IT	; Ext. INT5 Handler
	jmp DUMMY_IT	; Ext. INT6 Handler
	jmp DUMMY_IT	; Ext. INT7 Handler
	jmp DUMMY_IT	; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp DUMMY_IT	; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp TIMER_IT	; Timer0 Compare Match Handler 
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

;< többi IT kezelõ a fájl végére! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< többi IT kezelõ a fájl végére! >

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
;< ki- és bemenetek inicializálása stb > 

; LED-ek inicializálása
	ldi temp, 0xFF
	out DDRC, temp ; összes LED kimenet
	ldi temp, 0x01
	out PORTC, temp ; összes LED off

; BTN-k inicializálása (DDR esetén 0-val inicializáljuk bemenetként!)
	ldi temp, 0x00	; BTN3 engedélyezése bemenetként
	out DDRB, temp
	ldi temp, 0x80
	out PORTB, temp
	ldi temp, 0x00	; BTN0, BTN1, BTN2, IT engedényezése bemenetként
	out DDRE, temp
	ldi temp, 0xF0
	out PORTE, temp

; buttonsbits inicializálása
	ldi buttonsbits, 0x00


;******** Timer inicializálása *******
	ldi temp, 107						; komparálandó érték (0…107 = 108)
	out OCR0, temp
	ldi temp, 0b00001111 				; TCCR0: CTC mód, 1024-es elõosztó
										; 0.00.... ; FOC=0 COM=00 (kimenet tiltva)
										; .0..1... ; WGM=10 (CTC mód)
										; .....111 ; CS0=111 (CLK/1024)
	out TCCR0, temp
	ldi temp, 0b00000010				; TIMSK: Output Compare Match IT engedélyezés
										; ......1. ; OCIE0=1: ha TCNT0 == OCR0, akkor IT
										; .......0 ; TOIE0=0 (nincs IT túlcsordulás esetén)
	out TIMSK, temp
	ldi temp, 0xFF
	out DDRC, temp
;********** számlálók beállítása **********
	ldi szamlal, 25
	ldi tick, 0
	ldi masodperc, 0
	sei 								; globális IT engedélyezve


;*************************************************************** 
;* MAIN program, Endless loop part
 
M_LOOP: 

;< fõciklus >


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
	push temp 			; sem temp-et, sem SREG-et nem használja M_LOOP,
	in temp, SREG 		; így nem lenne szükséges menteni
	push temp
	dec szamlal			; csökkentjük a századmásodpercek számát
	brne NEM_JART_LE 	; ha nem érte el 0-t, kilépünk
	ldi tick, 1 		; különben jelezzük a fõprogramnak
	ldi szamlal, 25 	; és újrakezdjük a számlálás


NEM_JART_LE:
	pop temp
	out SREG, temp
	pop temp			 ; visszatöltjük SREG-et és temp-et a verembõl
	reti

;*************************************************************** 
;* Subroutines, Interrupt routines
