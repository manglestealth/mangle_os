%include "boot.inc"
SECTION MBR vstart=0x7c00
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov fs,ax
mov sp,0x7c00
mov ax,0xb800
mov gs,ax

;使用0x06号功能，上卷全部行，清屏
mov ax,0x600
mov bx,0x700 ;上卷的行属性
mov cx,0
mov dx,0x184f

int 10h

mov byte[gs:0x00],'6'
mov byte[gs:0x01],0xA4

mov byte[gs:0x02],' '
mov byte[gs:0x03],0xA4

mov byte[gs:0x04],'M'
mov byte[gs:0x05],0xA4

mov byte[gs:0x06],'B'
mov byte[gs:0x07],0xA1

mov byte[gs:0x08],'R'
mov byte[gs:0x09],0xA1

mov eax,LOADER_START_SECTOR;起始扇区lba地址
mov bx,LOADER_BASE_ADDR;写入的内存地址
mov cx,4;待读入的扇区数
call rd_disk_m_16;读取程序的起始部分

jmp LOADER_BASE_ADDR

rd_disk_m_16:
    mov esi,eax ;备份eax
    mov di,cx ;备份cx
    ;读写硬盘
    ;第一步：设置读取的扇区数
    mov dx,0x1F1  ;写入sector count
    mov al,cl 
    out dx,al ;读取的扇区数，写入端口
    mov eax,esi ;恢复ax
    ;第二步：设置LBA
    mov dx,0X1F3 ;LBA LOW  7~0
    out dx,al 

    mov cl,8
    shr eax,cl ;右移8位
    mov dx,0x1F4 ;LBA MID 15~8
    out dx,al 

    shr eax,cl ;右移8位
    mov dx,0X1F5 ;LBA HIGH 23~16
    out dx,al

    shr eax,cl ;右移8位
    and al,0x0f ;LBA 27~24
    or al,0xe0 ;设置7～4位为1110
    mov dx,0x1f6 ;device端口
    out dx,al
    ;第三步：写入command
    mov dx,0x1f7 ;command
    mov al,0x20 ;read sector
    out dx,al
    ;第四步：检测状态
    .not_ready:
    ;继续使用0x1f7,此时变为status
    nop ;空操作
    in al,dx
    and al,0x88 ;第4位为1表示硬盘控制器准备好数据传输，第7位为1表示硬盘忙
    cmp al,0x08 ;进行比较
    jnz .not_ready ;未准备好，则继续等待
    ;第五步：从0x1f0端口读数据写入对应的内存地址
    mov ax,di ;di为要读取的扇区数
    mov dx,256 ;一个扇区有512字节，每次读入一个字，共需要512/2次
    mul dx
    mov cx,ax
    mov dx,0x1f0

    .go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read
    ret 

times 510-($-$$) db 0
db 0x55,0xaa