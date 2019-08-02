	AREA	MotionBlur, CODE, READONLY
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

	MOV R1, #5								; R1 = diameter;
	MUL R2, R5, R6							; R2 = pixelAmount;
	BL blur									; blur();

	BL	putPic		; re-display the updated image

stop	B	stop

; blur subroutine
; Applies a motion blur to a picture starting from the top left and ending in the bottom right
; Parameters R1: radius
; 	R2: length of Array
;	R4: start address
; Returns: none
blur
	STMFD SP!, {LR}							; pushing stack
	MOV R7, R2								; R7 = pixelAmount;
	LDR R8, =0								; R8 = row;
	LDR R9, =0								; R9 = column;
	EOR R10, R10							; R10 = pixel;	
	EOR R11, R11							; R11 = count;
	ASR R1, #1								; R1 = radius;
	CMP R1, #0
	BLE stop
whl											; 
	CMP R11, R7								; while(count <= pixelAmount)
	BEQ endwh								; {
	STMFD SP!, {R1-R2}						; 	pushing stack
	MOV R1, R8								;	R1 = row;
	MOV R2, R9								; 	R2 = column;
	BL getpixel								; 	getpixel();
	LDMFD SP!, {R1-R2}						; 	popping stack
	MOV R10, R0								; 	R10 = pixel;
	ADD R11, R11, #1						; 	count++;
	
	BL getaverage							; 	getaverage();
	STMFD SP!, {R0-R2, R8-R9}				; 	pushing stack
	MOV R1, R8								; 	R1 = row;
	MOV R2, R9								; 	R2 = column;
	BL sendpixel							; 	sendpixel();
	LDMFD SP!, {R0-R2, R8-R9}				;	popping stack
	
	ADD R9, R9, #1							;	column++;
	CMP R9, R6								; 	if(column >= picWidth)
	BLO dontadd								; 	{
	ADD R8, R8, #1							;		row++;
	LDR R9, =0								;		column = 0;
dontadd										;	}
	
	B whl									; }
	
endwh
	LDMFD SP!, {PC}							; popping stack

; getpixel subroutine
; gets a single pixel from a picture
; Parameters: R1: Row
;	R2: Column
;	R4: Start address of picture
;	R6: Picture Width
; Returns: R0: Pixel
getpixel
	STMFD SP!, {R1-R4, R6, LR}				; pushing stack
	BL getPicWidth							; getPicWidth();
	MOV R6, R0								; R6 = picWidth;
	BL getPicAddr							; getPicAddr();
	MOV R4, R0								; R4 = picAddr();
	EOR R3, R3								; R3 = pixelAddr;
	MUL R3, R1, R6							; pixelAddr *= row * picWidth;
	ADD R3, R3, R2							; pixelAddr += column;
	LSL R3, #2								; pixelAddr *= 4;
	ADD R3, R4, R3							; pixelAddr += picAddr;
	LDR R0, [R3]							; pixel = memory.get[pixelAddr];
	LDMFD SP!, {R1-R4, R6, PC}				; popping stack

; sendpixel subroutine
; stores a single pixel back into memory
; Parameters: R1: Row
; 	R2: Column
; 	R4: Start address of picture
;	R6: Picture Width
;	R9: Pixel value
; Returns: none
sendpixel
	STMFD SP!, {R1-R4, R6, LR}				; pushing stack
	MOV R9, R0								; R9 = pixel
	BL getPicWidth							; getPicWidth();
	MOV R6, R0								; R6 = picWidth;
	BL getPicAddr							; getPicAddr();
	MOV R4, R0								; R4 = picAddr;
	EOR R3, R3								; R3 = pixelAddr;
	MUL R3, R1, R6							; pixelAddr = row * picWidth;
	ADD R3, R3, R2							; pixelAddr += column;
	LSL R3, #2								; pixelAddr *= 4;
	ADD R0, R4, R3							; pixelAddr += picAddr;
	STR R9, [R0]							; memory.get[pixelAddr] = pixel;
	LDMFD SP!, {R1-R4, R6, PC}				; popping stack
		
; getred subroutine
; Gets the red components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Red component.
getred
	STMFD SP!, {R1, LR}						; pushing stack
	AND R1, #0X000000FF						; pixel = pixel AND NOT(0xFFFFFF00);	
	MOV R0, R1								; redComponent = pixel;
	LDMFD SP!, {R1, PC}						; popping stack

; getgreen subroutine
; Gets the green components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Green component.
getgreen
	STMFD SP!, {R1, LR}						; pushing stack
	AND R1, #0x0000FF00						; pixel = pixel AND NOT(0xFFFF00FF);
	LSR R1, #8								; pixel /= 0x100;
	MOV R0, R1								; greenComponent = pixel;
	LDMFD SP!, {R1, PC}						; popping stack
	
; getblue subroutine
; Gets the blue components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Blue component.
getblue
	STMFD SP!, {R1, LR}						; pushing stack
	AND R1, #0x00FF0000						; pixel = pixel AND NOT(0xFF00FFFF);
	LSR R1, #16								; pixel /= 0x10000;
	MOV R0, R1								; blueComponent = pixel;
	LDMFD SP!, {R1, PC}						; popping stack
	
; divide subroutine
; takes two numbers and divides them
; parameters: R1: number to be divided
; 	R2: divisor
; returns: R0: Quotient
divide
	STMFD SP!, {R1-R3, LR}					; pushing stack;
	EOR R3, R3								; R3 = quotient;
