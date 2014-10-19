Segment .data
        msg     db 'Hello world!$'

Segment .code
_start:
        mov ax,data
        mov ds,ax
        mov ecx,msg
        mov ah,9
        int 21h
        mov ah,41h
        int 21h
