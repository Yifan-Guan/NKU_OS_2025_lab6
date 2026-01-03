
obj/__user_schedbench.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	144000ef          	jal	800164 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
  800028:	02810313          	addi	t1,sp,40
__panic(const char *file, int line, const char *fmt, ...) {
  80002c:	e822                	sd	s0,16(sp)
  80002e:	8432                	mv	s0,a2
    cprintf("user panic at %s:%d:\n    ", file, line);
  800030:	862e                	mv	a2,a1
  800032:	85aa                	mv	a1,a0
  800034:	00000517          	auipc	a0,0x0
  800038:	69c50513          	addi	a0,a0,1692 # 8006d0 <main+0x178>
__panic(const char *file, int line, const char *fmt, ...) {
  80003c:	ec06                	sd	ra,24(sp)
  80003e:	f436                	sd	a3,40(sp)
  800040:	f83a                	sd	a4,48(sp)
  800042:	fc3e                	sd	a5,56(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e41a                	sd	t1,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	056000ef          	jal	8000a0 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	02e000ef          	jal	800080 <vcprintf>
    cprintf("\n");
  800056:	00000517          	auipc	a0,0x0
  80005a:	69a50513          	addi	a0,a0,1690 # 8006f0 <main+0x198>
  80005e:	042000ef          	jal	8000a0 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0d6000ef          	jal	80013a <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1101                	addi	sp,sp,-32
  80006a:	ec06                	sd	ra,24(sp)
  80006c:	e42e                	sd	a1,8(sp)
    sys_putc(c);
  80006e:	0ba000ef          	jal	800128 <sys_putc>
    (*cnt) ++;
  800072:	65a2                	ld	a1,8(sp)
}
  800074:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
  800076:	419c                	lw	a5,0(a1)
  800078:	2785                	addiw	a5,a5,1
  80007a:	c19c                	sw	a5,0(a1)
}
  80007c:	6105                	addi	sp,sp,32
  80007e:	8082                	ret

0000000000800080 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800080:	1101                	addi	sp,sp,-32
  800082:	862a                	mv	a2,a0
  800084:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800086:	00000517          	auipc	a0,0x0
  80008a:	fe250513          	addi	a0,a0,-30 # 800068 <cputch>
  80008e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800090:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800092:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800094:	142000ef          	jal	8001d6 <vprintfmt>
    return cnt;
}
  800098:	60e2                	ld	ra,24(sp)
  80009a:	4532                	lw	a0,12(sp)
  80009c:	6105                	addi	sp,sp,32
  80009e:	8082                	ret

00000000008000a0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a0:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a2:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a6:	f42e                	sd	a1,40(sp)
  8000a8:	f832                	sd	a2,48(sp)
  8000aa:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000ac:	862a                	mv	a2,a0
  8000ae:	004c                	addi	a1,sp,4
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
  8000ba:	ec06                	sd	ra,24(sp)
  8000bc:	e0ba                	sd	a4,64(sp)
  8000be:	e4be                	sd	a5,72(sp)
  8000c0:	e8c2                	sd	a6,80(sp)
  8000c2:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
  8000c4:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
  8000c6:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000c8:	10e000ef          	jal	8001d6 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000cc:	60e2                	ld	ra,24(sp)
  8000ce:	4512                	lw	a0,4(sp)
  8000d0:	6125                	addi	sp,sp,96
  8000d2:	8082                	ret

