	AREA	Adjust, CODE, READONLY
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start
	PRESERVE8

start

	BL	getPicAddr	; load the start address of the image in R4
	MOV	R4, R0
	BL	getPicHeight	; load the height of the image (rows) in R5
	MOV	R5, R0
	BL	getPicWidth	; load the width of the image (columns) in R6
	MOV	R6, R0

	LDR R1, =0	     			    ; R1 = brightness;
	LDR R2, =16						; R2 = contrast;
	MUL R3, R5, R6					; R3 = pixelAmount;
	BL adjust						; adjust();
	
	BL	putPic		; re-display the updated image

stop	B	stop


; Adjust subroutine
; Adjusts the brightness and contrast of a given picture.
; Parameters: R1: Brightness
; 	R2: Contrast
;	R3: Length of Array
; 	R4: Starting address of picture
; Returns: none
adjust
	STMFD SP!, {R4 - R12, lr}	; pushing stack
	EOR R8, R8					; R8 = count;
	EOR R9, R9					; R9 = pixel;
	MOV R7, R3					; R7 = pixelAmount;
	LDR R10, =0					; R10 = row;
	LDR R11, =0					; R11 = column;
whl	CMP R8, R7					; while(count < pixelAmount)
	BEQ endwh					; {
	BL getpixel					; 	getpixel();
	MOV R9, R0					; 	R9 = pixel;
	
	STMFD SP!, {R1}				; 	pushing stack
	MOV R1, R9					; 	R1 = pixel;		
	BL getred					; 	getred();
	LDMFD SP!, {R1}				;   popping stack
	MOV R5, R0					;   R5 = redComponent;	
	MUL R5, R2, R5				;	redComponent *= contrast;
	CMP R5, #0					; 	if(redComponent <= 0)
	BGT noerror					;	{
	LDR R5, =0					;		redComponent = 0;
noerror							; 	}
	CMP R5, #255				; 	if(redComponent >= 255)
	BLT noerror4				;	{
	LDR R5, =255				;		redComponent = 255;
noerror4						;	}
	LSR R5, #4					; 	redComponent /= 16;
	ADD R5, R5, R1				;	redComponent += brightness;
	CMP R5, #0					;	if(redComponent <= 0)
	BGT done					; 	{
	LDR R5, =0					;		redComponent = 0;
done							;	}
	CMP R5, #255				;	if(redComponent >= 255)
	BLT done3					;	{
	LDR R5, =255				;		redComponent = 255;
done3							;	}
	
	STMFD SP!, {R1}				; 	pushing stack
	MOV R1, R9					;   R1 = pixel
	BL getgreen					; 	getgreen();
	LDMFD SP!, {R1}				;   popping stack
	MOV R6, R0					;	R6 = greenComponent
	MUL R6, R2, R6				;	greenComponent *= contrast
	CMP R6, #0					;	if(greenComponent <= 0)
	BGT noerror1				; 	{
	LDR R6, =0					;		greenComponent = 0;
noerror1						; 	}
	CMP R6, #255				; 	if(greenComponent >= 255)
	BLT noerror5				;	{
	LDR R6, =255				;		greenComponent = 255;
noerror5						;	}
	LSR R6, #4					; 	greenComponent /= 16;
	ADD R6, R6, R1				;	greenComponent += brightness;
	CMP R6, #0					;	if(greenComponent <= 0)
	BGT done1					; 	{
	LDR R6, =0					;		greenComponent = 0;
done1							; 	}
	CMP R6, #255				;	if(greenComponent >= 255)
	BLT done4					; 	{
	LDR R6, =255				;		greenComponent = 255;
done4							;	}
	LSL R6, #8					;	greenComponent *= 0x100;
								
	STMFD SP!, {R1}				; 	pushing stack
	MOV R1, R9					; 	R1 = pixel;
	BL getblue					;	getblue();
	LDMFD SP!, {R1}				;	popping stack
	MOV R9, R0					; 	R9 = blueComponent;
	MUL R9, R2, R9				;	blueComponent *= contrast
	CMP R9, #0					; 	if(blueComponent <= 0)
	BGT noerror2				; 	{
	LDR R9, =0					; 		blueComponent = 0;
noerror2						; 	}
	CMP R9, #255				;	if(blueComponent >= 255)
	BLT noerror6				;	{
	LDR R9, =255				; 		blueComponent = 255;
noerror6						;	}
	LSR R9, #4					; 	blueComponent /= 16;
	ADD R9, R9, R1				;	blueComponent += brightness;
	CMP R9, #0					;	if(blueComponent <= 0)
	BGT done2					; 	{
	LDR R9, =0					;		blueComponent = 0;
done2							;	}
    CMP R9, #255				;	if(blueComponent >= 255)
	BLT done5					;	{
	LDR R9, =255				;		blueComponent = 255;
done5							;	}
	LSL R9, #16					;	blueComponent *= 0x10000;
	
	ADD R5, R5, R6				; 	R5 = redComponent + greenComponent
	ADD R9, R9, R5				;	R9 = R5 + blueComponent;
	
	BL sendpixel				; 	sendpixel();
	ADD R11, R11, #1			;	column++;
	ADD R8, R8, #1				;	count++;
	BL getPicWidth				;	getPicWidth();
	CMP R11, R0					; 	if(column >= picWidth)
	BLO dontadd					;	{
	ADD R10, R10, #1			;		row++
	LDR R11, =0					;		column = 0;
dontadd							;	}
	B whl						; }