whlnotend									
	CMP R1, R2								; while(num <= divisor)
	BLO end									; {
	SUB R1, R1, R2							; 	num -= divisor;
	ADD R3, R3, #1							; 	quotient++;
	B whlnotend								; }
end											;
	MOV R0, R3								; R0 = quotient
	LDMFD SP!, {R1-R3, PC}					; popping stack
	
; getaverage subroutine
; takes a pixel and finds the average of surrounding pixels inclusive in a given radius
; parameters: R1: radius
;	R8: row
; 	R9: column
; 	R10: pixel
; returns: R0: average
getaverage
	STMFD SP!, {R1-R11, LR}					; pushing stack
	
	MOV R11, R1								; R11 = radius;
	LDR R12, =1								; R12 = divisor;
	MOV R6, R1								; R6 = radius;
	MOV R1, R10								; R1 = column;
	BL getred								; getRed();
	MOV R3, R0								; R3 = redComponent;
	BL getgreen								; getGreen();
	MOV R4, R0								; R4 = greenComponent;
	BL getblue								; getBlue();
	MOV R5, R0								; R5 = blueComponent;
	
	STMFD SP!, {R6,R8-R9}					; pushing stack
whl2
	CMP R6, #0								; while(radius != 0)
	BEQ next								; {
	SUB R6, R6, #1							; 	radius--;
	
	SUB R8, R8, #1							;	row--;
	MOV R1, R8								; 	R1 = row;	
	SUB R9, R9, #1							; 	column--;
	MOV R2, R9								; 	R2 = column;
	CMP R1, #0								; 	if(R1 <= 0)
	BLT next								; 		break;
	CMP R2, #0								;	if(R2 <= 0)
	BLT next								;		break;
	ADD R12, R12, #1						;	divisor++;
	STMFD SP!, {R4, R6}						; 	pushing stak
	BL getPicAddr							; 	getPicAddr();
	MOV R4, R0								; 	R4 = picAddr;
	BL getPicWidth							; 	getPicWidth();
	MOV R6, R0								;	R6 = picWidth;
	BL getpixel								; 	getpixel();
	LDMFD SP!, {R4, R6}						; 	popping stack
	MOV R10, R0								; 	R10 = pixel;
	
	MOV R1, R10								; 	R1 = pixel;
	BL getred								; 	getred();
	ADD R3, R0								; 	redComponent += redComponent;					
	BL getgreen								; 	getgreen();
	ADD R4, R0								; 	greenComponent += greenComponent;
	BL getblue								; 	getblue();
	ADD R5, R0								;	blueComponent += blueComponent;
				
	B whl2									; }
	
next
	LDMFD SP!, {R6,R8-R9}					; popping stack
	STMFD SP!, {R10-R11}					; pushing stack
whl3
	CMP R6, #0								; while(radius != 0)
	BEQ next2								; {
	SUB R6, R6, #1							; 	radius--;
	
	BL getPicWidth							; 	getPicWidth();
	MOV R10, R0								; 	R10 = picWidth;
	SUB R10, R10, #1						; 	picWidth--;
	BL getPicHeight							; 	getPicHeight();
	MOV R11, R0								; 	R11 = picHeight;
	SUB R11, R11, #1						; 	picHeight--;
	ADD R8, R8, #1							; 	row++;
	MOV R1, R8								; 	R1 = row;
	ADD R9, R9, #1  						; 	column++;
	MOV R2, R9								; 	R2 = column;
	CMP R1, R11								; 	if(row >= picHeight)
	BGT next2								;		break;
	CMP R2, R10								;	if(column >= picWidth)
	BGT next2								;		break;
	ADD R12, R12, #1						; 	divisor++;
	STMFD SP!, {R4, R6}						; 	pushing stack
	BL getPicAddr							;   getPicAddr();
	MOV R4, R0								; 	R4 = picAddr;
	BL getPicWidth							; 	getPicWidth();
	MOV R6, R0								; 	R6 = picWidth;
	BL getpixel								; 	getpixel();
	LDMFD SP!, {R4, R6}						;	popping stack
	MOV R10, R0								; 	R10 = pixel;
	
	MOV R1, R10								; 	R1 = pixel
	BL getred								; 	getred();
	ADD R3, R0								; 	redComponent += redComponent;
	BL getgreen								; 	getgreen();
	ADD R4, R0								;	greenComponent += greenComponent;
	BL getblue								;	getblue();
	ADD R5, R0								;	blueComponent += blueComponent;

	B whl3									; }
	
next2
	LDMFD SP!, {R10-R11}					; popping stack
	MOV R2, R12								; R2 = divisor;
	
	MOV R1, R3								; R1 = redComponent;
	BL divide								; divide();
	MOV R3, R0								; R3 = redComponent;
	MOV R1, R4								; R1 = greenComponent;
	BL divide								; divide();
	MOV R4, R0								; R4 = greenComponent;
	MOV R1, R5								; R1 = blueComponent;
	BL divide								; divide();
	MOV R5, R0								; R5 = blueComponent;
	
	LSL R4, #8								; greenComponent *= 0x100;
	LSL R5, #16								; blueComponent *= 0x10000;
	ADD R3, R3, R4							; pixel = redComponent + greenComponent;
	ADD R5, R5, R3							; pixel += blueComponent;
	MOV R0, R5								; R0 = pixel;

	LDMFD SP!, {R1-R11, PC}					; popping stack
	
	END	