00000000008000d4 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d4:	7175                	addi	sp,sp,-144
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000d6:	08010313          	addi	t1,sp,128
syscall(int64_t num, ...) {
  8000da:	e42a                	sd	a0,8(sp)
  8000dc:	ecae                	sd	a1,88(sp)
        a[i] = va_arg(ap, uint64_t);
  8000de:	f42e                	sd	a1,40(sp)
syscall(int64_t num, ...) {
  8000e0:	f0b2                	sd	a2,96(sp)
        a[i] = va_arg(ap, uint64_t);
  8000e2:	f832                	sd	a2,48(sp)
syscall(int64_t num, ...) {
  8000e4:	f4b6                	sd	a3,104(sp)
        a[i] = va_arg(ap, uint64_t);
  8000e6:	fc36                	sd	a3,56(sp)
syscall(int64_t num, ...) {
  8000e8:	f8ba                	sd	a4,112(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ea:	e0ba                	sd	a4,64(sp)
syscall(int64_t num, ...) {
  8000ec:	fcbe                	sd	a5,120(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	e4be                	sd	a5,72(sp)
syscall(int64_t num, ...) {
  8000f0:	e142                	sd	a6,128(sp)
  8000f2:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000f4:	f01a                	sd	t1,32(sp)
    }
    va_end(ap);
    asm volatile (
  8000f6:	4522                	lw	a0,8(sp)
  8000f8:	55a2                	lw	a1,40(sp)
  8000fa:	5642                	lw	a2,48(sp)
  8000fc:	56e2                	lw	a3,56(sp)
  8000fe:	4706                	lw	a4,64(sp)
  800100:	47a6                	lw	a5,72(sp)
  800102:	00000073          	ecall
  800106:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  800108:	4572                	lw	a0,28(sp)
  80010a:	6149                	addi	sp,sp,144
  80010c:	8082                	ret

000000000080010e <sys_exit>:

int
sys_exit(int64_t error_code) {
  80010e:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800110:	4505                	li	a0,1
  800112:	b7c9                	j	8000d4 <syscall>

0000000000800114 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800114:	4509                	li	a0,2
  800116:	bf7d                	j	8000d4 <syscall>

0000000000800118 <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  800118:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011a:	85aa                	mv	a1,a0
  80011c:	450d                	li	a0,3
  80011e:	bf5d                	j	8000d4 <syscall>

0000000000800120 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  800120:	4529                	li	a0,10
  800122:	bf4d                	j	8000d4 <syscall>

0000000000800124 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  800124:	4549                	li	a0,18
  800126:	b77d                	j	8000d4 <syscall>

0000000000800128 <sys_putc>:
}

int
sys_putc(int64_t c) {
  800128:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  80012a:	4579                	li	a0,30
  80012c:	b765                	j	8000d4 <syscall>

000000000080012e <sys_gettime>:
    return syscall(SYS_pgdir);
}

int
sys_gettime(void) {
    return syscall(SYS_gettime);
  80012e:	4545                	li	a0,17
  800130:	b755                	j	8000d4 <syscall>

0000000000800132 <sys_lab6_set_priority>:
}

void
sys_lab6_set_priority(uint64_t priority)
{
  800132:	85aa                	mv	a1,a0
    syscall(SYS_lab6_set_priority, priority);
  800134:	0ff00513          	li	a0,255
  800138:	bf71                	j	8000d4 <syscall>

000000000080013a <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80013a:	1141                	addi	sp,sp,-16
  80013c:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  80013e:	fd1ff0ef          	jal	80010e <sys_exit>
    cprintf("BUG: exit failed.\n");
  800142:	00000517          	auipc	a0,0x0
  800146:	5b650513          	addi	a0,a0,1462 # 8006f8 <main+0x1a0>
  80014a:	f57ff0ef          	jal	8000a0 <cprintf>
    while (1);
  80014e:	a001                	j	80014e <exit+0x14>

0000000000800150 <fork>:
}

int
fork(void) {
    return sys_fork();
  800150:	b7d1                	j	800114 <sys_fork>

0000000000800152 <wait>:
}

int
wait(void) {
    return sys_wait(0, NULL);
  800152:	4581                	li	a1,0
  800154:	4501                	li	a0,0
  800156:	b7c9                	j	800118 <sys_wait>

0000000000800158 <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  800158:	b7e1                	j	800120 <sys_yield>

000000000080015a <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  80015a:	b7e9                	j	800124 <sys_getpid>

000000000080015c <gettime_msec>:
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
  80015c:	bfc9                	j	80012e <sys_gettime>

000000000080015e <lab6_setpriority>:
}

void
lab6_setpriority(uint32_t priority)
{
    sys_lab6_set_priority(priority);
  80015e:	1502                	slli	a0,a0,0x20
  800160:	9101                	srli	a0,a0,0x20
  800162:	bfc1                	j	800132 <sys_lab6_set_priority>

0000000000800164 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800164:	1141                	addi	sp,sp,-16
  800166:	e406                	sd	ra,8(sp)
    int ret = main();
  800168:	3f0000ef          	jal	800558 <main>
    exit(ret);
  80016c:	fcfff0ef          	jal	80013a <exit>

0000000000800170 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  800170:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800172:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800176:	f022                	sd	s0,32(sp)
  800178:	ec26                	sd	s1,24(sp)
  80017a:	e84a                	sd	s2,16(sp)
  80017c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80017e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800182:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
  800184:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800188:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
  80018c:	84aa                	mv	s1,a0
  80018e:	892e                	mv	s2,a1
    if (num >= base) {
  800190:	03067d63          	bgeu	a2,a6,8001ca <printnum+0x5a>
  800194:	e44e                	sd	s3,8(sp)
  800196:	89be                	mv	s3,a5
        while (-- width > 0)
  800198:	4785                	li	a5,1
  80019a:	00e7d763          	bge	a5,a4,8001a8 <printnum+0x38>
            putch(padc, putdat);
  80019e:	85ca                	mv	a1,s2
  8001a0:	854e                	mv	a0,s3
        while (-- width > 0)
  8001a2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  8001a4:	9482                	jalr	s1
        while (-- width > 0)
  8001a6:	fc65                	bnez	s0,80019e <printnum+0x2e>
  8001a8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  8001aa:	00000797          	auipc	a5,0x0
  8001ae:	56678793          	addi	a5,a5,1382 # 800710 <main+0x1b8>
  8001b2:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001b4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b6:	0007c503          	lbu	a0,0(a5)
}
  8001ba:	70a2                	ld	ra,40(sp)
  8001bc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001be:	85ca                	mv	a1,s2
  8001c0:	87a6                	mv	a5,s1
}
  8001c2:	6942                	ld	s2,16(sp)
  8001c4:	64e2                	ld	s1,24(sp)
  8001c6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001c8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001ca:	03065633          	divu	a2,a2,a6
  8001ce:	8722                	mv	a4,s0
  8001d0:	fa1ff0ef          	jal	800170 <printnum>
  8001d4:	bfd9                	j	8001aa <printnum+0x3a>

00000000008001d6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001d6:	7119                	addi	sp,sp,-128
  8001d8:	f4a6                	sd	s1,104(sp)
  8001da:	f0ca                	sd	s2,96(sp)
  8001dc:	ecce                	sd	s3,88(sp)
  8001de:	e8d2                	sd	s4,80(sp)
  8001e0:	e4d6                	sd	s5,72(sp)
  8001e2:	e0da                	sd	s6,64(sp)
  8001e4:	f862                	sd	s8,48(sp)
  8001e6:	fc86                	sd	ra,120(sp)
  8001e8:	f8a2                	sd	s0,112(sp)
  8001ea:	fc5e                	sd	s7,56(sp)
  8001ec:	f466                	sd	s9,40(sp)
  8001ee:	f06a                	sd	s10,32(sp)
  8001f0:	ec6e                	sd	s11,24(sp)
  8001f2:	84aa                	mv	s1,a0
  8001f4:	8c32                	mv	s8,a2
  8001f6:	8a36                	mv	s4,a3
  8001f8:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fa:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  8001fe:	05500b13          	li	s6,85
  800202:	00000a97          	auipc	s5,0x0
  800206:	6f2a8a93          	addi	s5,s5,1778 # 8008f4 <main+0x39c>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80020a:	000c4503          	lbu	a0,0(s8)
  80020e:	001c0413          	addi	s0,s8,1
  800212:	01350a63          	beq	a0,s3,800226 <vprintfmt+0x50>
            if (ch == '\0') {
  800216:	cd0d                	beqz	a0,800250 <vprintfmt+0x7a>
            putch(ch, putdat);
  800218:	85ca                	mv	a1,s2
  80021a:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80021c:	00044503          	lbu	a0,0(s0)
  800220:	0405                	addi	s0,s0,1
  800222:	ff351ae3          	bne	a0,s3,800216 <vprintfmt+0x40>
        width = precision = -1;
  800226:	5cfd                	li	s9,-1
  800228:	8d66                	mv	s10,s9
        char padc = ' ';
  80022a:	02000d93          	li	s11,32
        lflag = altflag = 0;
  80022e:	4b81                	li	s7,0
  800230:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
  800232:	00044683          	lbu	a3,0(s0)
  800236:	00140c13          	addi	s8,s0,1
  80023a:	fdd6859b          	addiw	a1,a3,-35
  80023e:	0ff5f593          	zext.b	a1,a1
  800242:	02bb6663          	bltu	s6,a1,80026e <vprintfmt+0x98>
  800246:	058a                	slli	a1,a1,0x2
  800248:	95d6                	add	a1,a1,s5
  80024a:	4198                	lw	a4,0(a1)
  80024c:	9756                	add	a4,a4,s5
  80024e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800250:	70e6                	ld	ra,120(sp)
  800252:	7446                	ld	s0,112(sp)
  800254:	74a6                	ld	s1,104(sp)
  800256:	7906                	ld	s2,96(sp)
  800258:	69e6                	ld	s3,88(sp)
  80025a:	6a46                	ld	s4,80(sp)
  80025c:	6aa6                	ld	s5,72(sp)
  80025e:	6b06                	ld	s6,64(sp)
  800260:	7be2                	ld	s7,56(sp)
  800262:	7c42                	ld	s8,48(sp)
  800264:	7ca2                	ld	s9,40(sp)
  800266:	7d02                	ld	s10,32(sp)
  800268:	6de2                	ld	s11,24(sp)
  80026a:	6109                	addi	sp,sp,128
  80026c:	8082                	ret
            putch('%', putdat);
  80026e:	85ca                	mv	a1,s2
  800270:	02500513          	li	a0,37
  800274:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
  800276:	fff44783          	lbu	a5,-1(s0)
  80027a:	02500713          	li	a4,37
  80027e:	8c22                	mv	s8,s0
  800280:	f8e785e3          	beq	a5,a4,80020a <vprintfmt+0x34>
  800284:	ffec4783          	lbu	a5,-2(s8)
  800288:	1c7d                	addi	s8,s8,-1
  80028a:	fee79de3          	bne	a5,a4,800284 <vprintfmt+0xae>
  80028e:	bfb5                	j	80020a <vprintfmt+0x34>
                ch = *fmt;
  800290:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
  800294:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
  800296:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
  80029a:	fd06071b          	addiw	a4,a2,-48
  80029e:	24e56a63          	bltu	a0,a4,8004f2 <vprintfmt+0x31c>
                ch = *fmt;
  8002a2:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
  8002a4:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
  8002a6:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
  8002aa:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
  8002ae:	0197073b          	addw	a4,a4,s9
  8002b2:	0017171b          	slliw	a4,a4,0x1
  8002b6:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
  8002b8:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
  8002bc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002be:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
  8002c2:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
  8002c6:	feb570e3          	bgeu	a0,a1,8002a6 <vprintfmt+0xd0>
            if (width < 0)
  8002ca:	f60d54e3          	bgez	s10,800232 <vprintfmt+0x5c>
                width = precision, precision = -1;
  8002ce:	8d66                	mv	s10,s9
  8002d0:	5cfd                	li	s9,-1
  8002d2:	b785                	j	800232 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
  8002d4:	8db6                	mv	s11,a3
  8002d6:	8462                	mv	s0,s8
  8002d8:	bfa9                	j	800232 <vprintfmt+0x5c>
  8002da:	8462                	mv	s0,s8
            altflag = 1;
  8002dc:	4b85                	li	s7,1
            goto reswitch;
  8002de:	bf91                	j	800232 <vprintfmt+0x5c>
    if (lflag >= 2) {
  8002e0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002e2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002e6:	00f74463          	blt	a4,a5,8002ee <vprintfmt+0x118>
    else if (lflag) {
  8002ea:	1a078763          	beqz	a5,800498 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
  8002ee:	000a3603          	ld	a2,0(s4)
  8002f2:	46c1                	li	a3,16
  8002f4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002f6:	000d879b          	sext.w	a5,s11
  8002fa:	876a                	mv	a4,s10
  8002fc:	85ca                	mv	a1,s2
  8002fe:	8526                	mv	a0,s1
  800300:	e71ff0ef          	jal	800170 <printnum>
            break;
  800304:	b719                	j	80020a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
  800306:	000a2503          	lw	a0,0(s4)
  80030a:	85ca                	mv	a1,s2
  80030c:	0a21                	addi	s4,s4,8
  80030e:	9482                	jalr	s1
            break;
  800310:	bded                	j	80020a <vprintfmt+0x34>
    if (lflag >= 2) {
  800312:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800314:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800318:	00f74463          	blt	a4,a5,800320 <vprintfmt+0x14a>
    else if (lflag) {
  80031c:	16078963          	beqz	a5,80048e <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
  800320:	000a3603          	ld	a2,0(s4)
  800324:	46a9                	li	a3,10
  800326:	8a2e                	mv	s4,a1
  800328:	b7f9                	j	8002f6 <vprintfmt+0x120>
            putch('0', putdat);
  80032a:	85ca                	mv	a1,s2
  80032c:	03000513          	li	a0,48
  800330:	9482                	jalr	s1
            putch('x', putdat);
  800332:	85ca                	mv	a1,s2
  800334:	07800513          	li	a0,120
  800338:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80033a:	000a3603          	ld	a2,0(s4)
            goto number;
  80033e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800340:	0a21                	addi	s4,s4,8
            goto number;
  800342:	bf55                	j	8002f6 <vprintfmt+0x120>
            putch(ch, putdat);
  800344:	85ca                	mv	a1,s2
  800346:	02500513          	li	a0,37
  80034a:	9482                	jalr	s1
            break;
  80034c:	bd7d                	j	80020a <vprintfmt+0x34>
            precision = va_arg(ap, int);
  80034e:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800352:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
  800354:	0a21                	addi	s4,s4,8
            goto process_precision;
  800356:	bf95                	j	8002ca <vprintfmt+0xf4>
    if (lflag >= 2) {
  800358:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80035a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80035e:	00f74463          	blt	a4,a5,800366 <vprintfmt+0x190>
    else if (lflag) {
  800362:	12078163          	beqz	a5,800484 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
  800366:	000a3603          	ld	a2,0(s4)
  80036a:	46a1                	li	a3,8
  80036c:	8a2e                	mv	s4,a1
  80036e:	b761                	j	8002f6 <vprintfmt+0x120>
            if (width < 0)
  800370:	876a                	mv	a4,s10
  800372:	000d5363          	bgez	s10,800378 <vprintfmt+0x1a2>
  800376:	4701                	li	a4,0
  800378:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
  80037c:	8462                	mv	s0,s8
            goto reswitch;
  80037e:	bd55                	j	800232 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
  800380:	000d841b          	sext.w	s0,s11
  800384:	fd340793          	addi	a5,s0,-45
  800388:	00f037b3          	snez	a5,a5
  80038c:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
  800390:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
  800394:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
  800396:	008a0793          	addi	a5,s4,8
  80039a:	e43e                	sd	a5,8(sp)
  80039c:	100d8c63          	beqz	s11,8004b4 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
  8003a0:	12071363          	bnez	a4,8004c6 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a4:	000dc783          	lbu	a5,0(s11)
  8003a8:	0007851b          	sext.w	a0,a5
  8003ac:	c78d                	beqz	a5,8003d6 <vprintfmt+0x200>
  8003ae:	0d85                	addi	s11,s11,1
  8003b0:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003b2:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003b6:	000cc563          	bltz	s9,8003c0 <vprintfmt+0x1ea>
  8003ba:	3cfd                	addiw	s9,s9,-1
  8003bc:	008c8d63          	beq	s9,s0,8003d6 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003c0:	020b9663          	bnez	s7,8003ec <vprintfmt+0x216>
                    putch(ch, putdat);
  8003c4:	85ca                	mv	a1,s2
  8003c6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003c8:	000dc783          	lbu	a5,0(s11)
  8003cc:	0d85                	addi	s11,s11,1
  8003ce:	3d7d                	addiw	s10,s10,-1
  8003d0:	0007851b          	sext.w	a0,a5
  8003d4:	f3ed                	bnez	a5,8003b6 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
  8003d6:	01a05963          	blez	s10,8003e8 <vprintfmt+0x212>
                putch(' ', putdat);
  8003da:	85ca                	mv	a1,s2
  8003dc:	02000513          	li	a0,32
            for (; width > 0; width --) {
  8003e0:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
  8003e2:	9482                	jalr	s1
            for (; width > 0; width --) {
  8003e4:	fe0d1be3          	bnez	s10,8003da <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003e8:	6a22                	ld	s4,8(sp)
  8003ea:	b505                	j	80020a <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
  8003ec:	3781                	addiw	a5,a5,-32
  8003ee:	fcfa7be3          	bgeu	s4,a5,8003c4 <vprintfmt+0x1ee>
                    putch('?', putdat);
  8003f2:	03f00513          	li	a0,63
  8003f6:	85ca                	mv	a1,s2
  8003f8:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003fa:	000dc783          	lbu	a5,0(s11)
  8003fe:	0d85                	addi	s11,s11,1
  800400:	3d7d                	addiw	s10,s10,-1
  800402:	0007851b          	sext.w	a0,a5
  800406:	dbe1                	beqz	a5,8003d6 <vprintfmt+0x200>
  800408:	fa0cd9e3          	bgez	s9,8003ba <vprintfmt+0x1e4>
  80040c:	b7c5                	j	8003ec <vprintfmt+0x216>
            if (err < 0) {
  80040e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800412:	4661                	li	a2,24
            err = va_arg(ap, int);
  800414:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800416:	41f7d71b          	sraiw	a4,a5,0x1f
  80041a:	8fb9                	xor	a5,a5,a4
  80041c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800420:	02d64563          	blt	a2,a3,80044a <vprintfmt+0x274>
  800424:	00000797          	auipc	a5,0x0
  800428:	62c78793          	addi	a5,a5,1580 # 800a50 <error_string>
  80042c:	00369713          	slli	a4,a3,0x3
  800430:	97ba                	add	a5,a5,a4
  800432:	639c                	ld	a5,0(a5)
  800434:	cb99                	beqz	a5,80044a <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
  800436:	86be                	mv	a3,a5
  800438:	00000617          	auipc	a2,0x0
  80043c:	30860613          	addi	a2,a2,776 # 800740 <main+0x1e8>
  800440:	85ca                	mv	a1,s2
  800442:	8526                	mv	a0,s1
  800444:	0d8000ef          	jal	80051c <printfmt>
  800448:	b3c9                	j	80020a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
  80044a:	00000617          	auipc	a2,0x0
  80044e:	2e660613          	addi	a2,a2,742 # 800730 <main+0x1d8>
  800452:	85ca                	mv	a1,s2
  800454:	8526                	mv	a0,s1
  800456:	0c6000ef          	jal	80051c <printfmt>
  80045a:	bb45                	j	80020a <vprintfmt+0x34>
    if (lflag >= 2) {
  80045c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80045e:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
  800462:	00f74363          	blt	a4,a5,800468 <vprintfmt+0x292>
    else if (lflag) {
  800466:	cf81                	beqz	a5,80047e <vprintfmt+0x2a8>
        return va_arg(*ap, long);
  800468:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80046c:	02044b63          	bltz	s0,8004a2 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
  800470:	8622                	mv	a2,s0
  800472:	8a5e                	mv	s4,s7
  800474:	46a9                	li	a3,10
  800476:	b541                	j	8002f6 <vprintfmt+0x120>
            lflag ++;
  800478:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
  80047a:	8462                	mv	s0,s8
            goto reswitch;
  80047c:	bb5d                	j	800232 <vprintfmt+0x5c>
        return va_arg(*ap, int);
  80047e:	000a2403          	lw	s0,0(s4)
  800482:	b7ed                	j	80046c <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
  800484:	000a6603          	lwu	a2,0(s4)
  800488:	46a1                	li	a3,8
  80048a:	8a2e                	mv	s4,a1
  80048c:	b5ad                	j	8002f6 <vprintfmt+0x120>
  80048e:	000a6603          	lwu	a2,0(s4)
  800492:	46a9                	li	a3,10
  800494:	8a2e                	mv	s4,a1
  800496:	b585                	j	8002f6 <vprintfmt+0x120>
  800498:	000a6603          	lwu	a2,0(s4)
  80049c:	46c1                	li	a3,16
  80049e:	8a2e                	mv	s4,a1
  8004a0:	bd99                	j	8002f6 <vprintfmt+0x120>
                putch('-', putdat);
  8004a2:	85ca                	mv	a1,s2
  8004a4:	02d00513          	li	a0,45
  8004a8:	9482                	jalr	s1
                num = -(long long)num;
  8004aa:	40800633          	neg	a2,s0
  8004ae:	8a5e                	mv	s4,s7
  8004b0:	46a9                	li	a3,10
  8004b2:	b591                	j	8002f6 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
  8004b4:	e329                	bnez	a4,8004f6 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004b6:	02800793          	li	a5,40
  8004ba:	853e                	mv	a0,a5
  8004bc:	00000d97          	auipc	s11,0x0
  8004c0:	26dd8d93          	addi	s11,s11,621 # 800729 <main+0x1d1>
  8004c4:	b5f5                	j	8003b0 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004c6:	85e6                	mv	a1,s9
  8004c8:	856e                	mv	a0,s11
  8004ca:	072000ef          	jal	80053c <strnlen>
  8004ce:	40ad0d3b          	subw	s10,s10,a0
  8004d2:	01a05863          	blez	s10,8004e2 <vprintfmt+0x30c>
                    putch(padc, putdat);
  8004d6:	85ca                	mv	a1,s2
  8004d8:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004da:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
  8004dc:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004de:	fe0d1ce3          	bnez	s10,8004d6 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e2:	000dc783          	lbu	a5,0(s11)
  8004e6:	0007851b          	sext.w	a0,a5
  8004ea:	ec0792e3          	bnez	a5,8003ae <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
  8004ee:	6a22                	ld	s4,8(sp)
  8004f0:	bb29                	j	80020a <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
  8004f2:	8462                	mv	s0,s8
  8004f4:	bbd9                	j	8002ca <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004f6:	85e6                	mv	a1,s9
  8004f8:	00000517          	auipc	a0,0x0
  8004fc:	23050513          	addi	a0,a0,560 # 800728 <main+0x1d0>
  800500:	03c000ef          	jal	80053c <strnlen>
  800504:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800508:	02800793          	li	a5,40
                p = "(null)";
  80050c:	00000d97          	auipc	s11,0x0
  800510:	21cd8d93          	addi	s11,s11,540 # 800728 <main+0x1d0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800514:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800516:	fda040e3          	bgtz	s10,8004d6 <vprintfmt+0x300>
  80051a:	bd51                	j	8003ae <vprintfmt+0x1d8>

000000000080051c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80051c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80051e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800522:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800524:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800526:	ec06                	sd	ra,24(sp)
  800528:	f83a                	sd	a4,48(sp)
  80052a:	fc3e                	sd	a5,56(sp)
  80052c:	e0c2                	sd	a6,64(sp)
  80052e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800530:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800532:	ca5ff0ef          	jal	8001d6 <vprintfmt>
}
  800536:	60e2                	ld	ra,24(sp)
  800538:	6161                	addi	sp,sp,80
  80053a:	8082                	ret

000000000080053c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80053c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80053e:	e589                	bnez	a1,800548 <strnlen+0xc>
  800540:	a811                	j	800554 <strnlen+0x18>
        cnt ++;
  800542:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800544:	00f58863          	beq	a1,a5,800554 <strnlen+0x18>
  800548:	00f50733          	add	a4,a0,a5
  80054c:	00074703          	lbu	a4,0(a4)
  800550:	fb6d                	bnez	a4,800542 <strnlen+0x6>
  800552:	85be                	mv	a1,a5
    }
    return cnt;
}
  800554:	852e                	mv	a0,a1
  800556:	8082                	ret

0000000000800558 <main>:
}

int
main(void)
{
    struct bench_task tasks[] = {
  800558:	00000797          	auipc	a5,0x0
  80055c:	5c078793          	addi	a5,a5,1472 # 800b18 <error_string+0xc8>
  800560:	0007bf03          	ld	t5,0(a5)
  800564:	0087be83          	ld	t4,8(a5)
  800568:	0107be03          	ld	t3,16(a5)
  80056c:	0187b303          	ld	t1,24(a5)
  800570:	0207b883          	ld	a7,32(a5)
  800574:	0287b803          	ld	a6,40(a5)
  800578:	7b88                	ld	a0,48(a5)
  80057a:	7f8c                	ld	a1,56(a5)
  80057c:	63b0                	ld	a2,64(a5)
  80057e:	67b4                	ld	a3,72(a5)
  800580:	6bb8                	ld	a4,80(a5)
  800582:	6fbc                	ld	a5,88(a5)
{
  800584:	7171                	addi	sp,sp,-176
  800586:	f122                	sd	s0,160(sp)
  800588:	ed26                	sd	s1,152(sp)
  80058a:	e94a                	sd	s2,144(sp)
  80058c:	f506                	sd	ra,168(sp)
    struct bench_task tasks[] = {
  80058e:	f07a                	sd	t5,32(sp)
  800590:	f476                	sd	t4,40(sp)
  800592:	f872                	sd	t3,48(sp)
  800594:	fc1a                	sd	t1,56(sp)
  800596:	e0c6                	sd	a7,64(sp)
  800598:	e4c2                	sd	a6,72(sp)
  80059a:	e8aa                	sd	a0,80(sp)
  80059c:	ecae                	sd	a1,88(sp)
  80059e:	f0b2                	sd	a2,96(sp)
  8005a0:	f4b6                	sd	a3,104(sp)
  8005a2:	f8ba                	sd	a4,112(sp)
  8005a4:	fcbe                	sd	a5,120(sp)
        {"cpu-long", 200000, 0, 5},
        {"high-prio", 150000, 120, 10},
    };
    int ntasks = sizeof(tasks) / sizeof(tasks[0]);

    uint32_t global_start = gettime_msec();
  8005a6:	bb7ff0ef          	jal	80015c <gettime_msec>
  8005aa:	892a                	mv	s2,a0
    for (int i = 0; i < ntasks; i++)
  8005ac:	4401                	li	s0,0
  8005ae:	4491                	li	s1,4
    {
        int pid = fork();
  8005b0:	ba1ff0ef          	jal	800150 <fork>
        if (pid == 0)
  8005b4:	c91d                	beqz	a0,8005ea <main+0x92>
            uint32_t end = gettime_msec();
            cprintf("[bench] %-8s pid=%d prio=%u start=%ums end=%ums turnaround=%ums\n",
                    tasks[i].name, getpid(), tasks[i].prio, start, end, end - start);
            exit(0);
        }
        assert(pid > 0);
  8005b6:	0ea05a63          	blez	a0,8006aa <main+0x152>
    for (int i = 0; i < ntasks; i++)
  8005ba:	2405                	addiw	s0,s0,1
  8005bc:	fe941ae3          	bne	s0,s1,8005b0 <main+0x58>
    }

    while (wait() == 0)
  8005c0:	b93ff0ef          	jal	800152 <wait>
  8005c4:	dd75                	beqz	a0,8005c0 <main+0x68>
    {
        ;
    }

    uint32_t global_end = gettime_msec();
  8005c6:	b97ff0ef          	jal	80015c <gettime_msec>
    cprintf("[bench] all done total=%ums for %d tasks\n", global_end - global_start, ntasks);
  8005ca:	412505bb          	subw	a1,a0,s2
  8005ce:	4611                	li	a2,4
  8005d0:	00000517          	auipc	a0,0x0
  8005d4:	2b850513          	addi	a0,a0,696 # 800888 <main+0x330>
  8005d8:	ac9ff0ef          	jal	8000a0 <cprintf>
    return 0;
}
  8005dc:	70aa                	ld	ra,168(sp)
  8005de:	740a                	ld	s0,160(sp)
  8005e0:	64ea                	ld	s1,152(sp)
  8005e2:	694a                	ld	s2,144(sp)
  8005e4:	4501                	li	a0,0
  8005e6:	614d                	addi	sp,sp,176
  8005e8:	8082                	ret
            lab6_setpriority(tasks[i].prio);
  8005ea:	44e1                	li	s1,24
  8005ec:	029404b3          	mul	s1,s0,s1
  8005f0:	1018                	addi	a4,sp,32
  8005f2:	e42a                	sd	a0,8(sp)
  8005f4:	e54e                	sd	s3,136(sp)
  8005f6:	06048793          	addi	a5,s1,96
  8005fa:	00e784b3          	add	s1,a5,a4
  8005fe:	fb04a783          	lw	a5,-80(s1)
  800602:	853e                	mv	a0,a5
  800604:	893e                	mv	s2,a5
  800606:	b59ff0ef          	jal	80015e <lab6_setpriority>
            uint32_t start = gettime_msec();
  80060a:	b53ff0ef          	jal	80015c <gettime_msec>
    for (int i = 0; i < loops; i++)
  80060e:	67a2                	ld	a5,8(sp)
            busy_work(tasks[i].loops, tasks[i].yield_mod);
  800610:	fa84a583          	lw	a1,-88(s1)
  800614:	fac4a603          	lw	a2,-84(s1)
        sink = sink * 1664525U + 1013904223U;
  800618:	001966b7          	lui	a3,0x196
  80061c:	3c6ef4b7          	lui	s1,0x3c6ef
            uint32_t start = gettime_msec();
  800620:	89aa                	mv	s3,a0
        sink = sink * 1664525U + 1013904223U;
  800622:	60d6869b          	addiw	a3,a3,1549 # 19660d <_start-0x669a13>
  800626:	35f4849b          	addiw	s1,s1,863 # 3c6ef35f <sink+0x3beee35f>
    for (int i = 0; i < loops; i++)
  80062a:	04b7d263          	bge	a5,a1,80066e <main+0x116>
        sink = sink * 1664525U + 1013904223U;
  80062e:	00001717          	auipc	a4,0x1
  800632:	9d272703          	lw	a4,-1582(a4) # 801000 <sink>
  800636:	02d7073b          	mulw	a4,a4,a3
  80063a:	9f25                	addw	a4,a4,s1
  80063c:	00001517          	auipc	a0,0x1
  800640:	9ce52223          	sw	a4,-1596(a0) # 801000 <sink>
        if (yield_mod > 0 && (i % yield_mod) == 0)
  800644:	00c05563          	blez	a2,80064e <main+0xf6>
  800648:	02c7e73b          	remw	a4,a5,a2
  80064c:	c319                	beqz	a4,800652 <main+0xfa>
    for (int i = 0; i < loops; i++)
  80064e:	2785                	addiw	a5,a5,1
  800650:	bfe9                	j	80062a <main+0xd2>
  800652:	ec3e                	sd	a5,24(sp)
  800654:	e832                	sd	a2,16(sp)
  800656:	e42e                	sd	a1,8(sp)
            yield();
  800658:	b01ff0ef          	jal	800158 <yield>
  80065c:	67e2                	ld	a5,24(sp)
  80065e:	001966b7          	lui	a3,0x196
  800662:	6642                	ld	a2,16(sp)
  800664:	65a2                	ld	a1,8(sp)
  800666:	60d6869b          	addiw	a3,a3,1549 # 19660d <_start-0x669a13>
    for (int i = 0; i < loops; i++)
  80066a:	2785                	addiw	a5,a5,1
  80066c:	bf7d                	j	80062a <main+0xd2>
            uint32_t end = gettime_msec();
  80066e:	aefff0ef          	jal	80015c <gettime_msec>
            cprintf("[bench] %-8s pid=%d prio=%u start=%ums end=%ums turnaround=%ums\n",
  800672:	47e1                	li	a5,24
  800674:	02f40733          	mul	a4,s0,a5
            uint32_t end = gettime_msec();
  800678:	84aa                	mv	s1,a0
            cprintf("[bench] %-8s pid=%d prio=%u start=%ums end=%ums turnaround=%ums\n",
  80067a:	06070793          	addi	a5,a4,96
  80067e:	1018                	addi	a4,sp,32
  800680:	973e                	add	a4,a4,a5
  800682:	fa073403          	ld	s0,-96(a4)
  800686:	ad5ff0ef          	jal	80015a <getpid>
  80068a:	862a                	mv	a2,a0
  80068c:	86ca                	mv	a3,s2
  80068e:	85a2                	mv	a1,s0
  800690:	874e                	mv	a4,s3
  800692:	4134883b          	subw	a6,s1,s3
  800696:	87a6                	mv	a5,s1
  800698:	00000517          	auipc	a0,0x0
  80069c:	17050513          	addi	a0,a0,368 # 800808 <main+0x2b0>
  8006a0:	a01ff0ef          	jal	8000a0 <cprintf>
            exit(0);
  8006a4:	4501                	li	a0,0
  8006a6:	a95ff0ef          	jal	80013a <exit>
        assert(pid > 0);
  8006aa:	00000697          	auipc	a3,0x0
  8006ae:	1a668693          	addi	a3,a3,422 # 800850 <main+0x2f8>
  8006b2:	00000617          	auipc	a2,0x0
  8006b6:	1a660613          	addi	a2,a2,422 # 800858 <main+0x300>
  8006ba:	03300593          	li	a1,51
  8006be:	00000517          	auipc	a0,0x0
  8006c2:	1b250513          	addi	a0,a0,434 # 800870 <main+0x318>
  8006c6:	e54e                	sd	s3,136(sp)
  8006c8:	95fff0ef          	jal	800026 <__panic>