endwh
	LDMFD SP!, {R4-R12, PC}		; popping stack
	
; getpixel subroutine
; gets a single pixel from a picture
; Parameters: R1: Row
;	R2: Column
;	R4: Start address of picture
;	R6: Picture Width
; Returns: R0: Pixel
getpixel	
	STMFD SP!, {R1-R4, R6, LR}	; pushing stack
	BL getPicWidth				; getPicWidth();
	MOV R6, R0					; R6 = picWidth;
	BL getPicAddr				; getPicAddr();
	MOV R4, R0					; R4 = picAddr;
	EOR R3, R3					; R3 = pixelAddr;
	MOV R1, R10					; R1 = row;
	MOV R2, R11					; R2 = column;
	MUL R3, R1, R6				; pixelAddr = row * picWidth;
	ADD R3, R3, R2				; pixelAddr += column;
	LSL R3, #2					; pixelAddr *= 4;
	ADD R3, R4, R3				; pixelAddr += picAddr;
	LDR R0, [R3]				; pixel = memory.get[picAddr]
	LDMFD SP!, {R1-R4, R6, PC}	; popping stack

; sendpixel subroutine
; stores a single pixel back into memory
; Parameters: R1: Row
; 	R2: Column
; 	R4: Start address of picture
;	R6: Picture Width
;	R9: Pixel value
; Returns: none
sendpixel
	STMFD SP!, {R1-R4, R6, LR}	; pushing stack
	BL getPicWidth				; getPicWidth();
	MOV R6, R0					; R6 = picWidth;
	BL getPicAddr				; getPicAddr();
	MOV R4, R0					; R4 = picAddr;
	EOR R3, R3					; R3 = pixelAddr;
	MOV R1, R10					; R1 = row
	MOV R2, R11					; R2 = column;
	MUL R3, R1, R6				; pixelAddr = row * picWidth;
	ADD R3, R3, R2				; pixelAddr += column;
	LSL R3, #2					; pixelAddr *= 4;
	ADD R0, R4, R3				; pixelAddr += picAddr;
	STR R9, [R0]				; memory.get[pixelAddr] = pixel;
	LDMFD SP!, {R1-R4, R6, PC}	; popping stack
		
; getred subroutine
; Gets the red components of a pixel.
; Parameters: R1: Pixel value
; Returns: R0: Red component.
getred
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0X000000FF			; pixel = pixel AND NOT(0xFFFFFF00);
	MOV R0, R1					; redComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack

; getgreen subroutine
; Gets the green components of a pixel.
; Parameters: R1: Pixel value
; Returns: R0: Green component.
getgreen
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0x0000FF00			; pixel = pixel AND NOT(0xFFFF00FF);
	LSR R1, #8					; pixel /= 0x100;
	MOV R0, R1					; greenComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack
	
; getblue subroutine
; Gets the blue components of a pixel.
; Parameters: R1: Pixel value
; Returns: R0: Blue component.
getblue
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0x00FF0000			; pixel = pixel AND NOT(0xFF00FFFF);
	LSR R1, #16					; pixel /= 0x10000;
	MOV R0, R1					; blueComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack
	
	END	