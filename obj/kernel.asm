
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000b1517          	auipc	a0,0xb1
ffffffffc020004e:	23e50513          	addi	a0,a0,574 # ffffffffc02b1288 <buf>
ffffffffc0200052:	000b5617          	auipc	a2,0xb5
ffffffffc0200056:	71660613          	addi	a2,a2,1814 # ffffffffc02b5768 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc020aff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	037050ef          	jal	ffffffffc0205898 <memset>
    cons_init(); // init the console
ffffffffc0200066:	4da000ef          	jal	ffffffffc0200540 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	85e58593          	addi	a1,a1,-1954 # ffffffffc02058c8 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	87650513          	addi	a0,a0,-1930 # ffffffffc02058e8 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1ac000ef          	jal	ffffffffc020022a <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	530000ef          	jal	ffffffffc02005b2 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	604020ef          	jal	ffffffffc020268a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	07b000ef          	jal	ffffffffc0200904 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	079000ef          	jal	ffffffffc0200906 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	0f1030ef          	jal	ffffffffc0203982 <vmm_init>
    sched_init();
ffffffffc0200096:	06e050ef          	jal	ffffffffc0205104 <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	571040ef          	jal	ffffffffc0204e0a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	45a000ef          	jal	ffffffffc02004f8 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	057000ef          	jal	ffffffffc02008f8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	705040ef          	jal	ffffffffc0204faa <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	7179                	addi	sp,sp,-48
ffffffffc02000ac:	f406                	sd	ra,40(sp)
ffffffffc02000ae:	f022                	sd	s0,32(sp)
ffffffffc02000b0:	ec26                	sd	s1,24(sp)
ffffffffc02000b2:	e84a                	sd	s2,16(sp)
ffffffffc02000b4:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b6:	c901                	beqz	a0,ffffffffc02000c6 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b8:	85aa                	mv	a1,a0
ffffffffc02000ba:	00006517          	auipc	a0,0x6
ffffffffc02000be:	83650513          	addi	a0,a0,-1994 # ffffffffc02058f0 <etext+0x2e>
ffffffffc02000c2:	0d6000ef          	jal	ffffffffc0200198 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c6:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c8:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000ca:	000b1997          	auipc	s3,0xb1
ffffffffc02000ce:	1be98993          	addi	s3,s3,446 # ffffffffc02b1288 <buf>
        c = getchar();
ffffffffc02000d2:	148000ef          	jal	ffffffffc020021a <getchar>
ffffffffc02000d6:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d8:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000dc:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000e0:	ff650693          	addi	a3,a0,-10
ffffffffc02000e4:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e8:	02054963          	bltz	a0,ffffffffc020011a <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ec:	02a95f63          	bge	s2,a0,ffffffffc020012a <readline+0x80>
ffffffffc02000f0:	cf0d                	beqz	a4,ffffffffc020012a <readline+0x80>
            cputchar(c);
ffffffffc02000f2:	0da000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i ++] = c;
ffffffffc02000f6:	009987b3          	add	a5,s3,s1
ffffffffc02000fa:	00878023          	sb	s0,0(a5)
ffffffffc02000fe:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0200100:	11a000ef          	jal	ffffffffc020021a <getchar>
ffffffffc0200104:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200106:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010a:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	ff650693          	addi	a3,a0,-10
ffffffffc0200112:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200116:	fc055be3          	bgez	a0,ffffffffc02000ec <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc020011a:	70a2                	ld	ra,40(sp)
ffffffffc020011c:	7402                	ld	s0,32(sp)
ffffffffc020011e:	64e2                	ld	s1,24(sp)
ffffffffc0200120:	6942                	ld	s2,16(sp)
ffffffffc0200122:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200124:	4501                	li	a0,0
}
ffffffffc0200126:	6145                	addi	sp,sp,48
ffffffffc0200128:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	eb81                	bnez	a5,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc020012c:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012e:	00905663          	blez	s1,ffffffffc020013a <readline+0x90>
            cputchar(c);
ffffffffc0200132:	09a000ef          	jal	ffffffffc02001cc <cputchar>
            i --;
ffffffffc0200136:	34fd                	addiw	s1,s1,-1
ffffffffc0200138:	bf69                	j	ffffffffc02000d2 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc020013a:	c291                	beqz	a3,ffffffffc020013e <readline+0x94>
ffffffffc020013c:	fa59                	bnez	a2,ffffffffc02000d2 <readline+0x28>
            cputchar(c);
ffffffffc020013e:	8522                	mv	a0,s0
ffffffffc0200140:	08c000ef          	jal	ffffffffc02001cc <cputchar>
            buf[i] = '\0';
ffffffffc0200144:	000b1517          	auipc	a0,0xb1
ffffffffc0200148:	14450513          	addi	a0,a0,324 # ffffffffc02b1288 <buf>
ffffffffc020014c:	94aa                	add	s1,s1,a0
ffffffffc020014e:	00048023          	sb	zero,0(s1)
}
ffffffffc0200152:	70a2                	ld	ra,40(sp)
ffffffffc0200154:	7402                	ld	s0,32(sp)
ffffffffc0200156:	64e2                	ld	s1,24(sp)
ffffffffc0200158:	6942                	ld	s2,16(sp)
ffffffffc020015a:	69a2                	ld	s3,8(sp)
ffffffffc020015c:	6145                	addi	sp,sp,48
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200166:	3dc000ef          	jal	ffffffffc0200542 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	65a2                	ld	a1,8(sp)
}
ffffffffc020016c:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016e:	419c                	lw	a5,0(a1)
ffffffffc0200170:	2785                	addiw	a5,a5,1
ffffffffc0200172:	c19c                	sw	a5,0(a1)
}
ffffffffc0200174:	6105                	addi	sp,sp,32
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe250513          	addi	a0,a0,-30 # ffffffffc0200160 <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	2f2050ef          	jal	ffffffffc020547e <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40
{
ffffffffc020019e:	f42e                	sd	a1,40(sp)
ffffffffc02001a0:	f832                	sd	a2,48(sp)
ffffffffc02001a2:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a4:	862a                	mv	a2,a0
ffffffffc02001a6:	004c                	addi	a1,sp,4
ffffffffc02001a8:	00000517          	auipc	a0,0x0
ffffffffc02001ac:	fb850513          	addi	a0,a0,-72 # ffffffffc0200160 <cputch>
ffffffffc02001b0:	869a                	mv	a3,t1
{
ffffffffc02001b2:	ec06                	sd	ra,24(sp)
ffffffffc02001b4:	e0ba                	sd	a4,64(sp)
ffffffffc02001b6:	e4be                	sd	a5,72(sp)
ffffffffc02001b8:	e8c2                	sd	a6,80(sp)
ffffffffc02001ba:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c0:	2be050ef          	jal	ffffffffc020547e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c4:	60e2                	ld	ra,24(sp)
ffffffffc02001c6:	4512                	lw	a0,4(sp)
ffffffffc02001c8:	6125                	addi	sp,sp,96
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001cc:	ae9d                	j	ffffffffc0200542 <cons_putc>

ffffffffc02001ce <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ce:	1101                	addi	sp,sp,-32
ffffffffc02001d0:	e822                	sd	s0,16(sp)
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3a>
ffffffffc02001dc:	e426                	sd	s1,8(sp)
ffffffffc02001de:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001e0:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001e2:	360000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	0405                	addi	s0,s0,1
ffffffffc02001ec:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ee:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x14>
    cons_putc(c);
ffffffffc02001f2:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f4:	0027841b          	addiw	s0,a5,2
ffffffffc02001f8:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001fa:	348000ef          	jal	ffffffffc0200542 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fe:	60e2                	ld	ra,24(sp)
ffffffffc0200200:	8522                	mv	a0,s0
ffffffffc0200202:	6442                	ld	s0,16(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    cons_putc(c);
ffffffffc0200208:	4529                	li	a0,10
ffffffffc020020a:	338000ef          	jal	ffffffffc0200542 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020e:	4405                	li	s0,1
}
ffffffffc0200210:	60e2                	ld	ra,24(sp)
ffffffffc0200212:	8522                	mv	a0,s0
ffffffffc0200214:	6442                	ld	s0,16(sp)
ffffffffc0200216:	6105                	addi	sp,sp,32
ffffffffc0200218:	8082                	ret

ffffffffc020021a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020021a:	1141                	addi	sp,sp,-16
ffffffffc020021c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021e:	358000ef          	jal	ffffffffc0200576 <cons_getc>
ffffffffc0200222:	dd75                	beqz	a0,ffffffffc020021e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200224:	60a2                	ld	ra,8(sp)
ffffffffc0200226:	0141                	addi	sp,sp,16
ffffffffc0200228:	8082                	ret

ffffffffc020022a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020022a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	00005517          	auipc	a0,0x5
ffffffffc0200230:	6cc50513          	addi	a0,a0,1740 # ffffffffc02058f8 <etext+0x36>
void print_kerninfo(void) {
ffffffffc0200234:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200236:	f63ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020023a:	00000597          	auipc	a1,0x0
ffffffffc020023e:	e1058593          	addi	a1,a1,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	00005517          	auipc	a0,0x5
ffffffffc0200246:	6d650513          	addi	a0,a0,1750 # ffffffffc0205918 <etext+0x56>
ffffffffc020024a:	f4fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024e:	00005597          	auipc	a1,0x5
ffffffffc0200252:	67458593          	addi	a1,a1,1652 # ffffffffc02058c2 <etext>
ffffffffc0200256:	00005517          	auipc	a0,0x5
ffffffffc020025a:	6e250513          	addi	a0,a0,1762 # ffffffffc0205938 <etext+0x76>
ffffffffc020025e:	f3bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200262:	000b1597          	auipc	a1,0xb1
ffffffffc0200266:	02658593          	addi	a1,a1,38 # ffffffffc02b1288 <buf>
ffffffffc020026a:	00005517          	auipc	a0,0x5
ffffffffc020026e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0205958 <etext+0x96>
ffffffffc0200272:	f27ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200276:	000b5597          	auipc	a1,0xb5
ffffffffc020027a:	4f258593          	addi	a1,a1,1266 # ffffffffc02b5768 <end>
ffffffffc020027e:	00005517          	auipc	a0,0x5
ffffffffc0200282:	6fa50513          	addi	a0,a0,1786 # ffffffffc0205978 <etext+0xb6>
ffffffffc0200286:	f13ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020028a:	00000717          	auipc	a4,0x0
ffffffffc020028e:	dc070713          	addi	a4,a4,-576 # ffffffffc020004a <kern_init>
ffffffffc0200292:	000b6797          	auipc	a5,0xb6
ffffffffc0200296:	8d578793          	addi	a5,a5,-1835 # ffffffffc02b5b67 <end+0x3ff>
ffffffffc020029a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002a0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a6:	95be                	add	a1,a1,a5
ffffffffc02002a8:	85a9                	srai	a1,a1,0xa
ffffffffc02002aa:	00005517          	auipc	a0,0x5
ffffffffc02002ae:	6ee50513          	addi	a0,a0,1774 # ffffffffc0205998 <etext+0xd6>
}
ffffffffc02002b2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	b5d5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002b6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b8:	00005617          	auipc	a2,0x5
ffffffffc02002bc:	71060613          	addi	a2,a2,1808 # ffffffffc02059c8 <etext+0x106>
ffffffffc02002c0:	04d00593          	li	a1,77
ffffffffc02002c4:	00005517          	auipc	a0,0x5
ffffffffc02002c8:	71c50513          	addi	a0,a0,1820 # ffffffffc02059e0 <etext+0x11e>
void print_stackframe(void) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ce:	17c000ef          	jal	ffffffffc020044a <__panic>

ffffffffc02002d2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d2:	1101                	addi	sp,sp,-32
ffffffffc02002d4:	e822                	sd	s0,16(sp)
ffffffffc02002d6:	e426                	sd	s1,8(sp)
ffffffffc02002d8:	ec06                	sd	ra,24(sp)
ffffffffc02002da:	00007417          	auipc	s0,0x7
ffffffffc02002de:	34e40413          	addi	s0,s0,846 # ffffffffc0207628 <commands>
ffffffffc02002e2:	00007497          	auipc	s1,0x7
ffffffffc02002e6:	38e48493          	addi	s1,s1,910 # ffffffffc0207670 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	6410                	ld	a2,8(s0)
ffffffffc02002ec:	600c                	ld	a1,0(s0)
ffffffffc02002ee:	00005517          	auipc	a0,0x5
ffffffffc02002f2:	70a50513          	addi	a0,a0,1802 # ffffffffc02059f8 <etext+0x136>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f8:	ea1ff0ef          	jal	ffffffffc0200198 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fc:	fe9417e3          	bne	s0,s1,ffffffffc02002ea <mon_help+0x18>
    }
    return 0;
}
ffffffffc0200300:	60e2                	ld	ra,24(sp)
ffffffffc0200302:	6442                	ld	s0,16(sp)
ffffffffc0200304:	64a2                	ld	s1,8(sp)
ffffffffc0200306:	4501                	li	a0,0
ffffffffc0200308:	6105                	addi	sp,sp,32
ffffffffc020030a:	8082                	ret

ffffffffc020030c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020030c:	1141                	addi	sp,sp,-16
ffffffffc020030e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200310:	f1bff0ef          	jal	ffffffffc020022a <print_kerninfo>
    return 0;
}
ffffffffc0200314:	60a2                	ld	ra,8(sp)
ffffffffc0200316:	4501                	li	a0,0
ffffffffc0200318:	0141                	addi	sp,sp,16
ffffffffc020031a:	8082                	ret

ffffffffc020031c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020031c:	1141                	addi	sp,sp,-16
ffffffffc020031e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200320:	f97ff0ef          	jal	ffffffffc02002b6 <print_stackframe>
    return 0;
}
ffffffffc0200324:	60a2                	ld	ra,8(sp)
ffffffffc0200326:	4501                	li	a0,0
ffffffffc0200328:	0141                	addi	sp,sp,16
ffffffffc020032a:	8082                	ret

ffffffffc020032c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020032c:	7131                	addi	sp,sp,-192
ffffffffc020032e:	e952                	sd	s4,144(sp)
ffffffffc0200330:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200332:	00005517          	auipc	a0,0x5
ffffffffc0200336:	6d650513          	addi	a0,a0,1750 # ffffffffc0205a08 <etext+0x146>
kmonitor(struct trapframe *tf) {
ffffffffc020033a:	fd06                	sd	ra,184(sp)
ffffffffc020033c:	f922                	sd	s0,176(sp)
ffffffffc020033e:	f526                	sd	s1,168(sp)
ffffffffc0200340:	ed4e                	sd	s3,152(sp)
ffffffffc0200342:	e556                	sd	s5,136(sp)
ffffffffc0200344:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200346:	e53ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020034a:	00005517          	auipc	a0,0x5
ffffffffc020034e:	6e650513          	addi	a0,a0,1766 # ffffffffc0205a30 <etext+0x16e>
ffffffffc0200352:	e47ff0ef          	jal	ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc0200356:	000a0563          	beqz	s4,ffffffffc0200360 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020035a:	8552                	mv	a0,s4
ffffffffc020035c:	792000ef          	jal	ffffffffc0200aee <print_trapframe>
ffffffffc0200360:	00007a97          	auipc	s5,0x7
ffffffffc0200364:	2c8a8a93          	addi	s5,s5,712 # ffffffffc0207628 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036a:	00005517          	auipc	a0,0x5
ffffffffc020036e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0205a58 <etext+0x196>
ffffffffc0200372:	d39ff0ef          	jal	ffffffffc02000aa <readline>
ffffffffc0200376:	842a                	mv	s0,a0
ffffffffc0200378:	d96d                	beqz	a0,ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037e:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	e99d                	bnez	a1,ffffffffc02003b6 <kmonitor+0x8a>
    int argc = 0;
ffffffffc0200382:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200384:	fe0b03e3          	beqz	s6,ffffffffc020036a <kmonitor+0x3e>
ffffffffc0200388:	00007497          	auipc	s1,0x7
ffffffffc020038c:	2a048493          	addi	s1,s1,672 # ffffffffc0207628 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	6088                	ld	a0,0(s1)
ffffffffc0200396:	494050ef          	jal	ffffffffc020582a <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020039c:	c149                	beqz	a0,ffffffffc020041e <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	2405                	addiw	s0,s0,1
ffffffffc02003a0:	04e1                	addi	s1,s1,24
ffffffffc02003a2:	fef418e3          	bne	s0,a5,ffffffffc0200392 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a6:	6582                	ld	a1,0(sp)
ffffffffc02003a8:	00005517          	auipc	a0,0x5
ffffffffc02003ac:	6e050513          	addi	a0,a0,1760 # ffffffffc0205a88 <etext+0x1c6>
ffffffffc02003b0:	de9ff0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
ffffffffc02003b4:	bf5d                	j	ffffffffc020036a <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00005517          	auipc	a0,0x5
ffffffffc02003ba:	6aa50513          	addi	a0,a0,1706 # ffffffffc0205a60 <etext+0x19e>
ffffffffc02003be:	4c8050ef          	jal	ffffffffc0205886 <strchr>
ffffffffc02003c2:	c901                	beqz	a0,ffffffffc02003d2 <kmonitor+0xa6>
ffffffffc02003c4:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003c8:	00040023          	sb	zero,0(s0)
ffffffffc02003cc:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	d9d5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003d0:	b7dd                	j	ffffffffc02003b6 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc02003d2:	00044783          	lbu	a5,0(s0)
ffffffffc02003d6:	d7d5                	beqz	a5,ffffffffc0200382 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc02003d8:	03348b63          	beq	s1,s3,ffffffffc020040e <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc02003dc:	00349793          	slli	a5,s1,0x3
ffffffffc02003e0:	978a                	add	a5,a5,sp
ffffffffc02003e2:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003e8:	2485                	addiw	s1,s1,1
ffffffffc02003ea:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ec:	e591                	bnez	a1,ffffffffc02003f8 <kmonitor+0xcc>
ffffffffc02003ee:	bf59                	j	ffffffffc0200384 <kmonitor+0x58>
ffffffffc02003f0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003f4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f6:	d5d1                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc02003f8:	00005517          	auipc	a0,0x5
ffffffffc02003fc:	66850513          	addi	a0,a0,1640 # ffffffffc0205a60 <etext+0x19e>
ffffffffc0200400:	486050ef          	jal	ffffffffc0205886 <strchr>
ffffffffc0200404:	d575                	beqz	a0,ffffffffc02003f0 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	00044583          	lbu	a1,0(s0)
ffffffffc020040a:	dda5                	beqz	a1,ffffffffc0200382 <kmonitor+0x56>
ffffffffc020040c:	b76d                	j	ffffffffc02003b6 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040e:	45c1                	li	a1,16
ffffffffc0200410:	00005517          	auipc	a0,0x5
ffffffffc0200414:	65850513          	addi	a0,a0,1624 # ffffffffc0205a68 <etext+0x1a6>
ffffffffc0200418:	d81ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020041c:	b7c1                	j	ffffffffc02003dc <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041e:	00141793          	slli	a5,s0,0x1
ffffffffc0200422:	97a2                	add	a5,a5,s0
ffffffffc0200424:	078e                	slli	a5,a5,0x3
ffffffffc0200426:	97d6                	add	a5,a5,s5
ffffffffc0200428:	6b9c                	ld	a5,16(a5)
ffffffffc020042a:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042e:	8652                	mv	a2,s4
ffffffffc0200430:	002c                	addi	a1,sp,8
ffffffffc0200432:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200434:	f2055be3          	bgez	a0,ffffffffc020036a <kmonitor+0x3e>
}
ffffffffc0200438:	70ea                	ld	ra,184(sp)
ffffffffc020043a:	744a                	ld	s0,176(sp)
ffffffffc020043c:	74aa                	ld	s1,168(sp)
ffffffffc020043e:	69ea                	ld	s3,152(sp)
ffffffffc0200440:	6a4a                	ld	s4,144(sp)
ffffffffc0200442:	6aaa                	ld	s5,136(sp)
ffffffffc0200444:	6b0a                	ld	s6,128(sp)
ffffffffc0200446:	6129                	addi	sp,sp,192
ffffffffc0200448:	8082                	ret

ffffffffc020044a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020044a:	000b5317          	auipc	t1,0xb5
ffffffffc020044e:	29633303          	ld	t1,662(t1) # ffffffffc02b56e0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200452:	715d                	addi	sp,sp,-80
ffffffffc0200454:	ec06                	sd	ra,24(sp)
ffffffffc0200456:	f436                	sd	a3,40(sp)
ffffffffc0200458:	f83a                	sd	a4,48(sp)
ffffffffc020045a:	fc3e                	sd	a5,56(sp)
ffffffffc020045c:	e0c2                	sd	a6,64(sp)
ffffffffc020045e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200460:	02031e63          	bnez	t1,ffffffffc020049c <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200464:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200466:	103c                	addi	a5,sp,40
ffffffffc0200468:	e822                	sd	s0,16(sp)
ffffffffc020046a:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020046c:	862e                	mv	a2,a1
ffffffffc020046e:	85aa                	mv	a1,a0
ffffffffc0200470:	00005517          	auipc	a0,0x5
ffffffffc0200474:	6c050513          	addi	a0,a0,1728 # ffffffffc0205b30 <etext+0x26e>
    is_panic = 1;
ffffffffc0200478:	000b5697          	auipc	a3,0xb5
ffffffffc020047c:	26e6b423          	sd	a4,616(a3) # ffffffffc02b56e0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200480:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200482:	d17ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200486:	65a2                	ld	a1,8(sp)
ffffffffc0200488:	8522                	mv	a0,s0
ffffffffc020048a:	cefff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020048e:	00005517          	auipc	a0,0x5
ffffffffc0200492:	6c250513          	addi	a0,a0,1730 # ffffffffc0205b50 <etext+0x28e>
ffffffffc0200496:	d03ff0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc020049a:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020049c:	4501                	li	a0,0
ffffffffc020049e:	4581                	li	a1,0
ffffffffc02004a0:	4601                	li	a2,0
ffffffffc02004a2:	48a1                	li	a7,8
ffffffffc02004a4:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a8:	456000ef          	jal	ffffffffc02008fe <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	e7fff0ef          	jal	ffffffffc020032c <kmonitor>
    while (1) {
ffffffffc02004b2:	bfed                	j	ffffffffc02004ac <__panic+0x62>

ffffffffc02004b4 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004b4:	715d                	addi	sp,sp,-80
ffffffffc02004b6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	02810313          	addi	t1,sp,40
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004bc:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004be:	862e                	mv	a2,a1
ffffffffc02004c0:	85aa                	mv	a1,a0
ffffffffc02004c2:	00005517          	auipc	a0,0x5
ffffffffc02004c6:	69650513          	addi	a0,a0,1686 # ffffffffc0205b58 <etext+0x296>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ca:	ec06                	sd	ra,24(sp)
ffffffffc02004cc:	f436                	sd	a3,40(sp)
ffffffffc02004ce:	f83a                	sd	a4,48(sp)
ffffffffc02004d0:	fc3e                	sd	a5,56(sp)
ffffffffc02004d2:	e0c2                	sd	a6,64(sp)
ffffffffc02004d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d6:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d8:	cc1ff0ef          	jal	ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004dc:	65a2                	ld	a1,8(sp)
ffffffffc02004de:	8522                	mv	a0,s0
ffffffffc02004e0:	c99ff0ef          	jal	ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004e4:	00005517          	auipc	a0,0x5
ffffffffc02004e8:	66c50513          	addi	a0,a0,1644 # ffffffffc0205b50 <etext+0x28e>
ffffffffc02004ec:	cadff0ef          	jal	ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc02004f0:	60e2                	ld	ra,24(sp)
ffffffffc02004f2:	6442                	ld	s0,16(sp)
ffffffffc02004f4:	6161                	addi	sp,sp,80
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc02004f8:	02000793          	li	a5,32
ffffffffc02004fc:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200500:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200504:	67e1                	lui	a5,0x18
ffffffffc0200506:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd160>
ffffffffc020050a:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050c:	4581                	li	a1,0
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc0200516:	00005517          	auipc	a0,0x5
ffffffffc020051a:	66250513          	addi	a0,a0,1634 # ffffffffc0205b78 <etext+0x2b6>
    ticks = 0;
ffffffffc020051e:	000b5797          	auipc	a5,0xb5
ffffffffc0200522:	1c07b523          	sd	zero,458(a5) # ffffffffc02b56e8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200526:	b98d                	j	ffffffffc0200198 <cprintf>

ffffffffc0200528 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200528:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020052c:	67e1                	lui	a5,0x18
ffffffffc020052e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd160>
ffffffffc0200532:	953e                	add	a0,a0,a5
ffffffffc0200534:	4581                	li	a1,0
ffffffffc0200536:	4601                	li	a2,0
ffffffffc0200538:	4881                	li	a7,0
ffffffffc020053a:	00000073          	ecall
ffffffffc020053e:	8082                	ret

ffffffffc0200540 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200540:	8082                	ret

ffffffffc0200542 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200542:	100027f3          	csrr	a5,sstatus
ffffffffc0200546:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200548:	0ff57513          	zext.b	a0,a0
ffffffffc020054c:	e799                	bnez	a5,ffffffffc020055a <cons_putc+0x18>
ffffffffc020054e:	4581                	li	a1,0
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4885                	li	a7,1
ffffffffc0200554:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200558:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020055a:	1101                	addi	sp,sp,-32
ffffffffc020055c:	ec06                	sd	ra,24(sp)
ffffffffc020055e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200560:	39e000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200564:	6522                	ld	a0,8(sp)
ffffffffc0200566:	4581                	li	a1,0
ffffffffc0200568:	4601                	li	a2,0
ffffffffc020056a:	4885                	li	a7,1
ffffffffc020056c:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200570:	60e2                	ld	ra,24(sp)
ffffffffc0200572:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc0200574:	a651                	j	ffffffffc02008f8 <intr_enable>

ffffffffc0200576 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200576:	100027f3          	csrr	a5,sstatus
ffffffffc020057a:	8b89                	andi	a5,a5,2
ffffffffc020057c:	eb89                	bnez	a5,ffffffffc020058e <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020057e:	4501                	li	a0,0
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4889                	li	a7,2
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020058c:	8082                	ret
int cons_getc(void) {
ffffffffc020058e:	1101                	addi	sp,sp,-32
ffffffffc0200590:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200592:	36c000ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0200596:	4501                	li	a0,0
ffffffffc0200598:	4581                	li	a1,0
ffffffffc020059a:	4601                	li	a2,0
ffffffffc020059c:	4889                	li	a7,2
ffffffffc020059e:	00000073          	ecall
ffffffffc02005a2:	2501                	sext.w	a0,a0
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005a6:	352000ef          	jal	ffffffffc02008f8 <intr_enable>
}
ffffffffc02005aa:	60e2                	ld	ra,24(sp)
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	6105                	addi	sp,sp,32
ffffffffc02005b0:	8082                	ret

ffffffffc02005b2 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b2:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005b4:	00005517          	auipc	a0,0x5
ffffffffc02005b8:	5e450513          	addi	a0,a0,1508 # ffffffffc0205b98 <etext+0x2d6>
void dtb_init(void) {
ffffffffc02005bc:	f406                	sd	ra,40(sp)
ffffffffc02005be:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c0:	bd9ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005c4:	0000c597          	auipc	a1,0xc
ffffffffc02005c8:	a3c5b583          	ld	a1,-1476(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc02005cc:	00005517          	auipc	a0,0x5
ffffffffc02005d0:	5dc50513          	addi	a0,a0,1500 # ffffffffc0205ba8 <etext+0x2e6>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005d4:	0000c417          	auipc	s0,0xc
ffffffffc02005d8:	a3440413          	addi	s0,s0,-1484 # ffffffffc020c008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005dc:	bbdff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e0:	600c                	ld	a1,0(s0)
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	5d650513          	addi	a0,a0,1494 # ffffffffc0205bb8 <etext+0x2f6>
ffffffffc02005ea:	bafff0ef          	jal	ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005ee:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f0:	00005517          	auipc	a0,0x5
ffffffffc02005f4:	5e050513          	addi	a0,a0,1504 # ffffffffc0205bd0 <etext+0x30e>
    if (boot_dtb == 0) {
ffffffffc02005f8:	10070163          	beqz	a4,ffffffffc02006fa <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005fc:	57f5                	li	a5,-3
ffffffffc02005fe:	07fa                	slli	a5,a5,0x1e
ffffffffc0200600:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200602:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200604:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200608:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe2a785>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200610:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200614:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061c:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200620:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	8e49                	or	a2,a2,a0
ffffffffc0200624:	0ff7f793          	zext.b	a5,a5
ffffffffc0200628:	8dd1                	or	a1,a1,a2
ffffffffc020062a:	07a2                	slli	a5,a5,0x8
ffffffffc020062c:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062e:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200632:	0cd59863          	bne	a1,a3,ffffffffc0200702 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200636:	4710                	lw	a2,8(a4)
ffffffffc0200638:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020063a:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200640:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200644:	01865e1b          	srliw	t3,a2,0x18
ffffffffc0200648:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064c:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200650:	0186959b          	slliw	a1,a3,0x18
ffffffffc0200654:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200660:	0106d69b          	srliw	a3,a3,0x10
ffffffffc0200664:	01c56533          	or	a0,a0,t3
ffffffffc0200668:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200670:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0ff6f693          	zext.b	a3,a3
ffffffffc020067c:	8c49                	or	s0,s0,a0
ffffffffc020067e:	0622                	slli	a2,a2,0x8
ffffffffc0200680:	8fcd                	or	a5,a5,a1
ffffffffc0200682:	06a2                	slli	a3,a3,0x8
ffffffffc0200684:	8c51                	or	s0,s0,a2
ffffffffc0200686:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200688:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068a:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068c:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020068e:	9381                	srli	a5,a5,0x20
ffffffffc0200690:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200692:	4301                	li	t1,0
        switch (token) {
ffffffffc0200694:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200696:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200698:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020069c:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020069e:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006a4:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ac:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	8ed1                	or	a3,a3,a2
ffffffffc02006ba:	0ff77713          	zext.b	a4,a4
ffffffffc02006be:	8fd5                	or	a5,a5,a3
ffffffffc02006c0:	0722                	slli	a4,a4,0x8
ffffffffc02006c2:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006c4:	05178763          	beq	a5,a7,ffffffffc0200712 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c8:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006ca:	00f8e963          	bltu	a7,a5,ffffffffc02006dc <dtb_init+0x12a>
ffffffffc02006ce:	07c78d63          	beq	a5,t3,ffffffffc0200748 <dtb_init+0x196>
ffffffffc02006d2:	4709                	li	a4,2
ffffffffc02006d4:	00e79763          	bne	a5,a4,ffffffffc02006e2 <dtb_init+0x130>
ffffffffc02006d8:	4301                	li	t1,0
ffffffffc02006da:	b7d1                	j	ffffffffc020069e <dtb_init+0xec>
ffffffffc02006dc:	4711                	li	a4,4
ffffffffc02006de:	fce780e3          	beq	a5,a4,ffffffffc020069e <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e2:	00005517          	auipc	a0,0x5
ffffffffc02006e6:	5b650513          	addi	a0,a0,1462 # ffffffffc0205c98 <etext+0x3d6>
ffffffffc02006ea:	aafff0ef          	jal	ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006ee:	64e2                	ld	s1,24(sp)
ffffffffc02006f0:	6942                	ld	s2,16(sp)
ffffffffc02006f2:	00005517          	auipc	a0,0x5
ffffffffc02006f6:	5de50513          	addi	a0,a0,1502 # ffffffffc0205cd0 <etext+0x40e>
}
ffffffffc02006fa:	7402                	ld	s0,32(sp)
ffffffffc02006fc:	70a2                	ld	ra,40(sp)
ffffffffc02006fe:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200700:	bc61                	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200702:	7402                	ld	s0,32(sp)
ffffffffc0200704:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	4ea50513          	addi	a0,a0,1258 # ffffffffc0205bf0 <etext+0x32e>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200710:	b461                	j	ffffffffc0200198 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200712:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200718:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200724:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200728:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072c:	8ed1                	or	a3,a3,a2
ffffffffc020072e:	0ff77713          	zext.b	a4,a4
ffffffffc0200732:	8fd5                	or	a5,a5,a3
ffffffffc0200734:	0722                	slli	a4,a4,0x8
ffffffffc0200736:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200738:	04031463          	bnez	t1,ffffffffc0200780 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020073c:	1782                	slli	a5,a5,0x20
ffffffffc020073e:	9381                	srli	a5,a5,0x20
ffffffffc0200740:	043d                	addi	s0,s0,15
ffffffffc0200742:	943e                	add	s0,s0,a5
ffffffffc0200744:	9871                	andi	s0,s0,-4
                break;
ffffffffc0200746:	bfa1                	j	ffffffffc020069e <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc0200748:	8522                	mv	a0,s0
ffffffffc020074a:	e01a                	sd	t1,0(sp)
ffffffffc020074c:	098050ef          	jal	ffffffffc02057e4 <strlen>
ffffffffc0200750:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200752:	4619                	li	a2,6
ffffffffc0200754:	8522                	mv	a0,s0
ffffffffc0200756:	00005597          	auipc	a1,0x5
ffffffffc020075a:	4c258593          	addi	a1,a1,1218 # ffffffffc0205c18 <etext+0x356>
ffffffffc020075e:	100050ef          	jal	ffffffffc020585e <strncmp>
ffffffffc0200762:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200764:	0411                	addi	s0,s0,4
ffffffffc0200766:	0004879b          	sext.w	a5,s1
ffffffffc020076a:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020076c:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200770:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00a36333          	or	t1,t1,a0
                break;
ffffffffc0200776:	00ff0837          	lui	a6,0xff0
ffffffffc020077a:	488d                	li	a7,3
ffffffffc020077c:	4e05                	li	t3,1
ffffffffc020077e:	b705                	j	ffffffffc020069e <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200780:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200782:	00005597          	auipc	a1,0x5
ffffffffc0200786:	49e58593          	addi	a1,a1,1182 # ffffffffc0205c20 <etext+0x35e>
ffffffffc020078a:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200794:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200798:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079c:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a0:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a4:	8ed1                	or	a3,a3,a2
ffffffffc02007a6:	0ff77713          	zext.b	a4,a4
ffffffffc02007aa:	0722                	slli	a4,a4,0x8
ffffffffc02007ac:	8d55                	or	a0,a0,a3
ffffffffc02007ae:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b0:	1502                	slli	a0,a0,0x20
ffffffffc02007b2:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007b4:	954a                	add	a0,a0,s2
ffffffffc02007b6:	e01a                	sd	t1,0(sp)
ffffffffc02007b8:	072050ef          	jal	ffffffffc020582a <strcmp>
ffffffffc02007bc:	67a2                	ld	a5,8(sp)
ffffffffc02007be:	473d                	li	a4,15
ffffffffc02007c0:	6302                	ld	t1,0(sp)
ffffffffc02007c2:	00ff0837          	lui	a6,0xff0
ffffffffc02007c6:	488d                	li	a7,3
ffffffffc02007c8:	4e05                	li	t3,1
ffffffffc02007ca:	f6f779e3          	bgeu	a4,a5,ffffffffc020073c <dtb_init+0x18a>
ffffffffc02007ce:	f53d                	bnez	a0,ffffffffc020073c <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d0:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007d4:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	45050513          	addi	a0,a0,1104 # ffffffffc0205c28 <etext+0x366>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e0:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e4:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007e8:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007ec:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f0:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007f8:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	01037333          	and	t1,t1,a6
ffffffffc020080c:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200814:	0ff7f793          	zext.b	a5,a5
ffffffffc0200818:	01de6e33          	or	t3,t3,t4
ffffffffc020081c:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200820:	01067633          	and	a2,a2,a6
ffffffffc0200824:	0086d31b          	srliw	t1,a3,0x8
ffffffffc0200828:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020082c:	07a2                	slli	a5,a5,0x8
ffffffffc020082e:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200832:	0186df1b          	srliw	t5,a3,0x18
ffffffffc0200836:	01875e9b          	srliw	t4,a4,0x18
ffffffffc020083a:	8ddd                	or	a1,a1,a5
ffffffffc020083c:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200840:	0186979b          	slliw	a5,a3,0x18
ffffffffc0200844:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200848:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200850:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200854:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200858:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085c:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200860:	08a2                	slli	a7,a7,0x8
ffffffffc0200862:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200866:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020086a:	0ff6f693          	zext.b	a3,a3
ffffffffc020086e:	01de6833          	or	a6,t3,t4
ffffffffc0200872:	0ff77713          	zext.b	a4,a4
ffffffffc0200876:	01166633          	or	a2,a2,a7
ffffffffc020087a:	0067e7b3          	or	a5,a5,t1
ffffffffc020087e:	06a2                	slli	a3,a3,0x8
ffffffffc0200880:	01046433          	or	s0,s0,a6
ffffffffc0200884:	0722                	slli	a4,a4,0x8
ffffffffc0200886:	8fd5                	or	a5,a5,a3
ffffffffc0200888:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	1582                	slli	a1,a1,0x20
ffffffffc020088c:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020088e:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	9201                	srli	a2,a2,0x20
ffffffffc0200892:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1402                	slli	s0,s0,0x20
ffffffffc0200896:	00b7e4b3          	or	s1,a5,a1
ffffffffc020089a:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc020089c:	8fdff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a0:	85a6                	mv	a1,s1
ffffffffc02008a2:	00005517          	auipc	a0,0x5
ffffffffc02008a6:	3a650513          	addi	a0,a0,934 # ffffffffc0205c48 <etext+0x386>
ffffffffc02008aa:	8efff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008ae:	01445613          	srli	a2,s0,0x14
ffffffffc02008b2:	85a2                	mv	a1,s0
ffffffffc02008b4:	00005517          	auipc	a0,0x5
ffffffffc02008b8:	3ac50513          	addi	a0,a0,940 # ffffffffc0205c60 <etext+0x39e>
ffffffffc02008bc:	8ddff0ef          	jal	ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c0:	009405b3          	add	a1,s0,s1
ffffffffc02008c4:	15fd                	addi	a1,a1,-1
ffffffffc02008c6:	00005517          	auipc	a0,0x5
ffffffffc02008ca:	3ba50513          	addi	a0,a0,954 # ffffffffc0205c80 <etext+0x3be>
ffffffffc02008ce:	8cbff0ef          	jal	ffffffffc0200198 <cprintf>
        memory_base = mem_base;
ffffffffc02008d2:	000b5797          	auipc	a5,0xb5
ffffffffc02008d6:	e297b323          	sd	s1,-474(a5) # ffffffffc02b56f8 <memory_base>
        memory_size = mem_size;
ffffffffc02008da:	000b5797          	auipc	a5,0xb5
ffffffffc02008de:	e087bb23          	sd	s0,-490(a5) # ffffffffc02b56f0 <memory_size>
ffffffffc02008e2:	b531                	j	ffffffffc02006ee <dtb_init+0x13c>

ffffffffc02008e4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008e4:	000b5517          	auipc	a0,0xb5
ffffffffc02008e8:	e1453503          	ld	a0,-492(a0) # ffffffffc02b56f8 <memory_base>
ffffffffc02008ec:	8082                	ret

ffffffffc02008ee <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008ee:	000b5517          	auipc	a0,0xb5
ffffffffc02008f2:	e0253503          	ld	a0,-510(a0) # ffffffffc02b56f0 <memory_size>
ffffffffc02008f6:	8082                	ret

ffffffffc02008f8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008f8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200904:	8082                	ret

ffffffffc0200906 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200906:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020090a:	00000797          	auipc	a5,0x0
ffffffffc020090e:	4ae78793          	addi	a5,a5,1198 # ffffffffc0200db8 <__alltraps>
ffffffffc0200912:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200916:	000407b7          	lui	a5,0x40
ffffffffc020091a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200920:	610c                	ld	a1,0(a0)
{
ffffffffc0200922:	1141                	addi	sp,sp,-16
ffffffffc0200924:	e022                	sd	s0,0(sp)
ffffffffc0200926:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200928:	00005517          	auipc	a0,0x5
ffffffffc020092c:	3c050513          	addi	a0,a0,960 # ffffffffc0205ce8 <etext+0x426>
{
ffffffffc0200930:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200932:	867ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200936:	640c                	ld	a1,8(s0)
ffffffffc0200938:	00005517          	auipc	a0,0x5
ffffffffc020093c:	3c850513          	addi	a0,a0,968 # ffffffffc0205d00 <etext+0x43e>
ffffffffc0200940:	859ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200944:	680c                	ld	a1,16(s0)
ffffffffc0200946:	00005517          	auipc	a0,0x5
ffffffffc020094a:	3d250513          	addi	a0,a0,978 # ffffffffc0205d18 <etext+0x456>
ffffffffc020094e:	84bff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200952:	6c0c                	ld	a1,24(s0)
ffffffffc0200954:	00005517          	auipc	a0,0x5
ffffffffc0200958:	3dc50513          	addi	a0,a0,988 # ffffffffc0205d30 <etext+0x46e>
ffffffffc020095c:	83dff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200960:	700c                	ld	a1,32(s0)
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	3e650513          	addi	a0,a0,998 # ffffffffc0205d48 <etext+0x486>
ffffffffc020096a:	82fff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020096e:	740c                	ld	a1,40(s0)
ffffffffc0200970:	00005517          	auipc	a0,0x5
ffffffffc0200974:	3f050513          	addi	a0,a0,1008 # ffffffffc0205d60 <etext+0x49e>
ffffffffc0200978:	821ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020097c:	780c                	ld	a1,48(s0)
ffffffffc020097e:	00005517          	auipc	a0,0x5
ffffffffc0200982:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205d78 <etext+0x4b6>
ffffffffc0200986:	813ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020098a:	7c0c                	ld	a1,56(s0)
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	40450513          	addi	a0,a0,1028 # ffffffffc0205d90 <etext+0x4ce>
ffffffffc0200994:	805ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200998:	602c                	ld	a1,64(s0)
ffffffffc020099a:	00005517          	auipc	a0,0x5
ffffffffc020099e:	40e50513          	addi	a0,a0,1038 # ffffffffc0205da8 <etext+0x4e6>
ffffffffc02009a2:	ff6ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009a6:	642c                	ld	a1,72(s0)
ffffffffc02009a8:	00005517          	auipc	a0,0x5
ffffffffc02009ac:	41850513          	addi	a0,a0,1048 # ffffffffc0205dc0 <etext+0x4fe>
ffffffffc02009b0:	fe8ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009b4:	682c                	ld	a1,80(s0)
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	42250513          	addi	a0,a0,1058 # ffffffffc0205dd8 <etext+0x516>
ffffffffc02009be:	fdaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c2:	6c2c                	ld	a1,88(s0)
ffffffffc02009c4:	00005517          	auipc	a0,0x5
ffffffffc02009c8:	42c50513          	addi	a0,a0,1068 # ffffffffc0205df0 <etext+0x52e>
ffffffffc02009cc:	fccff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d0:	702c                	ld	a1,96(s0)
ffffffffc02009d2:	00005517          	auipc	a0,0x5
ffffffffc02009d6:	43650513          	addi	a0,a0,1078 # ffffffffc0205e08 <etext+0x546>
ffffffffc02009da:	fbeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009de:	742c                	ld	a1,104(s0)
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	44050513          	addi	a0,a0,1088 # ffffffffc0205e20 <etext+0x55e>
ffffffffc02009e8:	fb0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009ec:	782c                	ld	a1,112(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	44a50513          	addi	a0,a0,1098 # ffffffffc0205e38 <etext+0x576>
ffffffffc02009f6:	fa2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02009fa:	7c2c                	ld	a1,120(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	45450513          	addi	a0,a0,1108 # ffffffffc0205e50 <etext+0x58e>
ffffffffc0200a04:	f94ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a08:	604c                	ld	a1,128(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	45e50513          	addi	a0,a0,1118 # ffffffffc0205e68 <etext+0x5a6>
ffffffffc0200a12:	f86ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a16:	644c                	ld	a1,136(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	46850513          	addi	a0,a0,1128 # ffffffffc0205e80 <etext+0x5be>
ffffffffc0200a20:	f78ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a24:	684c                	ld	a1,144(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	47250513          	addi	a0,a0,1138 # ffffffffc0205e98 <etext+0x5d6>
ffffffffc0200a2e:	f6aff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a32:	6c4c                	ld	a1,152(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	47c50513          	addi	a0,a0,1148 # ffffffffc0205eb0 <etext+0x5ee>
ffffffffc0200a3c:	f5cff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a40:	704c                	ld	a1,160(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	48650513          	addi	a0,a0,1158 # ffffffffc0205ec8 <etext+0x606>
ffffffffc0200a4a:	f4eff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a4e:	744c                	ld	a1,168(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	49050513          	addi	a0,a0,1168 # ffffffffc0205ee0 <etext+0x61e>
ffffffffc0200a58:	f40ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a5c:	784c                	ld	a1,176(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	49a50513          	addi	a0,a0,1178 # ffffffffc0205ef8 <etext+0x636>
ffffffffc0200a66:	f32ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a6a:	7c4c                	ld	a1,184(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	4a450513          	addi	a0,a0,1188 # ffffffffc0205f10 <etext+0x64e>
ffffffffc0200a74:	f24ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a78:	606c                	ld	a1,192(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	4ae50513          	addi	a0,a0,1198 # ffffffffc0205f28 <etext+0x666>
ffffffffc0200a82:	f16ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a86:	646c                	ld	a1,200(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	4b850513          	addi	a0,a0,1208 # ffffffffc0205f40 <etext+0x67e>
ffffffffc0200a90:	f08ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a94:	686c                	ld	a1,208(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	4c250513          	addi	a0,a0,1218 # ffffffffc0205f58 <etext+0x696>
ffffffffc0200a9e:	efaff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa2:	6c6c                	ld	a1,216(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	4cc50513          	addi	a0,a0,1228 # ffffffffc0205f70 <etext+0x6ae>
ffffffffc0200aac:	eecff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab0:	706c                	ld	a1,224(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	4d650513          	addi	a0,a0,1238 # ffffffffc0205f88 <etext+0x6c6>
ffffffffc0200aba:	edeff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200abe:	746c                	ld	a1,232(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	4e050513          	addi	a0,a0,1248 # ffffffffc0205fa0 <etext+0x6de>
ffffffffc0200ac8:	ed0ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200acc:	786c                	ld	a1,240(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	4ea50513          	addi	a0,a0,1258 # ffffffffc0205fb8 <etext+0x6f6>
ffffffffc0200ad6:	ec2ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ada:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200adc:	6402                	ld	s0,0(sp)
ffffffffc0200ade:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	00005517          	auipc	a0,0x5
ffffffffc0200ae4:	4f050513          	addi	a0,a0,1264 # ffffffffc0205fd0 <etext+0x70e>
}
ffffffffc0200ae8:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200aea:	eaeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200aee <print_trapframe>:
{
ffffffffc0200aee:	1141                	addi	sp,sp,-16
ffffffffc0200af0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af2:	85aa                	mv	a1,a0
{
ffffffffc0200af4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af6:	00005517          	auipc	a0,0x5
ffffffffc0200afa:	4f250513          	addi	a0,a0,1266 # ffffffffc0205fe8 <etext+0x726>
{
ffffffffc0200afe:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b00:	e98ff0ef          	jal	ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b04:	8522                	mv	a0,s0
ffffffffc0200b06:	e1bff0ef          	jal	ffffffffc0200920 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b0a:	10043583          	ld	a1,256(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	4f250513          	addi	a0,a0,1266 # ffffffffc0206000 <etext+0x73e>
ffffffffc0200b16:	e82ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b1a:	10843583          	ld	a1,264(s0)
ffffffffc0200b1e:	00005517          	auipc	a0,0x5
ffffffffc0200b22:	4fa50513          	addi	a0,a0,1274 # ffffffffc0206018 <etext+0x756>
ffffffffc0200b26:	e72ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b2a:	11043583          	ld	a1,272(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	50250513          	addi	a0,a0,1282 # ffffffffc0206030 <etext+0x76e>
ffffffffc0200b36:	e62ff0ef          	jal	ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b3a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b3e:	6402                	ld	s0,0(sp)
ffffffffc0200b40:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b42:	00005517          	auipc	a0,0x5
ffffffffc0200b46:	4fe50513          	addi	a0,a0,1278 # ffffffffc0206040 <etext+0x77e>
}
ffffffffc0200b4a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b4c:	e4cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b50 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b50:	11853783          	ld	a5,280(a0)
ffffffffc0200b54:	472d                	li	a4,11
ffffffffc0200b56:	0786                	slli	a5,a5,0x1
ffffffffc0200b58:	8385                	srli	a5,a5,0x1
ffffffffc0200b5a:	0af76a63          	bltu	a4,a5,ffffffffc0200c0e <interrupt_handler+0xbe>
ffffffffc0200b5e:	00007717          	auipc	a4,0x7
ffffffffc0200b62:	b1270713          	addi	a4,a4,-1262 # ffffffffc0207670 <commands+0x48>
ffffffffc0200b66:	078a                	slli	a5,a5,0x2
ffffffffc0200b68:	97ba                	add	a5,a5,a4
ffffffffc0200b6a:	439c                	lw	a5,0(a5)
ffffffffc0200b6c:	97ba                	add	a5,a5,a4
ffffffffc0200b6e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	54850513          	addi	a0,a0,1352 # ffffffffc02060b8 <etext+0x7f6>
ffffffffc0200b78:	e20ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b7c:	00005517          	auipc	a0,0x5
ffffffffc0200b80:	51c50513          	addi	a0,a0,1308 # ffffffffc0206098 <etext+0x7d6>
ffffffffc0200b84:	e14ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	4d050513          	addi	a0,a0,1232 # ffffffffc0206058 <etext+0x796>
ffffffffc0200b90:	e08ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	4e450513          	addi	a0,a0,1252 # ffffffffc0206078 <etext+0x7b6>
ffffffffc0200b9c:	dfcff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200ba0:	1141                	addi	sp,sp,-16
ffffffffc0200ba2:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event();
ffffffffc0200ba4:	985ff0ef          	jal	ffffffffc0200528 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200ba8:	000b5697          	auipc	a3,0xb5
ffffffffc0200bac:	b406b683          	ld	a3,-1216(a3) # ffffffffc02b56e8 <ticks>
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bb0:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bb4:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_matrix_out_size+0x28f50d4f>
ffffffffc0200bb8:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200bbc:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <_binary_obj___user_matrix_out_size+0x5c284083>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200bc0:	0685                	addi	a3,a3,1
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bc2:	1702                	slli	a4,a4,0x20
ffffffffc0200bc4:	973e                	add	a4,a4,a5
ffffffffc0200bc6:	0026d793          	srli	a5,a3,0x2
ffffffffc0200bca:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bce:	06400713          	li	a4,100
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200bd2:	000b5617          	auipc	a2,0xb5
ffffffffc0200bd6:	b0d63b23          	sd	a3,-1258(a2) # ffffffffc02b56e8 <ticks>
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bda:	000b5517          	auipc	a0,0xb5
ffffffffc0200bde:	b6653503          	ld	a0,-1178(a0) # ffffffffc02b5740 <current>
ffffffffc0200be2:	8389                	srli	a5,a5,0x2
ffffffffc0200be4:	02e787b3          	mul	a5,a5,a4
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200be8:	00f69963          	bne	a3,a5,ffffffffc0200bfa <interrupt_handler+0xaa>
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bec:	c519                	beqz	a0,ffffffffc0200bfa <interrupt_handler+0xaa>
ffffffffc0200bee:	4118                	lw	a4,0(a0)
ffffffffc0200bf0:	4789                	li	a5,2
ffffffffc0200bf2:	00f71463          	bne	a4,a5,ffffffffc0200bfa <interrupt_handler+0xaa>
                current->need_resched = 1;
ffffffffc0200bf6:	4785                	li	a5,1
ffffffffc0200bf8:	ed1c                	sd	a5,24(a0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bfa:	60a2                	ld	ra,8(sp)
ffffffffc0200bfc:	0141                	addi	sp,sp,16
        sched_class_proc_tick(current);
ffffffffc0200bfe:	4de0406f          	j	ffffffffc02050dc <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c02:	00005517          	auipc	a0,0x5
ffffffffc0200c06:	4d650513          	addi	a0,a0,1238 # ffffffffc02060d8 <etext+0x816>
ffffffffc0200c0a:	d8eff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c0e:	b5c5                	j	ffffffffc0200aee <print_trapframe>

ffffffffc0200c10 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c10:	11853783          	ld	a5,280(a0)
ffffffffc0200c14:	473d                	li	a4,15
ffffffffc0200c16:	10f76e63          	bltu	a4,a5,ffffffffc0200d32 <exception_handler+0x122>
ffffffffc0200c1a:	00007717          	auipc	a4,0x7
ffffffffc0200c1e:	a8670713          	addi	a4,a4,-1402 # ffffffffc02076a0 <commands+0x78>
ffffffffc0200c22:	078a                	slli	a5,a5,0x2
ffffffffc0200c24:	97ba                	add	a5,a5,a4
ffffffffc0200c26:	439c                	lw	a5,0(a5)
{
ffffffffc0200c28:	1101                	addi	sp,sp,-32
ffffffffc0200c2a:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c2c:	97ba                	add	a5,a5,a4
ffffffffc0200c2e:	86aa                	mv	a3,a0
ffffffffc0200c30:	8782                	jr	a5
ffffffffc0200c32:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c34:	00005517          	auipc	a0,0x5
ffffffffc0200c38:	5ac50513          	addi	a0,a0,1452 # ffffffffc02061e0 <etext+0x91e>
ffffffffc0200c3c:	d5cff0ef          	jal	ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200c40:	66a2                	ld	a3,8(sp)
ffffffffc0200c42:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c46:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c48:	0791                	addi	a5,a5,4
ffffffffc0200c4a:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c4e:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c50:	7340406f          	j	ffffffffc0205384 <syscall>
}
ffffffffc0200c54:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c56:	00005517          	auipc	a0,0x5
ffffffffc0200c5a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0206200 <etext+0x93e>
}
ffffffffc0200c5e:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c60:	d38ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c64:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c66:	00005517          	auipc	a0,0x5
ffffffffc0200c6a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206220 <etext+0x95e>
}
ffffffffc0200c6e:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c70:	d28ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c74:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c76:	00005517          	auipc	a0,0x5
ffffffffc0200c7a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206240 <etext+0x97e>
}
ffffffffc0200c7e:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c80:	d18ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c84:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c86:	00005517          	auipc	a0,0x5
ffffffffc0200c8a:	5d250513          	addi	a0,a0,1490 # ffffffffc0206258 <etext+0x996>
}
ffffffffc0200c8e:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c90:	d08ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c96:	00005517          	auipc	a0,0x5
ffffffffc0200c9a:	5da50513          	addi	a0,a0,1498 # ffffffffc0206270 <etext+0x9ae>
}
ffffffffc0200c9e:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca0:	cf8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200ca4:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200ca6:	00005517          	auipc	a0,0x5
ffffffffc0200caa:	45250513          	addi	a0,a0,1106 # ffffffffc02060f8 <etext+0x836>
}
ffffffffc0200cae:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb0:	ce8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cb4:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cb6:	00005517          	auipc	a0,0x5
ffffffffc0200cba:	46250513          	addi	a0,a0,1122 # ffffffffc0206118 <etext+0x856>
}
ffffffffc0200cbe:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc0:	cd8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cc4:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cc6:	00005517          	auipc	a0,0x5
ffffffffc0200cca:	47250513          	addi	a0,a0,1138 # ffffffffc0206138 <etext+0x876>
}
ffffffffc0200cce:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cd0:	cc8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cd4:	60e2                	ld	ra,24(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cd6:	00005517          	auipc	a0,0x5
ffffffffc0200cda:	47a50513          	addi	a0,a0,1146 # ffffffffc0206150 <etext+0x88e>
}
ffffffffc0200cde:	6105                	addi	sp,sp,32
        cprintf("Breakpoint\n");
ffffffffc0200ce0:	cb8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200ce4:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200ce6:	00005517          	auipc	a0,0x5
ffffffffc0200cea:	47a50513          	addi	a0,a0,1146 # ffffffffc0206160 <etext+0x89e>
}
ffffffffc0200cee:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200cf0:	ca8ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200cf4:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200cf6:	00005517          	auipc	a0,0x5
ffffffffc0200cfa:	48a50513          	addi	a0,a0,1162 # ffffffffc0206180 <etext+0x8be>
}
ffffffffc0200cfe:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d00:	c98ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d04:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d06:	00005517          	auipc	a0,0x5
ffffffffc0200d0a:	4c250513          	addi	a0,a0,1218 # ffffffffc02061c8 <etext+0x906>
}
ffffffffc0200d0e:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d10:	c88ff06f          	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200d14:	60e2                	ld	ra,24(sp)
ffffffffc0200d16:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d18:	bbd9                	j	ffffffffc0200aee <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d1a:	00005617          	auipc	a2,0x5
ffffffffc0200d1e:	47e60613          	addi	a2,a2,1150 # ffffffffc0206198 <etext+0x8d6>
ffffffffc0200d22:	0bf00593          	li	a1,191
ffffffffc0200d26:	00005517          	auipc	a0,0x5
ffffffffc0200d2a:	48a50513          	addi	a0,a0,1162 # ffffffffc02061b0 <etext+0x8ee>
ffffffffc0200d2e:	f1cff0ef          	jal	ffffffffc020044a <__panic>
        print_trapframe(tf);
ffffffffc0200d32:	bb75                	j	ffffffffc0200aee <print_trapframe>

ffffffffc0200d34 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d34:	000b5717          	auipc	a4,0xb5
ffffffffc0200d38:	a0c73703          	ld	a4,-1524(a4) # ffffffffc02b5740 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d3c:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d40:	cf21                	beqz	a4,ffffffffc0200d98 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d42:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d46:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d4a:	1101                	addi	sp,sp,-32
ffffffffc0200d4c:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d4e:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d52:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d54:	e432                	sd	a2,8(sp)
ffffffffc0200d56:	e042                	sd	a6,0(sp)
ffffffffc0200d58:	0205c763          	bltz	a1,ffffffffc0200d86 <trap+0x52>
        exception_handler(tf);
ffffffffc0200d5c:	eb5ff0ef          	jal	ffffffffc0200c10 <exception_handler>
ffffffffc0200d60:	6622                	ld	a2,8(sp)
ffffffffc0200d62:	6802                	ld	a6,0(sp)
ffffffffc0200d64:	000b5697          	auipc	a3,0xb5
ffffffffc0200d68:	9dc68693          	addi	a3,a3,-1572 # ffffffffc02b5740 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d6c:	6298                	ld	a4,0(a3)
ffffffffc0200d6e:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200d72:	e619                	bnez	a2,ffffffffc0200d80 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d74:	0b072783          	lw	a5,176(a4)
ffffffffc0200d78:	8b85                	andi	a5,a5,1
ffffffffc0200d7a:	e79d                	bnez	a5,ffffffffc0200da8 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200d7c:	6f1c                	ld	a5,24(a4)
ffffffffc0200d7e:	e38d                	bnez	a5,ffffffffc0200da0 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200d80:	60e2                	ld	ra,24(sp)
ffffffffc0200d82:	6105                	addi	sp,sp,32
ffffffffc0200d84:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200d86:	dcbff0ef          	jal	ffffffffc0200b50 <interrupt_handler>
ffffffffc0200d8a:	6802                	ld	a6,0(sp)
ffffffffc0200d8c:	6622                	ld	a2,8(sp)
ffffffffc0200d8e:	000b5697          	auipc	a3,0xb5
ffffffffc0200d92:	9b268693          	addi	a3,a3,-1614 # ffffffffc02b5740 <current>
ffffffffc0200d96:	bfd9                	j	ffffffffc0200d6c <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d98:	0005c363          	bltz	a1,ffffffffc0200d9e <trap+0x6a>
        exception_handler(tf);
ffffffffc0200d9c:	bd95                	j	ffffffffc0200c10 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d9e:	bb4d                	j	ffffffffc0200b50 <interrupt_handler>
}
ffffffffc0200da0:	60e2                	ld	ra,24(sp)
ffffffffc0200da2:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200da4:	4ac0406f          	j	ffffffffc0205250 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200da8:	555d                	li	a0,-9
ffffffffc0200daa:	528030ef          	jal	ffffffffc02042d2 <do_exit>
            if (current->need_resched)
ffffffffc0200dae:	000b5717          	auipc	a4,0xb5
ffffffffc0200db2:	99273703          	ld	a4,-1646(a4) # ffffffffc02b5740 <current>
ffffffffc0200db6:	b7d9                	j	ffffffffc0200d7c <trap+0x48>

ffffffffc0200db8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200db8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200dbc:	00011463          	bnez	sp,ffffffffc0200dc4 <__alltraps+0xc>
ffffffffc0200dc0:	14002173          	csrr	sp,sscratch
ffffffffc0200dc4:	712d                	addi	sp,sp,-288
ffffffffc0200dc6:	e002                	sd	zero,0(sp)
ffffffffc0200dc8:	e406                	sd	ra,8(sp)
ffffffffc0200dca:	ec0e                	sd	gp,24(sp)
ffffffffc0200dcc:	f012                	sd	tp,32(sp)
ffffffffc0200dce:	f416                	sd	t0,40(sp)
ffffffffc0200dd0:	f81a                	sd	t1,48(sp)
ffffffffc0200dd2:	fc1e                	sd	t2,56(sp)
ffffffffc0200dd4:	e0a2                	sd	s0,64(sp)
ffffffffc0200dd6:	e4a6                	sd	s1,72(sp)
ffffffffc0200dd8:	e8aa                	sd	a0,80(sp)
ffffffffc0200dda:	ecae                	sd	a1,88(sp)
ffffffffc0200ddc:	f0b2                	sd	a2,96(sp)
ffffffffc0200dde:	f4b6                	sd	a3,104(sp)
ffffffffc0200de0:	f8ba                	sd	a4,112(sp)
ffffffffc0200de2:	fcbe                	sd	a5,120(sp)
ffffffffc0200de4:	e142                	sd	a6,128(sp)
ffffffffc0200de6:	e546                	sd	a7,136(sp)
ffffffffc0200de8:	e94a                	sd	s2,144(sp)
ffffffffc0200dea:	ed4e                	sd	s3,152(sp)
ffffffffc0200dec:	f152                	sd	s4,160(sp)
ffffffffc0200dee:	f556                	sd	s5,168(sp)
ffffffffc0200df0:	f95a                	sd	s6,176(sp)
ffffffffc0200df2:	fd5e                	sd	s7,184(sp)
ffffffffc0200df4:	e1e2                	sd	s8,192(sp)
ffffffffc0200df6:	e5e6                	sd	s9,200(sp)
ffffffffc0200df8:	e9ea                	sd	s10,208(sp)
ffffffffc0200dfa:	edee                	sd	s11,216(sp)
ffffffffc0200dfc:	f1f2                	sd	t3,224(sp)
ffffffffc0200dfe:	f5f6                	sd	t4,232(sp)
ffffffffc0200e00:	f9fa                	sd	t5,240(sp)
ffffffffc0200e02:	fdfe                	sd	t6,248(sp)
ffffffffc0200e04:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e08:	100024f3          	csrr	s1,sstatus
ffffffffc0200e0c:	14102973          	csrr	s2,sepc
ffffffffc0200e10:	143029f3          	csrr	s3,stval
ffffffffc0200e14:	14202a73          	csrr	s4,scause
ffffffffc0200e18:	e822                	sd	s0,16(sp)
ffffffffc0200e1a:	e226                	sd	s1,256(sp)
ffffffffc0200e1c:	e64a                	sd	s2,264(sp)
ffffffffc0200e1e:	ea4e                	sd	s3,272(sp)
ffffffffc0200e20:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e22:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e24:	f11ff0ef          	jal	ffffffffc0200d34 <trap>

ffffffffc0200e28 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e28:	6492                	ld	s1,256(sp)
ffffffffc0200e2a:	6932                	ld	s2,264(sp)
ffffffffc0200e2c:	1004f413          	andi	s0,s1,256
ffffffffc0200e30:	e401                	bnez	s0,ffffffffc0200e38 <__trapret+0x10>
ffffffffc0200e32:	1200                	addi	s0,sp,288
ffffffffc0200e34:	14041073          	csrw	sscratch,s0
ffffffffc0200e38:	10049073          	csrw	sstatus,s1
ffffffffc0200e3c:	14191073          	csrw	sepc,s2
ffffffffc0200e40:	60a2                	ld	ra,8(sp)
ffffffffc0200e42:	61e2                	ld	gp,24(sp)
ffffffffc0200e44:	7202                	ld	tp,32(sp)
ffffffffc0200e46:	72a2                	ld	t0,40(sp)
ffffffffc0200e48:	7342                	ld	t1,48(sp)
ffffffffc0200e4a:	73e2                	ld	t2,56(sp)
ffffffffc0200e4c:	6406                	ld	s0,64(sp)
ffffffffc0200e4e:	64a6                	ld	s1,72(sp)
ffffffffc0200e50:	6546                	ld	a0,80(sp)
ffffffffc0200e52:	65e6                	ld	a1,88(sp)
ffffffffc0200e54:	7606                	ld	a2,96(sp)
ffffffffc0200e56:	76a6                	ld	a3,104(sp)
ffffffffc0200e58:	7746                	ld	a4,112(sp)
ffffffffc0200e5a:	77e6                	ld	a5,120(sp)
ffffffffc0200e5c:	680a                	ld	a6,128(sp)
ffffffffc0200e5e:	68aa                	ld	a7,136(sp)
ffffffffc0200e60:	694a                	ld	s2,144(sp)
ffffffffc0200e62:	69ea                	ld	s3,152(sp)
ffffffffc0200e64:	7a0a                	ld	s4,160(sp)
ffffffffc0200e66:	7aaa                	ld	s5,168(sp)
ffffffffc0200e68:	7b4a                	ld	s6,176(sp)
ffffffffc0200e6a:	7bea                	ld	s7,184(sp)
ffffffffc0200e6c:	6c0e                	ld	s8,192(sp)
ffffffffc0200e6e:	6cae                	ld	s9,200(sp)
ffffffffc0200e70:	6d4e                	ld	s10,208(sp)
ffffffffc0200e72:	6dee                	ld	s11,216(sp)
ffffffffc0200e74:	7e0e                	ld	t3,224(sp)
ffffffffc0200e76:	7eae                	ld	t4,232(sp)
ffffffffc0200e78:	7f4e                	ld	t5,240(sp)
ffffffffc0200e7a:	7fee                	ld	t6,248(sp)
ffffffffc0200e7c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e7e:	10200073          	sret

ffffffffc0200e82 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200e82:	812a                	mv	sp,a0
ffffffffc0200e84:	b755                	j	ffffffffc0200e28 <__trapret>

ffffffffc0200e86 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e86:	000b1797          	auipc	a5,0xb1
ffffffffc0200e8a:	80278793          	addi	a5,a5,-2046 # ffffffffc02b1688 <free_area>
ffffffffc0200e8e:	e79c                	sd	a5,8(a5)
ffffffffc0200e90:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e92:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e96:	8082                	ret

ffffffffc0200e98 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200e98:	000b1517          	auipc	a0,0xb1
ffffffffc0200e9c:	80056503          	lwu	a0,-2048(a0) # ffffffffc02b1698 <free_area+0x10>
ffffffffc0200ea0:	8082                	ret

ffffffffc0200ea2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ea2:	711d                	addi	sp,sp,-96
ffffffffc0200ea4:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ea6:	000b0917          	auipc	s2,0xb0
ffffffffc0200eaa:	7e290913          	addi	s2,s2,2018 # ffffffffc02b1688 <free_area>
ffffffffc0200eae:	00893783          	ld	a5,8(s2)
ffffffffc0200eb2:	ec86                	sd	ra,88(sp)
ffffffffc0200eb4:	e8a2                	sd	s0,80(sp)
ffffffffc0200eb6:	e4a6                	sd	s1,72(sp)
ffffffffc0200eb8:	fc4e                	sd	s3,56(sp)
ffffffffc0200eba:	f852                	sd	s4,48(sp)
ffffffffc0200ebc:	f456                	sd	s5,40(sp)
ffffffffc0200ebe:	f05a                	sd	s6,32(sp)
ffffffffc0200ec0:	ec5e                	sd	s7,24(sp)
ffffffffc0200ec2:	e862                	sd	s8,16(sp)
ffffffffc0200ec4:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ec6:	2f278363          	beq	a5,s2,ffffffffc02011ac <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200eca:	4401                	li	s0,0
ffffffffc0200ecc:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ece:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ed2:	8b09                	andi	a4,a4,2
ffffffffc0200ed4:	2e070063          	beqz	a4,ffffffffc02011b4 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200ed8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200edc:	679c                	ld	a5,8(a5)
ffffffffc0200ede:	2485                	addiw	s1,s1,1
ffffffffc0200ee0:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ee2:	ff2796e3          	bne	a5,s2,ffffffffc0200ece <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200ee6:	89a2                	mv	s3,s0
ffffffffc0200ee8:	741000ef          	jal	ffffffffc0201e28 <nr_free_pages>
ffffffffc0200eec:	73351463          	bne	a0,s3,ffffffffc0201614 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ef0:	4505                	li	a0,1
ffffffffc0200ef2:	6c5000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200ef6:	8a2a                	mv	s4,a0
ffffffffc0200ef8:	44050e63          	beqz	a0,ffffffffc0201354 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200efc:	4505                	li	a0,1
ffffffffc0200efe:	6b9000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200f02:	89aa                	mv	s3,a0
ffffffffc0200f04:	72050863          	beqz	a0,ffffffffc0201634 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f08:	4505                	li	a0,1
ffffffffc0200f0a:	6ad000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200f0e:	8aaa                	mv	s5,a0
ffffffffc0200f10:	4c050263          	beqz	a0,ffffffffc02013d4 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f14:	40a987b3          	sub	a5,s3,a0
ffffffffc0200f18:	40aa0733          	sub	a4,s4,a0
ffffffffc0200f1c:	0017b793          	seqz	a5,a5
ffffffffc0200f20:	00173713          	seqz	a4,a4
ffffffffc0200f24:	8fd9                	or	a5,a5,a4
ffffffffc0200f26:	30079763          	bnez	a5,ffffffffc0201234 <default_check+0x392>
ffffffffc0200f2a:	313a0563          	beq	s4,s3,ffffffffc0201234 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f2e:	000a2783          	lw	a5,0(s4)
ffffffffc0200f32:	2a079163          	bnez	a5,ffffffffc02011d4 <default_check+0x332>
ffffffffc0200f36:	0009a783          	lw	a5,0(s3)
ffffffffc0200f3a:	28079d63          	bnez	a5,ffffffffc02011d4 <default_check+0x332>
ffffffffc0200f3e:	411c                	lw	a5,0(a0)
ffffffffc0200f40:	28079a63          	bnez	a5,ffffffffc02011d4 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f44:	000b4797          	auipc	a5,0xb4
ffffffffc0200f48:	7ec7b783          	ld	a5,2028(a5) # ffffffffc02b5730 <pages>
ffffffffc0200f4c:	00007617          	auipc	a2,0x7
ffffffffc0200f50:	1ec63603          	ld	a2,492(a2) # ffffffffc0208138 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f54:	000b4697          	auipc	a3,0xb4
ffffffffc0200f58:	7d46b683          	ld	a3,2004(a3) # ffffffffc02b5728 <npage>
ffffffffc0200f5c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f60:	8719                	srai	a4,a4,0x6
ffffffffc0200f62:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f64:	0732                	slli	a4,a4,0xc
ffffffffc0200f66:	06b2                	slli	a3,a3,0xc
ffffffffc0200f68:	2ad77663          	bgeu	a4,a3,ffffffffc0201214 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0200f6c:	40f98733          	sub	a4,s3,a5
ffffffffc0200f70:	8719                	srai	a4,a4,0x6
ffffffffc0200f72:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f74:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f76:	4cd77f63          	bgeu	a4,a3,ffffffffc0201454 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0200f7a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f7e:	8799                	srai	a5,a5,0x6
ffffffffc0200f80:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f82:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f84:	32d7f863          	bgeu	a5,a3,ffffffffc02012b4 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0200f88:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f8a:	00093c03          	ld	s8,0(s2)
ffffffffc0200f8e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f92:	000b0b17          	auipc	s6,0xb0
ffffffffc0200f96:	706b2b03          	lw	s6,1798(s6) # ffffffffc02b1698 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200f9a:	01293023          	sd	s2,0(s2)
ffffffffc0200f9e:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200fa2:	000b0797          	auipc	a5,0xb0
ffffffffc0200fa6:	6e07ab23          	sw	zero,1782(a5) # ffffffffc02b1698 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200faa:	60d000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200fae:	2e051363          	bnez	a0,ffffffffc0201294 <default_check+0x3f2>
    free_page(p0);
ffffffffc0200fb2:	8552                	mv	a0,s4
ffffffffc0200fb4:	4585                	li	a1,1
ffffffffc0200fb6:	63b000ef          	jal	ffffffffc0201df0 <free_pages>
    free_page(p1);
ffffffffc0200fba:	854e                	mv	a0,s3
ffffffffc0200fbc:	4585                	li	a1,1
ffffffffc0200fbe:	633000ef          	jal	ffffffffc0201df0 <free_pages>
    free_page(p2);
ffffffffc0200fc2:	8556                	mv	a0,s5
ffffffffc0200fc4:	4585                	li	a1,1
ffffffffc0200fc6:	62b000ef          	jal	ffffffffc0201df0 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fca:	000b0717          	auipc	a4,0xb0
ffffffffc0200fce:	6ce72703          	lw	a4,1742(a4) # ffffffffc02b1698 <free_area+0x10>
ffffffffc0200fd2:	478d                	li	a5,3
ffffffffc0200fd4:	2af71063          	bne	a4,a5,ffffffffc0201274 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fd8:	4505                	li	a0,1
ffffffffc0200fda:	5dd000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200fde:	89aa                	mv	s3,a0
ffffffffc0200fe0:	26050a63          	beqz	a0,ffffffffc0201254 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fe4:	4505                	li	a0,1
ffffffffc0200fe6:	5d1000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200fea:	8aaa                	mv	s5,a0
ffffffffc0200fec:	3c050463          	beqz	a0,ffffffffc02013b4 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ff0:	4505                	li	a0,1
ffffffffc0200ff2:	5c5000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0200ff6:	8a2a                	mv	s4,a0
ffffffffc0200ff8:	38050e63          	beqz	a0,ffffffffc0201394 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0200ffc:	4505                	li	a0,1
ffffffffc0200ffe:	5b9000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201002:	36051963          	bnez	a0,ffffffffc0201374 <default_check+0x4d2>
    free_page(p0);
ffffffffc0201006:	4585                	li	a1,1
ffffffffc0201008:	854e                	mv	a0,s3
ffffffffc020100a:	5e7000ef          	jal	ffffffffc0201df0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020100e:	00893783          	ld	a5,8(s2)
ffffffffc0201012:	1f278163          	beq	a5,s2,ffffffffc02011f4 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc0201016:	4505                	li	a0,1
ffffffffc0201018:	59f000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc020101c:	8caa                	mv	s9,a0
ffffffffc020101e:	30a99b63          	bne	s3,a0,ffffffffc0201334 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc0201022:	4505                	li	a0,1
ffffffffc0201024:	593000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201028:	2e051663          	bnez	a0,ffffffffc0201314 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc020102c:	000b0797          	auipc	a5,0xb0
ffffffffc0201030:	66c7a783          	lw	a5,1644(a5) # ffffffffc02b1698 <free_area+0x10>
ffffffffc0201034:	2c079063          	bnez	a5,ffffffffc02012f4 <default_check+0x452>
    free_page(p);
ffffffffc0201038:	8566                	mv	a0,s9
ffffffffc020103a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020103c:	01893023          	sd	s8,0(s2)
ffffffffc0201040:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201044:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201048:	5a9000ef          	jal	ffffffffc0201df0 <free_pages>
    free_page(p1);
ffffffffc020104c:	8556                	mv	a0,s5
ffffffffc020104e:	4585                	li	a1,1
ffffffffc0201050:	5a1000ef          	jal	ffffffffc0201df0 <free_pages>
    free_page(p2);
ffffffffc0201054:	8552                	mv	a0,s4
ffffffffc0201056:	4585                	li	a1,1
ffffffffc0201058:	599000ef          	jal	ffffffffc0201df0 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020105c:	4515                	li	a0,5
ffffffffc020105e:	559000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201062:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201064:	26050863          	beqz	a0,ffffffffc02012d4 <default_check+0x432>
ffffffffc0201068:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc020106a:	8b89                	andi	a5,a5,2
ffffffffc020106c:	54079463          	bnez	a5,ffffffffc02015b4 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201070:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201072:	00093b83          	ld	s7,0(s2)
ffffffffc0201076:	00893b03          	ld	s6,8(s2)
ffffffffc020107a:	01293023          	sd	s2,0(s2)
ffffffffc020107e:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0201082:	535000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201086:	50051763          	bnez	a0,ffffffffc0201594 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020108a:	08098a13          	addi	s4,s3,128
ffffffffc020108e:	8552                	mv	a0,s4
ffffffffc0201090:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201092:	000b0c17          	auipc	s8,0xb0
ffffffffc0201096:	606c2c03          	lw	s8,1542(s8) # ffffffffc02b1698 <free_area+0x10>
    nr_free = 0;
ffffffffc020109a:	000b0797          	auipc	a5,0xb0
ffffffffc020109e:	5e07af23          	sw	zero,1534(a5) # ffffffffc02b1698 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010a2:	54f000ef          	jal	ffffffffc0201df0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010a6:	4511                	li	a0,4
ffffffffc02010a8:	50f000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc02010ac:	4c051463          	bnez	a0,ffffffffc0201574 <default_check+0x6d2>
ffffffffc02010b0:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010b4:	8b89                	andi	a5,a5,2
ffffffffc02010b6:	48078f63          	beqz	a5,ffffffffc0201554 <default_check+0x6b2>
ffffffffc02010ba:	0909a503          	lw	a0,144(s3)
ffffffffc02010be:	478d                	li	a5,3
ffffffffc02010c0:	48f51a63          	bne	a0,a5,ffffffffc0201554 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010c4:	4f3000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc02010c8:	8aaa                	mv	s5,a0
ffffffffc02010ca:	46050563          	beqz	a0,ffffffffc0201534 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02010ce:	4505                	li	a0,1
ffffffffc02010d0:	4e7000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc02010d4:	44051063          	bnez	a0,ffffffffc0201514 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02010d8:	415a1e63          	bne	s4,s5,ffffffffc02014f4 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010dc:	4585                	li	a1,1
ffffffffc02010de:	854e                	mv	a0,s3
ffffffffc02010e0:	511000ef          	jal	ffffffffc0201df0 <free_pages>
    free_pages(p1, 3);
ffffffffc02010e4:	8552                	mv	a0,s4
ffffffffc02010e6:	458d                	li	a1,3
ffffffffc02010e8:	509000ef          	jal	ffffffffc0201df0 <free_pages>
ffffffffc02010ec:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010f0:	8b89                	andi	a5,a5,2
ffffffffc02010f2:	3e078163          	beqz	a5,ffffffffc02014d4 <default_check+0x632>
ffffffffc02010f6:	0109aa83          	lw	s5,16(s3)
ffffffffc02010fa:	4785                	li	a5,1
ffffffffc02010fc:	3cfa9c63          	bne	s5,a5,ffffffffc02014d4 <default_check+0x632>
ffffffffc0201100:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201104:	8b89                	andi	a5,a5,2
ffffffffc0201106:	3a078763          	beqz	a5,ffffffffc02014b4 <default_check+0x612>
ffffffffc020110a:	010a2703          	lw	a4,16(s4)
ffffffffc020110e:	478d                	li	a5,3
ffffffffc0201110:	3af71263          	bne	a4,a5,ffffffffc02014b4 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201114:	8556                	mv	a0,s5
ffffffffc0201116:	4a1000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc020111a:	36a99d63          	bne	s3,a0,ffffffffc0201494 <default_check+0x5f2>
    free_page(p0);
ffffffffc020111e:	85d6                	mv	a1,s5
ffffffffc0201120:	4d1000ef          	jal	ffffffffc0201df0 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201124:	4509                	li	a0,2
ffffffffc0201126:	491000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc020112a:	34aa1563          	bne	s4,a0,ffffffffc0201474 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020112e:	4589                	li	a1,2
ffffffffc0201130:	4c1000ef          	jal	ffffffffc0201df0 <free_pages>
    free_page(p2);
ffffffffc0201134:	04098513          	addi	a0,s3,64
ffffffffc0201138:	85d6                	mv	a1,s5
ffffffffc020113a:	4b7000ef          	jal	ffffffffc0201df0 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020113e:	4515                	li	a0,5
ffffffffc0201140:	477000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201144:	89aa                	mv	s3,a0
ffffffffc0201146:	48050763          	beqz	a0,ffffffffc02015d4 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020114a:	8556                	mv	a0,s5
ffffffffc020114c:	46b000ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc0201150:	2e051263          	bnez	a0,ffffffffc0201434 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201154:	000b0797          	auipc	a5,0xb0
ffffffffc0201158:	5447a783          	lw	a5,1348(a5) # ffffffffc02b1698 <free_area+0x10>
ffffffffc020115c:	2a079c63          	bnez	a5,ffffffffc0201414 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201160:	854e                	mv	a0,s3
ffffffffc0201162:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201164:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201168:	01793023          	sd	s7,0(s2)
ffffffffc020116c:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201170:	481000ef          	jal	ffffffffc0201df0 <free_pages>
    return listelm->next;
ffffffffc0201174:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201178:	01278963          	beq	a5,s2,ffffffffc020118a <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020117c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201180:	679c                	ld	a5,8(a5)
ffffffffc0201182:	34fd                	addiw	s1,s1,-1
ffffffffc0201184:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201186:	ff279be3          	bne	a5,s2,ffffffffc020117c <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc020118a:	26049563          	bnez	s1,ffffffffc02013f4 <default_check+0x552>
    assert(total == 0);
ffffffffc020118e:	46041363          	bnez	s0,ffffffffc02015f4 <default_check+0x752>
}
ffffffffc0201192:	60e6                	ld	ra,88(sp)
ffffffffc0201194:	6446                	ld	s0,80(sp)
ffffffffc0201196:	64a6                	ld	s1,72(sp)
ffffffffc0201198:	6906                	ld	s2,64(sp)
ffffffffc020119a:	79e2                	ld	s3,56(sp)
ffffffffc020119c:	7a42                	ld	s4,48(sp)
ffffffffc020119e:	7aa2                	ld	s5,40(sp)
ffffffffc02011a0:	7b02                	ld	s6,32(sp)
ffffffffc02011a2:	6be2                	ld	s7,24(sp)
ffffffffc02011a4:	6c42                	ld	s8,16(sp)
ffffffffc02011a6:	6ca2                	ld	s9,8(sp)
ffffffffc02011a8:	6125                	addi	sp,sp,96
ffffffffc02011aa:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011ac:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011ae:	4401                	li	s0,0
ffffffffc02011b0:	4481                	li	s1,0
ffffffffc02011b2:	bb1d                	j	ffffffffc0200ee8 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02011b4:	00005697          	auipc	a3,0x5
ffffffffc02011b8:	0d468693          	addi	a3,a3,212 # ffffffffc0206288 <etext+0x9c6>
ffffffffc02011bc:	00005617          	auipc	a2,0x5
ffffffffc02011c0:	0dc60613          	addi	a2,a2,220 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02011c4:	11000593          	li	a1,272
ffffffffc02011c8:	00005517          	auipc	a0,0x5
ffffffffc02011cc:	0e850513          	addi	a0,a0,232 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02011d0:	a7aff0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011d4:	00005697          	auipc	a3,0x5
ffffffffc02011d8:	19c68693          	addi	a3,a3,412 # ffffffffc0206370 <etext+0xaae>
ffffffffc02011dc:	00005617          	auipc	a2,0x5
ffffffffc02011e0:	0bc60613          	addi	a2,a2,188 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02011e4:	0dc00593          	li	a1,220
ffffffffc02011e8:	00005517          	auipc	a0,0x5
ffffffffc02011ec:	0c850513          	addi	a0,a0,200 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02011f0:	a5aff0ef          	jal	ffffffffc020044a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011f4:	00005697          	auipc	a3,0x5
ffffffffc02011f8:	24468693          	addi	a3,a3,580 # ffffffffc0206438 <etext+0xb76>
ffffffffc02011fc:	00005617          	auipc	a2,0x5
ffffffffc0201200:	09c60613          	addi	a2,a2,156 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201204:	0f700593          	li	a1,247
ffffffffc0201208:	00005517          	auipc	a0,0x5
ffffffffc020120c:	0a850513          	addi	a0,a0,168 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201210:	a3aff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201214:	00005697          	auipc	a3,0x5
ffffffffc0201218:	19c68693          	addi	a3,a3,412 # ffffffffc02063b0 <etext+0xaee>
ffffffffc020121c:	00005617          	auipc	a2,0x5
ffffffffc0201220:	07c60613          	addi	a2,a2,124 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201224:	0de00593          	li	a1,222
ffffffffc0201228:	00005517          	auipc	a0,0x5
ffffffffc020122c:	08850513          	addi	a0,a0,136 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201230:	a1aff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201234:	00005697          	auipc	a3,0x5
ffffffffc0201238:	11468693          	addi	a3,a3,276 # ffffffffc0206348 <etext+0xa86>
ffffffffc020123c:	00005617          	auipc	a2,0x5
ffffffffc0201240:	05c60613          	addi	a2,a2,92 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201244:	0db00593          	li	a1,219
ffffffffc0201248:	00005517          	auipc	a0,0x5
ffffffffc020124c:	06850513          	addi	a0,a0,104 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201250:	9faff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201254:	00005697          	auipc	a3,0x5
ffffffffc0201258:	09468693          	addi	a3,a3,148 # ffffffffc02062e8 <etext+0xa26>
ffffffffc020125c:	00005617          	auipc	a2,0x5
ffffffffc0201260:	03c60613          	addi	a2,a2,60 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201264:	0f000593          	li	a1,240
ffffffffc0201268:	00005517          	auipc	a0,0x5
ffffffffc020126c:	04850513          	addi	a0,a0,72 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201270:	9daff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 3);
ffffffffc0201274:	00005697          	auipc	a3,0x5
ffffffffc0201278:	1b468693          	addi	a3,a3,436 # ffffffffc0206428 <etext+0xb66>
ffffffffc020127c:	00005617          	auipc	a2,0x5
ffffffffc0201280:	01c60613          	addi	a2,a2,28 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201284:	0ee00593          	li	a1,238
ffffffffc0201288:	00005517          	auipc	a0,0x5
ffffffffc020128c:	02850513          	addi	a0,a0,40 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201290:	9baff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201294:	00005697          	auipc	a3,0x5
ffffffffc0201298:	17c68693          	addi	a3,a3,380 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020129c:	00005617          	auipc	a2,0x5
ffffffffc02012a0:	ffc60613          	addi	a2,a2,-4 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02012a4:	0e900593          	li	a1,233
ffffffffc02012a8:	00005517          	auipc	a0,0x5
ffffffffc02012ac:	00850513          	addi	a0,a0,8 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02012b0:	99aff0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012b4:	00005697          	auipc	a3,0x5
ffffffffc02012b8:	13c68693          	addi	a3,a3,316 # ffffffffc02063f0 <etext+0xb2e>
ffffffffc02012bc:	00005617          	auipc	a2,0x5
ffffffffc02012c0:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02012c4:	0e000593          	li	a1,224
ffffffffc02012c8:	00005517          	auipc	a0,0x5
ffffffffc02012cc:	fe850513          	addi	a0,a0,-24 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02012d0:	97aff0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 != NULL);
ffffffffc02012d4:	00005697          	auipc	a3,0x5
ffffffffc02012d8:	1ac68693          	addi	a3,a3,428 # ffffffffc0206480 <etext+0xbbe>
ffffffffc02012dc:	00005617          	auipc	a2,0x5
ffffffffc02012e0:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02012e4:	11800593          	li	a1,280
ffffffffc02012e8:	00005517          	auipc	a0,0x5
ffffffffc02012ec:	fc850513          	addi	a0,a0,-56 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02012f0:	95aff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc02012f4:	00005697          	auipc	a3,0x5
ffffffffc02012f8:	17c68693          	addi	a3,a3,380 # ffffffffc0206470 <etext+0xbae>
ffffffffc02012fc:	00005617          	auipc	a2,0x5
ffffffffc0201300:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201304:	0fd00593          	li	a1,253
ffffffffc0201308:	00005517          	auipc	a0,0x5
ffffffffc020130c:	fa850513          	addi	a0,a0,-88 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201310:	93aff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201314:	00005697          	auipc	a3,0x5
ffffffffc0201318:	0fc68693          	addi	a3,a3,252 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020131c:	00005617          	auipc	a2,0x5
ffffffffc0201320:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201324:	0fb00593          	li	a1,251
ffffffffc0201328:	00005517          	auipc	a0,0x5
ffffffffc020132c:	f8850513          	addi	a0,a0,-120 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201330:	91aff0ef          	jal	ffffffffc020044a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201334:	00005697          	auipc	a3,0x5
ffffffffc0201338:	11c68693          	addi	a3,a3,284 # ffffffffc0206450 <etext+0xb8e>
ffffffffc020133c:	00005617          	auipc	a2,0x5
ffffffffc0201340:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201344:	0fa00593          	li	a1,250
ffffffffc0201348:	00005517          	auipc	a0,0x5
ffffffffc020134c:	f6850513          	addi	a0,a0,-152 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201350:	8faff0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201354:	00005697          	auipc	a3,0x5
ffffffffc0201358:	f9468693          	addi	a3,a3,-108 # ffffffffc02062e8 <etext+0xa26>
ffffffffc020135c:	00005617          	auipc	a2,0x5
ffffffffc0201360:	f3c60613          	addi	a2,a2,-196 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201364:	0d700593          	li	a1,215
ffffffffc0201368:	00005517          	auipc	a0,0x5
ffffffffc020136c:	f4850513          	addi	a0,a0,-184 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201370:	8daff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201374:	00005697          	auipc	a3,0x5
ffffffffc0201378:	09c68693          	addi	a3,a3,156 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020137c:	00005617          	auipc	a2,0x5
ffffffffc0201380:	f1c60613          	addi	a2,a2,-228 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201384:	0f400593          	li	a1,244
ffffffffc0201388:	00005517          	auipc	a0,0x5
ffffffffc020138c:	f2850513          	addi	a0,a0,-216 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201390:	8baff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201394:	00005697          	auipc	a3,0x5
ffffffffc0201398:	f9468693          	addi	a3,a3,-108 # ffffffffc0206328 <etext+0xa66>
ffffffffc020139c:	00005617          	auipc	a2,0x5
ffffffffc02013a0:	efc60613          	addi	a2,a2,-260 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02013a4:	0f200593          	li	a1,242
ffffffffc02013a8:	00005517          	auipc	a0,0x5
ffffffffc02013ac:	f0850513          	addi	a0,a0,-248 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02013b0:	89aff0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013b4:	00005697          	auipc	a3,0x5
ffffffffc02013b8:	f5468693          	addi	a3,a3,-172 # ffffffffc0206308 <etext+0xa46>
ffffffffc02013bc:	00005617          	auipc	a2,0x5
ffffffffc02013c0:	edc60613          	addi	a2,a2,-292 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02013c4:	0f100593          	li	a1,241
ffffffffc02013c8:	00005517          	auipc	a0,0x5
ffffffffc02013cc:	ee850513          	addi	a0,a0,-280 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02013d0:	87aff0ef          	jal	ffffffffc020044a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013d4:	00005697          	auipc	a3,0x5
ffffffffc02013d8:	f5468693          	addi	a3,a3,-172 # ffffffffc0206328 <etext+0xa66>
ffffffffc02013dc:	00005617          	auipc	a2,0x5
ffffffffc02013e0:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02013e4:	0d900593          	li	a1,217
ffffffffc02013e8:	00005517          	auipc	a0,0x5
ffffffffc02013ec:	ec850513          	addi	a0,a0,-312 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02013f0:	85aff0ef          	jal	ffffffffc020044a <__panic>
    assert(count == 0);
ffffffffc02013f4:	00005697          	auipc	a3,0x5
ffffffffc02013f8:	1dc68693          	addi	a3,a3,476 # ffffffffc02065d0 <etext+0xd0e>
ffffffffc02013fc:	00005617          	auipc	a2,0x5
ffffffffc0201400:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201404:	14600593          	li	a1,326
ffffffffc0201408:	00005517          	auipc	a0,0x5
ffffffffc020140c:	ea850513          	addi	a0,a0,-344 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201410:	83aff0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free == 0);
ffffffffc0201414:	00005697          	auipc	a3,0x5
ffffffffc0201418:	05c68693          	addi	a3,a3,92 # ffffffffc0206470 <etext+0xbae>
ffffffffc020141c:	00005617          	auipc	a2,0x5
ffffffffc0201420:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201424:	13a00593          	li	a1,314
ffffffffc0201428:	00005517          	auipc	a0,0x5
ffffffffc020142c:	e8850513          	addi	a0,a0,-376 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201430:	81aff0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201434:	00005697          	auipc	a3,0x5
ffffffffc0201438:	fdc68693          	addi	a3,a3,-36 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020143c:	00005617          	auipc	a2,0x5
ffffffffc0201440:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201444:	13800593          	li	a1,312
ffffffffc0201448:	00005517          	auipc	a0,0x5
ffffffffc020144c:	e6850513          	addi	a0,a0,-408 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201450:	ffbfe0ef          	jal	ffffffffc020044a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201454:	00005697          	auipc	a3,0x5
ffffffffc0201458:	f7c68693          	addi	a3,a3,-132 # ffffffffc02063d0 <etext+0xb0e>
ffffffffc020145c:	00005617          	auipc	a2,0x5
ffffffffc0201460:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201464:	0df00593          	li	a1,223
ffffffffc0201468:	00005517          	auipc	a0,0x5
ffffffffc020146c:	e4850513          	addi	a0,a0,-440 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201470:	fdbfe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201474:	00005697          	auipc	a3,0x5
ffffffffc0201478:	11c68693          	addi	a3,a3,284 # ffffffffc0206590 <etext+0xcce>
ffffffffc020147c:	00005617          	auipc	a2,0x5
ffffffffc0201480:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201484:	13200593          	li	a1,306
ffffffffc0201488:	00005517          	auipc	a0,0x5
ffffffffc020148c:	e2850513          	addi	a0,a0,-472 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201490:	fbbfe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201494:	00005697          	auipc	a3,0x5
ffffffffc0201498:	0dc68693          	addi	a3,a3,220 # ffffffffc0206570 <etext+0xcae>
ffffffffc020149c:	00005617          	auipc	a2,0x5
ffffffffc02014a0:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02014a4:	13000593          	li	a1,304
ffffffffc02014a8:	00005517          	auipc	a0,0x5
ffffffffc02014ac:	e0850513          	addi	a0,a0,-504 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02014b0:	f9bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014b4:	00005697          	auipc	a3,0x5
ffffffffc02014b8:	09468693          	addi	a3,a3,148 # ffffffffc0206548 <etext+0xc86>
ffffffffc02014bc:	00005617          	auipc	a2,0x5
ffffffffc02014c0:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02014c4:	12e00593          	li	a1,302
ffffffffc02014c8:	00005517          	auipc	a0,0x5
ffffffffc02014cc:	de850513          	addi	a0,a0,-536 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02014d0:	f7bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014d4:	00005697          	auipc	a3,0x5
ffffffffc02014d8:	04c68693          	addi	a3,a3,76 # ffffffffc0206520 <etext+0xc5e>
ffffffffc02014dc:	00005617          	auipc	a2,0x5
ffffffffc02014e0:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02014e4:	12d00593          	li	a1,301
ffffffffc02014e8:	00005517          	auipc	a0,0x5
ffffffffc02014ec:	dc850513          	addi	a0,a0,-568 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02014f0:	f5bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014f4:	00005697          	auipc	a3,0x5
ffffffffc02014f8:	01c68693          	addi	a3,a3,28 # ffffffffc0206510 <etext+0xc4e>
ffffffffc02014fc:	00005617          	auipc	a2,0x5
ffffffffc0201500:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201504:	12800593          	li	a1,296
ffffffffc0201508:	00005517          	auipc	a0,0x5
ffffffffc020150c:	da850513          	addi	a0,a0,-600 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201510:	f3bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201514:	00005697          	auipc	a3,0x5
ffffffffc0201518:	efc68693          	addi	a3,a3,-260 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020151c:	00005617          	auipc	a2,0x5
ffffffffc0201520:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201524:	12700593          	li	a1,295
ffffffffc0201528:	00005517          	auipc	a0,0x5
ffffffffc020152c:	d8850513          	addi	a0,a0,-632 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201530:	f1bfe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201534:	00005697          	auipc	a3,0x5
ffffffffc0201538:	fbc68693          	addi	a3,a3,-68 # ffffffffc02064f0 <etext+0xc2e>
ffffffffc020153c:	00005617          	auipc	a2,0x5
ffffffffc0201540:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201544:	12600593          	li	a1,294
ffffffffc0201548:	00005517          	auipc	a0,0x5
ffffffffc020154c:	d6850513          	addi	a0,a0,-664 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201550:	efbfe0ef          	jal	ffffffffc020044a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201554:	00005697          	auipc	a3,0x5
ffffffffc0201558:	f6c68693          	addi	a3,a3,-148 # ffffffffc02064c0 <etext+0xbfe>
ffffffffc020155c:	00005617          	auipc	a2,0x5
ffffffffc0201560:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201564:	12500593          	li	a1,293
ffffffffc0201568:	00005517          	auipc	a0,0x5
ffffffffc020156c:	d4850513          	addi	a0,a0,-696 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201570:	edbfe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201574:	00005697          	auipc	a3,0x5
ffffffffc0201578:	f3468693          	addi	a3,a3,-204 # ffffffffc02064a8 <etext+0xbe6>
ffffffffc020157c:	00005617          	auipc	a2,0x5
ffffffffc0201580:	d1c60613          	addi	a2,a2,-740 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201584:	12400593          	li	a1,292
ffffffffc0201588:	00005517          	auipc	a0,0x5
ffffffffc020158c:	d2850513          	addi	a0,a0,-728 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201590:	ebbfe0ef          	jal	ffffffffc020044a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201594:	00005697          	auipc	a3,0x5
ffffffffc0201598:	e7c68693          	addi	a3,a3,-388 # ffffffffc0206410 <etext+0xb4e>
ffffffffc020159c:	00005617          	auipc	a2,0x5
ffffffffc02015a0:	cfc60613          	addi	a2,a2,-772 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02015a4:	11e00593          	li	a1,286
ffffffffc02015a8:	00005517          	auipc	a0,0x5
ffffffffc02015ac:	d0850513          	addi	a0,a0,-760 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02015b0:	e9bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(!PageProperty(p0));
ffffffffc02015b4:	00005697          	auipc	a3,0x5
ffffffffc02015b8:	edc68693          	addi	a3,a3,-292 # ffffffffc0206490 <etext+0xbce>
ffffffffc02015bc:	00005617          	auipc	a2,0x5
ffffffffc02015c0:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02015c4:	11900593          	li	a1,281
ffffffffc02015c8:	00005517          	auipc	a0,0x5
ffffffffc02015cc:	ce850513          	addi	a0,a0,-792 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02015d0:	e7bfe0ef          	jal	ffffffffc020044a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015d4:	00005697          	auipc	a3,0x5
ffffffffc02015d8:	fdc68693          	addi	a3,a3,-36 # ffffffffc02065b0 <etext+0xcee>
ffffffffc02015dc:	00005617          	auipc	a2,0x5
ffffffffc02015e0:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02015e4:	13700593          	li	a1,311
ffffffffc02015e8:	00005517          	auipc	a0,0x5
ffffffffc02015ec:	cc850513          	addi	a0,a0,-824 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02015f0:	e5bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == 0);
ffffffffc02015f4:	00005697          	auipc	a3,0x5
ffffffffc02015f8:	fec68693          	addi	a3,a3,-20 # ffffffffc02065e0 <etext+0xd1e>
ffffffffc02015fc:	00005617          	auipc	a2,0x5
ffffffffc0201600:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201604:	14700593          	li	a1,327
ffffffffc0201608:	00005517          	auipc	a0,0x5
ffffffffc020160c:	ca850513          	addi	a0,a0,-856 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201610:	e3bfe0ef          	jal	ffffffffc020044a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201614:	00005697          	auipc	a3,0x5
ffffffffc0201618:	cb468693          	addi	a3,a3,-844 # ffffffffc02062c8 <etext+0xa06>
ffffffffc020161c:	00005617          	auipc	a2,0x5
ffffffffc0201620:	c7c60613          	addi	a2,a2,-900 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201624:	11300593          	li	a1,275
ffffffffc0201628:	00005517          	auipc	a0,0x5
ffffffffc020162c:	c8850513          	addi	a0,a0,-888 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201630:	e1bfe0ef          	jal	ffffffffc020044a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	cd468693          	addi	a3,a3,-812 # ffffffffc0206308 <etext+0xa46>
ffffffffc020163c:	00005617          	auipc	a2,0x5
ffffffffc0201640:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201644:	0d800593          	li	a1,216
ffffffffc0201648:	00005517          	auipc	a0,0x5
ffffffffc020164c:	c6850513          	addi	a0,a0,-920 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc0201650:	dfbfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201654 <default_free_pages>:
{
ffffffffc0201654:	1141                	addi	sp,sp,-16
ffffffffc0201656:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201658:	14058663          	beqz	a1,ffffffffc02017a4 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc020165c:	00659713          	slli	a4,a1,0x6
ffffffffc0201660:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201664:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201666:	c30d                	beqz	a4,ffffffffc0201688 <default_free_pages+0x34>
ffffffffc0201668:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020166a:	8b05                	andi	a4,a4,1
ffffffffc020166c:	10071c63          	bnez	a4,ffffffffc0201784 <default_free_pages+0x130>
ffffffffc0201670:	6798                	ld	a4,8(a5)
ffffffffc0201672:	8b09                	andi	a4,a4,2
ffffffffc0201674:	10071863          	bnez	a4,ffffffffc0201784 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201678:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020167c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201680:	04078793          	addi	a5,a5,64
ffffffffc0201684:	fed792e3          	bne	a5,a3,ffffffffc0201668 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201688:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020168a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020168e:	4789                	li	a5,2
ffffffffc0201690:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201694:	000b0717          	auipc	a4,0xb0
ffffffffc0201698:	00472703          	lw	a4,4(a4) # ffffffffc02b1698 <free_area+0x10>
ffffffffc020169c:	000b0697          	auipc	a3,0xb0
ffffffffc02016a0:	fec68693          	addi	a3,a3,-20 # ffffffffc02b1688 <free_area>
    return list->next == list;
ffffffffc02016a4:	669c                	ld	a5,8(a3)
ffffffffc02016a6:	9f2d                	addw	a4,a4,a1
ffffffffc02016a8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02016aa:	0ad78163          	beq	a5,a3,ffffffffc020174c <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02016ae:	fe878713          	addi	a4,a5,-24
ffffffffc02016b2:	4581                	li	a1,0
ffffffffc02016b4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02016b8:	00e56a63          	bltu	a0,a4,ffffffffc02016cc <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016bc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016be:	04d70c63          	beq	a4,a3,ffffffffc0201716 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02016c2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016c4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016c8:	fee57ae3          	bgeu	a0,a4,ffffffffc02016bc <default_free_pages+0x68>
ffffffffc02016cc:	c199                	beqz	a1,ffffffffc02016d2 <default_free_pages+0x7e>
ffffffffc02016ce:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016d2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016d4:	e390                	sd	a2,0(a5)
ffffffffc02016d6:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02016d8:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016da:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02016dc:	00d70d63          	beq	a4,a3,ffffffffc02016f6 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016e0:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016e4:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02016e8:	02059813          	slli	a6,a1,0x20
ffffffffc02016ec:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016f0:	97b2                	add	a5,a5,a2
ffffffffc02016f2:	02f50c63          	beq	a0,a5,ffffffffc020172a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016f6:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02016f8:	00d78c63          	beq	a5,a3,ffffffffc0201710 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02016fc:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02016fe:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201702:	02061593          	slli	a1,a2,0x20
ffffffffc0201706:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020170a:	972a                	add	a4,a4,a0
ffffffffc020170c:	04e68c63          	beq	a3,a4,ffffffffc0201764 <default_free_pages+0x110>
}
ffffffffc0201710:	60a2                	ld	ra,8(sp)
ffffffffc0201712:	0141                	addi	sp,sp,16
ffffffffc0201714:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201716:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201718:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020171a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020171c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020171e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201720:	02d70f63          	beq	a4,a3,ffffffffc020175e <default_free_pages+0x10a>
ffffffffc0201724:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201726:	87ba                	mv	a5,a4
ffffffffc0201728:	bf71                	j	ffffffffc02016c4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020172a:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020172c:	5875                	li	a6,-3
ffffffffc020172e:	9fad                	addw	a5,a5,a1
ffffffffc0201730:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201734:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201738:	01853803          	ld	a6,24(a0)
ffffffffc020173c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020173e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201740:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_matrix_out_size+0xfe4ac8>
    return listelm->next;
ffffffffc0201744:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201746:	0105b023          	sd	a6,0(a1)
ffffffffc020174a:	b77d                	j	ffffffffc02016f8 <default_free_pages+0xa4>
}
ffffffffc020174c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020174e:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201752:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201754:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201756:	e398                	sd	a4,0(a5)
ffffffffc0201758:	e798                	sd	a4,8(a5)
}
ffffffffc020175a:	0141                	addi	sp,sp,16
ffffffffc020175c:	8082                	ret
ffffffffc020175e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201760:	873e                	mv	a4,a5
ffffffffc0201762:	bfad                	j	ffffffffc02016dc <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201764:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201768:	56f5                	li	a3,-3
ffffffffc020176a:	9f31                	addw	a4,a4,a2
ffffffffc020176c:	c918                	sw	a4,16(a0)
ffffffffc020176e:	ff078713          	addi	a4,a5,-16
ffffffffc0201772:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201776:	6398                	ld	a4,0(a5)
ffffffffc0201778:	679c                	ld	a5,8(a5)
}
ffffffffc020177a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020177c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020177e:	e398                	sd	a4,0(a5)
ffffffffc0201780:	0141                	addi	sp,sp,16
ffffffffc0201782:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201784:	00005697          	auipc	a3,0x5
ffffffffc0201788:	e7468693          	addi	a3,a3,-396 # ffffffffc02065f8 <etext+0xd36>
ffffffffc020178c:	00005617          	auipc	a2,0x5
ffffffffc0201790:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201794:	09400593          	li	a1,148
ffffffffc0201798:	00005517          	auipc	a0,0x5
ffffffffc020179c:	b1850513          	addi	a0,a0,-1256 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02017a0:	cabfe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc02017a4:	00005697          	auipc	a3,0x5
ffffffffc02017a8:	e4c68693          	addi	a3,a3,-436 # ffffffffc02065f0 <etext+0xd2e>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02017b4:	09000593          	li	a1,144
ffffffffc02017b8:	00005517          	auipc	a0,0x5
ffffffffc02017bc:	af850513          	addi	a0,a0,-1288 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc02017c0:	c8bfe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02017c4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017c4:	c951                	beqz	a0,ffffffffc0201858 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02017c6:	000b0597          	auipc	a1,0xb0
ffffffffc02017ca:	ed25a583          	lw	a1,-302(a1) # ffffffffc02b1698 <free_area+0x10>
ffffffffc02017ce:	86aa                	mv	a3,a0
ffffffffc02017d0:	02059793          	slli	a5,a1,0x20
ffffffffc02017d4:	9381                	srli	a5,a5,0x20
ffffffffc02017d6:	00a7ef63          	bltu	a5,a0,ffffffffc02017f4 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02017da:	000b0617          	auipc	a2,0xb0
ffffffffc02017de:	eae60613          	addi	a2,a2,-338 # ffffffffc02b1688 <free_area>
ffffffffc02017e2:	87b2                	mv	a5,a2
ffffffffc02017e4:	a029                	j	ffffffffc02017ee <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02017e6:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02017ea:	00d77763          	bgeu	a4,a3,ffffffffc02017f8 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02017ee:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02017f0:	fec79be3          	bne	a5,a2,ffffffffc02017e6 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02017f4:	4501                	li	a0,0
}
ffffffffc02017f6:	8082                	ret
        if (page->property > n)
ffffffffc02017f8:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02017fc:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201800:	6798                	ld	a4,8(a5)
ffffffffc0201802:	02089313          	slli	t1,a7,0x20
ffffffffc0201806:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc020180a:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020180e:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc0201812:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc0201816:	0266fa63          	bgeu	a3,t1,ffffffffc020184a <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020181a:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc020181e:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201822:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201824:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201828:	00870313          	addi	t1,a4,8
ffffffffc020182c:	4889                	li	a7,2
ffffffffc020182e:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201832:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201836:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020183a:	0068b023          	sd	t1,0(a7)
ffffffffc020183e:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201842:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201846:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020184a:	9d95                	subw	a1,a1,a3
ffffffffc020184c:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020184e:	5775                	li	a4,-3
ffffffffc0201850:	17c1                	addi	a5,a5,-16
ffffffffc0201852:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201856:	8082                	ret
{
ffffffffc0201858:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020185a:	00005697          	auipc	a3,0x5
ffffffffc020185e:	d9668693          	addi	a3,a3,-618 # ffffffffc02065f0 <etext+0xd2e>
ffffffffc0201862:	00005617          	auipc	a2,0x5
ffffffffc0201866:	a3660613          	addi	a2,a2,-1482 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020186a:	06c00593          	li	a1,108
ffffffffc020186e:	00005517          	auipc	a0,0x5
ffffffffc0201872:	a4250513          	addi	a0,a0,-1470 # ffffffffc02062b0 <etext+0x9ee>
{
ffffffffc0201876:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201878:	bd3fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020187c <default_init_memmap>:
{
ffffffffc020187c:	1141                	addi	sp,sp,-16
ffffffffc020187e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201880:	c9e1                	beqz	a1,ffffffffc0201950 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc0201882:	00659713          	slli	a4,a1,0x6
ffffffffc0201886:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020188a:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020188c:	cf11                	beqz	a4,ffffffffc02018a8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020188e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201890:	8b05                	andi	a4,a4,1
ffffffffc0201892:	cf59                	beqz	a4,ffffffffc0201930 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201894:	0007a823          	sw	zero,16(a5)
ffffffffc0201898:	0007b423          	sd	zero,8(a5)
ffffffffc020189c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018a0:	04078793          	addi	a5,a5,64
ffffffffc02018a4:	fed795e3          	bne	a5,a3,ffffffffc020188e <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018a8:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018aa:	4789                	li	a5,2
ffffffffc02018ac:	00850713          	addi	a4,a0,8
ffffffffc02018b0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018b4:	000b0717          	auipc	a4,0xb0
ffffffffc02018b8:	de472703          	lw	a4,-540(a4) # ffffffffc02b1698 <free_area+0x10>
ffffffffc02018bc:	000b0697          	auipc	a3,0xb0
ffffffffc02018c0:	dcc68693          	addi	a3,a3,-564 # ffffffffc02b1688 <free_area>
    return list->next == list;
ffffffffc02018c4:	669c                	ld	a5,8(a3)
ffffffffc02018c6:	9f2d                	addw	a4,a4,a1
ffffffffc02018c8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02018ca:	04d78663          	beq	a5,a3,ffffffffc0201916 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02018ce:	fe878713          	addi	a4,a5,-24
ffffffffc02018d2:	4581                	li	a1,0
ffffffffc02018d4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02018d8:	00e56a63          	bltu	a0,a4,ffffffffc02018ec <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018dc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018de:	02d70263          	beq	a4,a3,ffffffffc0201902 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02018e2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018e4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018e8:	fee57ae3          	bgeu	a0,a4,ffffffffc02018dc <default_init_memmap+0x60>
ffffffffc02018ec:	c199                	beqz	a1,ffffffffc02018f2 <default_init_memmap+0x76>
ffffffffc02018ee:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018f2:	6398                	ld	a4,0(a5)
}
ffffffffc02018f4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018f6:	e390                	sd	a2,0(a5)
ffffffffc02018f8:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02018fa:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02018fc:	f11c                	sd	a5,32(a0)
ffffffffc02018fe:	0141                	addi	sp,sp,16
ffffffffc0201900:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201902:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201904:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201906:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201908:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020190a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc020190c:	00d70e63          	beq	a4,a3,ffffffffc0201928 <default_init_memmap+0xac>
ffffffffc0201910:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201912:	87ba                	mv	a5,a4
ffffffffc0201914:	bfc1                	j	ffffffffc02018e4 <default_init_memmap+0x68>
}
ffffffffc0201916:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201918:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020191c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020191e:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201920:	e398                	sd	a4,0(a5)
ffffffffc0201922:	e798                	sd	a4,8(a5)
}
ffffffffc0201924:	0141                	addi	sp,sp,16
ffffffffc0201926:	8082                	ret
ffffffffc0201928:	60a2                	ld	ra,8(sp)
ffffffffc020192a:	e290                	sd	a2,0(a3)
ffffffffc020192c:	0141                	addi	sp,sp,16
ffffffffc020192e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201930:	00005697          	auipc	a3,0x5
ffffffffc0201934:	cf068693          	addi	a3,a3,-784 # ffffffffc0206620 <etext+0xd5e>
ffffffffc0201938:	00005617          	auipc	a2,0x5
ffffffffc020193c:	96060613          	addi	a2,a2,-1696 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201940:	04b00593          	li	a1,75
ffffffffc0201944:	00005517          	auipc	a0,0x5
ffffffffc0201948:	96c50513          	addi	a0,a0,-1684 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc020194c:	afffe0ef          	jal	ffffffffc020044a <__panic>
    assert(n > 0);
ffffffffc0201950:	00005697          	auipc	a3,0x5
ffffffffc0201954:	ca068693          	addi	a3,a3,-864 # ffffffffc02065f0 <etext+0xd2e>
ffffffffc0201958:	00005617          	auipc	a2,0x5
ffffffffc020195c:	94060613          	addi	a2,a2,-1728 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201960:	04700593          	li	a1,71
ffffffffc0201964:	00005517          	auipc	a0,0x5
ffffffffc0201968:	94c50513          	addi	a0,a0,-1716 # ffffffffc02062b0 <etext+0x9ee>
ffffffffc020196c:	adffe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201970 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201970:	c531                	beqz	a0,ffffffffc02019bc <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201972:	e9b9                	bnez	a1,ffffffffc02019c8 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201974:	100027f3          	csrr	a5,sstatus
ffffffffc0201978:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020197a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020197c:	efb1                	bnez	a5,ffffffffc02019d8 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020197e:	000b0797          	auipc	a5,0xb0
ffffffffc0201982:	8fa7b783          	ld	a5,-1798(a5) # ffffffffc02b1278 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201986:	873e                	mv	a4,a5
ffffffffc0201988:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020198a:	02a77a63          	bgeu	a4,a0,ffffffffc02019be <slob_free+0x4e>
ffffffffc020198e:	00f56463          	bltu	a0,a5,ffffffffc0201996 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201992:	fef76ae3          	bltu	a4,a5,ffffffffc0201986 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201996:	4110                	lw	a2,0(a0)
ffffffffc0201998:	00461693          	slli	a3,a2,0x4
ffffffffc020199c:	96aa                	add	a3,a3,a0
ffffffffc020199e:	0ad78463          	beq	a5,a3,ffffffffc0201a46 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019a2:	4310                	lw	a2,0(a4)
ffffffffc02019a4:	e51c                	sd	a5,8(a0)
ffffffffc02019a6:	00461693          	slli	a3,a2,0x4
ffffffffc02019aa:	96ba                	add	a3,a3,a4
ffffffffc02019ac:	08d50163          	beq	a0,a3,ffffffffc0201a2e <slob_free+0xbe>
ffffffffc02019b0:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc02019b2:	000b0797          	auipc	a5,0xb0
ffffffffc02019b6:	8ce7b323          	sd	a4,-1850(a5) # ffffffffc02b1278 <slobfree>
    if (flag)
ffffffffc02019ba:	e9a5                	bnez	a1,ffffffffc0201a2a <slob_free+0xba>
ffffffffc02019bc:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019be:	fcf574e3          	bgeu	a0,a5,ffffffffc0201986 <slob_free+0x16>
ffffffffc02019c2:	fcf762e3          	bltu	a4,a5,ffffffffc0201986 <slob_free+0x16>
ffffffffc02019c6:	bfc1                	j	ffffffffc0201996 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc02019c8:	25bd                	addiw	a1,a1,15
ffffffffc02019ca:	8191                	srli	a1,a1,0x4
ffffffffc02019cc:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019ce:	100027f3          	csrr	a5,sstatus
ffffffffc02019d2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019d4:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d6:	d7c5                	beqz	a5,ffffffffc020197e <slob_free+0xe>
{
ffffffffc02019d8:	1101                	addi	sp,sp,-32
ffffffffc02019da:	e42a                	sd	a0,8(sp)
ffffffffc02019dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02019de:	f21fe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02019e2:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019e4:	000b0797          	auipc	a5,0xb0
ffffffffc02019e8:	8947b783          	ld	a5,-1900(a5) # ffffffffc02b1278 <slobfree>
ffffffffc02019ec:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019ee:	873e                	mv	a4,a5
ffffffffc02019f0:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019f2:	06a77663          	bgeu	a4,a0,ffffffffc0201a5e <slob_free+0xee>
ffffffffc02019f6:	00f56463          	bltu	a0,a5,ffffffffc02019fe <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019fa:	fef76ae3          	bltu	a4,a5,ffffffffc02019ee <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc02019fe:	4110                	lw	a2,0(a0)
ffffffffc0201a00:	00461693          	slli	a3,a2,0x4
ffffffffc0201a04:	96aa                	add	a3,a3,a0
ffffffffc0201a06:	06d78363          	beq	a5,a3,ffffffffc0201a6c <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201a0a:	4310                	lw	a2,0(a4)
ffffffffc0201a0c:	e51c                	sd	a5,8(a0)
ffffffffc0201a0e:	00461693          	slli	a3,a2,0x4
ffffffffc0201a12:	96ba                	add	a3,a3,a4
ffffffffc0201a14:	06d50163          	beq	a0,a3,ffffffffc0201a76 <slob_free+0x106>
ffffffffc0201a18:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201a1a:	000b0797          	auipc	a5,0xb0
ffffffffc0201a1e:	84e7bf23          	sd	a4,-1954(a5) # ffffffffc02b1278 <slobfree>
    if (flag)
ffffffffc0201a22:	e1a9                	bnez	a1,ffffffffc0201a64 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a24:	60e2                	ld	ra,24(sp)
ffffffffc0201a26:	6105                	addi	sp,sp,32
ffffffffc0201a28:	8082                	ret
        intr_enable();
ffffffffc0201a2a:	ecffe06f          	j	ffffffffc02008f8 <intr_enable>
		cur->units += b->units;
ffffffffc0201a2e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a30:	853e                	mv	a0,a5
ffffffffc0201a32:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201a34:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a38:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201a3a:	000b0797          	auipc	a5,0xb0
ffffffffc0201a3e:	82e7bf23          	sd	a4,-1986(a5) # ffffffffc02b1278 <slobfree>
    if (flag)
ffffffffc0201a42:	ddad                	beqz	a1,ffffffffc02019bc <slob_free+0x4c>
ffffffffc0201a44:	b7dd                	j	ffffffffc0201a2a <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201a46:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a48:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a4a:	9eb1                	addw	a3,a3,a2
ffffffffc0201a4c:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201a4e:	4310                	lw	a2,0(a4)
ffffffffc0201a50:	e51c                	sd	a5,8(a0)
ffffffffc0201a52:	00461693          	slli	a3,a2,0x4
ffffffffc0201a56:	96ba                	add	a3,a3,a4
ffffffffc0201a58:	f4d51ce3          	bne	a0,a3,ffffffffc02019b0 <slob_free+0x40>
ffffffffc0201a5c:	bfc9                	j	ffffffffc0201a2e <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a5e:	f8f56ee3          	bltu	a0,a5,ffffffffc02019fa <slob_free+0x8a>
ffffffffc0201a62:	b771                	j	ffffffffc02019ee <slob_free+0x7e>
}
ffffffffc0201a64:	60e2                	ld	ra,24(sp)
ffffffffc0201a66:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a68:	e91fe06f          	j	ffffffffc02008f8 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201a6c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a6e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a70:	9eb1                	addw	a3,a3,a2
ffffffffc0201a72:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201a74:	bf59                	j	ffffffffc0201a0a <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201a76:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201a78:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201a7a:	00c687bb          	addw	a5,a3,a2
ffffffffc0201a7e:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201a80:	bf61                	j	ffffffffc0201a18 <slob_free+0xa8>

ffffffffc0201a82 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a82:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a84:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a86:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a8a:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a8c:	32a000ef          	jal	ffffffffc0201db6 <alloc_pages>
	if (!page)
ffffffffc0201a90:	c91d                	beqz	a0,ffffffffc0201ac6 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a92:	000b4697          	auipc	a3,0xb4
ffffffffc0201a96:	c9e6b683          	ld	a3,-866(a3) # ffffffffc02b5730 <pages>
ffffffffc0201a9a:	00006797          	auipc	a5,0x6
ffffffffc0201a9e:	69e7b783          	ld	a5,1694(a5) # ffffffffc0208138 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201aa2:	000b4717          	auipc	a4,0xb4
ffffffffc0201aa6:	c8673703          	ld	a4,-890(a4) # ffffffffc02b5728 <npage>
    return page - pages + nbase;
ffffffffc0201aaa:	8d15                	sub	a0,a0,a3
ffffffffc0201aac:	8519                	srai	a0,a0,0x6
ffffffffc0201aae:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201ab0:	00c51793          	slli	a5,a0,0xc
ffffffffc0201ab4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ab6:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201ab8:	00e7fa63          	bgeu	a5,a4,ffffffffc0201acc <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201abc:	000b4797          	auipc	a5,0xb4
ffffffffc0201ac0:	c647b783          	ld	a5,-924(a5) # ffffffffc02b5720 <va_pa_offset>
ffffffffc0201ac4:	953e                	add	a0,a0,a5
}
ffffffffc0201ac6:	60a2                	ld	ra,8(sp)
ffffffffc0201ac8:	0141                	addi	sp,sp,16
ffffffffc0201aca:	8082                	ret
ffffffffc0201acc:	86aa                	mv	a3,a0
ffffffffc0201ace:	00005617          	auipc	a2,0x5
ffffffffc0201ad2:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0206648 <etext+0xd86>
ffffffffc0201ad6:	07100593          	li	a1,113
ffffffffc0201ada:	00005517          	auipc	a0,0x5
ffffffffc0201ade:	b9650513          	addi	a0,a0,-1130 # ffffffffc0206670 <etext+0xdae>
ffffffffc0201ae2:	969fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201ae6 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201ae6:	7179                	addi	sp,sp,-48
ffffffffc0201ae8:	f406                	sd	ra,40(sp)
ffffffffc0201aea:	f022                	sd	s0,32(sp)
ffffffffc0201aec:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201aee:	01050713          	addi	a4,a0,16
ffffffffc0201af2:	6785                	lui	a5,0x1
ffffffffc0201af4:	0af77e63          	bgeu	a4,a5,ffffffffc0201bb0 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201af8:	00f50413          	addi	s0,a0,15
ffffffffc0201afc:	8011                	srli	s0,s0,0x4
ffffffffc0201afe:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b00:	100025f3          	csrr	a1,sstatus
ffffffffc0201b04:	8989                	andi	a1,a1,2
ffffffffc0201b06:	edd1                	bnez	a1,ffffffffc0201ba2 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201b08:	000af497          	auipc	s1,0xaf
ffffffffc0201b0c:	77048493          	addi	s1,s1,1904 # ffffffffc02b1278 <slobfree>
ffffffffc0201b10:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b12:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201b14:	4314                	lw	a3,0(a4)
ffffffffc0201b16:	0886da63          	bge	a3,s0,ffffffffc0201baa <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201b1a:	00e60a63          	beq	a2,a4,ffffffffc0201b2e <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b1e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b20:	4394                	lw	a3,0(a5)
ffffffffc0201b22:	0286d863          	bge	a3,s0,ffffffffc0201b52 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201b26:	6090                	ld	a2,0(s1)
ffffffffc0201b28:	873e                	mv	a4,a5
ffffffffc0201b2a:	fee61ae3          	bne	a2,a4,ffffffffc0201b1e <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201b2e:	e9b1                	bnez	a1,ffffffffc0201b82 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b30:	4501                	li	a0,0
ffffffffc0201b32:	f51ff0ef          	jal	ffffffffc0201a82 <__slob_get_free_pages.constprop.0>
ffffffffc0201b36:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201b38:	c915                	beqz	a0,ffffffffc0201b6c <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b3a:	6585                	lui	a1,0x1
ffffffffc0201b3c:	e35ff0ef          	jal	ffffffffc0201970 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b40:	100025f3          	csrr	a1,sstatus
ffffffffc0201b44:	8989                	andi	a1,a1,2
ffffffffc0201b46:	e98d                	bnez	a1,ffffffffc0201b78 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201b48:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b4a:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201b4c:	4394                	lw	a3,0(a5)
ffffffffc0201b4e:	fc86cce3          	blt	a3,s0,ffffffffc0201b26 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b52:	04d40563          	beq	s0,a3,ffffffffc0201b9c <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201b56:	00441613          	slli	a2,s0,0x4
ffffffffc0201b5a:	963e                	add	a2,a2,a5
ffffffffc0201b5c:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201b5e:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201b60:	9e81                	subw	a3,a3,s0
ffffffffc0201b62:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201b64:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201b66:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201b68:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201b6a:	ed99                	bnez	a1,ffffffffc0201b88 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201b6c:	70a2                	ld	ra,40(sp)
ffffffffc0201b6e:	7402                	ld	s0,32(sp)
ffffffffc0201b70:	64e2                	ld	s1,24(sp)
ffffffffc0201b72:	853e                	mv	a0,a5
ffffffffc0201b74:	6145                	addi	sp,sp,48
ffffffffc0201b76:	8082                	ret
        intr_disable();
ffffffffc0201b78:	d87fe0ef          	jal	ffffffffc02008fe <intr_disable>
			cur = slobfree;
ffffffffc0201b7c:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201b7e:	4585                	li	a1,1
ffffffffc0201b80:	b7e9                	j	ffffffffc0201b4a <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201b82:	d77fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b86:	b76d                	j	ffffffffc0201b30 <slob_alloc.constprop.0+0x4a>
ffffffffc0201b88:	e43e                	sd	a5,8(sp)
ffffffffc0201b8a:	d6ffe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201b8e:	67a2                	ld	a5,8(sp)
}
ffffffffc0201b90:	70a2                	ld	ra,40(sp)
ffffffffc0201b92:	7402                	ld	s0,32(sp)
ffffffffc0201b94:	64e2                	ld	s1,24(sp)
ffffffffc0201b96:	853e                	mv	a0,a5
ffffffffc0201b98:	6145                	addi	sp,sp,48
ffffffffc0201b9a:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b9c:	6794                	ld	a3,8(a5)
ffffffffc0201b9e:	e714                	sd	a3,8(a4)
ffffffffc0201ba0:	b7e1                	j	ffffffffc0201b68 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201ba2:	d5dfe0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0201ba6:	4585                	li	a1,1
ffffffffc0201ba8:	b785                	j	ffffffffc0201b08 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201baa:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201bac:	8732                	mv	a4,a2
ffffffffc0201bae:	b755                	j	ffffffffc0201b52 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bb0:	00005697          	auipc	a3,0x5
ffffffffc0201bb4:	ad068693          	addi	a3,a3,-1328 # ffffffffc0206680 <etext+0xdbe>
ffffffffc0201bb8:	00004617          	auipc	a2,0x4
ffffffffc0201bbc:	6e060613          	addi	a2,a2,1760 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0201bc0:	06300593          	li	a1,99
ffffffffc0201bc4:	00005517          	auipc	a0,0x5
ffffffffc0201bc8:	adc50513          	addi	a0,a0,-1316 # ffffffffc02066a0 <etext+0xdde>
ffffffffc0201bcc:	87ffe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201bd0 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201bd0:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201bd2:	00005517          	auipc	a0,0x5
ffffffffc0201bd6:	ae650513          	addi	a0,a0,-1306 # ffffffffc02066b8 <etext+0xdf6>
{
ffffffffc0201bda:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201bdc:	dbcfe0ef          	jal	ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201be0:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201be2:	00005517          	auipc	a0,0x5
ffffffffc0201be6:	aee50513          	addi	a0,a0,-1298 # ffffffffc02066d0 <etext+0xe0e>
}
ffffffffc0201bea:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bec:	dacfe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201bf0 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201bf0:	4501                	li	a0,0
ffffffffc0201bf2:	8082                	ret

ffffffffc0201bf4 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bf4:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bf6:	6685                	lui	a3,0x1
{
ffffffffc0201bf8:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bfa:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7f51>
ffffffffc0201bfc:	04a6f963          	bgeu	a3,a0,ffffffffc0201c4e <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c00:	e42a                	sd	a0,8(sp)
ffffffffc0201c02:	4561                	li	a0,24
ffffffffc0201c04:	e822                	sd	s0,16(sp)
ffffffffc0201c06:	ee1ff0ef          	jal	ffffffffc0201ae6 <slob_alloc.constprop.0>
ffffffffc0201c0a:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201c0c:	c541                	beqz	a0,ffffffffc0201c94 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201c0e:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201c10:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201c12:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c14:	00f75763          	bge	a4,a5,ffffffffc0201c22 <kmalloc+0x2e>
ffffffffc0201c18:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201c1c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c1e:	fef74de3          	blt	a4,a5,ffffffffc0201c18 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201c22:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c24:	e5fff0ef          	jal	ffffffffc0201a82 <__slob_get_free_pages.constprop.0>
ffffffffc0201c28:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201c2a:	cd31                	beqz	a0,ffffffffc0201c86 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c2c:	100027f3          	csrr	a5,sstatus
ffffffffc0201c30:	8b89                	andi	a5,a5,2
ffffffffc0201c32:	eb85                	bnez	a5,ffffffffc0201c62 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201c34:	000b4797          	auipc	a5,0xb4
ffffffffc0201c38:	acc7b783          	ld	a5,-1332(a5) # ffffffffc02b5700 <bigblocks>
		bigblocks = bb;
ffffffffc0201c3c:	000b4717          	auipc	a4,0xb4
ffffffffc0201c40:	ac873223          	sd	s0,-1340(a4) # ffffffffc02b5700 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c44:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201c46:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201c48:	60e2                	ld	ra,24(sp)
ffffffffc0201c4a:	6105                	addi	sp,sp,32
ffffffffc0201c4c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c4e:	0541                	addi	a0,a0,16
ffffffffc0201c50:	e97ff0ef          	jal	ffffffffc0201ae6 <slob_alloc.constprop.0>
ffffffffc0201c54:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c56:	0541                	addi	a0,a0,16
ffffffffc0201c58:	fbe5                	bnez	a5,ffffffffc0201c48 <kmalloc+0x54>
		return 0;
ffffffffc0201c5a:	4501                	li	a0,0
}
ffffffffc0201c5c:	60e2                	ld	ra,24(sp)
ffffffffc0201c5e:	6105                	addi	sp,sp,32
ffffffffc0201c60:	8082                	ret
        intr_disable();
ffffffffc0201c62:	c9dfe0ef          	jal	ffffffffc02008fe <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c66:	000b4797          	auipc	a5,0xb4
ffffffffc0201c6a:	a9a7b783          	ld	a5,-1382(a5) # ffffffffc02b5700 <bigblocks>
		bigblocks = bb;
ffffffffc0201c6e:	000b4717          	auipc	a4,0xb4
ffffffffc0201c72:	a8873923          	sd	s0,-1390(a4) # ffffffffc02b5700 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201c76:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201c78:	c81fe0ef          	jal	ffffffffc02008f8 <intr_enable>
		return bb->pages;
ffffffffc0201c7c:	6408                	ld	a0,8(s0)
}
ffffffffc0201c7e:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201c80:	6442                	ld	s0,16(sp)
}
ffffffffc0201c82:	6105                	addi	sp,sp,32
ffffffffc0201c84:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c86:	8522                	mv	a0,s0
ffffffffc0201c88:	45e1                	li	a1,24
ffffffffc0201c8a:	ce7ff0ef          	jal	ffffffffc0201970 <slob_free>
		return 0;
ffffffffc0201c8e:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c90:	6442                	ld	s0,16(sp)
ffffffffc0201c92:	b7e9                	j	ffffffffc0201c5c <kmalloc+0x68>
ffffffffc0201c94:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201c96:	4501                	li	a0,0
ffffffffc0201c98:	b7d1                	j	ffffffffc0201c5c <kmalloc+0x68>

ffffffffc0201c9a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c9a:	c571                	beqz	a0,ffffffffc0201d66 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c9c:	03451793          	slli	a5,a0,0x34
ffffffffc0201ca0:	e3e1                	bnez	a5,ffffffffc0201d60 <kfree+0xc6>
{
ffffffffc0201ca2:	1101                	addi	sp,sp,-32
ffffffffc0201ca4:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ca6:	100027f3          	csrr	a5,sstatus
ffffffffc0201caa:	8b89                	andi	a5,a5,2
ffffffffc0201cac:	e7c1                	bnez	a5,ffffffffc0201d34 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cae:	000b4797          	auipc	a5,0xb4
ffffffffc0201cb2:	a527b783          	ld	a5,-1454(a5) # ffffffffc02b5700 <bigblocks>
    return 0;
ffffffffc0201cb6:	4581                	li	a1,0
ffffffffc0201cb8:	cbad                	beqz	a5,ffffffffc0201d2a <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201cba:	000b4617          	auipc	a2,0xb4
ffffffffc0201cbe:	a4660613          	addi	a2,a2,-1466 # ffffffffc02b5700 <bigblocks>
ffffffffc0201cc2:	a021                	j	ffffffffc0201cca <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cc4:	01070613          	addi	a2,a4,16
ffffffffc0201cc8:	c3a5                	beqz	a5,ffffffffc0201d28 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201cca:	6794                	ld	a3,8(a5)
ffffffffc0201ccc:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201cce:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201cd0:	fea69ae3          	bne	a3,a0,ffffffffc0201cc4 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201cd4:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201cd6:	edb5                	bnez	a1,ffffffffc0201d52 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201cd8:	c02007b7          	lui	a5,0xc0200
ffffffffc0201cdc:	0af56263          	bltu	a0,a5,ffffffffc0201d80 <kfree+0xe6>
ffffffffc0201ce0:	000b4797          	auipc	a5,0xb4
ffffffffc0201ce4:	a407b783          	ld	a5,-1472(a5) # ffffffffc02b5720 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201ce8:	000b4697          	auipc	a3,0xb4
ffffffffc0201cec:	a406b683          	ld	a3,-1472(a3) # ffffffffc02b5728 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201cf0:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201cf2:	00c55793          	srli	a5,a0,0xc
ffffffffc0201cf6:	06d7f963          	bgeu	a5,a3,ffffffffc0201d68 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cfa:	00006617          	auipc	a2,0x6
ffffffffc0201cfe:	43e63603          	ld	a2,1086(a2) # ffffffffc0208138 <nbase>
ffffffffc0201d02:	000b4517          	auipc	a0,0xb4
ffffffffc0201d06:	a2e53503          	ld	a0,-1490(a0) # ffffffffc02b5730 <pages>
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201d0a:	4314                	lw	a3,0(a4)
ffffffffc0201d0c:	8f91                	sub	a5,a5,a2
ffffffffc0201d0e:	079a                	slli	a5,a5,0x6
ffffffffc0201d10:	4585                	li	a1,1
ffffffffc0201d12:	953e                	add	a0,a0,a5
ffffffffc0201d14:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201d18:	e03a                	sd	a4,0(sp)
ffffffffc0201d1a:	0d6000ef          	jal	ffffffffc0201df0 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d1e:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d20:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d22:	45e1                	li	a1,24
}
ffffffffc0201d24:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d26:	b1a9                	j	ffffffffc0201970 <slob_free>
ffffffffc0201d28:	e185                	bnez	a1,ffffffffc0201d48 <kfree+0xae>
}
ffffffffc0201d2a:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d2c:	1541                	addi	a0,a0,-16
ffffffffc0201d2e:	4581                	li	a1,0
}
ffffffffc0201d30:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d32:	b93d                	j	ffffffffc0201970 <slob_free>
        intr_disable();
ffffffffc0201d34:	e02a                	sd	a0,0(sp)
ffffffffc0201d36:	bc9fe0ef          	jal	ffffffffc02008fe <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d3a:	000b4797          	auipc	a5,0xb4
ffffffffc0201d3e:	9c67b783          	ld	a5,-1594(a5) # ffffffffc02b5700 <bigblocks>
ffffffffc0201d42:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201d44:	4585                	li	a1,1
ffffffffc0201d46:	fbb5                	bnez	a5,ffffffffc0201cba <kfree+0x20>
ffffffffc0201d48:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201d4a:	baffe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d4e:	6502                	ld	a0,0(sp)
ffffffffc0201d50:	bfe9                	j	ffffffffc0201d2a <kfree+0x90>
ffffffffc0201d52:	e42a                	sd	a0,8(sp)
ffffffffc0201d54:	e03a                	sd	a4,0(sp)
ffffffffc0201d56:	ba3fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0201d5a:	6522                	ld	a0,8(sp)
ffffffffc0201d5c:	6702                	ld	a4,0(sp)
ffffffffc0201d5e:	bfad                	j	ffffffffc0201cd8 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d60:	1541                	addi	a0,a0,-16
ffffffffc0201d62:	4581                	li	a1,0
ffffffffc0201d64:	b131                	j	ffffffffc0201970 <slob_free>
ffffffffc0201d66:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d68:	00005617          	auipc	a2,0x5
ffffffffc0201d6c:	9b060613          	addi	a2,a2,-1616 # ffffffffc0206718 <etext+0xe56>
ffffffffc0201d70:	06900593          	li	a1,105
ffffffffc0201d74:	00005517          	auipc	a0,0x5
ffffffffc0201d78:	8fc50513          	addi	a0,a0,-1796 # ffffffffc0206670 <etext+0xdae>
ffffffffc0201d7c:	ecefe0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d80:	86aa                	mv	a3,a0
ffffffffc0201d82:	00005617          	auipc	a2,0x5
ffffffffc0201d86:	96e60613          	addi	a2,a2,-1682 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc0201d8a:	07700593          	li	a1,119
ffffffffc0201d8e:	00005517          	auipc	a0,0x5
ffffffffc0201d92:	8e250513          	addi	a0,a0,-1822 # ffffffffc0206670 <etext+0xdae>
ffffffffc0201d96:	eb4fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201d9a <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d9a:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d9c:	00005617          	auipc	a2,0x5
ffffffffc0201da0:	97c60613          	addi	a2,a2,-1668 # ffffffffc0206718 <etext+0xe56>
ffffffffc0201da4:	06900593          	li	a1,105
ffffffffc0201da8:	00005517          	auipc	a0,0x5
ffffffffc0201dac:	8c850513          	addi	a0,a0,-1848 # ffffffffc0206670 <etext+0xdae>
pa2page(uintptr_t pa)
ffffffffc0201db0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201db2:	e98fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0201db6 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201db6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dba:	8b89                	andi	a5,a5,2
ffffffffc0201dbc:	e799                	bnez	a5,ffffffffc0201dca <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dbe:	000b4797          	auipc	a5,0xb4
ffffffffc0201dc2:	94a7b783          	ld	a5,-1718(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201dc6:	6f9c                	ld	a5,24(a5)
ffffffffc0201dc8:	8782                	jr	a5
{
ffffffffc0201dca:	1101                	addi	sp,sp,-32
ffffffffc0201dcc:	ec06                	sd	ra,24(sp)
ffffffffc0201dce:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201dd0:	b2ffe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dd4:	000b4797          	auipc	a5,0xb4
ffffffffc0201dd8:	9347b783          	ld	a5,-1740(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201ddc:	6522                	ld	a0,8(sp)
ffffffffc0201dde:	6f9c                	ld	a5,24(a5)
ffffffffc0201de0:	9782                	jalr	a5
ffffffffc0201de2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201de4:	b15fe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201de8:	60e2                	ld	ra,24(sp)
ffffffffc0201dea:	6522                	ld	a0,8(sp)
ffffffffc0201dec:	6105                	addi	sp,sp,32
ffffffffc0201dee:	8082                	ret

ffffffffc0201df0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201df0:	100027f3          	csrr	a5,sstatus
ffffffffc0201df4:	8b89                	andi	a5,a5,2
ffffffffc0201df6:	e799                	bnez	a5,ffffffffc0201e04 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201df8:	000b4797          	auipc	a5,0xb4
ffffffffc0201dfc:	9107b783          	ld	a5,-1776(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201e00:	739c                	ld	a5,32(a5)
ffffffffc0201e02:	8782                	jr	a5
{
ffffffffc0201e04:	1101                	addi	sp,sp,-32
ffffffffc0201e06:	ec06                	sd	ra,24(sp)
ffffffffc0201e08:	e42e                	sd	a1,8(sp)
ffffffffc0201e0a:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201e0c:	af3fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e10:	000b4797          	auipc	a5,0xb4
ffffffffc0201e14:	8f87b783          	ld	a5,-1800(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201e18:	65a2                	ld	a1,8(sp)
ffffffffc0201e1a:	6502                	ld	a0,0(sp)
ffffffffc0201e1c:	739c                	ld	a5,32(a5)
ffffffffc0201e1e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e20:	60e2                	ld	ra,24(sp)
ffffffffc0201e22:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e24:	ad5fe06f          	j	ffffffffc02008f8 <intr_enable>

ffffffffc0201e28 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e28:	100027f3          	csrr	a5,sstatus
ffffffffc0201e2c:	8b89                	andi	a5,a5,2
ffffffffc0201e2e:	e799                	bnez	a5,ffffffffc0201e3c <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e30:	000b4797          	auipc	a5,0xb4
ffffffffc0201e34:	8d87b783          	ld	a5,-1832(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201e38:	779c                	ld	a5,40(a5)
ffffffffc0201e3a:	8782                	jr	a5
{
ffffffffc0201e3c:	1101                	addi	sp,sp,-32
ffffffffc0201e3e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201e40:	abffe0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e44:	000b4797          	auipc	a5,0xb4
ffffffffc0201e48:	8c47b783          	ld	a5,-1852(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201e4c:	779c                	ld	a5,40(a5)
ffffffffc0201e4e:	9782                	jalr	a5
ffffffffc0201e50:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e52:	aa7fe0ef          	jal	ffffffffc02008f8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e56:	60e2                	ld	ra,24(sp)
ffffffffc0201e58:	6522                	ld	a0,8(sp)
ffffffffc0201e5a:	6105                	addi	sp,sp,32
ffffffffc0201e5c:	8082                	ret

ffffffffc0201e5e <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e5e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e62:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e66:	078e                	slli	a5,a5,0x3
ffffffffc0201e68:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e6c:	6314                	ld	a3,0(a4)
{
ffffffffc0201e6e:	7139                	addi	sp,sp,-64
ffffffffc0201e70:	f822                	sd	s0,48(sp)
ffffffffc0201e72:	f426                	sd	s1,40(sp)
ffffffffc0201e74:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e76:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e7a:	842e                	mv	s0,a1
ffffffffc0201e7c:	8832                	mv	a6,a2
ffffffffc0201e7e:	000b4497          	auipc	s1,0xb4
ffffffffc0201e82:	8aa48493          	addi	s1,s1,-1878 # ffffffffc02b5728 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e86:	ebd1                	bnez	a5,ffffffffc0201f1a <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e88:	16060d63          	beqz	a2,ffffffffc0202002 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e90:	8b89                	andi	a5,a5,2
ffffffffc0201e92:	16079e63          	bnez	a5,ffffffffc020200e <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e96:	000b4797          	auipc	a5,0xb4
ffffffffc0201e9a:	8727b783          	ld	a5,-1934(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201e9e:	4505                	li	a0,1
ffffffffc0201ea0:	e43a                	sd	a4,8(sp)
ffffffffc0201ea2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea4:	e832                	sd	a2,16(sp)
ffffffffc0201ea6:	9782                	jalr	a5
ffffffffc0201ea8:	6722                	ld	a4,8(sp)
ffffffffc0201eaa:	6842                	ld	a6,16(sp)
ffffffffc0201eac:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201eae:	14078a63          	beqz	a5,ffffffffc0202002 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201eb2:	000b4517          	auipc	a0,0xb4
ffffffffc0201eb6:	87e53503          	ld	a0,-1922(a0) # ffffffffc02b5730 <pages>
ffffffffc0201eba:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ebe:	000b4497          	auipc	s1,0xb4
ffffffffc0201ec2:	86a48493          	addi	s1,s1,-1942 # ffffffffc02b5728 <npage>
ffffffffc0201ec6:	40a78533          	sub	a0,a5,a0
ffffffffc0201eca:	8519                	srai	a0,a0,0x6
ffffffffc0201ecc:	9546                	add	a0,a0,a7
ffffffffc0201ece:	6090                	ld	a2,0(s1)
ffffffffc0201ed0:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201ed4:	4585                	li	a1,1
ffffffffc0201ed6:	82b1                	srli	a3,a3,0xc
ffffffffc0201ed8:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201eda:	0532                	slli	a0,a0,0xc
ffffffffc0201edc:	1ac6f763          	bgeu	a3,a2,ffffffffc020208a <get_pte+0x22c>
ffffffffc0201ee0:	000b4697          	auipc	a3,0xb4
ffffffffc0201ee4:	8406b683          	ld	a3,-1984(a3) # ffffffffc02b5720 <va_pa_offset>
ffffffffc0201ee8:	6605                	lui	a2,0x1
ffffffffc0201eea:	4581                	li	a1,0
ffffffffc0201eec:	9536                	add	a0,a0,a3
ffffffffc0201eee:	ec42                	sd	a6,24(sp)
ffffffffc0201ef0:	e83e                	sd	a5,16(sp)
ffffffffc0201ef2:	e43a                	sd	a4,8(sp)
ffffffffc0201ef4:	1a5030ef          	jal	ffffffffc0205898 <memset>
    return page - pages + nbase;
ffffffffc0201ef8:	000b4697          	auipc	a3,0xb4
ffffffffc0201efc:	8386b683          	ld	a3,-1992(a3) # ffffffffc02b5730 <pages>
ffffffffc0201f00:	67c2                	ld	a5,16(sp)
ffffffffc0201f02:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f06:	6722                	ld	a4,8(sp)
ffffffffc0201f08:	40d786b3          	sub	a3,a5,a3
ffffffffc0201f0c:	8699                	srai	a3,a3,0x6
ffffffffc0201f0e:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f10:	06aa                	slli	a3,a3,0xa
ffffffffc0201f12:	6862                	ld	a6,24(sp)
ffffffffc0201f14:	0116e693          	ori	a3,a3,17
ffffffffc0201f18:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f1a:	c006f693          	andi	a3,a3,-1024
ffffffffc0201f1e:	6098                	ld	a4,0(s1)
ffffffffc0201f20:	068a                	slli	a3,a3,0x2
ffffffffc0201f22:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f26:	14e7f663          	bgeu	a5,a4,ffffffffc0202072 <get_pte+0x214>
ffffffffc0201f2a:	000b3897          	auipc	a7,0xb3
ffffffffc0201f2e:	7f688893          	addi	a7,a7,2038 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0201f32:	0008b603          	ld	a2,0(a7)
ffffffffc0201f36:	01545793          	srli	a5,s0,0x15
ffffffffc0201f3a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f3e:	96b2                	add	a3,a3,a2
ffffffffc0201f40:	078e                	slli	a5,a5,0x3
ffffffffc0201f42:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f44:	6394                	ld	a3,0(a5)
ffffffffc0201f46:	0016f613          	andi	a2,a3,1
ffffffffc0201f4a:	e659                	bnez	a2,ffffffffc0201fd8 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f4c:	0a080b63          	beqz	a6,ffffffffc0202002 <get_pte+0x1a4>
ffffffffc0201f50:	10002773          	csrr	a4,sstatus
ffffffffc0201f54:	8b09                	andi	a4,a4,2
ffffffffc0201f56:	ef71                	bnez	a4,ffffffffc0202032 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f58:	000b3717          	auipc	a4,0xb3
ffffffffc0201f5c:	7b073703          	ld	a4,1968(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc0201f60:	4505                	li	a0,1
ffffffffc0201f62:	e43e                	sd	a5,8(sp)
ffffffffc0201f64:	6f18                	ld	a4,24(a4)
ffffffffc0201f66:	9702                	jalr	a4
ffffffffc0201f68:	67a2                	ld	a5,8(sp)
ffffffffc0201f6a:	872a                	mv	a4,a0
ffffffffc0201f6c:	000b3897          	auipc	a7,0xb3
ffffffffc0201f70:	7b488893          	addi	a7,a7,1972 # ffffffffc02b5720 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f74:	c759                	beqz	a4,ffffffffc0202002 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f76:	000b3697          	auipc	a3,0xb3
ffffffffc0201f7a:	7ba6b683          	ld	a3,1978(a3) # ffffffffc02b5730 <pages>
ffffffffc0201f7e:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f82:	608c                	ld	a1,0(s1)
ffffffffc0201f84:	40d706b3          	sub	a3,a4,a3
ffffffffc0201f88:	8699                	srai	a3,a3,0x6
ffffffffc0201f8a:	96c2                	add	a3,a3,a6
ffffffffc0201f8c:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201f90:	4505                	li	a0,1
ffffffffc0201f92:	8231                	srli	a2,a2,0xc
ffffffffc0201f94:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f96:	06b2                	slli	a3,a3,0xc
ffffffffc0201f98:	10b67663          	bgeu	a2,a1,ffffffffc02020a4 <get_pte+0x246>
ffffffffc0201f9c:	0008b503          	ld	a0,0(a7)
ffffffffc0201fa0:	6605                	lui	a2,0x1
ffffffffc0201fa2:	4581                	li	a1,0
ffffffffc0201fa4:	9536                	add	a0,a0,a3
ffffffffc0201fa6:	e83a                	sd	a4,16(sp)
ffffffffc0201fa8:	e43e                	sd	a5,8(sp)
ffffffffc0201faa:	0ef030ef          	jal	ffffffffc0205898 <memset>
    return page - pages + nbase;
ffffffffc0201fae:	000b3697          	auipc	a3,0xb3
ffffffffc0201fb2:	7826b683          	ld	a3,1922(a3) # ffffffffc02b5730 <pages>
ffffffffc0201fb6:	6742                	ld	a4,16(sp)
ffffffffc0201fb8:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fbc:	67a2                	ld	a5,8(sp)
ffffffffc0201fbe:	40d706b3          	sub	a3,a4,a3
ffffffffc0201fc2:	8699                	srai	a3,a3,0x6
ffffffffc0201fc4:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fc6:	06aa                	slli	a3,a3,0xa
ffffffffc0201fc8:	0116e693          	ori	a3,a3,17
ffffffffc0201fcc:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fce:	6098                	ld	a4,0(s1)
ffffffffc0201fd0:	000b3897          	auipc	a7,0xb3
ffffffffc0201fd4:	75088893          	addi	a7,a7,1872 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0201fd8:	c006f693          	andi	a3,a3,-1024
ffffffffc0201fdc:	068a                	slli	a3,a3,0x2
ffffffffc0201fde:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fe2:	06e7fc63          	bgeu	a5,a4,ffffffffc020205a <get_pte+0x1fc>
ffffffffc0201fe6:	0008b783          	ld	a5,0(a7)
ffffffffc0201fea:	8031                	srli	s0,s0,0xc
ffffffffc0201fec:	1ff47413          	andi	s0,s0,511
ffffffffc0201ff0:	040e                	slli	s0,s0,0x3
ffffffffc0201ff2:	96be                	add	a3,a3,a5
}
ffffffffc0201ff4:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ff6:	00868533          	add	a0,a3,s0
}
ffffffffc0201ffa:	7442                	ld	s0,48(sp)
ffffffffc0201ffc:	74a2                	ld	s1,40(sp)
ffffffffc0201ffe:	6121                	addi	sp,sp,64
ffffffffc0202000:	8082                	ret
ffffffffc0202002:	70e2                	ld	ra,56(sp)
ffffffffc0202004:	7442                	ld	s0,48(sp)
ffffffffc0202006:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202008:	4501                	li	a0,0
}
ffffffffc020200a:	6121                	addi	sp,sp,64
ffffffffc020200c:	8082                	ret
        intr_disable();
ffffffffc020200e:	e83a                	sd	a4,16(sp)
ffffffffc0202010:	ec32                	sd	a2,24(sp)
ffffffffc0202012:	8edfe0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202016:	000b3797          	auipc	a5,0xb3
ffffffffc020201a:	6f27b783          	ld	a5,1778(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc020201e:	4505                	li	a0,1
ffffffffc0202020:	6f9c                	ld	a5,24(a5)
ffffffffc0202022:	9782                	jalr	a5
ffffffffc0202024:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202026:	8d3fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020202a:	6862                	ld	a6,24(sp)
ffffffffc020202c:	6742                	ld	a4,16(sp)
ffffffffc020202e:	67a2                	ld	a5,8(sp)
ffffffffc0202030:	bdbd                	j	ffffffffc0201eae <get_pte+0x50>
        intr_disable();
ffffffffc0202032:	e83e                	sd	a5,16(sp)
ffffffffc0202034:	8cbfe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202038:	000b3717          	auipc	a4,0xb3
ffffffffc020203c:	6d073703          	ld	a4,1744(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202040:	4505                	li	a0,1
ffffffffc0202042:	6f18                	ld	a4,24(a4)
ffffffffc0202044:	9702                	jalr	a4
ffffffffc0202046:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202048:	8b1fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020204c:	6722                	ld	a4,8(sp)
ffffffffc020204e:	67c2                	ld	a5,16(sp)
ffffffffc0202050:	000b3897          	auipc	a7,0xb3
ffffffffc0202054:	6d088893          	addi	a7,a7,1744 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0202058:	bf31                	j	ffffffffc0201f74 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020205a:	00004617          	auipc	a2,0x4
ffffffffc020205e:	5ee60613          	addi	a2,a2,1518 # ffffffffc0206648 <etext+0xd86>
ffffffffc0202062:	0fa00593          	li	a1,250
ffffffffc0202066:	00004517          	auipc	a0,0x4
ffffffffc020206a:	6d250513          	addi	a0,a0,1746 # ffffffffc0206738 <etext+0xe76>
ffffffffc020206e:	bdcfe0ef          	jal	ffffffffc020044a <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202072:	00004617          	auipc	a2,0x4
ffffffffc0202076:	5d660613          	addi	a2,a2,1494 # ffffffffc0206648 <etext+0xd86>
ffffffffc020207a:	0ed00593          	li	a1,237
ffffffffc020207e:	00004517          	auipc	a0,0x4
ffffffffc0202082:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202086:	bc4fe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020208a:	86aa                	mv	a3,a0
ffffffffc020208c:	00004617          	auipc	a2,0x4
ffffffffc0202090:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206648 <etext+0xd86>
ffffffffc0202094:	0e900593          	li	a1,233
ffffffffc0202098:	00004517          	auipc	a0,0x4
ffffffffc020209c:	6a050513          	addi	a0,a0,1696 # ffffffffc0206738 <etext+0xe76>
ffffffffc02020a0:	baafe0ef          	jal	ffffffffc020044a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020a4:	00004617          	auipc	a2,0x4
ffffffffc02020a8:	5a460613          	addi	a2,a2,1444 # ffffffffc0206648 <etext+0xd86>
ffffffffc02020ac:	0f700593          	li	a1,247
ffffffffc02020b0:	00004517          	auipc	a0,0x4
ffffffffc02020b4:	68850513          	addi	a0,a0,1672 # ffffffffc0206738 <etext+0xe76>
ffffffffc02020b8:	b92fe0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02020bc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02020bc:	1141                	addi	sp,sp,-16
ffffffffc02020be:	e022                	sd	s0,0(sp)
ffffffffc02020c0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020c2:	4601                	li	a2,0
{
ffffffffc02020c4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020c6:	d99ff0ef          	jal	ffffffffc0201e5e <get_pte>
    if (ptep_store != NULL)
ffffffffc02020ca:	c011                	beqz	s0,ffffffffc02020ce <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02020cc:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020ce:	c511                	beqz	a0,ffffffffc02020da <get_page+0x1e>
ffffffffc02020d0:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02020d2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020d4:	0017f713          	andi	a4,a5,1
ffffffffc02020d8:	e709                	bnez	a4,ffffffffc02020e2 <get_page+0x26>
}
ffffffffc02020da:	60a2                	ld	ra,8(sp)
ffffffffc02020dc:	6402                	ld	s0,0(sp)
ffffffffc02020de:	0141                	addi	sp,sp,16
ffffffffc02020e0:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020e2:	000b3717          	auipc	a4,0xb3
ffffffffc02020e6:	64673703          	ld	a4,1606(a4) # ffffffffc02b5728 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020ea:	078a                	slli	a5,a5,0x2
ffffffffc02020ec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020ee:	00e7ff63          	bgeu	a5,a4,ffffffffc020210c <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02020f2:	000b3517          	auipc	a0,0xb3
ffffffffc02020f6:	63e53503          	ld	a0,1598(a0) # ffffffffc02b5730 <pages>
ffffffffc02020fa:	60a2                	ld	ra,8(sp)
ffffffffc02020fc:	6402                	ld	s0,0(sp)
ffffffffc02020fe:	079a                	slli	a5,a5,0x6
ffffffffc0202100:	fe000737          	lui	a4,0xfe000
ffffffffc0202104:	97ba                	add	a5,a5,a4
ffffffffc0202106:	953e                	add	a0,a0,a5
ffffffffc0202108:	0141                	addi	sp,sp,16
ffffffffc020210a:	8082                	ret
ffffffffc020210c:	c8fff0ef          	jal	ffffffffc0201d9a <pa2page.part.0>

ffffffffc0202110 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202110:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202112:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202116:	e486                	sd	ra,72(sp)
ffffffffc0202118:	e0a2                	sd	s0,64(sp)
ffffffffc020211a:	fc26                	sd	s1,56(sp)
ffffffffc020211c:	f84a                	sd	s2,48(sp)
ffffffffc020211e:	f44e                	sd	s3,40(sp)
ffffffffc0202120:	f052                	sd	s4,32(sp)
ffffffffc0202122:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202124:	03479713          	slli	a4,a5,0x34
ffffffffc0202128:	ef61                	bnez	a4,ffffffffc0202200 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc020212a:	00200a37          	lui	s4,0x200
ffffffffc020212e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202132:	0145b733          	sltu	a4,a1,s4
ffffffffc0202136:	0017b793          	seqz	a5,a5
ffffffffc020213a:	8fd9                	or	a5,a5,a4
ffffffffc020213c:	842e                	mv	s0,a1
ffffffffc020213e:	84b2                	mv	s1,a2
ffffffffc0202140:	e3e5                	bnez	a5,ffffffffc0202220 <unmap_range+0x110>
ffffffffc0202142:	4785                	li	a5,1
ffffffffc0202144:	07fe                	slli	a5,a5,0x1f
ffffffffc0202146:	0785                	addi	a5,a5,1
ffffffffc0202148:	892a                	mv	s2,a0
ffffffffc020214a:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020214c:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202150:	0cf67863          	bgeu	a2,a5,ffffffffc0202220 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202154:	4601                	li	a2,0
ffffffffc0202156:	85a2                	mv	a1,s0
ffffffffc0202158:	854a                	mv	a0,s2
ffffffffc020215a:	d05ff0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc020215e:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202160:	cd31                	beqz	a0,ffffffffc02021bc <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc0202162:	6118                	ld	a4,0(a0)
ffffffffc0202164:	ef11                	bnez	a4,ffffffffc0202180 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202166:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202168:	c019                	beqz	s0,ffffffffc020216e <unmap_range+0x5e>
ffffffffc020216a:	fe9465e3          	bltu	s0,s1,ffffffffc0202154 <unmap_range+0x44>
}
ffffffffc020216e:	60a6                	ld	ra,72(sp)
ffffffffc0202170:	6406                	ld	s0,64(sp)
ffffffffc0202172:	74e2                	ld	s1,56(sp)
ffffffffc0202174:	7942                	ld	s2,48(sp)
ffffffffc0202176:	79a2                	ld	s3,40(sp)
ffffffffc0202178:	7a02                	ld	s4,32(sp)
ffffffffc020217a:	6ae2                	ld	s5,24(sp)
ffffffffc020217c:	6161                	addi	sp,sp,80
ffffffffc020217e:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202180:	00177693          	andi	a3,a4,1
ffffffffc0202184:	d2ed                	beqz	a3,ffffffffc0202166 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc0202186:	000b3697          	auipc	a3,0xb3
ffffffffc020218a:	5a26b683          	ld	a3,1442(a3) # ffffffffc02b5728 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020218e:	070a                	slli	a4,a4,0x2
ffffffffc0202190:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202192:	0ad77763          	bgeu	a4,a3,ffffffffc0202240 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc0202196:	000b3517          	auipc	a0,0xb3
ffffffffc020219a:	59a53503          	ld	a0,1434(a0) # ffffffffc02b5730 <pages>
ffffffffc020219e:	071a                	slli	a4,a4,0x6
ffffffffc02021a0:	fe0006b7          	lui	a3,0xfe000
ffffffffc02021a4:	9736                	add	a4,a4,a3
ffffffffc02021a6:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02021a8:	4118                	lw	a4,0(a0)
ffffffffc02021aa:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd4a897>
ffffffffc02021ac:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02021ae:	cb19                	beqz	a4,ffffffffc02021c4 <unmap_range+0xb4>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02021b0:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02021b4:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02021b8:	944e                	add	s0,s0,s3
ffffffffc02021ba:	b77d                	j	ffffffffc0202168 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021bc:	9452                	add	s0,s0,s4
ffffffffc02021be:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02021c2:	b75d                	j	ffffffffc0202168 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021c4:	10002773          	csrr	a4,sstatus
ffffffffc02021c8:	8b09                	andi	a4,a4,2
ffffffffc02021ca:	eb19                	bnez	a4,ffffffffc02021e0 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02021cc:	000b3717          	auipc	a4,0xb3
ffffffffc02021d0:	53c73703          	ld	a4,1340(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc02021d4:	4585                	li	a1,1
ffffffffc02021d6:	e03e                	sd	a5,0(sp)
ffffffffc02021d8:	7318                	ld	a4,32(a4)
ffffffffc02021da:	9702                	jalr	a4
    if (flag)
ffffffffc02021dc:	6782                	ld	a5,0(sp)
ffffffffc02021de:	bfc9                	j	ffffffffc02021b0 <unmap_range+0xa0>
        intr_disable();
ffffffffc02021e0:	e43e                	sd	a5,8(sp)
ffffffffc02021e2:	e02a                	sd	a0,0(sp)
ffffffffc02021e4:	f1afe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc02021e8:	000b3717          	auipc	a4,0xb3
ffffffffc02021ec:	52073703          	ld	a4,1312(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc02021f0:	6502                	ld	a0,0(sp)
ffffffffc02021f2:	4585                	li	a1,1
ffffffffc02021f4:	7318                	ld	a4,32(a4)
ffffffffc02021f6:	9702                	jalr	a4
        intr_enable();
ffffffffc02021f8:	f00fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02021fc:	67a2                	ld	a5,8(sp)
ffffffffc02021fe:	bf4d                	j	ffffffffc02021b0 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202200:	00004697          	auipc	a3,0x4
ffffffffc0202204:	54868693          	addi	a3,a3,1352 # ffffffffc0206748 <etext+0xe86>
ffffffffc0202208:	00004617          	auipc	a2,0x4
ffffffffc020220c:	09060613          	addi	a2,a2,144 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202210:	12200593          	li	a1,290
ffffffffc0202214:	00004517          	auipc	a0,0x4
ffffffffc0202218:	52450513          	addi	a0,a0,1316 # ffffffffc0206738 <etext+0xe76>
ffffffffc020221c:	a2efe0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202220:	00004697          	auipc	a3,0x4
ffffffffc0202224:	55868693          	addi	a3,a3,1368 # ffffffffc0206778 <etext+0xeb6>
ffffffffc0202228:	00004617          	auipc	a2,0x4
ffffffffc020222c:	07060613          	addi	a2,a2,112 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202230:	12300593          	li	a1,291
ffffffffc0202234:	00004517          	auipc	a0,0x4
ffffffffc0202238:	50450513          	addi	a0,a0,1284 # ffffffffc0206738 <etext+0xe76>
ffffffffc020223c:	a0efe0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202240:	b5bff0ef          	jal	ffffffffc0201d9a <pa2page.part.0>

ffffffffc0202244 <exit_range>:
{
ffffffffc0202244:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202246:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020224a:	ed06                	sd	ra,152(sp)
ffffffffc020224c:	e922                	sd	s0,144(sp)
ffffffffc020224e:	e526                	sd	s1,136(sp)
ffffffffc0202250:	e14a                	sd	s2,128(sp)
ffffffffc0202252:	fcce                	sd	s3,120(sp)
ffffffffc0202254:	f8d2                	sd	s4,112(sp)
ffffffffc0202256:	f4d6                	sd	s5,104(sp)
ffffffffc0202258:	f0da                	sd	s6,96(sp)
ffffffffc020225a:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020225c:	17d2                	slli	a5,a5,0x34
ffffffffc020225e:	22079263          	bnez	a5,ffffffffc0202482 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc0202262:	00200937          	lui	s2,0x200
ffffffffc0202266:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020226a:	0125b733          	sltu	a4,a1,s2
ffffffffc020226e:	0017b793          	seqz	a5,a5
ffffffffc0202272:	8fd9                	or	a5,a5,a4
ffffffffc0202274:	26079263          	bnez	a5,ffffffffc02024d8 <exit_range+0x294>
ffffffffc0202278:	4785                	li	a5,1
ffffffffc020227a:	07fe                	slli	a5,a5,0x1f
ffffffffc020227c:	0785                	addi	a5,a5,1
ffffffffc020227e:	24f67d63          	bgeu	a2,a5,ffffffffc02024d8 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202282:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202286:	ffe007b7          	lui	a5,0xffe00
ffffffffc020228a:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020228c:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020228e:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc0202292:	000b3a97          	auipc	s5,0xb3
ffffffffc0202296:	496a8a93          	addi	s5,s5,1174 # ffffffffc02b5728 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020229a:	400009b7          	lui	s3,0x40000
ffffffffc020229e:	a809                	j	ffffffffc02022b0 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02022a0:	013487b3          	add	a5,s1,s3
ffffffffc02022a4:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02022a8:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02022aa:	c3f1                	beqz	a5,ffffffffc020236e <exit_range+0x12a>
ffffffffc02022ac:	0cc7f163          	bgeu	a5,a2,ffffffffc020236e <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022b0:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02022b4:	1ff47413          	andi	s0,s0,511
ffffffffc02022b8:	040e                	slli	s0,s0,0x3
ffffffffc02022ba:	9452                	add	s0,s0,s4
ffffffffc02022bc:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02022c0:	0018f793          	andi	a5,a7,1
ffffffffc02022c4:	dff1                	beqz	a5,ffffffffc02022a0 <exit_range+0x5c>
ffffffffc02022c6:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022ca:	088a                	slli	a7,a7,0x2
ffffffffc02022cc:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02022d0:	20f8f263          	bgeu	a7,a5,ffffffffc02024d4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02022d4:	fff802b7          	lui	t0,0xfff80
ffffffffc02022d8:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02022dc:	000803b7          	lui	t2,0x80
ffffffffc02022e0:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02022e4:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02022e8:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02022ea:	1cf77863          	bgeu	a4,a5,ffffffffc02024ba <exit_range+0x276>
ffffffffc02022ee:	000b3f97          	auipc	t6,0xb3
ffffffffc02022f2:	432f8f93          	addi	t6,t6,1074 # ffffffffc02b5720 <va_pa_offset>
ffffffffc02022f6:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02022fa:	4e85                	li	t4,1
ffffffffc02022fc:	6b05                	lui	s6,0x1
ffffffffc02022fe:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202300:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202304:	01585713          	srli	a4,a6,0x15
ffffffffc0202308:	1ff77713          	andi	a4,a4,511
ffffffffc020230c:	070e                	slli	a4,a4,0x3
ffffffffc020230e:	9772                	add	a4,a4,t3
ffffffffc0202310:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc0202312:	0017f693          	andi	a3,a5,1
ffffffffc0202316:	e6bd                	bnez	a3,ffffffffc0202384 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202318:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc020231a:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020231c:	00080863          	beqz	a6,ffffffffc020232c <exit_range+0xe8>
ffffffffc0202320:	879a                	mv	a5,t1
ffffffffc0202322:	00667363          	bgeu	a2,t1,ffffffffc0202328 <exit_range+0xe4>
ffffffffc0202326:	87b2                	mv	a5,a2
ffffffffc0202328:	fcf86ee3          	bltu	a6,a5,ffffffffc0202304 <exit_range+0xc0>
            if (free_pd0)
ffffffffc020232c:	f60e8ae3          	beqz	t4,ffffffffc02022a0 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202330:	000ab783          	ld	a5,0(s5)
ffffffffc0202334:	1af8f063          	bgeu	a7,a5,ffffffffc02024d4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202338:	000b3517          	auipc	a0,0xb3
ffffffffc020233c:	3f853503          	ld	a0,1016(a0) # ffffffffc02b5730 <pages>
ffffffffc0202340:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202342:	100027f3          	csrr	a5,sstatus
ffffffffc0202346:	8b89                	andi	a5,a5,2
ffffffffc0202348:	10079b63          	bnez	a5,ffffffffc020245e <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc020234c:	000b3797          	auipc	a5,0xb3
ffffffffc0202350:	3bc7b783          	ld	a5,956(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202354:	4585                	li	a1,1
ffffffffc0202356:	e432                	sd	a2,8(sp)
ffffffffc0202358:	739c                	ld	a5,32(a5)
ffffffffc020235a:	9782                	jalr	a5
ffffffffc020235c:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020235e:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc0202362:	013487b3          	add	a5,s1,s3
ffffffffc0202366:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020236a:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc020236c:	f3a1                	bnez	a5,ffffffffc02022ac <exit_range+0x68>
}
ffffffffc020236e:	60ea                	ld	ra,152(sp)
ffffffffc0202370:	644a                	ld	s0,144(sp)
ffffffffc0202372:	64aa                	ld	s1,136(sp)
ffffffffc0202374:	690a                	ld	s2,128(sp)
ffffffffc0202376:	79e6                	ld	s3,120(sp)
ffffffffc0202378:	7a46                	ld	s4,112(sp)
ffffffffc020237a:	7aa6                	ld	s5,104(sp)
ffffffffc020237c:	7b06                	ld	s6,96(sp)
ffffffffc020237e:	6be6                	ld	s7,88(sp)
ffffffffc0202380:	610d                	addi	sp,sp,160
ffffffffc0202382:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202384:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202388:	078a                	slli	a5,a5,0x2
ffffffffc020238a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020238c:	14a7f463          	bgeu	a5,a0,ffffffffc02024d4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202390:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc0202392:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc0202396:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020239a:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc020239e:	10abf263          	bgeu	s7,a0,ffffffffc02024a2 <exit_range+0x25e>
ffffffffc02023a2:	000fb783          	ld	a5,0(t6)
ffffffffc02023a6:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023a8:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02023ac:	629c                	ld	a5,0(a3)
ffffffffc02023ae:	8b85                	andi	a5,a5,1
ffffffffc02023b0:	f7ad                	bnez	a5,ffffffffc020231a <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023b2:	06a1                	addi	a3,a3,8
ffffffffc02023b4:	fea69ce3          	bne	a3,a0,ffffffffc02023ac <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b8:	000b3517          	auipc	a0,0xb3
ffffffffc02023bc:	37853503          	ld	a0,888(a0) # ffffffffc02b5730 <pages>
ffffffffc02023c0:	952e                	add	a0,a0,a1
ffffffffc02023c2:	100027f3          	csrr	a5,sstatus
ffffffffc02023c6:	8b89                	andi	a5,a5,2
ffffffffc02023c8:	e3b9                	bnez	a5,ffffffffc020240e <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02023ca:	000b3797          	auipc	a5,0xb3
ffffffffc02023ce:	33e7b783          	ld	a5,830(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc02023d2:	4585                	li	a1,1
ffffffffc02023d4:	e0b2                	sd	a2,64(sp)
ffffffffc02023d6:	739c                	ld	a5,32(a5)
ffffffffc02023d8:	fc1a                	sd	t1,56(sp)
ffffffffc02023da:	f846                	sd	a7,48(sp)
ffffffffc02023dc:	f47a                	sd	t5,40(sp)
ffffffffc02023de:	f072                	sd	t3,32(sp)
ffffffffc02023e0:	ec76                	sd	t4,24(sp)
ffffffffc02023e2:	e842                	sd	a6,16(sp)
ffffffffc02023e4:	e43a                	sd	a4,8(sp)
ffffffffc02023e6:	9782                	jalr	a5
    if (flag)
ffffffffc02023e8:	6722                	ld	a4,8(sp)
ffffffffc02023ea:	6842                	ld	a6,16(sp)
ffffffffc02023ec:	6ee2                	ld	t4,24(sp)
ffffffffc02023ee:	7e02                	ld	t3,32(sp)
ffffffffc02023f0:	7f22                	ld	t5,40(sp)
ffffffffc02023f2:	78c2                	ld	a7,48(sp)
ffffffffc02023f4:	7362                	ld	t1,56(sp)
ffffffffc02023f6:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023f8:	fff802b7          	lui	t0,0xfff80
ffffffffc02023fc:	000803b7          	lui	t2,0x80
ffffffffc0202400:	000b3f97          	auipc	t6,0xb3
ffffffffc0202404:	320f8f93          	addi	t6,t6,800 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0202408:	00073023          	sd	zero,0(a4)
ffffffffc020240c:	b739                	j	ffffffffc020231a <exit_range+0xd6>
        intr_disable();
ffffffffc020240e:	e4b2                	sd	a2,72(sp)
ffffffffc0202410:	e09a                	sd	t1,64(sp)
ffffffffc0202412:	fc46                	sd	a7,56(sp)
ffffffffc0202414:	f47a                	sd	t5,40(sp)
ffffffffc0202416:	f072                	sd	t3,32(sp)
ffffffffc0202418:	ec76                	sd	t4,24(sp)
ffffffffc020241a:	e842                	sd	a6,16(sp)
ffffffffc020241c:	e43a                	sd	a4,8(sp)
ffffffffc020241e:	f82a                	sd	a0,48(sp)
ffffffffc0202420:	cdefe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202424:	000b3797          	auipc	a5,0xb3
ffffffffc0202428:	2e47b783          	ld	a5,740(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc020242c:	7542                	ld	a0,48(sp)
ffffffffc020242e:	4585                	li	a1,1
ffffffffc0202430:	739c                	ld	a5,32(a5)
ffffffffc0202432:	9782                	jalr	a5
        intr_enable();
ffffffffc0202434:	cc4fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202438:	6722                	ld	a4,8(sp)
ffffffffc020243a:	6626                	ld	a2,72(sp)
ffffffffc020243c:	6306                	ld	t1,64(sp)
ffffffffc020243e:	78e2                	ld	a7,56(sp)
ffffffffc0202440:	7f22                	ld	t5,40(sp)
ffffffffc0202442:	7e02                	ld	t3,32(sp)
ffffffffc0202444:	6ee2                	ld	t4,24(sp)
ffffffffc0202446:	6842                	ld	a6,16(sp)
ffffffffc0202448:	000b3f97          	auipc	t6,0xb3
ffffffffc020244c:	2d8f8f93          	addi	t6,t6,728 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0202450:	000803b7          	lui	t2,0x80
ffffffffc0202454:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202458:	00073023          	sd	zero,0(a4)
ffffffffc020245c:	bd7d                	j	ffffffffc020231a <exit_range+0xd6>
        intr_disable();
ffffffffc020245e:	e832                	sd	a2,16(sp)
ffffffffc0202460:	e42a                	sd	a0,8(sp)
ffffffffc0202462:	c9cfe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202466:	000b3797          	auipc	a5,0xb3
ffffffffc020246a:	2a27b783          	ld	a5,674(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc020246e:	6522                	ld	a0,8(sp)
ffffffffc0202470:	4585                	li	a1,1
ffffffffc0202472:	739c                	ld	a5,32(a5)
ffffffffc0202474:	9782                	jalr	a5
        intr_enable();
ffffffffc0202476:	c82fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020247a:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020247c:	00043023          	sd	zero,0(s0)
ffffffffc0202480:	b5cd                	j	ffffffffc0202362 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202482:	00004697          	auipc	a3,0x4
ffffffffc0202486:	2c668693          	addi	a3,a3,710 # ffffffffc0206748 <etext+0xe86>
ffffffffc020248a:	00004617          	auipc	a2,0x4
ffffffffc020248e:	e0e60613          	addi	a2,a2,-498 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202492:	13700593          	li	a1,311
ffffffffc0202496:	00004517          	auipc	a0,0x4
ffffffffc020249a:	2a250513          	addi	a0,a0,674 # ffffffffc0206738 <etext+0xe76>
ffffffffc020249e:	fadfd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc02024a2:	00004617          	auipc	a2,0x4
ffffffffc02024a6:	1a660613          	addi	a2,a2,422 # ffffffffc0206648 <etext+0xd86>
ffffffffc02024aa:	07100593          	li	a1,113
ffffffffc02024ae:	00004517          	auipc	a0,0x4
ffffffffc02024b2:	1c250513          	addi	a0,a0,450 # ffffffffc0206670 <etext+0xdae>
ffffffffc02024b6:	f95fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024ba:	86f2                	mv	a3,t3
ffffffffc02024bc:	00004617          	auipc	a2,0x4
ffffffffc02024c0:	18c60613          	addi	a2,a2,396 # ffffffffc0206648 <etext+0xd86>
ffffffffc02024c4:	07100593          	li	a1,113
ffffffffc02024c8:	00004517          	auipc	a0,0x4
ffffffffc02024cc:	1a850513          	addi	a0,a0,424 # ffffffffc0206670 <etext+0xdae>
ffffffffc02024d0:	f7bfd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc02024d4:	8c7ff0ef          	jal	ffffffffc0201d9a <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02024d8:	00004697          	auipc	a3,0x4
ffffffffc02024dc:	2a068693          	addi	a3,a3,672 # ffffffffc0206778 <etext+0xeb6>
ffffffffc02024e0:	00004617          	auipc	a2,0x4
ffffffffc02024e4:	db860613          	addi	a2,a2,-584 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02024e8:	13800593          	li	a1,312
ffffffffc02024ec:	00004517          	auipc	a0,0x4
ffffffffc02024f0:	24c50513          	addi	a0,a0,588 # ffffffffc0206738 <etext+0xe76>
ffffffffc02024f4:	f57fd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02024f8 <page_remove>:
{
ffffffffc02024f8:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024fa:	4601                	li	a2,0
{
ffffffffc02024fc:	e822                	sd	s0,16(sp)
ffffffffc02024fe:	ec06                	sd	ra,24(sp)
ffffffffc0202500:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202502:	95dff0ef          	jal	ffffffffc0201e5e <get_pte>
    if (ptep != NULL)
ffffffffc0202506:	c511                	beqz	a0,ffffffffc0202512 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202508:	6118                	ld	a4,0(a0)
ffffffffc020250a:	87aa                	mv	a5,a0
ffffffffc020250c:	00177693          	andi	a3,a4,1
ffffffffc0202510:	e689                	bnez	a3,ffffffffc020251a <page_remove+0x22>
}
ffffffffc0202512:	60e2                	ld	ra,24(sp)
ffffffffc0202514:	6442                	ld	s0,16(sp)
ffffffffc0202516:	6105                	addi	sp,sp,32
ffffffffc0202518:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020251a:	000b3697          	auipc	a3,0xb3
ffffffffc020251e:	20e6b683          	ld	a3,526(a3) # ffffffffc02b5728 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202522:	070a                	slli	a4,a4,0x2
ffffffffc0202524:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202526:	06d77563          	bgeu	a4,a3,ffffffffc0202590 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020252a:	000b3517          	auipc	a0,0xb3
ffffffffc020252e:	20653503          	ld	a0,518(a0) # ffffffffc02b5730 <pages>
ffffffffc0202532:	071a                	slli	a4,a4,0x6
ffffffffc0202534:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202538:	9736                	add	a4,a4,a3
ffffffffc020253a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020253c:	4118                	lw	a4,0(a0)
ffffffffc020253e:	377d                	addiw	a4,a4,-1
ffffffffc0202540:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202542:	cb09                	beqz	a4,ffffffffc0202554 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202544:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202548:	12040073          	sfence.vma	s0
}
ffffffffc020254c:	60e2                	ld	ra,24(sp)
ffffffffc020254e:	6442                	ld	s0,16(sp)
ffffffffc0202550:	6105                	addi	sp,sp,32
ffffffffc0202552:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202554:	10002773          	csrr	a4,sstatus
ffffffffc0202558:	8b09                	andi	a4,a4,2
ffffffffc020255a:	eb19                	bnez	a4,ffffffffc0202570 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc020255c:	000b3717          	auipc	a4,0xb3
ffffffffc0202560:	1ac73703          	ld	a4,428(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202564:	4585                	li	a1,1
ffffffffc0202566:	e03e                	sd	a5,0(sp)
ffffffffc0202568:	7318                	ld	a4,32(a4)
ffffffffc020256a:	9702                	jalr	a4
    if (flag)
ffffffffc020256c:	6782                	ld	a5,0(sp)
ffffffffc020256e:	bfd9                	j	ffffffffc0202544 <page_remove+0x4c>
        intr_disable();
ffffffffc0202570:	e43e                	sd	a5,8(sp)
ffffffffc0202572:	e02a                	sd	a0,0(sp)
ffffffffc0202574:	b8afe0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202578:	000b3717          	auipc	a4,0xb3
ffffffffc020257c:	19073703          	ld	a4,400(a4) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202580:	6502                	ld	a0,0(sp)
ffffffffc0202582:	4585                	li	a1,1
ffffffffc0202584:	7318                	ld	a4,32(a4)
ffffffffc0202586:	9702                	jalr	a4
        intr_enable();
ffffffffc0202588:	b70fe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc020258c:	67a2                	ld	a5,8(sp)
ffffffffc020258e:	bf5d                	j	ffffffffc0202544 <page_remove+0x4c>
ffffffffc0202590:	80bff0ef          	jal	ffffffffc0201d9a <pa2page.part.0>

ffffffffc0202594 <page_insert>:
{
ffffffffc0202594:	7139                	addi	sp,sp,-64
ffffffffc0202596:	f426                	sd	s1,40(sp)
ffffffffc0202598:	84b2                	mv	s1,a2
ffffffffc020259a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020259c:	4605                	li	a2,1
{
ffffffffc020259e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025a0:	85a6                	mv	a1,s1
{
ffffffffc02025a2:	fc06                	sd	ra,56(sp)
ffffffffc02025a4:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025a6:	8b9ff0ef          	jal	ffffffffc0201e5e <get_pte>
    if (ptep == NULL)
ffffffffc02025aa:	cd61                	beqz	a0,ffffffffc0202682 <page_insert+0xee>
    page->ref += 1;
ffffffffc02025ac:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc02025ae:	611c                	ld	a5,0(a0)
ffffffffc02025b0:	66a2                	ld	a3,8(sp)
ffffffffc02025b2:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7f3f>
ffffffffc02025b6:	c010                	sw	a2,0(s0)
ffffffffc02025b8:	0017f613          	andi	a2,a5,1
ffffffffc02025bc:	872a                	mv	a4,a0
ffffffffc02025be:	e61d                	bnez	a2,ffffffffc02025ec <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c0:	000b3617          	auipc	a2,0xb3
ffffffffc02025c4:	17063603          	ld	a2,368(a2) # ffffffffc02b5730 <pages>
    return page - pages + nbase;
ffffffffc02025c8:	8c11                	sub	s0,s0,a2
ffffffffc02025ca:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025cc:	200007b7          	lui	a5,0x20000
ffffffffc02025d0:	042a                	slli	s0,s0,0xa
ffffffffc02025d2:	943e                	add	s0,s0,a5
ffffffffc02025d4:	8ec1                	or	a3,a3,s0
ffffffffc02025d6:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02025da:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025dc:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02025e0:	4501                	li	a0,0
}
ffffffffc02025e2:	70e2                	ld	ra,56(sp)
ffffffffc02025e4:	7442                	ld	s0,48(sp)
ffffffffc02025e6:	74a2                	ld	s1,40(sp)
ffffffffc02025e8:	6121                	addi	sp,sp,64
ffffffffc02025ea:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025ec:	000b3617          	auipc	a2,0xb3
ffffffffc02025f0:	13c63603          	ld	a2,316(a2) # ffffffffc02b5728 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02025f4:	078a                	slli	a5,a5,0x2
ffffffffc02025f6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025f8:	08c7f763          	bgeu	a5,a2,ffffffffc0202686 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02025fc:	000b3617          	auipc	a2,0xb3
ffffffffc0202600:	13463603          	ld	a2,308(a2) # ffffffffc02b5730 <pages>
ffffffffc0202604:	fe000537          	lui	a0,0xfe000
ffffffffc0202608:	079a                	slli	a5,a5,0x6
ffffffffc020260a:	97aa                	add	a5,a5,a0
ffffffffc020260c:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc0202610:	00a40963          	beq	s0,a0,ffffffffc0202622 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc0202614:	411c                	lw	a5,0(a0)
ffffffffc0202616:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_matrix_out_size+0x1fff4abf>
ffffffffc0202618:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc020261a:	c791                	beqz	a5,ffffffffc0202626 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020261c:	12048073          	sfence.vma	s1
}
ffffffffc0202620:	b765                	j	ffffffffc02025c8 <page_insert+0x34>
ffffffffc0202622:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202624:	b755                	j	ffffffffc02025c8 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202626:	100027f3          	csrr	a5,sstatus
ffffffffc020262a:	8b89                	andi	a5,a5,2
ffffffffc020262c:	e39d                	bnez	a5,ffffffffc0202652 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020262e:	000b3797          	auipc	a5,0xb3
ffffffffc0202632:	0da7b783          	ld	a5,218(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202636:	4585                	li	a1,1
ffffffffc0202638:	e83a                	sd	a4,16(sp)
ffffffffc020263a:	739c                	ld	a5,32(a5)
ffffffffc020263c:	e436                	sd	a3,8(sp)
ffffffffc020263e:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202640:	000b3617          	auipc	a2,0xb3
ffffffffc0202644:	0f063603          	ld	a2,240(a2) # ffffffffc02b5730 <pages>
ffffffffc0202648:	66a2                	ld	a3,8(sp)
ffffffffc020264a:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020264c:	12048073          	sfence.vma	s1
ffffffffc0202650:	bfa5                	j	ffffffffc02025c8 <page_insert+0x34>
        intr_disable();
ffffffffc0202652:	ec3a                	sd	a4,24(sp)
ffffffffc0202654:	e836                	sd	a3,16(sp)
ffffffffc0202656:	e42a                	sd	a0,8(sp)
ffffffffc0202658:	aa6fe0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020265c:	000b3797          	auipc	a5,0xb3
ffffffffc0202660:	0ac7b783          	ld	a5,172(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc0202664:	6522                	ld	a0,8(sp)
ffffffffc0202666:	4585                	li	a1,1
ffffffffc0202668:	739c                	ld	a5,32(a5)
ffffffffc020266a:	9782                	jalr	a5
        intr_enable();
ffffffffc020266c:	a8cfe0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202670:	000b3617          	auipc	a2,0xb3
ffffffffc0202674:	0c063603          	ld	a2,192(a2) # ffffffffc02b5730 <pages>
ffffffffc0202678:	6762                	ld	a4,24(sp)
ffffffffc020267a:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020267c:	12048073          	sfence.vma	s1
ffffffffc0202680:	b7a1                	j	ffffffffc02025c8 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202682:	5571                	li	a0,-4
ffffffffc0202684:	bfb9                	j	ffffffffc02025e2 <page_insert+0x4e>
ffffffffc0202686:	f14ff0ef          	jal	ffffffffc0201d9a <pa2page.part.0>

ffffffffc020268a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020268a:	00005797          	auipc	a5,0x5
ffffffffc020268e:	05678793          	addi	a5,a5,86 # ffffffffc02076e0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202692:	638c                	ld	a1,0(a5)
{
ffffffffc0202694:	7159                	addi	sp,sp,-112
ffffffffc0202696:	f486                	sd	ra,104(sp)
ffffffffc0202698:	e8ca                	sd	s2,80(sp)
ffffffffc020269a:	e4ce                	sd	s3,72(sp)
ffffffffc020269c:	f85a                	sd	s6,48(sp)
ffffffffc020269e:	f0a2                	sd	s0,96(sp)
ffffffffc02026a0:	eca6                	sd	s1,88(sp)
ffffffffc02026a2:	e0d2                	sd	s4,64(sp)
ffffffffc02026a4:	fc56                	sd	s5,56(sp)
ffffffffc02026a6:	f45e                	sd	s7,40(sp)
ffffffffc02026a8:	f062                	sd	s8,32(sp)
ffffffffc02026aa:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02026ac:	000b3b17          	auipc	s6,0xb3
ffffffffc02026b0:	05cb0b13          	addi	s6,s6,92 # ffffffffc02b5708 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026b4:	00004517          	auipc	a0,0x4
ffffffffc02026b8:	0dc50513          	addi	a0,a0,220 # ffffffffc0206790 <etext+0xece>
    pmm_manager = &default_pmm_manager;
ffffffffc02026bc:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026c0:	ad9fd0ef          	jal	ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc02026c4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026c8:	000b3997          	auipc	s3,0xb3
ffffffffc02026cc:	05898993          	addi	s3,s3,88 # ffffffffc02b5720 <va_pa_offset>
    pmm_manager->init();
ffffffffc02026d0:	679c                	ld	a5,8(a5)
ffffffffc02026d2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026d4:	57f5                	li	a5,-3
ffffffffc02026d6:	07fa                	slli	a5,a5,0x1e
ffffffffc02026d8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02026dc:	a08fe0ef          	jal	ffffffffc02008e4 <get_memory_base>
ffffffffc02026e0:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02026e2:	a0cfe0ef          	jal	ffffffffc02008ee <get_memory_size>
    if (mem_size == 0)
ffffffffc02026e6:	70050e63          	beqz	a0,ffffffffc0202e02 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026ea:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02026ec:	00004517          	auipc	a0,0x4
ffffffffc02026f0:	0dc50513          	addi	a0,a0,220 # ffffffffc02067c8 <etext+0xf06>
ffffffffc02026f4:	aa5fd0ef          	jal	ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026f8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02026fc:	864a                	mv	a2,s2
ffffffffc02026fe:	85a6                	mv	a1,s1
ffffffffc0202700:	fff40693          	addi	a3,s0,-1
ffffffffc0202704:	00004517          	auipc	a0,0x4
ffffffffc0202708:	0dc50513          	addi	a0,a0,220 # ffffffffc02067e0 <etext+0xf1e>
ffffffffc020270c:	a8dfd0ef          	jal	ffffffffc0200198 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202710:	c80007b7          	lui	a5,0xc8000
ffffffffc0202714:	8522                	mv	a0,s0
ffffffffc0202716:	5287ed63          	bltu	a5,s0,ffffffffc0202c50 <pmm_init+0x5c6>
ffffffffc020271a:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020271c:	000b4617          	auipc	a2,0xb4
ffffffffc0202720:	04b60613          	addi	a2,a2,75 # ffffffffc02b6767 <end+0xfff>
ffffffffc0202724:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202726:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202728:	000b3b97          	auipc	s7,0xb3
ffffffffc020272c:	008b8b93          	addi	s7,s7,8 # ffffffffc02b5730 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202730:	000b3497          	auipc	s1,0xb3
ffffffffc0202734:	ff848493          	addi	s1,s1,-8 # ffffffffc02b5728 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202738:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc020273c:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020273e:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202742:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202744:	02f50763          	beq	a0,a5,ffffffffc0202772 <pmm_init+0xe8>
ffffffffc0202748:	4701                	li	a4,0
ffffffffc020274a:	4585                	li	a1,1
ffffffffc020274c:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202750:	00671793          	slli	a5,a4,0x6
ffffffffc0202754:	97b2                	add	a5,a5,a2
ffffffffc0202756:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_matrix_out_size+0x74ac8>
ffffffffc0202758:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020275c:	6088                	ld	a0,0(s1)
ffffffffc020275e:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202760:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202764:	00d507b3          	add	a5,a0,a3
ffffffffc0202768:	fef764e3          	bltu	a4,a5,ffffffffc0202750 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020276c:	079a                	slli	a5,a5,0x6
ffffffffc020276e:	00f606b3          	add	a3,a2,a5
ffffffffc0202772:	c02007b7          	lui	a5,0xc0200
ffffffffc0202776:	16f6eee3          	bltu	a3,a5,ffffffffc02030f2 <pmm_init+0xa68>
ffffffffc020277a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020277e:	77fd                	lui	a5,0xfffff
ffffffffc0202780:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202782:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202784:	4e86ed63          	bltu	a3,s0,ffffffffc0202c7e <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202788:	00004517          	auipc	a0,0x4
ffffffffc020278c:	08050513          	addi	a0,a0,128 # ffffffffc0206808 <etext+0xf46>
ffffffffc0202790:	a09fd0ef          	jal	ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202794:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202798:	000b3917          	auipc	s2,0xb3
ffffffffc020279c:	f8090913          	addi	s2,s2,-128 # ffffffffc02b5718 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02027a0:	7b9c                	ld	a5,48(a5)
ffffffffc02027a2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02027a4:	00004517          	auipc	a0,0x4
ffffffffc02027a8:	07c50513          	addi	a0,a0,124 # ffffffffc0206820 <etext+0xf5e>
ffffffffc02027ac:	9edfd0ef          	jal	ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027b0:	00009697          	auipc	a3,0x9
ffffffffc02027b4:	85068693          	addi	a3,a3,-1968 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02027b8:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02027bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02027c0:	2af6eee3          	bltu	a3,a5,ffffffffc020327c <pmm_init+0xbf2>
ffffffffc02027c4:	0009b783          	ld	a5,0(s3)
ffffffffc02027c8:	8e9d                	sub	a3,a3,a5
ffffffffc02027ca:	000b3797          	auipc	a5,0xb3
ffffffffc02027ce:	f4d7b323          	sd	a3,-186(a5) # ffffffffc02b5710 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027d2:	100027f3          	csrr	a5,sstatus
ffffffffc02027d6:	8b89                	andi	a5,a5,2
ffffffffc02027d8:	48079963          	bnez	a5,ffffffffc0202c6a <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027dc:	000b3783          	ld	a5,0(s6)
ffffffffc02027e0:	779c                	ld	a5,40(a5)
ffffffffc02027e2:	9782                	jalr	a5
ffffffffc02027e4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027e6:	6098                	ld	a4,0(s1)
ffffffffc02027e8:	c80007b7          	lui	a5,0xc8000
ffffffffc02027ec:	83b1                	srli	a5,a5,0xc
ffffffffc02027ee:	66e7e663          	bltu	a5,a4,ffffffffc0202e5a <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02027f2:	00093503          	ld	a0,0(s2)
ffffffffc02027f6:	64050263          	beqz	a0,ffffffffc0202e3a <pmm_init+0x7b0>
ffffffffc02027fa:	03451793          	slli	a5,a0,0x34
ffffffffc02027fe:	62079e63          	bnez	a5,ffffffffc0202e3a <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202802:	4601                	li	a2,0
ffffffffc0202804:	4581                	li	a1,0
ffffffffc0202806:	8b7ff0ef          	jal	ffffffffc02020bc <get_page>
ffffffffc020280a:	240519e3          	bnez	a0,ffffffffc020325c <pmm_init+0xbd2>
ffffffffc020280e:	100027f3          	csrr	a5,sstatus
ffffffffc0202812:	8b89                	andi	a5,a5,2
ffffffffc0202814:	44079063          	bnez	a5,ffffffffc0202c54 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202818:	000b3783          	ld	a5,0(s6)
ffffffffc020281c:	4505                	li	a0,1
ffffffffc020281e:	6f9c                	ld	a5,24(a5)
ffffffffc0202820:	9782                	jalr	a5
ffffffffc0202822:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202824:	00093503          	ld	a0,0(s2)
ffffffffc0202828:	4681                	li	a3,0
ffffffffc020282a:	4601                	li	a2,0
ffffffffc020282c:	85d2                	mv	a1,s4
ffffffffc020282e:	d67ff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc0202832:	280511e3          	bnez	a0,ffffffffc02032b4 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202836:	00093503          	ld	a0,0(s2)
ffffffffc020283a:	4601                	li	a2,0
ffffffffc020283c:	4581                	li	a1,0
ffffffffc020283e:	e20ff0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc0202842:	240509e3          	beqz	a0,ffffffffc0203294 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202846:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202848:	0017f713          	andi	a4,a5,1
ffffffffc020284c:	58070f63          	beqz	a4,ffffffffc0202dea <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202850:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202852:	078a                	slli	a5,a5,0x2
ffffffffc0202854:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202856:	58e7f863          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020285a:	000bb683          	ld	a3,0(s7)
ffffffffc020285e:	079a                	slli	a5,a5,0x6
ffffffffc0202860:	fe000637          	lui	a2,0xfe000
ffffffffc0202864:	97b2                	add	a5,a5,a2
ffffffffc0202866:	97b6                	add	a5,a5,a3
ffffffffc0202868:	14fa1ae3          	bne	s4,a5,ffffffffc02031bc <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc020286c:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_matrix_out_size+0x1f4ac0>
ffffffffc0202870:	4785                	li	a5,1
ffffffffc0202872:	12f695e3          	bne	a3,a5,ffffffffc020319c <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202876:	00093503          	ld	a0,0(s2)
ffffffffc020287a:	77fd                	lui	a5,0xfffff
ffffffffc020287c:	6114                	ld	a3,0(a0)
ffffffffc020287e:	068a                	slli	a3,a3,0x2
ffffffffc0202880:	8efd                	and	a3,a3,a5
ffffffffc0202882:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202886:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203184 <pmm_init+0xafa>
ffffffffc020288a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020288e:	96e2                	add	a3,a3,s8
ffffffffc0202890:	0006ba83          	ld	s5,0(a3)
ffffffffc0202894:	0a8a                	slli	s5,s5,0x2
ffffffffc0202896:	00fafab3          	and	s5,s5,a5
ffffffffc020289a:	00cad793          	srli	a5,s5,0xc
ffffffffc020289e:	0ce7f6e3          	bgeu	a5,a4,ffffffffc020316a <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028a2:	4601                	li	a2,0
ffffffffc02028a4:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028a6:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028a8:	db6ff0ef          	jal	ffffffffc0201e5e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028ac:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028ae:	05851ee3          	bne	a0,s8,ffffffffc020310a <pmm_init+0xa80>
ffffffffc02028b2:	100027f3          	csrr	a5,sstatus
ffffffffc02028b6:	8b89                	andi	a5,a5,2
ffffffffc02028b8:	3e079b63          	bnez	a5,ffffffffc0202cae <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028bc:	000b3783          	ld	a5,0(s6)
ffffffffc02028c0:	4505                	li	a0,1
ffffffffc02028c2:	6f9c                	ld	a5,24(a5)
ffffffffc02028c4:	9782                	jalr	a5
ffffffffc02028c6:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02028c8:	00093503          	ld	a0,0(s2)
ffffffffc02028cc:	46d1                	li	a3,20
ffffffffc02028ce:	6605                	lui	a2,0x1
ffffffffc02028d0:	85e2                	mv	a1,s8
ffffffffc02028d2:	cc3ff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc02028d6:	06051ae3          	bnez	a0,ffffffffc020314a <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028da:	00093503          	ld	a0,0(s2)
ffffffffc02028de:	4601                	li	a2,0
ffffffffc02028e0:	6585                	lui	a1,0x1
ffffffffc02028e2:	d7cff0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc02028e6:	040502e3          	beqz	a0,ffffffffc020312a <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02028ea:	611c                	ld	a5,0(a0)
ffffffffc02028ec:	0107f713          	andi	a4,a5,16
ffffffffc02028f0:	7e070163          	beqz	a4,ffffffffc02030d2 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02028f4:	8b91                	andi	a5,a5,4
ffffffffc02028f6:	7a078e63          	beqz	a5,ffffffffc02030b2 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02028fa:	00093503          	ld	a0,0(s2)
ffffffffc02028fe:	611c                	ld	a5,0(a0)
ffffffffc0202900:	8bc1                	andi	a5,a5,16
ffffffffc0202902:	78078863          	beqz	a5,ffffffffc0203092 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202906:	000c2703          	lw	a4,0(s8)
ffffffffc020290a:	4785                	li	a5,1
ffffffffc020290c:	76f71363          	bne	a4,a5,ffffffffc0203072 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202910:	4681                	li	a3,0
ffffffffc0202912:	6605                	lui	a2,0x1
ffffffffc0202914:	85d2                	mv	a1,s4
ffffffffc0202916:	c7fff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc020291a:	72051c63          	bnez	a0,ffffffffc0203052 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc020291e:	000a2703          	lw	a4,0(s4)
ffffffffc0202922:	4789                	li	a5,2
ffffffffc0202924:	70f71763          	bne	a4,a5,ffffffffc0203032 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202928:	000c2783          	lw	a5,0(s8)
ffffffffc020292c:	6e079363          	bnez	a5,ffffffffc0203012 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202930:	00093503          	ld	a0,0(s2)
ffffffffc0202934:	4601                	li	a2,0
ffffffffc0202936:	6585                	lui	a1,0x1
ffffffffc0202938:	d26ff0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc020293c:	6a050b63          	beqz	a0,ffffffffc0202ff2 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202940:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202942:	00177793          	andi	a5,a4,1
ffffffffc0202946:	4a078263          	beqz	a5,ffffffffc0202dea <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020294a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020294c:	00271793          	slli	a5,a4,0x2
ffffffffc0202950:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202952:	48d7fa63          	bgeu	a5,a3,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202956:	000bb683          	ld	a3,0(s7)
ffffffffc020295a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020295e:	97d6                	add	a5,a5,s5
ffffffffc0202960:	079a                	slli	a5,a5,0x6
ffffffffc0202962:	97b6                	add	a5,a5,a3
ffffffffc0202964:	66fa1763          	bne	s4,a5,ffffffffc0202fd2 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202968:	8b41                	andi	a4,a4,16
ffffffffc020296a:	64071463          	bnez	a4,ffffffffc0202fb2 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020296e:	00093503          	ld	a0,0(s2)
ffffffffc0202972:	4581                	li	a1,0
ffffffffc0202974:	b85ff0ef          	jal	ffffffffc02024f8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202978:	000a2c83          	lw	s9,0(s4)
ffffffffc020297c:	4785                	li	a5,1
ffffffffc020297e:	60fc9a63          	bne	s9,a5,ffffffffc0202f92 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202982:	000c2783          	lw	a5,0(s8)
ffffffffc0202986:	5e079663          	bnez	a5,ffffffffc0202f72 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020298a:	00093503          	ld	a0,0(s2)
ffffffffc020298e:	6585                	lui	a1,0x1
ffffffffc0202990:	b69ff0ef          	jal	ffffffffc02024f8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202994:	000a2783          	lw	a5,0(s4)
ffffffffc0202998:	52079d63          	bnez	a5,ffffffffc0202ed2 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc020299c:	000c2783          	lw	a5,0(s8)
ffffffffc02029a0:	50079963          	bnez	a5,ffffffffc0202eb2 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02029a4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02029a8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029aa:	000a3783          	ld	a5,0(s4)
ffffffffc02029ae:	078a                	slli	a5,a5,0x2
ffffffffc02029b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029b2:	42e7fa63          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02029b6:	000bb503          	ld	a0,0(s7)
ffffffffc02029ba:	97d6                	add	a5,a5,s5
ffffffffc02029bc:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc02029be:	00f506b3          	add	a3,a0,a5
ffffffffc02029c2:	4294                	lw	a3,0(a3)
ffffffffc02029c4:	4d969763          	bne	a3,s9,ffffffffc0202e92 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc02029c8:	8799                	srai	a5,a5,0x6
ffffffffc02029ca:	00080637          	lui	a2,0x80
ffffffffc02029ce:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02029d0:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02029d4:	4ae7f363          	bgeu	a5,a4,ffffffffc0202e7a <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02029d8:	0009b783          	ld	a5,0(s3)
ffffffffc02029dc:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02029de:	639c                	ld	a5,0(a5)
ffffffffc02029e0:	078a                	slli	a5,a5,0x2
ffffffffc02029e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029e4:	40e7f163          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02029e8:	8f91                	sub	a5,a5,a2
ffffffffc02029ea:	079a                	slli	a5,a5,0x6
ffffffffc02029ec:	953e                	add	a0,a0,a5
ffffffffc02029ee:	100027f3          	csrr	a5,sstatus
ffffffffc02029f2:	8b89                	andi	a5,a5,2
ffffffffc02029f4:	30079863          	bnez	a5,ffffffffc0202d04 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc02029f8:	000b3783          	ld	a5,0(s6)
ffffffffc02029fc:	4585                	li	a1,1
ffffffffc02029fe:	739c                	ld	a5,32(a5)
ffffffffc0202a00:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a02:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a06:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a08:	078a                	slli	a5,a5,0x2
ffffffffc0202a0a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a0c:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a10:	000bb503          	ld	a0,0(s7)
ffffffffc0202a14:	fe000737          	lui	a4,0xfe000
ffffffffc0202a18:	079a                	slli	a5,a5,0x6
ffffffffc0202a1a:	97ba                	add	a5,a5,a4
ffffffffc0202a1c:	953e                	add	a0,a0,a5
ffffffffc0202a1e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a22:	8b89                	andi	a5,a5,2
ffffffffc0202a24:	2c079463          	bnez	a5,ffffffffc0202cec <pmm_init+0x662>
ffffffffc0202a28:	000b3783          	ld	a5,0(s6)
ffffffffc0202a2c:	4585                	li	a1,1
ffffffffc0202a2e:	739c                	ld	a5,32(a5)
ffffffffc0202a30:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202a32:	00093783          	ld	a5,0(s2)
ffffffffc0202a36:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49898>
    asm volatile("sfence.vma");
ffffffffc0202a3a:	12000073          	sfence.vma
ffffffffc0202a3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a42:	8b89                	andi	a5,a5,2
ffffffffc0202a44:	28079a63          	bnez	a5,ffffffffc0202cd8 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a48:	000b3783          	ld	a5,0(s6)
ffffffffc0202a4c:	779c                	ld	a5,40(a5)
ffffffffc0202a4e:	9782                	jalr	a5
ffffffffc0202a50:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202a52:	4d441063          	bne	s0,s4,ffffffffc0202f12 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202a56:	00004517          	auipc	a0,0x4
ffffffffc0202a5a:	11a50513          	addi	a0,a0,282 # ffffffffc0206b70 <etext+0x12ae>
ffffffffc0202a5e:	f3afd0ef          	jal	ffffffffc0200198 <cprintf>
ffffffffc0202a62:	100027f3          	csrr	a5,sstatus
ffffffffc0202a66:	8b89                	andi	a5,a5,2
ffffffffc0202a68:	24079e63          	bnez	a5,ffffffffc0202cc4 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a70:	779c                	ld	a5,40(a5)
ffffffffc0202a72:	9782                	jalr	a5
ffffffffc0202a74:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a76:	609c                	ld	a5,0(s1)
ffffffffc0202a78:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a7c:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a7e:	00c79713          	slli	a4,a5,0xc
ffffffffc0202a82:	6a85                	lui	s5,0x1
ffffffffc0202a84:	02e47c63          	bgeu	s0,a4,ffffffffc0202abc <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a88:	00c45713          	srli	a4,s0,0xc
ffffffffc0202a8c:	30f77063          	bgeu	a4,a5,ffffffffc0202d8c <pmm_init+0x702>
ffffffffc0202a90:	0009b583          	ld	a1,0(s3)
ffffffffc0202a94:	00093503          	ld	a0,0(s2)
ffffffffc0202a98:	4601                	li	a2,0
ffffffffc0202a9a:	95a2                	add	a1,a1,s0
ffffffffc0202a9c:	bc2ff0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc0202aa0:	32050363          	beqz	a0,ffffffffc0202dc6 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202aa4:	611c                	ld	a5,0(a0)
ffffffffc0202aa6:	078a                	slli	a5,a5,0x2
ffffffffc0202aa8:	0147f7b3          	and	a5,a5,s4
ffffffffc0202aac:	2e879d63          	bne	a5,s0,ffffffffc0202da6 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ab0:	609c                	ld	a5,0(s1)
ffffffffc0202ab2:	9456                	add	s0,s0,s5
ffffffffc0202ab4:	00c79713          	slli	a4,a5,0xc
ffffffffc0202ab8:	fce468e3          	bltu	s0,a4,ffffffffc0202a88 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202abc:	00093783          	ld	a5,0(s2)
ffffffffc0202ac0:	639c                	ld	a5,0(a5)
ffffffffc0202ac2:	42079863          	bnez	a5,ffffffffc0202ef2 <pmm_init+0x868>
ffffffffc0202ac6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aca:	8b89                	andi	a5,a5,2
ffffffffc0202acc:	24079863          	bnez	a5,ffffffffc0202d1c <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202ad0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ad4:	4505                	li	a0,1
ffffffffc0202ad6:	6f9c                	ld	a5,24(a5)
ffffffffc0202ad8:	9782                	jalr	a5
ffffffffc0202ada:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202adc:	00093503          	ld	a0,0(s2)
ffffffffc0202ae0:	4699                	li	a3,6
ffffffffc0202ae2:	10000613          	li	a2,256
ffffffffc0202ae6:	85a2                	mv	a1,s0
ffffffffc0202ae8:	aadff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc0202aec:	46051363          	bnez	a0,ffffffffc0202f52 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202af0:	4018                	lw	a4,0(s0)
ffffffffc0202af2:	4785                	li	a5,1
ffffffffc0202af4:	42f71f63          	bne	a4,a5,ffffffffc0202f32 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202af8:	00093503          	ld	a0,0(s2)
ffffffffc0202afc:	6605                	lui	a2,0x1
ffffffffc0202afe:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7e40>
ffffffffc0202b02:	4699                	li	a3,6
ffffffffc0202b04:	85a2                	mv	a1,s0
ffffffffc0202b06:	a8fff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc0202b0a:	72051963          	bnez	a0,ffffffffc020323c <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202b0e:	4018                	lw	a4,0(s0)
ffffffffc0202b10:	4789                	li	a5,2
ffffffffc0202b12:	70f71563          	bne	a4,a5,ffffffffc020321c <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b16:	00004597          	auipc	a1,0x4
ffffffffc0202b1a:	1a258593          	addi	a1,a1,418 # ffffffffc0206cb8 <etext+0x13f6>
ffffffffc0202b1e:	10000513          	li	a0,256
ffffffffc0202b22:	4f7020ef          	jal	ffffffffc0205818 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b26:	6585                	lui	a1,0x1
ffffffffc0202b28:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7e40>
ffffffffc0202b2c:	10000513          	li	a0,256
ffffffffc0202b30:	4fb020ef          	jal	ffffffffc020582a <strcmp>
ffffffffc0202b34:	6c051463          	bnez	a0,ffffffffc02031fc <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202b38:	000bb683          	ld	a3,0(s7)
ffffffffc0202b3c:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202b40:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202b42:	40d406b3          	sub	a3,s0,a3
ffffffffc0202b46:	8699                	srai	a3,a3,0x6
ffffffffc0202b48:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202b4a:	00c69793          	slli	a5,a3,0xc
ffffffffc0202b4e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b50:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b52:	32e7f463          	bgeu	a5,a4,ffffffffc0202e7a <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b56:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b5a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b5e:	97b6                	add	a5,a5,a3
ffffffffc0202b60:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_matrix_out_size+0x74bc0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b64:	481020ef          	jal	ffffffffc02057e4 <strlen>
ffffffffc0202b68:	66051a63          	bnez	a0,ffffffffc02031dc <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b6c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b70:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b72:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd49898>
ffffffffc0202b76:	078a                	slli	a5,a5,0x2
ffffffffc0202b78:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b7a:	26e7f663          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b7e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202b82:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202e7a <pmm_init+0x7f0>
ffffffffc0202b86:	0009b783          	ld	a5,0(s3)
ffffffffc0202b8a:	00f689b3          	add	s3,a3,a5
ffffffffc0202b8e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b92:	8b89                	andi	a5,a5,2
ffffffffc0202b94:	1e079163          	bnez	a5,ffffffffc0202d76 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202b98:	000b3783          	ld	a5,0(s6)
ffffffffc0202b9c:	8522                	mv	a0,s0
ffffffffc0202b9e:	4585                	li	a1,1
ffffffffc0202ba0:	739c                	ld	a5,32(a5)
ffffffffc0202ba2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ba4:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202ba8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202baa:	078a                	slli	a5,a5,0x2
ffffffffc0202bac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bae:	22e7fc63          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bb2:	000bb503          	ld	a0,0(s7)
ffffffffc0202bb6:	fe000737          	lui	a4,0xfe000
ffffffffc0202bba:	079a                	slli	a5,a5,0x6
ffffffffc0202bbc:	97ba                	add	a5,a5,a4
ffffffffc0202bbe:	953e                	add	a0,a0,a5
ffffffffc0202bc0:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc4:	8b89                	andi	a5,a5,2
ffffffffc0202bc6:	18079c63          	bnez	a5,ffffffffc0202d5e <pmm_init+0x6d4>
ffffffffc0202bca:	000b3783          	ld	a5,0(s6)
ffffffffc0202bce:	4585                	li	a1,1
ffffffffc0202bd0:	739c                	ld	a5,32(a5)
ffffffffc0202bd2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202bd8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bda:	078a                	slli	a5,a5,0x2
ffffffffc0202bdc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bde:	20e7f463          	bgeu	a5,a4,ffffffffc0202de6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202be2:	000bb503          	ld	a0,0(s7)
ffffffffc0202be6:	fe000737          	lui	a4,0xfe000
ffffffffc0202bea:	079a                	slli	a5,a5,0x6
ffffffffc0202bec:	97ba                	add	a5,a5,a4
ffffffffc0202bee:	953e                	add	a0,a0,a5
ffffffffc0202bf0:	100027f3          	csrr	a5,sstatus
ffffffffc0202bf4:	8b89                	andi	a5,a5,2
ffffffffc0202bf6:	14079863          	bnez	a5,ffffffffc0202d46 <pmm_init+0x6bc>
ffffffffc0202bfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202bfe:	4585                	li	a1,1
ffffffffc0202c00:	739c                	ld	a5,32(a5)
ffffffffc0202c02:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c04:	00093783          	ld	a5,0(s2)
ffffffffc0202c08:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c0c:	12000073          	sfence.vma
ffffffffc0202c10:	100027f3          	csrr	a5,sstatus
ffffffffc0202c14:	8b89                	andi	a5,a5,2
ffffffffc0202c16:	10079e63          	bnez	a5,ffffffffc0202d32 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c1e:	779c                	ld	a5,40(a5)
ffffffffc0202c20:	9782                	jalr	a5
ffffffffc0202c22:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c24:	1e8c1b63          	bne	s8,s0,ffffffffc0202e1a <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202c28:	00004517          	auipc	a0,0x4
ffffffffc0202c2c:	10850513          	addi	a0,a0,264 # ffffffffc0206d30 <etext+0x146e>
ffffffffc0202c30:	d68fd0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0202c34:	7406                	ld	s0,96(sp)
ffffffffc0202c36:	70a6                	ld	ra,104(sp)
ffffffffc0202c38:	64e6                	ld	s1,88(sp)
ffffffffc0202c3a:	6946                	ld	s2,80(sp)
ffffffffc0202c3c:	69a6                	ld	s3,72(sp)
ffffffffc0202c3e:	6a06                	ld	s4,64(sp)
ffffffffc0202c40:	7ae2                	ld	s5,56(sp)
ffffffffc0202c42:	7b42                	ld	s6,48(sp)
ffffffffc0202c44:	7ba2                	ld	s7,40(sp)
ffffffffc0202c46:	7c02                	ld	s8,32(sp)
ffffffffc0202c48:	6ce2                	ld	s9,24(sp)
ffffffffc0202c4a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202c4c:	f85fe06f          	j	ffffffffc0201bd0 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202c50:	853e                	mv	a0,a5
ffffffffc0202c52:	b4e1                	j	ffffffffc020271a <pmm_init+0x90>
        intr_disable();
ffffffffc0202c54:	cabfd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c58:	000b3783          	ld	a5,0(s6)
ffffffffc0202c5c:	4505                	li	a0,1
ffffffffc0202c5e:	6f9c                	ld	a5,24(a5)
ffffffffc0202c60:	9782                	jalr	a5
ffffffffc0202c62:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c64:	c95fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202c68:	be75                	j	ffffffffc0202824 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202c6a:	c95fd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c6e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c72:	779c                	ld	a5,40(a5)
ffffffffc0202c74:	9782                	jalr	a5
ffffffffc0202c76:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c78:	c81fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202c7c:	b6ad                	j	ffffffffc02027e6 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c7e:	6705                	lui	a4,0x1
ffffffffc0202c80:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7f41>
ffffffffc0202c82:	96ba                	add	a3,a3,a4
ffffffffc0202c84:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c86:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c8a:	14a77e63          	bgeu	a4,a0,ffffffffc0202de6 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c8e:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c92:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202c94:	071a                	slli	a4,a4,0x6
ffffffffc0202c96:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202c9a:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202c9c:	6a9c                	ld	a5,16(a3)
ffffffffc0202c9e:	00c45593          	srli	a1,s0,0xc
ffffffffc0202ca2:	00e60533          	add	a0,a2,a4
ffffffffc0202ca6:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202ca8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202cac:	bcf1                	j	ffffffffc0202788 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202cae:	c51fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cb2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb6:	4505                	li	a0,1
ffffffffc0202cb8:	6f9c                	ld	a5,24(a5)
ffffffffc0202cba:	9782                	jalr	a5
ffffffffc0202cbc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cbe:	c3bfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202cc2:	b119                	j	ffffffffc02028c8 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202cc4:	c3bfd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202ccc:	779c                	ld	a5,40(a5)
ffffffffc0202cce:	9782                	jalr	a5
ffffffffc0202cd0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cd2:	c27fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202cd6:	b345                	j	ffffffffc0202a76 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202cd8:	c27fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202cdc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce0:	779c                	ld	a5,40(a5)
ffffffffc0202ce2:	9782                	jalr	a5
ffffffffc0202ce4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202ce6:	c13fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202cea:	b3a5                	j	ffffffffc0202a52 <pmm_init+0x3c8>
ffffffffc0202cec:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cee:	c11fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202cf2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf6:	6522                	ld	a0,8(sp)
ffffffffc0202cf8:	4585                	li	a1,1
ffffffffc0202cfa:	739c                	ld	a5,32(a5)
ffffffffc0202cfc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cfe:	bfbfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d02:	bb05                	j	ffffffffc0202a32 <pmm_init+0x3a8>
ffffffffc0202d04:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d06:	bf9fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202d0a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0e:	6522                	ld	a0,8(sp)
ffffffffc0202d10:	4585                	li	a1,1
ffffffffc0202d12:	739c                	ld	a5,32(a5)
ffffffffc0202d14:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d16:	be3fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d1a:	b1e5                	j	ffffffffc0202a02 <pmm_init+0x378>
        intr_disable();
ffffffffc0202d1c:	be3fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d20:	000b3783          	ld	a5,0(s6)
ffffffffc0202d24:	4505                	li	a0,1
ffffffffc0202d26:	6f9c                	ld	a5,24(a5)
ffffffffc0202d28:	9782                	jalr	a5
ffffffffc0202d2a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d2c:	bcdfd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d30:	b375                	j	ffffffffc0202adc <pmm_init+0x452>
        intr_disable();
ffffffffc0202d32:	bcdfd0ef          	jal	ffffffffc02008fe <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d36:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3a:	779c                	ld	a5,40(a5)
ffffffffc0202d3c:	9782                	jalr	a5
ffffffffc0202d3e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d40:	bb9fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d44:	b5c5                	j	ffffffffc0202c24 <pmm_init+0x59a>
ffffffffc0202d46:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d48:	bb7fd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d4c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d50:	6522                	ld	a0,8(sp)
ffffffffc0202d52:	4585                	li	a1,1
ffffffffc0202d54:	739c                	ld	a5,32(a5)
ffffffffc0202d56:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d58:	ba1fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d5c:	b565                	j	ffffffffc0202c04 <pmm_init+0x57a>
ffffffffc0202d5e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d60:	b9ffd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202d64:	000b3783          	ld	a5,0(s6)
ffffffffc0202d68:	6522                	ld	a0,8(sp)
ffffffffc0202d6a:	4585                	li	a1,1
ffffffffc0202d6c:	739c                	ld	a5,32(a5)
ffffffffc0202d6e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d70:	b89fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d74:	b585                	j	ffffffffc0202bd4 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202d76:	b89fd0ef          	jal	ffffffffc02008fe <intr_disable>
ffffffffc0202d7a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7e:	8522                	mv	a0,s0
ffffffffc0202d80:	4585                	li	a1,1
ffffffffc0202d82:	739c                	ld	a5,32(a5)
ffffffffc0202d84:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d86:	b73fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0202d8a:	bd29                	j	ffffffffc0202ba4 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d8c:	86a2                	mv	a3,s0
ffffffffc0202d8e:	00004617          	auipc	a2,0x4
ffffffffc0202d92:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0206648 <etext+0xd86>
ffffffffc0202d96:	25500593          	li	a1,597
ffffffffc0202d9a:	00004517          	auipc	a0,0x4
ffffffffc0202d9e:	99e50513          	addi	a0,a0,-1634 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202da2:	ea8fd0ef          	jal	ffffffffc020044a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202da6:	00004697          	auipc	a3,0x4
ffffffffc0202daa:	e2a68693          	addi	a3,a3,-470 # ffffffffc0206bd0 <etext+0x130e>
ffffffffc0202dae:	00003617          	auipc	a2,0x3
ffffffffc0202db2:	4ea60613          	addi	a2,a2,1258 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202db6:	25600593          	li	a1,598
ffffffffc0202dba:	00004517          	auipc	a0,0x4
ffffffffc0202dbe:	97e50513          	addi	a0,a0,-1666 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202dc2:	e88fd0ef          	jal	ffffffffc020044a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202dc6:	00004697          	auipc	a3,0x4
ffffffffc0202dca:	dca68693          	addi	a3,a3,-566 # ffffffffc0206b90 <etext+0x12ce>
ffffffffc0202dce:	00003617          	auipc	a2,0x3
ffffffffc0202dd2:	4ca60613          	addi	a2,a2,1226 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202dd6:	25500593          	li	a1,597
ffffffffc0202dda:	00004517          	auipc	a0,0x4
ffffffffc0202dde:	95e50513          	addi	a0,a0,-1698 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202de2:	e68fd0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0202de6:	fb5fe0ef          	jal	ffffffffc0201d9a <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202dea:	00004617          	auipc	a2,0x4
ffffffffc0202dee:	b4660613          	addi	a2,a2,-1210 # ffffffffc0206930 <etext+0x106e>
ffffffffc0202df2:	07f00593          	li	a1,127
ffffffffc0202df6:	00004517          	auipc	a0,0x4
ffffffffc0202dfa:	87a50513          	addi	a0,a0,-1926 # ffffffffc0206670 <etext+0xdae>
ffffffffc0202dfe:	e4cfd0ef          	jal	ffffffffc020044a <__panic>
        panic("DTB memory info not available");
ffffffffc0202e02:	00004617          	auipc	a2,0x4
ffffffffc0202e06:	9a660613          	addi	a2,a2,-1626 # ffffffffc02067a8 <etext+0xee6>
ffffffffc0202e0a:	06500593          	li	a1,101
ffffffffc0202e0e:	00004517          	auipc	a0,0x4
ffffffffc0202e12:	92a50513          	addi	a0,a0,-1750 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202e16:	e34fd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202e1a:	00004697          	auipc	a3,0x4
ffffffffc0202e1e:	d2e68693          	addi	a3,a3,-722 # ffffffffc0206b48 <etext+0x1286>
ffffffffc0202e22:	00003617          	auipc	a2,0x3
ffffffffc0202e26:	47660613          	addi	a2,a2,1142 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202e2a:	27000593          	li	a1,624
ffffffffc0202e2e:	00004517          	auipc	a0,0x4
ffffffffc0202e32:	90a50513          	addi	a0,a0,-1782 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202e36:	e14fd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202e3a:	00004697          	auipc	a3,0x4
ffffffffc0202e3e:	a2668693          	addi	a3,a3,-1498 # ffffffffc0206860 <etext+0xf9e>
ffffffffc0202e42:	00003617          	auipc	a2,0x3
ffffffffc0202e46:	45660613          	addi	a2,a2,1110 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202e4a:	21700593          	li	a1,535
ffffffffc0202e4e:	00004517          	auipc	a0,0x4
ffffffffc0202e52:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202e56:	df4fd0ef          	jal	ffffffffc020044a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202e5a:	00004697          	auipc	a3,0x4
ffffffffc0202e5e:	9e668693          	addi	a3,a3,-1562 # ffffffffc0206840 <etext+0xf7e>
ffffffffc0202e62:	00003617          	auipc	a2,0x3
ffffffffc0202e66:	43660613          	addi	a2,a2,1078 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202e6a:	21600593          	li	a1,534
ffffffffc0202e6e:	00004517          	auipc	a0,0x4
ffffffffc0202e72:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202e76:	dd4fd0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e7a:	00003617          	auipc	a2,0x3
ffffffffc0202e7e:	7ce60613          	addi	a2,a2,1998 # ffffffffc0206648 <etext+0xd86>
ffffffffc0202e82:	07100593          	li	a1,113
ffffffffc0202e86:	00003517          	auipc	a0,0x3
ffffffffc0202e8a:	7ea50513          	addi	a0,a0,2026 # ffffffffc0206670 <etext+0xdae>
ffffffffc0202e8e:	dbcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e92:	00004697          	auipc	a3,0x4
ffffffffc0202e96:	c8668693          	addi	a3,a3,-890 # ffffffffc0206b18 <etext+0x1256>
ffffffffc0202e9a:	00003617          	auipc	a2,0x3
ffffffffc0202e9e:	3fe60613          	addi	a2,a2,1022 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202ea2:	23e00593          	li	a1,574
ffffffffc0202ea6:	00004517          	auipc	a0,0x4
ffffffffc0202eaa:	89250513          	addi	a0,a0,-1902 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202eae:	d9cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202eb2:	00004697          	auipc	a3,0x4
ffffffffc0202eb6:	c1e68693          	addi	a3,a3,-994 # ffffffffc0206ad0 <etext+0x120e>
ffffffffc0202eba:	00003617          	auipc	a2,0x3
ffffffffc0202ebe:	3de60613          	addi	a2,a2,990 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202ec2:	23c00593          	li	a1,572
ffffffffc0202ec6:	00004517          	auipc	a0,0x4
ffffffffc0202eca:	87250513          	addi	a0,a0,-1934 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202ece:	d7cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202ed2:	00004697          	auipc	a3,0x4
ffffffffc0202ed6:	c2e68693          	addi	a3,a3,-978 # ffffffffc0206b00 <etext+0x123e>
ffffffffc0202eda:	00003617          	auipc	a2,0x3
ffffffffc0202ede:	3be60613          	addi	a2,a2,958 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202ee2:	23b00593          	li	a1,571
ffffffffc0202ee6:	00004517          	auipc	a0,0x4
ffffffffc0202eea:	85250513          	addi	a0,a0,-1966 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202eee:	d5cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202ef2:	00004697          	auipc	a3,0x4
ffffffffc0202ef6:	cf668693          	addi	a3,a3,-778 # ffffffffc0206be8 <etext+0x1326>
ffffffffc0202efa:	00003617          	auipc	a2,0x3
ffffffffc0202efe:	39e60613          	addi	a2,a2,926 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202f02:	25900593          	li	a1,601
ffffffffc0202f06:	00004517          	auipc	a0,0x4
ffffffffc0202f0a:	83250513          	addi	a0,a0,-1998 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202f0e:	d3cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f12:	00004697          	auipc	a3,0x4
ffffffffc0202f16:	c3668693          	addi	a3,a3,-970 # ffffffffc0206b48 <etext+0x1286>
ffffffffc0202f1a:	00003617          	auipc	a2,0x3
ffffffffc0202f1e:	37e60613          	addi	a2,a2,894 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202f22:	24600593          	li	a1,582
ffffffffc0202f26:	00004517          	auipc	a0,0x4
ffffffffc0202f2a:	81250513          	addi	a0,a0,-2030 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202f2e:	d1cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f32:	00004697          	auipc	a3,0x4
ffffffffc0202f36:	d0e68693          	addi	a3,a3,-754 # ffffffffc0206c40 <etext+0x137e>
ffffffffc0202f3a:	00003617          	auipc	a2,0x3
ffffffffc0202f3e:	35e60613          	addi	a2,a2,862 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202f42:	25e00593          	li	a1,606
ffffffffc0202f46:	00003517          	auipc	a0,0x3
ffffffffc0202f4a:	7f250513          	addi	a0,a0,2034 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202f4e:	cfcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f52:	00004697          	auipc	a3,0x4
ffffffffc0202f56:	cae68693          	addi	a3,a3,-850 # ffffffffc0206c00 <etext+0x133e>
ffffffffc0202f5a:	00003617          	auipc	a2,0x3
ffffffffc0202f5e:	33e60613          	addi	a2,a2,830 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202f62:	25d00593          	li	a1,605
ffffffffc0202f66:	00003517          	auipc	a0,0x3
ffffffffc0202f6a:	7d250513          	addi	a0,a0,2002 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202f6e:	cdcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f72:	00004697          	auipc	a3,0x4
ffffffffc0202f76:	b5e68693          	addi	a3,a3,-1186 # ffffffffc0206ad0 <etext+0x120e>
ffffffffc0202f7a:	00003617          	auipc	a2,0x3
ffffffffc0202f7e:	31e60613          	addi	a2,a2,798 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202f82:	23800593          	li	a1,568
ffffffffc0202f86:	00003517          	auipc	a0,0x3
ffffffffc0202f8a:	7b250513          	addi	a0,a0,1970 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202f8e:	cbcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f92:	00004697          	auipc	a3,0x4
ffffffffc0202f96:	9de68693          	addi	a3,a3,-1570 # ffffffffc0206970 <etext+0x10ae>
ffffffffc0202f9a:	00003617          	auipc	a2,0x3
ffffffffc0202f9e:	2fe60613          	addi	a2,a2,766 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202fa2:	23700593          	li	a1,567
ffffffffc0202fa6:	00003517          	auipc	a0,0x3
ffffffffc0202faa:	79250513          	addi	a0,a0,1938 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202fae:	c9cfd0ef          	jal	ffffffffc020044a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202fb2:	00004697          	auipc	a3,0x4
ffffffffc0202fb6:	b3668693          	addi	a3,a3,-1226 # ffffffffc0206ae8 <etext+0x1226>
ffffffffc0202fba:	00003617          	auipc	a2,0x3
ffffffffc0202fbe:	2de60613          	addi	a2,a2,734 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202fc2:	23400593          	li	a1,564
ffffffffc0202fc6:	00003517          	auipc	a0,0x3
ffffffffc0202fca:	77250513          	addi	a0,a0,1906 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202fce:	c7cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202fd2:	00004697          	auipc	a3,0x4
ffffffffc0202fd6:	98668693          	addi	a3,a3,-1658 # ffffffffc0206958 <etext+0x1096>
ffffffffc0202fda:	00003617          	auipc	a2,0x3
ffffffffc0202fde:	2be60613          	addi	a2,a2,702 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0202fe2:	23300593          	li	a1,563
ffffffffc0202fe6:	00003517          	auipc	a0,0x3
ffffffffc0202fea:	75250513          	addi	a0,a0,1874 # ffffffffc0206738 <etext+0xe76>
ffffffffc0202fee:	c5cfd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ff2:	00004697          	auipc	a3,0x4
ffffffffc0202ff6:	a0668693          	addi	a3,a3,-1530 # ffffffffc02069f8 <etext+0x1136>
ffffffffc0202ffa:	00003617          	auipc	a2,0x3
ffffffffc0202ffe:	29e60613          	addi	a2,a2,670 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203002:	23200593          	li	a1,562
ffffffffc0203006:	00003517          	auipc	a0,0x3
ffffffffc020300a:	73250513          	addi	a0,a0,1842 # ffffffffc0206738 <etext+0xe76>
ffffffffc020300e:	c3cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203012:	00004697          	auipc	a3,0x4
ffffffffc0203016:	abe68693          	addi	a3,a3,-1346 # ffffffffc0206ad0 <etext+0x120e>
ffffffffc020301a:	00003617          	auipc	a2,0x3
ffffffffc020301e:	27e60613          	addi	a2,a2,638 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203022:	23100593          	li	a1,561
ffffffffc0203026:	00003517          	auipc	a0,0x3
ffffffffc020302a:	71250513          	addi	a0,a0,1810 # ffffffffc0206738 <etext+0xe76>
ffffffffc020302e:	c1cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203032:	00004697          	auipc	a3,0x4
ffffffffc0203036:	a8668693          	addi	a3,a3,-1402 # ffffffffc0206ab8 <etext+0x11f6>
ffffffffc020303a:	00003617          	auipc	a2,0x3
ffffffffc020303e:	25e60613          	addi	a2,a2,606 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203042:	23000593          	li	a1,560
ffffffffc0203046:	00003517          	auipc	a0,0x3
ffffffffc020304a:	6f250513          	addi	a0,a0,1778 # ffffffffc0206738 <etext+0xe76>
ffffffffc020304e:	bfcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203052:	00004697          	auipc	a3,0x4
ffffffffc0203056:	a3668693          	addi	a3,a3,-1482 # ffffffffc0206a88 <etext+0x11c6>
ffffffffc020305a:	00003617          	auipc	a2,0x3
ffffffffc020305e:	23e60613          	addi	a2,a2,574 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203062:	22f00593          	li	a1,559
ffffffffc0203066:	00003517          	auipc	a0,0x3
ffffffffc020306a:	6d250513          	addi	a0,a0,1746 # ffffffffc0206738 <etext+0xe76>
ffffffffc020306e:	bdcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203072:	00004697          	auipc	a3,0x4
ffffffffc0203076:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0206a70 <etext+0x11ae>
ffffffffc020307a:	00003617          	auipc	a2,0x3
ffffffffc020307e:	21e60613          	addi	a2,a2,542 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203082:	22d00593          	li	a1,557
ffffffffc0203086:	00003517          	auipc	a0,0x3
ffffffffc020308a:	6b250513          	addi	a0,a0,1714 # ffffffffc0206738 <etext+0xe76>
ffffffffc020308e:	bbcfd0ef          	jal	ffffffffc020044a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203092:	00004697          	auipc	a3,0x4
ffffffffc0203096:	9be68693          	addi	a3,a3,-1602 # ffffffffc0206a50 <etext+0x118e>
ffffffffc020309a:	00003617          	auipc	a2,0x3
ffffffffc020309e:	1fe60613          	addi	a2,a2,510 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02030a2:	22c00593          	li	a1,556
ffffffffc02030a6:	00003517          	auipc	a0,0x3
ffffffffc02030aa:	69250513          	addi	a0,a0,1682 # ffffffffc0206738 <etext+0xe76>
ffffffffc02030ae:	b9cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_W);
ffffffffc02030b2:	00004697          	auipc	a3,0x4
ffffffffc02030b6:	98e68693          	addi	a3,a3,-1650 # ffffffffc0206a40 <etext+0x117e>
ffffffffc02030ba:	00003617          	auipc	a2,0x3
ffffffffc02030be:	1de60613          	addi	a2,a2,478 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02030c2:	22b00593          	li	a1,555
ffffffffc02030c6:	00003517          	auipc	a0,0x3
ffffffffc02030ca:	67250513          	addi	a0,a0,1650 # ffffffffc0206738 <etext+0xe76>
ffffffffc02030ce:	b7cfd0ef          	jal	ffffffffc020044a <__panic>
    assert(*ptep & PTE_U);
ffffffffc02030d2:	00004697          	auipc	a3,0x4
ffffffffc02030d6:	95e68693          	addi	a3,a3,-1698 # ffffffffc0206a30 <etext+0x116e>
ffffffffc02030da:	00003617          	auipc	a2,0x3
ffffffffc02030de:	1be60613          	addi	a2,a2,446 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02030e2:	22a00593          	li	a1,554
ffffffffc02030e6:	00003517          	auipc	a0,0x3
ffffffffc02030ea:	65250513          	addi	a0,a0,1618 # ffffffffc0206738 <etext+0xe76>
ffffffffc02030ee:	b5cfd0ef          	jal	ffffffffc020044a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02030f2:	00003617          	auipc	a2,0x3
ffffffffc02030f6:	5fe60613          	addi	a2,a2,1534 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc02030fa:	08100593          	li	a1,129
ffffffffc02030fe:	00003517          	auipc	a0,0x3
ffffffffc0203102:	63a50513          	addi	a0,a0,1594 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203106:	b44fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020310a:	00004697          	auipc	a3,0x4
ffffffffc020310e:	87e68693          	addi	a3,a3,-1922 # ffffffffc0206988 <etext+0x10c6>
ffffffffc0203112:	00003617          	auipc	a2,0x3
ffffffffc0203116:	18660613          	addi	a2,a2,390 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020311a:	22500593          	li	a1,549
ffffffffc020311e:	00003517          	auipc	a0,0x3
ffffffffc0203122:	61a50513          	addi	a0,a0,1562 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203126:	b24fd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020312a:	00004697          	auipc	a3,0x4
ffffffffc020312e:	8ce68693          	addi	a3,a3,-1842 # ffffffffc02069f8 <etext+0x1136>
ffffffffc0203132:	00003617          	auipc	a2,0x3
ffffffffc0203136:	16660613          	addi	a2,a2,358 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020313a:	22900593          	li	a1,553
ffffffffc020313e:	00003517          	auipc	a0,0x3
ffffffffc0203142:	5fa50513          	addi	a0,a0,1530 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203146:	b04fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020314a:	00004697          	auipc	a3,0x4
ffffffffc020314e:	86e68693          	addi	a3,a3,-1938 # ffffffffc02069b8 <etext+0x10f6>
ffffffffc0203152:	00003617          	auipc	a2,0x3
ffffffffc0203156:	14660613          	addi	a2,a2,326 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020315a:	22800593          	li	a1,552
ffffffffc020315e:	00003517          	auipc	a0,0x3
ffffffffc0203162:	5da50513          	addi	a0,a0,1498 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203166:	ae4fd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020316a:	86d6                	mv	a3,s5
ffffffffc020316c:	00003617          	auipc	a2,0x3
ffffffffc0203170:	4dc60613          	addi	a2,a2,1244 # ffffffffc0206648 <etext+0xd86>
ffffffffc0203174:	22400593          	li	a1,548
ffffffffc0203178:	00003517          	auipc	a0,0x3
ffffffffc020317c:	5c050513          	addi	a0,a0,1472 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203180:	acafd0ef          	jal	ffffffffc020044a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203184:	00003617          	auipc	a2,0x3
ffffffffc0203188:	4c460613          	addi	a2,a2,1220 # ffffffffc0206648 <etext+0xd86>
ffffffffc020318c:	22300593          	li	a1,547
ffffffffc0203190:	00003517          	auipc	a0,0x3
ffffffffc0203194:	5a850513          	addi	a0,a0,1448 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203198:	ab2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020319c:	00003697          	auipc	a3,0x3
ffffffffc02031a0:	7d468693          	addi	a3,a3,2004 # ffffffffc0206970 <etext+0x10ae>
ffffffffc02031a4:	00003617          	auipc	a2,0x3
ffffffffc02031a8:	0f460613          	addi	a2,a2,244 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02031ac:	22100593          	li	a1,545
ffffffffc02031b0:	00003517          	auipc	a0,0x3
ffffffffc02031b4:	58850513          	addi	a0,a0,1416 # ffffffffc0206738 <etext+0xe76>
ffffffffc02031b8:	a92fd0ef          	jal	ffffffffc020044a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031bc:	00003697          	auipc	a3,0x3
ffffffffc02031c0:	79c68693          	addi	a3,a3,1948 # ffffffffc0206958 <etext+0x1096>
ffffffffc02031c4:	00003617          	auipc	a2,0x3
ffffffffc02031c8:	0d460613          	addi	a2,a2,212 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02031cc:	22000593          	li	a1,544
ffffffffc02031d0:	00003517          	auipc	a0,0x3
ffffffffc02031d4:	56850513          	addi	a0,a0,1384 # ffffffffc0206738 <etext+0xe76>
ffffffffc02031d8:	a72fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02031dc:	00004697          	auipc	a3,0x4
ffffffffc02031e0:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206d08 <etext+0x1446>
ffffffffc02031e4:	00003617          	auipc	a2,0x3
ffffffffc02031e8:	0b460613          	addi	a2,a2,180 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02031ec:	26700593          	li	a1,615
ffffffffc02031f0:	00003517          	auipc	a0,0x3
ffffffffc02031f4:	54850513          	addi	a0,a0,1352 # ffffffffc0206738 <etext+0xe76>
ffffffffc02031f8:	a52fd0ef          	jal	ffffffffc020044a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02031fc:	00004697          	auipc	a3,0x4
ffffffffc0203200:	ad468693          	addi	a3,a3,-1324 # ffffffffc0206cd0 <etext+0x140e>
ffffffffc0203204:	00003617          	auipc	a2,0x3
ffffffffc0203208:	09460613          	addi	a2,a2,148 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020320c:	26400593          	li	a1,612
ffffffffc0203210:	00003517          	auipc	a0,0x3
ffffffffc0203214:	52850513          	addi	a0,a0,1320 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203218:	a32fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_ref(p) == 2);
ffffffffc020321c:	00004697          	auipc	a3,0x4
ffffffffc0203220:	a8468693          	addi	a3,a3,-1404 # ffffffffc0206ca0 <etext+0x13de>
ffffffffc0203224:	00003617          	auipc	a2,0x3
ffffffffc0203228:	07460613          	addi	a2,a2,116 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020322c:	26000593          	li	a1,608
ffffffffc0203230:	00003517          	auipc	a0,0x3
ffffffffc0203234:	50850513          	addi	a0,a0,1288 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203238:	a12fd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020323c:	00004697          	auipc	a3,0x4
ffffffffc0203240:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206c58 <etext+0x1396>
ffffffffc0203244:	00003617          	auipc	a2,0x3
ffffffffc0203248:	05460613          	addi	a2,a2,84 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020324c:	25f00593          	li	a1,607
ffffffffc0203250:	00003517          	auipc	a0,0x3
ffffffffc0203254:	4e850513          	addi	a0,a0,1256 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203258:	9f2fd0ef          	jal	ffffffffc020044a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020325c:	00003697          	auipc	a3,0x3
ffffffffc0203260:	64468693          	addi	a3,a3,1604 # ffffffffc02068a0 <etext+0xfde>
ffffffffc0203264:	00003617          	auipc	a2,0x3
ffffffffc0203268:	03460613          	addi	a2,a2,52 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020326c:	21800593          	li	a1,536
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	4c850513          	addi	a0,a0,1224 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203278:	9d2fd0ef          	jal	ffffffffc020044a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020327c:	00003617          	auipc	a2,0x3
ffffffffc0203280:	47460613          	addi	a2,a2,1140 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc0203284:	0c900593          	li	a1,201
ffffffffc0203288:	00003517          	auipc	a0,0x3
ffffffffc020328c:	4b050513          	addi	a0,a0,1200 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203290:	9bafd0ef          	jal	ffffffffc020044a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203294:	00003697          	auipc	a3,0x3
ffffffffc0203298:	66c68693          	addi	a3,a3,1644 # ffffffffc0206900 <etext+0x103e>
ffffffffc020329c:	00003617          	auipc	a2,0x3
ffffffffc02032a0:	ffc60613          	addi	a2,a2,-4 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02032a4:	21f00593          	li	a1,543
ffffffffc02032a8:	00003517          	auipc	a0,0x3
ffffffffc02032ac:	49050513          	addi	a0,a0,1168 # ffffffffc0206738 <etext+0xe76>
ffffffffc02032b0:	99afd0ef          	jal	ffffffffc020044a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02032b4:	00003697          	auipc	a3,0x3
ffffffffc02032b8:	61c68693          	addi	a3,a3,1564 # ffffffffc02068d0 <etext+0x100e>
ffffffffc02032bc:	00003617          	auipc	a2,0x3
ffffffffc02032c0:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02032c4:	21c00593          	li	a1,540
ffffffffc02032c8:	00003517          	auipc	a0,0x3
ffffffffc02032cc:	47050513          	addi	a0,a0,1136 # ffffffffc0206738 <etext+0xe76>
ffffffffc02032d0:	97afd0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02032d4 <copy_range>:
{
ffffffffc02032d4:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032d6:	00d667b3          	or	a5,a2,a3
{
ffffffffc02032da:	f486                	sd	ra,104(sp)
ffffffffc02032dc:	f0a2                	sd	s0,96(sp)
ffffffffc02032de:	eca6                	sd	s1,88(sp)
ffffffffc02032e0:	e8ca                	sd	s2,80(sp)
ffffffffc02032e2:	e4ce                	sd	s3,72(sp)
ffffffffc02032e4:	e0d2                	sd	s4,64(sp)
ffffffffc02032e6:	fc56                	sd	s5,56(sp)
ffffffffc02032e8:	f85a                	sd	s6,48(sp)
ffffffffc02032ea:	f45e                	sd	s7,40(sp)
ffffffffc02032ec:	f062                	sd	s8,32(sp)
ffffffffc02032ee:	ec66                	sd	s9,24(sp)
ffffffffc02032f0:	e86a                	sd	s10,16(sp)
ffffffffc02032f2:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032f4:	03479713          	slli	a4,a5,0x34
ffffffffc02032f8:	20071f63          	bnez	a4,ffffffffc0203516 <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02032fc:	002007b7          	lui	a5,0x200
ffffffffc0203300:	00d63733          	sltu	a4,a2,a3
ffffffffc0203304:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203308:	00173713          	seqz	a4,a4
ffffffffc020330c:	8fd9                	or	a5,a5,a4
ffffffffc020330e:	8432                	mv	s0,a2
ffffffffc0203310:	8936                	mv	s2,a3
ffffffffc0203312:	1e079263          	bnez	a5,ffffffffc02034f6 <copy_range+0x222>
ffffffffc0203316:	4785                	li	a5,1
ffffffffc0203318:	07fe                	slli	a5,a5,0x1f
ffffffffc020331a:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ac1>
ffffffffc020331c:	1cf6fd63          	bgeu	a3,a5,ffffffffc02034f6 <copy_range+0x222>
ffffffffc0203320:	5b7d                	li	s6,-1
ffffffffc0203322:	8baa                	mv	s7,a0
ffffffffc0203324:	8a2e                	mv	s4,a1
ffffffffc0203326:	6a85                	lui	s5,0x1
ffffffffc0203328:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc020332c:	000b2c97          	auipc	s9,0xb2
ffffffffc0203330:	3fcc8c93          	addi	s9,s9,1020 # ffffffffc02b5728 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203334:	000b2c17          	auipc	s8,0xb2
ffffffffc0203338:	3fcc0c13          	addi	s8,s8,1020 # ffffffffc02b5730 <pages>
ffffffffc020333c:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203340:	4601                	li	a2,0
ffffffffc0203342:	85a2                	mv	a1,s0
ffffffffc0203344:	8552                	mv	a0,s4
ffffffffc0203346:	b19fe0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc020334a:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020334c:	0e050a63          	beqz	a0,ffffffffc0203440 <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc0203350:	611c                	ld	a5,0(a0)
ffffffffc0203352:	8b85                	andi	a5,a5,1
ffffffffc0203354:	e78d                	bnez	a5,ffffffffc020337e <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203356:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0203358:	c019                	beqz	s0,ffffffffc020335e <copy_range+0x8a>
ffffffffc020335a:	ff2463e3          	bltu	s0,s2,ffffffffc0203340 <copy_range+0x6c>
    return 0;
ffffffffc020335e:	4501                	li	a0,0
}
ffffffffc0203360:	70a6                	ld	ra,104(sp)
ffffffffc0203362:	7406                	ld	s0,96(sp)
ffffffffc0203364:	64e6                	ld	s1,88(sp)
ffffffffc0203366:	6946                	ld	s2,80(sp)
ffffffffc0203368:	69a6                	ld	s3,72(sp)
ffffffffc020336a:	6a06                	ld	s4,64(sp)
ffffffffc020336c:	7ae2                	ld	s5,56(sp)
ffffffffc020336e:	7b42                	ld	s6,48(sp)
ffffffffc0203370:	7ba2                	ld	s7,40(sp)
ffffffffc0203372:	7c02                	ld	s8,32(sp)
ffffffffc0203374:	6ce2                	ld	s9,24(sp)
ffffffffc0203376:	6d42                	ld	s10,16(sp)
ffffffffc0203378:	6da2                	ld	s11,8(sp)
ffffffffc020337a:	6165                	addi	sp,sp,112
ffffffffc020337c:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020337e:	4605                	li	a2,1
ffffffffc0203380:	85a2                	mv	a1,s0
ffffffffc0203382:	855e                	mv	a0,s7
ffffffffc0203384:	adbfe0ef          	jal	ffffffffc0201e5e <get_pte>
ffffffffc0203388:	c165                	beqz	a0,ffffffffc0203468 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020338a:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc020338e:	0019f793          	andi	a5,s3,1
ffffffffc0203392:	14078663          	beqz	a5,ffffffffc02034de <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc0203396:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020339a:	00299793          	slli	a5,s3,0x2
ffffffffc020339e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02033a0:	12e7f363          	bgeu	a5,a4,ffffffffc02034c6 <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc02033a4:	000c3483          	ld	s1,0(s8)
ffffffffc02033a8:	97ea                	add	a5,a5,s10
ffffffffc02033aa:	079a                	slli	a5,a5,0x6
ffffffffc02033ac:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02033ae:	100027f3          	csrr	a5,sstatus
ffffffffc02033b2:	8b89                	andi	a5,a5,2
ffffffffc02033b4:	efc9                	bnez	a5,ffffffffc020344e <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc02033b6:	000b2797          	auipc	a5,0xb2
ffffffffc02033ba:	3527b783          	ld	a5,850(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc02033be:	4505                	li	a0,1
ffffffffc02033c0:	6f9c                	ld	a5,24(a5)
ffffffffc02033c2:	9782                	jalr	a5
ffffffffc02033c4:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02033c6:	c0e5                	beqz	s1,ffffffffc02034a6 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02033c8:	0a0d8f63          	beqz	s11,ffffffffc0203486 <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02033cc:	000c3783          	ld	a5,0(s8)
ffffffffc02033d0:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc02033d4:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc02033d8:	40f486b3          	sub	a3,s1,a5
ffffffffc02033dc:	8699                	srai	a3,a3,0x6
ffffffffc02033de:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02033e0:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02033e4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033e6:	08e5f463          	bgeu	a1,a4,ffffffffc020346e <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02033ea:	40fd87b3          	sub	a5,s11,a5
ffffffffc02033ee:	8799                	srai	a5,a5,0x6
ffffffffc02033f0:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02033f2:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02033f6:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02033f8:	06e67a63          	bgeu	a2,a4,ffffffffc020346c <copy_range+0x198>
ffffffffc02033fc:	000b2517          	auipc	a0,0xb2
ffffffffc0203400:	32453503          	ld	a0,804(a0) # ffffffffc02b5720 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203404:	6605                	lui	a2,0x1
ffffffffc0203406:	00a685b3          	add	a1,a3,a0
ffffffffc020340a:	953e                	add	a0,a0,a5
ffffffffc020340c:	49e020ef          	jal	ffffffffc02058aa <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc0203410:	01f9f693          	andi	a3,s3,31
ffffffffc0203414:	85ee                	mv	a1,s11
ffffffffc0203416:	8622                	mv	a2,s0
ffffffffc0203418:	855e                	mv	a0,s7
ffffffffc020341a:	97aff0ef          	jal	ffffffffc0202594 <page_insert>
            assert(ret == 0);
ffffffffc020341e:	dd05                	beqz	a0,ffffffffc0203356 <copy_range+0x82>
ffffffffc0203420:	00004697          	auipc	a3,0x4
ffffffffc0203424:	95068693          	addi	a3,a3,-1712 # ffffffffc0206d70 <etext+0x14ae>
ffffffffc0203428:	00003617          	auipc	a2,0x3
ffffffffc020342c:	e7060613          	addi	a2,a2,-400 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203430:	1b400593          	li	a1,436
ffffffffc0203434:	00003517          	auipc	a0,0x3
ffffffffc0203438:	30450513          	addi	a0,a0,772 # ffffffffc0206738 <etext+0xe76>
ffffffffc020343c:	80efd0ef          	jal	ffffffffc020044a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203440:	002007b7          	lui	a5,0x200
ffffffffc0203444:	97a2                	add	a5,a5,s0
ffffffffc0203446:	ffe00437          	lui	s0,0xffe00
ffffffffc020344a:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc020344c:	b731                	j	ffffffffc0203358 <copy_range+0x84>
        intr_disable();
ffffffffc020344e:	cb0fd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203452:	000b2797          	auipc	a5,0xb2
ffffffffc0203456:	2b67b783          	ld	a5,694(a5) # ffffffffc02b5708 <pmm_manager>
ffffffffc020345a:	4505                	li	a0,1
ffffffffc020345c:	6f9c                	ld	a5,24(a5)
ffffffffc020345e:	9782                	jalr	a5
ffffffffc0203460:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203462:	c96fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0203466:	b785                	j	ffffffffc02033c6 <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc0203468:	5571                	li	a0,-4
ffffffffc020346a:	bddd                	j	ffffffffc0203360 <copy_range+0x8c>
ffffffffc020346c:	86be                	mv	a3,a5
ffffffffc020346e:	00003617          	auipc	a2,0x3
ffffffffc0203472:	1da60613          	addi	a2,a2,474 # ffffffffc0206648 <etext+0xd86>
ffffffffc0203476:	07100593          	li	a1,113
ffffffffc020347a:	00003517          	auipc	a0,0x3
ffffffffc020347e:	1f650513          	addi	a0,a0,502 # ffffffffc0206670 <etext+0xdae>
ffffffffc0203482:	fc9fc0ef          	jal	ffffffffc020044a <__panic>
            assert(npage != NULL);
ffffffffc0203486:	00004697          	auipc	a3,0x4
ffffffffc020348a:	8da68693          	addi	a3,a3,-1830 # ffffffffc0206d60 <etext+0x149e>
ffffffffc020348e:	00003617          	auipc	a2,0x3
ffffffffc0203492:	e0a60613          	addi	a2,a2,-502 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203496:	19700593          	li	a1,407
ffffffffc020349a:	00003517          	auipc	a0,0x3
ffffffffc020349e:	29e50513          	addi	a0,a0,670 # ffffffffc0206738 <etext+0xe76>
ffffffffc02034a2:	fa9fc0ef          	jal	ffffffffc020044a <__panic>
            assert(page != NULL);
ffffffffc02034a6:	00004697          	auipc	a3,0x4
ffffffffc02034aa:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0206d50 <etext+0x148e>
ffffffffc02034ae:	00003617          	auipc	a2,0x3
ffffffffc02034b2:	dea60613          	addi	a2,a2,-534 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02034b6:	19600593          	li	a1,406
ffffffffc02034ba:	00003517          	auipc	a0,0x3
ffffffffc02034be:	27e50513          	addi	a0,a0,638 # ffffffffc0206738 <etext+0xe76>
ffffffffc02034c2:	f89fc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02034c6:	00003617          	auipc	a2,0x3
ffffffffc02034ca:	25260613          	addi	a2,a2,594 # ffffffffc0206718 <etext+0xe56>
ffffffffc02034ce:	06900593          	li	a1,105
ffffffffc02034d2:	00003517          	auipc	a0,0x3
ffffffffc02034d6:	19e50513          	addi	a0,a0,414 # ffffffffc0206670 <etext+0xdae>
ffffffffc02034da:	f71fc0ef          	jal	ffffffffc020044a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02034de:	00003617          	auipc	a2,0x3
ffffffffc02034e2:	45260613          	addi	a2,a2,1106 # ffffffffc0206930 <etext+0x106e>
ffffffffc02034e6:	07f00593          	li	a1,127
ffffffffc02034ea:	00003517          	auipc	a0,0x3
ffffffffc02034ee:	18650513          	addi	a0,a0,390 # ffffffffc0206670 <etext+0xdae>
ffffffffc02034f2:	f59fc0ef          	jal	ffffffffc020044a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02034f6:	00003697          	auipc	a3,0x3
ffffffffc02034fa:	28268693          	addi	a3,a3,642 # ffffffffc0206778 <etext+0xeb6>
ffffffffc02034fe:	00003617          	auipc	a2,0x3
ffffffffc0203502:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203506:	17e00593          	li	a1,382
ffffffffc020350a:	00003517          	auipc	a0,0x3
ffffffffc020350e:	22e50513          	addi	a0,a0,558 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203512:	f39fc0ef          	jal	ffffffffc020044a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203516:	00003697          	auipc	a3,0x3
ffffffffc020351a:	23268693          	addi	a3,a3,562 # ffffffffc0206748 <etext+0xe86>
ffffffffc020351e:	00003617          	auipc	a2,0x3
ffffffffc0203522:	d7a60613          	addi	a2,a2,-646 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203526:	17d00593          	li	a1,381
ffffffffc020352a:	00003517          	auipc	a0,0x3
ffffffffc020352e:	20e50513          	addi	a0,a0,526 # ffffffffc0206738 <etext+0xe76>
ffffffffc0203532:	f19fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203536 <pgdir_alloc_page>:
{
ffffffffc0203536:	7139                	addi	sp,sp,-64
ffffffffc0203538:	f426                	sd	s1,40(sp)
ffffffffc020353a:	f04a                	sd	s2,32(sp)
ffffffffc020353c:	ec4e                	sd	s3,24(sp)
ffffffffc020353e:	fc06                	sd	ra,56(sp)
ffffffffc0203540:	f822                	sd	s0,48(sp)
ffffffffc0203542:	892a                	mv	s2,a0
ffffffffc0203544:	84ae                	mv	s1,a1
ffffffffc0203546:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203548:	100027f3          	csrr	a5,sstatus
ffffffffc020354c:	8b89                	andi	a5,a5,2
ffffffffc020354e:	ebb5                	bnez	a5,ffffffffc02035c2 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203550:	000b2417          	auipc	s0,0xb2
ffffffffc0203554:	1b840413          	addi	s0,s0,440 # ffffffffc02b5708 <pmm_manager>
ffffffffc0203558:	601c                	ld	a5,0(s0)
ffffffffc020355a:	4505                	li	a0,1
ffffffffc020355c:	6f9c                	ld	a5,24(a5)
ffffffffc020355e:	9782                	jalr	a5
ffffffffc0203560:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203562:	c5b9                	beqz	a1,ffffffffc02035b0 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203564:	86ce                	mv	a3,s3
ffffffffc0203566:	854a                	mv	a0,s2
ffffffffc0203568:	8626                	mv	a2,s1
ffffffffc020356a:	e42e                	sd	a1,8(sp)
ffffffffc020356c:	828ff0ef          	jal	ffffffffc0202594 <page_insert>
ffffffffc0203570:	65a2                	ld	a1,8(sp)
ffffffffc0203572:	e515                	bnez	a0,ffffffffc020359e <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203574:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc0203576:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc0203578:	4785                	li	a5,1
ffffffffc020357a:	02f70c63          	beq	a4,a5,ffffffffc02035b2 <pgdir_alloc_page+0x7c>
ffffffffc020357e:	00004697          	auipc	a3,0x4
ffffffffc0203582:	80268693          	addi	a3,a3,-2046 # ffffffffc0206d80 <etext+0x14be>
ffffffffc0203586:	00003617          	auipc	a2,0x3
ffffffffc020358a:	d1260613          	addi	a2,a2,-750 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020358e:	1fd00593          	li	a1,509
ffffffffc0203592:	00003517          	auipc	a0,0x3
ffffffffc0203596:	1a650513          	addi	a0,a0,422 # ffffffffc0206738 <etext+0xe76>
ffffffffc020359a:	eb1fc0ef          	jal	ffffffffc020044a <__panic>
ffffffffc020359e:	100027f3          	csrr	a5,sstatus
ffffffffc02035a2:	8b89                	andi	a5,a5,2
ffffffffc02035a4:	ef95                	bnez	a5,ffffffffc02035e0 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc02035a6:	601c                	ld	a5,0(s0)
ffffffffc02035a8:	852e                	mv	a0,a1
ffffffffc02035aa:	4585                	li	a1,1
ffffffffc02035ac:	739c                	ld	a5,32(a5)
ffffffffc02035ae:	9782                	jalr	a5
            return NULL;
ffffffffc02035b0:	4581                	li	a1,0
}
ffffffffc02035b2:	70e2                	ld	ra,56(sp)
ffffffffc02035b4:	7442                	ld	s0,48(sp)
ffffffffc02035b6:	74a2                	ld	s1,40(sp)
ffffffffc02035b8:	7902                	ld	s2,32(sp)
ffffffffc02035ba:	69e2                	ld	s3,24(sp)
ffffffffc02035bc:	852e                	mv	a0,a1
ffffffffc02035be:	6121                	addi	sp,sp,64
ffffffffc02035c0:	8082                	ret
        intr_disable();
ffffffffc02035c2:	b3cfd0ef          	jal	ffffffffc02008fe <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035c6:	000b2417          	auipc	s0,0xb2
ffffffffc02035ca:	14240413          	addi	s0,s0,322 # ffffffffc02b5708 <pmm_manager>
ffffffffc02035ce:	601c                	ld	a5,0(s0)
ffffffffc02035d0:	4505                	li	a0,1
ffffffffc02035d2:	6f9c                	ld	a5,24(a5)
ffffffffc02035d4:	9782                	jalr	a5
ffffffffc02035d6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02035d8:	b20fd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02035dc:	65a2                	ld	a1,8(sp)
ffffffffc02035de:	b751                	j	ffffffffc0203562 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02035e0:	b1efd0ef          	jal	ffffffffc02008fe <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02035e4:	601c                	ld	a5,0(s0)
ffffffffc02035e6:	6522                	ld	a0,8(sp)
ffffffffc02035e8:	4585                	li	a1,1
ffffffffc02035ea:	739c                	ld	a5,32(a5)
ffffffffc02035ec:	9782                	jalr	a5
        intr_enable();
ffffffffc02035ee:	b0afd0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02035f2:	bf7d                	j	ffffffffc02035b0 <pgdir_alloc_page+0x7a>

ffffffffc02035f4 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035f4:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02035f6:	00003697          	auipc	a3,0x3
ffffffffc02035fa:	7a268693          	addi	a3,a3,1954 # ffffffffc0206d98 <etext+0x14d6>
ffffffffc02035fe:	00003617          	auipc	a2,0x3
ffffffffc0203602:	c9a60613          	addi	a2,a2,-870 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203606:	07400593          	li	a1,116
ffffffffc020360a:	00003517          	auipc	a0,0x3
ffffffffc020360e:	7ae50513          	addi	a0,a0,1966 # ffffffffc0206db8 <etext+0x14f6>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203612:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203614:	e37fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203618 <mm_create>:
{
ffffffffc0203618:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020361a:	04000513          	li	a0,64
{
ffffffffc020361e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203620:	dd4fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
    if (mm != NULL)
ffffffffc0203624:	cd19                	beqz	a0,ffffffffc0203642 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203626:	e508                	sd	a0,8(a0)
ffffffffc0203628:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020362a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020362e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203632:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203636:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020363a:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020363e:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203642:	60a2                	ld	ra,8(sp)
ffffffffc0203644:	0141                	addi	sp,sp,16
ffffffffc0203646:	8082                	ret

ffffffffc0203648 <find_vma>:
    if (mm != NULL)
ffffffffc0203648:	c505                	beqz	a0,ffffffffc0203670 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc020364a:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020364c:	c781                	beqz	a5,ffffffffc0203654 <find_vma+0xc>
ffffffffc020364e:	6798                	ld	a4,8(a5)
ffffffffc0203650:	02e5f363          	bgeu	a1,a4,ffffffffc0203676 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203654:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203656:	00f50d63          	beq	a0,a5,ffffffffc0203670 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020365a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020365e:	00e5e663          	bltu	a1,a4,ffffffffc020366a <find_vma+0x22>
ffffffffc0203662:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203666:	00e5ee63          	bltu	a1,a4,ffffffffc0203682 <find_vma+0x3a>
ffffffffc020366a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020366c:	fef517e3          	bne	a0,a5,ffffffffc020365a <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203670:	4781                	li	a5,0
}
ffffffffc0203672:	853e                	mv	a0,a5
ffffffffc0203674:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203676:	6b98                	ld	a4,16(a5)
ffffffffc0203678:	fce5fee3          	bgeu	a1,a4,ffffffffc0203654 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020367c:	e91c                	sd	a5,16(a0)
}
ffffffffc020367e:	853e                	mv	a0,a5
ffffffffc0203680:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203682:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203684:	e91c                	sd	a5,16(a0)
ffffffffc0203686:	bfe5                	j	ffffffffc020367e <find_vma+0x36>

ffffffffc0203688 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203688:	6590                	ld	a2,8(a1)
ffffffffc020368a:	0105b803          	ld	a6,16(a1)
{
ffffffffc020368e:	1141                	addi	sp,sp,-16
ffffffffc0203690:	e406                	sd	ra,8(sp)
ffffffffc0203692:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203694:	01066763          	bltu	a2,a6,ffffffffc02036a2 <insert_vma_struct+0x1a>
ffffffffc0203698:	a8b9                	j	ffffffffc02036f6 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020369a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020369e:	04e66763          	bltu	a2,a4,ffffffffc02036ec <insert_vma_struct+0x64>
ffffffffc02036a2:	86be                	mv	a3,a5
ffffffffc02036a4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02036a6:	fef51ae3          	bne	a0,a5,ffffffffc020369a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02036aa:	02a68463          	beq	a3,a0,ffffffffc02036d2 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02036ae:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036b2:	fe86b883          	ld	a7,-24(a3)
ffffffffc02036b6:	08e8f063          	bgeu	a7,a4,ffffffffc0203736 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036ba:	04e66e63          	bltu	a2,a4,ffffffffc0203716 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02036be:	00f50a63          	beq	a0,a5,ffffffffc02036d2 <insert_vma_struct+0x4a>
ffffffffc02036c2:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036c6:	05076863          	bltu	a4,a6,ffffffffc0203716 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02036ca:	ff07b603          	ld	a2,-16(a5)
ffffffffc02036ce:	02c77263          	bgeu	a4,a2,ffffffffc02036f2 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02036d2:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02036d4:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02036d6:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02036da:	e390                	sd	a2,0(a5)
ffffffffc02036dc:	e690                	sd	a2,8(a3)
}
ffffffffc02036de:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02036e0:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02036e2:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02036e4:	2705                	addiw	a4,a4,1
ffffffffc02036e6:	d118                	sw	a4,32(a0)
}
ffffffffc02036e8:	0141                	addi	sp,sp,16
ffffffffc02036ea:	8082                	ret
    if (le_prev != list)
ffffffffc02036ec:	fca691e3          	bne	a3,a0,ffffffffc02036ae <insert_vma_struct+0x26>
ffffffffc02036f0:	bfd9                	j	ffffffffc02036c6 <insert_vma_struct+0x3e>
ffffffffc02036f2:	f03ff0ef          	jal	ffffffffc02035f4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036f6:	00003697          	auipc	a3,0x3
ffffffffc02036fa:	6d268693          	addi	a3,a3,1746 # ffffffffc0206dc8 <etext+0x1506>
ffffffffc02036fe:	00003617          	auipc	a2,0x3
ffffffffc0203702:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203706:	07a00593          	li	a1,122
ffffffffc020370a:	00003517          	auipc	a0,0x3
ffffffffc020370e:	6ae50513          	addi	a0,a0,1710 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203712:	d39fc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203716:	00003697          	auipc	a3,0x3
ffffffffc020371a:	6f268693          	addi	a3,a3,1778 # ffffffffc0206e08 <etext+0x1546>
ffffffffc020371e:	00003617          	auipc	a2,0x3
ffffffffc0203722:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203726:	07300593          	li	a1,115
ffffffffc020372a:	00003517          	auipc	a0,0x3
ffffffffc020372e:	68e50513          	addi	a0,a0,1678 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203732:	d19fc0ef          	jal	ffffffffc020044a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203736:	00003697          	auipc	a3,0x3
ffffffffc020373a:	6b268693          	addi	a3,a3,1714 # ffffffffc0206de8 <etext+0x1526>
ffffffffc020373e:	00003617          	auipc	a2,0x3
ffffffffc0203742:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203746:	07200593          	li	a1,114
ffffffffc020374a:	00003517          	auipc	a0,0x3
ffffffffc020374e:	66e50513          	addi	a0,a0,1646 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203752:	cf9fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203756 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203756:	591c                	lw	a5,48(a0)
{
ffffffffc0203758:	1141                	addi	sp,sp,-16
ffffffffc020375a:	e406                	sd	ra,8(sp)
ffffffffc020375c:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020375e:	e78d                	bnez	a5,ffffffffc0203788 <mm_destroy+0x32>
ffffffffc0203760:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203762:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203764:	00a40c63          	beq	s0,a0,ffffffffc020377c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203768:	6118                	ld	a4,0(a0)
ffffffffc020376a:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020376c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020376e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203770:	e398                	sd	a4,0(a5)
ffffffffc0203772:	d28fe0ef          	jal	ffffffffc0201c9a <kfree>
    return listelm->next;
ffffffffc0203776:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203778:	fea418e3          	bne	s0,a0,ffffffffc0203768 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020377c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020377e:	6402                	ld	s0,0(sp)
ffffffffc0203780:	60a2                	ld	ra,8(sp)
ffffffffc0203782:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203784:	d16fe06f          	j	ffffffffc0201c9a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203788:	00003697          	auipc	a3,0x3
ffffffffc020378c:	6a068693          	addi	a3,a3,1696 # ffffffffc0206e28 <etext+0x1566>
ffffffffc0203790:	00003617          	auipc	a2,0x3
ffffffffc0203794:	b0860613          	addi	a2,a2,-1272 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203798:	09e00593          	li	a1,158
ffffffffc020379c:	00003517          	auipc	a0,0x3
ffffffffc02037a0:	61c50513          	addi	a0,a0,1564 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc02037a4:	ca7fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02037a8 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037a8:	6785                	lui	a5,0x1
ffffffffc02037aa:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7f41>
ffffffffc02037ac:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc02037ae:	4785                	li	a5,1
{
ffffffffc02037b0:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037b2:	962e                	add	a2,a2,a1
ffffffffc02037b4:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc02037b6:	07fe                	slli	a5,a5,0x1f
{
ffffffffc02037b8:	f822                	sd	s0,48(sp)
ffffffffc02037ba:	f426                	sd	s1,40(sp)
ffffffffc02037bc:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037c0:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02037c4:	0785                	addi	a5,a5,1
ffffffffc02037c6:	0084b633          	sltu	a2,s1,s0
ffffffffc02037ca:	00f437b3          	sltu	a5,s0,a5
ffffffffc02037ce:	00163613          	seqz	a2,a2
ffffffffc02037d2:	0017b793          	seqz	a5,a5
{
ffffffffc02037d6:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02037d8:	8fd1                	or	a5,a5,a2
ffffffffc02037da:	ebbd                	bnez	a5,ffffffffc0203850 <mm_map+0xa8>
ffffffffc02037dc:	002007b7          	lui	a5,0x200
ffffffffc02037e0:	06f4e863          	bltu	s1,a5,ffffffffc0203850 <mm_map+0xa8>
ffffffffc02037e4:	f04a                	sd	s2,32(sp)
ffffffffc02037e6:	ec4e                	sd	s3,24(sp)
ffffffffc02037e8:	e852                	sd	s4,16(sp)
ffffffffc02037ea:	892a                	mv	s2,a0
ffffffffc02037ec:	89ba                	mv	s3,a4
ffffffffc02037ee:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02037f0:	c135                	beqz	a0,ffffffffc0203854 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02037f2:	85a6                	mv	a1,s1
ffffffffc02037f4:	e55ff0ef          	jal	ffffffffc0203648 <find_vma>
ffffffffc02037f8:	c501                	beqz	a0,ffffffffc0203800 <mm_map+0x58>
ffffffffc02037fa:	651c                	ld	a5,8(a0)
ffffffffc02037fc:	0487e763          	bltu	a5,s0,ffffffffc020384a <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203800:	03000513          	li	a0,48
ffffffffc0203804:	bf0fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
ffffffffc0203808:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020380a:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020380c:	c59d                	beqz	a1,ffffffffc020383a <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc020380e:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc0203810:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203812:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203816:	854a                	mv	a0,s2
ffffffffc0203818:	e42e                	sd	a1,8(sp)
ffffffffc020381a:	e6fff0ef          	jal	ffffffffc0203688 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc020381e:	65a2                	ld	a1,8(sp)
ffffffffc0203820:	00098463          	beqz	s3,ffffffffc0203828 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203824:	00b9b023          	sd	a1,0(s3)
ffffffffc0203828:	7902                	ld	s2,32(sp)
ffffffffc020382a:	69e2                	ld	s3,24(sp)
ffffffffc020382c:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020382e:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203830:	70e2                	ld	ra,56(sp)
ffffffffc0203832:	7442                	ld	s0,48(sp)
ffffffffc0203834:	74a2                	ld	s1,40(sp)
ffffffffc0203836:	6121                	addi	sp,sp,64
ffffffffc0203838:	8082                	ret
ffffffffc020383a:	70e2                	ld	ra,56(sp)
ffffffffc020383c:	7442                	ld	s0,48(sp)
ffffffffc020383e:	7902                	ld	s2,32(sp)
ffffffffc0203840:	69e2                	ld	s3,24(sp)
ffffffffc0203842:	6a42                	ld	s4,16(sp)
ffffffffc0203844:	74a2                	ld	s1,40(sp)
ffffffffc0203846:	6121                	addi	sp,sp,64
ffffffffc0203848:	8082                	ret
ffffffffc020384a:	7902                	ld	s2,32(sp)
ffffffffc020384c:	69e2                	ld	s3,24(sp)
ffffffffc020384e:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203850:	5575                	li	a0,-3
ffffffffc0203852:	bff9                	j	ffffffffc0203830 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203854:	00003697          	auipc	a3,0x3
ffffffffc0203858:	5ec68693          	addi	a3,a3,1516 # ffffffffc0206e40 <etext+0x157e>
ffffffffc020385c:	00003617          	auipc	a2,0x3
ffffffffc0203860:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203864:	0b300593          	li	a1,179
ffffffffc0203868:	00003517          	auipc	a0,0x3
ffffffffc020386c:	55050513          	addi	a0,a0,1360 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203870:	bdbfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203874 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203874:	7139                	addi	sp,sp,-64
ffffffffc0203876:	fc06                	sd	ra,56(sp)
ffffffffc0203878:	f822                	sd	s0,48(sp)
ffffffffc020387a:	f426                	sd	s1,40(sp)
ffffffffc020387c:	f04a                	sd	s2,32(sp)
ffffffffc020387e:	ec4e                	sd	s3,24(sp)
ffffffffc0203880:	e852                	sd	s4,16(sp)
ffffffffc0203882:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203884:	c525                	beqz	a0,ffffffffc02038ec <dup_mmap+0x78>
ffffffffc0203886:	892a                	mv	s2,a0
ffffffffc0203888:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020388a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020388c:	c1a5                	beqz	a1,ffffffffc02038ec <dup_mmap+0x78>
    return listelm->prev;
ffffffffc020388e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203890:	04848c63          	beq	s1,s0,ffffffffc02038e8 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203894:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203898:	fe843a83          	ld	s5,-24(s0)
ffffffffc020389c:	ff043a03          	ld	s4,-16(s0)
ffffffffc02038a0:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038a4:	b50fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
    if (vma != NULL)
ffffffffc02038a8:	c515                	beqz	a0,ffffffffc02038d4 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02038aa:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02038ac:	01553423          	sd	s5,8(a0)
ffffffffc02038b0:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038b4:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc02038b8:	854a                	mv	a0,s2
ffffffffc02038ba:	dcfff0ef          	jal	ffffffffc0203688 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02038be:	ff043683          	ld	a3,-16(s0)
ffffffffc02038c2:	fe843603          	ld	a2,-24(s0)
ffffffffc02038c6:	6c8c                	ld	a1,24(s1)
ffffffffc02038c8:	01893503          	ld	a0,24(s2)
ffffffffc02038cc:	4701                	li	a4,0
ffffffffc02038ce:	a07ff0ef          	jal	ffffffffc02032d4 <copy_range>
ffffffffc02038d2:	dd55                	beqz	a0,ffffffffc020388e <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02038d4:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02038d6:	70e2                	ld	ra,56(sp)
ffffffffc02038d8:	7442                	ld	s0,48(sp)
ffffffffc02038da:	74a2                	ld	s1,40(sp)
ffffffffc02038dc:	7902                	ld	s2,32(sp)
ffffffffc02038de:	69e2                	ld	s3,24(sp)
ffffffffc02038e0:	6a42                	ld	s4,16(sp)
ffffffffc02038e2:	6aa2                	ld	s5,8(sp)
ffffffffc02038e4:	6121                	addi	sp,sp,64
ffffffffc02038e6:	8082                	ret
    return 0;
ffffffffc02038e8:	4501                	li	a0,0
ffffffffc02038ea:	b7f5                	j	ffffffffc02038d6 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02038ec:	00003697          	auipc	a3,0x3
ffffffffc02038f0:	56468693          	addi	a3,a3,1380 # ffffffffc0206e50 <etext+0x158e>
ffffffffc02038f4:	00003617          	auipc	a2,0x3
ffffffffc02038f8:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02038fc:	0cf00593          	li	a1,207
ffffffffc0203900:	00003517          	auipc	a0,0x3
ffffffffc0203904:	4b850513          	addi	a0,a0,1208 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203908:	b43fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020390c <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020390c:	1101                	addi	sp,sp,-32
ffffffffc020390e:	ec06                	sd	ra,24(sp)
ffffffffc0203910:	e822                	sd	s0,16(sp)
ffffffffc0203912:	e426                	sd	s1,8(sp)
ffffffffc0203914:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203916:	c531                	beqz	a0,ffffffffc0203962 <exit_mmap+0x56>
ffffffffc0203918:	591c                	lw	a5,48(a0)
ffffffffc020391a:	84aa                	mv	s1,a0
ffffffffc020391c:	e3b9                	bnez	a5,ffffffffc0203962 <exit_mmap+0x56>
    return listelm->next;
ffffffffc020391e:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203920:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203924:	02850663          	beq	a0,s0,ffffffffc0203950 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203928:	ff043603          	ld	a2,-16(s0)
ffffffffc020392c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203930:	854a                	mv	a0,s2
ffffffffc0203932:	fdefe0ef          	jal	ffffffffc0202110 <unmap_range>
ffffffffc0203936:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203938:	fe8498e3          	bne	s1,s0,ffffffffc0203928 <exit_mmap+0x1c>
ffffffffc020393c:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc020393e:	00848c63          	beq	s1,s0,ffffffffc0203956 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203942:	ff043603          	ld	a2,-16(s0)
ffffffffc0203946:	fe843583          	ld	a1,-24(s0)
ffffffffc020394a:	854a                	mv	a0,s2
ffffffffc020394c:	8f9fe0ef          	jal	ffffffffc0202244 <exit_range>
ffffffffc0203950:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203952:	fe8498e3          	bne	s1,s0,ffffffffc0203942 <exit_mmap+0x36>
    }
}
ffffffffc0203956:	60e2                	ld	ra,24(sp)
ffffffffc0203958:	6442                	ld	s0,16(sp)
ffffffffc020395a:	64a2                	ld	s1,8(sp)
ffffffffc020395c:	6902                	ld	s2,0(sp)
ffffffffc020395e:	6105                	addi	sp,sp,32
ffffffffc0203960:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203962:	00003697          	auipc	a3,0x3
ffffffffc0203966:	50e68693          	addi	a3,a3,1294 # ffffffffc0206e70 <etext+0x15ae>
ffffffffc020396a:	00003617          	auipc	a2,0x3
ffffffffc020396e:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203972:	0e800593          	li	a1,232
ffffffffc0203976:	00003517          	auipc	a0,0x3
ffffffffc020397a:	44250513          	addi	a0,a0,1090 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc020397e:	acdfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203982 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203982:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203984:	04000513          	li	a0,64
{
ffffffffc0203988:	f406                	sd	ra,40(sp)
ffffffffc020398a:	f022                	sd	s0,32(sp)
ffffffffc020398c:	ec26                	sd	s1,24(sp)
ffffffffc020398e:	e84a                	sd	s2,16(sp)
ffffffffc0203990:	e44e                	sd	s3,8(sp)
ffffffffc0203992:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203994:	a60fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
    if (mm != NULL)
ffffffffc0203998:	16050c63          	beqz	a0,ffffffffc0203b10 <vmm_init+0x18e>
ffffffffc020399c:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc020399e:	e508                	sd	a0,8(a0)
ffffffffc02039a0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02039a2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02039a6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02039aa:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02039ae:	02053423          	sd	zero,40(a0)
ffffffffc02039b2:	02052823          	sw	zero,48(a0)
ffffffffc02039b6:	02053c23          	sd	zero,56(a0)
ffffffffc02039ba:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039be:	03000513          	li	a0,48
ffffffffc02039c2:	a32fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
    if (vma != NULL)
ffffffffc02039c6:	12050563          	beqz	a0,ffffffffc0203af0 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc02039ca:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc02039ce:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039d0:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc02039d4:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039d6:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc02039d8:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc02039da:	8522                	mv	a0,s0
ffffffffc02039dc:	cadff0ef          	jal	ffffffffc0203688 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc02039e0:	fcf9                	bnez	s1,ffffffffc02039be <vmm_init+0x3c>
ffffffffc02039e2:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039e6:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039ea:	03000513          	li	a0,48
ffffffffc02039ee:	a06fe0ef          	jal	ffffffffc0201bf4 <kmalloc>
    if (vma != NULL)
ffffffffc02039f2:	12050f63          	beqz	a0,ffffffffc0203b30 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc02039f6:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc02039fa:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039fc:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203a00:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a02:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a04:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203a06:	8522                	mv	a0,s0
ffffffffc0203a08:	c81ff0ef          	jal	ffffffffc0203688 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a0c:	fd249fe3          	bne	s1,s2,ffffffffc02039ea <vmm_init+0x68>
    return listelm->next;
ffffffffc0203a10:	641c                	ld	a5,8(s0)
ffffffffc0203a12:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203a14:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203a18:	1ef40c63          	beq	s0,a5,ffffffffc0203c10 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a1c:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f4aa8>
ffffffffc0203a20:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a24:	12d61663          	bne	a2,a3,ffffffffc0203b50 <vmm_init+0x1ce>
ffffffffc0203a28:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a2c:	12e69263          	bne	a3,a4,ffffffffc0203b50 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203a30:	0715                	addi	a4,a4,5
ffffffffc0203a32:	679c                	ld	a5,8(a5)
ffffffffc0203a34:	feb712e3          	bne	a4,a1,ffffffffc0203a18 <vmm_init+0x96>
ffffffffc0203a38:	491d                	li	s2,7
ffffffffc0203a3a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a3c:	85a6                	mv	a1,s1
ffffffffc0203a3e:	8522                	mv	a0,s0
ffffffffc0203a40:	c09ff0ef          	jal	ffffffffc0203648 <find_vma>
ffffffffc0203a44:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203a46:	20050563          	beqz	a0,ffffffffc0203c50 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a4a:	00148593          	addi	a1,s1,1
ffffffffc0203a4e:	8522                	mv	a0,s0
ffffffffc0203a50:	bf9ff0ef          	jal	ffffffffc0203648 <find_vma>
ffffffffc0203a54:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a56:	1c050d63          	beqz	a0,ffffffffc0203c30 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a5a:	85ca                	mv	a1,s2
ffffffffc0203a5c:	8522                	mv	a0,s0
ffffffffc0203a5e:	bebff0ef          	jal	ffffffffc0203648 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a62:	18051763          	bnez	a0,ffffffffc0203bf0 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a66:	00348593          	addi	a1,s1,3
ffffffffc0203a6a:	8522                	mv	a0,s0
ffffffffc0203a6c:	bddff0ef          	jal	ffffffffc0203648 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a70:	16051063          	bnez	a0,ffffffffc0203bd0 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a74:	00448593          	addi	a1,s1,4
ffffffffc0203a78:	8522                	mv	a0,s0
ffffffffc0203a7a:	bcfff0ef          	jal	ffffffffc0203648 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a7e:	12051963          	bnez	a0,ffffffffc0203bb0 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a82:	008a3783          	ld	a5,8(s4)
ffffffffc0203a86:	10979563          	bne	a5,s1,ffffffffc0203b90 <vmm_init+0x20e>
ffffffffc0203a8a:	010a3783          	ld	a5,16(s4)
ffffffffc0203a8e:	11279163          	bne	a5,s2,ffffffffc0203b90 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a92:	0089b783          	ld	a5,8(s3)
ffffffffc0203a96:	0c979d63          	bne	a5,s1,ffffffffc0203b70 <vmm_init+0x1ee>
ffffffffc0203a9a:	0109b783          	ld	a5,16(s3)
ffffffffc0203a9e:	0d279963          	bne	a5,s2,ffffffffc0203b70 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203aa2:	0495                	addi	s1,s1,5
ffffffffc0203aa4:	1f900793          	li	a5,505
ffffffffc0203aa8:	0915                	addi	s2,s2,5
ffffffffc0203aaa:	f8f499e3          	bne	s1,a5,ffffffffc0203a3c <vmm_init+0xba>
ffffffffc0203aae:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203ab0:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203ab2:	85a6                	mv	a1,s1
ffffffffc0203ab4:	8522                	mv	a0,s0
ffffffffc0203ab6:	b93ff0ef          	jal	ffffffffc0203648 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203aba:	1a051b63          	bnez	a0,ffffffffc0203c70 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203abe:	14fd                	addi	s1,s1,-1
ffffffffc0203ac0:	ff2499e3          	bne	s1,s2,ffffffffc0203ab2 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203ac4:	8522                	mv	a0,s0
ffffffffc0203ac6:	c91ff0ef          	jal	ffffffffc0203756 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203aca:	00003517          	auipc	a0,0x3
ffffffffc0203ace:	51650513          	addi	a0,a0,1302 # ffffffffc0206fe0 <etext+0x171e>
ffffffffc0203ad2:	ec6fc0ef          	jal	ffffffffc0200198 <cprintf>
}
ffffffffc0203ad6:	7402                	ld	s0,32(sp)
ffffffffc0203ad8:	70a2                	ld	ra,40(sp)
ffffffffc0203ada:	64e2                	ld	s1,24(sp)
ffffffffc0203adc:	6942                	ld	s2,16(sp)
ffffffffc0203ade:	69a2                	ld	s3,8(sp)
ffffffffc0203ae0:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ae2:	00003517          	auipc	a0,0x3
ffffffffc0203ae6:	51e50513          	addi	a0,a0,1310 # ffffffffc0207000 <etext+0x173e>
}
ffffffffc0203aea:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203aec:	eacfc06f          	j	ffffffffc0200198 <cprintf>
        assert(vma != NULL);
ffffffffc0203af0:	00003697          	auipc	a3,0x3
ffffffffc0203af4:	3a068693          	addi	a3,a3,928 # ffffffffc0206e90 <etext+0x15ce>
ffffffffc0203af8:	00002617          	auipc	a2,0x2
ffffffffc0203afc:	7a060613          	addi	a2,a2,1952 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203b00:	12c00593          	li	a1,300
ffffffffc0203b04:	00003517          	auipc	a0,0x3
ffffffffc0203b08:	2b450513          	addi	a0,a0,692 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203b0c:	93ffc0ef          	jal	ffffffffc020044a <__panic>
    assert(mm != NULL);
ffffffffc0203b10:	00003697          	auipc	a3,0x3
ffffffffc0203b14:	33068693          	addi	a3,a3,816 # ffffffffc0206e40 <etext+0x157e>
ffffffffc0203b18:	00002617          	auipc	a2,0x2
ffffffffc0203b1c:	78060613          	addi	a2,a2,1920 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203b20:	12400593          	li	a1,292
ffffffffc0203b24:	00003517          	auipc	a0,0x3
ffffffffc0203b28:	29450513          	addi	a0,a0,660 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203b2c:	91ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma != NULL);
ffffffffc0203b30:	00003697          	auipc	a3,0x3
ffffffffc0203b34:	36068693          	addi	a3,a3,864 # ffffffffc0206e90 <etext+0x15ce>
ffffffffc0203b38:	00002617          	auipc	a2,0x2
ffffffffc0203b3c:	76060613          	addi	a2,a2,1888 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203b40:	13300593          	li	a1,307
ffffffffc0203b44:	00003517          	auipc	a0,0x3
ffffffffc0203b48:	27450513          	addi	a0,a0,628 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203b4c:	8fffc0ef          	jal	ffffffffc020044a <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b50:	00003697          	auipc	a3,0x3
ffffffffc0203b54:	36868693          	addi	a3,a3,872 # ffffffffc0206eb8 <etext+0x15f6>
ffffffffc0203b58:	00002617          	auipc	a2,0x2
ffffffffc0203b5c:	74060613          	addi	a2,a2,1856 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203b60:	13d00593          	li	a1,317
ffffffffc0203b64:	00003517          	auipc	a0,0x3
ffffffffc0203b68:	25450513          	addi	a0,a0,596 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203b6c:	8dffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b70:	00003697          	auipc	a3,0x3
ffffffffc0203b74:	40068693          	addi	a3,a3,1024 # ffffffffc0206f70 <etext+0x16ae>
ffffffffc0203b78:	00002617          	auipc	a2,0x2
ffffffffc0203b7c:	72060613          	addi	a2,a2,1824 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203b80:	14f00593          	li	a1,335
ffffffffc0203b84:	00003517          	auipc	a0,0x3
ffffffffc0203b88:	23450513          	addi	a0,a0,564 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203b8c:	8bffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b90:	00003697          	auipc	a3,0x3
ffffffffc0203b94:	3b068693          	addi	a3,a3,944 # ffffffffc0206f40 <etext+0x167e>
ffffffffc0203b98:	00002617          	auipc	a2,0x2
ffffffffc0203b9c:	70060613          	addi	a2,a2,1792 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203ba0:	14e00593          	li	a1,334
ffffffffc0203ba4:	00003517          	auipc	a0,0x3
ffffffffc0203ba8:	21450513          	addi	a0,a0,532 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203bac:	89ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma5 == NULL);
ffffffffc0203bb0:	00003697          	auipc	a3,0x3
ffffffffc0203bb4:	38068693          	addi	a3,a3,896 # ffffffffc0206f30 <etext+0x166e>
ffffffffc0203bb8:	00002617          	auipc	a2,0x2
ffffffffc0203bbc:	6e060613          	addi	a2,a2,1760 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203bc0:	14c00593          	li	a1,332
ffffffffc0203bc4:	00003517          	auipc	a0,0x3
ffffffffc0203bc8:	1f450513          	addi	a0,a0,500 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203bcc:	87ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma4 == NULL);
ffffffffc0203bd0:	00003697          	auipc	a3,0x3
ffffffffc0203bd4:	35068693          	addi	a3,a3,848 # ffffffffc0206f20 <etext+0x165e>
ffffffffc0203bd8:	00002617          	auipc	a2,0x2
ffffffffc0203bdc:	6c060613          	addi	a2,a2,1728 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203be0:	14a00593          	li	a1,330
ffffffffc0203be4:	00003517          	auipc	a0,0x3
ffffffffc0203be8:	1d450513          	addi	a0,a0,468 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203bec:	85ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma3 == NULL);
ffffffffc0203bf0:	00003697          	auipc	a3,0x3
ffffffffc0203bf4:	32068693          	addi	a3,a3,800 # ffffffffc0206f10 <etext+0x164e>
ffffffffc0203bf8:	00002617          	auipc	a2,0x2
ffffffffc0203bfc:	6a060613          	addi	a2,a2,1696 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203c00:	14800593          	li	a1,328
ffffffffc0203c04:	00003517          	auipc	a0,0x3
ffffffffc0203c08:	1b450513          	addi	a0,a0,436 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203c0c:	83ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c10:	00003697          	auipc	a3,0x3
ffffffffc0203c14:	29068693          	addi	a3,a3,656 # ffffffffc0206ea0 <etext+0x15de>
ffffffffc0203c18:	00002617          	auipc	a2,0x2
ffffffffc0203c1c:	68060613          	addi	a2,a2,1664 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203c20:	13b00593          	li	a1,315
ffffffffc0203c24:	00003517          	auipc	a0,0x3
ffffffffc0203c28:	19450513          	addi	a0,a0,404 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203c2c:	81ffc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma2 != NULL);
ffffffffc0203c30:	00003697          	auipc	a3,0x3
ffffffffc0203c34:	2d068693          	addi	a3,a3,720 # ffffffffc0206f00 <etext+0x163e>
ffffffffc0203c38:	00002617          	auipc	a2,0x2
ffffffffc0203c3c:	66060613          	addi	a2,a2,1632 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203c40:	14600593          	li	a1,326
ffffffffc0203c44:	00003517          	auipc	a0,0x3
ffffffffc0203c48:	17450513          	addi	a0,a0,372 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203c4c:	ffefc0ef          	jal	ffffffffc020044a <__panic>
        assert(vma1 != NULL);
ffffffffc0203c50:	00003697          	auipc	a3,0x3
ffffffffc0203c54:	2a068693          	addi	a3,a3,672 # ffffffffc0206ef0 <etext+0x162e>
ffffffffc0203c58:	00002617          	auipc	a2,0x2
ffffffffc0203c5c:	64060613          	addi	a2,a2,1600 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203c60:	14400593          	li	a1,324
ffffffffc0203c64:	00003517          	auipc	a0,0x3
ffffffffc0203c68:	15450513          	addi	a0,a0,340 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203c6c:	fdefc0ef          	jal	ffffffffc020044a <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c70:	6914                	ld	a3,16(a0)
ffffffffc0203c72:	6510                	ld	a2,8(a0)
ffffffffc0203c74:	0004859b          	sext.w	a1,s1
ffffffffc0203c78:	00003517          	auipc	a0,0x3
ffffffffc0203c7c:	32850513          	addi	a0,a0,808 # ffffffffc0206fa0 <etext+0x16de>
ffffffffc0203c80:	d18fc0ef          	jal	ffffffffc0200198 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203c84:	00003697          	auipc	a3,0x3
ffffffffc0203c88:	34468693          	addi	a3,a3,836 # ffffffffc0206fc8 <etext+0x1706>
ffffffffc0203c8c:	00002617          	auipc	a2,0x2
ffffffffc0203c90:	60c60613          	addi	a2,a2,1548 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0203c94:	15900593          	li	a1,345
ffffffffc0203c98:	00003517          	auipc	a0,0x3
ffffffffc0203c9c:	12050513          	addi	a0,a0,288 # ffffffffc0206db8 <etext+0x14f6>
ffffffffc0203ca0:	faafc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203ca4 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203ca4:	7179                	addi	sp,sp,-48
ffffffffc0203ca6:	f022                	sd	s0,32(sp)
ffffffffc0203ca8:	f406                	sd	ra,40(sp)
ffffffffc0203caa:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203cac:	c52d                	beqz	a0,ffffffffc0203d16 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203cae:	002007b7          	lui	a5,0x200
ffffffffc0203cb2:	04f5ed63          	bltu	a1,a5,ffffffffc0203d0c <user_mem_check+0x68>
ffffffffc0203cb6:	ec26                	sd	s1,24(sp)
ffffffffc0203cb8:	00c584b3          	add	s1,a1,a2
ffffffffc0203cbc:	0695ff63          	bgeu	a1,s1,ffffffffc0203d3a <user_mem_check+0x96>
ffffffffc0203cc0:	4785                	li	a5,1
ffffffffc0203cc2:	07fe                	slli	a5,a5,0x1f
ffffffffc0203cc4:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ac1>
ffffffffc0203cc6:	06f4fa63          	bgeu	s1,a5,ffffffffc0203d3a <user_mem_check+0x96>
ffffffffc0203cca:	e84a                	sd	s2,16(sp)
ffffffffc0203ccc:	e44e                	sd	s3,8(sp)
ffffffffc0203cce:	8936                	mv	s2,a3
ffffffffc0203cd0:	89aa                	mv	s3,a0
ffffffffc0203cd2:	a829                	j	ffffffffc0203cec <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203cd4:	6685                	lui	a3,0x1
ffffffffc0203cd6:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cd8:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203cdc:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cde:	c685                	beqz	a3,ffffffffc0203d06 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203ce0:	c399                	beqz	a5,ffffffffc0203ce6 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203ce2:	02e46263          	bltu	s0,a4,ffffffffc0203d06 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203ce6:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203ce8:	04947b63          	bgeu	s0,s1,ffffffffc0203d3e <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203cec:	85a2                	mv	a1,s0
ffffffffc0203cee:	854e                	mv	a0,s3
ffffffffc0203cf0:	959ff0ef          	jal	ffffffffc0203648 <find_vma>
ffffffffc0203cf4:	c909                	beqz	a0,ffffffffc0203d06 <user_mem_check+0x62>
ffffffffc0203cf6:	6518                	ld	a4,8(a0)
ffffffffc0203cf8:	00e46763          	bltu	s0,a4,ffffffffc0203d06 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cfc:	4d1c                	lw	a5,24(a0)
ffffffffc0203cfe:	fc091be3          	bnez	s2,ffffffffc0203cd4 <user_mem_check+0x30>
ffffffffc0203d02:	8b85                	andi	a5,a5,1
ffffffffc0203d04:	f3ed                	bnez	a5,ffffffffc0203ce6 <user_mem_check+0x42>
ffffffffc0203d06:	64e2                	ld	s1,24(sp)
ffffffffc0203d08:	6942                	ld	s2,16(sp)
ffffffffc0203d0a:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203d0c:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203d0e:	70a2                	ld	ra,40(sp)
ffffffffc0203d10:	7402                	ld	s0,32(sp)
ffffffffc0203d12:	6145                	addi	sp,sp,48
ffffffffc0203d14:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d16:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d1a:	fef5eae3          	bltu	a1,a5,ffffffffc0203d0e <user_mem_check+0x6a>
ffffffffc0203d1e:	c80007b7          	lui	a5,0xc8000
ffffffffc0203d22:	962e                	add	a2,a2,a1
ffffffffc0203d24:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d4a899>
ffffffffc0203d26:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203d2a:	00f63633          	sltu	a2,a2,a5
}
ffffffffc0203d2e:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d30:	00867533          	and	a0,a2,s0
}
ffffffffc0203d34:	7402                	ld	s0,32(sp)
ffffffffc0203d36:	6145                	addi	sp,sp,48
ffffffffc0203d38:	8082                	ret
ffffffffc0203d3a:	64e2                	ld	s1,24(sp)
ffffffffc0203d3c:	bfc1                	j	ffffffffc0203d0c <user_mem_check+0x68>
ffffffffc0203d3e:	64e2                	ld	s1,24(sp)
ffffffffc0203d40:	6942                	ld	s2,16(sp)
ffffffffc0203d42:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203d44:	4505                	li	a0,1
ffffffffc0203d46:	b7e1                	j	ffffffffc0203d0e <user_mem_check+0x6a>

ffffffffc0203d48 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203d48:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203d4a:	9402                	jalr	s0

	jal do_exit
ffffffffc0203d4c:	586000ef          	jal	ffffffffc02042d2 <do_exit>

ffffffffc0203d50 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203d50:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d52:	14800513          	li	a0,328
{
ffffffffc0203d56:	e022                	sd	s0,0(sp)
ffffffffc0203d58:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d5a:	e9bfd0ef          	jal	ffffffffc0201bf4 <kmalloc>
ffffffffc0203d5e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203d60:	cd35                	beqz	a0,ffffffffc0203ddc <alloc_proc+0x8c>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
ffffffffc0203d62:	57fd                	li	a5,-1
ffffffffc0203d64:	1782                	slli	a5,a5,0x20
ffffffffc0203d66:	e11c                	sd	a5,0(a0)
        // 初始化进程ID为-1（无效ID）
        proc->pid = -1;
        // 初始化运行次数为0
        proc->runs = 0;
ffffffffc0203d68:	00052423          	sw	zero,8(a0)
        // 初始化内核栈地址为0
        proc->kstack = 0;
ffffffffc0203d6c:	00053823          	sd	zero,16(a0)
        // 初始化不需要重新调度
        proc->need_resched = 0;
ffffffffc0203d70:	00053c23          	sd	zero,24(a0)
        // 初始化父进程指针为NULL
        proc->parent = NULL;
ffffffffc0203d74:	02053023          	sd	zero,32(a0)
        // 初始化内存管理结构为NULL
        proc->mm = NULL;
ffffffffc0203d78:	02053423          	sd	zero,40(a0)
        // 初始化上下文结构体（全部设为0）
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203d7c:	07000613          	li	a2,112
ffffffffc0203d80:	4581                	li	a1,0
ffffffffc0203d82:	03050513          	addi	a0,a0,48
ffffffffc0203d86:	313010ef          	jal	ffffffffc0205898 <memset>
        // 初始化陷阱帧指针为NULL
        proc->tf = NULL;
        // 初始化页目录基址为boot_pgdir
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203d8a:	000b2797          	auipc	a5,0xb2
ffffffffc0203d8e:	9867b783          	ld	a5,-1658(a5) # ffffffffc02b5710 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203d92:	0a043023          	sd	zero,160(s0)
        // 初始化标志位为0
        proc->flags = 0;
ffffffffc0203d96:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203d9a:	f45c                	sd	a5,168(s0)
        // 初始化进程名称为空字符串
        memset(proc->name, 0, PROC_NAME_LEN + 1); 
ffffffffc0203d9c:	0b440513          	addi	a0,s0,180
ffffffffc0203da0:	4641                	li	a2,16
ffffffffc0203da2:	4581                	li	a1,0
ffffffffc0203da4:	2f5010ef          	jal	ffffffffc0205898 <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203da8:	11040793          	addi	a5,s0,272
        proc->wait_state = 0; 
ffffffffc0203dac:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;  
ffffffffc0203db0:	10043023          	sd	zero,256(s0)
ffffffffc0203db4:	0e043c23          	sd	zero,248(s0)
ffffffffc0203db8:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203dbc:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203dc0:	12042023          	sw	zero,288(s0)
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
ffffffffc0203dc4:	12043423          	sd	zero,296(s0)
ffffffffc0203dc8:	12043c23          	sd	zero,312(s0)
ffffffffc0203dcc:	12043823          	sd	zero,304(s0)
        skew_heap_init(&proc->lab6_run_pool);
        proc->lab6_stride = 0;
ffffffffc0203dd0:	14043023          	sd	zero,320(s0)
    elm->prev = elm->next = elm;
ffffffffc0203dd4:	10f43c23          	sd	a5,280(s0)
ffffffffc0203dd8:	10f43823          	sd	a5,272(s0)
        proc->lab6_priority = 0;
    }
    return proc;
}
ffffffffc0203ddc:	60a2                	ld	ra,8(sp)
ffffffffc0203dde:	8522                	mv	a0,s0
ffffffffc0203de0:	6402                	ld	s0,0(sp)
ffffffffc0203de2:	0141                	addi	sp,sp,16
ffffffffc0203de4:	8082                	ret

ffffffffc0203de6 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203de6:	000b2797          	auipc	a5,0xb2
ffffffffc0203dea:	95a7b783          	ld	a5,-1702(a5) # ffffffffc02b5740 <current>
ffffffffc0203dee:	73c8                	ld	a0,160(a5)
ffffffffc0203df0:	892fd06f          	j	ffffffffc0200e82 <forkrets>

ffffffffc0203df4 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203df4:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203df6:	1141                	addi	sp,sp,-16
ffffffffc0203df8:	e406                	sd	ra,8(sp)
ffffffffc0203dfa:	c02007b7          	lui	a5,0xc0200
ffffffffc0203dfe:	02f6ee63          	bltu	a3,a5,ffffffffc0203e3a <put_pgdir+0x46>
ffffffffc0203e02:	000b2717          	auipc	a4,0xb2
ffffffffc0203e06:	91e73703          	ld	a4,-1762(a4) # ffffffffc02b5720 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203e0a:	000b2797          	auipc	a5,0xb2
ffffffffc0203e0e:	91e7b783          	ld	a5,-1762(a5) # ffffffffc02b5728 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203e12:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203e14:	82b1                	srli	a3,a3,0xc
ffffffffc0203e16:	02f6fe63          	bgeu	a3,a5,ffffffffc0203e52 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203e1a:	00004797          	auipc	a5,0x4
ffffffffc0203e1e:	31e7b783          	ld	a5,798(a5) # ffffffffc0208138 <nbase>
ffffffffc0203e22:	000b2517          	auipc	a0,0xb2
ffffffffc0203e26:	90e53503          	ld	a0,-1778(a0) # ffffffffc02b5730 <pages>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203e2a:	60a2                	ld	ra,8(sp)
ffffffffc0203e2c:	8e9d                	sub	a3,a3,a5
ffffffffc0203e2e:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203e30:	4585                	li	a1,1
ffffffffc0203e32:	9536                	add	a0,a0,a3
}
ffffffffc0203e34:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203e36:	fbbfd06f          	j	ffffffffc0201df0 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203e3a:	00003617          	auipc	a2,0x3
ffffffffc0203e3e:	8b660613          	addi	a2,a2,-1866 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc0203e42:	07700593          	li	a1,119
ffffffffc0203e46:	00003517          	auipc	a0,0x3
ffffffffc0203e4a:	82a50513          	addi	a0,a0,-2006 # ffffffffc0206670 <etext+0xdae>
ffffffffc0203e4e:	dfcfc0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203e52:	00003617          	auipc	a2,0x3
ffffffffc0203e56:	8c660613          	addi	a2,a2,-1850 # ffffffffc0206718 <etext+0xe56>
ffffffffc0203e5a:	06900593          	li	a1,105
ffffffffc0203e5e:	00003517          	auipc	a0,0x3
ffffffffc0203e62:	81250513          	addi	a0,a0,-2030 # ffffffffc0206670 <etext+0xdae>
ffffffffc0203e66:	de4fc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0203e6a <proc_run>:
    if (proc != current)
ffffffffc0203e6a:	000b2697          	auipc	a3,0xb2
ffffffffc0203e6e:	8d66b683          	ld	a3,-1834(a3) # ffffffffc02b5740 <current>
ffffffffc0203e72:	04a68463          	beq	a3,a0,ffffffffc0203eba <proc_run+0x50>
{
ffffffffc0203e76:	1101                	addi	sp,sp,-32
ffffffffc0203e78:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e7a:	100027f3          	csrr	a5,sstatus
ffffffffc0203e7e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203e80:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e82:	ef8d                	bnez	a5,ffffffffc0203ebc <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203e84:	755c                	ld	a5,168(a0)
ffffffffc0203e86:	577d                	li	a4,-1
ffffffffc0203e88:	177e                	slli	a4,a4,0x3f
ffffffffc0203e8a:	83b1                	srli	a5,a5,0xc
ffffffffc0203e8c:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203e8e:	000b2597          	auipc	a1,0xb2
ffffffffc0203e92:	8aa5b923          	sd	a0,-1870(a1) # ffffffffc02b5740 <current>
ffffffffc0203e96:	8fd9                	or	a5,a5,a4
ffffffffc0203e98:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203e9c:	03050593          	addi	a1,a0,48
ffffffffc0203ea0:	03068513          	addi	a0,a3,48
ffffffffc0203ea4:	14e010ef          	jal	ffffffffc0204ff2 <switch_to>
    if (flag)
ffffffffc0203ea8:	6602                	ld	a2,0(sp)
ffffffffc0203eaa:	e601                	bnez	a2,ffffffffc0203eb2 <proc_run+0x48>
}
ffffffffc0203eac:	60e2                	ld	ra,24(sp)
ffffffffc0203eae:	6105                	addi	sp,sp,32
ffffffffc0203eb0:	8082                	ret
ffffffffc0203eb2:	60e2                	ld	ra,24(sp)
ffffffffc0203eb4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203eb6:	a43fc06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc0203eba:	8082                	ret
ffffffffc0203ebc:	e42a                	sd	a0,8(sp)
ffffffffc0203ebe:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0203ec0:	a3ffc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0203ec4:	6522                	ld	a0,8(sp)
ffffffffc0203ec6:	6682                	ld	a3,0(sp)
ffffffffc0203ec8:	4605                	li	a2,1
ffffffffc0203eca:	bf6d                	j	ffffffffc0203e84 <proc_run+0x1a>

ffffffffc0203ecc <do_fork>:
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203ecc:	000b2797          	auipc	a5,0xb2
ffffffffc0203ed0:	86c7a783          	lw	a5,-1940(a5) # ffffffffc02b5738 <nr_process>
{
ffffffffc0203ed4:	7159                	addi	sp,sp,-112
ffffffffc0203ed6:	e4ce                	sd	s3,72(sp)
ffffffffc0203ed8:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203eda:	6985                	lui	s3,0x1
ffffffffc0203edc:	3337d463          	bge	a5,s3,ffffffffc0204204 <do_fork+0x338>
ffffffffc0203ee0:	f0a2                	sd	s0,96(sp)
ffffffffc0203ee2:	eca6                	sd	s1,88(sp)
ffffffffc0203ee4:	e8ca                	sd	s2,80(sp)
ffffffffc0203ee6:	e86a                	sd	s10,16(sp)
ffffffffc0203ee8:	892e                	mv	s2,a1
ffffffffc0203eea:	84b2                	mv	s1,a2
ffffffffc0203eec:	8d2a                	mv	s10,a0
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    //    1. call alloc_proc to allocate a proc_struct
    if ((proc = alloc_proc()) == NULL){
ffffffffc0203eee:	e63ff0ef          	jal	ffffffffc0203d50 <alloc_proc>
ffffffffc0203ef2:	842a                	mv	s0,a0
ffffffffc0203ef4:	2e050463          	beqz	a0,ffffffffc02041dc <do_fork+0x310>
ffffffffc0203ef8:	f45e                	sd	s7,40(sp)
        goto fork_out;
    }
    proc->parent = current;
ffffffffc0203efa:	000b2b97          	auipc	s7,0xb2
ffffffffc0203efe:	846b8b93          	addi	s7,s7,-1978 # ffffffffc02b5740 <current>
ffffffffc0203f02:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f06:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203f08:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // set current process's wait_state is 0
ffffffffc0203f0a:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f0e:	ea9fd0ef          	jal	ffffffffc0201db6 <alloc_pages>
    if (page != NULL)
ffffffffc0203f12:	2c050163          	beqz	a0,ffffffffc02041d4 <do_fork+0x308>
ffffffffc0203f16:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc0203f18:	000b2a17          	auipc	s4,0xb2
ffffffffc0203f1c:	818a0a13          	addi	s4,s4,-2024 # ffffffffc02b5730 <pages>
ffffffffc0203f20:	000a3783          	ld	a5,0(s4)
ffffffffc0203f24:	fc56                	sd	s5,56(sp)
ffffffffc0203f26:	00004a97          	auipc	s5,0x4
ffffffffc0203f2a:	212a8a93          	addi	s5,s5,530 # ffffffffc0208138 <nbase>
ffffffffc0203f2e:	000ab703          	ld	a4,0(s5)
ffffffffc0203f32:	40f506b3          	sub	a3,a0,a5
ffffffffc0203f36:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc0203f38:	000b1b17          	auipc	s6,0xb1
ffffffffc0203f3c:	7f0b0b13          	addi	s6,s6,2032 # ffffffffc02b5728 <npage>
ffffffffc0203f40:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc0203f42:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203f44:	5cfd                	li	s9,-1
ffffffffc0203f46:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0203f4a:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203f4c:	00ccdc93          	srli	s9,s9,0xc
ffffffffc0203f50:	0196f633          	and	a2,a3,s9
ffffffffc0203f54:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f56:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203f58:	2cf67463          	bgeu	a2,a5,ffffffffc0204220 <do_fork+0x354>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203f5c:	000bb603          	ld	a2,0(s7)
ffffffffc0203f60:	000b1b97          	auipc	s7,0xb1
ffffffffc0203f64:	7c0b8b93          	addi	s7,s7,1984 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0203f68:	000bb783          	ld	a5,0(s7)
ffffffffc0203f6c:	02863c03          	ld	s8,40(a2)
ffffffffc0203f70:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203f72:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0203f74:	020c0863          	beqz	s8,ffffffffc0203fa4 <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc0203f78:	100d7793          	andi	a5,s10,256
ffffffffc0203f7c:	18078063          	beqz	a5,ffffffffc02040fc <do_fork+0x230>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203f80:	030c2703          	lw	a4,48(s8)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f84:	018c3783          	ld	a5,24(s8)
ffffffffc0203f88:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f8c:	2705                	addiw	a4,a4,1
ffffffffc0203f8e:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc0203f92:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f96:	2ad7ed63          	bltu	a5,a3,ffffffffc0204250 <do_fork+0x384>
ffffffffc0203f9a:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f9e:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203fa0:	8f99                	sub	a5,a5,a4
ffffffffc0203fa2:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203fa4:	6789                	lui	a5,0x2
ffffffffc0203fa6:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7060>
ffffffffc0203faa:	96be                	add	a3,a3,a5
ffffffffc0203fac:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0203fae:	87b6                	mv	a5,a3
ffffffffc0203fb0:	12048713          	addi	a4,s1,288
ffffffffc0203fb4:	6890                	ld	a2,16(s1)
ffffffffc0203fb6:	6088                	ld	a0,0(s1)
ffffffffc0203fb8:	648c                	ld	a1,8(s1)
ffffffffc0203fba:	eb90                	sd	a2,16(a5)
ffffffffc0203fbc:	e388                	sd	a0,0(a5)
ffffffffc0203fbe:	e78c                	sd	a1,8(a5)
ffffffffc0203fc0:	6c90                	ld	a2,24(s1)
ffffffffc0203fc2:	02048493          	addi	s1,s1,32
ffffffffc0203fc6:	02078793          	addi	a5,a5,32
ffffffffc0203fca:	fec7bc23          	sd	a2,-8(a5)
ffffffffc0203fce:	fee493e3          	bne	s1,a4,ffffffffc0203fb4 <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc0203fd2:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203fd6:	20090963          	beqz	s2,ffffffffc02041e8 <do_fork+0x31c>
    if (++last_pid >= MAX_PID)
ffffffffc0203fda:	000ad517          	auipc	a0,0xad
ffffffffc0203fde:	2aa52503          	lw	a0,682(a0) # ffffffffc02b1284 <last_pid.1>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203fe2:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203fe6:	00000797          	auipc	a5,0x0
ffffffffc0203fea:	e0078793          	addi	a5,a5,-512 # ffffffffc0203de6 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203fee:	2505                	addiw	a0,a0,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203ff0:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203ff2:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc0203ff4:	000ad717          	auipc	a4,0xad
ffffffffc0203ff8:	28a72823          	sw	a0,656(a4) # ffffffffc02b1284 <last_pid.1>
ffffffffc0203ffc:	6789                	lui	a5,0x2
ffffffffc0203ffe:	1ef55763          	bge	a0,a5,ffffffffc02041ec <do_fork+0x320>
    if (last_pid >= next_safe)
ffffffffc0204002:	000ad797          	auipc	a5,0xad
ffffffffc0204006:	27e7a783          	lw	a5,638(a5) # ffffffffc02b1280 <next_safe.0>
ffffffffc020400a:	000b1497          	auipc	s1,0xb1
ffffffffc020400e:	69648493          	addi	s1,s1,1686 # ffffffffc02b56a0 <proc_list>
ffffffffc0204012:	06f54563          	blt	a0,a5,ffffffffc020407c <do_fork+0x1b0>
    return listelm->next;
ffffffffc0204016:	000b1497          	auipc	s1,0xb1
ffffffffc020401a:	68a48493          	addi	s1,s1,1674 # ffffffffc02b56a0 <proc_list>
ffffffffc020401e:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0204022:	6789                	lui	a5,0x2
ffffffffc0204024:	000ad717          	auipc	a4,0xad
ffffffffc0204028:	24f72e23          	sw	a5,604(a4) # ffffffffc02b1280 <next_safe.0>
ffffffffc020402c:	86aa                	mv	a3,a0
ffffffffc020402e:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204030:	04988063          	beq	a7,s1,ffffffffc0204070 <do_fork+0x1a4>
ffffffffc0204034:	882e                	mv	a6,a1
ffffffffc0204036:	87c6                	mv	a5,a7
ffffffffc0204038:	6609                	lui	a2,0x2
ffffffffc020403a:	a811                	j	ffffffffc020404e <do_fork+0x182>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020403c:	00e6d663          	bge	a3,a4,ffffffffc0204048 <do_fork+0x17c>
ffffffffc0204040:	00c75463          	bge	a4,a2,ffffffffc0204048 <do_fork+0x17c>
                next_safe = proc->pid;
ffffffffc0204044:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204046:	4805                	li	a6,1
ffffffffc0204048:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020404a:	00978d63          	beq	a5,s1,ffffffffc0204064 <do_fork+0x198>
            if (proc->pid == last_pid)
ffffffffc020404e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x7004>
ffffffffc0204052:	fed715e3          	bne	a4,a3,ffffffffc020403c <do_fork+0x170>
                if (++last_pid >= next_safe)
ffffffffc0204056:	2685                	addiw	a3,a3,1
ffffffffc0204058:	1ac6d063          	bge	a3,a2,ffffffffc02041f8 <do_fork+0x32c>
ffffffffc020405c:	679c                	ld	a5,8(a5)
ffffffffc020405e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204060:	fe9797e3          	bne	a5,s1,ffffffffc020404e <do_fork+0x182>
ffffffffc0204064:	00080663          	beqz	a6,ffffffffc0204070 <do_fork+0x1a4>
ffffffffc0204068:	000ad797          	auipc	a5,0xad
ffffffffc020406c:	20c7ac23          	sw	a2,536(a5) # ffffffffc02b1280 <next_safe.0>
ffffffffc0204070:	c591                	beqz	a1,ffffffffc020407c <do_fork+0x1b0>
ffffffffc0204072:	000ad797          	auipc	a5,0xad
ffffffffc0204076:	20d7a923          	sw	a3,530(a5) # ffffffffc02b1284 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020407a:	8536                	mv	a0,a3
        goto bad_fork_cleanup_kstack;
    }
    //    4. call copy_thread to setup tf & context in proc_struct
    copy_thread(proc, stack, tf);
    //    5. insert proc_struct into hash_list && proc_list, set relation links
    proc->pid = get_pid();
ffffffffc020407c:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020407e:	45a9                	li	a1,10
ffffffffc0204080:	382010ef          	jal	ffffffffc0205402 <hash32>
ffffffffc0204084:	02051793          	slli	a5,a0,0x20
ffffffffc0204088:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020408c:	000ad797          	auipc	a5,0xad
ffffffffc0204090:	61478793          	addi	a5,a5,1556 # ffffffffc02b16a0 <hash_list>
ffffffffc0204094:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204096:	6518                	ld	a4,8(a0)
ffffffffc0204098:	0d840793          	addi	a5,s0,216
ffffffffc020409c:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc020409e:	e31c                	sd	a5,0(a4)
ffffffffc02040a0:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02040a2:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02040a4:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040a8:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc02040aa:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02040ac:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc02040ae:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040b2:	7b74                	ld	a3,240(a4)
ffffffffc02040b4:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc02040b6:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02040b8:	e464                	sd	s1,200(s0)
ffffffffc02040ba:	10d43023          	sd	a3,256(s0)
ffffffffc02040be:	c299                	beqz	a3,ffffffffc02040c4 <do_fork+0x1f8>
        proc->optr->yptr = proc;
ffffffffc02040c0:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc02040c2:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc02040c4:	000b1797          	auipc	a5,0xb1
ffffffffc02040c8:	6747a783          	lw	a5,1652(a5) # ffffffffc02b5738 <nr_process>
    proc->parent->cptr = proc;
ffffffffc02040cc:	fb60                	sd	s0,240(a4)
    hash_proc(proc);
    set_links(proc);
    //    6. call wakeup_proc to make the new child process RUNNABLE
    wakeup_proc(proc);
ffffffffc02040ce:	8522                	mv	a0,s0
    nr_process++;
ffffffffc02040d0:	2785                	addiw	a5,a5,1
ffffffffc02040d2:	000b1717          	auipc	a4,0xb1
ffffffffc02040d6:	66f72323          	sw	a5,1638(a4) # ffffffffc02b5738 <nr_process>
    wakeup_proc(proc);
ffffffffc02040da:	07e010ef          	jal	ffffffffc0205158 <wakeup_proc>
    //    7. set ret vaule using child proc's pid
    ret = proc->pid;
ffffffffc02040de:	4048                	lw	a0,4(s0)
ffffffffc02040e0:	64e6                	ld	s1,88(sp)
ffffffffc02040e2:	7406                	ld	s0,96(sp)
ffffffffc02040e4:	6946                	ld	s2,80(sp)
ffffffffc02040e6:	6a06                	ld	s4,64(sp)
ffffffffc02040e8:	7ae2                	ld	s5,56(sp)
ffffffffc02040ea:	7b42                	ld	s6,48(sp)
ffffffffc02040ec:	7ba2                	ld	s7,40(sp)
ffffffffc02040ee:	7c02                	ld	s8,32(sp)
ffffffffc02040f0:	6ce2                	ld	s9,24(sp)
ffffffffc02040f2:	6d42                	ld	s10,16(sp)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc02040f4:	70a6                	ld	ra,104(sp)
ffffffffc02040f6:	69a6                	ld	s3,72(sp)
ffffffffc02040f8:	6165                	addi	sp,sp,112
ffffffffc02040fa:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc02040fc:	e43a                	sd	a4,8(sp)
ffffffffc02040fe:	d1aff0ef          	jal	ffffffffc0203618 <mm_create>
ffffffffc0204102:	8d2a                	mv	s10,a0
ffffffffc0204104:	c959                	beqz	a0,ffffffffc020419a <do_fork+0x2ce>
    if ((page = alloc_page()) == NULL)
ffffffffc0204106:	4505                	li	a0,1
ffffffffc0204108:	caffd0ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc020410c:	c541                	beqz	a0,ffffffffc0204194 <do_fork+0x2c8>
    return page - pages + nbase;
ffffffffc020410e:	000a3683          	ld	a3,0(s4)
ffffffffc0204112:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204114:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0204118:	40d506b3          	sub	a3,a0,a3
ffffffffc020411c:	8699                	srai	a3,a3,0x6
ffffffffc020411e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204120:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc0204124:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204126:	0efcfd63          	bgeu	s9,a5,ffffffffc0204220 <do_fork+0x354>
ffffffffc020412a:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020412e:	000b1597          	auipc	a1,0xb1
ffffffffc0204132:	5ea5b583          	ld	a1,1514(a1) # ffffffffc02b5718 <boot_pgdir_va>
ffffffffc0204136:	864e                	mv	a2,s3
ffffffffc0204138:	00f689b3          	add	s3,a3,a5
ffffffffc020413c:	854e                	mv	a0,s3
ffffffffc020413e:	76c010ef          	jal	ffffffffc02058aa <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204142:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc0204146:	013d3c23          	sd	s3,24(s10) # fffffffffff80018 <end+0x3fcca8b0>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020414a:	4785                	li	a5,1
ffffffffc020414c:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204150:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204154:	03f75793          	srli	a5,a4,0x3f
ffffffffc0204158:	4985                	li	s3,1
ffffffffc020415a:	cb91                	beqz	a5,ffffffffc020416e <do_fork+0x2a2>
    {
        schedule();
ffffffffc020415c:	0f4010ef          	jal	ffffffffc0205250 <schedule>
ffffffffc0204160:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc0204164:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204168:	03f75793          	srli	a5,a4,0x3f
ffffffffc020416c:	fbe5                	bnez	a5,ffffffffc020415c <do_fork+0x290>
        ret = dup_mmap(mm, oldmm);
ffffffffc020416e:	85e2                	mv	a1,s8
ffffffffc0204170:	856a                	mv	a0,s10
ffffffffc0204172:	f02ff0ef          	jal	ffffffffc0203874 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204176:	57f9                	li	a5,-2
ffffffffc0204178:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc020417c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020417e:	0e078663          	beqz	a5,ffffffffc020426a <do_fork+0x39e>
    if ((mm = mm_create()) == NULL)
ffffffffc0204182:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc0204184:	de050ee3          	beqz	a0,ffffffffc0203f80 <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc0204188:	856a                	mv	a0,s10
ffffffffc020418a:	f82ff0ef          	jal	ffffffffc020390c <exit_mmap>
    put_pgdir(mm);
ffffffffc020418e:	856a                	mv	a0,s10
ffffffffc0204190:	c65ff0ef          	jal	ffffffffc0203df4 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204194:	856a                	mv	a0,s10
ffffffffc0204196:	dc0ff0ef          	jal	ffffffffc0203756 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020419a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020419c:	c02007b7          	lui	a5,0xc0200
ffffffffc02041a0:	08f6ec63          	bltu	a3,a5,ffffffffc0204238 <do_fork+0x36c>
ffffffffc02041a4:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc02041a8:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc02041ac:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02041b0:	83b1                	srli	a5,a5,0xc
ffffffffc02041b2:	04e7fb63          	bgeu	a5,a4,ffffffffc0204208 <do_fork+0x33c>
    return &pages[PPN(pa) - nbase];
ffffffffc02041b6:	000ab703          	ld	a4,0(s5)
ffffffffc02041ba:	000a3503          	ld	a0,0(s4)
ffffffffc02041be:	4589                	li	a1,2
ffffffffc02041c0:	8f99                	sub	a5,a5,a4
ffffffffc02041c2:	079a                	slli	a5,a5,0x6
ffffffffc02041c4:	953e                	add	a0,a0,a5
ffffffffc02041c6:	c2bfd0ef          	jal	ffffffffc0201df0 <free_pages>
}
ffffffffc02041ca:	6a06                	ld	s4,64(sp)
ffffffffc02041cc:	7ae2                	ld	s5,56(sp)
ffffffffc02041ce:	7b42                	ld	s6,48(sp)
ffffffffc02041d0:	7c02                	ld	s8,32(sp)
ffffffffc02041d2:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc02041d4:	8522                	mv	a0,s0
ffffffffc02041d6:	ac5fd0ef          	jal	ffffffffc0201c9a <kfree>
ffffffffc02041da:	7ba2                	ld	s7,40(sp)
ffffffffc02041dc:	7406                	ld	s0,96(sp)
ffffffffc02041de:	64e6                	ld	s1,88(sp)
ffffffffc02041e0:	6946                	ld	s2,80(sp)
ffffffffc02041e2:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc02041e4:	5571                	li	a0,-4
    return ret;
ffffffffc02041e6:	b739                	j	ffffffffc02040f4 <do_fork+0x228>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041e8:	8936                	mv	s2,a3
ffffffffc02041ea:	bbc5                	j	ffffffffc0203fda <do_fork+0x10e>
        last_pid = 1;
ffffffffc02041ec:	4505                	li	a0,1
ffffffffc02041ee:	000ad797          	auipc	a5,0xad
ffffffffc02041f2:	08a7ab23          	sw	a0,150(a5) # ffffffffc02b1284 <last_pid.1>
        goto inside;
ffffffffc02041f6:	b505                	j	ffffffffc0204016 <do_fork+0x14a>
                    if (last_pid >= MAX_PID)
ffffffffc02041f8:	6789                	lui	a5,0x2
ffffffffc02041fa:	00f6c363          	blt	a3,a5,ffffffffc0204200 <do_fork+0x334>
                        last_pid = 1;
ffffffffc02041fe:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204200:	4585                	li	a1,1
ffffffffc0204202:	b53d                	j	ffffffffc0204030 <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204204:	556d                	li	a0,-5
ffffffffc0204206:	b5fd                	j	ffffffffc02040f4 <do_fork+0x228>
        panic("pa2page called with invalid pa");
ffffffffc0204208:	00002617          	auipc	a2,0x2
ffffffffc020420c:	51060613          	addi	a2,a2,1296 # ffffffffc0206718 <etext+0xe56>
ffffffffc0204210:	06900593          	li	a1,105
ffffffffc0204214:	00002517          	auipc	a0,0x2
ffffffffc0204218:	45c50513          	addi	a0,a0,1116 # ffffffffc0206670 <etext+0xdae>
ffffffffc020421c:	a2efc0ef          	jal	ffffffffc020044a <__panic>
    return KADDR(page2pa(page));
ffffffffc0204220:	00002617          	auipc	a2,0x2
ffffffffc0204224:	42860613          	addi	a2,a2,1064 # ffffffffc0206648 <etext+0xd86>
ffffffffc0204228:	07100593          	li	a1,113
ffffffffc020422c:	00002517          	auipc	a0,0x2
ffffffffc0204230:	44450513          	addi	a0,a0,1092 # ffffffffc0206670 <etext+0xdae>
ffffffffc0204234:	a16fc0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204238:	00002617          	auipc	a2,0x2
ffffffffc020423c:	4b860613          	addi	a2,a2,1208 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc0204240:	07700593          	li	a1,119
ffffffffc0204244:	00002517          	auipc	a0,0x2
ffffffffc0204248:	42c50513          	addi	a0,a0,1068 # ffffffffc0206670 <etext+0xdae>
ffffffffc020424c:	9fefc0ef          	jal	ffffffffc020044a <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204250:	86be                	mv	a3,a5
ffffffffc0204252:	00002617          	auipc	a2,0x2
ffffffffc0204256:	49e60613          	addi	a2,a2,1182 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc020425a:	1b100593          	li	a1,433
ffffffffc020425e:	00003517          	auipc	a0,0x3
ffffffffc0204262:	de250513          	addi	a0,a0,-542 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204266:	9e4fc0ef          	jal	ffffffffc020044a <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020426a:	00003617          	auipc	a2,0x3
ffffffffc020426e:	dae60613          	addi	a2,a2,-594 # ffffffffc0207018 <etext+0x1756>
ffffffffc0204272:	04000593          	li	a1,64
ffffffffc0204276:	00003517          	auipc	a0,0x3
ffffffffc020427a:	db250513          	addi	a0,a0,-590 # ffffffffc0207028 <etext+0x1766>
ffffffffc020427e:	9ccfc0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204282 <kernel_thread>:
{
ffffffffc0204282:	7129                	addi	sp,sp,-320
ffffffffc0204284:	fa22                	sd	s0,304(sp)
ffffffffc0204286:	f626                	sd	s1,296(sp)
ffffffffc0204288:	f24a                	sd	s2,288(sp)
ffffffffc020428a:	842a                	mv	s0,a0
ffffffffc020428c:	84ae                	mv	s1,a1
ffffffffc020428e:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204290:	850a                	mv	a0,sp
ffffffffc0204292:	12000613          	li	a2,288
ffffffffc0204296:	4581                	li	a1,0
{
ffffffffc0204298:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020429a:	5fe010ef          	jal	ffffffffc0205898 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020429e:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02042a0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02042a2:	100027f3          	csrr	a5,sstatus
ffffffffc02042a6:	edd7f793          	andi	a5,a5,-291
ffffffffc02042aa:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042ae:	860a                	mv	a2,sp
ffffffffc02042b0:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042b4:	00000717          	auipc	a4,0x0
ffffffffc02042b8:	a9470713          	addi	a4,a4,-1388 # ffffffffc0203d48 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042bc:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02042be:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042c0:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042c2:	c0bff0ef          	jal	ffffffffc0203ecc <do_fork>
}
ffffffffc02042c6:	70f2                	ld	ra,312(sp)
ffffffffc02042c8:	7452                	ld	s0,304(sp)
ffffffffc02042ca:	74b2                	ld	s1,296(sp)
ffffffffc02042cc:	7912                	ld	s2,288(sp)
ffffffffc02042ce:	6131                	addi	sp,sp,320
ffffffffc02042d0:	8082                	ret

ffffffffc02042d2 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02042d2:	7179                	addi	sp,sp,-48
ffffffffc02042d4:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042d6:	000b1417          	auipc	s0,0xb1
ffffffffc02042da:	46a40413          	addi	s0,s0,1130 # ffffffffc02b5740 <current>
ffffffffc02042de:	601c                	ld	a5,0(s0)
ffffffffc02042e0:	000b1717          	auipc	a4,0xb1
ffffffffc02042e4:	47073703          	ld	a4,1136(a4) # ffffffffc02b5750 <idleproc>
{
ffffffffc02042e8:	f406                	sd	ra,40(sp)
ffffffffc02042ea:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02042ec:	0ce78b63          	beq	a5,a4,ffffffffc02043c2 <do_exit+0xf0>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042f0:	000b1497          	auipc	s1,0xb1
ffffffffc02042f4:	45848493          	addi	s1,s1,1112 # ffffffffc02b5748 <initproc>
ffffffffc02042f8:	6098                	ld	a4,0(s1)
ffffffffc02042fa:	e84a                	sd	s2,16(sp)
ffffffffc02042fc:	0ee78a63          	beq	a5,a4,ffffffffc02043f0 <do_exit+0x11e>
ffffffffc0204300:	892a                	mv	s2,a0
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc0204302:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc0204304:	c115                	beqz	a0,ffffffffc0204328 <do_exit+0x56>
ffffffffc0204306:	000b1797          	auipc	a5,0xb1
ffffffffc020430a:	40a7b783          	ld	a5,1034(a5) # ffffffffc02b5710 <boot_pgdir_pa>
ffffffffc020430e:	577d                	li	a4,-1
ffffffffc0204310:	177e                	slli	a4,a4,0x3f
ffffffffc0204312:	83b1                	srli	a5,a5,0xc
ffffffffc0204314:	8fd9                	or	a5,a5,a4
ffffffffc0204316:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020431a:	591c                	lw	a5,48(a0)
ffffffffc020431c:	37fd                	addiw	a5,a5,-1
ffffffffc020431e:	d91c                	sw	a5,48(a0)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204320:	cfd5                	beqz	a5,ffffffffc02043dc <do_exit+0x10a>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204322:	601c                	ld	a5,0(s0)
ffffffffc0204324:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204328:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc020432a:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020432e:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204330:	100027f3          	csrr	a5,sstatus
ffffffffc0204334:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204336:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204338:	ebe1                	bnez	a5,ffffffffc0204408 <do_exit+0x136>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc020433a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020433c:	800007b7          	lui	a5,0x80000
ffffffffc0204340:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        proc = current->parent;
ffffffffc0204342:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204344:	0ec52703          	lw	a4,236(a0)
ffffffffc0204348:	0cf70463          	beq	a4,a5,ffffffffc0204410 <do_exit+0x13e>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020434c:	6018                	ld	a4,0(s0)
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020434e:	800005b7          	lui	a1,0x80000
ffffffffc0204352:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        while (current->cptr != NULL)
ffffffffc0204354:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204356:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204358:	e789                	bnez	a5,ffffffffc0204362 <do_exit+0x90>
ffffffffc020435a:	a83d                	j	ffffffffc0204398 <do_exit+0xc6>
ffffffffc020435c:	6018                	ld	a4,0(s0)
ffffffffc020435e:	7b7c                	ld	a5,240(a4)
ffffffffc0204360:	cf85                	beqz	a5,ffffffffc0204398 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204362:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204366:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204368:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc020436a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020436e:	7978                	ld	a4,240(a0)
ffffffffc0204370:	10e7b023          	sd	a4,256(a5)
ffffffffc0204374:	c311                	beqz	a4,ffffffffc0204378 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204376:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204378:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020437a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020437c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020437e:	fcc71fe3          	bne	a4,a2,ffffffffc020435c <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204382:	0ec52783          	lw	a5,236(a0)
ffffffffc0204386:	fcb79be3          	bne	a5,a1,ffffffffc020435c <do_exit+0x8a>
                {
                    wakeup_proc(initproc);
ffffffffc020438a:	5cf000ef          	jal	ffffffffc0205158 <wakeup_proc>
ffffffffc020438e:	800005b7          	lui	a1,0x80000
ffffffffc0204392:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
ffffffffc0204394:	460d                	li	a2,3
ffffffffc0204396:	b7d9                	j	ffffffffc020435c <do_exit+0x8a>
    if (flag)
ffffffffc0204398:	02091263          	bnez	s2,ffffffffc02043bc <do_exit+0xea>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020439c:	6b5000ef          	jal	ffffffffc0205250 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02043a0:	601c                	ld	a5,0(s0)
ffffffffc02043a2:	00003617          	auipc	a2,0x3
ffffffffc02043a6:	cd660613          	addi	a2,a2,-810 # ffffffffc0207078 <etext+0x17b6>
ffffffffc02043aa:	25a00593          	li	a1,602
ffffffffc02043ae:	43d4                	lw	a3,4(a5)
ffffffffc02043b0:	00003517          	auipc	a0,0x3
ffffffffc02043b4:	c9050513          	addi	a0,a0,-880 # ffffffffc0207040 <etext+0x177e>
ffffffffc02043b8:	892fc0ef          	jal	ffffffffc020044a <__panic>
        intr_enable();
ffffffffc02043bc:	d3cfc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc02043c0:	bff1                	j	ffffffffc020439c <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02043c2:	00003617          	auipc	a2,0x3
ffffffffc02043c6:	c9660613          	addi	a2,a2,-874 # ffffffffc0207058 <etext+0x1796>
ffffffffc02043ca:	22600593          	li	a1,550
ffffffffc02043ce:	00003517          	auipc	a0,0x3
ffffffffc02043d2:	c7250513          	addi	a0,a0,-910 # ffffffffc0207040 <etext+0x177e>
ffffffffc02043d6:	e84a                	sd	s2,16(sp)
ffffffffc02043d8:	872fc0ef          	jal	ffffffffc020044a <__panic>
            exit_mmap(mm);
ffffffffc02043dc:	e42a                	sd	a0,8(sp)
ffffffffc02043de:	d2eff0ef          	jal	ffffffffc020390c <exit_mmap>
            put_pgdir(mm);
ffffffffc02043e2:	6522                	ld	a0,8(sp)
ffffffffc02043e4:	a11ff0ef          	jal	ffffffffc0203df4 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043e8:	6522                	ld	a0,8(sp)
ffffffffc02043ea:	b6cff0ef          	jal	ffffffffc0203756 <mm_destroy>
ffffffffc02043ee:	bf15                	j	ffffffffc0204322 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02043f0:	00003617          	auipc	a2,0x3
ffffffffc02043f4:	c7860613          	addi	a2,a2,-904 # ffffffffc0207068 <etext+0x17a6>
ffffffffc02043f8:	22a00593          	li	a1,554
ffffffffc02043fc:	00003517          	auipc	a0,0x3
ffffffffc0204400:	c4450513          	addi	a0,a0,-956 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204404:	846fc0ef          	jal	ffffffffc020044a <__panic>
        intr_disable();
ffffffffc0204408:	cf6fc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc020440c:	4905                	li	s2,1
ffffffffc020440e:	b735                	j	ffffffffc020433a <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc0204410:	549000ef          	jal	ffffffffc0205158 <wakeup_proc>
ffffffffc0204414:	bf25                	j	ffffffffc020434c <do_exit+0x7a>

ffffffffc0204416 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204416:	7179                	addi	sp,sp,-48
ffffffffc0204418:	ec26                	sd	s1,24(sp)
ffffffffc020441a:	e84a                	sd	s2,16(sp)
ffffffffc020441c:	e44e                	sd	s3,8(sp)
ffffffffc020441e:	f406                	sd	ra,40(sp)
ffffffffc0204420:	f022                	sd	s0,32(sp)
ffffffffc0204422:	84aa                	mv	s1,a0
ffffffffc0204424:	892e                	mv	s2,a1
ffffffffc0204426:	000b1997          	auipc	s3,0xb1
ffffffffc020442a:	31a98993          	addi	s3,s3,794 # ffffffffc02b5740 <current>

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0)
ffffffffc020442e:	cd19                	beqz	a0,ffffffffc020444c <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204430:	6789                	lui	a5,0x2
ffffffffc0204432:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f42>
ffffffffc0204434:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204438:	12e7f563          	bgeu	a5,a4,ffffffffc0204562 <do_wait.part.0+0x14c>
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020443c:	70a2                	ld	ra,40(sp)
ffffffffc020443e:	7402                	ld	s0,32(sp)
ffffffffc0204440:	64e2                	ld	s1,24(sp)
ffffffffc0204442:	6942                	ld	s2,16(sp)
ffffffffc0204444:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204446:	5579                	li	a0,-2
}
ffffffffc0204448:	6145                	addi	sp,sp,48
ffffffffc020444a:	8082                	ret
        proc = current->cptr;
ffffffffc020444c:	0009b703          	ld	a4,0(s3)
ffffffffc0204450:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204452:	d46d                	beqz	s0,ffffffffc020443c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204454:	468d                	li	a3,3
ffffffffc0204456:	a021                	j	ffffffffc020445e <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204458:	10043403          	ld	s0,256(s0)
ffffffffc020445c:	c075                	beqz	s0,ffffffffc0204540 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020445e:	401c                	lw	a5,0(s0)
ffffffffc0204460:	fed79ce3          	bne	a5,a3,ffffffffc0204458 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204464:	000b1797          	auipc	a5,0xb1
ffffffffc0204468:	2ec7b783          	ld	a5,748(a5) # ffffffffc02b5750 <idleproc>
ffffffffc020446c:	14878263          	beq	a5,s0,ffffffffc02045b0 <do_wait.part.0+0x19a>
ffffffffc0204470:	000b1797          	auipc	a5,0xb1
ffffffffc0204474:	2d87b783          	ld	a5,728(a5) # ffffffffc02b5748 <initproc>
ffffffffc0204478:	12f40c63          	beq	s0,a5,ffffffffc02045b0 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020447c:	00090663          	beqz	s2,ffffffffc0204488 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc0204480:	0e842783          	lw	a5,232(s0)
ffffffffc0204484:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204488:	100027f3          	csrr	a5,sstatus
ffffffffc020448c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020448e:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204490:	10079963          	bnez	a5,ffffffffc02045a2 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204494:	6c74                	ld	a3,216(s0)
ffffffffc0204496:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204498:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020449c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020449e:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02044a0:	6474                	ld	a3,200(s0)
ffffffffc02044a2:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02044a4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02044a6:	e314                	sd	a3,0(a4)
ffffffffc02044a8:	c789                	beqz	a5,ffffffffc02044b2 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02044aa:	7c78                	ld	a4,248(s0)
ffffffffc02044ac:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02044ae:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02044b2:	7c78                	ld	a4,248(s0)
ffffffffc02044b4:	c36d                	beqz	a4,ffffffffc0204596 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc02044b6:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc02044ba:	000b1797          	auipc	a5,0xb1
ffffffffc02044be:	27e7a783          	lw	a5,638(a5) # ffffffffc02b5738 <nr_process>
ffffffffc02044c2:	37fd                	addiw	a5,a5,-1
ffffffffc02044c4:	000b1717          	auipc	a4,0xb1
ffffffffc02044c8:	26f72a23          	sw	a5,628(a4) # ffffffffc02b5738 <nr_process>
    if (flag)
ffffffffc02044cc:	e271                	bnez	a2,ffffffffc0204590 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02044ce:	6814                	ld	a3,16(s0)
ffffffffc02044d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02044d4:	10f6e663          	bltu	a3,a5,ffffffffc02045e0 <do_wait.part.0+0x1ca>
ffffffffc02044d8:	000b1717          	auipc	a4,0xb1
ffffffffc02044dc:	24873703          	ld	a4,584(a4) # ffffffffc02b5720 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02044e0:	000b1797          	auipc	a5,0xb1
ffffffffc02044e4:	2487b783          	ld	a5,584(a5) # ffffffffc02b5728 <npage>
    return pa2page(PADDR(kva));
ffffffffc02044e8:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02044ea:	82b1                	srli	a3,a3,0xc
ffffffffc02044ec:	0cf6fe63          	bgeu	a3,a5,ffffffffc02045c8 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02044f0:	00004797          	auipc	a5,0x4
ffffffffc02044f4:	c487b783          	ld	a5,-952(a5) # ffffffffc0208138 <nbase>
ffffffffc02044f8:	000b1517          	auipc	a0,0xb1
ffffffffc02044fc:	23853503          	ld	a0,568(a0) # ffffffffc02b5730 <pages>
ffffffffc0204500:	4589                	li	a1,2
ffffffffc0204502:	8e9d                	sub	a3,a3,a5
ffffffffc0204504:	069a                	slli	a3,a3,0x6
ffffffffc0204506:	9536                	add	a0,a0,a3
ffffffffc0204508:	8e9fd0ef          	jal	ffffffffc0201df0 <free_pages>
    kfree(proc);
ffffffffc020450c:	8522                	mv	a0,s0
ffffffffc020450e:	f8cfd0ef          	jal	ffffffffc0201c9a <kfree>
}
ffffffffc0204512:	70a2                	ld	ra,40(sp)
ffffffffc0204514:	7402                	ld	s0,32(sp)
ffffffffc0204516:	64e2                	ld	s1,24(sp)
ffffffffc0204518:	6942                	ld	s2,16(sp)
ffffffffc020451a:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc020451c:	4501                	li	a0,0
}
ffffffffc020451e:	6145                	addi	sp,sp,48
ffffffffc0204520:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204522:	000b1997          	auipc	s3,0xb1
ffffffffc0204526:	21e98993          	addi	s3,s3,542 # ffffffffc02b5740 <current>
ffffffffc020452a:	0009b703          	ld	a4,0(s3)
ffffffffc020452e:	f487b683          	ld	a3,-184(a5)
ffffffffc0204532:	f0e695e3          	bne	a3,a4,ffffffffc020443c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204536:	f287a603          	lw	a2,-216(a5)
ffffffffc020453a:	468d                	li	a3,3
ffffffffc020453c:	06d60063          	beq	a2,a3,ffffffffc020459c <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204540:	800007b7          	lui	a5,0x80000
ffffffffc0204544:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ac1>
        current->state = PROC_SLEEPING;
ffffffffc0204546:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204548:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc020454c:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc020454e:	503000ef          	jal	ffffffffc0205250 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204552:	0009b783          	ld	a5,0(s3)
ffffffffc0204556:	0b07a783          	lw	a5,176(a5)
ffffffffc020455a:	8b85                	andi	a5,a5,1
ffffffffc020455c:	e7b9                	bnez	a5,ffffffffc02045aa <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc020455e:	ee0487e3          	beqz	s1,ffffffffc020444c <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204562:	45a9                	li	a1,10
ffffffffc0204564:	8526                	mv	a0,s1
ffffffffc0204566:	69d000ef          	jal	ffffffffc0205402 <hash32>
ffffffffc020456a:	02051793          	slli	a5,a0,0x20
ffffffffc020456e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204572:	000ad797          	auipc	a5,0xad
ffffffffc0204576:	12e78793          	addi	a5,a5,302 # ffffffffc02b16a0 <hash_list>
ffffffffc020457a:	953e                	add	a0,a0,a5
ffffffffc020457c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020457e:	a029                	j	ffffffffc0204588 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc0204580:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204584:	f8970fe3          	beq	a4,s1,ffffffffc0204522 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204588:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020458a:	fef51be3          	bne	a0,a5,ffffffffc0204580 <do_wait.part.0+0x16a>
ffffffffc020458e:	b57d                	j	ffffffffc020443c <do_wait.part.0+0x26>
        intr_enable();
ffffffffc0204590:	b68fc0ef          	jal	ffffffffc02008f8 <intr_enable>
ffffffffc0204594:	bf2d                	j	ffffffffc02044ce <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204596:	7018                	ld	a4,32(s0)
ffffffffc0204598:	fb7c                	sd	a5,240(a4)
ffffffffc020459a:	b705                	j	ffffffffc02044ba <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020459c:	f2878413          	addi	s0,a5,-216
ffffffffc02045a0:	b5d1                	j	ffffffffc0204464 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02045a2:	b5cfc0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc02045a6:	4605                	li	a2,1
ffffffffc02045a8:	b5f5                	j	ffffffffc0204494 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02045aa:	555d                	li	a0,-9
ffffffffc02045ac:	d27ff0ef          	jal	ffffffffc02042d2 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02045b0:	00003617          	auipc	a2,0x3
ffffffffc02045b4:	ae860613          	addi	a2,a2,-1304 # ffffffffc0207098 <etext+0x17d6>
ffffffffc02045b8:	37f00593          	li	a1,895
ffffffffc02045bc:	00003517          	auipc	a0,0x3
ffffffffc02045c0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0207040 <etext+0x177e>
ffffffffc02045c4:	e87fb0ef          	jal	ffffffffc020044a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02045c8:	00002617          	auipc	a2,0x2
ffffffffc02045cc:	15060613          	addi	a2,a2,336 # ffffffffc0206718 <etext+0xe56>
ffffffffc02045d0:	06900593          	li	a1,105
ffffffffc02045d4:	00002517          	auipc	a0,0x2
ffffffffc02045d8:	09c50513          	addi	a0,a0,156 # ffffffffc0206670 <etext+0xdae>
ffffffffc02045dc:	e6ffb0ef          	jal	ffffffffc020044a <__panic>
    return pa2page(PADDR(kva));
ffffffffc02045e0:	00002617          	auipc	a2,0x2
ffffffffc02045e4:	11060613          	addi	a2,a2,272 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc02045e8:	07700593          	li	a1,119
ffffffffc02045ec:	00002517          	auipc	a0,0x2
ffffffffc02045f0:	08450513          	addi	a0,a0,132 # ffffffffc0206670 <etext+0xdae>
ffffffffc02045f4:	e57fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc02045f8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045f8:	1141                	addi	sp,sp,-16
ffffffffc02045fa:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045fc:	82dfd0ef          	jal	ffffffffc0201e28 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204600:	df0fd0ef          	jal	ffffffffc0201bf0 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204604:	4601                	li	a2,0
ffffffffc0204606:	4581                	li	a1,0
ffffffffc0204608:	00000517          	auipc	a0,0x0
ffffffffc020460c:	6b050513          	addi	a0,a0,1712 # ffffffffc0204cb8 <user_main>
ffffffffc0204610:	c73ff0ef          	jal	ffffffffc0204282 <kernel_thread>
    if (pid <= 0)
ffffffffc0204614:	00a04563          	bgtz	a0,ffffffffc020461e <init_main+0x26>
ffffffffc0204618:	a071                	j	ffffffffc02046a4 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc020461a:	437000ef          	jal	ffffffffc0205250 <schedule>
    if (code_store != NULL)
ffffffffc020461e:	4581                	li	a1,0
ffffffffc0204620:	4501                	li	a0,0
ffffffffc0204622:	df5ff0ef          	jal	ffffffffc0204416 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204626:	d975                	beqz	a0,ffffffffc020461a <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204628:	00003517          	auipc	a0,0x3
ffffffffc020462c:	ab050513          	addi	a0,a0,-1360 # ffffffffc02070d8 <etext+0x1816>
ffffffffc0204630:	b69fb0ef          	jal	ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204634:	000b1797          	auipc	a5,0xb1
ffffffffc0204638:	1147b783          	ld	a5,276(a5) # ffffffffc02b5748 <initproc>
ffffffffc020463c:	7bf8                	ld	a4,240(a5)
ffffffffc020463e:	e339                	bnez	a4,ffffffffc0204684 <init_main+0x8c>
ffffffffc0204640:	7ff8                	ld	a4,248(a5)
ffffffffc0204642:	e329                	bnez	a4,ffffffffc0204684 <init_main+0x8c>
ffffffffc0204644:	1007b703          	ld	a4,256(a5)
ffffffffc0204648:	ef15                	bnez	a4,ffffffffc0204684 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020464a:	000b1697          	auipc	a3,0xb1
ffffffffc020464e:	0ee6a683          	lw	a3,238(a3) # ffffffffc02b5738 <nr_process>
ffffffffc0204652:	4709                	li	a4,2
ffffffffc0204654:	0ae69463          	bne	a3,a4,ffffffffc02046fc <init_main+0x104>
ffffffffc0204658:	000b1697          	auipc	a3,0xb1
ffffffffc020465c:	04868693          	addi	a3,a3,72 # ffffffffc02b56a0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204660:	6698                	ld	a4,8(a3)
ffffffffc0204662:	0c878793          	addi	a5,a5,200
ffffffffc0204666:	06f71b63          	bne	a4,a5,ffffffffc02046dc <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020466a:	629c                	ld	a5,0(a3)
ffffffffc020466c:	04f71863          	bne	a4,a5,ffffffffc02046bc <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204670:	00003517          	auipc	a0,0x3
ffffffffc0204674:	b5050513          	addi	a0,a0,-1200 # ffffffffc02071c0 <etext+0x18fe>
ffffffffc0204678:	b21fb0ef          	jal	ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020467c:	60a2                	ld	ra,8(sp)
ffffffffc020467e:	4501                	li	a0,0
ffffffffc0204680:	0141                	addi	sp,sp,16
ffffffffc0204682:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204684:	00003697          	auipc	a3,0x3
ffffffffc0204688:	a7c68693          	addi	a3,a3,-1412 # ffffffffc0207100 <etext+0x183e>
ffffffffc020468c:	00002617          	auipc	a2,0x2
ffffffffc0204690:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204694:	3eb00593          	li	a1,1003
ffffffffc0204698:	00003517          	auipc	a0,0x3
ffffffffc020469c:	9a850513          	addi	a0,a0,-1624 # ffffffffc0207040 <etext+0x177e>
ffffffffc02046a0:	dabfb0ef          	jal	ffffffffc020044a <__panic>
        panic("create user_main failed.\n");
ffffffffc02046a4:	00003617          	auipc	a2,0x3
ffffffffc02046a8:	a1460613          	addi	a2,a2,-1516 # ffffffffc02070b8 <etext+0x17f6>
ffffffffc02046ac:	3e200593          	li	a1,994
ffffffffc02046b0:	00003517          	auipc	a0,0x3
ffffffffc02046b4:	99050513          	addi	a0,a0,-1648 # ffffffffc0207040 <etext+0x177e>
ffffffffc02046b8:	d93fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02046bc:	00003697          	auipc	a3,0x3
ffffffffc02046c0:	ad468693          	addi	a3,a3,-1324 # ffffffffc0207190 <etext+0x18ce>
ffffffffc02046c4:	00002617          	auipc	a2,0x2
ffffffffc02046c8:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02046cc:	3ee00593          	li	a1,1006
ffffffffc02046d0:	00003517          	auipc	a0,0x3
ffffffffc02046d4:	97050513          	addi	a0,a0,-1680 # ffffffffc0207040 <etext+0x177e>
ffffffffc02046d8:	d73fb0ef          	jal	ffffffffc020044a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046dc:	00003697          	auipc	a3,0x3
ffffffffc02046e0:	a8468693          	addi	a3,a3,-1404 # ffffffffc0207160 <etext+0x189e>
ffffffffc02046e4:	00002617          	auipc	a2,0x2
ffffffffc02046e8:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206298 <etext+0x9d6>
ffffffffc02046ec:	3ed00593          	li	a1,1005
ffffffffc02046f0:	00003517          	auipc	a0,0x3
ffffffffc02046f4:	95050513          	addi	a0,a0,-1712 # ffffffffc0207040 <etext+0x177e>
ffffffffc02046f8:	d53fb0ef          	jal	ffffffffc020044a <__panic>
    assert(nr_process == 2);
ffffffffc02046fc:	00003697          	auipc	a3,0x3
ffffffffc0204700:	a5468693          	addi	a3,a3,-1452 # ffffffffc0207150 <etext+0x188e>
ffffffffc0204704:	00002617          	auipc	a2,0x2
ffffffffc0204708:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206298 <etext+0x9d6>
ffffffffc020470c:	3ec00593          	li	a1,1004
ffffffffc0204710:	00003517          	auipc	a0,0x3
ffffffffc0204714:	93050513          	addi	a0,a0,-1744 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204718:	d33fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc020471c <do_execve>:
{
ffffffffc020471c:	7171                	addi	sp,sp,-176
ffffffffc020471e:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204720:	000b1d17          	auipc	s10,0xb1
ffffffffc0204724:	020d0d13          	addi	s10,s10,32 # ffffffffc02b5740 <current>
ffffffffc0204728:	000d3783          	ld	a5,0(s10)
{
ffffffffc020472c:	e94a                	sd	s2,144(sp)
ffffffffc020472e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204730:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204734:	84ae                	mv	s1,a1
ffffffffc0204736:	e54e                	sd	s3,136(sp)
ffffffffc0204738:	ec32                	sd	a2,24(sp)
ffffffffc020473a:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020473c:	85aa                	mv	a1,a0
ffffffffc020473e:	8626                	mv	a2,s1
ffffffffc0204740:	854a                	mv	a0,s2
ffffffffc0204742:	4681                	li	a3,0
{
ffffffffc0204744:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204746:	d5eff0ef          	jal	ffffffffc0203ca4 <user_mem_check>
ffffffffc020474a:	46050f63          	beqz	a0,ffffffffc0204bc8 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020474e:	4641                	li	a2,16
ffffffffc0204750:	1808                	addi	a0,sp,48
ffffffffc0204752:	4581                	li	a1,0
ffffffffc0204754:	144010ef          	jal	ffffffffc0205898 <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204758:	47bd                	li	a5,15
ffffffffc020475a:	8626                	mv	a2,s1
ffffffffc020475c:	0e97ef63          	bltu	a5,s1,ffffffffc020485a <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204760:	85ce                	mv	a1,s3
ffffffffc0204762:	1808                	addi	a0,sp,48
ffffffffc0204764:	146010ef          	jal	ffffffffc02058aa <memcpy>
    if (mm != NULL)
ffffffffc0204768:	10090063          	beqz	s2,ffffffffc0204868 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020476c:	00002517          	auipc	a0,0x2
ffffffffc0204770:	6d450513          	addi	a0,a0,1748 # ffffffffc0206e40 <etext+0x157e>
ffffffffc0204774:	a5bfb0ef          	jal	ffffffffc02001ce <cputs>
ffffffffc0204778:	000b1797          	auipc	a5,0xb1
ffffffffc020477c:	f987b783          	ld	a5,-104(a5) # ffffffffc02b5710 <boot_pgdir_pa>
ffffffffc0204780:	577d                	li	a4,-1
ffffffffc0204782:	177e                	slli	a4,a4,0x3f
ffffffffc0204784:	83b1                	srli	a5,a5,0xc
ffffffffc0204786:	8fd9                	or	a5,a5,a4
ffffffffc0204788:	18079073          	csrw	satp,a5
ffffffffc020478c:	03092783          	lw	a5,48(s2)
ffffffffc0204790:	37fd                	addiw	a5,a5,-1
ffffffffc0204792:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204796:	30078563          	beqz	a5,ffffffffc0204aa0 <do_execve+0x384>
        current->mm = NULL;
ffffffffc020479a:	000d3783          	ld	a5,0(s10)
ffffffffc020479e:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02047a2:	e77fe0ef          	jal	ffffffffc0203618 <mm_create>
ffffffffc02047a6:	892a                	mv	s2,a0
ffffffffc02047a8:	22050063          	beqz	a0,ffffffffc02049c8 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc02047ac:	4505                	li	a0,1
ffffffffc02047ae:	e08fd0ef          	jal	ffffffffc0201db6 <alloc_pages>
ffffffffc02047b2:	42050063          	beqz	a0,ffffffffc0204bd2 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc02047b6:	f0e2                	sd	s8,96(sp)
ffffffffc02047b8:	000b1c17          	auipc	s8,0xb1
ffffffffc02047bc:	f78c0c13          	addi	s8,s8,-136 # ffffffffc02b5730 <pages>
ffffffffc02047c0:	000c3783          	ld	a5,0(s8)
ffffffffc02047c4:	f4de                	sd	s7,104(sp)
ffffffffc02047c6:	00004b97          	auipc	s7,0x4
ffffffffc02047ca:	972bbb83          	ld	s7,-1678(s7) # ffffffffc0208138 <nbase>
ffffffffc02047ce:	40f506b3          	sub	a3,a0,a5
ffffffffc02047d2:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02047d4:	000b1c97          	auipc	s9,0xb1
ffffffffc02047d8:	f54c8c93          	addi	s9,s9,-172 # ffffffffc02b5728 <npage>
ffffffffc02047dc:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02047de:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047e0:	5b7d                	li	s6,-1
ffffffffc02047e2:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02047e6:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02047e8:	00cb5713          	srli	a4,s6,0xc
ffffffffc02047ec:	e83a                	sd	a4,16(sp)
ffffffffc02047ee:	fcd6                	sd	s5,120(sp)
ffffffffc02047f0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047f2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047f4:	40f77263          	bgeu	a4,a5,ffffffffc0204bf8 <do_execve+0x4dc>
ffffffffc02047f8:	000b1a97          	auipc	s5,0xb1
ffffffffc02047fc:	f28a8a93          	addi	s5,s5,-216 # ffffffffc02b5720 <va_pa_offset>
ffffffffc0204800:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204804:	000b1597          	auipc	a1,0xb1
ffffffffc0204808:	f145b583          	ld	a1,-236(a1) # ffffffffc02b5718 <boot_pgdir_va>
ffffffffc020480c:	6605                	lui	a2,0x1
ffffffffc020480e:	00f684b3          	add	s1,a3,a5
ffffffffc0204812:	8526                	mv	a0,s1
ffffffffc0204814:	096010ef          	jal	ffffffffc02058aa <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204818:	66e2                	ld	a3,24(sp)
ffffffffc020481a:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020481e:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204822:	4298                	lw	a4,0(a3)
ffffffffc0204824:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b903f>
ffffffffc0204828:	06f70863          	beq	a4,a5,ffffffffc0204898 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc020482c:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc020482e:	854a                	mv	a0,s2
ffffffffc0204830:	dc4ff0ef          	jal	ffffffffc0203df4 <put_pgdir>
ffffffffc0204834:	7ae6                	ld	s5,120(sp)
ffffffffc0204836:	7b46                	ld	s6,112(sp)
ffffffffc0204838:	7ba6                	ld	s7,104(sp)
ffffffffc020483a:	7c06                	ld	s8,96(sp)
ffffffffc020483c:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc020483e:	854a                	mv	a0,s2
ffffffffc0204840:	f17fe0ef          	jal	ffffffffc0203756 <mm_destroy>
    do_exit(ret);
ffffffffc0204844:	8526                	mv	a0,s1
ffffffffc0204846:	f122                	sd	s0,160(sp)
ffffffffc0204848:	e152                	sd	s4,128(sp)
ffffffffc020484a:	fcd6                	sd	s5,120(sp)
ffffffffc020484c:	f8da                	sd	s6,112(sp)
ffffffffc020484e:	f4de                	sd	s7,104(sp)
ffffffffc0204850:	f0e2                	sd	s8,96(sp)
ffffffffc0204852:	ece6                	sd	s9,88(sp)
ffffffffc0204854:	e4ee                	sd	s11,72(sp)
ffffffffc0204856:	a7dff0ef          	jal	ffffffffc02042d2 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc020485a:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc020485c:	85ce                	mv	a1,s3
ffffffffc020485e:	1808                	addi	a0,sp,48
ffffffffc0204860:	04a010ef          	jal	ffffffffc02058aa <memcpy>
    if (mm != NULL)
ffffffffc0204864:	f00914e3          	bnez	s2,ffffffffc020476c <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204868:	000d3783          	ld	a5,0(s10)
ffffffffc020486c:	779c                	ld	a5,40(a5)
ffffffffc020486e:	db95                	beqz	a5,ffffffffc02047a2 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204870:	00003617          	auipc	a2,0x3
ffffffffc0204874:	97060613          	addi	a2,a2,-1680 # ffffffffc02071e0 <etext+0x191e>
ffffffffc0204878:	26600593          	li	a1,614
ffffffffc020487c:	00002517          	auipc	a0,0x2
ffffffffc0204880:	7c450513          	addi	a0,a0,1988 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204884:	f122                	sd	s0,160(sp)
ffffffffc0204886:	e152                	sd	s4,128(sp)
ffffffffc0204888:	fcd6                	sd	s5,120(sp)
ffffffffc020488a:	f8da                	sd	s6,112(sp)
ffffffffc020488c:	f4de                	sd	s7,104(sp)
ffffffffc020488e:	f0e2                	sd	s8,96(sp)
ffffffffc0204890:	ece6                	sd	s9,88(sp)
ffffffffc0204892:	e4ee                	sd	s11,72(sp)
ffffffffc0204894:	bb7fb0ef          	jal	ffffffffc020044a <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204898:	0386d703          	lhu	a4,56(a3)
ffffffffc020489c:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020489e:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048a2:	00371793          	slli	a5,a4,0x3
ffffffffc02048a6:	8f99                	sub	a5,a5,a4
ffffffffc02048a8:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02048aa:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048ac:	97d2                	add	a5,a5,s4
ffffffffc02048ae:	f122                	sd	s0,160(sp)
ffffffffc02048b0:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02048b2:	00fa7e63          	bgeu	s4,a5,ffffffffc02048ce <do_execve+0x1b2>
ffffffffc02048b6:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02048b8:	000a2783          	lw	a5,0(s4)
ffffffffc02048bc:	4705                	li	a4,1
ffffffffc02048be:	10e78763          	beq	a5,a4,ffffffffc02049cc <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc02048c2:	77a2                	ld	a5,40(sp)
ffffffffc02048c4:	038a0a13          	addi	s4,s4,56
ffffffffc02048c8:	fefa68e3          	bltu	s4,a5,ffffffffc02048b8 <do_execve+0x19c>
ffffffffc02048cc:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02048ce:	4701                	li	a4,0
ffffffffc02048d0:	46ad                	li	a3,11
ffffffffc02048d2:	00100637          	lui	a2,0x100
ffffffffc02048d6:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02048da:	854a                	mv	a0,s2
ffffffffc02048dc:	ecdfe0ef          	jal	ffffffffc02037a8 <mm_map>
ffffffffc02048e0:	84aa                	mv	s1,a0
ffffffffc02048e2:	1a051963          	bnez	a0,ffffffffc0204a94 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02048e6:	01893503          	ld	a0,24(s2)
ffffffffc02048ea:	467d                	li	a2,31
ffffffffc02048ec:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02048f0:	c47fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc02048f4:	3a050163          	beqz	a0,ffffffffc0204c96 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048f8:	01893503          	ld	a0,24(s2)
ffffffffc02048fc:	467d                	li	a2,31
ffffffffc02048fe:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204902:	c35fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc0204906:	36050763          	beqz	a0,ffffffffc0204c74 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020490a:	01893503          	ld	a0,24(s2)
ffffffffc020490e:	467d                	li	a2,31
ffffffffc0204910:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204914:	c23fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc0204918:	32050d63          	beqz	a0,ffffffffc0204c52 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020491c:	01893503          	ld	a0,24(s2)
ffffffffc0204920:	467d                	li	a2,31
ffffffffc0204922:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204926:	c11fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc020492a:	30050363          	beqz	a0,ffffffffc0204c30 <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc020492e:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204932:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204936:	01893683          	ld	a3,24(s2)
ffffffffc020493a:	2785                	addiw	a5,a5,1
ffffffffc020493c:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204940:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_matrix_out_size+0xf4ae8>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204944:	c02007b7          	lui	a5,0xc0200
ffffffffc0204948:	2cf6e763          	bltu	a3,a5,ffffffffc0204c16 <do_execve+0x4fa>
ffffffffc020494c:	000ab783          	ld	a5,0(s5)
ffffffffc0204950:	577d                	li	a4,-1
ffffffffc0204952:	177e                	slli	a4,a4,0x3f
ffffffffc0204954:	8e9d                	sub	a3,a3,a5
ffffffffc0204956:	00c6d793          	srli	a5,a3,0xc
ffffffffc020495a:	f654                	sd	a3,168(a2)
ffffffffc020495c:	8fd9                	or	a5,a5,a4
ffffffffc020495e:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204962:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204964:	4581                	li	a1,0
ffffffffc0204966:	12000613          	li	a2,288
ffffffffc020496a:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020496c:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204970:	729000ef          	jal	ffffffffc0205898 <memset>
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204974:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204976:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc020497a:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc020497e:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc0204980:	4785                	li	a5,1
ffffffffc0204982:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204984:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204988:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc020498c:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc020498e:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204992:	4641                	li	a2,16
ffffffffc0204994:	4581                	li	a1,0
ffffffffc0204996:	0b498513          	addi	a0,s3,180
ffffffffc020499a:	6ff000ef          	jal	ffffffffc0205898 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020499e:	180c                	addi	a1,sp,48
ffffffffc02049a0:	0b498513          	addi	a0,s3,180
ffffffffc02049a4:	463d                	li	a2,15
ffffffffc02049a6:	705000ef          	jal	ffffffffc02058aa <memcpy>
ffffffffc02049aa:	740a                	ld	s0,160(sp)
ffffffffc02049ac:	6a0a                	ld	s4,128(sp)
ffffffffc02049ae:	7ae6                	ld	s5,120(sp)
ffffffffc02049b0:	7b46                	ld	s6,112(sp)
ffffffffc02049b2:	7ba6                	ld	s7,104(sp)
ffffffffc02049b4:	7c06                	ld	s8,96(sp)
ffffffffc02049b6:	6ce6                	ld	s9,88(sp)
}
ffffffffc02049b8:	70aa                	ld	ra,168(sp)
ffffffffc02049ba:	694a                	ld	s2,144(sp)
ffffffffc02049bc:	69aa                	ld	s3,136(sp)
ffffffffc02049be:	6d46                	ld	s10,80(sp)
ffffffffc02049c0:	8526                	mv	a0,s1
ffffffffc02049c2:	64ea                	ld	s1,152(sp)
ffffffffc02049c4:	614d                	addi	sp,sp,176
ffffffffc02049c6:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc02049c8:	54f1                	li	s1,-4
ffffffffc02049ca:	bdad                	j	ffffffffc0204844 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc02049cc:	028a3603          	ld	a2,40(s4)
ffffffffc02049d0:	020a3783          	ld	a5,32(s4)
ffffffffc02049d4:	20f66363          	bltu	a2,a5,ffffffffc0204bda <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049d8:	004a2783          	lw	a5,4(s4)
ffffffffc02049dc:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049e0:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049e4:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049e6:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049e8:	c6f1                	beqz	a3,ffffffffc0204ab4 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049ea:	1c079763          	bnez	a5,ffffffffc0204bb8 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc02049ee:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc02049f0:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc02049f4:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc02049f6:	c709                	beqz	a4,ffffffffc0204a00 <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc02049f8:	67a2                	ld	a5,8(sp)
ffffffffc02049fa:	0087e793          	ori	a5,a5,8
ffffffffc02049fe:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204a00:	010a3583          	ld	a1,16(s4)
ffffffffc0204a04:	4701                	li	a4,0
ffffffffc0204a06:	854a                	mv	a0,s2
ffffffffc0204a08:	da1fe0ef          	jal	ffffffffc02037a8 <mm_map>
ffffffffc0204a0c:	84aa                	mv	s1,a0
ffffffffc0204a0e:	1c051463          	bnez	a0,ffffffffc0204bd6 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a12:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a16:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a1a:	77fd                	lui	a5,0xfffff
ffffffffc0204a1c:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a20:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204a22:	1a9b7563          	bgeu	s6,s1,ffffffffc0204bcc <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a26:	008a3983          	ld	s3,8(s4)
ffffffffc0204a2a:	67e2                	ld	a5,24(sp)
ffffffffc0204a2c:	99be                	add	s3,s3,a5
ffffffffc0204a2e:	a881                	j	ffffffffc0204a7e <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a30:	6785                	lui	a5,0x1
ffffffffc0204a32:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204a36:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204a3a:	01b4e463          	bltu	s1,s11,ffffffffc0204a42 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a3e:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204a42:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204a46:	67c2                	ld	a5,16(sp)
ffffffffc0204a48:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204a4c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a50:	8699                	srai	a3,a3,0x6
ffffffffc0204a52:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204a54:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a58:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a5a:	18a87363          	bgeu	a6,a0,ffffffffc0204be0 <do_execve+0x4c4>
ffffffffc0204a5e:	000ab503          	ld	a0,0(s5)
ffffffffc0204a62:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a66:	e032                	sd	a2,0(sp)
ffffffffc0204a68:	9536                	add	a0,a0,a3
ffffffffc0204a6a:	952e                	add	a0,a0,a1
ffffffffc0204a6c:	85ce                	mv	a1,s3
ffffffffc0204a6e:	63d000ef          	jal	ffffffffc02058aa <memcpy>
            start += size, from += size;
ffffffffc0204a72:	6602                	ld	a2,0(sp)
ffffffffc0204a74:	9b32                	add	s6,s6,a2
ffffffffc0204a76:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204a78:	049b7563          	bgeu	s6,s1,ffffffffc0204ac2 <do_execve+0x3a6>
ffffffffc0204a7c:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a7e:	01893503          	ld	a0,24(s2)
ffffffffc0204a82:	6622                	ld	a2,8(sp)
ffffffffc0204a84:	e02e                	sd	a1,0(sp)
ffffffffc0204a86:	ab1fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc0204a8a:	6582                	ld	a1,0(sp)
ffffffffc0204a8c:	842a                	mv	s0,a0
ffffffffc0204a8e:	f14d                	bnez	a0,ffffffffc0204a30 <do_execve+0x314>
ffffffffc0204a90:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204a92:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204a94:	854a                	mv	a0,s2
ffffffffc0204a96:	e77fe0ef          	jal	ffffffffc020390c <exit_mmap>
ffffffffc0204a9a:	740a                	ld	s0,160(sp)
ffffffffc0204a9c:	6a0a                	ld	s4,128(sp)
ffffffffc0204a9e:	bb41                	j	ffffffffc020482e <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204aa0:	854a                	mv	a0,s2
ffffffffc0204aa2:	e6bfe0ef          	jal	ffffffffc020390c <exit_mmap>
            put_pgdir(mm);
ffffffffc0204aa6:	854a                	mv	a0,s2
ffffffffc0204aa8:	b4cff0ef          	jal	ffffffffc0203df4 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204aac:	854a                	mv	a0,s2
ffffffffc0204aae:	ca9fe0ef          	jal	ffffffffc0203756 <mm_destroy>
ffffffffc0204ab2:	b1e5                	j	ffffffffc020479a <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ab4:	0e078e63          	beqz	a5,ffffffffc0204bb0 <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204ab8:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204aba:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204abe:	e43e                	sd	a5,8(sp)
ffffffffc0204ac0:	bf1d                	j	ffffffffc02049f6 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204ac2:	010a3483          	ld	s1,16(s4)
ffffffffc0204ac6:	028a3683          	ld	a3,40(s4)
ffffffffc0204aca:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204acc:	07bb7c63          	bgeu	s6,s11,ffffffffc0204b44 <do_execve+0x428>
            if (start == end)
ffffffffc0204ad0:	df6489e3          	beq	s1,s6,ffffffffc02048c2 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204ad4:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204ad8:	0fb4f563          	bgeu	s1,s11,ffffffffc0204bc2 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204adc:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204ae0:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204ae4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ae8:	8699                	srai	a3,a3,0x6
ffffffffc0204aea:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204aec:	00c69593          	slli	a1,a3,0xc
ffffffffc0204af0:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204af2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204af4:	0ec5f663          	bgeu	a1,a2,ffffffffc0204be0 <do_execve+0x4c4>
ffffffffc0204af8:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204afc:	6505                	lui	a0,0x1
ffffffffc0204afe:	955a                	add	a0,a0,s6
ffffffffc0204b00:	96b2                	add	a3,a3,a2
ffffffffc0204b02:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b06:	9536                	add	a0,a0,a3
ffffffffc0204b08:	864e                	mv	a2,s3
ffffffffc0204b0a:	4581                	li	a1,0
ffffffffc0204b0c:	58d000ef          	jal	ffffffffc0205898 <memset>
            start += size;
ffffffffc0204b10:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204b12:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204b16:	01b4f463          	bgeu	s1,s11,ffffffffc0204b1e <do_execve+0x402>
ffffffffc0204b1a:	db6484e3          	beq	s1,s6,ffffffffc02048c2 <do_execve+0x1a6>
ffffffffc0204b1e:	e299                	bnez	a3,ffffffffc0204b24 <do_execve+0x408>
ffffffffc0204b20:	03bb0263          	beq	s6,s11,ffffffffc0204b44 <do_execve+0x428>
ffffffffc0204b24:	00002697          	auipc	a3,0x2
ffffffffc0204b28:	6e468693          	addi	a3,a3,1764 # ffffffffc0207208 <etext+0x1946>
ffffffffc0204b2c:	00001617          	auipc	a2,0x1
ffffffffc0204b30:	76c60613          	addi	a2,a2,1900 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204b34:	2cf00593          	li	a1,719
ffffffffc0204b38:	00002517          	auipc	a0,0x2
ffffffffc0204b3c:	50850513          	addi	a0,a0,1288 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204b40:	90bfb0ef          	jal	ffffffffc020044a <__panic>
        while (start < end)
ffffffffc0204b44:	d69b7fe3          	bgeu	s6,s1,ffffffffc02048c2 <do_execve+0x1a6>
ffffffffc0204b48:	56fd                	li	a3,-1
ffffffffc0204b4a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b4e:	f03e                	sd	a5,32(sp)
ffffffffc0204b50:	a0b9                	j	ffffffffc0204b9e <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b52:	6785                	lui	a5,0x1
ffffffffc0204b54:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204b58:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204b5c:	0104e463          	bltu	s1,a6,ffffffffc0204b64 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b60:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204b64:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b68:	7782                	ld	a5,32(sp)
ffffffffc0204b6a:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204b6e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b72:	8699                	srai	a3,a3,0x6
ffffffffc0204b74:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b76:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b7a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b7c:	06b57263          	bgeu	a0,a1,ffffffffc0204be0 <do_execve+0x4c4>
ffffffffc0204b80:	000ab583          	ld	a1,0(s5)
ffffffffc0204b84:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b88:	864e                	mv	a2,s3
ffffffffc0204b8a:	96ae                	add	a3,a3,a1
ffffffffc0204b8c:	9536                	add	a0,a0,a3
ffffffffc0204b8e:	4581                	li	a1,0
            start += size;
ffffffffc0204b90:	9b4e                	add	s6,s6,s3
ffffffffc0204b92:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b94:	505000ef          	jal	ffffffffc0205898 <memset>
        while (start < end)
ffffffffc0204b98:	d29b75e3          	bgeu	s6,s1,ffffffffc02048c2 <do_execve+0x1a6>
ffffffffc0204b9c:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b9e:	01893503          	ld	a0,24(s2)
ffffffffc0204ba2:	6622                	ld	a2,8(sp)
ffffffffc0204ba4:	85ee                	mv	a1,s11
ffffffffc0204ba6:	991fe0ef          	jal	ffffffffc0203536 <pgdir_alloc_page>
ffffffffc0204baa:	842a                	mv	s0,a0
ffffffffc0204bac:	f15d                	bnez	a0,ffffffffc0204b52 <do_execve+0x436>
ffffffffc0204bae:	b5cd                	j	ffffffffc0204a90 <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204bb0:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bb2:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204bb4:	e43e                	sd	a5,8(sp)
ffffffffc0204bb6:	b581                	j	ffffffffc02049f6 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bb8:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204bba:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204bbe:	e43e                	sd	a5,8(sp)
ffffffffc0204bc0:	bd1d                	j	ffffffffc02049f6 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bc2:	416d89b3          	sub	s3,s11,s6
ffffffffc0204bc6:	bf19                	j	ffffffffc0204adc <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204bc8:	54f5                	li	s1,-3
ffffffffc0204bca:	b3fd                	j	ffffffffc02049b8 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bcc:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204bce:	84da                	mv	s1,s6
ffffffffc0204bd0:	bddd                	j	ffffffffc0204ac6 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204bd2:	54f1                	li	s1,-4
ffffffffc0204bd4:	b1ad                	j	ffffffffc020483e <do_execve+0x122>
ffffffffc0204bd6:	6da6                	ld	s11,72(sp)
ffffffffc0204bd8:	bd75                	j	ffffffffc0204a94 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204bda:	6da6                	ld	s11,72(sp)
ffffffffc0204bdc:	54e1                	li	s1,-8
ffffffffc0204bde:	bd5d                	j	ffffffffc0204a94 <do_execve+0x378>
ffffffffc0204be0:	00002617          	auipc	a2,0x2
ffffffffc0204be4:	a6860613          	addi	a2,a2,-1432 # ffffffffc0206648 <etext+0xd86>
ffffffffc0204be8:	07100593          	li	a1,113
ffffffffc0204bec:	00002517          	auipc	a0,0x2
ffffffffc0204bf0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206670 <etext+0xdae>
ffffffffc0204bf4:	857fb0ef          	jal	ffffffffc020044a <__panic>
ffffffffc0204bf8:	00002617          	auipc	a2,0x2
ffffffffc0204bfc:	a5060613          	addi	a2,a2,-1456 # ffffffffc0206648 <etext+0xd86>
ffffffffc0204c00:	07100593          	li	a1,113
ffffffffc0204c04:	00002517          	auipc	a0,0x2
ffffffffc0204c08:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0206670 <etext+0xdae>
ffffffffc0204c0c:	f122                	sd	s0,160(sp)
ffffffffc0204c0e:	e152                	sd	s4,128(sp)
ffffffffc0204c10:	e4ee                	sd	s11,72(sp)
ffffffffc0204c12:	839fb0ef          	jal	ffffffffc020044a <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c16:	00002617          	auipc	a2,0x2
ffffffffc0204c1a:	ada60613          	addi	a2,a2,-1318 # ffffffffc02066f0 <etext+0xe2e>
ffffffffc0204c1e:	2ee00593          	li	a1,750
ffffffffc0204c22:	00002517          	auipc	a0,0x2
ffffffffc0204c26:	41e50513          	addi	a0,a0,1054 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204c2a:	e4ee                	sd	s11,72(sp)
ffffffffc0204c2c:	81ffb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c30:	00002697          	auipc	a3,0x2
ffffffffc0204c34:	6f068693          	addi	a3,a3,1776 # ffffffffc0207320 <etext+0x1a5e>
ffffffffc0204c38:	00001617          	auipc	a2,0x1
ffffffffc0204c3c:	66060613          	addi	a2,a2,1632 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204c40:	2e900593          	li	a1,745
ffffffffc0204c44:	00002517          	auipc	a0,0x2
ffffffffc0204c48:	3fc50513          	addi	a0,a0,1020 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204c4c:	e4ee                	sd	s11,72(sp)
ffffffffc0204c4e:	ffcfb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c52:	00002697          	auipc	a3,0x2
ffffffffc0204c56:	68668693          	addi	a3,a3,1670 # ffffffffc02072d8 <etext+0x1a16>
ffffffffc0204c5a:	00001617          	auipc	a2,0x1
ffffffffc0204c5e:	63e60613          	addi	a2,a2,1598 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204c62:	2e800593          	li	a1,744
ffffffffc0204c66:	00002517          	auipc	a0,0x2
ffffffffc0204c6a:	3da50513          	addi	a0,a0,986 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204c6e:	e4ee                	sd	s11,72(sp)
ffffffffc0204c70:	fdafb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c74:	00002697          	auipc	a3,0x2
ffffffffc0204c78:	61c68693          	addi	a3,a3,1564 # ffffffffc0207290 <etext+0x19ce>
ffffffffc0204c7c:	00001617          	auipc	a2,0x1
ffffffffc0204c80:	61c60613          	addi	a2,a2,1564 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204c84:	2e700593          	li	a1,743
ffffffffc0204c88:	00002517          	auipc	a0,0x2
ffffffffc0204c8c:	3b850513          	addi	a0,a0,952 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204c90:	e4ee                	sd	s11,72(sp)
ffffffffc0204c92:	fb8fb0ef          	jal	ffffffffc020044a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c96:	00002697          	auipc	a3,0x2
ffffffffc0204c9a:	5b268693          	addi	a3,a3,1458 # ffffffffc0207248 <etext+0x1986>
ffffffffc0204c9e:	00001617          	auipc	a2,0x1
ffffffffc0204ca2:	5fa60613          	addi	a2,a2,1530 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204ca6:	2e600593          	li	a1,742
ffffffffc0204caa:	00002517          	auipc	a0,0x2
ffffffffc0204cae:	39650513          	addi	a0,a0,918 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204cb2:	e4ee                	sd	s11,72(sp)
ffffffffc0204cb4:	f96fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204cb8 <user_main>:
{
ffffffffc0204cb8:	1101                	addi	sp,sp,-32
ffffffffc0204cba:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204cbc:	000b1497          	auipc	s1,0xb1
ffffffffc0204cc0:	a8448493          	addi	s1,s1,-1404 # ffffffffc02b5740 <current>
ffffffffc0204cc4:	609c                	ld	a5,0(s1)
ffffffffc0204cc6:	00002617          	auipc	a2,0x2
ffffffffc0204cca:	6a260613          	addi	a2,a2,1698 # ffffffffc0207368 <etext+0x1aa6>
ffffffffc0204cce:	00002517          	auipc	a0,0x2
ffffffffc0204cd2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0207378 <etext+0x1ab6>
ffffffffc0204cd6:	43cc                	lw	a1,4(a5)
{
ffffffffc0204cd8:	ec06                	sd	ra,24(sp)
ffffffffc0204cda:	e822                	sd	s0,16(sp)
ffffffffc0204cdc:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204cde:	cbafb0ef          	jal	ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204ce2:	00002517          	auipc	a0,0x2
ffffffffc0204ce6:	68650513          	addi	a0,a0,1670 # ffffffffc0207368 <etext+0x1aa6>
ffffffffc0204cea:	2fb000ef          	jal	ffffffffc02057e4 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204cee:	6098                	ld	a4,0(s1)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cf0:	6789                	lui	a5,0x2
ffffffffc0204cf2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7060>
ffffffffc0204cf6:	6b00                	ld	s0,16(a4)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cf8:	734c                	ld	a1,160(a4)
    size_t len = strlen(name);
ffffffffc0204cfa:	892a                	mv	s2,a0
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204cfc:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204cfe:	12000613          	li	a2,288
ffffffffc0204d02:	8522                	mv	a0,s0
ffffffffc0204d04:	3a7000ef          	jal	ffffffffc02058aa <memcpy>
    current->tf = new_tf;
ffffffffc0204d08:	609c                	ld	a5,0(s1)
    ret = do_execve(name, len, binary, size);
ffffffffc0204d0a:	85ca                	mv	a1,s2
ffffffffc0204d0c:	3fe06697          	auipc	a3,0x3fe06
ffffffffc0204d10:	a1468693          	addi	a3,a3,-1516 # a720 <_binary_obj___user_priority_out_size>
    current->tf = new_tf;
ffffffffc0204d14:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204d16:	00072617          	auipc	a2,0x72
ffffffffc0204d1a:	cea60613          	addi	a2,a2,-790 # ffffffffc0276a00 <_binary_obj___user_priority_out_start>
ffffffffc0204d1e:	00002517          	auipc	a0,0x2
ffffffffc0204d22:	64a50513          	addi	a0,a0,1610 # ffffffffc0207368 <etext+0x1aa6>
ffffffffc0204d26:	9f7ff0ef          	jal	ffffffffc020471c <do_execve>
    asm volatile(
ffffffffc0204d2a:	8122                	mv	sp,s0
ffffffffc0204d2c:	8fcfc06f          	j	ffffffffc0200e28 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204d30:	00002617          	auipc	a2,0x2
ffffffffc0204d34:	67060613          	addi	a2,a2,1648 # ffffffffc02073a0 <etext+0x1ade>
ffffffffc0204d38:	3d500593          	li	a1,981
ffffffffc0204d3c:	00002517          	auipc	a0,0x2
ffffffffc0204d40:	30450513          	addi	a0,a0,772 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204d44:	f06fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204d48 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d48:	000b1797          	auipc	a5,0xb1
ffffffffc0204d4c:	9f87b783          	ld	a5,-1544(a5) # ffffffffc02b5740 <current>
ffffffffc0204d50:	4705                	li	a4,1
}
ffffffffc0204d52:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204d54:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d56:	8082                	ret

ffffffffc0204d58 <do_wait>:
    if (code_store != NULL)
ffffffffc0204d58:	c59d                	beqz	a1,ffffffffc0204d86 <do_wait+0x2e>
{
ffffffffc0204d5a:	1101                	addi	sp,sp,-32
ffffffffc0204d5c:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204d5e:	000b1517          	auipc	a0,0xb1
ffffffffc0204d62:	9e253503          	ld	a0,-1566(a0) # ffffffffc02b5740 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d66:	4685                	li	a3,1
ffffffffc0204d68:	4611                	li	a2,4
ffffffffc0204d6a:	7508                	ld	a0,40(a0)
{
ffffffffc0204d6c:	ec06                	sd	ra,24(sp)
ffffffffc0204d6e:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d70:	f35fe0ef          	jal	ffffffffc0203ca4 <user_mem_check>
ffffffffc0204d74:	6702                	ld	a4,0(sp)
ffffffffc0204d76:	67a2                	ld	a5,8(sp)
ffffffffc0204d78:	c909                	beqz	a0,ffffffffc0204d8a <do_wait+0x32>
}
ffffffffc0204d7a:	60e2                	ld	ra,24(sp)
ffffffffc0204d7c:	85be                	mv	a1,a5
ffffffffc0204d7e:	853a                	mv	a0,a4
ffffffffc0204d80:	6105                	addi	sp,sp,32
ffffffffc0204d82:	e94ff06f          	j	ffffffffc0204416 <do_wait.part.0>
ffffffffc0204d86:	e90ff06f          	j	ffffffffc0204416 <do_wait.part.0>
ffffffffc0204d8a:	60e2                	ld	ra,24(sp)
ffffffffc0204d8c:	5575                	li	a0,-3
ffffffffc0204d8e:	6105                	addi	sp,sp,32
ffffffffc0204d90:	8082                	ret

ffffffffc0204d92 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d92:	6789                	lui	a5,0x2
ffffffffc0204d94:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d98:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f42>
ffffffffc0204d9a:	06e7e463          	bltu	a5,a4,ffffffffc0204e02 <do_kill+0x70>
{
ffffffffc0204d9e:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204da0:	45a9                	li	a1,10
{
ffffffffc0204da2:	ec06                	sd	ra,24(sp)
ffffffffc0204da4:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204da6:	65c000ef          	jal	ffffffffc0205402 <hash32>
ffffffffc0204daa:	02051793          	slli	a5,a0,0x20
ffffffffc0204dae:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204db2:	000ad797          	auipc	a5,0xad
ffffffffc0204db6:	8ee78793          	addi	a5,a5,-1810 # ffffffffc02b16a0 <hash_list>
ffffffffc0204dba:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204dbc:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204dbe:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204dc0:	a029                	j	ffffffffc0204dca <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204dc2:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204dc6:	00c70963          	beq	a4,a2,ffffffffc0204dd8 <do_kill+0x46>
ffffffffc0204dca:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204dcc:	fea69be3          	bne	a3,a0,ffffffffc0204dc2 <do_kill+0x30>
}
ffffffffc0204dd0:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204dd2:	5575                	li	a0,-3
}
ffffffffc0204dd4:	6105                	addi	sp,sp,32
ffffffffc0204dd6:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204dd8:	fd852703          	lw	a4,-40(a0)
ffffffffc0204ddc:	00177693          	andi	a3,a4,1
ffffffffc0204de0:	e29d                	bnez	a3,ffffffffc0204e06 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204de2:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204de4:	00176713          	ori	a4,a4,1
ffffffffc0204de8:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204dec:	0006c663          	bltz	a3,ffffffffc0204df8 <do_kill+0x66>
            return 0;
ffffffffc0204df0:	4501                	li	a0,0
}
ffffffffc0204df2:	60e2                	ld	ra,24(sp)
ffffffffc0204df4:	6105                	addi	sp,sp,32
ffffffffc0204df6:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204df8:	f2850513          	addi	a0,a0,-216
ffffffffc0204dfc:	35c000ef          	jal	ffffffffc0205158 <wakeup_proc>
ffffffffc0204e00:	bfc5                	j	ffffffffc0204df0 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204e02:	5575                	li	a0,-3
}
ffffffffc0204e04:	8082                	ret
        return -E_KILLED;
ffffffffc0204e06:	555d                	li	a0,-9
ffffffffc0204e08:	b7ed                	j	ffffffffc0204df2 <do_kill+0x60>

ffffffffc0204e0a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204e0a:	1101                	addi	sp,sp,-32
ffffffffc0204e0c:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204e0e:	000b1797          	auipc	a5,0xb1
ffffffffc0204e12:	89278793          	addi	a5,a5,-1902 # ffffffffc02b56a0 <proc_list>
ffffffffc0204e16:	ec06                	sd	ra,24(sp)
ffffffffc0204e18:	e822                	sd	s0,16(sp)
ffffffffc0204e1a:	e04a                	sd	s2,0(sp)
ffffffffc0204e1c:	000ad497          	auipc	s1,0xad
ffffffffc0204e20:	88448493          	addi	s1,s1,-1916 # ffffffffc02b16a0 <hash_list>
ffffffffc0204e24:	e79c                	sd	a5,8(a5)
ffffffffc0204e26:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204e28:	000b1717          	auipc	a4,0xb1
ffffffffc0204e2c:	87870713          	addi	a4,a4,-1928 # ffffffffc02b56a0 <proc_list>
ffffffffc0204e30:	87a6                	mv	a5,s1
ffffffffc0204e32:	e79c                	sd	a5,8(a5)
ffffffffc0204e34:	e39c                	sd	a5,0(a5)
ffffffffc0204e36:	07c1                	addi	a5,a5,16
ffffffffc0204e38:	fee79de3          	bne	a5,a4,ffffffffc0204e32 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e3c:	f15fe0ef          	jal	ffffffffc0203d50 <alloc_proc>
ffffffffc0204e40:	000b1917          	auipc	s2,0xb1
ffffffffc0204e44:	91090913          	addi	s2,s2,-1776 # ffffffffc02b5750 <idleproc>
ffffffffc0204e48:	00a93023          	sd	a0,0(s2)
ffffffffc0204e4c:	10050363          	beqz	a0,ffffffffc0204f52 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e50:	4789                	li	a5,2
ffffffffc0204e52:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e54:	00004797          	auipc	a5,0x4
ffffffffc0204e58:	1ac78793          	addi	a5,a5,428 # ffffffffc0209000 <bootstack>
ffffffffc0204e5c:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e5e:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204e62:	4785                	li	a5,1
ffffffffc0204e64:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e66:	4641                	li	a2,16
ffffffffc0204e68:	8522                	mv	a0,s0
ffffffffc0204e6a:	4581                	li	a1,0
ffffffffc0204e6c:	22d000ef          	jal	ffffffffc0205898 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e70:	8522                	mv	a0,s0
ffffffffc0204e72:	463d                	li	a2,15
ffffffffc0204e74:	00002597          	auipc	a1,0x2
ffffffffc0204e78:	56458593          	addi	a1,a1,1380 # ffffffffc02073d8 <etext+0x1b16>
ffffffffc0204e7c:	22f000ef          	jal	ffffffffc02058aa <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e80:	000b1797          	auipc	a5,0xb1
ffffffffc0204e84:	8b87a783          	lw	a5,-1864(a5) # ffffffffc02b5738 <nr_process>

    current = idleproc;
ffffffffc0204e88:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e8c:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e8e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e90:	4581                	li	a1,0
ffffffffc0204e92:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e96:	76650513          	addi	a0,a0,1894 # ffffffffc02045f8 <init_main>
    current = idleproc;
ffffffffc0204e9a:	000b1697          	auipc	a3,0xb1
ffffffffc0204e9e:	8ae6b323          	sd	a4,-1882(a3) # ffffffffc02b5740 <current>
    nr_process++;
ffffffffc0204ea2:	000b1717          	auipc	a4,0xb1
ffffffffc0204ea6:	88f72b23          	sw	a5,-1898(a4) # ffffffffc02b5738 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204eaa:	bd8ff0ef          	jal	ffffffffc0204282 <kernel_thread>
ffffffffc0204eae:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204eb0:	08a05563          	blez	a0,ffffffffc0204f3a <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204eb4:	6789                	lui	a5,0x2
ffffffffc0204eb6:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f42>
ffffffffc0204eb8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ebc:	02e7e463          	bltu	a5,a4,ffffffffc0204ee4 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ec0:	45a9                	li	a1,10
ffffffffc0204ec2:	540000ef          	jal	ffffffffc0205402 <hash32>
ffffffffc0204ec6:	02051713          	slli	a4,a0,0x20
ffffffffc0204eca:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204ece:	00f486b3          	add	a3,s1,a5
ffffffffc0204ed2:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ed4:	a029                	j	ffffffffc0204ede <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204ed6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204eda:	04870d63          	beq	a4,s0,ffffffffc0204f34 <proc_init+0x12a>
    return listelm->next;
ffffffffc0204ede:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ee0:	fef69be3          	bne	a3,a5,ffffffffc0204ed6 <proc_init+0xcc>
    return NULL;
ffffffffc0204ee4:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ee6:	0b478413          	addi	s0,a5,180
ffffffffc0204eea:	4641                	li	a2,16
ffffffffc0204eec:	4581                	li	a1,0
ffffffffc0204eee:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204ef0:	000b1717          	auipc	a4,0xb1
ffffffffc0204ef4:	84f73c23          	sd	a5,-1960(a4) # ffffffffc02b5748 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ef8:	1a1000ef          	jal	ffffffffc0205898 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204efc:	8522                	mv	a0,s0
ffffffffc0204efe:	463d                	li	a2,15
ffffffffc0204f00:	00002597          	auipc	a1,0x2
ffffffffc0204f04:	50058593          	addi	a1,a1,1280 # ffffffffc0207400 <etext+0x1b3e>
ffffffffc0204f08:	1a3000ef          	jal	ffffffffc02058aa <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f0c:	00093783          	ld	a5,0(s2)
ffffffffc0204f10:	cfad                	beqz	a5,ffffffffc0204f8a <proc_init+0x180>
ffffffffc0204f12:	43dc                	lw	a5,4(a5)
ffffffffc0204f14:	ebbd                	bnez	a5,ffffffffc0204f8a <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f16:	000b1797          	auipc	a5,0xb1
ffffffffc0204f1a:	8327b783          	ld	a5,-1998(a5) # ffffffffc02b5748 <initproc>
ffffffffc0204f1e:	c7b1                	beqz	a5,ffffffffc0204f6a <proc_init+0x160>
ffffffffc0204f20:	43d8                	lw	a4,4(a5)
ffffffffc0204f22:	4785                	li	a5,1
ffffffffc0204f24:	04f71363          	bne	a4,a5,ffffffffc0204f6a <proc_init+0x160>
}
ffffffffc0204f28:	60e2                	ld	ra,24(sp)
ffffffffc0204f2a:	6442                	ld	s0,16(sp)
ffffffffc0204f2c:	64a2                	ld	s1,8(sp)
ffffffffc0204f2e:	6902                	ld	s2,0(sp)
ffffffffc0204f30:	6105                	addi	sp,sp,32
ffffffffc0204f32:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f34:	f2878793          	addi	a5,a5,-216
ffffffffc0204f38:	b77d                	j	ffffffffc0204ee6 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0204f3a:	00002617          	auipc	a2,0x2
ffffffffc0204f3e:	4a660613          	addi	a2,a2,1190 # ffffffffc02073e0 <etext+0x1b1e>
ffffffffc0204f42:	41100593          	li	a1,1041
ffffffffc0204f46:	00002517          	auipc	a0,0x2
ffffffffc0204f4a:	0fa50513          	addi	a0,a0,250 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204f4e:	cfcfb0ef          	jal	ffffffffc020044a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f52:	00002617          	auipc	a2,0x2
ffffffffc0204f56:	46e60613          	addi	a2,a2,1134 # ffffffffc02073c0 <etext+0x1afe>
ffffffffc0204f5a:	40200593          	li	a1,1026
ffffffffc0204f5e:	00002517          	auipc	a0,0x2
ffffffffc0204f62:	0e250513          	addi	a0,a0,226 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204f66:	ce4fb0ef          	jal	ffffffffc020044a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f6a:	00002697          	auipc	a3,0x2
ffffffffc0204f6e:	4c668693          	addi	a3,a3,1222 # ffffffffc0207430 <etext+0x1b6e>
ffffffffc0204f72:	00001617          	auipc	a2,0x1
ffffffffc0204f76:	32660613          	addi	a2,a2,806 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204f7a:	41800593          	li	a1,1048
ffffffffc0204f7e:	00002517          	auipc	a0,0x2
ffffffffc0204f82:	0c250513          	addi	a0,a0,194 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204f86:	cc4fb0ef          	jal	ffffffffc020044a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f8a:	00002697          	auipc	a3,0x2
ffffffffc0204f8e:	47e68693          	addi	a3,a3,1150 # ffffffffc0207408 <etext+0x1b46>
ffffffffc0204f92:	00001617          	auipc	a2,0x1
ffffffffc0204f96:	30660613          	addi	a2,a2,774 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0204f9a:	41700593          	li	a1,1047
ffffffffc0204f9e:	00002517          	auipc	a0,0x2
ffffffffc0204fa2:	0a250513          	addi	a0,a0,162 # ffffffffc0207040 <etext+0x177e>
ffffffffc0204fa6:	ca4fb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0204faa <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204faa:	1141                	addi	sp,sp,-16
ffffffffc0204fac:	e022                	sd	s0,0(sp)
ffffffffc0204fae:	e406                	sd	ra,8(sp)
ffffffffc0204fb0:	000b0417          	auipc	s0,0xb0
ffffffffc0204fb4:	79040413          	addi	s0,s0,1936 # ffffffffc02b5740 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204fb8:	6018                	ld	a4,0(s0)
ffffffffc0204fba:	6f1c                	ld	a5,24(a4)
ffffffffc0204fbc:	dffd                	beqz	a5,ffffffffc0204fba <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204fbe:	292000ef          	jal	ffffffffc0205250 <schedule>
ffffffffc0204fc2:	bfdd                	j	ffffffffc0204fb8 <cpu_idle+0xe>

ffffffffc0204fc4 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204fc4:	1101                	addi	sp,sp,-32
ffffffffc0204fc6:	85aa                	mv	a1,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204fc8:	e42a                	sd	a0,8(sp)
ffffffffc0204fca:	00002517          	auipc	a0,0x2
ffffffffc0204fce:	48e50513          	addi	a0,a0,1166 # ffffffffc0207458 <etext+0x1b96>
{
ffffffffc0204fd2:	ec06                	sd	ra,24(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204fd4:	9c4fb0ef          	jal	ffffffffc0200198 <cprintf>
    if (priority == 0)
ffffffffc0204fd8:	65a2                	ld	a1,8(sp)
        current->lab6_priority = 1;
ffffffffc0204fda:	000b0717          	auipc	a4,0xb0
ffffffffc0204fde:	76673703          	ld	a4,1894(a4) # ffffffffc02b5740 <current>
    if (priority == 0)
ffffffffc0204fe2:	4785                	li	a5,1
ffffffffc0204fe4:	c191                	beqz	a1,ffffffffc0204fe8 <lab6_set_priority+0x24>
ffffffffc0204fe6:	87ae                	mv	a5,a1
    else
        current->lab6_priority = priority;
}
ffffffffc0204fe8:	60e2                	ld	ra,24(sp)
        current->lab6_priority = 1;
ffffffffc0204fea:	14f72223          	sw	a5,324(a4)
}
ffffffffc0204fee:	6105                	addi	sp,sp,32
ffffffffc0204ff0:	8082                	ret

ffffffffc0204ff2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204ff2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204ff6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204ffa:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204ffc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204ffe:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205002:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205006:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020500a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020500e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205012:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205016:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020501a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020501e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205022:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205026:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020502a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020502e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205030:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205032:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205036:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020503a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020503e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205042:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205046:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020504a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020504e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205052:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205056:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020505a:	8082                	ret

ffffffffc020505c <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc020505c:	e508                	sd	a0,8(a0)
ffffffffc020505e:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&rq->run_list);
    rq->proc_num = 0;
ffffffffc0205060:	00052823          	sw	zero,16(a0)
}
ffffffffc0205064:	8082                	ret

ffffffffc0205066 <RR_enqueue>:
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205066:	611c                	ld	a5,0(a0)
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312307
    list_add_before(&rq->run_list, &proc->run_link);
ffffffffc0205068:	11058713          	addi	a4,a1,272
    prev->next = next->prev = elm;
ffffffffc020506c:	e118                	sd	a4,0(a0)
    if (proc->time_slice <= 0) {
ffffffffc020506e:	1205a683          	lw	a3,288(a1)
ffffffffc0205072:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0205074:	10f5b823          	sd	a5,272(a1)
    elm->next = next;
ffffffffc0205078:	10a5bc23          	sd	a0,280(a1)
ffffffffc020507c:	00d04563          	bgtz	a3,ffffffffc0205086 <RR_enqueue+0x20>
        proc->time_slice = rq->max_time_slice;
ffffffffc0205080:	495c                	lw	a5,20(a0)
ffffffffc0205082:	12f5a023          	sw	a5,288(a1)
    }
    proc->rq = rq;
    rq->proc_num++;
ffffffffc0205086:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc0205088:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc020508c:	2785                	addiw	a5,a5,1
ffffffffc020508e:	c91c                	sw	a5,16(a0)
}
ffffffffc0205090:	8082                	ret

ffffffffc0205092 <RR_dequeue>:
    __list_del(listelm->prev, listelm->next);
ffffffffc0205092:	1185b703          	ld	a4,280(a1)
ffffffffc0205096:	1105b683          	ld	a3,272(a1)
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312307
    list_del_init(&proc->run_link);
    proc->rq = NULL;
    rq->proc_num--;
ffffffffc020509a:	491c                	lw	a5,16(a0)
    prev->next = next;
ffffffffc020509c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020509e:	e314                	sd	a3,0(a4)
    list_del_init(&proc->run_link);
ffffffffc02050a0:	11058713          	addi	a4,a1,272
    proc->rq = NULL;
ffffffffc02050a4:	1005b423          	sd	zero,264(a1)
    rq->proc_num--;
ffffffffc02050a8:	37fd                	addiw	a5,a5,-1
    elm->prev = elm->next = elm;
ffffffffc02050aa:	10e5bc23          	sd	a4,280(a1)
ffffffffc02050ae:	10e5b823          	sd	a4,272(a1)
ffffffffc02050b2:	c91c                	sw	a5,16(a0)
}
ffffffffc02050b4:	8082                	ret

ffffffffc02050b6 <RR_pick_next>:
    return list->next == list;
ffffffffc02050b6:	651c                	ld	a5,8(a0)
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2312307
    if (list_empty(&rq->run_list)) {
ffffffffc02050b8:	00f50563          	beq	a0,a5,ffffffffc02050c2 <RR_pick_next+0xc>
        return NULL;
    } else {
        list_entry_t *le = rq->run_list.next;
        struct proc_struct *proc = le2proc(le, run_link);
ffffffffc02050bc:	ef078513          	addi	a0,a5,-272
        return proc;
ffffffffc02050c0:	8082                	ret
        return NULL;
ffffffffc02050c2:	4501                	li	a0,0
    }
}
ffffffffc02050c4:	8082                	ret

ffffffffc02050c6 <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
ffffffffc02050c6:	1205a783          	lw	a5,288(a1)
ffffffffc02050ca:	00f05663          	blez	a5,ffffffffc02050d6 <RR_proc_tick+0x10>
        proc->time_slice--;
ffffffffc02050ce:	37fd                	addiw	a5,a5,-1
ffffffffc02050d0:	12f5a023          	sw	a5,288(a1)
ffffffffc02050d4:	8082                	ret
    } else {
        proc->need_resched = 1;
ffffffffc02050d6:	4785                	li	a5,1
ffffffffc02050d8:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc02050da:	8082                	ret

ffffffffc02050dc <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc02050dc:	000b0797          	auipc	a5,0xb0
ffffffffc02050e0:	6747b783          	ld	a5,1652(a5) # ffffffffc02b5750 <idleproc>
{
ffffffffc02050e4:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc02050e6:	00a78c63          	beq	a5,a0,ffffffffc02050fe <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02050ea:	000b0797          	auipc	a5,0xb0
ffffffffc02050ee:	6767b783          	ld	a5,1654(a5) # ffffffffc02b5760 <sched_class>
ffffffffc02050f2:	000b0517          	auipc	a0,0xb0
ffffffffc02050f6:	66653503          	ld	a0,1638(a0) # ffffffffc02b5758 <rq>
ffffffffc02050fa:	779c                	ld	a5,40(a5)
ffffffffc02050fc:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050fe:	4705                	li	a4,1
ffffffffc0205100:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc0205102:	8082                	ret

ffffffffc0205104 <sched_init>:

void sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc0205104:	000ac797          	auipc	a5,0xac
ffffffffc0205108:	14478793          	addi	a5,a5,324 # ffffffffc02b1248 <default_sched_class>
{
ffffffffc020510c:	1141                	addi	sp,sp,-16
    // sched_class = &stride_sched_class;

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc020510e:	6794                	ld	a3,8(a5)
    sched_class = &default_sched_class;
ffffffffc0205110:	000b0717          	auipc	a4,0xb0
ffffffffc0205114:	64f73823          	sd	a5,1616(a4) # ffffffffc02b5760 <sched_class>
{
ffffffffc0205118:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc020511a:	000b0797          	auipc	a5,0xb0
ffffffffc020511e:	5b678793          	addi	a5,a5,1462 # ffffffffc02b56d0 <timer_list>
    rq = &__rq;
ffffffffc0205122:	000b0717          	auipc	a4,0xb0
ffffffffc0205126:	58e70713          	addi	a4,a4,1422 # ffffffffc02b56b0 <__rq>
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc020512a:	4615                	li	a2,5
ffffffffc020512c:	e79c                	sd	a5,8(a5)
ffffffffc020512e:	e39c                	sd	a5,0(a5)
    sched_class->init(rq);
ffffffffc0205130:	853a                	mv	a0,a4
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205132:	cb50                	sw	a2,20(a4)
    rq = &__rq;
ffffffffc0205134:	000b0797          	auipc	a5,0xb0
ffffffffc0205138:	62e7b223          	sd	a4,1572(a5) # ffffffffc02b5758 <rq>
    sched_class->init(rq);
ffffffffc020513c:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020513e:	000b0797          	auipc	a5,0xb0
ffffffffc0205142:	6227b783          	ld	a5,1570(a5) # ffffffffc02b5760 <sched_class>
}
ffffffffc0205146:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205148:	00002517          	auipc	a0,0x2
ffffffffc020514c:	33850513          	addi	a0,a0,824 # ffffffffc0207480 <etext+0x1bbe>
ffffffffc0205150:	638c                	ld	a1,0(a5)
}
ffffffffc0205152:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205154:	844fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0205158 <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205158:	4118                	lw	a4,0(a0)
{
ffffffffc020515a:	1101                	addi	sp,sp,-32
ffffffffc020515c:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020515e:	478d                	li	a5,3
ffffffffc0205160:	0cf70863          	beq	a4,a5,ffffffffc0205230 <wakeup_proc+0xd8>
ffffffffc0205164:	85aa                	mv	a1,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205166:	100027f3          	csrr	a5,sstatus
ffffffffc020516a:	8b89                	andi	a5,a5,2
ffffffffc020516c:	e3b1                	bnez	a5,ffffffffc02051b0 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020516e:	4789                	li	a5,2
ffffffffc0205170:	08f70563          	beq	a4,a5,ffffffffc02051fa <wakeup_proc+0xa2>
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
ffffffffc0205174:	000b0717          	auipc	a4,0xb0
ffffffffc0205178:	5cc73703          	ld	a4,1484(a4) # ffffffffc02b5740 <current>
            proc->wait_state = 0;
ffffffffc020517c:	0e052623          	sw	zero,236(a0)
            proc->state = PROC_RUNNABLE;
ffffffffc0205180:	c11c                	sw	a5,0(a0)
            if (proc != current)
ffffffffc0205182:	02e50463          	beq	a0,a4,ffffffffc02051aa <wakeup_proc+0x52>
    if (proc != idleproc)
ffffffffc0205186:	000b0797          	auipc	a5,0xb0
ffffffffc020518a:	5ca7b783          	ld	a5,1482(a5) # ffffffffc02b5750 <idleproc>
ffffffffc020518e:	00f50e63          	beq	a0,a5,ffffffffc02051aa <wakeup_proc+0x52>
        sched_class->enqueue(rq, proc);
ffffffffc0205192:	000b0797          	auipc	a5,0xb0
ffffffffc0205196:	5ce7b783          	ld	a5,1486(a5) # ffffffffc02b5760 <sched_class>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020519a:	60e2                	ld	ra,24(sp)
        sched_class->enqueue(rq, proc);
ffffffffc020519c:	000b0517          	auipc	a0,0xb0
ffffffffc02051a0:	5bc53503          	ld	a0,1468(a0) # ffffffffc02b5758 <rq>
ffffffffc02051a4:	6b9c                	ld	a5,16(a5)
}
ffffffffc02051a6:	6105                	addi	sp,sp,32
        sched_class->enqueue(rq, proc);
ffffffffc02051a8:	8782                	jr	a5
}
ffffffffc02051aa:	60e2                	ld	ra,24(sp)
ffffffffc02051ac:	6105                	addi	sp,sp,32
ffffffffc02051ae:	8082                	ret
        intr_disable();
ffffffffc02051b0:	e42a                	sd	a0,8(sp)
ffffffffc02051b2:	f4cfb0ef          	jal	ffffffffc02008fe <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051b6:	65a2                	ld	a1,8(sp)
ffffffffc02051b8:	4789                	li	a5,2
ffffffffc02051ba:	4198                	lw	a4,0(a1)
ffffffffc02051bc:	04f70d63          	beq	a4,a5,ffffffffc0205216 <wakeup_proc+0xbe>
            if (proc != current)
ffffffffc02051c0:	000b0717          	auipc	a4,0xb0
ffffffffc02051c4:	58073703          	ld	a4,1408(a4) # ffffffffc02b5740 <current>
            proc->wait_state = 0;
ffffffffc02051c8:	0e05a623          	sw	zero,236(a1)
            proc->state = PROC_RUNNABLE;
ffffffffc02051cc:	c19c                	sw	a5,0(a1)
            if (proc != current)
ffffffffc02051ce:	02e58263          	beq	a1,a4,ffffffffc02051f2 <wakeup_proc+0x9a>
    if (proc != idleproc)
ffffffffc02051d2:	000b0797          	auipc	a5,0xb0
ffffffffc02051d6:	57e7b783          	ld	a5,1406(a5) # ffffffffc02b5750 <idleproc>
ffffffffc02051da:	00f58c63          	beq	a1,a5,ffffffffc02051f2 <wakeup_proc+0x9a>
        sched_class->enqueue(rq, proc);
ffffffffc02051de:	000b0797          	auipc	a5,0xb0
ffffffffc02051e2:	5827b783          	ld	a5,1410(a5) # ffffffffc02b5760 <sched_class>
ffffffffc02051e6:	000b0517          	auipc	a0,0xb0
ffffffffc02051ea:	57253503          	ld	a0,1394(a0) # ffffffffc02b5758 <rq>
ffffffffc02051ee:	6b9c                	ld	a5,16(a5)
ffffffffc02051f0:	9782                	jalr	a5
}
ffffffffc02051f2:	60e2                	ld	ra,24(sp)
ffffffffc02051f4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051f6:	f02fb06f          	j	ffffffffc02008f8 <intr_enable>
ffffffffc02051fa:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051fc:	00002617          	auipc	a2,0x2
ffffffffc0205200:	2d460613          	addi	a2,a2,724 # ffffffffc02074d0 <etext+0x1c0e>
ffffffffc0205204:	05200593          	li	a1,82
ffffffffc0205208:	00002517          	auipc	a0,0x2
ffffffffc020520c:	2b050513          	addi	a0,a0,688 # ffffffffc02074b8 <etext+0x1bf6>
}
ffffffffc0205210:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc0205212:	aa2fb06f          	j	ffffffffc02004b4 <__warn>
ffffffffc0205216:	00002617          	auipc	a2,0x2
ffffffffc020521a:	2ba60613          	addi	a2,a2,698 # ffffffffc02074d0 <etext+0x1c0e>
ffffffffc020521e:	05200593          	li	a1,82
ffffffffc0205222:	00002517          	auipc	a0,0x2
ffffffffc0205226:	29650513          	addi	a0,a0,662 # ffffffffc02074b8 <etext+0x1bf6>
ffffffffc020522a:	a8afb0ef          	jal	ffffffffc02004b4 <__warn>
    if (flag)
ffffffffc020522e:	b7d1                	j	ffffffffc02051f2 <wakeup_proc+0x9a>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205230:	00002697          	auipc	a3,0x2
ffffffffc0205234:	26868693          	addi	a3,a3,616 # ffffffffc0207498 <etext+0x1bd6>
ffffffffc0205238:	00001617          	auipc	a2,0x1
ffffffffc020523c:	06060613          	addi	a2,a2,96 # ffffffffc0206298 <etext+0x9d6>
ffffffffc0205240:	04300593          	li	a1,67
ffffffffc0205244:	00002517          	auipc	a0,0x2
ffffffffc0205248:	27450513          	addi	a0,a0,628 # ffffffffc02074b8 <etext+0x1bf6>
ffffffffc020524c:	9fefb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205250 <schedule>:

void schedule(void)
{
ffffffffc0205250:	7139                	addi	sp,sp,-64
ffffffffc0205252:	fc06                	sd	ra,56(sp)
ffffffffc0205254:	f822                	sd	s0,48(sp)
ffffffffc0205256:	f426                	sd	s1,40(sp)
ffffffffc0205258:	f04a                	sd	s2,32(sp)
ffffffffc020525a:	ec4e                	sd	s3,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020525c:	100027f3          	csrr	a5,sstatus
ffffffffc0205260:	8b89                	andi	a5,a5,2
ffffffffc0205262:	4981                	li	s3,0
ffffffffc0205264:	efc9                	bnez	a5,ffffffffc02052fe <schedule+0xae>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205266:	000b0417          	auipc	s0,0xb0
ffffffffc020526a:	4da40413          	addi	s0,s0,1242 # ffffffffc02b5740 <current>
ffffffffc020526e:	600c                	ld	a1,0(s0)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205270:	4789                	li	a5,2
ffffffffc0205272:	000b0497          	auipc	s1,0xb0
ffffffffc0205276:	4e648493          	addi	s1,s1,1254 # ffffffffc02b5758 <rq>
ffffffffc020527a:	4198                	lw	a4,0(a1)
        current->need_resched = 0;
ffffffffc020527c:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205280:	000b0917          	auipc	s2,0xb0
ffffffffc0205284:	4e090913          	addi	s2,s2,1248 # ffffffffc02b5760 <sched_class>
ffffffffc0205288:	04f70f63          	beq	a4,a5,ffffffffc02052e6 <schedule+0x96>
    return sched_class->pick_next(rq);
ffffffffc020528c:	00093783          	ld	a5,0(s2)
ffffffffc0205290:	6088                	ld	a0,0(s1)
ffffffffc0205292:	739c                	ld	a5,32(a5)
ffffffffc0205294:	9782                	jalr	a5
ffffffffc0205296:	85aa                	mv	a1,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc0205298:	c131                	beqz	a0,ffffffffc02052dc <schedule+0x8c>
    sched_class->dequeue(rq, proc);
ffffffffc020529a:	00093783          	ld	a5,0(s2)
ffffffffc020529e:	6088                	ld	a0,0(s1)
ffffffffc02052a0:	e42e                	sd	a1,8(sp)
ffffffffc02052a2:	6f9c                	ld	a5,24(a5)
ffffffffc02052a4:	9782                	jalr	a5
ffffffffc02052a6:	65a2                	ld	a1,8(sp)
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02052a8:	459c                	lw	a5,8(a1)
        if (next != current)
ffffffffc02052aa:	6018                	ld	a4,0(s0)
        next->runs++;
ffffffffc02052ac:	2785                	addiw	a5,a5,1
ffffffffc02052ae:	c59c                	sw	a5,8(a1)
        if (next != current)
ffffffffc02052b0:	00b70563          	beq	a4,a1,ffffffffc02052ba <schedule+0x6a>
        {
            proc_run(next);
ffffffffc02052b4:	852e                	mv	a0,a1
ffffffffc02052b6:	bb5fe0ef          	jal	ffffffffc0203e6a <proc_run>
    if (flag)
ffffffffc02052ba:	00099963          	bnez	s3,ffffffffc02052cc <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052be:	70e2                	ld	ra,56(sp)
ffffffffc02052c0:	7442                	ld	s0,48(sp)
ffffffffc02052c2:	74a2                	ld	s1,40(sp)
ffffffffc02052c4:	7902                	ld	s2,32(sp)
ffffffffc02052c6:	69e2                	ld	s3,24(sp)
ffffffffc02052c8:	6121                	addi	sp,sp,64
ffffffffc02052ca:	8082                	ret
ffffffffc02052cc:	7442                	ld	s0,48(sp)
ffffffffc02052ce:	70e2                	ld	ra,56(sp)
ffffffffc02052d0:	74a2                	ld	s1,40(sp)
ffffffffc02052d2:	7902                	ld	s2,32(sp)
ffffffffc02052d4:	69e2                	ld	s3,24(sp)
ffffffffc02052d6:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc02052d8:	e20fb06f          	j	ffffffffc02008f8 <intr_enable>
            next = idleproc;
ffffffffc02052dc:	000b0597          	auipc	a1,0xb0
ffffffffc02052e0:	4745b583          	ld	a1,1140(a1) # ffffffffc02b5750 <idleproc>
ffffffffc02052e4:	b7d1                	j	ffffffffc02052a8 <schedule+0x58>
    if (proc != idleproc)
ffffffffc02052e6:	000b0797          	auipc	a5,0xb0
ffffffffc02052ea:	46a7b783          	ld	a5,1130(a5) # ffffffffc02b5750 <idleproc>
ffffffffc02052ee:	f8f58fe3          	beq	a1,a5,ffffffffc020528c <schedule+0x3c>
        sched_class->enqueue(rq, proc);
ffffffffc02052f2:	00093783          	ld	a5,0(s2)
ffffffffc02052f6:	6088                	ld	a0,0(s1)
ffffffffc02052f8:	6b9c                	ld	a5,16(a5)
ffffffffc02052fa:	9782                	jalr	a5
ffffffffc02052fc:	bf41                	j	ffffffffc020528c <schedule+0x3c>
        intr_disable();
ffffffffc02052fe:	e00fb0ef          	jal	ffffffffc02008fe <intr_disable>
        return 1;
ffffffffc0205302:	4985                	li	s3,1
ffffffffc0205304:	b78d                	j	ffffffffc0205266 <schedule+0x16>

ffffffffc0205306 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205306:	000b0797          	auipc	a5,0xb0
ffffffffc020530a:	43a7b783          	ld	a5,1082(a5) # ffffffffc02b5740 <current>
}
ffffffffc020530e:	43c8                	lw	a0,4(a5)
ffffffffc0205310:	8082                	ret

ffffffffc0205312 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205312:	4501                	li	a0,0
ffffffffc0205314:	8082                	ret

ffffffffc0205316 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc0205316:	000b0797          	auipc	a5,0xb0
ffffffffc020531a:	3d27b783          	ld	a5,978(a5) # ffffffffc02b56e8 <ticks>
ffffffffc020531e:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205322:	9d3d                	addw	a0,a0,a5
ffffffffc0205324:	0015151b          	slliw	a0,a0,0x1
}
ffffffffc0205328:	8082                	ret

ffffffffc020532a <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc020532a:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc020532c:	1141                	addi	sp,sp,-16
ffffffffc020532e:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205330:	c95ff0ef          	jal	ffffffffc0204fc4 <lab6_set_priority>
    return 0;
}
ffffffffc0205334:	60a2                	ld	ra,8(sp)
ffffffffc0205336:	4501                	li	a0,0
ffffffffc0205338:	0141                	addi	sp,sp,16
ffffffffc020533a:	8082                	ret

ffffffffc020533c <sys_putc>:
    cputchar(c);
ffffffffc020533c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020533e:	1141                	addi	sp,sp,-16
ffffffffc0205340:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205342:	e8bfa0ef          	jal	ffffffffc02001cc <cputchar>
}
ffffffffc0205346:	60a2                	ld	ra,8(sp)
ffffffffc0205348:	4501                	li	a0,0
ffffffffc020534a:	0141                	addi	sp,sp,16
ffffffffc020534c:	8082                	ret

ffffffffc020534e <sys_kill>:
    return do_kill(pid);
ffffffffc020534e:	4108                	lw	a0,0(a0)
ffffffffc0205350:	a43ff06f          	j	ffffffffc0204d92 <do_kill>

ffffffffc0205354 <sys_yield>:
    return do_yield();
ffffffffc0205354:	9f5ff06f          	j	ffffffffc0204d48 <do_yield>

ffffffffc0205358 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205358:	6d14                	ld	a3,24(a0)
ffffffffc020535a:	6910                	ld	a2,16(a0)
ffffffffc020535c:	650c                	ld	a1,8(a0)
ffffffffc020535e:	6108                	ld	a0,0(a0)
ffffffffc0205360:	bbcff06f          	j	ffffffffc020471c <do_execve>

ffffffffc0205364 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205364:	650c                	ld	a1,8(a0)
ffffffffc0205366:	4108                	lw	a0,0(a0)
ffffffffc0205368:	9f1ff06f          	j	ffffffffc0204d58 <do_wait>

ffffffffc020536c <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020536c:	000b0797          	auipc	a5,0xb0
ffffffffc0205370:	3d47b783          	ld	a5,980(a5) # ffffffffc02b5740 <current>
    return do_fork(0, stack, tf);
ffffffffc0205374:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0205376:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205378:	6a0c                	ld	a1,16(a2)
ffffffffc020537a:	b53fe06f          	j	ffffffffc0203ecc <do_fork>

ffffffffc020537e <sys_exit>:
    return do_exit(error_code);
ffffffffc020537e:	4108                	lw	a0,0(a0)
ffffffffc0205380:	f53fe06f          	j	ffffffffc02042d2 <do_exit>

ffffffffc0205384 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205384:	000b0697          	auipc	a3,0xb0
ffffffffc0205388:	3bc6b683          	ld	a3,956(a3) # ffffffffc02b5740 <current>
syscall(void) {
ffffffffc020538c:	715d                	addi	sp,sp,-80
ffffffffc020538e:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205390:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205392:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205394:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc0205398:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020539a:	02d7ec63          	bltu	a5,a3,ffffffffc02053d2 <syscall+0x4e>
        if (syscalls[num] != NULL) {
ffffffffc020539e:	00002797          	auipc	a5,0x2
ffffffffc02053a2:	37a78793          	addi	a5,a5,890 # ffffffffc0207718 <syscalls>
ffffffffc02053a6:	00369613          	slli	a2,a3,0x3
ffffffffc02053aa:	97b2                	add	a5,a5,a2
ffffffffc02053ac:	639c                	ld	a5,0(a5)
ffffffffc02053ae:	c395                	beqz	a5,ffffffffc02053d2 <syscall+0x4e>
            arg[0] = tf->gpr.a1;
ffffffffc02053b0:	7028                	ld	a0,96(s0)
ffffffffc02053b2:	742c                	ld	a1,104(s0)
ffffffffc02053b4:	7830                	ld	a2,112(s0)
ffffffffc02053b6:	7c34                	ld	a3,120(s0)
ffffffffc02053b8:	6c38                	ld	a4,88(s0)
ffffffffc02053ba:	f02a                	sd	a0,32(sp)
ffffffffc02053bc:	f42e                	sd	a1,40(sp)
ffffffffc02053be:	f832                	sd	a2,48(sp)
ffffffffc02053c0:	fc36                	sd	a3,56(sp)
ffffffffc02053c2:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053c4:	0828                	addi	a0,sp,24
ffffffffc02053c6:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053c8:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053ca:	e828                	sd	a0,80(s0)
}
ffffffffc02053cc:	6406                	ld	s0,64(sp)
ffffffffc02053ce:	6161                	addi	sp,sp,80
ffffffffc02053d0:	8082                	ret
    print_trapframe(tf);
ffffffffc02053d2:	8522                	mv	a0,s0
ffffffffc02053d4:	e436                	sd	a3,8(sp)
ffffffffc02053d6:	f18fb0ef          	jal	ffffffffc0200aee <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053da:	000b0797          	auipc	a5,0xb0
ffffffffc02053de:	3667b783          	ld	a5,870(a5) # ffffffffc02b5740 <current>
ffffffffc02053e2:	66a2                	ld	a3,8(sp)
ffffffffc02053e4:	00002617          	auipc	a2,0x2
ffffffffc02053e8:	10c60613          	addi	a2,a2,268 # ffffffffc02074f0 <etext+0x1c2e>
ffffffffc02053ec:	43d8                	lw	a4,4(a5)
ffffffffc02053ee:	06c00593          	li	a1,108
ffffffffc02053f2:	0b478793          	addi	a5,a5,180
ffffffffc02053f6:	00002517          	auipc	a0,0x2
ffffffffc02053fa:	12a50513          	addi	a0,a0,298 # ffffffffc0207520 <etext+0x1c5e>
ffffffffc02053fe:	84cfb0ef          	jal	ffffffffc020044a <__panic>

ffffffffc0205402 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205402:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205406:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_matrix_out_size+0xffffffff9e364ac1>
ffffffffc0205408:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc020540c:	02000513          	li	a0,32
ffffffffc0205410:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205412:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0205416:	8082                	ret

ffffffffc0205418 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205418:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020541a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020541e:	f022                	sd	s0,32(sp)
ffffffffc0205420:	ec26                	sd	s1,24(sp)
ffffffffc0205422:	e84a                	sd	s2,16(sp)
ffffffffc0205424:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205426:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020542a:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc020542c:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205430:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205434:	84aa                	mv	s1,a0
ffffffffc0205436:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0205438:	03067d63          	bgeu	a2,a6,ffffffffc0205472 <printnum+0x5a>
ffffffffc020543c:	e44e                	sd	s3,8(sp)
ffffffffc020543e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205440:	4785                	li	a5,1
ffffffffc0205442:	00e7d763          	bge	a5,a4,ffffffffc0205450 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205446:	85ca                	mv	a1,s2
ffffffffc0205448:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc020544a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020544c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020544e:	fc65                	bnez	s0,ffffffffc0205446 <printnum+0x2e>
ffffffffc0205450:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205452:	00002797          	auipc	a5,0x2
ffffffffc0205456:	0e678793          	addi	a5,a5,230 # ffffffffc0207538 <etext+0x1c76>
ffffffffc020545a:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020545c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020545e:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205462:	70a2                	ld	ra,40(sp)
ffffffffc0205464:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205466:	85ca                	mv	a1,s2
ffffffffc0205468:	87a6                	mv	a5,s1
}
ffffffffc020546a:	6942                	ld	s2,16(sp)
ffffffffc020546c:	64e2                	ld	s1,24(sp)
ffffffffc020546e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205470:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205472:	03065633          	divu	a2,a2,a6
ffffffffc0205476:	8722                	mv	a4,s0
ffffffffc0205478:	fa1ff0ef          	jal	ffffffffc0205418 <printnum>
ffffffffc020547c:	bfd9                	j	ffffffffc0205452 <printnum+0x3a>

ffffffffc020547e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020547e:	7119                	addi	sp,sp,-128
ffffffffc0205480:	f4a6                	sd	s1,104(sp)
ffffffffc0205482:	f0ca                	sd	s2,96(sp)
ffffffffc0205484:	ecce                	sd	s3,88(sp)
ffffffffc0205486:	e8d2                	sd	s4,80(sp)
ffffffffc0205488:	e4d6                	sd	s5,72(sp)
ffffffffc020548a:	e0da                	sd	s6,64(sp)
ffffffffc020548c:	f862                	sd	s8,48(sp)
ffffffffc020548e:	fc86                	sd	ra,120(sp)
ffffffffc0205490:	f8a2                	sd	s0,112(sp)
ffffffffc0205492:	fc5e                	sd	s7,56(sp)
ffffffffc0205494:	f466                	sd	s9,40(sp)
ffffffffc0205496:	f06a                	sd	s10,32(sp)
ffffffffc0205498:	ec6e                	sd	s11,24(sp)
ffffffffc020549a:	84aa                	mv	s1,a0
ffffffffc020549c:	8c32                	mv	s8,a2
ffffffffc020549e:	8a36                	mv	s4,a3
ffffffffc02054a0:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054a2:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054a6:	05500b13          	li	s6,85
ffffffffc02054aa:	00003a97          	auipc	s5,0x3
ffffffffc02054ae:	a6ea8a93          	addi	s5,s5,-1426 # ffffffffc0207f18 <syscalls+0x800>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054b2:	000c4503          	lbu	a0,0(s8)
ffffffffc02054b6:	001c0413          	addi	s0,s8,1
ffffffffc02054ba:	01350a63          	beq	a0,s3,ffffffffc02054ce <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02054be:	cd0d                	beqz	a0,ffffffffc02054f8 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02054c0:	85ca                	mv	a1,s2
ffffffffc02054c2:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054c4:	00044503          	lbu	a0,0(s0)
ffffffffc02054c8:	0405                	addi	s0,s0,1
ffffffffc02054ca:	ff351ae3          	bne	a0,s3,ffffffffc02054be <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02054ce:	5cfd                	li	s9,-1
ffffffffc02054d0:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02054d2:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02054d6:	4b81                	li	s7,0
ffffffffc02054d8:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054da:	00044683          	lbu	a3,0(s0)
ffffffffc02054de:	00140c13          	addi	s8,s0,1
ffffffffc02054e2:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02054e6:	0ff5f593          	zext.b	a1,a1
ffffffffc02054ea:	02bb6663          	bltu	s6,a1,ffffffffc0205516 <vprintfmt+0x98>
ffffffffc02054ee:	058a                	slli	a1,a1,0x2
ffffffffc02054f0:	95d6                	add	a1,a1,s5
ffffffffc02054f2:	4198                	lw	a4,0(a1)
ffffffffc02054f4:	9756                	add	a4,a4,s5
ffffffffc02054f6:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054f8:	70e6                	ld	ra,120(sp)
ffffffffc02054fa:	7446                	ld	s0,112(sp)
ffffffffc02054fc:	74a6                	ld	s1,104(sp)
ffffffffc02054fe:	7906                	ld	s2,96(sp)
ffffffffc0205500:	69e6                	ld	s3,88(sp)
ffffffffc0205502:	6a46                	ld	s4,80(sp)
ffffffffc0205504:	6aa6                	ld	s5,72(sp)
ffffffffc0205506:	6b06                	ld	s6,64(sp)
ffffffffc0205508:	7be2                	ld	s7,56(sp)
ffffffffc020550a:	7c42                	ld	s8,48(sp)
ffffffffc020550c:	7ca2                	ld	s9,40(sp)
ffffffffc020550e:	7d02                	ld	s10,32(sp)
ffffffffc0205510:	6de2                	ld	s11,24(sp)
ffffffffc0205512:	6109                	addi	sp,sp,128
ffffffffc0205514:	8082                	ret
            putch('%', putdat);
ffffffffc0205516:	85ca                	mv	a1,s2
ffffffffc0205518:	02500513          	li	a0,37
ffffffffc020551c:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020551e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205522:	02500713          	li	a4,37
ffffffffc0205526:	8c22                	mv	s8,s0
ffffffffc0205528:	f8e785e3          	beq	a5,a4,ffffffffc02054b2 <vprintfmt+0x34>
ffffffffc020552c:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205530:	1c7d                	addi	s8,s8,-1
ffffffffc0205532:	fee79de3          	bne	a5,a4,ffffffffc020552c <vprintfmt+0xae>
ffffffffc0205536:	bfb5                	j	ffffffffc02054b2 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0205538:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020553c:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc020553e:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205542:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205546:	24e56a63          	bltu	a0,a4,ffffffffc020579a <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc020554a:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020554c:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc020554e:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205552:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205556:	0197073b          	addw	a4,a4,s9
ffffffffc020555a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020555e:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205560:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205564:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205566:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020556a:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc020556e:	feb570e3          	bgeu	a0,a1,ffffffffc020554e <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205572:	f60d54e3          	bgez	s10,ffffffffc02054da <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0205576:	8d66                	mv	s10,s9
ffffffffc0205578:	5cfd                	li	s9,-1
ffffffffc020557a:	b785                	j	ffffffffc02054da <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020557c:	8db6                	mv	s11,a3
ffffffffc020557e:	8462                	mv	s0,s8
ffffffffc0205580:	bfa9                	j	ffffffffc02054da <vprintfmt+0x5c>
ffffffffc0205582:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205584:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205586:	bf91                	j	ffffffffc02054da <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0205588:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020558a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020558e:	00f74463          	blt	a4,a5,ffffffffc0205596 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205592:	1a078763          	beqz	a5,ffffffffc0205740 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205596:	000a3603          	ld	a2,0(s4)
ffffffffc020559a:	46c1                	li	a3,16
ffffffffc020559c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020559e:	000d879b          	sext.w	a5,s11
ffffffffc02055a2:	876a                	mv	a4,s10
ffffffffc02055a4:	85ca                	mv	a1,s2
ffffffffc02055a6:	8526                	mv	a0,s1
ffffffffc02055a8:	e71ff0ef          	jal	ffffffffc0205418 <printnum>
            break;
ffffffffc02055ac:	b719                	j	ffffffffc02054b2 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02055ae:	000a2503          	lw	a0,0(s4)
ffffffffc02055b2:	85ca                	mv	a1,s2
ffffffffc02055b4:	0a21                	addi	s4,s4,8
ffffffffc02055b6:	9482                	jalr	s1
            break;
ffffffffc02055b8:	bded                	j	ffffffffc02054b2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02055ba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055bc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055c0:	00f74463          	blt	a4,a5,ffffffffc02055c8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02055c4:	16078963          	beqz	a5,ffffffffc0205736 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02055c8:	000a3603          	ld	a2,0(s4)
ffffffffc02055cc:	46a9                	li	a3,10
ffffffffc02055ce:	8a2e                	mv	s4,a1
ffffffffc02055d0:	b7f9                	j	ffffffffc020559e <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02055d2:	85ca                	mv	a1,s2
ffffffffc02055d4:	03000513          	li	a0,48
ffffffffc02055d8:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02055da:	85ca                	mv	a1,s2
ffffffffc02055dc:	07800513          	li	a0,120
ffffffffc02055e0:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055e2:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02055e6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055e8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055ea:	bf55                	j	ffffffffc020559e <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02055ec:	85ca                	mv	a1,s2
ffffffffc02055ee:	02500513          	li	a0,37
ffffffffc02055f2:	9482                	jalr	s1
            break;
ffffffffc02055f4:	bd7d                	j	ffffffffc02054b2 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02055f6:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055fa:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02055fc:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02055fe:	bf95                	j	ffffffffc0205572 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205600:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205602:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205606:	00f74463          	blt	a4,a5,ffffffffc020560e <vprintfmt+0x190>
    else if (lflag) {
ffffffffc020560a:	12078163          	beqz	a5,ffffffffc020572c <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc020560e:	000a3603          	ld	a2,0(s4)
ffffffffc0205612:	46a1                	li	a3,8
ffffffffc0205614:	8a2e                	mv	s4,a1
ffffffffc0205616:	b761                	j	ffffffffc020559e <vprintfmt+0x120>
            if (width < 0)
ffffffffc0205618:	876a                	mv	a4,s10
ffffffffc020561a:	000d5363          	bgez	s10,ffffffffc0205620 <vprintfmt+0x1a2>
ffffffffc020561e:	4701                	li	a4,0
ffffffffc0205620:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205624:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205626:	bd55                	j	ffffffffc02054da <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0205628:	000d841b          	sext.w	s0,s11
ffffffffc020562c:	fd340793          	addi	a5,s0,-45
ffffffffc0205630:	00f037b3          	snez	a5,a5
ffffffffc0205634:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205638:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020563c:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020563e:	008a0793          	addi	a5,s4,8
ffffffffc0205642:	e43e                	sd	a5,8(sp)
ffffffffc0205644:	100d8c63          	beqz	s11,ffffffffc020575c <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0205648:	12071363          	bnez	a4,ffffffffc020576e <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020564c:	000dc783          	lbu	a5,0(s11)
ffffffffc0205650:	0007851b          	sext.w	a0,a5
ffffffffc0205654:	c78d                	beqz	a5,ffffffffc020567e <vprintfmt+0x200>
ffffffffc0205656:	0d85                	addi	s11,s11,1
ffffffffc0205658:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020565a:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020565e:	000cc563          	bltz	s9,ffffffffc0205668 <vprintfmt+0x1ea>
ffffffffc0205662:	3cfd                	addiw	s9,s9,-1
ffffffffc0205664:	008c8d63          	beq	s9,s0,ffffffffc020567e <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205668:	020b9663          	bnez	s7,ffffffffc0205694 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc020566c:	85ca                	mv	a1,s2
ffffffffc020566e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205670:	000dc783          	lbu	a5,0(s11)
ffffffffc0205674:	0d85                	addi	s11,s11,1
ffffffffc0205676:	3d7d                	addiw	s10,s10,-1
ffffffffc0205678:	0007851b          	sext.w	a0,a5
ffffffffc020567c:	f3ed                	bnez	a5,ffffffffc020565e <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc020567e:	01a05963          	blez	s10,ffffffffc0205690 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205682:	85ca                	mv	a1,s2
ffffffffc0205684:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0205688:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc020568a:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020568c:	fe0d1be3          	bnez	s10,ffffffffc0205682 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205690:	6a22                	ld	s4,8(sp)
ffffffffc0205692:	b505                	j	ffffffffc02054b2 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205694:	3781                	addiw	a5,a5,-32
ffffffffc0205696:	fcfa7be3          	bgeu	s4,a5,ffffffffc020566c <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc020569a:	03f00513          	li	a0,63
ffffffffc020569e:	85ca                	mv	a1,s2
ffffffffc02056a0:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056a2:	000dc783          	lbu	a5,0(s11)
ffffffffc02056a6:	0d85                	addi	s11,s11,1
ffffffffc02056a8:	3d7d                	addiw	s10,s10,-1
ffffffffc02056aa:	0007851b          	sext.w	a0,a5
ffffffffc02056ae:	dbe1                	beqz	a5,ffffffffc020567e <vprintfmt+0x200>
ffffffffc02056b0:	fa0cd9e3          	bgez	s9,ffffffffc0205662 <vprintfmt+0x1e4>
ffffffffc02056b4:	b7c5                	j	ffffffffc0205694 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02056b6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056ba:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc02056bc:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056be:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02056c2:	8fb9                	xor	a5,a5,a4
ffffffffc02056c4:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056c8:	02d64563          	blt	a2,a3,ffffffffc02056f2 <vprintfmt+0x274>
ffffffffc02056cc:	00003797          	auipc	a5,0x3
ffffffffc02056d0:	9a478793          	addi	a5,a5,-1628 # ffffffffc0208070 <error_string>
ffffffffc02056d4:	00369713          	slli	a4,a3,0x3
ffffffffc02056d8:	97ba                	add	a5,a5,a4
ffffffffc02056da:	639c                	ld	a5,0(a5)
ffffffffc02056dc:	cb99                	beqz	a5,ffffffffc02056f2 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056de:	86be                	mv	a3,a5
ffffffffc02056e0:	00000617          	auipc	a2,0x0
ffffffffc02056e4:	21060613          	addi	a2,a2,528 # ffffffffc02058f0 <etext+0x2e>
ffffffffc02056e8:	85ca                	mv	a1,s2
ffffffffc02056ea:	8526                	mv	a0,s1
ffffffffc02056ec:	0d8000ef          	jal	ffffffffc02057c4 <printfmt>
ffffffffc02056f0:	b3c9                	j	ffffffffc02054b2 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056f2:	00002617          	auipc	a2,0x2
ffffffffc02056f6:	e6660613          	addi	a2,a2,-410 # ffffffffc0207558 <etext+0x1c96>
ffffffffc02056fa:	85ca                	mv	a1,s2
ffffffffc02056fc:	8526                	mv	a0,s1
ffffffffc02056fe:	0c6000ef          	jal	ffffffffc02057c4 <printfmt>
ffffffffc0205702:	bb45                	j	ffffffffc02054b2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205704:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205706:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020570a:	00f74363          	blt	a4,a5,ffffffffc0205710 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc020570e:	cf81                	beqz	a5,ffffffffc0205726 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205710:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205714:	02044b63          	bltz	s0,ffffffffc020574a <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0205718:	8622                	mv	a2,s0
ffffffffc020571a:	8a5e                	mv	s4,s7
ffffffffc020571c:	46a9                	li	a3,10
ffffffffc020571e:	b541                	j	ffffffffc020559e <vprintfmt+0x120>
            lflag ++;
ffffffffc0205720:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205722:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205724:	bb5d                	j	ffffffffc02054da <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0205726:	000a2403          	lw	s0,0(s4)
ffffffffc020572a:	b7ed                	j	ffffffffc0205714 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc020572c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205730:	46a1                	li	a3,8
ffffffffc0205732:	8a2e                	mv	s4,a1
ffffffffc0205734:	b5ad                	j	ffffffffc020559e <vprintfmt+0x120>
ffffffffc0205736:	000a6603          	lwu	a2,0(s4)
ffffffffc020573a:	46a9                	li	a3,10
ffffffffc020573c:	8a2e                	mv	s4,a1
ffffffffc020573e:	b585                	j	ffffffffc020559e <vprintfmt+0x120>
ffffffffc0205740:	000a6603          	lwu	a2,0(s4)
ffffffffc0205744:	46c1                	li	a3,16
ffffffffc0205746:	8a2e                	mv	s4,a1
ffffffffc0205748:	bd99                	j	ffffffffc020559e <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc020574a:	85ca                	mv	a1,s2
ffffffffc020574c:	02d00513          	li	a0,45
ffffffffc0205750:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205752:	40800633          	neg	a2,s0
ffffffffc0205756:	8a5e                	mv	s4,s7
ffffffffc0205758:	46a9                	li	a3,10
ffffffffc020575a:	b591                	j	ffffffffc020559e <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020575c:	e329                	bnez	a4,ffffffffc020579e <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020575e:	02800793          	li	a5,40
ffffffffc0205762:	853e                	mv	a0,a5
ffffffffc0205764:	00002d97          	auipc	s11,0x2
ffffffffc0205768:	dedd8d93          	addi	s11,s11,-531 # ffffffffc0207551 <etext+0x1c8f>
ffffffffc020576c:	b5f5                	j	ffffffffc0205658 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020576e:	85e6                	mv	a1,s9
ffffffffc0205770:	856e                	mv	a0,s11
ffffffffc0205772:	08a000ef          	jal	ffffffffc02057fc <strnlen>
ffffffffc0205776:	40ad0d3b          	subw	s10,s10,a0
ffffffffc020577a:	01a05863          	blez	s10,ffffffffc020578a <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc020577e:	85ca                	mv	a1,s2
ffffffffc0205780:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205782:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205784:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205786:	fe0d1ce3          	bnez	s10,ffffffffc020577e <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020578a:	000dc783          	lbu	a5,0(s11)
ffffffffc020578e:	0007851b          	sext.w	a0,a5
ffffffffc0205792:	ec0792e3          	bnez	a5,ffffffffc0205656 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205796:	6a22                	ld	s4,8(sp)
ffffffffc0205798:	bb29                	j	ffffffffc02054b2 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020579a:	8462                	mv	s0,s8
ffffffffc020579c:	bbd9                	j	ffffffffc0205572 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020579e:	85e6                	mv	a1,s9
ffffffffc02057a0:	00002517          	auipc	a0,0x2
ffffffffc02057a4:	db050513          	addi	a0,a0,-592 # ffffffffc0207550 <etext+0x1c8e>
ffffffffc02057a8:	054000ef          	jal	ffffffffc02057fc <strnlen>
ffffffffc02057ac:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057b0:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02057b4:	00002d97          	auipc	s11,0x2
ffffffffc02057b8:	d9cd8d93          	addi	s11,s11,-612 # ffffffffc0207550 <etext+0x1c8e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057bc:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057be:	fda040e3          	bgtz	s10,ffffffffc020577e <vprintfmt+0x300>
ffffffffc02057c2:	bd51                	j	ffffffffc0205656 <vprintfmt+0x1d8>

ffffffffc02057c4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057c4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057c6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057ca:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057cc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057ce:	ec06                	sd	ra,24(sp)
ffffffffc02057d0:	f83a                	sd	a4,48(sp)
ffffffffc02057d2:	fc3e                	sd	a5,56(sp)
ffffffffc02057d4:	e0c2                	sd	a6,64(sp)
ffffffffc02057d6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057d8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057da:	ca5ff0ef          	jal	ffffffffc020547e <vprintfmt>
}
ffffffffc02057de:	60e2                	ld	ra,24(sp)
ffffffffc02057e0:	6161                	addi	sp,sp,80
ffffffffc02057e2:	8082                	ret

ffffffffc02057e4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057e4:	00054783          	lbu	a5,0(a0)
ffffffffc02057e8:	cb81                	beqz	a5,ffffffffc02057f8 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02057ea:	4781                	li	a5,0
        cnt ++;
ffffffffc02057ec:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02057ee:	00f50733          	add	a4,a0,a5
ffffffffc02057f2:	00074703          	lbu	a4,0(a4)
ffffffffc02057f6:	fb7d                	bnez	a4,ffffffffc02057ec <strlen+0x8>
    }
    return cnt;
}
ffffffffc02057f8:	853e                	mv	a0,a5
ffffffffc02057fa:	8082                	ret

ffffffffc02057fc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057fc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057fe:	e589                	bnez	a1,ffffffffc0205808 <strnlen+0xc>
ffffffffc0205800:	a811                	j	ffffffffc0205814 <strnlen+0x18>
        cnt ++;
ffffffffc0205802:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205804:	00f58863          	beq	a1,a5,ffffffffc0205814 <strnlen+0x18>
ffffffffc0205808:	00f50733          	add	a4,a0,a5
ffffffffc020580c:	00074703          	lbu	a4,0(a4)
ffffffffc0205810:	fb6d                	bnez	a4,ffffffffc0205802 <strnlen+0x6>
ffffffffc0205812:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205814:	852e                	mv	a0,a1
ffffffffc0205816:	8082                	ret

ffffffffc0205818 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205818:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020581a:	0005c703          	lbu	a4,0(a1)
ffffffffc020581e:	0585                	addi	a1,a1,1
ffffffffc0205820:	0785                	addi	a5,a5,1
ffffffffc0205822:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205826:	fb75                	bnez	a4,ffffffffc020581a <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205828:	8082                	ret

ffffffffc020582a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020582a:	00054783          	lbu	a5,0(a0)
ffffffffc020582e:	e791                	bnez	a5,ffffffffc020583a <strcmp+0x10>
ffffffffc0205830:	a01d                	j	ffffffffc0205856 <strcmp+0x2c>
ffffffffc0205832:	00054783          	lbu	a5,0(a0)
ffffffffc0205836:	cb99                	beqz	a5,ffffffffc020584c <strcmp+0x22>
ffffffffc0205838:	0585                	addi	a1,a1,1
ffffffffc020583a:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020583e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205840:	fef709e3          	beq	a4,a5,ffffffffc0205832 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205844:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205848:	9d19                	subw	a0,a0,a4
ffffffffc020584a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020584c:	0015c703          	lbu	a4,1(a1)
ffffffffc0205850:	4501                	li	a0,0
}
ffffffffc0205852:	9d19                	subw	a0,a0,a4
ffffffffc0205854:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205856:	0005c703          	lbu	a4,0(a1)
ffffffffc020585a:	4501                	li	a0,0
ffffffffc020585c:	b7f5                	j	ffffffffc0205848 <strcmp+0x1e>

ffffffffc020585e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020585e:	ce01                	beqz	a2,ffffffffc0205876 <strncmp+0x18>
ffffffffc0205860:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205864:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205866:	cb91                	beqz	a5,ffffffffc020587a <strncmp+0x1c>
ffffffffc0205868:	0005c703          	lbu	a4,0(a1)
ffffffffc020586c:	00f71763          	bne	a4,a5,ffffffffc020587a <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205870:	0505                	addi	a0,a0,1
ffffffffc0205872:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205874:	f675                	bnez	a2,ffffffffc0205860 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205876:	4501                	li	a0,0
ffffffffc0205878:	8082                	ret
ffffffffc020587a:	00054503          	lbu	a0,0(a0)
ffffffffc020587e:	0005c783          	lbu	a5,0(a1)
ffffffffc0205882:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205884:	8082                	ret

ffffffffc0205886 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205886:	a021                	j	ffffffffc020588e <strchr+0x8>
        if (*s == c) {
ffffffffc0205888:	00f58763          	beq	a1,a5,ffffffffc0205896 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020588c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020588e:	00054783          	lbu	a5,0(a0)
ffffffffc0205892:	fbfd                	bnez	a5,ffffffffc0205888 <strchr+0x2>
    }
    return NULL;
ffffffffc0205894:	4501                	li	a0,0
}
ffffffffc0205896:	8082                	ret

ffffffffc0205898 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205898:	ca01                	beqz	a2,ffffffffc02058a8 <memset+0x10>
ffffffffc020589a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020589c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020589e:	0785                	addi	a5,a5,1
ffffffffc02058a0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02058a4:	fef61de3          	bne	a2,a5,ffffffffc020589e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02058a8:	8082                	ret

ffffffffc02058aa <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02058aa:	ca19                	beqz	a2,ffffffffc02058c0 <memcpy+0x16>
ffffffffc02058ac:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02058ae:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02058b0:	0005c703          	lbu	a4,0(a1)
ffffffffc02058b4:	0585                	addi	a1,a1,1
ffffffffc02058b6:	0785                	addi	a5,a5,1
ffffffffc02058b8:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058bc:	feb61ae3          	bne	a2,a1,ffffffffc02058b0 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058c0:	8082                	ret
