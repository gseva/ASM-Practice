;******************************************************
;	TP Nro 22 - Caso de estudio IBM
;   Almacenamiento de BPFlotante IBM Mainframe
;
;	Autor: Gavrilov Vsevolod
;   Version: 0.1
;******************************************************
segment pila stack
				resb	64
				
segment datos data

msgSig db 10,13,'Ingrese signo:','$'
msgMant db 10,13,'Ingrese mantisa:','$'
msgSigExp db 10,13,'Ingrese signo del exponente:','$'
msgExp db 10,13,'Ingrese exponente:','$'
msgInval db 10,13,'Ingreso invalido!','$'
msgBin db 10,13,'Numero en binario:     ','$'
msgHex db 10,13,'Numero en hexadecimal: ','$'
msgChar db 10,13,' ','$'
salto  db 10,13,'$'

	   db 7
	   db 0
mant   db '0000000'
	   db 3
	   db 0
expon  resb 3
signo  resb 1
sigExp db 0

result db '00000000'
	   db '$'

error  db 0

segment codigo code
..start:

	mov ax,datos
	mov	ds,ax
	mov es,ax
 	mov	ax,pila
	mov	ss,ax

	; Pido y parseo el signo
	mov	dx,msgSig
	call printMsg
	mov ah,1
	int 21h
	call valSig
	cmp byte[error],1
	je showErr
	mov [signo],al
	
	; Pido y parseo la mantisa
	mov	dx,msgMant
	call printMsg
	mov dx,mant-2
	mov ah,0ah
	int 21h
	call valMant
	cmp byte[error],1
	je showErr

	; Pido y parseo el signo del exponente
	mov	dx,msgSigExp
	call printMsg
	mov ah,1
	int 21h
	call valSig
	cmp byte[error],1
	je showErr
	mov [sigExp],al

	; Pido y parseo el exponente
	mov	dx,msgExp
	call printMsg
	mov dx,expon-2
	mov ah,0ah
	int 21h
	call valExp
	cmp byte[error],1
	je showErr
	
	call showHex
	call showBin
	jmp  exit

showErr:
	mov dx,msgInval
	call printMsg
exit:
	mov	ax,4c00h	
	int	21h

;*************************************Rutinas*******************************************
printMsg:
	mov	ah,9
	int	21h
	ret

printChar:
	mov ah,2
	int 21h
	ret

; Rutina que valida y parsea el signo
valSig:
	cmp al,'+'
	je  vsMas
	cmp al,'-'
	je  vsMenos
	mov byte[error],1
	jmp vsExit
vsMas:
	mov al,0
	jmp vsExit
vsMenos:
	mov al,1
vsExit:
	ret


; Rutina que valida y parsea el exponente
valExp:
	mov si,0
	mov dx,0
	mov ah,[expon]
	call chrtonum
	cmp byte[error],1
	je  veSalir
	cmp byte[expon-1],2  ; Se ingreso un exponente de 2 digitos
	jne veSeguir
	mov al,ah
	mov bh,10h
	mul bh
	add dx,ax
	mov ah,[expon+1]
	call chrtonum
	cmp byte[error],1
	je  veSalir
veSeguir:
	add dl,ah
	mov ax,dx
	cmp ax,7Fh
	jg  veErr    ; Exponente demasiado grande
	cmp byte[sigExp],1
	jne veExpSinSig
	neg ax
veExpSinSig:
	add ax,40h
	cmp byte[signo],1
	jne veSinsig
	add al,80h   ; Hay signo
veSinsig:
	mov ah,0
	shl ax,4
	call numtochr
	mov byte[result],ah
	mov ah,0
	shl ax,4
	call numtochr
	mov byte[result+1],ah
	jmp veSalir
veErr:
	mov byte[error],1	
veSalir:
	ret


; Rutina que valida y parsea la mantisa
valMant:
	mov si,0
	mov cx,0
	mov cl,[mant-1]  ; Cantidad de caracteres ingresados
vmOtro:
	mov ah,[mant+si]
	mov byte[result+si+2],ah  
	call chrtonum    ; Primero valido que el caracter sea un numero
	cmp byte[error],1
	je vmExit
	inc si
	dec cx
	jnz vmOtro
vmExit:
	ret


; Rutina que convierte un caracter alojado en ah en un numero.
; En el caso de haber un error, setea el error en 1
chrtonum:
	cmp ah,30h ;'0'
	jl  ctnErr
	cmp ah,39h ;'9'
	jle ctnDec
	cmp ah,41h ;'A'
	jl  ctnErr
	cmp ah,46h ;'F'
	jle ctnHex
ctnErr:
	mov byte[error],1  ; Error
	jmp ctnExit
ctnDec:
	sub ah,'0'
	jmp ctnExit
ctnHex:
	sub ah,37h
ctnExit:
	ret
	
; Rutina que convierte un numero hexadecimal alojado en ah en un
; caracter. En el caso de haber un error, setea el error en 1
numtochr:
	cmp ah,0
	jl  ntcErr
	cmp ah,9
	jle ntcDec
	cmp ah,10
	jl  ntcErr
	cmp ah,15
	jle ntcHex
ntcErr:
	mov byte[error],1
	jmp ntcExit
ntcDec:
	add ah,'0'
	jmp ntcExit
ntcHex:
	add ah,37h
ntcExit:
	ret

; Rutina que muestra el numero en binario
showBin:
	mov dx,msgBin
	call printMsg
	mov cx,8
	mov si,0
sbOtro:
	mov ah,byte[result+si]
	call chrtonum
	mov al,ah
	shl al,4
	inc si
	push cx
	mov cx,4
bbbOtro:
	mov ah,0
	shl ax,1
	add ah,'0'
	mov dl,ah
	push ax
	call printChar
	pop ax
	loop bbbOtro
	pop cx
	loop sbOtro
	ret
	
; Rutina que muestra el numero en hexadecimal
showHex:
	mov dx,msgHex
	call printMsg
	mov dx,result
	call printMsg
	ret

;***************************************************************************************
