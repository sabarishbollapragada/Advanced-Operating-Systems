
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 10 cb 17 f0       	mov    $0xf017cb10,%eax
f010004b:	2d ee bb 17 f0       	sub    $0xf017bbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee bb 17 f0       	push   $0xf017bbee
f0100058:	e8 43 40 00 00       	call   f01040a0 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 45 10 f0       	push   $0xf0104540
f010006f:	e8 42 2e 00 00       	call   f0102eb6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 db 0f 00 00       	call   f0101054 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 87 28 00 00       	call   f0102905 <env_init>
	trap_init();
f010007e:	e8 ad 2e 00 00       	call   f0102f30 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 e2 43 17 f0       	push   $0xf01743e2
f010008d:	e8 39 2a 00 00       	call   f0102acb <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 be 17 f0    	pushl  0xf017be48
f010009b:	e8 4f 2d 00 00       	call   f0102def <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 cb 17 f0 00 	cmpl   $0x0,0xf017cb00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 cb 17 f0    	mov    %esi,0xf017cb00

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 5b 45 10 f0       	push   $0xf010455b
f01000ca:	e8 e7 2d 00 00       	call   f0102eb6 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 b7 2d 00 00       	call   f0102e90 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 aa 4d 10 f0 	movl   $0xf0104daa,(%esp)
f01000e0:	e8 d1 2d 00 00       	call   f0102eb6 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 c7 06 00 00       	call   f01007b9 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 73 45 10 f0       	push   $0xf0104573
f010010c:	e8 a5 2d 00 00       	call   f0102eb6 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 73 2d 00 00       	call   f0102e90 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 aa 4d 10 f0 	movl   $0xf0104daa,(%esp)
f0100124:	e8 8d 2d 00 00       	call   f0102eb6 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 be 17 f0    	mov    0xf017be24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 be 17 f0    	mov    %edx,0xf017be24
f010016e:	88 81 20 bc 17 f0    	mov    %al,-0xfe843e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 be 17 f0 00 	movl   $0x0,0xf017be24
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 00 bc 17 f0 40 	orl    $0x40,0xf017bc00
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 e0 46 10 f0 	movzbl -0xfefb920(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 00 bc 17 f0    	mov    %ecx,0xf017bc00
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 e0 46 10 f0 	movzbl -0xfefb920(%edx),%eax
f0100226:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f010022c:	0f b6 8a e0 45 10 f0 	movzbl -0xfefba20(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d c0 45 10 f0 	mov    -0xfefba40(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 8d 45 10 f0       	push   $0xf010458d
f0100282:	e8 2f 2c 00 00       	call   f0102eb6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 28 be 17 f0 	addw   $0x50,0xf017be28
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 28 be 17 f0 	mov    %dx,0xf017be28
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 28 be 17 f0 	cmpw   $0x7cf,0xf017be28
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 2c be 17 f0       	mov    0xf017be2c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 b7 3c 00 00       	call   f01040ed <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 28 be 17 f0 	subw   $0x50,0xf017be28
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 30 be 17 f0    	mov    0xf017be30,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 28 be 17 f0 	movzwl 0xf017be28,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 34 be 17 f0 00 	cmpb   $0x0,0xf017be34
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 20 be 17 f0       	mov    0xf017be20,%eax
f01004d8:	3b 05 24 be 17 f0    	cmp    0xf017be24,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 20 be 17 f0    	mov    %edx,0xf017be20
f01004e9:	0f b6 88 20 bc 17 f0 	movzbl -0xfe843e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 20 be 17 f0 00 	movl   $0x0,0xf017be20
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 30 be 17 f0 b4 	movl   $0x3b4,0xf017be30
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 30 be 17 f0 d4 	movl   $0x3d4,0xf017be30
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 30 be 17 f0    	mov    0xf017be30,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 2c be 17 f0    	mov    %esi,0xf017be2c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 34 be 17 f0 	setne  0xf017be34
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 99 45 10 f0       	push   $0xf0104599
f0100605:	e8 ac 28 00 00       	call   f0102eb6 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 e0 47 10 f0       	push   $0xf01047e0
f010064b:	68 fe 47 10 f0       	push   $0xf01047fe
f0100650:	68 03 48 10 f0       	push   $0xf0104803
f0100655:	e8 5c 28 00 00       	call   f0102eb6 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 ac 48 10 f0       	push   $0xf01048ac
f0100662:	68 0c 48 10 f0       	push   $0xf010480c
f0100667:	68 03 48 10 f0       	push   $0xf0104803
f010066c:	e8 45 28 00 00       	call   f0102eb6 <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 15 48 10 f0       	push   $0xf0104815
f0100679:	68 26 48 10 f0       	push   $0xf0104826
f010067e:	68 03 48 10 f0       	push   $0xf0104803
f0100683:	e8 2e 28 00 00       	call   f0102eb6 <cprintf>
	return 0;
}
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100695:	68 30 48 10 f0       	push   $0xf0104830
f010069a:	e8 17 28 00 00       	call   f0102eb6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 d4 48 10 f0       	push   $0xf01048d4
f01006ac:	e8 05 28 00 00       	call   f0102eb6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 fc 48 10 f0       	push   $0xf01048fc
f01006c3:	e8 ee 27 00 00       	call   f0102eb6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 31 45 10 00       	push   $0x104531
f01006d0:	68 31 45 10 f0       	push   $0xf0104531
f01006d5:	68 20 49 10 f0       	push   $0xf0104920
f01006da:	e8 d7 27 00 00       	call   f0102eb6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 ee bb 17 00       	push   $0x17bbee
f01006e7:	68 ee bb 17 f0       	push   $0xf017bbee
f01006ec:	68 44 49 10 f0       	push   $0xf0104944
f01006f1:	e8 c0 27 00 00       	call   f0102eb6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 10 cb 17 00       	push   $0x17cb10
f01006fe:	68 10 cb 17 f0       	push   $0xf017cb10
f0100703:	68 68 49 10 f0       	push   $0xf0104968
f0100708:	e8 a9 27 00 00       	call   f0102eb6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 0f cf 17 f0       	mov    $0xf017cf0f,%eax
f0100712:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100717:	83 c4 08             	add    $0x8,%esp
f010071a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010071f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100725:	85 c0                	test   %eax,%eax
f0100727:	0f 48 c2             	cmovs  %edx,%eax
f010072a:	c1 f8 0a             	sar    $0xa,%eax
f010072d:	50                   	push   %eax
f010072e:	68 8c 49 10 f0       	push   $0xf010498c
f0100733:	e8 7e 27 00 00       	call   f0102eb6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	56                   	push   %esi
f0100743:	53                   	push   %ebx
f0100744:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100747:	89 eb                	mov    %ebp,%ebx
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f0100749:	68 49 48 10 f0       	push   $0xf0104849
f010074e:	e8 63 27 00 00       	call   f0102eb6 <cprintf>
	while(p)
f0100753:	83 c4 10             	add    $0x10,%esp
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
		debuginfo_eip(*(p+1), &info);
f0100756:	8d 75 e0             	lea    -0x20(%ebp),%esi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f0100759:	eb 4e                	jmp    f01007a9 <mon_backtrace+0x6a>
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
f010075b:	ff 73 18             	pushl  0x18(%ebx)
f010075e:	ff 73 14             	pushl  0x14(%ebx)
f0100761:	ff 73 10             	pushl  0x10(%ebx)
f0100764:	ff 73 0c             	pushl  0xc(%ebx)
f0100767:	ff 73 08             	pushl  0x8(%ebx)
f010076a:	ff 73 04             	pushl  0x4(%ebx)
f010076d:	53                   	push   %ebx
f010076e:	68 b8 49 10 f0       	push   $0xf01049b8
f0100773:	e8 3e 27 00 00       	call   f0102eb6 <cprintf>
		debuginfo_eip(*(p+1), &info);
f0100778:	83 c4 18             	add    $0x18,%esp
f010077b:	56                   	push   %esi
f010077c:	ff 73 04             	pushl  0x4(%ebx)
f010077f:	e8 c5 2e 00 00       	call   f0103649 <debuginfo_eip>
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
f0100784:	83 c4 08             	add    $0x8,%esp
f0100787:	8b 43 04             	mov    0x4(%ebx),%eax
f010078a:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010078d:	50                   	push   %eax
f010078e:	ff 75 e8             	pushl  -0x18(%ebp)
f0100791:	ff 75 ec             	pushl  -0x14(%ebp)
f0100794:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100797:	ff 75 e0             	pushl  -0x20(%ebp)
f010079a:	68 5b 48 10 f0       	push   $0xf010485b
f010079f:	e8 12 27 00 00       	call   f0102eb6 <cprintf>
		p=(uint32_t*)*p;
f01007a4:	8b 1b                	mov    (%ebx),%ebx
f01007a6:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f01007a9:	85 db                	test   %ebx,%ebx
f01007ab:	75 ae                	jne    f010075b <mon_backtrace+0x1c>
		debuginfo_eip(*(p+1), &info);
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
		p=(uint32_t*)*p;
	}
	return 0;
}
f01007ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007b5:	5b                   	pop    %ebx
f01007b6:	5e                   	pop    %esi
f01007b7:	5d                   	pop    %ebp
f01007b8:	c3                   	ret    

f01007b9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b9:	55                   	push   %ebp
f01007ba:	89 e5                	mov    %esp,%ebp
f01007bc:	57                   	push   %edi
f01007bd:	56                   	push   %esi
f01007be:	53                   	push   %ebx
f01007bf:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c2:	68 ec 49 10 f0       	push   $0xf01049ec
f01007c7:	e8 ea 26 00 00       	call   f0102eb6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cc:	c7 04 24 10 4a 10 f0 	movl   $0xf0104a10,(%esp)
f01007d3:	e8 de 26 00 00       	call   f0102eb6 <cprintf>

	if (tf != NULL)
f01007d8:	83 c4 10             	add    $0x10,%esp
f01007db:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007df:	74 0e                	je     f01007ef <monitor+0x36>
		print_trapframe(tf);
f01007e1:	83 ec 0c             	sub    $0xc,%esp
f01007e4:	ff 75 08             	pushl  0x8(%ebp)
f01007e7:	e8 61 2a 00 00       	call   f010324d <print_trapframe>
f01007ec:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007ef:	83 ec 0c             	sub    $0xc,%esp
f01007f2:	68 6d 48 10 f0       	push   $0xf010486d
f01007f7:	e8 4d 36 00 00       	call   f0103e49 <readline>
f01007fc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007fe:	83 c4 10             	add    $0x10,%esp
f0100801:	85 c0                	test   %eax,%eax
f0100803:	74 ea                	je     f01007ef <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100805:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010080c:	be 00 00 00 00       	mov    $0x0,%esi
f0100811:	eb 0a                	jmp    f010081d <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100813:	c6 03 00             	movb   $0x0,(%ebx)
f0100816:	89 f7                	mov    %esi,%edi
f0100818:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010081b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010081d:	0f b6 03             	movzbl (%ebx),%eax
f0100820:	84 c0                	test   %al,%al
f0100822:	74 63                	je     f0100887 <monitor+0xce>
f0100824:	83 ec 08             	sub    $0x8,%esp
f0100827:	0f be c0             	movsbl %al,%eax
f010082a:	50                   	push   %eax
f010082b:	68 71 48 10 f0       	push   $0xf0104871
f0100830:	e8 2e 38 00 00       	call   f0104063 <strchr>
f0100835:	83 c4 10             	add    $0x10,%esp
f0100838:	85 c0                	test   %eax,%eax
f010083a:	75 d7                	jne    f0100813 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010083c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010083f:	74 46                	je     f0100887 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100841:	83 fe 0f             	cmp    $0xf,%esi
f0100844:	75 14                	jne    f010085a <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100846:	83 ec 08             	sub    $0x8,%esp
f0100849:	6a 10                	push   $0x10
f010084b:	68 76 48 10 f0       	push   $0xf0104876
f0100850:	e8 61 26 00 00       	call   f0102eb6 <cprintf>
f0100855:	83 c4 10             	add    $0x10,%esp
f0100858:	eb 95                	jmp    f01007ef <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010085a:	8d 7e 01             	lea    0x1(%esi),%edi
f010085d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100861:	eb 03                	jmp    f0100866 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100863:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100866:	0f b6 03             	movzbl (%ebx),%eax
f0100869:	84 c0                	test   %al,%al
f010086b:	74 ae                	je     f010081b <monitor+0x62>
f010086d:	83 ec 08             	sub    $0x8,%esp
f0100870:	0f be c0             	movsbl %al,%eax
f0100873:	50                   	push   %eax
f0100874:	68 71 48 10 f0       	push   $0xf0104871
f0100879:	e8 e5 37 00 00       	call   f0104063 <strchr>
f010087e:	83 c4 10             	add    $0x10,%esp
f0100881:	85 c0                	test   %eax,%eax
f0100883:	74 de                	je     f0100863 <monitor+0xaa>
f0100885:	eb 94                	jmp    f010081b <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100887:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010088e:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010088f:	85 f6                	test   %esi,%esi
f0100891:	0f 84 58 ff ff ff    	je     f01007ef <monitor+0x36>
f0100897:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010089c:	83 ec 08             	sub    $0x8,%esp
f010089f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008a2:	ff 34 85 40 4a 10 f0 	pushl  -0xfefb5c0(,%eax,4)
f01008a9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ac:	e8 54 37 00 00       	call   f0104005 <strcmp>
f01008b1:	83 c4 10             	add    $0x10,%esp
f01008b4:	85 c0                	test   %eax,%eax
f01008b6:	75 21                	jne    f01008d9 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008b8:	83 ec 04             	sub    $0x4,%esp
f01008bb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008be:	ff 75 08             	pushl  0x8(%ebp)
f01008c1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008c4:	52                   	push   %edx
f01008c5:	56                   	push   %esi
f01008c6:	ff 14 85 48 4a 10 f0 	call   *-0xfefb5b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008cd:	83 c4 10             	add    $0x10,%esp
f01008d0:	85 c0                	test   %eax,%eax
f01008d2:	78 25                	js     f01008f9 <monitor+0x140>
f01008d4:	e9 16 ff ff ff       	jmp    f01007ef <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008d9:	83 c3 01             	add    $0x1,%ebx
f01008dc:	83 fb 03             	cmp    $0x3,%ebx
f01008df:	75 bb                	jne    f010089c <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e1:	83 ec 08             	sub    $0x8,%esp
f01008e4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e7:	68 93 48 10 f0       	push   $0xf0104893
f01008ec:	e8 c5 25 00 00       	call   f0102eb6 <cprintf>
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	e9 f6 fe ff ff       	jmp    f01007ef <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008fc:	5b                   	pop    %ebx
f01008fd:	5e                   	pop    %esi
f01008fe:	5f                   	pop    %edi
f01008ff:	5d                   	pop    %ebp
f0100900:	c3                   	ret    

f0100901 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100901:	55                   	push   %ebp
f0100902:	89 e5                	mov    %esp,%ebp
f0100904:	53                   	push   %ebx
f0100905:	83 ec 04             	sub    $0x4,%esp
f0100908:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010090a:	83 3d 38 be 17 f0 00 	cmpl   $0x0,0xf017be38
f0100911:	75 0f                	jne    f0100922 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100913:	b8 0f db 17 f0       	mov    $0xf017db0f,%eax
f0100918:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010091d:	a3 38 be 17 f0       	mov    %eax,0xf017be38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	cprintf("boot_alloc memory at %x\n", nextfree);
f0100922:	83 ec 08             	sub    $0x8,%esp
f0100925:	ff 35 38 be 17 f0    	pushl  0xf017be38
f010092b:	68 64 4a 10 f0       	push   $0xf0104a64
f0100930:	e8 81 25 00 00       	call   f0102eb6 <cprintf>
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f0100935:	89 d8                	mov    %ebx,%eax
f0100937:	03 05 38 be 17 f0    	add    0xf017be38,%eax
f010093d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100942:	83 c4 08             	add    $0x8,%esp
f0100945:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010094a:	50                   	push   %eax
f010094b:	68 7d 4a 10 f0       	push   $0xf0104a7d
f0100950:	e8 61 25 00 00       	call   f0102eb6 <cprintf>
	if (n != 0) {
f0100955:	83 c4 10             	add    $0x10,%esp
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;
f0100958:	a1 38 be 17 f0       	mov    0xf017be38,%eax
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	cprintf("boot_alloc memory at %x\n", nextfree);
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
	if (n != 0) {
f010095d:	85 db                	test   %ebx,%ebx
f010095f:	74 13                	je     f0100974 <boot_alloc+0x73>
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100961:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f0100968:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010096e:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
		return next;
	} else return nextfree;

	return NULL;
}
f0100974:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100977:	c9                   	leave  
f0100978:	c3                   	ret    

f0100979 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100979:	89 d1                	mov    %edx,%ecx
f010097b:	c1 e9 16             	shr    $0x16,%ecx
f010097e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100981:	a8 01                	test   $0x1,%al
f0100983:	74 52                	je     f01009d7 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100985:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010098a:	89 c1                	mov    %eax,%ecx
f010098c:	c1 e9 0c             	shr    $0xc,%ecx
f010098f:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0100995:	72 1b                	jb     f01009b2 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100997:	55                   	push   %ebp
f0100998:	89 e5                	mov    %esp,%ebp
f010099a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010099d:	50                   	push   %eax
f010099e:	68 04 4e 10 f0       	push   $0xf0104e04
f01009a3:	68 1a 03 00 00       	push   $0x31a
f01009a8:	68 90 4a 10 f0       	push   $0xf0104a90
f01009ad:	e8 ee f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009b2:	c1 ea 0c             	shr    $0xc,%edx
f01009b5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009bb:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009c2:	89 c2                	mov    %eax,%edx
f01009c4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009cc:	85 d2                	test   %edx,%edx
f01009ce:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009d3:	0f 44 c2             	cmove  %edx,%eax
f01009d6:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009dc:	c3                   	ret    

f01009dd <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009dd:	55                   	push   %ebp
f01009de:	89 e5                	mov    %esp,%ebp
f01009e0:	57                   	push   %edi
f01009e1:	56                   	push   %esi
f01009e2:	53                   	push   %ebx
f01009e3:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009e6:	84 c0                	test   %al,%al
f01009e8:	0f 85 81 02 00 00    	jne    f0100c6f <check_page_free_list+0x292>
f01009ee:	e9 8e 02 00 00       	jmp    f0100c81 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009f3:	83 ec 04             	sub    $0x4,%esp
f01009f6:	68 28 4e 10 f0       	push   $0xf0104e28
f01009fb:	68 54 02 00 00       	push   $0x254
f0100a00:	68 90 4a 10 f0       	push   $0xf0104a90
f0100a05:	e8 96 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a0a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a0d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a10:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a13:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a16:	89 c2                	mov    %eax,%edx
f0100a18:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0100a1e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a24:	0f 95 c2             	setne  %dl
f0100a27:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a2a:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a2e:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a30:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a34:	8b 00                	mov    (%eax),%eax
f0100a36:	85 c0                	test   %eax,%eax
f0100a38:	75 dc                	jne    f0100a16 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a3d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a43:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a46:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a49:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a4b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a4e:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a53:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a58:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100a5e:	eb 53                	jmp    f0100ab3 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a60:	89 d8                	mov    %ebx,%eax
f0100a62:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100a68:	c1 f8 03             	sar    $0x3,%eax
f0100a6b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a6e:	89 c2                	mov    %eax,%edx
f0100a70:	c1 ea 16             	shr    $0x16,%edx
f0100a73:	39 f2                	cmp    %esi,%edx
f0100a75:	73 3a                	jae    f0100ab1 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a77:	89 c2                	mov    %eax,%edx
f0100a79:	c1 ea 0c             	shr    $0xc,%edx
f0100a7c:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100a82:	72 12                	jb     f0100a96 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a84:	50                   	push   %eax
f0100a85:	68 04 4e 10 f0       	push   $0xf0104e04
f0100a8a:	6a 56                	push   $0x56
f0100a8c:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0100a91:	e8 0a f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a96:	83 ec 04             	sub    $0x4,%esp
f0100a99:	68 80 00 00 00       	push   $0x80
f0100a9e:	68 97 00 00 00       	push   $0x97
f0100aa3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aa8:	50                   	push   %eax
f0100aa9:	e8 f2 35 00 00       	call   f01040a0 <memset>
f0100aae:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ab1:	8b 1b                	mov    (%ebx),%ebx
f0100ab3:	85 db                	test   %ebx,%ebx
f0100ab5:	75 a9                	jne    f0100a60 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ab7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100abc:	e8 40 fe ff ff       	call   f0100901 <boot_alloc>
f0100ac1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ac4:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aca:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
		assert(pp < pages + npages);
f0100ad0:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0100ad5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ad8:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100adb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ade:	be 00 00 00 00       	mov    $0x0,%esi
f0100ae3:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ae6:	e9 30 01 00 00       	jmp    f0100c1b <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aeb:	39 ca                	cmp    %ecx,%edx
f0100aed:	73 19                	jae    f0100b08 <check_page_free_list+0x12b>
f0100aef:	68 aa 4a 10 f0       	push   $0xf0104aaa
f0100af4:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100af9:	68 6e 02 00 00       	push   $0x26e
f0100afe:	68 90 4a 10 f0       	push   $0xf0104a90
f0100b03:	e8 98 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b08:	39 fa                	cmp    %edi,%edx
f0100b0a:	72 19                	jb     f0100b25 <check_page_free_list+0x148>
f0100b0c:	68 cb 4a 10 f0       	push   $0xf0104acb
f0100b11:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100b16:	68 6f 02 00 00       	push   $0x26f
f0100b1b:	68 90 4a 10 f0       	push   $0xf0104a90
f0100b20:	e8 7b f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b25:	89 d0                	mov    %edx,%eax
f0100b27:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b2a:	a8 07                	test   $0x7,%al
f0100b2c:	74 19                	je     f0100b47 <check_page_free_list+0x16a>
f0100b2e:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0100b33:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100b38:	68 70 02 00 00       	push   $0x270
f0100b3d:	68 90 4a 10 f0       	push   $0xf0104a90
f0100b42:	e8 59 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b47:	c1 f8 03             	sar    $0x3,%eax
f0100b4a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b4d:	85 c0                	test   %eax,%eax
f0100b4f:	75 19                	jne    f0100b6a <check_page_free_list+0x18d>
f0100b51:	68 df 4a 10 f0       	push   $0xf0104adf
f0100b56:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100b5b:	68 73 02 00 00       	push   $0x273
f0100b60:	68 90 4a 10 f0       	push   $0xf0104a90
f0100b65:	e8 36 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b6a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b6f:	75 19                	jne    f0100b8a <check_page_free_list+0x1ad>
f0100b71:	68 f0 4a 10 f0       	push   $0xf0104af0
f0100b76:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100b7b:	68 74 02 00 00       	push   $0x274
f0100b80:	68 90 4a 10 f0       	push   $0xf0104a90
f0100b85:	e8 16 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b8a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b8f:	75 19                	jne    f0100baa <check_page_free_list+0x1cd>
f0100b91:	68 80 4e 10 f0       	push   $0xf0104e80
f0100b96:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100b9b:	68 75 02 00 00       	push   $0x275
f0100ba0:	68 90 4a 10 f0       	push   $0xf0104a90
f0100ba5:	e8 f6 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100baa:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100baf:	75 19                	jne    f0100bca <check_page_free_list+0x1ed>
f0100bb1:	68 09 4b 10 f0       	push   $0xf0104b09
f0100bb6:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100bbb:	68 76 02 00 00       	push   $0x276
f0100bc0:	68 90 4a 10 f0       	push   $0xf0104a90
f0100bc5:	e8 d6 f4 ff ff       	call   f01000a0 <_panic>
		// cprintf("pp: %x, page2pa(pp): %x, page2kva(pp): %x, first_free_page: %x\n",
		// 	pp, page2pa(pp), page2kva(pp), first_free_page);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bca:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bcf:	76 3f                	jbe    f0100c10 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd1:	89 c3                	mov    %eax,%ebx
f0100bd3:	c1 eb 0c             	shr    $0xc,%ebx
f0100bd6:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bd9:	77 12                	ja     f0100bed <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bdb:	50                   	push   %eax
f0100bdc:	68 04 4e 10 f0       	push   $0xf0104e04
f0100be1:	6a 56                	push   $0x56
f0100be3:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0100be8:	e8 b3 f4 ff ff       	call   f01000a0 <_panic>
f0100bed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bf2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bf5:	76 1e                	jbe    f0100c15 <check_page_free_list+0x238>
f0100bf7:	68 a4 4e 10 f0       	push   $0xf0104ea4
f0100bfc:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100c01:	68 79 02 00 00       	push   $0x279
f0100c06:	68 90 4a 10 f0       	push   $0xf0104a90
f0100c0b:	e8 90 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c10:	83 c6 01             	add    $0x1,%esi
f0100c13:	eb 04                	jmp    f0100c19 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c15:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c19:	8b 12                	mov    (%edx),%edx
f0100c1b:	85 d2                	test   %edx,%edx
f0100c1d:	0f 85 c8 fe ff ff    	jne    f0100aeb <check_page_free_list+0x10e>
f0100c23:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c26:	85 f6                	test   %esi,%esi
f0100c28:	7f 19                	jg     f0100c43 <check_page_free_list+0x266>
f0100c2a:	68 23 4b 10 f0       	push   $0xf0104b23
f0100c2f:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100c34:	68 81 02 00 00       	push   $0x281
f0100c39:	68 90 4a 10 f0       	push   $0xf0104a90
f0100c3e:	e8 5d f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c43:	85 db                	test   %ebx,%ebx
f0100c45:	7f 19                	jg     f0100c60 <check_page_free_list+0x283>
f0100c47:	68 35 4b 10 f0       	push   $0xf0104b35
f0100c4c:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0100c51:	68 82 02 00 00       	push   $0x282
f0100c56:	68 90 4a 10 f0       	push   $0xf0104a90
f0100c5b:	e8 40 f4 ff ff       	call   f01000a0 <_panic>
	cprintf("check_page_free_list done\n");
f0100c60:	83 ec 0c             	sub    $0xc,%esp
f0100c63:	68 46 4b 10 f0       	push   $0xf0104b46
f0100c68:	e8 49 22 00 00       	call   f0102eb6 <cprintf>
}
f0100c6d:	eb 29                	jmp    f0100c98 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c6f:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0100c74:	85 c0                	test   %eax,%eax
f0100c76:	0f 85 8e fd ff ff    	jne    f0100a0a <check_page_free_list+0x2d>
f0100c7c:	e9 72 fd ff ff       	jmp    f01009f3 <check_page_free_list+0x16>
f0100c81:	83 3d 3c be 17 f0 00 	cmpl   $0x0,0xf017be3c
f0100c88:	0f 84 65 fd ff ff    	je     f01009f3 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c8e:	be 00 04 00 00       	mov    $0x400,%esi
f0100c93:	e9 c0 fd ff ff       	jmp    f0100a58 <check_page_free_list+0x7b>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list done\n");
}
f0100c98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c9b:	5b                   	pop    %ebx
f0100c9c:	5e                   	pop    %esi
f0100c9d:	5f                   	pop    %edi
f0100c9e:	5d                   	pop    %ebp
f0100c9f:	c3                   	ret    

f0100ca0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ca0:	55                   	push   %ebp
f0100ca1:	89 e5                	mov    %esp,%ebp
f0100ca3:	56                   	push   %esi
f0100ca4:	53                   	push   %ebx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100ca5:	8b 35 40 be 17 f0    	mov    0xf017be40,%esi
f0100cab:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100cb1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cbb:	eb 27                	jmp    f0100ce4 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100cbd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cc4:	89 d1                	mov    %edx,%ecx
f0100cc6:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100ccc:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cd2:	89 19                	mov    %ebx,(%ecx)
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100cd4:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100cd7:	89 d3                	mov    %edx,%ebx
f0100cd9:	03 1d 0c cb 17 f0    	add    0xf017cb0c,%ebx
f0100cdf:	ba 01 00 00 00       	mov    $0x1,%edx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100ce4:	39 f0                	cmp    %esi,%eax
f0100ce6:	72 d5                	jb     f0100cbd <page_init+0x1d>
f0100ce8:	84 d2                	test   %dl,%dl
f0100cea:	74 06                	je     f0100cf2 <page_init+0x52>
f0100cec:	89 1d 3c be 17 f0    	mov    %ebx,0xf017be3c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - 0xf0000000, PGSIZE)/PGSIZE;
f0100cf2:	8b 15 48 be 17 f0    	mov    0xf017be48,%edx
f0100cf8:	8d 82 ff 8f 01 10    	lea    0x10018fff(%edx),%eax
f0100cfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d03:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0100d09:	85 c0                	test   %eax,%eax
f0100d0b:	0f 48 c3             	cmovs  %ebx,%eax
f0100d0e:	c1 f8 0c             	sar    $0xc,%eax
f0100d11:	89 c3                	mov    %eax,%ebx
	cprintf("%x\n", ((char*)envs) + (sizeof(struct Env) * NENV));
f0100d13:	83 ec 08             	sub    $0x8,%esp
f0100d16:	81 c2 00 80 01 00    	add    $0x18000,%edx
f0100d1c:	52                   	push   %edx
f0100d1d:	68 ce 4d 10 f0       	push   $0xf0104dce
f0100d22:	e8 8f 21 00 00       	call   f0102eb6 <cprintf>
	cprintf("med=%d\n", med);
f0100d27:	83 c4 08             	add    $0x8,%esp
f0100d2a:	53                   	push   %ebx
f0100d2b:	68 61 4b 10 f0       	push   $0xf0104b61
f0100d30:	e8 81 21 00 00       	call   f0102eb6 <cprintf>
	for (i = med; i < npages; i++) {
f0100d35:	89 da                	mov    %ebx,%edx
f0100d37:	8b 35 3c be 17 f0    	mov    0xf017be3c,%esi
f0100d3d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100d44:	83 c4 10             	add    $0x10,%esp
f0100d47:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d4c:	eb 23                	jmp    f0100d71 <page_init+0xd1>
		pages[i].pp_ref = 0;
f0100d4e:	89 c1                	mov    %eax,%ecx
f0100d50:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100d56:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d5c:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0100d5e:	89 c6                	mov    %eax,%esi
f0100d60:	03 35 0c cb 17 f0    	add    0xf017cb0c,%esi
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - 0xf0000000, PGSIZE)/PGSIZE;
	cprintf("%x\n", ((char*)envs) + (sizeof(struct Env) * NENV));
	cprintf("med=%d\n", med);
	for (i = med; i < npages; i++) {
f0100d66:	83 c2 01             	add    $0x1,%edx
f0100d69:	83 c0 08             	add    $0x8,%eax
f0100d6c:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d71:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100d77:	72 d5                	jb     f0100d4e <page_init+0xae>
f0100d79:	84 c9                	test   %cl,%cl
f0100d7b:	74 06                	je     f0100d83 <page_init+0xe3>
f0100d7d:	89 35 3c be 17 f0    	mov    %esi,0xf017be3c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100d83:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d86:	5b                   	pop    %ebx
f0100d87:	5e                   	pop    %esi
f0100d88:	5d                   	pop    %ebp
f0100d89:	c3                   	ret    

f0100d8a <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d8a:	55                   	push   %ebp
f0100d8b:	89 e5                	mov    %esp,%ebp
f0100d8d:	53                   	push   %ebx
f0100d8e:	83 ec 04             	sub    $0x4,%esp
	if (page_free_list) {
f0100d91:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100d97:	85 db                	test   %ebx,%ebx
f0100d99:	74 52                	je     f0100ded <page_alloc+0x63>
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d9b:	8b 03                	mov    (%ebx),%eax
f0100d9d:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
		if (alloc_flags & ALLOC_ZERO) 
f0100da2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100da6:	74 45                	je     f0100ded <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da8:	89 d8                	mov    %ebx,%eax
f0100daa:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100db0:	c1 f8 03             	sar    $0x3,%eax
f0100db3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db6:	89 c2                	mov    %eax,%edx
f0100db8:	c1 ea 0c             	shr    $0xc,%edx
f0100dbb:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100dc1:	72 12                	jb     f0100dd5 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc3:	50                   	push   %eax
f0100dc4:	68 04 4e 10 f0       	push   $0xf0104e04
f0100dc9:	6a 56                	push   $0x56
f0100dcb:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0100dd0:	e8 cb f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100dd5:	83 ec 04             	sub    $0x4,%esp
f0100dd8:	68 00 10 00 00       	push   $0x1000
f0100ddd:	6a 00                	push   $0x0
f0100ddf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100de4:	50                   	push   %eax
f0100de5:	e8 b6 32 00 00       	call   f01040a0 <memset>
f0100dea:	83 c4 10             	add    $0x10,%esp
		return ret;
	}
	return NULL;
}
f0100ded:	89 d8                	mov    %ebx,%eax
f0100def:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100df2:	c9                   	leave  
f0100df3:	c3                   	ret    

f0100df4 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100df4:	55                   	push   %ebp
f0100df5:	89 e5                	mov    %esp,%ebp
f0100df7:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_link = page_free_list;
f0100dfa:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
f0100e00:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e02:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
}
f0100e07:	5d                   	pop    %ebp
f0100e08:	c3                   	ret    

f0100e09 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e09:	55                   	push   %ebp
f0100e0a:	89 e5                	mov    %esp,%ebp
f0100e0c:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e0f:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e13:	83 e8 01             	sub    $0x1,%eax
f0100e16:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e1a:	66 85 c0             	test   %ax,%ax
f0100e1d:	75 09                	jne    f0100e28 <page_decref+0x1f>
		page_free(pp);
f0100e1f:	52                   	push   %edx
f0100e20:	e8 cf ff ff ff       	call   f0100df4 <page_free>
f0100e25:	83 c4 04             	add    $0x4,%esp
}
f0100e28:	c9                   	leave  
f0100e29:	c3                   	ret    

f0100e2a <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e2a:	55                   	push   %ebp
f0100e2b:	89 e5                	mov    %esp,%ebp
f0100e2d:	56                   	push   %esi
f0100e2e:	53                   	push   %ebx
f0100e2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int dindex = PDX(va), tindex = PTX(va);
f0100e32:	89 de                	mov    %ebx,%esi
f0100e34:	c1 ee 0c             	shr    $0xc,%esi
f0100e37:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	//dir index, table index
	if (!(pgdir[dindex] & PTE_P)) {	//if pde not exist
f0100e3d:	c1 eb 16             	shr    $0x16,%ebx
f0100e40:	c1 e3 02             	shl    $0x2,%ebx
f0100e43:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e46:	f6 03 01             	testb  $0x1,(%ebx)
f0100e49:	75 2d                	jne    f0100e78 <pgdir_walk+0x4e>
		if (create) {
f0100e4b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e4f:	74 59                	je     f0100eaa <pgdir_walk+0x80>
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
f0100e51:	83 ec 0c             	sub    $0xc,%esp
f0100e54:	6a 01                	push   $0x1
f0100e56:	e8 2f ff ff ff       	call   f0100d8a <page_alloc>
			if (!pg) return NULL;	//allocation fails
f0100e5b:	83 c4 10             	add    $0x10,%esp
f0100e5e:	85 c0                	test   %eax,%eax
f0100e60:	74 4f                	je     f0100eb1 <pgdir_walk+0x87>
			pg->pp_ref++;
f0100e62:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			pgdir[dindex] = page2pa(pg) | PTE_P | PTE_U | PTE_W;
f0100e67:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100e6d:	c1 f8 03             	sar    $0x3,%eax
f0100e70:	c1 e0 0c             	shl    $0xc,%eax
f0100e73:	83 c8 07             	or     $0x7,%eax
f0100e76:	89 03                	mov    %eax,(%ebx)
		} else return NULL;
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
f0100e78:	8b 03                	mov    (%ebx),%eax
f0100e7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e7f:	89 c2                	mov    %eax,%edx
f0100e81:	c1 ea 0c             	shr    $0xc,%edx
f0100e84:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100e8a:	72 15                	jb     f0100ea1 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e8c:	50                   	push   %eax
f0100e8d:	68 04 4e 10 f0       	push   $0xf0104e04
f0100e92:	68 8b 01 00 00       	push   $0x18b
f0100e97:	68 90 4a 10 f0       	push   $0xf0104a90
f0100e9c:	e8 ff f1 ff ff       	call   f01000a0 <_panic>
	// 		struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
	// 		pg->pp_ref++;
	// 		p[tindex] = page2pa(pg) | PTE_P;
	// 	} else return NULL;

	return p+tindex;
f0100ea1:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100ea8:	eb 0c                	jmp    f0100eb6 <pgdir_walk+0x8c>
		if (create) {
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
			if (!pg) return NULL;	//allocation fails
			pg->pp_ref++;
			pgdir[dindex] = page2pa(pg) | PTE_P | PTE_U | PTE_W;
		} else return NULL;
f0100eaa:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eaf:	eb 05                	jmp    f0100eb6 <pgdir_walk+0x8c>
	int dindex = PDX(va), tindex = PTX(va);
	//dir index, table index
	if (!(pgdir[dindex] & PTE_P)) {	//if pde not exist
		if (create) {
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
			if (!pg) return NULL;	//allocation fails
f0100eb1:	b8 00 00 00 00       	mov    $0x0,%eax
	// 		pg->pp_ref++;
	// 		p[tindex] = page2pa(pg) | PTE_P;
	// 	} else return NULL;

	return p+tindex;
}
f0100eb6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100eb9:	5b                   	pop    %ebx
f0100eba:	5e                   	pop    %esi
f0100ebb:	5d                   	pop    %ebp
f0100ebc:	c3                   	ret    

f0100ebd <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ebd:	55                   	push   %ebp
f0100ebe:	89 e5                	mov    %esp,%ebp
f0100ec0:	57                   	push   %edi
f0100ec1:	56                   	push   %esi
f0100ec2:	53                   	push   %ebx
f0100ec3:	83 ec 20             	sub    $0x20,%esp
f0100ec6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ec9:	89 d7                	mov    %edx,%edi
f0100ecb:	89 cb                	mov    %ecx,%ebx
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f0100ecd:	ff 75 08             	pushl  0x8(%ebp)
f0100ed0:	52                   	push   %edx
f0100ed1:	68 ec 4e 10 f0       	push   $0xf0104eec
f0100ed6:	e8 db 1f 00 00       	call   f0102eb6 <cprintf>
f0100edb:	c1 eb 0c             	shr    $0xc,%ebx
f0100ede:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100ee1:	83 c4 10             	add    $0x10,%esp
f0100ee4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100ee7:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
f0100eec:	29 df                	sub    %ebx,%edi
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
f0100eee:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ef1:	83 c8 01             	or     $0x1,%eax
f0100ef4:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100ef7:	eb 3f                	jmp    f0100f38 <boot_map_region+0x7b>
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
f0100ef9:	83 ec 04             	sub    $0x4,%esp
f0100efc:	6a 01                	push   $0x1
f0100efe:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f01:	50                   	push   %eax
f0100f02:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f05:	e8 20 ff ff ff       	call   f0100e2a <pgdir_walk>
		if (!pte) panic("boot_map_region panic, out of memory");
f0100f0a:	83 c4 10             	add    $0x10,%esp
f0100f0d:	85 c0                	test   %eax,%eax
f0100f0f:	75 17                	jne    f0100f28 <boot_map_region+0x6b>
f0100f11:	83 ec 04             	sub    $0x4,%esp
f0100f14:	68 20 4f 10 f0       	push   $0xf0104f20
f0100f19:	68 a9 01 00 00       	push   $0x1a9
f0100f1e:	68 90 4a 10 f0       	push   $0xf0104a90
f0100f23:	e8 78 f1 ff ff       	call   f01000a0 <_panic>
		*pte = pa | perm | PTE_P;
f0100f28:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f2b:	09 da                	or     %ebx,%edx
f0100f2d:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100f2f:	83 c6 01             	add    $0x1,%esi
f0100f32:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f38:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f3b:	75 bc                	jne    f0100ef9 <boot_map_region+0x3c>
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
	}
}
f0100f3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f40:	5b                   	pop    %ebx
f0100f41:	5e                   	pop    %esi
f0100f42:	5f                   	pop    %edi
f0100f43:	5d                   	pop    %ebp
f0100f44:	c3                   	ret    

f0100f45 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f45:	55                   	push   %ebp
f0100f46:	89 e5                	mov    %esp,%ebp
f0100f48:	53                   	push   %ebx
f0100f49:	83 ec 08             	sub    $0x8,%esp
f0100f4c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//not create
f0100f4f:	6a 00                	push   $0x0
f0100f51:	ff 75 0c             	pushl  0xc(%ebp)
f0100f54:	ff 75 08             	pushl  0x8(%ebp)
f0100f57:	e8 ce fe ff ff       	call   f0100e2a <pgdir_walk>
	if (!pte || !(*pte & PTE_P)) return NULL;	//page not found
f0100f5c:	83 c4 10             	add    $0x10,%esp
f0100f5f:	85 c0                	test   %eax,%eax
f0100f61:	74 37                	je     f0100f9a <page_lookup+0x55>
f0100f63:	f6 00 01             	testb  $0x1,(%eax)
f0100f66:	74 39                	je     f0100fa1 <page_lookup+0x5c>
	if (pte_store)
f0100f68:	85 db                	test   %ebx,%ebx
f0100f6a:	74 02                	je     f0100f6e <page_lookup+0x29>
		*pte_store = pte;	//found and set
f0100f6c:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f6e:	8b 00                	mov    (%eax),%eax
f0100f70:	c1 e8 0c             	shr    $0xc,%eax
f0100f73:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0100f79:	72 14                	jb     f0100f8f <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100f7b:	83 ec 04             	sub    $0x4,%esp
f0100f7e:	68 48 4f 10 f0       	push   $0xf0104f48
f0100f83:	6a 4f                	push   $0x4f
f0100f85:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0100f8a:	e8 11 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f8f:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0100f95:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));		
f0100f98:	eb 0c                	jmp    f0100fa6 <page_lookup+0x61>
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//not create
	if (!pte || !(*pte & PTE_P)) return NULL;	//page not found
f0100f9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f9f:	eb 05                	jmp    f0100fa6 <page_lookup+0x61>
f0100fa1:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store)
		*pte_store = pte;	//found and set
	return pa2page(PTE_ADDR(*pte));		
}
f0100fa6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fa9:	c9                   	leave  
f0100faa:	c3                   	ret    

f0100fab <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fab:	55                   	push   %ebp
f0100fac:	89 e5                	mov    %esp,%ebp
f0100fae:	53                   	push   %ebx
f0100faf:	83 ec 18             	sub    $0x18,%esp
f0100fb2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *pg = page_lookup(pgdir, va, &pte);
f0100fb5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fb8:	50                   	push   %eax
f0100fb9:	53                   	push   %ebx
f0100fba:	ff 75 08             	pushl  0x8(%ebp)
f0100fbd:	e8 83 ff ff ff       	call   f0100f45 <page_lookup>
	if (!pg || !(*pte & PTE_P)) return;	//page not exist
f0100fc2:	83 c4 10             	add    $0x10,%esp
f0100fc5:	85 c0                	test   %eax,%eax
f0100fc7:	74 20                	je     f0100fe9 <page_remove+0x3e>
f0100fc9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100fcc:	f6 02 01             	testb  $0x1,(%edx)
f0100fcf:	74 18                	je     f0100fe9 <page_remove+0x3e>
//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
	page_decref(pg);
f0100fd1:	83 ec 0c             	sub    $0xc,%esp
f0100fd4:	50                   	push   %eax
f0100fd5:	e8 2f fe ff ff       	call   f0100e09 <page_decref>
//   - The pg table entry corresponding to 'va' should be set to 0.
	*pte = 0;
f0100fda:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fdd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fe3:	0f 01 3b             	invlpg (%ebx)
f0100fe6:	83 c4 10             	add    $0x10,%esp
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
	tlb_invalidate(pgdir, va);
}
f0100fe9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fec:	c9                   	leave  
f0100fed:	c3                   	ret    

f0100fee <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fee:	55                   	push   %ebp
f0100fef:	89 e5                	mov    %esp,%ebp
f0100ff1:	57                   	push   %edi
f0100ff2:	56                   	push   %esi
f0100ff3:	53                   	push   %ebx
f0100ff4:	83 ec 10             	sub    $0x10,%esp
f0100ff7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ffa:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1);	//create on demand
f0100ffd:	6a 01                	push   $0x1
f0100fff:	57                   	push   %edi
f0101000:	ff 75 08             	pushl  0x8(%ebp)
f0101003:	e8 22 fe ff ff       	call   f0100e2a <pgdir_walk>
	if (!pte) 	//page table not allocated
f0101008:	83 c4 10             	add    $0x10,%esp
f010100b:	85 c0                	test   %eax,%eax
f010100d:	74 38                	je     f0101047 <page_insert+0x59>
f010100f:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;	
	//increase ref count to avoid the corner case that pp is freed before it is inserted.
	pp->pp_ref++;	
f0101011:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte & PTE_P) 	//page colides, tle is invalidated in page_remove
f0101016:	f6 00 01             	testb  $0x1,(%eax)
f0101019:	74 0f                	je     f010102a <page_insert+0x3c>
		page_remove(pgdir, va);
f010101b:	83 ec 08             	sub    $0x8,%esp
f010101e:	57                   	push   %edi
f010101f:	ff 75 08             	pushl  0x8(%ebp)
f0101022:	e8 84 ff ff ff       	call   f0100fab <page_remove>
f0101027:	83 c4 10             	add    $0x10,%esp
	*pte = page2pa(pp) | perm | PTE_P;
f010102a:	2b 1d 0c cb 17 f0    	sub    0xf017cb0c,%ebx
f0101030:	c1 fb 03             	sar    $0x3,%ebx
f0101033:	c1 e3 0c             	shl    $0xc,%ebx
f0101036:	8b 45 14             	mov    0x14(%ebp),%eax
f0101039:	83 c8 01             	or     $0x1,%eax
f010103c:	09 c3                	or     %eax,%ebx
f010103e:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101040:	b8 00 00 00 00       	mov    $0x0,%eax
f0101045:	eb 05                	jmp    f010104c <page_insert+0x5e>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *pte = pgdir_walk(pgdir, va, 1);	//create on demand
	if (!pte) 	//page table not allocated
		return -E_NO_MEM;	
f0101047:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;	
	if (*pte & PTE_P) 	//page colides, tle is invalidated in page_remove
		page_remove(pgdir, va);
	*pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f010104c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010104f:	5b                   	pop    %ebx
f0101050:	5e                   	pop    %esi
f0101051:	5f                   	pop    %edi
f0101052:	5d                   	pop    %ebp
f0101053:	c3                   	ret    

f0101054 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101054:	55                   	push   %ebp
f0101055:	89 e5                	mov    %esp,%ebp
f0101057:	57                   	push   %edi
f0101058:	56                   	push   %esi
f0101059:	53                   	push   %ebx
f010105a:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010105d:	6a 15                	push   $0x15
f010105f:	e8 eb 1d 00 00       	call   f0102e4f <mc146818_read>
f0101064:	89 c3                	mov    %eax,%ebx
f0101066:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010106d:	e8 dd 1d 00 00       	call   f0102e4f <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101072:	c1 e0 08             	shl    $0x8,%eax
f0101075:	09 d8                	or     %ebx,%eax
f0101077:	c1 e0 0a             	shl    $0xa,%eax
f010107a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101080:	85 c0                	test   %eax,%eax
f0101082:	0f 48 c2             	cmovs  %edx,%eax
f0101085:	c1 f8 0c             	sar    $0xc,%eax
f0101088:	a3 40 be 17 f0       	mov    %eax,0xf017be40
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010108d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101094:	e8 b6 1d 00 00       	call   f0102e4f <mc146818_read>
f0101099:	89 c3                	mov    %eax,%ebx
f010109b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010a2:	e8 a8 1d 00 00       	call   f0102e4f <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010a7:	c1 e0 08             	shl    $0x8,%eax
f01010aa:	09 d8                	or     %ebx,%eax
f01010ac:	c1 e0 0a             	shl    $0xa,%eax
f01010af:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010b5:	83 c4 10             	add    $0x10,%esp
f01010b8:	85 c0                	test   %eax,%eax
f01010ba:	0f 48 c2             	cmovs  %edx,%eax
f01010bd:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010c0:	85 c0                	test   %eax,%eax
f01010c2:	74 0e                	je     f01010d2 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010c4:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010ca:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04
f01010d0:	eb 0c                	jmp    f01010de <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010d2:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f01010d8:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010de:	c1 e0 0c             	shl    $0xc,%eax
f01010e1:	c1 e8 0a             	shr    $0xa,%eax
f01010e4:	50                   	push   %eax
f01010e5:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f01010ea:	c1 e0 0c             	shl    $0xc,%eax
f01010ed:	c1 e8 0a             	shr    $0xa,%eax
f01010f0:	50                   	push   %eax
f01010f1:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f01010f6:	c1 e0 0c             	shl    $0xc,%eax
f01010f9:	c1 e8 0a             	shr    $0xa,%eax
f01010fc:	50                   	push   %eax
f01010fd:	68 68 4f 10 f0       	push   $0xf0104f68
f0101102:	e8 af 1d 00 00       	call   f0102eb6 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101107:	b8 00 10 00 00       	mov    $0x1000,%eax
f010110c:	e8 f0 f7 ff ff       	call   f0100901 <boot_alloc>
f0101111:	a3 08 cb 17 f0       	mov    %eax,0xf017cb08
	memset(kern_pgdir, 0, PGSIZE);
f0101116:	83 c4 0c             	add    $0xc,%esp
f0101119:	68 00 10 00 00       	push   $0x1000
f010111e:	6a 00                	push   $0x0
f0101120:	50                   	push   %eax
f0101121:	e8 7a 2f 00 00       	call   f01040a0 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101126:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010112b:	83 c4 10             	add    $0x10,%esp
f010112e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101133:	77 15                	ja     f010114a <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101135:	50                   	push   %eax
f0101136:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010113b:	68 93 00 00 00       	push   $0x93
f0101140:	68 90 4a 10 f0       	push   $0xf0104a90
f0101145:	e8 56 ef ff ff       	call   f01000a0 <_panic>
f010114a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101150:	83 ca 05             	or     $0x5,%edx
f0101153:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f0101159:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f010115e:	c1 e0 03             	shl    $0x3,%eax
f0101161:	e8 9b f7 ff ff       	call   f0100901 <boot_alloc>
f0101166:	a3 0c cb 17 f0       	mov    %eax,0xf017cb0c

	cprintf("npages: %d\n", npages);
f010116b:	83 ec 08             	sub    $0x8,%esp
f010116e:	ff 35 04 cb 17 f0    	pushl  0xf017cb04
f0101174:	68 69 4b 10 f0       	push   $0xf0104b69
f0101179:	e8 38 1d 00 00       	call   f0102eb6 <cprintf>
	cprintf("npages_basemem: %d\n", npages_basemem);
f010117e:	83 c4 08             	add    $0x8,%esp
f0101181:	ff 35 40 be 17 f0    	pushl  0xf017be40
f0101187:	68 75 4b 10 f0       	push   $0xf0104b75
f010118c:	e8 25 1d 00 00       	call   f0102eb6 <cprintf>
	cprintf("pages: %x\n", pages);
f0101191:	83 c4 08             	add    $0x8,%esp
f0101194:	ff 35 0c cb 17 f0    	pushl  0xf017cb0c
f010119a:	68 89 4b 10 f0       	push   $0xf0104b89
f010119f:	e8 12 1d 00 00       	call   f0102eb6 <cprintf>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f01011a4:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011a9:	e8 53 f7 ff ff       	call   f0100901 <boot_alloc>
f01011ae:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011b3:	e8 e8 fa ff ff       	call   f0100ca0 <page_init>

	check_page_free_list(1);
f01011b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01011bd:	e8 1b f8 ff ff       	call   f01009dd <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011c2:	83 c4 10             	add    $0x10,%esp
f01011c5:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01011cc:	75 17                	jne    f01011e5 <mem_init+0x191>
		panic("'pages' is a null pointer!");
f01011ce:	83 ec 04             	sub    $0x4,%esp
f01011d1:	68 94 4b 10 f0       	push   $0xf0104b94
f01011d6:	68 94 02 00 00       	push   $0x294
f01011db:	68 90 4a 10 f0       	push   $0xf0104a90
f01011e0:	e8 bb ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e5:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01011ea:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011ef:	eb 05                	jmp    f01011f6 <mem_init+0x1a2>
		++nfree;
f01011f1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f4:	8b 00                	mov    (%eax),%eax
f01011f6:	85 c0                	test   %eax,%eax
f01011f8:	75 f7                	jne    f01011f1 <mem_init+0x19d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011fa:	83 ec 0c             	sub    $0xc,%esp
f01011fd:	6a 00                	push   $0x0
f01011ff:	e8 86 fb ff ff       	call   f0100d8a <page_alloc>
f0101204:	89 c7                	mov    %eax,%edi
f0101206:	83 c4 10             	add    $0x10,%esp
f0101209:	85 c0                	test   %eax,%eax
f010120b:	75 19                	jne    f0101226 <mem_init+0x1d2>
f010120d:	68 af 4b 10 f0       	push   $0xf0104baf
f0101212:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101217:	68 9c 02 00 00       	push   $0x29c
f010121c:	68 90 4a 10 f0       	push   $0xf0104a90
f0101221:	e8 7a ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101226:	83 ec 0c             	sub    $0xc,%esp
f0101229:	6a 00                	push   $0x0
f010122b:	e8 5a fb ff ff       	call   f0100d8a <page_alloc>
f0101230:	89 c6                	mov    %eax,%esi
f0101232:	83 c4 10             	add    $0x10,%esp
f0101235:	85 c0                	test   %eax,%eax
f0101237:	75 19                	jne    f0101252 <mem_init+0x1fe>
f0101239:	68 c5 4b 10 f0       	push   $0xf0104bc5
f010123e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101243:	68 9d 02 00 00       	push   $0x29d
f0101248:	68 90 4a 10 f0       	push   $0xf0104a90
f010124d:	e8 4e ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101252:	83 ec 0c             	sub    $0xc,%esp
f0101255:	6a 00                	push   $0x0
f0101257:	e8 2e fb ff ff       	call   f0100d8a <page_alloc>
f010125c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010125f:	83 c4 10             	add    $0x10,%esp
f0101262:	85 c0                	test   %eax,%eax
f0101264:	75 19                	jne    f010127f <mem_init+0x22b>
f0101266:	68 db 4b 10 f0       	push   $0xf0104bdb
f010126b:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101270:	68 9e 02 00 00       	push   $0x29e
f0101275:	68 90 4a 10 f0       	push   $0xf0104a90
f010127a:	e8 21 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127f:	39 f7                	cmp    %esi,%edi
f0101281:	75 19                	jne    f010129c <mem_init+0x248>
f0101283:	68 f1 4b 10 f0       	push   $0xf0104bf1
f0101288:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010128d:	68 a1 02 00 00       	push   $0x2a1
f0101292:	68 90 4a 10 f0       	push   $0xf0104a90
f0101297:	e8 04 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129f:	39 c6                	cmp    %eax,%esi
f01012a1:	74 04                	je     f01012a7 <mem_init+0x253>
f01012a3:	39 c7                	cmp    %eax,%edi
f01012a5:	75 19                	jne    f01012c0 <mem_init+0x26c>
f01012a7:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01012ac:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01012b1:	68 a2 02 00 00       	push   $0x2a2
f01012b6:	68 90 4a 10 f0       	push   $0xf0104a90
f01012bb:	e8 e0 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012c0:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012c6:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01012cc:	c1 e2 0c             	shl    $0xc,%edx
f01012cf:	89 f8                	mov    %edi,%eax
f01012d1:	29 c8                	sub    %ecx,%eax
f01012d3:	c1 f8 03             	sar    $0x3,%eax
f01012d6:	c1 e0 0c             	shl    $0xc,%eax
f01012d9:	39 d0                	cmp    %edx,%eax
f01012db:	72 19                	jb     f01012f6 <mem_init+0x2a2>
f01012dd:	68 03 4c 10 f0       	push   $0xf0104c03
f01012e2:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01012e7:	68 a3 02 00 00       	push   $0x2a3
f01012ec:	68 90 4a 10 f0       	push   $0xf0104a90
f01012f1:	e8 aa ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012f6:	89 f0                	mov    %esi,%eax
f01012f8:	29 c8                	sub    %ecx,%eax
f01012fa:	c1 f8 03             	sar    $0x3,%eax
f01012fd:	c1 e0 0c             	shl    $0xc,%eax
f0101300:	39 c2                	cmp    %eax,%edx
f0101302:	77 19                	ja     f010131d <mem_init+0x2c9>
f0101304:	68 20 4c 10 f0       	push   $0xf0104c20
f0101309:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010130e:	68 a4 02 00 00       	push   $0x2a4
f0101313:	68 90 4a 10 f0       	push   $0xf0104a90
f0101318:	e8 83 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010131d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101320:	29 c8                	sub    %ecx,%eax
f0101322:	c1 f8 03             	sar    $0x3,%eax
f0101325:	c1 e0 0c             	shl    $0xc,%eax
f0101328:	39 c2                	cmp    %eax,%edx
f010132a:	77 19                	ja     f0101345 <mem_init+0x2f1>
f010132c:	68 3d 4c 10 f0       	push   $0xf0104c3d
f0101331:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101336:	68 a5 02 00 00       	push   $0x2a5
f010133b:	68 90 4a 10 f0       	push   $0xf0104a90
f0101340:	e8 5b ed ff ff       	call   f01000a0 <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101345:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f010134a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010134d:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0101354:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101357:	83 ec 0c             	sub    $0xc,%esp
f010135a:	6a 00                	push   $0x0
f010135c:	e8 29 fa ff ff       	call   f0100d8a <page_alloc>
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	74 19                	je     f0101381 <mem_init+0x32d>
f0101368:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010136d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101372:	68 ad 02 00 00       	push   $0x2ad
f0101377:	68 90 4a 10 f0       	push   $0xf0104a90
f010137c:	e8 1f ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101381:	83 ec 0c             	sub    $0xc,%esp
f0101384:	57                   	push   %edi
f0101385:	e8 6a fa ff ff       	call   f0100df4 <page_free>
	page_free(pp1);
f010138a:	89 34 24             	mov    %esi,(%esp)
f010138d:	e8 62 fa ff ff       	call   f0100df4 <page_free>
	page_free(pp2);
f0101392:	83 c4 04             	add    $0x4,%esp
f0101395:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101398:	e8 57 fa ff ff       	call   f0100df4 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010139d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a4:	e8 e1 f9 ff ff       	call   f0100d8a <page_alloc>
f01013a9:	89 c6                	mov    %eax,%esi
f01013ab:	83 c4 10             	add    $0x10,%esp
f01013ae:	85 c0                	test   %eax,%eax
f01013b0:	75 19                	jne    f01013cb <mem_init+0x377>
f01013b2:	68 af 4b 10 f0       	push   $0xf0104baf
f01013b7:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01013bc:	68 b4 02 00 00       	push   $0x2b4
f01013c1:	68 90 4a 10 f0       	push   $0xf0104a90
f01013c6:	e8 d5 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013cb:	83 ec 0c             	sub    $0xc,%esp
f01013ce:	6a 00                	push   $0x0
f01013d0:	e8 b5 f9 ff ff       	call   f0100d8a <page_alloc>
f01013d5:	89 c7                	mov    %eax,%edi
f01013d7:	83 c4 10             	add    $0x10,%esp
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	75 19                	jne    f01013f7 <mem_init+0x3a3>
f01013de:	68 c5 4b 10 f0       	push   $0xf0104bc5
f01013e3:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01013e8:	68 b5 02 00 00       	push   $0x2b5
f01013ed:	68 90 4a 10 f0       	push   $0xf0104a90
f01013f2:	e8 a9 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f7:	83 ec 0c             	sub    $0xc,%esp
f01013fa:	6a 00                	push   $0x0
f01013fc:	e8 89 f9 ff ff       	call   f0100d8a <page_alloc>
f0101401:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101404:	83 c4 10             	add    $0x10,%esp
f0101407:	85 c0                	test   %eax,%eax
f0101409:	75 19                	jne    f0101424 <mem_init+0x3d0>
f010140b:	68 db 4b 10 f0       	push   $0xf0104bdb
f0101410:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101415:	68 b6 02 00 00       	push   $0x2b6
f010141a:	68 90 4a 10 f0       	push   $0xf0104a90
f010141f:	e8 7c ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101424:	39 fe                	cmp    %edi,%esi
f0101426:	75 19                	jne    f0101441 <mem_init+0x3ed>
f0101428:	68 f1 4b 10 f0       	push   $0xf0104bf1
f010142d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101432:	68 b8 02 00 00       	push   $0x2b8
f0101437:	68 90 4a 10 f0       	push   $0xf0104a90
f010143c:	e8 5f ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101441:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101444:	39 c7                	cmp    %eax,%edi
f0101446:	74 04                	je     f010144c <mem_init+0x3f8>
f0101448:	39 c6                	cmp    %eax,%esi
f010144a:	75 19                	jne    f0101465 <mem_init+0x411>
f010144c:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0101451:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101456:	68 b9 02 00 00       	push   $0x2b9
f010145b:	68 90 4a 10 f0       	push   $0xf0104a90
f0101460:	e8 3b ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101465:	83 ec 0c             	sub    $0xc,%esp
f0101468:	6a 00                	push   $0x0
f010146a:	e8 1b f9 ff ff       	call   f0100d8a <page_alloc>
f010146f:	83 c4 10             	add    $0x10,%esp
f0101472:	85 c0                	test   %eax,%eax
f0101474:	74 19                	je     f010148f <mem_init+0x43b>
f0101476:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010147b:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101480:	68 ba 02 00 00       	push   $0x2ba
f0101485:	68 90 4a 10 f0       	push   $0xf0104a90
f010148a:	e8 11 ec ff ff       	call   f01000a0 <_panic>
f010148f:	89 f0                	mov    %esi,%eax
f0101491:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101497:	c1 f8 03             	sar    $0x3,%eax
f010149a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149d:	89 c2                	mov    %eax,%edx
f010149f:	c1 ea 0c             	shr    $0xc,%edx
f01014a2:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01014a8:	72 12                	jb     f01014bc <mem_init+0x468>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014aa:	50                   	push   %eax
f01014ab:	68 04 4e 10 f0       	push   $0xf0104e04
f01014b0:	6a 56                	push   $0x56
f01014b2:	68 9c 4a 10 f0       	push   $0xf0104a9c
f01014b7:	e8 e4 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014bc:	83 ec 04             	sub    $0x4,%esp
f01014bf:	68 00 10 00 00       	push   $0x1000
f01014c4:	6a 01                	push   $0x1
f01014c6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014cb:	50                   	push   %eax
f01014cc:	e8 cf 2b 00 00       	call   f01040a0 <memset>
	page_free(pp0);
f01014d1:	89 34 24             	mov    %esi,(%esp)
f01014d4:	e8 1b f9 ff ff       	call   f0100df4 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014e0:	e8 a5 f8 ff ff       	call   f0100d8a <page_alloc>
f01014e5:	83 c4 10             	add    $0x10,%esp
f01014e8:	85 c0                	test   %eax,%eax
f01014ea:	75 19                	jne    f0101505 <mem_init+0x4b1>
f01014ec:	68 69 4c 10 f0       	push   $0xf0104c69
f01014f1:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01014f6:	68 bf 02 00 00       	push   $0x2bf
f01014fb:	68 90 4a 10 f0       	push   $0xf0104a90
f0101500:	e8 9b eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101505:	39 c6                	cmp    %eax,%esi
f0101507:	74 19                	je     f0101522 <mem_init+0x4ce>
f0101509:	68 87 4c 10 f0       	push   $0xf0104c87
f010150e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101513:	68 c0 02 00 00       	push   $0x2c0
f0101518:	68 90 4a 10 f0       	push   $0xf0104a90
f010151d:	e8 7e eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101522:	89 f0                	mov    %esi,%eax
f0101524:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010152a:	c1 f8 03             	sar    $0x3,%eax
f010152d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101530:	89 c2                	mov    %eax,%edx
f0101532:	c1 ea 0c             	shr    $0xc,%edx
f0101535:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010153b:	72 12                	jb     f010154f <mem_init+0x4fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010153d:	50                   	push   %eax
f010153e:	68 04 4e 10 f0       	push   $0xf0104e04
f0101543:	6a 56                	push   $0x56
f0101545:	68 9c 4a 10 f0       	push   $0xf0104a9c
f010154a:	e8 51 eb ff ff       	call   f01000a0 <_panic>
f010154f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101555:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010155b:	80 38 00             	cmpb   $0x0,(%eax)
f010155e:	74 19                	je     f0101579 <mem_init+0x525>
f0101560:	68 97 4c 10 f0       	push   $0xf0104c97
f0101565:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010156a:	68 c3 02 00 00       	push   $0x2c3
f010156f:	68 90 4a 10 f0       	push   $0xf0104a90
f0101574:	e8 27 eb ff ff       	call   f01000a0 <_panic>
f0101579:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010157c:	39 d0                	cmp    %edx,%eax
f010157e:	75 db                	jne    f010155b <mem_init+0x507>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101580:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101583:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101588:	83 ec 0c             	sub    $0xc,%esp
f010158b:	56                   	push   %esi
f010158c:	e8 63 f8 ff ff       	call   f0100df4 <page_free>
	page_free(pp1);
f0101591:	89 3c 24             	mov    %edi,(%esp)
f0101594:	e8 5b f8 ff ff       	call   f0100df4 <page_free>
	page_free(pp2);
f0101599:	83 c4 04             	add    $0x4,%esp
f010159c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010159f:	e8 50 f8 ff ff       	call   f0100df4 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015a4:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01015a9:	83 c4 10             	add    $0x10,%esp
f01015ac:	eb 05                	jmp    f01015b3 <mem_init+0x55f>
		--nfree;
f01015ae:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015b1:	8b 00                	mov    (%eax),%eax
f01015b3:	85 c0                	test   %eax,%eax
f01015b5:	75 f7                	jne    f01015ae <mem_init+0x55a>
		--nfree;
	assert(nfree == 0);
f01015b7:	85 db                	test   %ebx,%ebx
f01015b9:	74 19                	je     f01015d4 <mem_init+0x580>
f01015bb:	68 a1 4c 10 f0       	push   $0xf0104ca1
f01015c0:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01015c5:	68 d0 02 00 00       	push   $0x2d0
f01015ca:	68 90 4a 10 f0       	push   $0xf0104a90
f01015cf:	e8 cc ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015d4:	83 ec 0c             	sub    $0xc,%esp
f01015d7:	68 e8 4f 10 f0       	push   $0xf0104fe8
f01015dc:	e8 d5 18 00 00       	call   f0102eb6 <cprintf>
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	cprintf("so far so good\n");
f01015e1:	c7 04 24 ac 4c 10 f0 	movl   $0xf0104cac,(%esp)
f01015e8:	e8 c9 18 00 00       	call   f0102eb6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f4:	e8 91 f7 ff ff       	call   f0100d8a <page_alloc>
f01015f9:	89 c6                	mov    %eax,%esi
f01015fb:	83 c4 10             	add    $0x10,%esp
f01015fe:	85 c0                	test   %eax,%eax
f0101600:	75 19                	jne    f010161b <mem_init+0x5c7>
f0101602:	68 af 4b 10 f0       	push   $0xf0104baf
f0101607:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010160c:	68 2e 03 00 00       	push   $0x32e
f0101611:	68 90 4a 10 f0       	push   $0xf0104a90
f0101616:	e8 85 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	6a 00                	push   $0x0
f0101620:	e8 65 f7 ff ff       	call   f0100d8a <page_alloc>
f0101625:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101628:	83 c4 10             	add    $0x10,%esp
f010162b:	85 c0                	test   %eax,%eax
f010162d:	75 19                	jne    f0101648 <mem_init+0x5f4>
f010162f:	68 c5 4b 10 f0       	push   $0xf0104bc5
f0101634:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101639:	68 2f 03 00 00       	push   $0x32f
f010163e:	68 90 4a 10 f0       	push   $0xf0104a90
f0101643:	e8 58 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101648:	83 ec 0c             	sub    $0xc,%esp
f010164b:	6a 00                	push   $0x0
f010164d:	e8 38 f7 ff ff       	call   f0100d8a <page_alloc>
f0101652:	89 c3                	mov    %eax,%ebx
f0101654:	83 c4 10             	add    $0x10,%esp
f0101657:	85 c0                	test   %eax,%eax
f0101659:	75 19                	jne    f0101674 <mem_init+0x620>
f010165b:	68 db 4b 10 f0       	push   $0xf0104bdb
f0101660:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101665:	68 30 03 00 00       	push   $0x330
f010166a:	68 90 4a 10 f0       	push   $0xf0104a90
f010166f:	e8 2c ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101674:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101677:	75 19                	jne    f0101692 <mem_init+0x63e>
f0101679:	68 f1 4b 10 f0       	push   $0xf0104bf1
f010167e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101683:	68 33 03 00 00       	push   $0x333
f0101688:	68 90 4a 10 f0       	push   $0xf0104a90
f010168d:	e8 0e ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101692:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101695:	74 04                	je     f010169b <mem_init+0x647>
f0101697:	39 c6                	cmp    %eax,%esi
f0101699:	75 19                	jne    f01016b4 <mem_init+0x660>
f010169b:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01016a0:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01016a5:	68 34 03 00 00       	push   $0x334
f01016aa:	68 90 4a 10 f0       	push   $0xf0104a90
f01016af:	e8 ec e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016b4:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01016b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016bc:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f01016c3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016c6:	83 ec 0c             	sub    $0xc,%esp
f01016c9:	6a 00                	push   $0x0
f01016cb:	e8 ba f6 ff ff       	call   f0100d8a <page_alloc>
f01016d0:	83 c4 10             	add    $0x10,%esp
f01016d3:	85 c0                	test   %eax,%eax
f01016d5:	74 19                	je     f01016f0 <mem_init+0x69c>
f01016d7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01016dc:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01016e1:	68 3b 03 00 00       	push   $0x33b
f01016e6:	68 90 4a 10 f0       	push   $0xf0104a90
f01016eb:	e8 b0 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016f0:	83 ec 04             	sub    $0x4,%esp
f01016f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016f6:	50                   	push   %eax
f01016f7:	6a 00                	push   $0x0
f01016f9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01016ff:	e8 41 f8 ff ff       	call   f0100f45 <page_lookup>
f0101704:	83 c4 10             	add    $0x10,%esp
f0101707:	85 c0                	test   %eax,%eax
f0101709:	74 19                	je     f0101724 <mem_init+0x6d0>
f010170b:	68 08 50 10 f0       	push   $0xf0105008
f0101710:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101715:	68 3e 03 00 00       	push   $0x33e
f010171a:	68 90 4a 10 f0       	push   $0xf0104a90
f010171f:	e8 7c e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101724:	6a 02                	push   $0x2
f0101726:	6a 00                	push   $0x0
f0101728:	ff 75 d4             	pushl  -0x2c(%ebp)
f010172b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101731:	e8 b8 f8 ff ff       	call   f0100fee <page_insert>
f0101736:	83 c4 10             	add    $0x10,%esp
f0101739:	85 c0                	test   %eax,%eax
f010173b:	78 19                	js     f0101756 <mem_init+0x702>
f010173d:	68 40 50 10 f0       	push   $0xf0105040
f0101742:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101747:	68 41 03 00 00       	push   $0x341
f010174c:	68 90 4a 10 f0       	push   $0xf0104a90
f0101751:	e8 4a e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101756:	83 ec 0c             	sub    $0xc,%esp
f0101759:	56                   	push   %esi
f010175a:	e8 95 f6 ff ff       	call   f0100df4 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010175f:	6a 02                	push   $0x2
f0101761:	6a 00                	push   $0x0
f0101763:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101766:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010176c:	e8 7d f8 ff ff       	call   f0100fee <page_insert>
f0101771:	83 c4 20             	add    $0x20,%esp
f0101774:	85 c0                	test   %eax,%eax
f0101776:	74 19                	je     f0101791 <mem_init+0x73d>
f0101778:	68 70 50 10 f0       	push   $0xf0105070
f010177d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101782:	68 45 03 00 00       	push   $0x345
f0101787:	68 90 4a 10 f0       	push   $0xf0104a90
f010178c:	e8 0f e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101791:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101797:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f010179c:	89 c1                	mov    %eax,%ecx
f010179e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017a1:	8b 17                	mov    (%edi),%edx
f01017a3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017a9:	89 f0                	mov    %esi,%eax
f01017ab:	29 c8                	sub    %ecx,%eax
f01017ad:	c1 f8 03             	sar    $0x3,%eax
f01017b0:	c1 e0 0c             	shl    $0xc,%eax
f01017b3:	39 c2                	cmp    %eax,%edx
f01017b5:	74 19                	je     f01017d0 <mem_init+0x77c>
f01017b7:	68 a0 50 10 f0       	push   $0xf01050a0
f01017bc:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01017c1:	68 46 03 00 00       	push   $0x346
f01017c6:	68 90 4a 10 f0       	push   $0xf0104a90
f01017cb:	e8 d0 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017d0:	ba 00 00 00 00       	mov    $0x0,%edx
f01017d5:	89 f8                	mov    %edi,%eax
f01017d7:	e8 9d f1 ff ff       	call   f0100979 <check_va2pa>
f01017dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01017df:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017e2:	c1 fa 03             	sar    $0x3,%edx
f01017e5:	c1 e2 0c             	shl    $0xc,%edx
f01017e8:	39 d0                	cmp    %edx,%eax
f01017ea:	74 19                	je     f0101805 <mem_init+0x7b1>
f01017ec:	68 c8 50 10 f0       	push   $0xf01050c8
f01017f1:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01017f6:	68 47 03 00 00       	push   $0x347
f01017fb:	68 90 4a 10 f0       	push   $0xf0104a90
f0101800:	e8 9b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101805:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101808:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010180d:	74 19                	je     f0101828 <mem_init+0x7d4>
f010180f:	68 bc 4c 10 f0       	push   $0xf0104cbc
f0101814:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101819:	68 48 03 00 00       	push   $0x348
f010181e:	68 90 4a 10 f0       	push   $0xf0104a90
f0101823:	e8 78 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101828:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010182d:	74 19                	je     f0101848 <mem_init+0x7f4>
f010182f:	68 cd 4c 10 f0       	push   $0xf0104ccd
f0101834:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101839:	68 49 03 00 00       	push   $0x349
f010183e:	68 90 4a 10 f0       	push   $0xf0104a90
f0101843:	e8 58 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101848:	6a 02                	push   $0x2
f010184a:	68 00 10 00 00       	push   $0x1000
f010184f:	53                   	push   %ebx
f0101850:	57                   	push   %edi
f0101851:	e8 98 f7 ff ff       	call   f0100fee <page_insert>
f0101856:	83 c4 10             	add    $0x10,%esp
f0101859:	85 c0                	test   %eax,%eax
f010185b:	74 19                	je     f0101876 <mem_init+0x822>
f010185d:	68 f8 50 10 f0       	push   $0xf01050f8
f0101862:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101867:	68 4c 03 00 00       	push   $0x34c
f010186c:	68 90 4a 10 f0       	push   $0xf0104a90
f0101871:	e8 2a e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101876:	ba 00 10 00 00       	mov    $0x1000,%edx
f010187b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101880:	e8 f4 f0 ff ff       	call   f0100979 <check_va2pa>
f0101885:	89 da                	mov    %ebx,%edx
f0101887:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f010188d:	c1 fa 03             	sar    $0x3,%edx
f0101890:	c1 e2 0c             	shl    $0xc,%edx
f0101893:	39 d0                	cmp    %edx,%eax
f0101895:	74 19                	je     f01018b0 <mem_init+0x85c>
f0101897:	68 34 51 10 f0       	push   $0xf0105134
f010189c:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01018a1:	68 4d 03 00 00       	push   $0x34d
f01018a6:	68 90 4a 10 f0       	push   $0xf0104a90
f01018ab:	e8 f0 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018b0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018b5:	74 19                	je     f01018d0 <mem_init+0x87c>
f01018b7:	68 de 4c 10 f0       	push   $0xf0104cde
f01018bc:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01018c1:	68 4e 03 00 00       	push   $0x34e
f01018c6:	68 90 4a 10 f0       	push   $0xf0104a90
f01018cb:	e8 d0 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018d0:	83 ec 0c             	sub    $0xc,%esp
f01018d3:	6a 00                	push   $0x0
f01018d5:	e8 b0 f4 ff ff       	call   f0100d8a <page_alloc>
f01018da:	83 c4 10             	add    $0x10,%esp
f01018dd:	85 c0                	test   %eax,%eax
f01018df:	74 19                	je     f01018fa <mem_init+0x8a6>
f01018e1:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01018e6:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01018eb:	68 51 03 00 00       	push   $0x351
f01018f0:	68 90 4a 10 f0       	push   $0xf0104a90
f01018f5:	e8 a6 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018fa:	6a 02                	push   $0x2
f01018fc:	68 00 10 00 00       	push   $0x1000
f0101901:	53                   	push   %ebx
f0101902:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101908:	e8 e1 f6 ff ff       	call   f0100fee <page_insert>
f010190d:	83 c4 10             	add    $0x10,%esp
f0101910:	85 c0                	test   %eax,%eax
f0101912:	74 19                	je     f010192d <mem_init+0x8d9>
f0101914:	68 f8 50 10 f0       	push   $0xf01050f8
f0101919:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010191e:	68 54 03 00 00       	push   $0x354
f0101923:	68 90 4a 10 f0       	push   $0xf0104a90
f0101928:	e8 73 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010192d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101932:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101937:	e8 3d f0 ff ff       	call   f0100979 <check_va2pa>
f010193c:	89 da                	mov    %ebx,%edx
f010193e:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101944:	c1 fa 03             	sar    $0x3,%edx
f0101947:	c1 e2 0c             	shl    $0xc,%edx
f010194a:	39 d0                	cmp    %edx,%eax
f010194c:	74 19                	je     f0101967 <mem_init+0x913>
f010194e:	68 34 51 10 f0       	push   $0xf0105134
f0101953:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101958:	68 55 03 00 00       	push   $0x355
f010195d:	68 90 4a 10 f0       	push   $0xf0104a90
f0101962:	e8 39 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101967:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010196c:	74 19                	je     f0101987 <mem_init+0x933>
f010196e:	68 de 4c 10 f0       	push   $0xf0104cde
f0101973:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101978:	68 56 03 00 00       	push   $0x356
f010197d:	68 90 4a 10 f0       	push   $0xf0104a90
f0101982:	e8 19 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101987:	83 ec 0c             	sub    $0xc,%esp
f010198a:	6a 00                	push   $0x0
f010198c:	e8 f9 f3 ff ff       	call   f0100d8a <page_alloc>
f0101991:	83 c4 10             	add    $0x10,%esp
f0101994:	85 c0                	test   %eax,%eax
f0101996:	74 19                	je     f01019b1 <mem_init+0x95d>
f0101998:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010199d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01019a2:	68 5a 03 00 00       	push   $0x35a
f01019a7:	68 90 4a 10 f0       	push   $0xf0104a90
f01019ac:	e8 ef e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019b1:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f01019b7:	8b 02                	mov    (%edx),%eax
f01019b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019be:	89 c1                	mov    %eax,%ecx
f01019c0:	c1 e9 0c             	shr    $0xc,%ecx
f01019c3:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f01019c9:	72 15                	jb     f01019e0 <mem_init+0x98c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019cb:	50                   	push   %eax
f01019cc:	68 04 4e 10 f0       	push   $0xf0104e04
f01019d1:	68 5d 03 00 00       	push   $0x35d
f01019d6:	68 90 4a 10 f0       	push   $0xf0104a90
f01019db:	e8 c0 e6 ff ff       	call   f01000a0 <_panic>
f01019e0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019e8:	83 ec 04             	sub    $0x4,%esp
f01019eb:	6a 00                	push   $0x0
f01019ed:	68 00 10 00 00       	push   $0x1000
f01019f2:	52                   	push   %edx
f01019f3:	e8 32 f4 ff ff       	call   f0100e2a <pgdir_walk>
f01019f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019fb:	8d 57 04             	lea    0x4(%edi),%edx
f01019fe:	83 c4 10             	add    $0x10,%esp
f0101a01:	39 d0                	cmp    %edx,%eax
f0101a03:	74 19                	je     f0101a1e <mem_init+0x9ca>
f0101a05:	68 64 51 10 f0       	push   $0xf0105164
f0101a0a:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101a0f:	68 5e 03 00 00       	push   $0x35e
f0101a14:	68 90 4a 10 f0       	push   $0xf0104a90
f0101a19:	e8 82 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a1e:	6a 06                	push   $0x6
f0101a20:	68 00 10 00 00       	push   $0x1000
f0101a25:	53                   	push   %ebx
f0101a26:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a2c:	e8 bd f5 ff ff       	call   f0100fee <page_insert>
f0101a31:	83 c4 10             	add    $0x10,%esp
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	74 19                	je     f0101a51 <mem_init+0x9fd>
f0101a38:	68 a4 51 10 f0       	push   $0xf01051a4
f0101a3d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101a42:	68 61 03 00 00       	push   $0x361
f0101a47:	68 90 4a 10 f0       	push   $0xf0104a90
f0101a4c:	e8 4f e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a51:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101a57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a5c:	89 f8                	mov    %edi,%eax
f0101a5e:	e8 16 ef ff ff       	call   f0100979 <check_va2pa>
f0101a63:	89 da                	mov    %ebx,%edx
f0101a65:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101a6b:	c1 fa 03             	sar    $0x3,%edx
f0101a6e:	c1 e2 0c             	shl    $0xc,%edx
f0101a71:	39 d0                	cmp    %edx,%eax
f0101a73:	74 19                	je     f0101a8e <mem_init+0xa3a>
f0101a75:	68 34 51 10 f0       	push   $0xf0105134
f0101a7a:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101a7f:	68 62 03 00 00       	push   $0x362
f0101a84:	68 90 4a 10 f0       	push   $0xf0104a90
f0101a89:	e8 12 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a8e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a93:	74 19                	je     f0101aae <mem_init+0xa5a>
f0101a95:	68 de 4c 10 f0       	push   $0xf0104cde
f0101a9a:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101a9f:	68 63 03 00 00       	push   $0x363
f0101aa4:	68 90 4a 10 f0       	push   $0xf0104a90
f0101aa9:	e8 f2 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101aae:	83 ec 04             	sub    $0x4,%esp
f0101ab1:	6a 00                	push   $0x0
f0101ab3:	68 00 10 00 00       	push   $0x1000
f0101ab8:	57                   	push   %edi
f0101ab9:	e8 6c f3 ff ff       	call   f0100e2a <pgdir_walk>
f0101abe:	83 c4 10             	add    $0x10,%esp
f0101ac1:	f6 00 04             	testb  $0x4,(%eax)
f0101ac4:	75 19                	jne    f0101adf <mem_init+0xa8b>
f0101ac6:	68 e4 51 10 f0       	push   $0xf01051e4
f0101acb:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101ad0:	68 64 03 00 00       	push   $0x364
f0101ad5:	68 90 4a 10 f0       	push   $0xf0104a90
f0101ada:	e8 c1 e5 ff ff       	call   f01000a0 <_panic>
	cprintf("pp2 %x\n", pp2);
f0101adf:	83 ec 08             	sub    $0x8,%esp
f0101ae2:	53                   	push   %ebx
f0101ae3:	68 ef 4c 10 f0       	push   $0xf0104cef
f0101ae8:	e8 c9 13 00 00       	call   f0102eb6 <cprintf>
	cprintf("kern_pgdir %x\n", kern_pgdir);
f0101aed:	83 c4 08             	add    $0x8,%esp
f0101af0:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101af6:	68 f7 4c 10 f0       	push   $0xf0104cf7
f0101afb:	e8 b6 13 00 00       	call   f0102eb6 <cprintf>
	cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
f0101b00:	83 c4 08             	add    $0x8,%esp
f0101b03:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101b08:	ff 30                	pushl  (%eax)
f0101b0a:	68 06 4d 10 f0       	push   $0xf0104d06
f0101b0f:	e8 a2 13 00 00       	call   f0102eb6 <cprintf>
	assert(kern_pgdir[0] & PTE_U);
f0101b14:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101b19:	83 c4 10             	add    $0x10,%esp
f0101b1c:	f6 00 04             	testb  $0x4,(%eax)
f0101b1f:	75 19                	jne    f0101b3a <mem_init+0xae6>
f0101b21:	68 1b 4d 10 f0       	push   $0xf0104d1b
f0101b26:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101b2b:	68 68 03 00 00       	push   $0x368
f0101b30:	68 90 4a 10 f0       	push   $0xf0104a90
f0101b35:	e8 66 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3a:	6a 02                	push   $0x2
f0101b3c:	68 00 10 00 00       	push   $0x1000
f0101b41:	53                   	push   %ebx
f0101b42:	50                   	push   %eax
f0101b43:	e8 a6 f4 ff ff       	call   f0100fee <page_insert>
f0101b48:	83 c4 10             	add    $0x10,%esp
f0101b4b:	85 c0                	test   %eax,%eax
f0101b4d:	74 19                	je     f0101b68 <mem_init+0xb14>
f0101b4f:	68 f8 50 10 f0       	push   $0xf01050f8
f0101b54:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101b59:	68 6b 03 00 00       	push   $0x36b
f0101b5e:	68 90 4a 10 f0       	push   $0xf0104a90
f0101b63:	e8 38 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b68:	83 ec 04             	sub    $0x4,%esp
f0101b6b:	6a 00                	push   $0x0
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b78:	e8 ad f2 ff ff       	call   f0100e2a <pgdir_walk>
f0101b7d:	83 c4 10             	add    $0x10,%esp
f0101b80:	f6 00 02             	testb  $0x2,(%eax)
f0101b83:	75 19                	jne    f0101b9e <mem_init+0xb4a>
f0101b85:	68 18 52 10 f0       	push   $0xf0105218
f0101b8a:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101b8f:	68 6c 03 00 00       	push   $0x36c
f0101b94:	68 90 4a 10 f0       	push   $0xf0104a90
f0101b99:	e8 02 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b9e:	83 ec 04             	sub    $0x4,%esp
f0101ba1:	6a 00                	push   $0x0
f0101ba3:	68 00 10 00 00       	push   $0x1000
f0101ba8:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101bae:	e8 77 f2 ff ff       	call   f0100e2a <pgdir_walk>
f0101bb3:	83 c4 10             	add    $0x10,%esp
f0101bb6:	f6 00 04             	testb  $0x4,(%eax)
f0101bb9:	74 19                	je     f0101bd4 <mem_init+0xb80>
f0101bbb:	68 4c 52 10 f0       	push   $0xf010524c
f0101bc0:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101bc5:	68 6d 03 00 00       	push   $0x36d
f0101bca:	68 90 4a 10 f0       	push   $0xf0104a90
f0101bcf:	e8 cc e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bd4:	6a 02                	push   $0x2
f0101bd6:	68 00 00 40 00       	push   $0x400000
f0101bdb:	56                   	push   %esi
f0101bdc:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101be2:	e8 07 f4 ff ff       	call   f0100fee <page_insert>
f0101be7:	83 c4 10             	add    $0x10,%esp
f0101bea:	85 c0                	test   %eax,%eax
f0101bec:	78 19                	js     f0101c07 <mem_init+0xbb3>
f0101bee:	68 84 52 10 f0       	push   $0xf0105284
f0101bf3:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101bf8:	68 70 03 00 00       	push   $0x370
f0101bfd:	68 90 4a 10 f0       	push   $0xf0104a90
f0101c02:	e8 99 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c07:	6a 02                	push   $0x2
f0101c09:	68 00 10 00 00       	push   $0x1000
f0101c0e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c11:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c17:	e8 d2 f3 ff ff       	call   f0100fee <page_insert>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 19                	je     f0101c3c <mem_init+0xbe8>
f0101c23:	68 bc 52 10 f0       	push   $0xf01052bc
f0101c28:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101c2d:	68 73 03 00 00       	push   $0x373
f0101c32:	68 90 4a 10 f0       	push   $0xf0104a90
f0101c37:	e8 64 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c4c:	e8 d9 f1 ff ff       	call   f0100e2a <pgdir_walk>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	f6 00 04             	testb  $0x4,(%eax)
f0101c57:	74 19                	je     f0101c72 <mem_init+0xc1e>
f0101c59:	68 4c 52 10 f0       	push   $0xf010524c
f0101c5e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101c63:	68 74 03 00 00       	push   $0x374
f0101c68:	68 90 4a 10 f0       	push   $0xf0104a90
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c72:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101c78:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c7d:	89 f8                	mov    %edi,%eax
f0101c7f:	e8 f5 ec ff ff       	call   f0100979 <check_va2pa>
f0101c84:	89 c1                	mov    %eax,%ecx
f0101c86:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c8c:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101c92:	c1 f8 03             	sar    $0x3,%eax
f0101c95:	c1 e0 0c             	shl    $0xc,%eax
f0101c98:	39 c1                	cmp    %eax,%ecx
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0xc61>
f0101c9c:	68 f8 52 10 f0       	push   $0xf01052f8
f0101ca1:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101ca6:	68 77 03 00 00       	push   $0x377
f0101cab:	68 90 4a 10 f0       	push   $0xf0104a90
f0101cb0:	e8 eb e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cba:	89 f8                	mov    %edi,%eax
f0101cbc:	e8 b8 ec ff ff       	call   f0100979 <check_va2pa>
f0101cc1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xc8b>
f0101cc6:	68 24 53 10 f0       	push   $0xf0105324
f0101ccb:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101cd0:	68 78 03 00 00       	push   $0x378
f0101cd5:	68 90 4a 10 f0       	push   $0xf0104a90
f0101cda:	e8 c1 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce2:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101ce7:	74 19                	je     f0101d02 <mem_init+0xcae>
f0101ce9:	68 31 4d 10 f0       	push   $0xf0104d31
f0101cee:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101cf3:	68 7a 03 00 00       	push   $0x37a
f0101cf8:	68 90 4a 10 f0       	push   $0xf0104a90
f0101cfd:	e8 9e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d02:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d07:	74 19                	je     f0101d22 <mem_init+0xcce>
f0101d09:	68 42 4d 10 f0       	push   $0xf0104d42
f0101d0e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101d13:	68 7b 03 00 00       	push   $0x37b
f0101d18:	68 90 4a 10 f0       	push   $0xf0104a90
f0101d1d:	e8 7e e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d22:	83 ec 0c             	sub    $0xc,%esp
f0101d25:	6a 00                	push   $0x0
f0101d27:	e8 5e f0 ff ff       	call   f0100d8a <page_alloc>
f0101d2c:	83 c4 10             	add    $0x10,%esp
f0101d2f:	85 c0                	test   %eax,%eax
f0101d31:	74 04                	je     f0101d37 <mem_init+0xce3>
f0101d33:	39 c3                	cmp    %eax,%ebx
f0101d35:	74 19                	je     f0101d50 <mem_init+0xcfc>
f0101d37:	68 54 53 10 f0       	push   $0xf0105354
f0101d3c:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101d41:	68 7e 03 00 00       	push   $0x37e
f0101d46:	68 90 4a 10 f0       	push   $0xf0104a90
f0101d4b:	e8 50 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d50:	83 ec 08             	sub    $0x8,%esp
f0101d53:	6a 00                	push   $0x0
f0101d55:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d5b:	e8 4b f2 ff ff       	call   f0100fab <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d60:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d66:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d6b:	89 f8                	mov    %edi,%eax
f0101d6d:	e8 07 ec ff ff       	call   f0100979 <check_va2pa>
f0101d72:	83 c4 10             	add    $0x10,%esp
f0101d75:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d78:	74 19                	je     f0101d93 <mem_init+0xd3f>
f0101d7a:	68 78 53 10 f0       	push   $0xf0105378
f0101d7f:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101d84:	68 82 03 00 00       	push   $0x382
f0101d89:	68 90 4a 10 f0       	push   $0xf0104a90
f0101d8e:	e8 0d e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d93:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d98:	89 f8                	mov    %edi,%eax
f0101d9a:	e8 da eb ff ff       	call   f0100979 <check_va2pa>
f0101d9f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101da2:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101da8:	c1 fa 03             	sar    $0x3,%edx
f0101dab:	c1 e2 0c             	shl    $0xc,%edx
f0101dae:	39 d0                	cmp    %edx,%eax
f0101db0:	74 19                	je     f0101dcb <mem_init+0xd77>
f0101db2:	68 24 53 10 f0       	push   $0xf0105324
f0101db7:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101dbc:	68 83 03 00 00       	push   $0x383
f0101dc1:	68 90 4a 10 f0       	push   $0xf0104a90
f0101dc6:	e8 d5 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dce:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101dd3:	74 19                	je     f0101dee <mem_init+0xd9a>
f0101dd5:	68 bc 4c 10 f0       	push   $0xf0104cbc
f0101dda:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101ddf:	68 84 03 00 00       	push   $0x384
f0101de4:	68 90 4a 10 f0       	push   $0xf0104a90
f0101de9:	e8 b2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dee:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df3:	74 19                	je     f0101e0e <mem_init+0xdba>
f0101df5:	68 42 4d 10 f0       	push   $0xf0104d42
f0101dfa:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101dff:	68 85 03 00 00       	push   $0x385
f0101e04:	68 90 4a 10 f0       	push   $0xf0104a90
f0101e09:	e8 92 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e0e:	83 ec 08             	sub    $0x8,%esp
f0101e11:	68 00 10 00 00       	push   $0x1000
f0101e16:	57                   	push   %edi
f0101e17:	e8 8f f1 ff ff       	call   f0100fab <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e1c:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101e22:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e27:	89 f8                	mov    %edi,%eax
f0101e29:	e8 4b eb ff ff       	call   f0100979 <check_va2pa>
f0101e2e:	83 c4 10             	add    $0x10,%esp
f0101e31:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e34:	74 19                	je     f0101e4f <mem_init+0xdfb>
f0101e36:	68 78 53 10 f0       	push   $0xf0105378
f0101e3b:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101e40:	68 89 03 00 00       	push   $0x389
f0101e45:	68 90 4a 10 f0       	push   $0xf0104a90
f0101e4a:	e8 51 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e4f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e54:	89 f8                	mov    %edi,%eax
f0101e56:	e8 1e eb ff ff       	call   f0100979 <check_va2pa>
f0101e5b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e5e:	74 19                	je     f0101e79 <mem_init+0xe25>
f0101e60:	68 9c 53 10 f0       	push   $0xf010539c
f0101e65:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101e6a:	68 8a 03 00 00       	push   $0x38a
f0101e6f:	68 90 4a 10 f0       	push   $0xf0104a90
f0101e74:	e8 27 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e79:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e7c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e81:	74 19                	je     f0101e9c <mem_init+0xe48>
f0101e83:	68 53 4d 10 f0       	push   $0xf0104d53
f0101e88:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101e8d:	68 8b 03 00 00       	push   $0x38b
f0101e92:	68 90 4a 10 f0       	push   $0xf0104a90
f0101e97:	e8 04 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e9c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ea1:	74 19                	je     f0101ebc <mem_init+0xe68>
f0101ea3:	68 42 4d 10 f0       	push   $0xf0104d42
f0101ea8:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101ead:	68 8c 03 00 00       	push   $0x38c
f0101eb2:	68 90 4a 10 f0       	push   $0xf0104a90
f0101eb7:	e8 e4 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ebc:	83 ec 0c             	sub    $0xc,%esp
f0101ebf:	6a 00                	push   $0x0
f0101ec1:	e8 c4 ee ff ff       	call   f0100d8a <page_alloc>
f0101ec6:	83 c4 10             	add    $0x10,%esp
f0101ec9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ecc:	75 04                	jne    f0101ed2 <mem_init+0xe7e>
f0101ece:	85 c0                	test   %eax,%eax
f0101ed0:	75 19                	jne    f0101eeb <mem_init+0xe97>
f0101ed2:	68 c4 53 10 f0       	push   $0xf01053c4
f0101ed7:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101edc:	68 8f 03 00 00       	push   $0x38f
f0101ee1:	68 90 4a 10 f0       	push   $0xf0104a90
f0101ee6:	e8 b5 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eeb:	83 ec 0c             	sub    $0xc,%esp
f0101eee:	6a 00                	push   $0x0
f0101ef0:	e8 95 ee ff ff       	call   f0100d8a <page_alloc>
f0101ef5:	83 c4 10             	add    $0x10,%esp
f0101ef8:	85 c0                	test   %eax,%eax
f0101efa:	74 19                	je     f0101f15 <mem_init+0xec1>
f0101efc:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101f01:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101f06:	68 92 03 00 00       	push   $0x392
f0101f0b:	68 90 4a 10 f0       	push   $0xf0104a90
f0101f10:	e8 8b e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f15:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0101f1b:	8b 11                	mov    (%ecx),%edx
f0101f1d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f23:	89 f0                	mov    %esi,%eax
f0101f25:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101f2b:	c1 f8 03             	sar    $0x3,%eax
f0101f2e:	c1 e0 0c             	shl    $0xc,%eax
f0101f31:	39 c2                	cmp    %eax,%edx
f0101f33:	74 19                	je     f0101f4e <mem_init+0xefa>
f0101f35:	68 a0 50 10 f0       	push   $0xf01050a0
f0101f3a:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101f3f:	68 95 03 00 00       	push   $0x395
f0101f44:	68 90 4a 10 f0       	push   $0xf0104a90
f0101f49:	e8 52 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f4e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f54:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f59:	74 19                	je     f0101f74 <mem_init+0xf20>
f0101f5b:	68 cd 4c 10 f0       	push   $0xf0104ccd
f0101f60:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101f65:	68 97 03 00 00       	push   $0x397
f0101f6a:	68 90 4a 10 f0       	push   $0xf0104a90
f0101f6f:	e8 2c e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f74:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f7a:	83 ec 0c             	sub    $0xc,%esp
f0101f7d:	56                   	push   %esi
f0101f7e:	e8 71 ee ff ff       	call   f0100df4 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f83:	83 c4 0c             	add    $0xc,%esp
f0101f86:	6a 01                	push   $0x1
f0101f88:	68 00 10 40 00       	push   $0x401000
f0101f8d:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101f93:	e8 92 ee ff ff       	call   f0100e2a <pgdir_walk>
f0101f98:	89 c7                	mov    %eax,%edi
f0101f9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f9d:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101fa2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fa5:	8b 40 04             	mov    0x4(%eax),%eax
f0101fa8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fad:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0101fb3:	89 c2                	mov    %eax,%edx
f0101fb5:	c1 ea 0c             	shr    $0xc,%edx
f0101fb8:	83 c4 10             	add    $0x10,%esp
f0101fbb:	39 ca                	cmp    %ecx,%edx
f0101fbd:	72 15                	jb     f0101fd4 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbf:	50                   	push   %eax
f0101fc0:	68 04 4e 10 f0       	push   $0xf0104e04
f0101fc5:	68 9e 03 00 00       	push   $0x39e
f0101fca:	68 90 4a 10 f0       	push   $0xf0104a90
f0101fcf:	e8 cc e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fd4:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fd9:	39 c7                	cmp    %eax,%edi
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xfa2>
f0101fdd:	68 64 4d 10 f0       	push   $0xf0104d64
f0101fe2:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0101fe7:	68 9f 03 00 00       	push   $0x39f
f0101fec:	68 90 4a 10 f0       	push   $0xf0104a90
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ff6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ff9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102000:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102006:	89 f0                	mov    %esi,%eax
f0102008:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010200e:	c1 f8 03             	sar    $0x3,%eax
f0102011:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102014:	89 c2                	mov    %eax,%edx
f0102016:	c1 ea 0c             	shr    $0xc,%edx
f0102019:	39 d1                	cmp    %edx,%ecx
f010201b:	77 12                	ja     f010202f <mem_init+0xfdb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010201d:	50                   	push   %eax
f010201e:	68 04 4e 10 f0       	push   $0xf0104e04
f0102023:	6a 56                	push   $0x56
f0102025:	68 9c 4a 10 f0       	push   $0xf0104a9c
f010202a:	e8 71 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010202f:	83 ec 04             	sub    $0x4,%esp
f0102032:	68 00 10 00 00       	push   $0x1000
f0102037:	68 ff 00 00 00       	push   $0xff
f010203c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102041:	50                   	push   %eax
f0102042:	e8 59 20 00 00       	call   f01040a0 <memset>
	page_free(pp0);
f0102047:	89 34 24             	mov    %esi,(%esp)
f010204a:	e8 a5 ed ff ff       	call   f0100df4 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010204f:	83 c4 0c             	add    $0xc,%esp
f0102052:	6a 01                	push   $0x1
f0102054:	6a 00                	push   $0x0
f0102056:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010205c:	e8 c9 ed ff ff       	call   f0100e2a <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102061:	89 f2                	mov    %esi,%edx
f0102063:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0102069:	c1 fa 03             	sar    $0x3,%edx
f010206c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010206f:	89 d0                	mov    %edx,%eax
f0102071:	c1 e8 0c             	shr    $0xc,%eax
f0102074:	83 c4 10             	add    $0x10,%esp
f0102077:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f010207d:	72 12                	jb     f0102091 <mem_init+0x103d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010207f:	52                   	push   %edx
f0102080:	68 04 4e 10 f0       	push   $0xf0104e04
f0102085:	6a 56                	push   $0x56
f0102087:	68 9c 4a 10 f0       	push   $0xf0104a9c
f010208c:	e8 0f e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102091:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102097:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010209a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020a0:	f6 00 01             	testb  $0x1,(%eax)
f01020a3:	74 19                	je     f01020be <mem_init+0x106a>
f01020a5:	68 7c 4d 10 f0       	push   $0xf0104d7c
f01020aa:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01020af:	68 a9 03 00 00       	push   $0x3a9
f01020b4:	68 90 4a 10 f0       	push   $0xf0104a90
f01020b9:	e8 e2 df ff ff       	call   f01000a0 <_panic>
f01020be:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020c1:	39 c2                	cmp    %eax,%edx
f01020c3:	75 db                	jne    f01020a0 <mem_init+0x104c>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020c5:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01020d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020d9:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f01020de:	83 ec 0c             	sub    $0xc,%esp
f01020e1:	56                   	push   %esi
f01020e2:	e8 0d ed ff ff       	call   f0100df4 <page_free>
	page_free(pp1);
f01020e7:	83 c4 04             	add    $0x4,%esp
f01020ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01020ed:	e8 02 ed ff ff       	call   f0100df4 <page_free>
	page_free(pp2);
f01020f2:	89 1c 24             	mov    %ebx,(%esp)
f01020f5:	e8 fa ec ff ff       	call   f0100df4 <page_free>

	cprintf("check_page() succeeded!\n");
f01020fa:	c7 04 24 93 4d 10 f0 	movl   $0xf0104d93,(%esp)
f0102101:	e8 b0 0d 00 00       	call   f0102eb6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f0102106:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210b:	83 c4 10             	add    $0x10,%esp
f010210e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102113:	77 15                	ja     f010212a <mem_init+0x10d6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102115:	50                   	push   %eax
f0102116:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010211b:	68 c0 00 00 00       	push   $0xc0
f0102120:	68 90 4a 10 f0       	push   $0xf0104a90
f0102125:	e8 76 df ff ff       	call   f01000a0 <_panic>
f010212a:	83 ec 08             	sub    $0x8,%esp
f010212d:	6a 04                	push   $0x4
f010212f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102134:	50                   	push   %eax
f0102135:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010213a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010213f:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102144:	e8 74 ed ff ff       	call   f0100ebd <boot_map_region>
		UPAGES, 
		PTSIZE, 
		PADDR(pages), 
		PTE_U);
	cprintf("PADDR(pages) %x\n", PADDR(pages));
f0102149:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010214e:	83 c4 10             	add    $0x10,%esp
f0102151:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102156:	77 15                	ja     f010216d <mem_init+0x1119>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102158:	50                   	push   %eax
f0102159:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010215e:	68 c2 00 00 00       	push   $0xc2
f0102163:	68 90 4a 10 f0       	push   $0xf0104a90
f0102168:	e8 33 df ff ff       	call   f01000a0 <_panic>
f010216d:	83 ec 08             	sub    $0x8,%esp
f0102170:	05 00 00 00 10       	add    $0x10000000,%eax
f0102175:	50                   	push   %eax
f0102176:	68 ac 4d 10 f0       	push   $0xf0104dac
f010217b:	e8 36 0d 00 00       	call   f0102eb6 <cprintf>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,
f0102180:	a1 48 be 17 f0       	mov    0xf017be48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102185:	83 c4 10             	add    $0x10,%esp
f0102188:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010218d:	77 15                	ja     f01021a4 <mem_init+0x1150>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010218f:	50                   	push   %eax
f0102190:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102195:	68 cd 00 00 00       	push   $0xcd
f010219a:	68 90 4a 10 f0       	push   $0xf0104a90
f010219f:	e8 fc de ff ff       	call   f01000a0 <_panic>
f01021a4:	83 ec 08             	sub    $0x8,%esp
f01021a7:	6a 04                	push   $0x4
f01021a9:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ae:	50                   	push   %eax
f01021af:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021b4:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021b9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01021be:	e8 fa ec ff ff       	call   f0100ebd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c3:	83 c4 10             	add    $0x10,%esp
f01021c6:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01021cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d0:	77 15                	ja     f01021e7 <mem_init+0x1193>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d2:	50                   	push   %eax
f01021d3:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01021d8:	68 df 00 00 00       	push   $0xdf
f01021dd:	68 90 4a 10 f0       	push   $0xf0104a90
f01021e2:	e8 b9 de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f01021e7:	83 ec 08             	sub    $0x8,%esp
f01021ea:	6a 02                	push   $0x2
f01021ec:	68 00 00 11 00       	push   $0x110000
f01021f1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021f6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021fb:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102200:	e8 b8 ec ff ff       	call   f0100ebd <boot_map_region>
		KSTACKTOP-KSTKSIZE, 
		KSTKSIZE, 
		PADDR(bootstack), 
		PTE_W);
	cprintf("PADDR(bootstack) %x\n", PADDR(bootstack));
f0102205:	83 c4 08             	add    $0x8,%esp
f0102208:	68 00 00 11 00       	push   $0x110000
f010220d:	68 bd 4d 10 f0       	push   $0xf0104dbd
f0102212:	e8 9f 0c 00 00       	call   f0102eb6 <cprintf>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f0102217:	83 c4 08             	add    $0x8,%esp
f010221a:	6a 02                	push   $0x2
f010221c:	6a 00                	push   $0x0
f010221e:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102223:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102228:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010222d:	e8 8b ec ff ff       	call   f0100ebd <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102232:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102238:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f010223d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102240:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102247:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010224c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010224f:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102255:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102258:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010225b:	be 00 00 00 00       	mov    $0x0,%esi
f0102260:	eb 55                	jmp    f01022b7 <mem_init+0x1263>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102262:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102268:	89 d8                	mov    %ebx,%eax
f010226a:	e8 0a e7 ff ff       	call   f0100979 <check_va2pa>
f010226f:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102276:	77 15                	ja     f010228d <mem_init+0x1239>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102278:	57                   	push   %edi
f0102279:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010227e:	68 e8 02 00 00       	push   $0x2e8
f0102283:	68 90 4a 10 f0       	push   $0xf0104a90
f0102288:	e8 13 de ff ff       	call   f01000a0 <_panic>
f010228d:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102294:	39 d0                	cmp    %edx,%eax
f0102296:	74 19                	je     f01022b1 <mem_init+0x125d>
f0102298:	68 e8 53 10 f0       	push   $0xf01053e8
f010229d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01022a2:	68 e8 02 00 00       	push   $0x2e8
f01022a7:	68 90 4a 10 f0       	push   $0xf0104a90
f01022ac:	e8 ef dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022b1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022b7:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022ba:	77 a6                	ja     f0102262 <mem_init+0x120e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022bc:	8b 3d 48 be 17 f0    	mov    0xf017be48,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022c2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022c5:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022ca:	89 f2                	mov    %esi,%edx
f01022cc:	89 d8                	mov    %ebx,%eax
f01022ce:	e8 a6 e6 ff ff       	call   f0100979 <check_va2pa>
f01022d3:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01022da:	77 15                	ja     f01022f1 <mem_init+0x129d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022dc:	57                   	push   %edi
f01022dd:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01022e2:	68 ed 02 00 00       	push   $0x2ed
f01022e7:	68 90 4a 10 f0       	push   $0xf0104a90
f01022ec:	e8 af dd ff ff       	call   f01000a0 <_panic>
f01022f1:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022f8:	39 c2                	cmp    %eax,%edx
f01022fa:	74 19                	je     f0102315 <mem_init+0x12c1>
f01022fc:	68 1c 54 10 f0       	push   $0xf010541c
f0102301:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102306:	68 ed 02 00 00       	push   $0x2ed
f010230b:	68 90 4a 10 f0       	push   $0xf0104a90
f0102310:	e8 8b dd ff ff       	call   f01000a0 <_panic>
f0102315:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010231b:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102321:	75 a7                	jne    f01022ca <mem_init+0x1276>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102323:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102326:	c1 e7 0c             	shl    $0xc,%edi
f0102329:	be 00 00 00 00       	mov    $0x0,%esi
f010232e:	eb 30                	jmp    f0102360 <mem_init+0x130c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102330:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102336:	89 d8                	mov    %ebx,%eax
f0102338:	e8 3c e6 ff ff       	call   f0100979 <check_va2pa>
f010233d:	39 c6                	cmp    %eax,%esi
f010233f:	74 19                	je     f010235a <mem_init+0x1306>
f0102341:	68 50 54 10 f0       	push   $0xf0105450
f0102346:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010234b:	68 f1 02 00 00       	push   $0x2f1
f0102350:	68 90 4a 10 f0       	push   $0xf0104a90
f0102355:	e8 46 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010235a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102360:	39 fe                	cmp    %edi,%esi
f0102362:	72 cc                	jb     f0102330 <mem_init+0x12dc>
f0102364:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102369:	89 f2                	mov    %esi,%edx
f010236b:	89 d8                	mov    %ebx,%eax
f010236d:	e8 07 e6 ff ff       	call   f0100979 <check_va2pa>
f0102372:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102378:	39 c2                	cmp    %eax,%edx
f010237a:	74 19                	je     f0102395 <mem_init+0x1341>
f010237c:	68 78 54 10 f0       	push   $0xf0105478
f0102381:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102386:	68 f5 02 00 00       	push   $0x2f5
f010238b:	68 90 4a 10 f0       	push   $0xf0104a90
f0102390:	e8 0b dd ff ff       	call   f01000a0 <_panic>
f0102395:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010239b:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023a1:	75 c6                	jne    f0102369 <mem_init+0x1315>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023a3:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023a8:	89 d8                	mov    %ebx,%eax
f01023aa:	e8 ca e5 ff ff       	call   f0100979 <check_va2pa>
f01023af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023b2:	74 51                	je     f0102405 <mem_init+0x13b1>
f01023b4:	68 c0 54 10 f0       	push   $0xf01054c0
f01023b9:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01023be:	68 f6 02 00 00       	push   $0x2f6
f01023c3:	68 90 4a 10 f0       	push   $0xf0104a90
f01023c8:	e8 d3 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023cd:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023d2:	72 36                	jb     f010240a <mem_init+0x13b6>
f01023d4:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023d9:	76 07                	jbe    f01023e2 <mem_init+0x138e>
f01023db:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023e0:	75 28                	jne    f010240a <mem_init+0x13b6>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01023e2:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01023e6:	0f 85 83 00 00 00    	jne    f010246f <mem_init+0x141b>
f01023ec:	68 d2 4d 10 f0       	push   $0xf0104dd2
f01023f1:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01023f6:	68 ff 02 00 00       	push   $0x2ff
f01023fb:	68 90 4a 10 f0       	push   $0xf0104a90
f0102400:	e8 9b dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102405:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010240a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010240f:	76 3f                	jbe    f0102450 <mem_init+0x13fc>
				assert(pgdir[i] & PTE_P);
f0102411:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102414:	f6 c2 01             	test   $0x1,%dl
f0102417:	75 19                	jne    f0102432 <mem_init+0x13de>
f0102419:	68 d2 4d 10 f0       	push   $0xf0104dd2
f010241e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102423:	68 03 03 00 00       	push   $0x303
f0102428:	68 90 4a 10 f0       	push   $0xf0104a90
f010242d:	e8 6e dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102432:	f6 c2 02             	test   $0x2,%dl
f0102435:	75 38                	jne    f010246f <mem_init+0x141b>
f0102437:	68 e3 4d 10 f0       	push   $0xf0104de3
f010243c:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102441:	68 04 03 00 00       	push   $0x304
f0102446:	68 90 4a 10 f0       	push   $0xf0104a90
f010244b:	e8 50 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102450:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102454:	74 19                	je     f010246f <mem_init+0x141b>
f0102456:	68 f4 4d 10 f0       	push   $0xf0104df4
f010245b:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102460:	68 06 03 00 00       	push   $0x306
f0102465:	68 90 4a 10 f0       	push   $0xf0104a90
f010246a:	e8 31 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010246f:	83 c0 01             	add    $0x1,%eax
f0102472:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102477:	0f 86 50 ff ff ff    	jbe    f01023cd <mem_init+0x1379>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010247d:	83 ec 0c             	sub    $0xc,%esp
f0102480:	68 f0 54 10 f0       	push   $0xf01054f0
f0102485:	e8 2c 0a 00 00       	call   f0102eb6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010248a:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010248f:	83 c4 10             	add    $0x10,%esp
f0102492:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102497:	77 15                	ja     f01024ae <mem_init+0x145a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102499:	50                   	push   %eax
f010249a:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010249f:	68 fd 00 00 00       	push   $0xfd
f01024a4:	68 90 4a 10 f0       	push   $0xf0104a90
f01024a9:	e8 f2 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024ae:	05 00 00 00 10       	add    $0x10000000,%eax
f01024b3:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01024bb:	e8 1d e5 ff ff       	call   f01009dd <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01024c0:	0f 20 c0             	mov    %cr0,%eax
f01024c3:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01024c6:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024cb:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024ce:	83 ec 0c             	sub    $0xc,%esp
f01024d1:	6a 00                	push   $0x0
f01024d3:	e8 b2 e8 ff ff       	call   f0100d8a <page_alloc>
f01024d8:	89 c3                	mov    %eax,%ebx
f01024da:	83 c4 10             	add    $0x10,%esp
f01024dd:	85 c0                	test   %eax,%eax
f01024df:	75 19                	jne    f01024fa <mem_init+0x14a6>
f01024e1:	68 af 4b 10 f0       	push   $0xf0104baf
f01024e6:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01024eb:	68 c4 03 00 00       	push   $0x3c4
f01024f0:	68 90 4a 10 f0       	push   $0xf0104a90
f01024f5:	e8 a6 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024fa:	83 ec 0c             	sub    $0xc,%esp
f01024fd:	6a 00                	push   $0x0
f01024ff:	e8 86 e8 ff ff       	call   f0100d8a <page_alloc>
f0102504:	89 c7                	mov    %eax,%edi
f0102506:	83 c4 10             	add    $0x10,%esp
f0102509:	85 c0                	test   %eax,%eax
f010250b:	75 19                	jne    f0102526 <mem_init+0x14d2>
f010250d:	68 c5 4b 10 f0       	push   $0xf0104bc5
f0102512:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102517:	68 c5 03 00 00       	push   $0x3c5
f010251c:	68 90 4a 10 f0       	push   $0xf0104a90
f0102521:	e8 7a db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102526:	83 ec 0c             	sub    $0xc,%esp
f0102529:	6a 00                	push   $0x0
f010252b:	e8 5a e8 ff ff       	call   f0100d8a <page_alloc>
f0102530:	89 c6                	mov    %eax,%esi
f0102532:	83 c4 10             	add    $0x10,%esp
f0102535:	85 c0                	test   %eax,%eax
f0102537:	75 19                	jne    f0102552 <mem_init+0x14fe>
f0102539:	68 db 4b 10 f0       	push   $0xf0104bdb
f010253e:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102543:	68 c6 03 00 00       	push   $0x3c6
f0102548:	68 90 4a 10 f0       	push   $0xf0104a90
f010254d:	e8 4e db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102552:	83 ec 0c             	sub    $0xc,%esp
f0102555:	53                   	push   %ebx
f0102556:	e8 99 e8 ff ff       	call   f0100df4 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010255b:	89 f8                	mov    %edi,%eax
f010255d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102563:	c1 f8 03             	sar    $0x3,%eax
f0102566:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102569:	89 c2                	mov    %eax,%edx
f010256b:	c1 ea 0c             	shr    $0xc,%edx
f010256e:	83 c4 10             	add    $0x10,%esp
f0102571:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102577:	72 12                	jb     f010258b <mem_init+0x1537>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102579:	50                   	push   %eax
f010257a:	68 04 4e 10 f0       	push   $0xf0104e04
f010257f:	6a 56                	push   $0x56
f0102581:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0102586:	e8 15 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010258b:	83 ec 04             	sub    $0x4,%esp
f010258e:	68 00 10 00 00       	push   $0x1000
f0102593:	6a 01                	push   $0x1
f0102595:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010259a:	50                   	push   %eax
f010259b:	e8 00 1b 00 00       	call   f01040a0 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025a0:	89 f0                	mov    %esi,%eax
f01025a2:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01025a8:	c1 f8 03             	sar    $0x3,%eax
f01025ab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025ae:	89 c2                	mov    %eax,%edx
f01025b0:	c1 ea 0c             	shr    $0xc,%edx
f01025b3:	83 c4 10             	add    $0x10,%esp
f01025b6:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01025bc:	72 12                	jb     f01025d0 <mem_init+0x157c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025be:	50                   	push   %eax
f01025bf:	68 04 4e 10 f0       	push   $0xf0104e04
f01025c4:	6a 56                	push   $0x56
f01025c6:	68 9c 4a 10 f0       	push   $0xf0104a9c
f01025cb:	e8 d0 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025d0:	83 ec 04             	sub    $0x4,%esp
f01025d3:	68 00 10 00 00       	push   $0x1000
f01025d8:	6a 02                	push   $0x2
f01025da:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025df:	50                   	push   %eax
f01025e0:	e8 bb 1a 00 00       	call   f01040a0 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025e5:	6a 02                	push   $0x2
f01025e7:	68 00 10 00 00       	push   $0x1000
f01025ec:	57                   	push   %edi
f01025ed:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01025f3:	e8 f6 e9 ff ff       	call   f0100fee <page_insert>
	assert(pp1->pp_ref == 1);
f01025f8:	83 c4 20             	add    $0x20,%esp
f01025fb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102600:	74 19                	je     f010261b <mem_init+0x15c7>
f0102602:	68 bc 4c 10 f0       	push   $0xf0104cbc
f0102607:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010260c:	68 cb 03 00 00       	push   $0x3cb
f0102611:	68 90 4a 10 f0       	push   $0xf0104a90
f0102616:	e8 85 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010261b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102622:	01 01 01 
f0102625:	74 19                	je     f0102640 <mem_init+0x15ec>
f0102627:	68 10 55 10 f0       	push   $0xf0105510
f010262c:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102631:	68 cc 03 00 00       	push   $0x3cc
f0102636:	68 90 4a 10 f0       	push   $0xf0104a90
f010263b:	e8 60 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102640:	6a 02                	push   $0x2
f0102642:	68 00 10 00 00       	push   $0x1000
f0102647:	56                   	push   %esi
f0102648:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010264e:	e8 9b e9 ff ff       	call   f0100fee <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102653:	83 c4 10             	add    $0x10,%esp
f0102656:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010265d:	02 02 02 
f0102660:	74 19                	je     f010267b <mem_init+0x1627>
f0102662:	68 34 55 10 f0       	push   $0xf0105534
f0102667:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010266c:	68 ce 03 00 00       	push   $0x3ce
f0102671:	68 90 4a 10 f0       	push   $0xf0104a90
f0102676:	e8 25 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010267b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102680:	74 19                	je     f010269b <mem_init+0x1647>
f0102682:	68 de 4c 10 f0       	push   $0xf0104cde
f0102687:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010268c:	68 cf 03 00 00       	push   $0x3cf
f0102691:	68 90 4a 10 f0       	push   $0xf0104a90
f0102696:	e8 05 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010269b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026a0:	74 19                	je     f01026bb <mem_init+0x1667>
f01026a2:	68 53 4d 10 f0       	push   $0xf0104d53
f01026a7:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01026ac:	68 d0 03 00 00       	push   $0x3d0
f01026b1:	68 90 4a 10 f0       	push   $0xf0104a90
f01026b6:	e8 e5 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026bb:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026c2:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026c5:	89 f0                	mov    %esi,%eax
f01026c7:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01026cd:	c1 f8 03             	sar    $0x3,%eax
f01026d0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026d3:	89 c2                	mov    %eax,%edx
f01026d5:	c1 ea 0c             	shr    $0xc,%edx
f01026d8:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01026de:	72 12                	jb     f01026f2 <mem_init+0x169e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026e0:	50                   	push   %eax
f01026e1:	68 04 4e 10 f0       	push   $0xf0104e04
f01026e6:	6a 56                	push   $0x56
f01026e8:	68 9c 4a 10 f0       	push   $0xf0104a9c
f01026ed:	e8 ae d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026f2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026f9:	03 03 03 
f01026fc:	74 19                	je     f0102717 <mem_init+0x16c3>
f01026fe:	68 58 55 10 f0       	push   $0xf0105558
f0102703:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102708:	68 d2 03 00 00       	push   $0x3d2
f010270d:	68 90 4a 10 f0       	push   $0xf0104a90
f0102712:	e8 89 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102717:	83 ec 08             	sub    $0x8,%esp
f010271a:	68 00 10 00 00       	push   $0x1000
f010271f:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102725:	e8 81 e8 ff ff       	call   f0100fab <page_remove>
	assert(pp2->pp_ref == 0);
f010272a:	83 c4 10             	add    $0x10,%esp
f010272d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102732:	74 19                	je     f010274d <mem_init+0x16f9>
f0102734:	68 42 4d 10 f0       	push   $0xf0104d42
f0102739:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010273e:	68 d4 03 00 00       	push   $0x3d4
f0102743:	68 90 4a 10 f0       	push   $0xf0104a90
f0102748:	e8 53 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010274d:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0102753:	8b 11                	mov    (%ecx),%edx
f0102755:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010275b:	89 d8                	mov    %ebx,%eax
f010275d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102763:	c1 f8 03             	sar    $0x3,%eax
f0102766:	c1 e0 0c             	shl    $0xc,%eax
f0102769:	39 c2                	cmp    %eax,%edx
f010276b:	74 19                	je     f0102786 <mem_init+0x1732>
f010276d:	68 a0 50 10 f0       	push   $0xf01050a0
f0102772:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0102777:	68 d7 03 00 00       	push   $0x3d7
f010277c:	68 90 4a 10 f0       	push   $0xf0104a90
f0102781:	e8 1a d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102786:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010278c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102791:	74 19                	je     f01027ac <mem_init+0x1758>
f0102793:	68 cd 4c 10 f0       	push   $0xf0104ccd
f0102798:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010279d:	68 d9 03 00 00       	push   $0x3d9
f01027a2:	68 90 4a 10 f0       	push   $0xf0104a90
f01027a7:	e8 f4 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027ac:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027b2:	83 ec 0c             	sub    $0xc,%esp
f01027b5:	53                   	push   %ebx
f01027b6:	e8 39 e6 ff ff       	call   f0100df4 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027bb:	c7 04 24 84 55 10 f0 	movl   $0xf0105584,(%esp)
f01027c2:	e8 ef 06 00 00       	call   f0102eb6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027c7:	83 c4 10             	add    $0x10,%esp
f01027ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027cd:	5b                   	pop    %ebx
f01027ce:	5e                   	pop    %esi
f01027cf:	5f                   	pop    %edi
f01027d0:	5d                   	pop    %ebp
f01027d1:	c3                   	ret    

f01027d2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027d2:	55                   	push   %ebp
f01027d3:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027d8:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027db:	5d                   	pop    %ebp
f01027dc:	c3                   	ret    

f01027dd <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01027dd:	55                   	push   %ebp
f01027de:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01027e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01027e5:	5d                   	pop    %ebp
f01027e6:	c3                   	ret    

f01027e7 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01027e7:	55                   	push   %ebp
f01027e8:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01027ea:	5d                   	pop    %ebp
f01027eb:	c3                   	ret    

f01027ec <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027ec:	55                   	push   %ebp
f01027ed:	89 e5                	mov    %esp,%ebp
f01027ef:	57                   	push   %edi
f01027f0:	56                   	push   %esi
f01027f1:	53                   	push   %ebx
f01027f2:	83 ec 0c             	sub    $0xc,%esp
f01027f5:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
f01027f7:	89 d3                	mov    %edx,%ebx
f01027f9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01027ff:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102806:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (; begin < end; begin += PGSIZE) {
f010280c:	eb 3d                	jmp    f010284b <region_alloc+0x5f>
		struct PageInfo *pg = page_alloc(0);
f010280e:	83 ec 0c             	sub    $0xc,%esp
f0102811:	6a 00                	push   $0x0
f0102813:	e8 72 e5 ff ff       	call   f0100d8a <page_alloc>
		if (!pg) panic("region_alloc failed!");
f0102818:	83 c4 10             	add    $0x10,%esp
f010281b:	85 c0                	test   %eax,%eax
f010281d:	75 17                	jne    f0102836 <region_alloc+0x4a>
f010281f:	83 ec 04             	sub    $0x4,%esp
f0102822:	68 ad 55 10 f0       	push   $0xf01055ad
f0102827:	68 15 01 00 00       	push   $0x115
f010282c:	68 c2 55 10 f0       	push   $0xf01055c2
f0102831:	e8 6a d8 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, pg, begin, PTE_W | PTE_U);
f0102836:	6a 06                	push   $0x6
f0102838:	53                   	push   %ebx
f0102839:	50                   	push   %eax
f010283a:	ff 77 5c             	pushl  0x5c(%edi)
f010283d:	e8 ac e7 ff ff       	call   f0100fee <page_insert>
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
	for (; begin < end; begin += PGSIZE) {
f0102842:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102848:	83 c4 10             	add    $0x10,%esp
f010284b:	39 f3                	cmp    %esi,%ebx
f010284d:	72 bf                	jb     f010280e <region_alloc+0x22>
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f010284f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102852:	5b                   	pop    %ebx
f0102853:	5e                   	pop    %esi
f0102854:	5f                   	pop    %edi
f0102855:	5d                   	pop    %ebp
f0102856:	c3                   	ret    

f0102857 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102857:	55                   	push   %ebp
f0102858:	89 e5                	mov    %esp,%ebp
f010285a:	8b 55 08             	mov    0x8(%ebp),%edx
f010285d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102860:	85 d2                	test   %edx,%edx
f0102862:	75 11                	jne    f0102875 <envid2env+0x1e>
		*env_store = curenv;
f0102864:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102869:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010286c:	89 01                	mov    %eax,(%ecx)
		return 0;
f010286e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102873:	eb 5e                	jmp    f01028d3 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102875:	89 d0                	mov    %edx,%eax
f0102877:	25 ff 03 00 00       	and    $0x3ff,%eax
f010287c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010287f:	c1 e0 05             	shl    $0x5,%eax
f0102882:	03 05 48 be 17 f0    	add    0xf017be48,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102888:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010288c:	74 05                	je     f0102893 <envid2env+0x3c>
f010288e:	3b 50 48             	cmp    0x48(%eax),%edx
f0102891:	74 10                	je     f01028a3 <envid2env+0x4c>
		*env_store = 0;
f0102893:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102896:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010289c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028a1:	eb 30                	jmp    f01028d3 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01028a3:	84 c9                	test   %cl,%cl
f01028a5:	74 22                	je     f01028c9 <envid2env+0x72>
f01028a7:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f01028ad:	39 d0                	cmp    %edx,%eax
f01028af:	74 18                	je     f01028c9 <envid2env+0x72>
f01028b1:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028b4:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028b7:	74 10                	je     f01028c9 <envid2env+0x72>
		*env_store = 0;
f01028b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028c2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028c7:	eb 0a                	jmp    f01028d3 <envid2env+0x7c>
	}

	*env_store = e;
f01028c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028cc:	89 01                	mov    %eax,(%ecx)
	return 0;
f01028ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028d3:	5d                   	pop    %ebp
f01028d4:	c3                   	ret    

f01028d5 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01028d5:	55                   	push   %ebp
f01028d6:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01028d8:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01028dd:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01028e0:	b8 23 00 00 00       	mov    $0x23,%eax
f01028e5:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01028e7:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01028e9:	b8 10 00 00 00       	mov    $0x10,%eax
f01028ee:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01028f0:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01028f2:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01028f4:	ea fb 28 10 f0 08 00 	ljmp   $0x8,$0xf01028fb
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01028fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102900:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102903:	5d                   	pop    %ebp
f0102904:	c3                   	ret    

f0102905 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102905:	55                   	push   %ebp
f0102906:	89 e5                	mov    %esp,%ebp
f0102908:	56                   	push   %esi
f0102909:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV-1;i >= 0; --i) {
		envs[i].env_id = 0;
f010290a:	8b 35 48 be 17 f0    	mov    0xf017be48,%esi
f0102910:	8b 15 4c be 17 f0    	mov    0xf017be4c,%edx
f0102916:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010291c:	8d 5e a0             	lea    -0x60(%esi),%ebx
f010291f:	89 c1                	mov    %eax,%ecx
f0102921:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102928:	89 50 44             	mov    %edx,0x44(%eax)
f010292b:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs+i;
f010292e:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV-1;i >= 0; --i) {
f0102930:	39 d8                	cmp    %ebx,%eax
f0102932:	75 eb                	jne    f010291f <env_init+0x1a>
f0102934:	89 35 4c be 17 f0    	mov    %esi,0xf017be4c
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = envs+i;
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f010293a:	e8 96 ff ff ff       	call   f01028d5 <env_init_percpu>
}
f010293f:	5b                   	pop    %ebx
f0102940:	5e                   	pop    %esi
f0102941:	5d                   	pop    %ebp
f0102942:	c3                   	ret    

f0102943 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102943:	55                   	push   %ebp
f0102944:	89 e5                	mov    %esp,%ebp
f0102946:	53                   	push   %ebx
f0102947:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010294a:	8b 1d 4c be 17 f0    	mov    0xf017be4c,%ebx
f0102950:	85 db                	test   %ebx,%ebx
f0102952:	0f 84 62 01 00 00    	je     f0102aba <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102958:	83 ec 0c             	sub    $0xc,%esp
f010295b:	6a 01                	push   $0x1
f010295d:	e8 28 e4 ff ff       	call   f0100d8a <page_alloc>
f0102962:	83 c4 10             	add    $0x10,%esp
f0102965:	85 c0                	test   %eax,%eax
f0102967:	0f 84 54 01 00 00    	je     f0102ac1 <env_alloc+0x17e>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010296d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102972:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102978:	c1 f8 03             	sar    $0x3,%eax
f010297b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010297e:	89 c2                	mov    %eax,%edx
f0102980:	c1 ea 0c             	shr    $0xc,%edx
f0102983:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102989:	72 12                	jb     f010299d <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010298b:	50                   	push   %eax
f010298c:	68 04 4e 10 f0       	push   $0xf0104e04
f0102991:	6a 56                	push   $0x56
f0102993:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0102998:	e8 03 d7 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010299d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f01029a2:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f01029a5:	83 ec 04             	sub    $0x4,%esp
f01029a8:	68 00 10 00 00       	push   $0x1000
f01029ad:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01029b3:	50                   	push   %eax
f01029b4:	e8 9c 17 00 00       	call   f0104155 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029b9:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029bc:	83 c4 10             	add    $0x10,%esp
f01029bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029c4:	77 15                	ja     f01029db <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029c6:	50                   	push   %eax
f01029c7:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01029cc:	68 c1 00 00 00       	push   $0xc1
f01029d1:	68 c2 55 10 f0       	push   $0xf01055c2
f01029d6:	e8 c5 d6 ff ff       	call   f01000a0 <_panic>
f01029db:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029e1:	83 ca 05             	or     $0x5,%edx
f01029e4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029ea:	8b 43 48             	mov    0x48(%ebx),%eax
f01029ed:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029f2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029f7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029fc:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029ff:	8b 0d 48 be 17 f0    	mov    0xf017be48,%ecx
f0102a05:	89 da                	mov    %ebx,%edx
f0102a07:	29 ca                	sub    %ecx,%edx
f0102a09:	c1 fa 05             	sar    $0x5,%edx
f0102a0c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a12:	09 d0                	or     %edx,%eax
f0102a14:	89 43 48             	mov    %eax,0x48(%ebx)
	cprintf("envs: %x, e: %x, e->env_id: %x\n", envs, e, e->env_id);
f0102a17:	50                   	push   %eax
f0102a18:	53                   	push   %ebx
f0102a19:	51                   	push   %ecx
f0102a1a:	68 3c 56 10 f0       	push   $0xf010563c
f0102a1f:	e8 92 04 00 00       	call   f0102eb6 <cprintf>

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a27:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a2a:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a31:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a38:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a3f:	83 c4 0c             	add    $0xc,%esp
f0102a42:	6a 44                	push   $0x44
f0102a44:	6a 00                	push   $0x0
f0102a46:	53                   	push   %ebx
f0102a47:	e8 54 16 00 00       	call   f01040a0 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a4c:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a52:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a58:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a5e:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a65:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a6b:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a6e:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	*newenv_store = e;
f0102a73:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a76:	89 18                	mov    %ebx,(%eax)

	cprintf("env_id, %x\n", e->env_id);
f0102a78:	83 c4 08             	add    $0x8,%esp
f0102a7b:	ff 73 48             	pushl  0x48(%ebx)
f0102a7e:	68 cd 55 10 f0       	push   $0xf01055cd
f0102a83:	e8 2e 04 00 00       	call   f0102eb6 <cprintf>
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a88:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a8b:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102a90:	83 c4 10             	add    $0x10,%esp
f0102a93:	85 c0                	test   %eax,%eax
f0102a95:	74 05                	je     f0102a9c <env_alloc+0x159>
f0102a97:	8b 40 48             	mov    0x48(%eax),%eax
f0102a9a:	eb 05                	jmp    f0102aa1 <env_alloc+0x15e>
f0102a9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aa1:	83 ec 04             	sub    $0x4,%esp
f0102aa4:	52                   	push   %edx
f0102aa5:	50                   	push   %eax
f0102aa6:	68 d9 55 10 f0       	push   $0xf01055d9
f0102aab:	e8 06 04 00 00       	call   f0102eb6 <cprintf>
	return 0;
f0102ab0:	83 c4 10             	add    $0x10,%esp
f0102ab3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ab8:	eb 0c                	jmp    f0102ac6 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102aba:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102abf:	eb 05                	jmp    f0102ac6 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102ac1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*newenv_store = e;

	cprintf("env_id, %x\n", e->env_id);
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102ac6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ac9:	c9                   	leave  
f0102aca:	c3                   	ret    

f0102acb <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102acb:	55                   	push   %ebp
f0102acc:	89 e5                	mov    %esp,%ebp
f0102ace:	57                   	push   %edi
f0102acf:	56                   	push   %esi
f0102ad0:	53                   	push   %ebx
f0102ad1:	83 ec 34             	sub    $0x34,%esp
f0102ad4:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
f0102ad7:	6a 00                	push   $0x0
f0102ad9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102adc:	50                   	push   %eax
f0102add:	e8 61 fe ff ff       	call   f0102943 <env_alloc>
	load_icode(penv, binary);
f0102ae2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ae5:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;

	if (ELFHDR->e_magic != ELF_MAGIC)
f0102ae8:	83 c4 10             	add    $0x10,%esp
f0102aeb:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102af1:	74 17                	je     f0102b0a <env_create+0x3f>
		panic("Not executable!");
f0102af3:	83 ec 04             	sub    $0x4,%esp
f0102af6:	68 ee 55 10 f0       	push   $0xf01055ee
f0102afb:	68 52 01 00 00       	push   $0x152
f0102b00:	68 c2 55 10 f0       	push   $0xf01055c2
f0102b05:	e8 96 d5 ff ff       	call   f01000a0 <_panic>
	
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102b0a:	89 fb                	mov    %edi,%ebx
f0102b0c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102b0f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b13:	c1 e6 05             	shl    $0x5,%esi
f0102b16:	01 de                	add    %ebx,%esi
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
f0102b18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b1b:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b1e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b23:	77 15                	ja     f0102b3a <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b25:	50                   	push   %eax
f0102b26:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102b2b:	68 5e 01 00 00       	push   $0x15e
f0102b30:	68 c2 55 10 f0       	push   $0xf01055c2
f0102b35:	e8 66 d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b3a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b3f:	0f 22 d8             	mov    %eax,%cr3
f0102b42:	eb 50                	jmp    f0102b94 <env_create+0xc9>
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
f0102b44:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b47:	75 48                	jne    f0102b91 <env_create+0xc6>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102b49:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b4c:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b52:	e8 95 fc ff ff       	call   f01027ec <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f0102b57:	83 ec 04             	sub    $0x4,%esp
f0102b5a:	ff 73 14             	pushl  0x14(%ebx)
f0102b5d:	6a 00                	push   $0x0
f0102b5f:	ff 73 08             	pushl  0x8(%ebx)
f0102b62:	e8 39 15 00 00       	call   f01040a0 <memset>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0102b67:	83 c4 0c             	add    $0xc,%esp
f0102b6a:	ff 73 10             	pushl  0x10(%ebx)
f0102b6d:	89 f8                	mov    %edi,%eax
f0102b6f:	03 43 04             	add    0x4(%ebx),%eax
f0102b72:	50                   	push   %eax
f0102b73:	ff 73 08             	pushl  0x8(%ebx)
f0102b76:	e8 da 15 00 00       	call   f0104155 <memcpy>
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
f0102b7b:	83 c4 0c             	add    $0xc,%esp
f0102b7e:	ff 73 10             	pushl  0x10(%ebx)
f0102b81:	ff 73 14             	pushl  0x14(%ebx)
f0102b84:	68 fe 55 10 f0       	push   $0xf01055fe
f0102b89:	e8 28 03 00 00       	call   f0102eb6 <cprintf>
f0102b8e:	83 c4 10             	add    $0x10,%esp
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
f0102b91:	83 c3 20             	add    $0x20,%ebx
f0102b94:	39 de                	cmp    %ebx,%esi
f0102b96:	77 ac                	ja     f0102b44 <env_create+0x79>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
		}
	//we can use this because kern_pgdir is a subset of e->env_pgdir
	lcr3(PADDR(kern_pgdir));
f0102b98:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b9d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ba2:	77 15                	ja     f0102bb9 <env_create+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ba4:	50                   	push   %eax
f0102ba5:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102baa:	68 69 01 00 00       	push   $0x169
f0102baf:	68 c2 55 10 f0       	push   $0xf01055c2
f0102bb4:	e8 e7 d4 ff ff       	call   f01000a0 <_panic>
f0102bb9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bbe:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102bc1:	8b 47 18             	mov    0x18(%edi),%eax
f0102bc4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102bc7:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102bca:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bcf:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bd4:	89 f8                	mov    %edi,%eax
f0102bd6:	e8 11 fc ff ff       	call   f01027ec <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
	load_icode(penv, binary);
}
f0102bdb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bde:	5b                   	pop    %ebx
f0102bdf:	5e                   	pop    %esi
f0102be0:	5f                   	pop    %edi
f0102be1:	5d                   	pop    %ebp
f0102be2:	c3                   	ret    

f0102be3 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102be3:	55                   	push   %ebp
f0102be4:	89 e5                	mov    %esp,%ebp
f0102be6:	57                   	push   %edi
f0102be7:	56                   	push   %esi
f0102be8:	53                   	push   %ebx
f0102be9:	83 ec 1c             	sub    $0x1c,%esp
f0102bec:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102bef:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102bf5:	39 fa                	cmp    %edi,%edx
f0102bf7:	75 29                	jne    f0102c22 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102bf9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bfe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c03:	77 15                	ja     f0102c1a <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c05:	50                   	push   %eax
f0102c06:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102c0b:	68 8f 01 00 00       	push   $0x18f
f0102c10:	68 c2 55 10 f0       	push   $0xf01055c2
f0102c15:	e8 86 d4 ff ff       	call   f01000a0 <_panic>
f0102c1a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c1f:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c22:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c25:	85 d2                	test   %edx,%edx
f0102c27:	74 05                	je     f0102c2e <env_free+0x4b>
f0102c29:	8b 42 48             	mov    0x48(%edx),%eax
f0102c2c:	eb 05                	jmp    f0102c33 <env_free+0x50>
f0102c2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c33:	83 ec 04             	sub    $0x4,%esp
f0102c36:	51                   	push   %ecx
f0102c37:	50                   	push   %eax
f0102c38:	68 19 56 10 f0       	push   $0xf0105619
f0102c3d:	e8 74 02 00 00       	call   f0102eb6 <cprintf>
f0102c42:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c45:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c4c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c4f:	89 d0                	mov    %edx,%eax
f0102c51:	c1 e0 02             	shl    $0x2,%eax
f0102c54:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c57:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c5a:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c5d:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c63:	0f 84 a8 00 00 00    	je     f0102d11 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c69:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c6f:	89 f0                	mov    %esi,%eax
f0102c71:	c1 e8 0c             	shr    $0xc,%eax
f0102c74:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c77:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102c7d:	77 15                	ja     f0102c94 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c7f:	56                   	push   %esi
f0102c80:	68 04 4e 10 f0       	push   $0xf0104e04
f0102c85:	68 9e 01 00 00       	push   $0x19e
f0102c8a:	68 c2 55 10 f0       	push   $0xf01055c2
f0102c8f:	e8 0c d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c97:	c1 e0 16             	shl    $0x16,%eax
f0102c9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c9d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102ca2:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102ca9:	01 
f0102caa:	74 17                	je     f0102cc3 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cac:	83 ec 08             	sub    $0x8,%esp
f0102caf:	89 d8                	mov    %ebx,%eax
f0102cb1:	c1 e0 0c             	shl    $0xc,%eax
f0102cb4:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102cb7:	50                   	push   %eax
f0102cb8:	ff 77 5c             	pushl  0x5c(%edi)
f0102cbb:	e8 eb e2 ff ff       	call   f0100fab <page_remove>
f0102cc0:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cc3:	83 c3 01             	add    $0x1,%ebx
f0102cc6:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102ccc:	75 d4                	jne    f0102ca2 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102cce:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102cd4:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cdb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102cde:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102ce4:	72 14                	jb     f0102cfa <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102ce6:	83 ec 04             	sub    $0x4,%esp
f0102ce9:	68 48 4f 10 f0       	push   $0xf0104f48
f0102cee:	6a 4f                	push   $0x4f
f0102cf0:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0102cf5:	e8 a6 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102cfa:	83 ec 0c             	sub    $0xc,%esp
f0102cfd:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102d02:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d05:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d08:	50                   	push   %eax
f0102d09:	e8 fb e0 ff ff       	call   f0100e09 <page_decref>
f0102d0e:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d11:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d15:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d18:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d1d:	0f 85 29 ff ff ff    	jne    f0102c4c <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d23:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d26:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d2b:	77 15                	ja     f0102d42 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d2d:	50                   	push   %eax
f0102d2e:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102d33:	68 ac 01 00 00       	push   $0x1ac
f0102d38:	68 c2 55 10 f0       	push   $0xf01055c2
f0102d3d:	e8 5e d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d42:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d49:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d4e:	c1 e8 0c             	shr    $0xc,%eax
f0102d51:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102d57:	72 14                	jb     f0102d6d <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d59:	83 ec 04             	sub    $0x4,%esp
f0102d5c:	68 48 4f 10 f0       	push   $0xf0104f48
f0102d61:	6a 4f                	push   $0x4f
f0102d63:	68 9c 4a 10 f0       	push   $0xf0104a9c
f0102d68:	e8 33 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102d6d:	83 ec 0c             	sub    $0xc,%esp
f0102d70:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102d76:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d79:	50                   	push   %eax
f0102d7a:	e8 8a e0 ff ff       	call   f0100e09 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d7f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d86:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
f0102d8b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d8e:	89 3d 4c be 17 f0    	mov    %edi,0xf017be4c
}
f0102d94:	83 c4 10             	add    $0x10,%esp
f0102d97:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d9a:	5b                   	pop    %ebx
f0102d9b:	5e                   	pop    %esi
f0102d9c:	5f                   	pop    %edi
f0102d9d:	5d                   	pop    %ebp
f0102d9e:	c3                   	ret    

f0102d9f <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102d9f:	55                   	push   %ebp
f0102da0:	89 e5                	mov    %esp,%ebp
f0102da2:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102da5:	ff 75 08             	pushl  0x8(%ebp)
f0102da8:	e8 36 fe ff ff       	call   f0102be3 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102dad:	c7 04 24 5c 56 10 f0 	movl   $0xf010565c,(%esp)
f0102db4:	e8 fd 00 00 00       	call   f0102eb6 <cprintf>
f0102db9:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102dbc:	83 ec 0c             	sub    $0xc,%esp
f0102dbf:	6a 00                	push   $0x0
f0102dc1:	e8 f3 d9 ff ff       	call   f01007b9 <monitor>
f0102dc6:	83 c4 10             	add    $0x10,%esp
f0102dc9:	eb f1                	jmp    f0102dbc <env_destroy+0x1d>

f0102dcb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102dcb:	55                   	push   %ebp
f0102dcc:	89 e5                	mov    %esp,%ebp
f0102dce:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102dd1:	8b 65 08             	mov    0x8(%ebp),%esp
f0102dd4:	61                   	popa   
f0102dd5:	07                   	pop    %es
f0102dd6:	1f                   	pop    %ds
f0102dd7:	83 c4 08             	add    $0x8,%esp
f0102dda:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102ddb:	68 2f 56 10 f0       	push   $0xf010562f
f0102de0:	68 d4 01 00 00       	push   $0x1d4
f0102de5:	68 c2 55 10 f0       	push   $0xf01055c2
f0102dea:	e8 b1 d2 ff ff       	call   f01000a0 <_panic>

f0102def <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102def:	55                   	push   %ebp
f0102df0:	89 e5                	mov    %esp,%ebp
f0102df2:	53                   	push   %ebx
f0102df3:	83 ec 10             	sub    $0x10,%esp
f0102df6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// cprintf("curenv: %x, e: %x\n", curenv, e);
	cprintf("\n");
f0102df9:	68 aa 4d 10 f0       	push   $0xf0104daa
f0102dfe:	e8 b3 00 00 00       	call   f0102eb6 <cprintf>
	if (curenv != e) {
f0102e03:	83 c4 10             	add    $0x10,%esp
f0102e06:	39 1d 44 be 17 f0    	cmp    %ebx,0xf017be44
f0102e0c:	74 38                	je     f0102e46 <env_run+0x57>
		// if (curenv->env_status == ENV_RUNNING)
		// 	curenv->env_status = ENV_RUNNABLE;
		curenv = e;
f0102e0e:	89 1d 44 be 17 f0    	mov    %ebx,0xf017be44
		e->env_status = ENV_RUNNING;
f0102e14:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
		e->env_runs++;
f0102e1b:	83 43 58 01          	addl   $0x1,0x58(%ebx)
		lcr3(PADDR(e->env_pgdir));
f0102e1f:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e22:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e27:	77 15                	ja     f0102e3e <env_run+0x4f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e29:	50                   	push   %eax
f0102e2a:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0102e2f:	68 fa 01 00 00       	push   $0x1fa
f0102e34:	68 c2 55 10 f0       	push   $0xf01055c2
f0102e39:	e8 62 d2 ff ff       	call   f01000a0 <_panic>
f0102e3e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e43:	0f 22 d8             	mov    %eax,%cr3
	}
	env_pop_tf(&e->env_tf);
f0102e46:	83 ec 0c             	sub    $0xc,%esp
f0102e49:	53                   	push   %ebx
f0102e4a:	e8 7c ff ff ff       	call   f0102dcb <env_pop_tf>

f0102e4f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e4f:	55                   	push   %ebp
f0102e50:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e52:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e57:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e5a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e5b:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e60:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e61:	0f b6 c0             	movzbl %al,%eax
}
f0102e64:	5d                   	pop    %ebp
f0102e65:	c3                   	ret    

f0102e66 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e66:	55                   	push   %ebp
f0102e67:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e69:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e71:	ee                   	out    %al,(%dx)
f0102e72:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e7a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e7b:	5d                   	pop    %ebp
f0102e7c:	c3                   	ret    

f0102e7d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e7d:	55                   	push   %ebp
f0102e7e:	89 e5                	mov    %esp,%ebp
f0102e80:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e83:	ff 75 08             	pushl  0x8(%ebp)
f0102e86:	e8 8a d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102e8b:	83 c4 10             	add    $0x10,%esp
f0102e8e:	c9                   	leave  
f0102e8f:	c3                   	ret    

f0102e90 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e90:	55                   	push   %ebp
f0102e91:	89 e5                	mov    %esp,%ebp
f0102e93:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e9d:	ff 75 0c             	pushl  0xc(%ebp)
f0102ea0:	ff 75 08             	pushl  0x8(%ebp)
f0102ea3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ea6:	50                   	push   %eax
f0102ea7:	68 7d 2e 10 f0       	push   $0xf0102e7d
f0102eac:	e8 ca 0a 00 00       	call   f010397b <vprintfmt>
	return cnt;
}
f0102eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eb4:	c9                   	leave  
f0102eb5:	c3                   	ret    

f0102eb6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102eb6:	55                   	push   %ebp
f0102eb7:	89 e5                	mov    %esp,%ebp
f0102eb9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ebc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ebf:	50                   	push   %eax
f0102ec0:	ff 75 08             	pushl  0x8(%ebp)
f0102ec3:	e8 c8 ff ff ff       	call   f0102e90 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102ec8:	c9                   	leave  
f0102ec9:	c3                   	ret    

f0102eca <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102eca:	55                   	push   %ebp
f0102ecb:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ecd:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102ed2:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102ed9:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102edc:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102ee3:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0102ee5:	66 c7 05 e6 c6 17 f0 	movw   $0x68,0xf017c6e6
f0102eec:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102eee:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102ef5:	67 00 
f0102ef7:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102efd:	89 c2                	mov    %eax,%edx
f0102eff:	c1 ea 10             	shr    $0x10,%edx
f0102f02:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102f08:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f0f:	c1 e8 18             	shr    $0x18,%eax
f0102f12:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f17:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f1e:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f23:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f26:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f2b:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f2e:	5d                   	pop    %ebp
f0102f2f:	c3                   	ret    

f0102f30 <trap_init>:
}


void
trap_init(void)
{
f0102f30:	55                   	push   %ebp
f0102f31:	89 e5                	mov    %esp,%ebp
	void th12();
	void th13();
	void th14();
	void th16();
	
	SETGATE(idt[0], 0, GD_KT, th0, 0);
f0102f33:	b8 ec 34 10 f0       	mov    $0xf01034ec,%eax
f0102f38:	66 a3 60 be 17 f0    	mov    %ax,0xf017be60
f0102f3e:	66 c7 05 62 be 17 f0 	movw   $0x8,0xf017be62
f0102f45:	08 00 
f0102f47:	c6 05 64 be 17 f0 00 	movb   $0x0,0xf017be64
f0102f4e:	c6 05 65 be 17 f0 8e 	movb   $0x8e,0xf017be65
f0102f55:	c1 e8 10             	shr    $0x10,%eax
f0102f58:	66 a3 66 be 17 f0    	mov    %ax,0xf017be66
	SETGATE(idt[1], 0, GD_KT, th1, 0);
f0102f5e:	b8 f2 34 10 f0       	mov    $0xf01034f2,%eax
f0102f63:	66 a3 68 be 17 f0    	mov    %ax,0xf017be68
f0102f69:	66 c7 05 6a be 17 f0 	movw   $0x8,0xf017be6a
f0102f70:	08 00 
f0102f72:	c6 05 6c be 17 f0 00 	movb   $0x0,0xf017be6c
f0102f79:	c6 05 6d be 17 f0 8e 	movb   $0x8e,0xf017be6d
f0102f80:	c1 e8 10             	shr    $0x10,%eax
f0102f83:	66 a3 6e be 17 f0    	mov    %ax,0xf017be6e
	SETGATE(idt[3], 0, GD_KT, th3, 3);
f0102f89:	b8 f8 34 10 f0       	mov    $0xf01034f8,%eax
f0102f8e:	66 a3 78 be 17 f0    	mov    %ax,0xf017be78
f0102f94:	66 c7 05 7a be 17 f0 	movw   $0x8,0xf017be7a
f0102f9b:	08 00 
f0102f9d:	c6 05 7c be 17 f0 00 	movb   $0x0,0xf017be7c
f0102fa4:	c6 05 7d be 17 f0 ee 	movb   $0xee,0xf017be7d
f0102fab:	c1 e8 10             	shr    $0x10,%eax
f0102fae:	66 a3 7e be 17 f0    	mov    %ax,0xf017be7e
	SETGATE(idt[4], 0, GD_KT, th4, 0);
f0102fb4:	b8 fe 34 10 f0       	mov    $0xf01034fe,%eax
f0102fb9:	66 a3 80 be 17 f0    	mov    %ax,0xf017be80
f0102fbf:	66 c7 05 82 be 17 f0 	movw   $0x8,0xf017be82
f0102fc6:	08 00 
f0102fc8:	c6 05 84 be 17 f0 00 	movb   $0x0,0xf017be84
f0102fcf:	c6 05 85 be 17 f0 8e 	movb   $0x8e,0xf017be85
f0102fd6:	c1 e8 10             	shr    $0x10,%eax
f0102fd9:	66 a3 86 be 17 f0    	mov    %ax,0xf017be86
	SETGATE(idt[5], 0, GD_KT, th5, 0);
f0102fdf:	b8 04 35 10 f0       	mov    $0xf0103504,%eax
f0102fe4:	66 a3 88 be 17 f0    	mov    %ax,0xf017be88
f0102fea:	66 c7 05 8a be 17 f0 	movw   $0x8,0xf017be8a
f0102ff1:	08 00 
f0102ff3:	c6 05 8c be 17 f0 00 	movb   $0x0,0xf017be8c
f0102ffa:	c6 05 8d be 17 f0 8e 	movb   $0x8e,0xf017be8d
f0103001:	c1 e8 10             	shr    $0x10,%eax
f0103004:	66 a3 8e be 17 f0    	mov    %ax,0xf017be8e
	SETGATE(idt[6], 0, GD_KT, th6, 0);
f010300a:	b8 0a 35 10 f0       	mov    $0xf010350a,%eax
f010300f:	66 a3 90 be 17 f0    	mov    %ax,0xf017be90
f0103015:	66 c7 05 92 be 17 f0 	movw   $0x8,0xf017be92
f010301c:	08 00 
f010301e:	c6 05 94 be 17 f0 00 	movb   $0x0,0xf017be94
f0103025:	c6 05 95 be 17 f0 8e 	movb   $0x8e,0xf017be95
f010302c:	c1 e8 10             	shr    $0x10,%eax
f010302f:	66 a3 96 be 17 f0    	mov    %ax,0xf017be96
	SETGATE(idt[7], 0, GD_KT, th7, 0);
f0103035:	b8 10 35 10 f0       	mov    $0xf0103510,%eax
f010303a:	66 a3 98 be 17 f0    	mov    %ax,0xf017be98
f0103040:	66 c7 05 9a be 17 f0 	movw   $0x8,0xf017be9a
f0103047:	08 00 
f0103049:	c6 05 9c be 17 f0 00 	movb   $0x0,0xf017be9c
f0103050:	c6 05 9d be 17 f0 8e 	movb   $0x8e,0xf017be9d
f0103057:	c1 e8 10             	shr    $0x10,%eax
f010305a:	66 a3 9e be 17 f0    	mov    %ax,0xf017be9e
	SETGATE(idt[8], 0, GD_KT, th8, 0);
f0103060:	b8 16 35 10 f0       	mov    $0xf0103516,%eax
f0103065:	66 a3 a0 be 17 f0    	mov    %ax,0xf017bea0
f010306b:	66 c7 05 a2 be 17 f0 	movw   $0x8,0xf017bea2
f0103072:	08 00 
f0103074:	c6 05 a4 be 17 f0 00 	movb   $0x0,0xf017bea4
f010307b:	c6 05 a5 be 17 f0 8e 	movb   $0x8e,0xf017bea5
f0103082:	c1 e8 10             	shr    $0x10,%eax
f0103085:	66 a3 a6 be 17 f0    	mov    %ax,0xf017bea6
	SETGATE(idt[9], 0, GD_KT, th9, 0);
f010308b:	b8 1a 35 10 f0       	mov    $0xf010351a,%eax
f0103090:	66 a3 a8 be 17 f0    	mov    %ax,0xf017bea8
f0103096:	66 c7 05 aa be 17 f0 	movw   $0x8,0xf017beaa
f010309d:	08 00 
f010309f:	c6 05 ac be 17 f0 00 	movb   $0x0,0xf017beac
f01030a6:	c6 05 ad be 17 f0 8e 	movb   $0x8e,0xf017bead
f01030ad:	c1 e8 10             	shr    $0x10,%eax
f01030b0:	66 a3 ae be 17 f0    	mov    %ax,0xf017beae
	SETGATE(idt[10], 0, GD_KT, th10, 0);
f01030b6:	b8 20 35 10 f0       	mov    $0xf0103520,%eax
f01030bb:	66 a3 b0 be 17 f0    	mov    %ax,0xf017beb0
f01030c1:	66 c7 05 b2 be 17 f0 	movw   $0x8,0xf017beb2
f01030c8:	08 00 
f01030ca:	c6 05 b4 be 17 f0 00 	movb   $0x0,0xf017beb4
f01030d1:	c6 05 b5 be 17 f0 8e 	movb   $0x8e,0xf017beb5
f01030d8:	c1 e8 10             	shr    $0x10,%eax
f01030db:	66 a3 b6 be 17 f0    	mov    %ax,0xf017beb6
	SETGATE(idt[11], 0, GD_KT, th11, 0);
f01030e1:	b8 24 35 10 f0       	mov    $0xf0103524,%eax
f01030e6:	66 a3 b8 be 17 f0    	mov    %ax,0xf017beb8
f01030ec:	66 c7 05 ba be 17 f0 	movw   $0x8,0xf017beba
f01030f3:	08 00 
f01030f5:	c6 05 bc be 17 f0 00 	movb   $0x0,0xf017bebc
f01030fc:	c6 05 bd be 17 f0 8e 	movb   $0x8e,0xf017bebd
f0103103:	c1 e8 10             	shr    $0x10,%eax
f0103106:	66 a3 be be 17 f0    	mov    %ax,0xf017bebe
	SETGATE(idt[12], 0, GD_KT, th12, 0);
f010310c:	b8 28 35 10 f0       	mov    $0xf0103528,%eax
f0103111:	66 a3 c0 be 17 f0    	mov    %ax,0xf017bec0
f0103117:	66 c7 05 c2 be 17 f0 	movw   $0x8,0xf017bec2
f010311e:	08 00 
f0103120:	c6 05 c4 be 17 f0 00 	movb   $0x0,0xf017bec4
f0103127:	c6 05 c5 be 17 f0 8e 	movb   $0x8e,0xf017bec5
f010312e:	c1 e8 10             	shr    $0x10,%eax
f0103131:	66 a3 c6 be 17 f0    	mov    %ax,0xf017bec6
	SETGATE(idt[13], 0, GD_KT, th13, 0);
f0103137:	b8 2c 35 10 f0       	mov    $0xf010352c,%eax
f010313c:	66 a3 c8 be 17 f0    	mov    %ax,0xf017bec8
f0103142:	66 c7 05 ca be 17 f0 	movw   $0x8,0xf017beca
f0103149:	08 00 
f010314b:	c6 05 cc be 17 f0 00 	movb   $0x0,0xf017becc
f0103152:	c6 05 cd be 17 f0 8e 	movb   $0x8e,0xf017becd
f0103159:	c1 e8 10             	shr    $0x10,%eax
f010315c:	66 a3 ce be 17 f0    	mov    %ax,0xf017bece
	SETGATE(idt[14], 0, GD_KT, th14, 0);
f0103162:	b8 30 35 10 f0       	mov    $0xf0103530,%eax
f0103167:	66 a3 d0 be 17 f0    	mov    %ax,0xf017bed0
f010316d:	66 c7 05 d2 be 17 f0 	movw   $0x8,0xf017bed2
f0103174:	08 00 
f0103176:	c6 05 d4 be 17 f0 00 	movb   $0x0,0xf017bed4
f010317d:	c6 05 d5 be 17 f0 8e 	movb   $0x8e,0xf017bed5
f0103184:	c1 e8 10             	shr    $0x10,%eax
f0103187:	66 a3 d6 be 17 f0    	mov    %ax,0xf017bed6
	SETGATE(idt[16], 0, GD_KT, th16, 0);
f010318d:	b8 34 35 10 f0       	mov    $0xf0103534,%eax
f0103192:	66 a3 e0 be 17 f0    	mov    %ax,0xf017bee0
f0103198:	66 c7 05 e2 be 17 f0 	movw   $0x8,0xf017bee2
f010319f:	08 00 
f01031a1:	c6 05 e4 be 17 f0 00 	movb   $0x0,0xf017bee4
f01031a8:	c6 05 e5 be 17 f0 8e 	movb   $0x8e,0xf017bee5
f01031af:	c1 e8 10             	shr    $0x10,%eax
f01031b2:	66 a3 e6 be 17 f0    	mov    %ax,0xf017bee6
	


	// Per-CPU setup 
	trap_init_percpu();
f01031b8:	e8 0d fd ff ff       	call   f0102eca <trap_init_percpu>
}
f01031bd:	5d                   	pop    %ebp
f01031be:	c3                   	ret    

f01031bf <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01031bf:	55                   	push   %ebp
f01031c0:	89 e5                	mov    %esp,%ebp
f01031c2:	53                   	push   %ebx
f01031c3:	83 ec 0c             	sub    $0xc,%esp
f01031c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01031c9:	ff 33                	pushl  (%ebx)
f01031cb:	68 92 56 10 f0       	push   $0xf0105692
f01031d0:	e8 e1 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01031d5:	83 c4 08             	add    $0x8,%esp
f01031d8:	ff 73 04             	pushl  0x4(%ebx)
f01031db:	68 a1 56 10 f0       	push   $0xf01056a1
f01031e0:	e8 d1 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01031e5:	83 c4 08             	add    $0x8,%esp
f01031e8:	ff 73 08             	pushl  0x8(%ebx)
f01031eb:	68 b0 56 10 f0       	push   $0xf01056b0
f01031f0:	e8 c1 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01031f5:	83 c4 08             	add    $0x8,%esp
f01031f8:	ff 73 0c             	pushl  0xc(%ebx)
f01031fb:	68 bf 56 10 f0       	push   $0xf01056bf
f0103200:	e8 b1 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103205:	83 c4 08             	add    $0x8,%esp
f0103208:	ff 73 10             	pushl  0x10(%ebx)
f010320b:	68 ce 56 10 f0       	push   $0xf01056ce
f0103210:	e8 a1 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103215:	83 c4 08             	add    $0x8,%esp
f0103218:	ff 73 14             	pushl  0x14(%ebx)
f010321b:	68 dd 56 10 f0       	push   $0xf01056dd
f0103220:	e8 91 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103225:	83 c4 08             	add    $0x8,%esp
f0103228:	ff 73 18             	pushl  0x18(%ebx)
f010322b:	68 ec 56 10 f0       	push   $0xf01056ec
f0103230:	e8 81 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103235:	83 c4 08             	add    $0x8,%esp
f0103238:	ff 73 1c             	pushl  0x1c(%ebx)
f010323b:	68 fb 56 10 f0       	push   $0xf01056fb
f0103240:	e8 71 fc ff ff       	call   f0102eb6 <cprintf>
}
f0103245:	83 c4 10             	add    $0x10,%esp
f0103248:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010324b:	c9                   	leave  
f010324c:	c3                   	ret    

f010324d <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010324d:	55                   	push   %ebp
f010324e:	89 e5                	mov    %esp,%ebp
f0103250:	56                   	push   %esi
f0103251:	53                   	push   %ebx
f0103252:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103255:	83 ec 08             	sub    $0x8,%esp
f0103258:	53                   	push   %ebx
f0103259:	68 31 58 10 f0       	push   $0xf0105831
f010325e:	e8 53 fc ff ff       	call   f0102eb6 <cprintf>
	print_regs(&tf->tf_regs);
f0103263:	89 1c 24             	mov    %ebx,(%esp)
f0103266:	e8 54 ff ff ff       	call   f01031bf <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010326b:	83 c4 08             	add    $0x8,%esp
f010326e:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103272:	50                   	push   %eax
f0103273:	68 4c 57 10 f0       	push   $0xf010574c
f0103278:	e8 39 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010327d:	83 c4 08             	add    $0x8,%esp
f0103280:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103284:	50                   	push   %eax
f0103285:	68 5f 57 10 f0       	push   $0xf010575f
f010328a:	e8 27 fc ff ff       	call   f0102eb6 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010328f:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103292:	83 c4 10             	add    $0x10,%esp
f0103295:	83 f8 13             	cmp    $0x13,%eax
f0103298:	77 09                	ja     f01032a3 <print_trapframe+0x56>
		return excnames[trapno];
f010329a:	8b 14 85 00 5a 10 f0 	mov    -0xfefa600(,%eax,4),%edx
f01032a1:	eb 10                	jmp    f01032b3 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01032a3:	83 f8 30             	cmp    $0x30,%eax
f01032a6:	b9 16 57 10 f0       	mov    $0xf0105716,%ecx
f01032ab:	ba 0a 57 10 f0       	mov    $0xf010570a,%edx
f01032b0:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032b3:	83 ec 04             	sub    $0x4,%esp
f01032b6:	52                   	push   %edx
f01032b7:	50                   	push   %eax
f01032b8:	68 72 57 10 f0       	push   $0xf0105772
f01032bd:	e8 f4 fb ff ff       	call   f0102eb6 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01032c2:	83 c4 10             	add    $0x10,%esp
f01032c5:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f01032cb:	75 1a                	jne    f01032e7 <print_trapframe+0x9a>
f01032cd:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01032d1:	75 14                	jne    f01032e7 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01032d3:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01032d6:	83 ec 08             	sub    $0x8,%esp
f01032d9:	50                   	push   %eax
f01032da:	68 84 57 10 f0       	push   $0xf0105784
f01032df:	e8 d2 fb ff ff       	call   f0102eb6 <cprintf>
f01032e4:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01032e7:	83 ec 08             	sub    $0x8,%esp
f01032ea:	ff 73 2c             	pushl  0x2c(%ebx)
f01032ed:	68 93 57 10 f0       	push   $0xf0105793
f01032f2:	e8 bf fb ff ff       	call   f0102eb6 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01032f7:	83 c4 10             	add    $0x10,%esp
f01032fa:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01032fe:	75 49                	jne    f0103349 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103300:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103303:	89 c2                	mov    %eax,%edx
f0103305:	83 e2 01             	and    $0x1,%edx
f0103308:	ba 30 57 10 f0       	mov    $0xf0105730,%edx
f010330d:	b9 25 57 10 f0       	mov    $0xf0105725,%ecx
f0103312:	0f 44 ca             	cmove  %edx,%ecx
f0103315:	89 c2                	mov    %eax,%edx
f0103317:	83 e2 02             	and    $0x2,%edx
f010331a:	ba 42 57 10 f0       	mov    $0xf0105742,%edx
f010331f:	be 3c 57 10 f0       	mov    $0xf010573c,%esi
f0103324:	0f 45 d6             	cmovne %esi,%edx
f0103327:	83 e0 04             	and    $0x4,%eax
f010332a:	be 5c 58 10 f0       	mov    $0xf010585c,%esi
f010332f:	b8 47 57 10 f0       	mov    $0xf0105747,%eax
f0103334:	0f 44 c6             	cmove  %esi,%eax
f0103337:	51                   	push   %ecx
f0103338:	52                   	push   %edx
f0103339:	50                   	push   %eax
f010333a:	68 a1 57 10 f0       	push   $0xf01057a1
f010333f:	e8 72 fb ff ff       	call   f0102eb6 <cprintf>
f0103344:	83 c4 10             	add    $0x10,%esp
f0103347:	eb 10                	jmp    f0103359 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103349:	83 ec 0c             	sub    $0xc,%esp
f010334c:	68 aa 4d 10 f0       	push   $0xf0104daa
f0103351:	e8 60 fb ff ff       	call   f0102eb6 <cprintf>
f0103356:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103359:	83 ec 08             	sub    $0x8,%esp
f010335c:	ff 73 30             	pushl  0x30(%ebx)
f010335f:	68 b0 57 10 f0       	push   $0xf01057b0
f0103364:	e8 4d fb ff ff       	call   f0102eb6 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103369:	83 c4 08             	add    $0x8,%esp
f010336c:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103370:	50                   	push   %eax
f0103371:	68 bf 57 10 f0       	push   $0xf01057bf
f0103376:	e8 3b fb ff ff       	call   f0102eb6 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010337b:	83 c4 08             	add    $0x8,%esp
f010337e:	ff 73 38             	pushl  0x38(%ebx)
f0103381:	68 d2 57 10 f0       	push   $0xf01057d2
f0103386:	e8 2b fb ff ff       	call   f0102eb6 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010338b:	83 c4 10             	add    $0x10,%esp
f010338e:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103392:	74 25                	je     f01033b9 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103394:	83 ec 08             	sub    $0x8,%esp
f0103397:	ff 73 3c             	pushl  0x3c(%ebx)
f010339a:	68 e1 57 10 f0       	push   $0xf01057e1
f010339f:	e8 12 fb ff ff       	call   f0102eb6 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01033a4:	83 c4 08             	add    $0x8,%esp
f01033a7:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01033ab:	50                   	push   %eax
f01033ac:	68 f0 57 10 f0       	push   $0xf01057f0
f01033b1:	e8 00 fb ff ff       	call   f0102eb6 <cprintf>
f01033b6:	83 c4 10             	add    $0x10,%esp
	}
}
f01033b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01033bc:	5b                   	pop    %ebx
f01033bd:	5e                   	pop    %esi
f01033be:	5d                   	pop    %ebp
f01033bf:	c3                   	ret    

f01033c0 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01033c0:	55                   	push   %ebp
f01033c1:	89 e5                	mov    %esp,%ebp
f01033c3:	57                   	push   %edi
f01033c4:	56                   	push   %esi
f01033c5:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01033c8:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01033c9:	9c                   	pushf  
f01033ca:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01033cb:	f6 c4 02             	test   $0x2,%ah
f01033ce:	74 19                	je     f01033e9 <trap+0x29>
f01033d0:	68 03 58 10 f0       	push   $0xf0105803
f01033d5:	68 b6 4a 10 f0       	push   $0xf0104ab6
f01033da:	68 cb 00 00 00       	push   $0xcb
f01033df:	68 1c 58 10 f0       	push   $0xf010581c
f01033e4:	e8 b7 cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01033e9:	83 ec 08             	sub    $0x8,%esp
f01033ec:	56                   	push   %esi
f01033ed:	68 28 58 10 f0       	push   $0xf0105828
f01033f2:	e8 bf fa ff ff       	call   f0102eb6 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01033f7:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01033fb:	83 e0 03             	and    $0x3,%eax
f01033fe:	83 c4 10             	add    $0x10,%esp
f0103401:	66 83 f8 03          	cmp    $0x3,%ax
f0103405:	75 31                	jne    f0103438 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103407:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010340c:	85 c0                	test   %eax,%eax
f010340e:	75 19                	jne    f0103429 <trap+0x69>
f0103410:	68 43 58 10 f0       	push   $0xf0105843
f0103415:	68 b6 4a 10 f0       	push   $0xf0104ab6
f010341a:	68 d1 00 00 00       	push   $0xd1
f010341f:	68 1c 58 10 f0       	push   $0xf010581c
f0103424:	e8 77 cc ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103429:	b9 11 00 00 00       	mov    $0x11,%ecx
f010342e:	89 c7                	mov    %eax,%edi
f0103430:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103432:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103438:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010343e:	83 ec 0c             	sub    $0xc,%esp
f0103441:	56                   	push   %esi
f0103442:	e8 06 fe ff ff       	call   f010324d <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103447:	83 c4 10             	add    $0x10,%esp
f010344a:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010344f:	75 17                	jne    f0103468 <trap+0xa8>
		panic("unhandled trap in kernel");
f0103451:	83 ec 04             	sub    $0x4,%esp
f0103454:	68 4a 58 10 f0       	push   $0xf010584a
f0103459:	68 ba 00 00 00       	push   $0xba
f010345e:	68 1c 58 10 f0       	push   $0xf010581c
f0103463:	e8 38 cc ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103468:	83 ec 0c             	sub    $0xc,%esp
f010346b:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0103471:	e8 29 f9 ff ff       	call   f0102d9f <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103476:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010347b:	83 c4 10             	add    $0x10,%esp
f010347e:	85 c0                	test   %eax,%eax
f0103480:	74 06                	je     f0103488 <trap+0xc8>
f0103482:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103486:	74 19                	je     f01034a1 <trap+0xe1>
f0103488:	68 a8 59 10 f0       	push   $0xf01059a8
f010348d:	68 b6 4a 10 f0       	push   $0xf0104ab6
f0103492:	68 e3 00 00 00       	push   $0xe3
f0103497:	68 1c 58 10 f0       	push   $0xf010581c
f010349c:	e8 ff cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01034a1:	83 ec 0c             	sub    $0xc,%esp
f01034a4:	50                   	push   %eax
f01034a5:	e8 45 f9 ff ff       	call   f0102def <env_run>

f01034aa <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034aa:	55                   	push   %ebp
f01034ab:	89 e5                	mov    %esp,%ebp
f01034ad:	53                   	push   %ebx
f01034ae:	83 ec 04             	sub    $0x4,%esp
f01034b1:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01034b4:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034b7:	ff 73 30             	pushl  0x30(%ebx)
f01034ba:	50                   	push   %eax
f01034bb:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f01034c0:	ff 70 48             	pushl  0x48(%eax)
f01034c3:	68 d4 59 10 f0       	push   $0xf01059d4
f01034c8:	e8 e9 f9 ff ff       	call   f0102eb6 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01034cd:	89 1c 24             	mov    %ebx,(%esp)
f01034d0:	e8 78 fd ff ff       	call   f010324d <print_trapframe>
	env_destroy(curenv);
f01034d5:	83 c4 04             	add    $0x4,%esp
f01034d8:	ff 35 44 be 17 f0    	pushl  0xf017be44
f01034de:	e8 bc f8 ff ff       	call   f0102d9f <env_destroy>
}
f01034e3:	83 c4 10             	add    $0x10,%esp
f01034e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034e9:	c9                   	leave  
f01034ea:	c3                   	ret    
f01034eb:	90                   	nop

f01034ec <th0>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

	TRAPHANDLER_NOEC(th0, 0)
f01034ec:	6a 00                	push   $0x0
f01034ee:	6a 00                	push   $0x0
f01034f0:	eb 48                	jmp    f010353a <_alltraps>

f01034f2 <th1>:
	TRAPHANDLER_NOEC(th1, 1)
f01034f2:	6a 00                	push   $0x0
f01034f4:	6a 01                	push   $0x1
f01034f6:	eb 42                	jmp    f010353a <_alltraps>

f01034f8 <th3>:
	TRAPHANDLER_NOEC(th3, 3)
f01034f8:	6a 00                	push   $0x0
f01034fa:	6a 03                	push   $0x3
f01034fc:	eb 3c                	jmp    f010353a <_alltraps>

f01034fe <th4>:
	TRAPHANDLER_NOEC(th4, 4)
f01034fe:	6a 00                	push   $0x0
f0103500:	6a 04                	push   $0x4
f0103502:	eb 36                	jmp    f010353a <_alltraps>

f0103504 <th5>:
	TRAPHANDLER_NOEC(th5, 5)
f0103504:	6a 00                	push   $0x0
f0103506:	6a 05                	push   $0x5
f0103508:	eb 30                	jmp    f010353a <_alltraps>

f010350a <th6>:
	TRAPHANDLER_NOEC(th6, 6)
f010350a:	6a 00                	push   $0x0
f010350c:	6a 06                	push   $0x6
f010350e:	eb 2a                	jmp    f010353a <_alltraps>

f0103510 <th7>:
	TRAPHANDLER_NOEC(th7, 7)
f0103510:	6a 00                	push   $0x0
f0103512:	6a 07                	push   $0x7
f0103514:	eb 24                	jmp    f010353a <_alltraps>

f0103516 <th8>:
	TRAPHANDLER(th8, 8)
f0103516:	6a 08                	push   $0x8
f0103518:	eb 20                	jmp    f010353a <_alltraps>

f010351a <th9>:
	TRAPHANDLER_NOEC(th9, 9)
f010351a:	6a 00                	push   $0x0
f010351c:	6a 09                	push   $0x9
f010351e:	eb 1a                	jmp    f010353a <_alltraps>

f0103520 <th10>:
	TRAPHANDLER(th10, 10)
f0103520:	6a 0a                	push   $0xa
f0103522:	eb 16                	jmp    f010353a <_alltraps>

f0103524 <th11>:
	TRAPHANDLER(th11, 11)
f0103524:	6a 0b                	push   $0xb
f0103526:	eb 12                	jmp    f010353a <_alltraps>

f0103528 <th12>:
	TRAPHANDLER(th12, 12)
f0103528:	6a 0c                	push   $0xc
f010352a:	eb 0e                	jmp    f010353a <_alltraps>

f010352c <th13>:
	TRAPHANDLER(th13, 13)
f010352c:	6a 0d                	push   $0xd
f010352e:	eb 0a                	jmp    f010353a <_alltraps>

f0103530 <th14>:
	TRAPHANDLER(th14, 14)
f0103530:	6a 0e                	push   $0xe
f0103532:	eb 06                	jmp    f010353a <_alltraps>

f0103534 <th16>:
	TRAPHANDLER_NOEC(th16, 16)
f0103534:	6a 00                	push   $0x0
f0103536:	6a 10                	push   $0x10
f0103538:	eb 00                	jmp    f010353a <_alltraps>

f010353a <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f010353a:	1e                   	push   %ds
	pushl %es
f010353b:	06                   	push   %es
	pushal
f010353c:	60                   	pusha  
	pushl $GD_KD
f010353d:	6a 10                	push   $0x10
	popl %ds
f010353f:	1f                   	pop    %ds
	pushl $GD_KD
f0103540:	6a 10                	push   $0x10
	popl %es
f0103542:	07                   	pop    %es
	pushl %esp
f0103543:	54                   	push   %esp
	call trap
f0103544:	e8 77 fe ff ff       	call   f01033c0 <trap>

f0103549 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103549:	55                   	push   %ebp
f010354a:	89 e5                	mov    %esp,%ebp
			ret = -E_INVAL;
	}
	
	return ret;
	panic("syscall not implemented");
}
f010354c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103551:	5d                   	pop    %ebp
f0103552:	c3                   	ret    

f0103553 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103553:	55                   	push   %ebp
f0103554:	89 e5                	mov    %esp,%ebp
f0103556:	57                   	push   %edi
f0103557:	56                   	push   %esi
f0103558:	53                   	push   %ebx
f0103559:	83 ec 14             	sub    $0x14,%esp
f010355c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010355f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103562:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103565:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103568:	8b 1a                	mov    (%edx),%ebx
f010356a:	8b 01                	mov    (%ecx),%eax
f010356c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010356f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103576:	eb 7f                	jmp    f01035f7 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103578:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010357b:	01 d8                	add    %ebx,%eax
f010357d:	89 c6                	mov    %eax,%esi
f010357f:	c1 ee 1f             	shr    $0x1f,%esi
f0103582:	01 c6                	add    %eax,%esi
f0103584:	d1 fe                	sar    %esi
f0103586:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103589:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010358c:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010358f:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103591:	eb 03                	jmp    f0103596 <stab_binsearch+0x43>
			m--;
f0103593:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103596:	39 c3                	cmp    %eax,%ebx
f0103598:	7f 0d                	jg     f01035a7 <stab_binsearch+0x54>
f010359a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010359e:	83 ea 0c             	sub    $0xc,%edx
f01035a1:	39 f9                	cmp    %edi,%ecx
f01035a3:	75 ee                	jne    f0103593 <stab_binsearch+0x40>
f01035a5:	eb 05                	jmp    f01035ac <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01035a7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01035aa:	eb 4b                	jmp    f01035f7 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01035ac:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01035af:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01035b2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01035b6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01035b9:	76 11                	jbe    f01035cc <stab_binsearch+0x79>
			*region_left = m;
f01035bb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01035be:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01035c0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01035c3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01035ca:	eb 2b                	jmp    f01035f7 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01035cc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01035cf:	73 14                	jae    f01035e5 <stab_binsearch+0x92>
			*region_right = m - 1;
f01035d1:	83 e8 01             	sub    $0x1,%eax
f01035d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035d7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01035da:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01035dc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01035e3:	eb 12                	jmp    f01035f7 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01035e5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01035e8:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01035ea:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01035ee:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01035f0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01035f7:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01035fa:	0f 8e 78 ff ff ff    	jle    f0103578 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103600:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103604:	75 0f                	jne    f0103615 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103606:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103609:	8b 00                	mov    (%eax),%eax
f010360b:	83 e8 01             	sub    $0x1,%eax
f010360e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103611:	89 06                	mov    %eax,(%esi)
f0103613:	eb 2c                	jmp    f0103641 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103615:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103618:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010361a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010361d:	8b 0e                	mov    (%esi),%ecx
f010361f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103622:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103625:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103628:	eb 03                	jmp    f010362d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010362a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010362d:	39 c8                	cmp    %ecx,%eax
f010362f:	7e 0b                	jle    f010363c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103631:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103635:	83 ea 0c             	sub    $0xc,%edx
f0103638:	39 df                	cmp    %ebx,%edi
f010363a:	75 ee                	jne    f010362a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010363c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010363f:	89 06                	mov    %eax,(%esi)
	}
}
f0103641:	83 c4 14             	add    $0x14,%esp
f0103644:	5b                   	pop    %ebx
f0103645:	5e                   	pop    %esi
f0103646:	5f                   	pop    %edi
f0103647:	5d                   	pop    %ebp
f0103648:	c3                   	ret    

f0103649 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103649:	55                   	push   %ebp
f010364a:	89 e5                	mov    %esp,%ebp
f010364c:	57                   	push   %edi
f010364d:	56                   	push   %esi
f010364e:	53                   	push   %ebx
f010364f:	83 ec 3c             	sub    $0x3c,%esp
f0103652:	8b 75 08             	mov    0x8(%ebp),%esi
f0103655:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103658:	c7 03 50 5a 10 f0    	movl   $0xf0105a50,(%ebx)
	info->eip_line = 0;
f010365e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103665:	c7 43 08 50 5a 10 f0 	movl   $0xf0105a50,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010366c:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103673:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103676:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010367d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103683:	77 21                	ja     f01036a6 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103685:	a1 00 00 20 00       	mov    0x200000,%eax
f010368a:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f010368d:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103692:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103698:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010369b:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01036a1:	89 7d c0             	mov    %edi,-0x40(%ebp)
f01036a4:	eb 1a                	jmp    f01036c0 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01036a6:	c7 45 c0 a5 fb 10 f0 	movl   $0xf010fba5,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01036ad:	c7 45 b8 05 d2 10 f0 	movl   $0xf010d205,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01036b4:	b8 04 d2 10 f0       	mov    $0xf010d204,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01036b9:	c7 45 bc 68 5c 10 f0 	movl   $0xf0105c68,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036c0:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01036c3:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f01036c6:	0f 83 9d 01 00 00    	jae    f0103869 <debuginfo_eip+0x220>
f01036cc:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01036d0:	0f 85 9a 01 00 00    	jne    f0103870 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01036d6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01036dd:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01036e0:	29 f8                	sub    %edi,%eax
f01036e2:	c1 f8 02             	sar    $0x2,%eax
f01036e5:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01036eb:	83 e8 01             	sub    $0x1,%eax
f01036ee:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01036f1:	56                   	push   %esi
f01036f2:	6a 64                	push   $0x64
f01036f4:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01036f7:	89 c1                	mov    %eax,%ecx
f01036f9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01036fc:	89 f8                	mov    %edi,%eax
f01036fe:	e8 50 fe ff ff       	call   f0103553 <stab_binsearch>
	if (lfile == 0)
f0103703:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103706:	83 c4 08             	add    $0x8,%esp
f0103709:	85 c0                	test   %eax,%eax
f010370b:	0f 84 66 01 00 00    	je     f0103877 <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103711:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103714:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103717:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010371a:	56                   	push   %esi
f010371b:	6a 24                	push   $0x24
f010371d:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103720:	89 c1                	mov    %eax,%ecx
f0103722:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103725:	89 f8                	mov    %edi,%eax
f0103727:	e8 27 fe ff ff       	call   f0103553 <stab_binsearch>

	if (lfun <= rfun) {
f010372c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010372f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103732:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103735:	83 c4 08             	add    $0x8,%esp
f0103738:	39 d0                	cmp    %edx,%eax
f010373a:	7f 2b                	jg     f0103767 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010373c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010373f:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103742:	8b 11                	mov    (%ecx),%edx
f0103744:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103747:	2b 7d b8             	sub    -0x48(%ebp),%edi
f010374a:	39 fa                	cmp    %edi,%edx
f010374c:	73 06                	jae    f0103754 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010374e:	03 55 b8             	add    -0x48(%ebp),%edx
f0103751:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103754:	8b 51 08             	mov    0x8(%ecx),%edx
f0103757:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010375a:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010375c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010375f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103762:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103765:	eb 0f                	jmp    f0103776 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103767:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010376a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010376d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103770:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103773:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103776:	83 ec 08             	sub    $0x8,%esp
f0103779:	6a 3a                	push   $0x3a
f010377b:	ff 73 08             	pushl  0x8(%ebx)
f010377e:	e8 01 09 00 00       	call   f0104084 <strfind>
f0103783:	2b 43 08             	sub    0x8(%ebx),%eax
f0103786:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	which one.
	// Your code here.
 
//	If *region_left > *region_right, then 'addr' is not contained in any
//	matching stab.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103789:	83 c4 08             	add    $0x8,%esp
f010378c:	56                   	push   %esi
f010378d:	6a 44                	push   $0x44
f010378f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103792:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103795:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103798:	89 f0                	mov    %esi,%eax
f010379a:	e8 b4 fd ff ff       	call   f0103553 <stab_binsearch>
                 if(lline > rline)
f010379f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01037a2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01037a5:	83 c4 10             	add    $0x10,%esp
f01037a8:	39 c2                	cmp    %eax,%edx
f01037aa:	0f 8f ce 00 00 00    	jg     f010387e <debuginfo_eip+0x235>
                 return -1;
		 info->eip_line = stabs[rline].n_desc;
f01037b0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01037b3:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f01037b8:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01037bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037be:	89 d0                	mov    %edx,%eax
f01037c0:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01037c3:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01037c6:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01037ca:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01037cd:	eb 0a                	jmp    f01037d9 <debuginfo_eip+0x190>
f01037cf:	83 e8 01             	sub    $0x1,%eax
f01037d2:	83 ea 0c             	sub    $0xc,%edx
f01037d5:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01037d9:	39 c7                	cmp    %eax,%edi
f01037db:	7e 05                	jle    f01037e2 <debuginfo_eip+0x199>
f01037dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037e0:	eb 47                	jmp    f0103829 <debuginfo_eip+0x1e0>
	       && stabs[lline].n_type != N_SOL
f01037e2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01037e6:	80 f9 84             	cmp    $0x84,%cl
f01037e9:	75 0e                	jne    f01037f9 <debuginfo_eip+0x1b0>
f01037eb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037ee:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01037f2:	74 1c                	je     f0103810 <debuginfo_eip+0x1c7>
f01037f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01037f7:	eb 17                	jmp    f0103810 <debuginfo_eip+0x1c7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01037f9:	80 f9 64             	cmp    $0x64,%cl
f01037fc:	75 d1                	jne    f01037cf <debuginfo_eip+0x186>
f01037fe:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103802:	74 cb                	je     f01037cf <debuginfo_eip+0x186>
f0103804:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103807:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010380b:	74 03                	je     f0103810 <debuginfo_eip+0x1c7>
f010380d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103810:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103813:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103816:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103819:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010381c:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010381f:	29 f8                	sub    %edi,%eax
f0103821:	39 c2                	cmp    %eax,%edx
f0103823:	73 04                	jae    f0103829 <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103825:	01 fa                	add    %edi,%edx
f0103827:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103829:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010382c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010382f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103834:	39 f2                	cmp    %esi,%edx
f0103836:	7d 52                	jge    f010388a <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f0103838:	83 c2 01             	add    $0x1,%edx
f010383b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010383e:	89 d0                	mov    %edx,%eax
f0103840:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103843:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103846:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103849:	eb 04                	jmp    f010384f <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010384b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010384f:	39 c6                	cmp    %eax,%esi
f0103851:	7e 32                	jle    f0103885 <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103853:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103857:	83 c0 01             	add    $0x1,%eax
f010385a:	83 c2 0c             	add    $0xc,%edx
f010385d:	80 f9 a0             	cmp    $0xa0,%cl
f0103860:	74 e9                	je     f010384b <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103862:	b8 00 00 00 00       	mov    $0x0,%eax
f0103867:	eb 21                	jmp    f010388a <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010386e:	eb 1a                	jmp    f010388a <debuginfo_eip+0x241>
f0103870:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103875:	eb 13                	jmp    f010388a <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103877:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010387c:	eb 0c                	jmp    f010388a <debuginfo_eip+0x241>
 
//	If *region_left > *region_right, then 'addr' is not contained in any
//	matching stab.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
                 if(lline > rline)
                 return -1;
f010387e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103883:	eb 05                	jmp    f010388a <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103885:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010388a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010388d:	5b                   	pop    %ebx
f010388e:	5e                   	pop    %esi
f010388f:	5f                   	pop    %edi
f0103890:	5d                   	pop    %ebp
f0103891:	c3                   	ret    

f0103892 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103892:	55                   	push   %ebp
f0103893:	89 e5                	mov    %esp,%ebp
f0103895:	57                   	push   %edi
f0103896:	56                   	push   %esi
f0103897:	53                   	push   %ebx
f0103898:	83 ec 1c             	sub    $0x1c,%esp
f010389b:	89 c7                	mov    %eax,%edi
f010389d:	89 d6                	mov    %edx,%esi
f010389f:	8b 45 08             	mov    0x8(%ebp),%eax
f01038a2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01038ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01038ae:	bb 00 00 00 00       	mov    $0x0,%ebx
f01038b3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01038b6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01038b9:	39 d3                	cmp    %edx,%ebx
f01038bb:	72 05                	jb     f01038c2 <printnum+0x30>
f01038bd:	39 45 10             	cmp    %eax,0x10(%ebp)
f01038c0:	77 45                	ja     f0103907 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01038c2:	83 ec 0c             	sub    $0xc,%esp
f01038c5:	ff 75 18             	pushl  0x18(%ebp)
f01038c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01038cb:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01038ce:	53                   	push   %ebx
f01038cf:	ff 75 10             	pushl  0x10(%ebp)
f01038d2:	83 ec 08             	sub    $0x8,%esp
f01038d5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01038d8:	ff 75 e0             	pushl  -0x20(%ebp)
f01038db:	ff 75 dc             	pushl  -0x24(%ebp)
f01038de:	ff 75 d8             	pushl  -0x28(%ebp)
f01038e1:	e8 ca 09 00 00       	call   f01042b0 <__udivdi3>
f01038e6:	83 c4 18             	add    $0x18,%esp
f01038e9:	52                   	push   %edx
f01038ea:	50                   	push   %eax
f01038eb:	89 f2                	mov    %esi,%edx
f01038ed:	89 f8                	mov    %edi,%eax
f01038ef:	e8 9e ff ff ff       	call   f0103892 <printnum>
f01038f4:	83 c4 20             	add    $0x20,%esp
f01038f7:	eb 18                	jmp    f0103911 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	56                   	push   %esi
f01038fd:	ff 75 18             	pushl  0x18(%ebp)
f0103900:	ff d7                	call   *%edi
f0103902:	83 c4 10             	add    $0x10,%esp
f0103905:	eb 03                	jmp    f010390a <printnum+0x78>
f0103907:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010390a:	83 eb 01             	sub    $0x1,%ebx
f010390d:	85 db                	test   %ebx,%ebx
f010390f:	7f e8                	jg     f01038f9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103911:	83 ec 08             	sub    $0x8,%esp
f0103914:	56                   	push   %esi
f0103915:	83 ec 04             	sub    $0x4,%esp
f0103918:	ff 75 e4             	pushl  -0x1c(%ebp)
f010391b:	ff 75 e0             	pushl  -0x20(%ebp)
f010391e:	ff 75 dc             	pushl  -0x24(%ebp)
f0103921:	ff 75 d8             	pushl  -0x28(%ebp)
f0103924:	e8 b7 0a 00 00       	call   f01043e0 <__umoddi3>
f0103929:	83 c4 14             	add    $0x14,%esp
f010392c:	0f be 80 5a 5a 10 f0 	movsbl -0xfefa5a6(%eax),%eax
f0103933:	50                   	push   %eax
f0103934:	ff d7                	call   *%edi
}
f0103936:	83 c4 10             	add    $0x10,%esp
f0103939:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010393c:	5b                   	pop    %ebx
f010393d:	5e                   	pop    %esi
f010393e:	5f                   	pop    %edi
f010393f:	5d                   	pop    %ebp
f0103940:	c3                   	ret    

f0103941 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103941:	55                   	push   %ebp
f0103942:	89 e5                	mov    %esp,%ebp
f0103944:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103947:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010394b:	8b 10                	mov    (%eax),%edx
f010394d:	3b 50 04             	cmp    0x4(%eax),%edx
f0103950:	73 0a                	jae    f010395c <sprintputch+0x1b>
		*b->buf++ = ch;
f0103952:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103955:	89 08                	mov    %ecx,(%eax)
f0103957:	8b 45 08             	mov    0x8(%ebp),%eax
f010395a:	88 02                	mov    %al,(%edx)
}
f010395c:	5d                   	pop    %ebp
f010395d:	c3                   	ret    

f010395e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010395e:	55                   	push   %ebp
f010395f:	89 e5                	mov    %esp,%ebp
f0103961:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103964:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103967:	50                   	push   %eax
f0103968:	ff 75 10             	pushl  0x10(%ebp)
f010396b:	ff 75 0c             	pushl  0xc(%ebp)
f010396e:	ff 75 08             	pushl  0x8(%ebp)
f0103971:	e8 05 00 00 00       	call   f010397b <vprintfmt>
	va_end(ap);
}
f0103976:	83 c4 10             	add    $0x10,%esp
f0103979:	c9                   	leave  
f010397a:	c3                   	ret    

f010397b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010397b:	55                   	push   %ebp
f010397c:	89 e5                	mov    %esp,%ebp
f010397e:	57                   	push   %edi
f010397f:	56                   	push   %esi
f0103980:	53                   	push   %ebx
f0103981:	83 ec 2c             	sub    $0x2c,%esp
f0103984:	8b 75 08             	mov    0x8(%ebp),%esi
f0103987:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010398a:	8b 7d 10             	mov    0x10(%ebp),%edi
f010398d:	eb 12                	jmp    f01039a1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010398f:	85 c0                	test   %eax,%eax
f0103991:	0f 84 42 04 00 00    	je     f0103dd9 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103997:	83 ec 08             	sub    $0x8,%esp
f010399a:	53                   	push   %ebx
f010399b:	50                   	push   %eax
f010399c:	ff d6                	call   *%esi
f010399e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01039a1:	83 c7 01             	add    $0x1,%edi
f01039a4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01039a8:	83 f8 25             	cmp    $0x25,%eax
f01039ab:	75 e2                	jne    f010398f <vprintfmt+0x14>
f01039ad:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01039b1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01039b8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01039bf:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01039c6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039cb:	eb 07                	jmp    f01039d4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01039d0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039d4:	8d 47 01             	lea    0x1(%edi),%eax
f01039d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01039da:	0f b6 07             	movzbl (%edi),%eax
f01039dd:	0f b6 d0             	movzbl %al,%edx
f01039e0:	83 e8 23             	sub    $0x23,%eax
f01039e3:	3c 55                	cmp    $0x55,%al
f01039e5:	0f 87 d3 03 00 00    	ja     f0103dbe <vprintfmt+0x443>
f01039eb:	0f b6 c0             	movzbl %al,%eax
f01039ee:	ff 24 85 e4 5a 10 f0 	jmp    *-0xfefa51c(,%eax,4)
f01039f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01039f8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01039fc:	eb d6                	jmp    f01039d4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a01:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a06:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103a09:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103a0c:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103a10:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103a13:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103a16:	83 f9 09             	cmp    $0x9,%ecx
f0103a19:	77 3f                	ja     f0103a5a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103a1b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103a1e:	eb e9                	jmp    f0103a09 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103a20:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a23:	8b 00                	mov    (%eax),%eax
f0103a25:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a28:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a2b:	8d 40 04             	lea    0x4(%eax),%eax
f0103a2e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103a34:	eb 2a                	jmp    f0103a60 <vprintfmt+0xe5>
f0103a36:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a39:	85 c0                	test   %eax,%eax
f0103a3b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a40:	0f 49 d0             	cmovns %eax,%edx
f0103a43:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a49:	eb 89                	jmp    f01039d4 <vprintfmt+0x59>
f0103a4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103a4e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103a55:	e9 7a ff ff ff       	jmp    f01039d4 <vprintfmt+0x59>
f0103a5a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103a5d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103a60:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103a64:	0f 89 6a ff ff ff    	jns    f01039d4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103a6a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a70:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103a77:	e9 58 ff ff ff       	jmp    f01039d4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103a7c:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103a82:	e9 4d ff ff ff       	jmp    f01039d4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103a87:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a8a:	8d 78 04             	lea    0x4(%eax),%edi
f0103a8d:	83 ec 08             	sub    $0x8,%esp
f0103a90:	53                   	push   %ebx
f0103a91:	ff 30                	pushl  (%eax)
f0103a93:	ff d6                	call   *%esi
			break;
f0103a95:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103a98:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103a9e:	e9 fe fe ff ff       	jmp    f01039a1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103aa3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aa6:	8d 78 04             	lea    0x4(%eax),%edi
f0103aa9:	8b 00                	mov    (%eax),%eax
f0103aab:	99                   	cltd   
f0103aac:	31 d0                	xor    %edx,%eax
f0103aae:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103ab0:	83 f8 06             	cmp    $0x6,%eax
f0103ab3:	7f 0b                	jg     f0103ac0 <vprintfmt+0x145>
f0103ab5:	8b 14 85 3c 5c 10 f0 	mov    -0xfefa3c4(,%eax,4),%edx
f0103abc:	85 d2                	test   %edx,%edx
f0103abe:	75 1b                	jne    f0103adb <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103ac0:	50                   	push   %eax
f0103ac1:	68 72 5a 10 f0       	push   $0xf0105a72
f0103ac6:	53                   	push   %ebx
f0103ac7:	56                   	push   %esi
f0103ac8:	e8 91 fe ff ff       	call   f010395e <printfmt>
f0103acd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103ad0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ad3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103ad6:	e9 c6 fe ff ff       	jmp    f01039a1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103adb:	52                   	push   %edx
f0103adc:	68 c8 4a 10 f0       	push   $0xf0104ac8
f0103ae1:	53                   	push   %ebx
f0103ae2:	56                   	push   %esi
f0103ae3:	e8 76 fe ff ff       	call   f010395e <printfmt>
f0103ae8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103aeb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103af1:	e9 ab fe ff ff       	jmp    f01039a1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103af6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103af9:	83 c0 04             	add    $0x4,%eax
f0103afc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103aff:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b02:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103b04:	85 ff                	test   %edi,%edi
f0103b06:	b8 6b 5a 10 f0       	mov    $0xf0105a6b,%eax
f0103b0b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103b0e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103b12:	0f 8e 94 00 00 00    	jle    f0103bac <vprintfmt+0x231>
f0103b18:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103b1c:	0f 84 98 00 00 00    	je     f0103bba <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b22:	83 ec 08             	sub    $0x8,%esp
f0103b25:	ff 75 d0             	pushl  -0x30(%ebp)
f0103b28:	57                   	push   %edi
f0103b29:	e8 0c 04 00 00       	call   f0103f3a <strnlen>
f0103b2e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103b31:	29 c1                	sub    %eax,%ecx
f0103b33:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103b36:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103b39:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103b3d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103b40:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103b43:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b45:	eb 0f                	jmp    f0103b56 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103b47:	83 ec 08             	sub    $0x8,%esp
f0103b4a:	53                   	push   %ebx
f0103b4b:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b4e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b50:	83 ef 01             	sub    $0x1,%edi
f0103b53:	83 c4 10             	add    $0x10,%esp
f0103b56:	85 ff                	test   %edi,%edi
f0103b58:	7f ed                	jg     f0103b47 <vprintfmt+0x1cc>
f0103b5a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b5d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103b60:	85 c9                	test   %ecx,%ecx
f0103b62:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b67:	0f 49 c1             	cmovns %ecx,%eax
f0103b6a:	29 c1                	sub    %eax,%ecx
f0103b6c:	89 75 08             	mov    %esi,0x8(%ebp)
f0103b6f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103b72:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103b75:	89 cb                	mov    %ecx,%ebx
f0103b77:	eb 4d                	jmp    f0103bc6 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103b79:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103b7d:	74 1b                	je     f0103b9a <vprintfmt+0x21f>
f0103b7f:	0f be c0             	movsbl %al,%eax
f0103b82:	83 e8 20             	sub    $0x20,%eax
f0103b85:	83 f8 5e             	cmp    $0x5e,%eax
f0103b88:	76 10                	jbe    f0103b9a <vprintfmt+0x21f>
					putch('?', putdat);
f0103b8a:	83 ec 08             	sub    $0x8,%esp
f0103b8d:	ff 75 0c             	pushl  0xc(%ebp)
f0103b90:	6a 3f                	push   $0x3f
f0103b92:	ff 55 08             	call   *0x8(%ebp)
f0103b95:	83 c4 10             	add    $0x10,%esp
f0103b98:	eb 0d                	jmp    f0103ba7 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103b9a:	83 ec 08             	sub    $0x8,%esp
f0103b9d:	ff 75 0c             	pushl  0xc(%ebp)
f0103ba0:	52                   	push   %edx
f0103ba1:	ff 55 08             	call   *0x8(%ebp)
f0103ba4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103ba7:	83 eb 01             	sub    $0x1,%ebx
f0103baa:	eb 1a                	jmp    f0103bc6 <vprintfmt+0x24b>
f0103bac:	89 75 08             	mov    %esi,0x8(%ebp)
f0103baf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103bb2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103bb5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103bb8:	eb 0c                	jmp    f0103bc6 <vprintfmt+0x24b>
f0103bba:	89 75 08             	mov    %esi,0x8(%ebp)
f0103bbd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103bc0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103bc3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103bc6:	83 c7 01             	add    $0x1,%edi
f0103bc9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103bcd:	0f be d0             	movsbl %al,%edx
f0103bd0:	85 d2                	test   %edx,%edx
f0103bd2:	74 23                	je     f0103bf7 <vprintfmt+0x27c>
f0103bd4:	85 f6                	test   %esi,%esi
f0103bd6:	78 a1                	js     f0103b79 <vprintfmt+0x1fe>
f0103bd8:	83 ee 01             	sub    $0x1,%esi
f0103bdb:	79 9c                	jns    f0103b79 <vprintfmt+0x1fe>
f0103bdd:	89 df                	mov    %ebx,%edi
f0103bdf:	8b 75 08             	mov    0x8(%ebp),%esi
f0103be2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103be5:	eb 18                	jmp    f0103bff <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103be7:	83 ec 08             	sub    $0x8,%esp
f0103bea:	53                   	push   %ebx
f0103beb:	6a 20                	push   $0x20
f0103bed:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103bef:	83 ef 01             	sub    $0x1,%edi
f0103bf2:	83 c4 10             	add    $0x10,%esp
f0103bf5:	eb 08                	jmp    f0103bff <vprintfmt+0x284>
f0103bf7:	89 df                	mov    %ebx,%edi
f0103bf9:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bfc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bff:	85 ff                	test   %edi,%edi
f0103c01:	7f e4                	jg     f0103be7 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c03:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103c06:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c0c:	e9 90 fd ff ff       	jmp    f01039a1 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103c11:	83 f9 01             	cmp    $0x1,%ecx
f0103c14:	7e 19                	jle    f0103c2f <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103c16:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c19:	8b 50 04             	mov    0x4(%eax),%edx
f0103c1c:	8b 00                	mov    (%eax),%eax
f0103c1e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c21:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c24:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c27:	8d 40 08             	lea    0x8(%eax),%eax
f0103c2a:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c2d:	eb 38                	jmp    f0103c67 <vprintfmt+0x2ec>
	else if (lflag)
f0103c2f:	85 c9                	test   %ecx,%ecx
f0103c31:	74 1b                	je     f0103c4e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103c33:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c36:	8b 00                	mov    (%eax),%eax
f0103c38:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c3b:	89 c1                	mov    %eax,%ecx
f0103c3d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103c40:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103c43:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c46:	8d 40 04             	lea    0x4(%eax),%eax
f0103c49:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c4c:	eb 19                	jmp    f0103c67 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103c4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c51:	8b 00                	mov    (%eax),%eax
f0103c53:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c56:	89 c1                	mov    %eax,%ecx
f0103c58:	c1 f9 1f             	sar    $0x1f,%ecx
f0103c5b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103c5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c61:	8d 40 04             	lea    0x4(%eax),%eax
f0103c64:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103c67:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103c6a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103c6d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103c72:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103c76:	0f 89 0e 01 00 00    	jns    f0103d8a <vprintfmt+0x40f>
				putch('-', putdat);
f0103c7c:	83 ec 08             	sub    $0x8,%esp
f0103c7f:	53                   	push   %ebx
f0103c80:	6a 2d                	push   $0x2d
f0103c82:	ff d6                	call   *%esi
				num = -(long long) num;
f0103c84:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103c87:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103c8a:	f7 da                	neg    %edx
f0103c8c:	83 d1 00             	adc    $0x0,%ecx
f0103c8f:	f7 d9                	neg    %ecx
f0103c91:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103c94:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c99:	e9 ec 00 00 00       	jmp    f0103d8a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103c9e:	83 f9 01             	cmp    $0x1,%ecx
f0103ca1:	7e 18                	jle    f0103cbb <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103ca3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ca6:	8b 10                	mov    (%eax),%edx
f0103ca8:	8b 48 04             	mov    0x4(%eax),%ecx
f0103cab:	8d 40 08             	lea    0x8(%eax),%eax
f0103cae:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103cb1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103cb6:	e9 cf 00 00 00       	jmp    f0103d8a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103cbb:	85 c9                	test   %ecx,%ecx
f0103cbd:	74 1a                	je     f0103cd9 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103cbf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cc2:	8b 10                	mov    (%eax),%edx
f0103cc4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cc9:	8d 40 04             	lea    0x4(%eax),%eax
f0103ccc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103ccf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103cd4:	e9 b1 00 00 00       	jmp    f0103d8a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103cd9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cdc:	8b 10                	mov    (%eax),%edx
f0103cde:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ce3:	8d 40 04             	lea    0x4(%eax),%eax
f0103ce6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103ce9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103cee:	e9 97 00 00 00       	jmp    f0103d8a <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103cf3:	83 ec 08             	sub    $0x8,%esp
f0103cf6:	53                   	push   %ebx
f0103cf7:	6a 58                	push   $0x58
f0103cf9:	ff d6                	call   *%esi
			putch('X', putdat);
f0103cfb:	83 c4 08             	add    $0x8,%esp
f0103cfe:	53                   	push   %ebx
f0103cff:	6a 58                	push   $0x58
f0103d01:	ff d6                	call   *%esi
			putch('X', putdat);
f0103d03:	83 c4 08             	add    $0x8,%esp
f0103d06:	53                   	push   %ebx
f0103d07:	6a 58                	push   $0x58
f0103d09:	ff d6                	call   *%esi
			break;
f0103d0b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103d11:	e9 8b fc ff ff       	jmp    f01039a1 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103d16:	83 ec 08             	sub    $0x8,%esp
f0103d19:	53                   	push   %ebx
f0103d1a:	6a 30                	push   $0x30
f0103d1c:	ff d6                	call   *%esi
			putch('x', putdat);
f0103d1e:	83 c4 08             	add    $0x8,%esp
f0103d21:	53                   	push   %ebx
f0103d22:	6a 78                	push   $0x78
f0103d24:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103d26:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d29:	8b 10                	mov    (%eax),%edx
f0103d2b:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103d30:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103d33:	8d 40 04             	lea    0x4(%eax),%eax
f0103d36:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103d39:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103d3e:	eb 4a                	jmp    f0103d8a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103d40:	83 f9 01             	cmp    $0x1,%ecx
f0103d43:	7e 15                	jle    f0103d5a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103d45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d48:	8b 10                	mov    (%eax),%edx
f0103d4a:	8b 48 04             	mov    0x4(%eax),%ecx
f0103d4d:	8d 40 08             	lea    0x8(%eax),%eax
f0103d50:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103d53:	b8 10 00 00 00       	mov    $0x10,%eax
f0103d58:	eb 30                	jmp    f0103d8a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103d5a:	85 c9                	test   %ecx,%ecx
f0103d5c:	74 17                	je     f0103d75 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103d5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d61:	8b 10                	mov    (%eax),%edx
f0103d63:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d68:	8d 40 04             	lea    0x4(%eax),%eax
f0103d6b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103d6e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103d73:	eb 15                	jmp    f0103d8a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103d75:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d78:	8b 10                	mov    (%eax),%edx
f0103d7a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d7f:	8d 40 04             	lea    0x4(%eax),%eax
f0103d82:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103d85:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103d8a:	83 ec 0c             	sub    $0xc,%esp
f0103d8d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103d91:	57                   	push   %edi
f0103d92:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d95:	50                   	push   %eax
f0103d96:	51                   	push   %ecx
f0103d97:	52                   	push   %edx
f0103d98:	89 da                	mov    %ebx,%edx
f0103d9a:	89 f0                	mov    %esi,%eax
f0103d9c:	e8 f1 fa ff ff       	call   f0103892 <printnum>
			break;
f0103da1:	83 c4 20             	add    $0x20,%esp
f0103da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103da7:	e9 f5 fb ff ff       	jmp    f01039a1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103dac:	83 ec 08             	sub    $0x8,%esp
f0103daf:	53                   	push   %ebx
f0103db0:	52                   	push   %edx
f0103db1:	ff d6                	call   *%esi
			break;
f0103db3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103db6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103db9:	e9 e3 fb ff ff       	jmp    f01039a1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103dbe:	83 ec 08             	sub    $0x8,%esp
f0103dc1:	53                   	push   %ebx
f0103dc2:	6a 25                	push   $0x25
f0103dc4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103dc6:	83 c4 10             	add    $0x10,%esp
f0103dc9:	eb 03                	jmp    f0103dce <vprintfmt+0x453>
f0103dcb:	83 ef 01             	sub    $0x1,%edi
f0103dce:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103dd2:	75 f7                	jne    f0103dcb <vprintfmt+0x450>
f0103dd4:	e9 c8 fb ff ff       	jmp    f01039a1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103dd9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ddc:	5b                   	pop    %ebx
f0103ddd:	5e                   	pop    %esi
f0103dde:	5f                   	pop    %edi
f0103ddf:	5d                   	pop    %ebp
f0103de0:	c3                   	ret    

f0103de1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103de1:	55                   	push   %ebp
f0103de2:	89 e5                	mov    %esp,%ebp
f0103de4:	83 ec 18             	sub    $0x18,%esp
f0103de7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dea:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103ded:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103df0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103df4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103df7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103dfe:	85 c0                	test   %eax,%eax
f0103e00:	74 26                	je     f0103e28 <vsnprintf+0x47>
f0103e02:	85 d2                	test   %edx,%edx
f0103e04:	7e 22                	jle    f0103e28 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e06:	ff 75 14             	pushl  0x14(%ebp)
f0103e09:	ff 75 10             	pushl  0x10(%ebp)
f0103e0c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e0f:	50                   	push   %eax
f0103e10:	68 41 39 10 f0       	push   $0xf0103941
f0103e15:	e8 61 fb ff ff       	call   f010397b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e1d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e23:	83 c4 10             	add    $0x10,%esp
f0103e26:	eb 05                	jmp    f0103e2d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103e28:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103e2d:	c9                   	leave  
f0103e2e:	c3                   	ret    

f0103e2f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e2f:	55                   	push   %ebp
f0103e30:	89 e5                	mov    %esp,%ebp
f0103e32:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103e35:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103e38:	50                   	push   %eax
f0103e39:	ff 75 10             	pushl  0x10(%ebp)
f0103e3c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e3f:	ff 75 08             	pushl  0x8(%ebp)
f0103e42:	e8 9a ff ff ff       	call   f0103de1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103e47:	c9                   	leave  
f0103e48:	c3                   	ret    

f0103e49 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103e49:	55                   	push   %ebp
f0103e4a:	89 e5                	mov    %esp,%ebp
f0103e4c:	57                   	push   %edi
f0103e4d:	56                   	push   %esi
f0103e4e:	53                   	push   %ebx
f0103e4f:	83 ec 0c             	sub    $0xc,%esp
f0103e52:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103e55:	85 c0                	test   %eax,%eax
f0103e57:	74 11                	je     f0103e6a <readline+0x21>
		cprintf("%s", prompt);
f0103e59:	83 ec 08             	sub    $0x8,%esp
f0103e5c:	50                   	push   %eax
f0103e5d:	68 c8 4a 10 f0       	push   $0xf0104ac8
f0103e62:	e8 4f f0 ff ff       	call   f0102eb6 <cprintf>
f0103e67:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103e6a:	83 ec 0c             	sub    $0xc,%esp
f0103e6d:	6a 00                	push   $0x0
f0103e6f:	e8 c2 c7 ff ff       	call   f0100636 <iscons>
f0103e74:	89 c7                	mov    %eax,%edi
f0103e76:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103e79:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103e7e:	e8 a2 c7 ff ff       	call   f0100625 <getchar>
f0103e83:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103e85:	85 c0                	test   %eax,%eax
f0103e87:	79 18                	jns    f0103ea1 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103e89:	83 ec 08             	sub    $0x8,%esp
f0103e8c:	50                   	push   %eax
f0103e8d:	68 58 5c 10 f0       	push   $0xf0105c58
f0103e92:	e8 1f f0 ff ff       	call   f0102eb6 <cprintf>
			return NULL;
f0103e97:	83 c4 10             	add    $0x10,%esp
f0103e9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e9f:	eb 79                	jmp    f0103f1a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103ea1:	83 f8 08             	cmp    $0x8,%eax
f0103ea4:	0f 94 c2             	sete   %dl
f0103ea7:	83 f8 7f             	cmp    $0x7f,%eax
f0103eaa:	0f 94 c0             	sete   %al
f0103ead:	08 c2                	or     %al,%dl
f0103eaf:	74 1a                	je     f0103ecb <readline+0x82>
f0103eb1:	85 f6                	test   %esi,%esi
f0103eb3:	7e 16                	jle    f0103ecb <readline+0x82>
			if (echoing)
f0103eb5:	85 ff                	test   %edi,%edi
f0103eb7:	74 0d                	je     f0103ec6 <readline+0x7d>
				cputchar('\b');
f0103eb9:	83 ec 0c             	sub    $0xc,%esp
f0103ebc:	6a 08                	push   $0x8
f0103ebe:	e8 52 c7 ff ff       	call   f0100615 <cputchar>
f0103ec3:	83 c4 10             	add    $0x10,%esp
			i--;
f0103ec6:	83 ee 01             	sub    $0x1,%esi
f0103ec9:	eb b3                	jmp    f0103e7e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103ecb:	83 fb 1f             	cmp    $0x1f,%ebx
f0103ece:	7e 23                	jle    f0103ef3 <readline+0xaa>
f0103ed0:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103ed6:	7f 1b                	jg     f0103ef3 <readline+0xaa>
			if (echoing)
f0103ed8:	85 ff                	test   %edi,%edi
f0103eda:	74 0c                	je     f0103ee8 <readline+0x9f>
				cputchar(c);
f0103edc:	83 ec 0c             	sub    $0xc,%esp
f0103edf:	53                   	push   %ebx
f0103ee0:	e8 30 c7 ff ff       	call   f0100615 <cputchar>
f0103ee5:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103ee8:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0103eee:	8d 76 01             	lea    0x1(%esi),%esi
f0103ef1:	eb 8b                	jmp    f0103e7e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103ef3:	83 fb 0a             	cmp    $0xa,%ebx
f0103ef6:	74 05                	je     f0103efd <readline+0xb4>
f0103ef8:	83 fb 0d             	cmp    $0xd,%ebx
f0103efb:	75 81                	jne    f0103e7e <readline+0x35>
			if (echoing)
f0103efd:	85 ff                	test   %edi,%edi
f0103eff:	74 0d                	je     f0103f0e <readline+0xc5>
				cputchar('\n');
f0103f01:	83 ec 0c             	sub    $0xc,%esp
f0103f04:	6a 0a                	push   $0xa
f0103f06:	e8 0a c7 ff ff       	call   f0100615 <cputchar>
f0103f0b:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103f0e:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0103f15:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f0103f1a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f1d:	5b                   	pop    %ebx
f0103f1e:	5e                   	pop    %esi
f0103f1f:	5f                   	pop    %edi
f0103f20:	5d                   	pop    %ebp
f0103f21:	c3                   	ret    

f0103f22 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f22:	55                   	push   %ebp
f0103f23:	89 e5                	mov    %esp,%ebp
f0103f25:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f28:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f2d:	eb 03                	jmp    f0103f32 <strlen+0x10>
		n++;
f0103f2f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f32:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103f36:	75 f7                	jne    f0103f2f <strlen+0xd>
		n++;
	return n;
}
f0103f38:	5d                   	pop    %ebp
f0103f39:	c3                   	ret    

f0103f3a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103f3a:	55                   	push   %ebp
f0103f3b:	89 e5                	mov    %esp,%ebp
f0103f3d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103f40:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f43:	ba 00 00 00 00       	mov    $0x0,%edx
f0103f48:	eb 03                	jmp    f0103f4d <strnlen+0x13>
		n++;
f0103f4a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f4d:	39 c2                	cmp    %eax,%edx
f0103f4f:	74 08                	je     f0103f59 <strnlen+0x1f>
f0103f51:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103f55:	75 f3                	jne    f0103f4a <strnlen+0x10>
f0103f57:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103f59:	5d                   	pop    %ebp
f0103f5a:	c3                   	ret    

f0103f5b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103f5b:	55                   	push   %ebp
f0103f5c:	89 e5                	mov    %esp,%ebp
f0103f5e:	53                   	push   %ebx
f0103f5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103f65:	89 c2                	mov    %eax,%edx
f0103f67:	83 c2 01             	add    $0x1,%edx
f0103f6a:	83 c1 01             	add    $0x1,%ecx
f0103f6d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103f71:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103f74:	84 db                	test   %bl,%bl
f0103f76:	75 ef                	jne    f0103f67 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103f78:	5b                   	pop    %ebx
f0103f79:	5d                   	pop    %ebp
f0103f7a:	c3                   	ret    

f0103f7b <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103f7b:	55                   	push   %ebp
f0103f7c:	89 e5                	mov    %esp,%ebp
f0103f7e:	53                   	push   %ebx
f0103f7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103f82:	53                   	push   %ebx
f0103f83:	e8 9a ff ff ff       	call   f0103f22 <strlen>
f0103f88:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103f8b:	ff 75 0c             	pushl  0xc(%ebp)
f0103f8e:	01 d8                	add    %ebx,%eax
f0103f90:	50                   	push   %eax
f0103f91:	e8 c5 ff ff ff       	call   f0103f5b <strcpy>
	return dst;
}
f0103f96:	89 d8                	mov    %ebx,%eax
f0103f98:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103f9b:	c9                   	leave  
f0103f9c:	c3                   	ret    

f0103f9d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103f9d:	55                   	push   %ebp
f0103f9e:	89 e5                	mov    %esp,%ebp
f0103fa0:	56                   	push   %esi
f0103fa1:	53                   	push   %ebx
f0103fa2:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fa5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103fa8:	89 f3                	mov    %esi,%ebx
f0103faa:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103fad:	89 f2                	mov    %esi,%edx
f0103faf:	eb 0f                	jmp    f0103fc0 <strncpy+0x23>
		*dst++ = *src;
f0103fb1:	83 c2 01             	add    $0x1,%edx
f0103fb4:	0f b6 01             	movzbl (%ecx),%eax
f0103fb7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103fba:	80 39 01             	cmpb   $0x1,(%ecx)
f0103fbd:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103fc0:	39 da                	cmp    %ebx,%edx
f0103fc2:	75 ed                	jne    f0103fb1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103fc4:	89 f0                	mov    %esi,%eax
f0103fc6:	5b                   	pop    %ebx
f0103fc7:	5e                   	pop    %esi
f0103fc8:	5d                   	pop    %ebp
f0103fc9:	c3                   	ret    

f0103fca <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103fca:	55                   	push   %ebp
f0103fcb:	89 e5                	mov    %esp,%ebp
f0103fcd:	56                   	push   %esi
f0103fce:	53                   	push   %ebx
f0103fcf:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fd2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103fd5:	8b 55 10             	mov    0x10(%ebp),%edx
f0103fd8:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103fda:	85 d2                	test   %edx,%edx
f0103fdc:	74 21                	je     f0103fff <strlcpy+0x35>
f0103fde:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103fe2:	89 f2                	mov    %esi,%edx
f0103fe4:	eb 09                	jmp    f0103fef <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103fe6:	83 c2 01             	add    $0x1,%edx
f0103fe9:	83 c1 01             	add    $0x1,%ecx
f0103fec:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103fef:	39 c2                	cmp    %eax,%edx
f0103ff1:	74 09                	je     f0103ffc <strlcpy+0x32>
f0103ff3:	0f b6 19             	movzbl (%ecx),%ebx
f0103ff6:	84 db                	test   %bl,%bl
f0103ff8:	75 ec                	jne    f0103fe6 <strlcpy+0x1c>
f0103ffa:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103ffc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103fff:	29 f0                	sub    %esi,%eax
}
f0104001:	5b                   	pop    %ebx
f0104002:	5e                   	pop    %esi
f0104003:	5d                   	pop    %ebp
f0104004:	c3                   	ret    

f0104005 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104005:	55                   	push   %ebp
f0104006:	89 e5                	mov    %esp,%ebp
f0104008:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010400b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010400e:	eb 06                	jmp    f0104016 <strcmp+0x11>
		p++, q++;
f0104010:	83 c1 01             	add    $0x1,%ecx
f0104013:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104016:	0f b6 01             	movzbl (%ecx),%eax
f0104019:	84 c0                	test   %al,%al
f010401b:	74 04                	je     f0104021 <strcmp+0x1c>
f010401d:	3a 02                	cmp    (%edx),%al
f010401f:	74 ef                	je     f0104010 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104021:	0f b6 c0             	movzbl %al,%eax
f0104024:	0f b6 12             	movzbl (%edx),%edx
f0104027:	29 d0                	sub    %edx,%eax
}
f0104029:	5d                   	pop    %ebp
f010402a:	c3                   	ret    

f010402b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010402b:	55                   	push   %ebp
f010402c:	89 e5                	mov    %esp,%ebp
f010402e:	53                   	push   %ebx
f010402f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104032:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104035:	89 c3                	mov    %eax,%ebx
f0104037:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010403a:	eb 06                	jmp    f0104042 <strncmp+0x17>
		n--, p++, q++;
f010403c:	83 c0 01             	add    $0x1,%eax
f010403f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104042:	39 d8                	cmp    %ebx,%eax
f0104044:	74 15                	je     f010405b <strncmp+0x30>
f0104046:	0f b6 08             	movzbl (%eax),%ecx
f0104049:	84 c9                	test   %cl,%cl
f010404b:	74 04                	je     f0104051 <strncmp+0x26>
f010404d:	3a 0a                	cmp    (%edx),%cl
f010404f:	74 eb                	je     f010403c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104051:	0f b6 00             	movzbl (%eax),%eax
f0104054:	0f b6 12             	movzbl (%edx),%edx
f0104057:	29 d0                	sub    %edx,%eax
f0104059:	eb 05                	jmp    f0104060 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010405b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104060:	5b                   	pop    %ebx
f0104061:	5d                   	pop    %ebp
f0104062:	c3                   	ret    

f0104063 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104063:	55                   	push   %ebp
f0104064:	89 e5                	mov    %esp,%ebp
f0104066:	8b 45 08             	mov    0x8(%ebp),%eax
f0104069:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010406d:	eb 07                	jmp    f0104076 <strchr+0x13>
		if (*s == c)
f010406f:	38 ca                	cmp    %cl,%dl
f0104071:	74 0f                	je     f0104082 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104073:	83 c0 01             	add    $0x1,%eax
f0104076:	0f b6 10             	movzbl (%eax),%edx
f0104079:	84 d2                	test   %dl,%dl
f010407b:	75 f2                	jne    f010406f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010407d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104082:	5d                   	pop    %ebp
f0104083:	c3                   	ret    

f0104084 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104084:	55                   	push   %ebp
f0104085:	89 e5                	mov    %esp,%ebp
f0104087:	8b 45 08             	mov    0x8(%ebp),%eax
f010408a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010408e:	eb 03                	jmp    f0104093 <strfind+0xf>
f0104090:	83 c0 01             	add    $0x1,%eax
f0104093:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104096:	38 ca                	cmp    %cl,%dl
f0104098:	74 04                	je     f010409e <strfind+0x1a>
f010409a:	84 d2                	test   %dl,%dl
f010409c:	75 f2                	jne    f0104090 <strfind+0xc>
			break;
	return (char *) s;
}
f010409e:	5d                   	pop    %ebp
f010409f:	c3                   	ret    

f01040a0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01040a0:	55                   	push   %ebp
f01040a1:	89 e5                	mov    %esp,%ebp
f01040a3:	57                   	push   %edi
f01040a4:	56                   	push   %esi
f01040a5:	53                   	push   %ebx
f01040a6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01040a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01040ac:	85 c9                	test   %ecx,%ecx
f01040ae:	74 36                	je     f01040e6 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01040b0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01040b6:	75 28                	jne    f01040e0 <memset+0x40>
f01040b8:	f6 c1 03             	test   $0x3,%cl
f01040bb:	75 23                	jne    f01040e0 <memset+0x40>
		c &= 0xFF;
f01040bd:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01040c1:	89 d3                	mov    %edx,%ebx
f01040c3:	c1 e3 08             	shl    $0x8,%ebx
f01040c6:	89 d6                	mov    %edx,%esi
f01040c8:	c1 e6 18             	shl    $0x18,%esi
f01040cb:	89 d0                	mov    %edx,%eax
f01040cd:	c1 e0 10             	shl    $0x10,%eax
f01040d0:	09 f0                	or     %esi,%eax
f01040d2:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01040d4:	89 d8                	mov    %ebx,%eax
f01040d6:	09 d0                	or     %edx,%eax
f01040d8:	c1 e9 02             	shr    $0x2,%ecx
f01040db:	fc                   	cld    
f01040dc:	f3 ab                	rep stos %eax,%es:(%edi)
f01040de:	eb 06                	jmp    f01040e6 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01040e0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040e3:	fc                   	cld    
f01040e4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01040e6:	89 f8                	mov    %edi,%eax
f01040e8:	5b                   	pop    %ebx
f01040e9:	5e                   	pop    %esi
f01040ea:	5f                   	pop    %edi
f01040eb:	5d                   	pop    %ebp
f01040ec:	c3                   	ret    

f01040ed <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01040ed:	55                   	push   %ebp
f01040ee:	89 e5                	mov    %esp,%ebp
f01040f0:	57                   	push   %edi
f01040f1:	56                   	push   %esi
f01040f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01040f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01040f8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01040fb:	39 c6                	cmp    %eax,%esi
f01040fd:	73 35                	jae    f0104134 <memmove+0x47>
f01040ff:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104102:	39 d0                	cmp    %edx,%eax
f0104104:	73 2e                	jae    f0104134 <memmove+0x47>
		s += n;
		d += n;
f0104106:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104109:	89 d6                	mov    %edx,%esi
f010410b:	09 fe                	or     %edi,%esi
f010410d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104113:	75 13                	jne    f0104128 <memmove+0x3b>
f0104115:	f6 c1 03             	test   $0x3,%cl
f0104118:	75 0e                	jne    f0104128 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010411a:	83 ef 04             	sub    $0x4,%edi
f010411d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104120:	c1 e9 02             	shr    $0x2,%ecx
f0104123:	fd                   	std    
f0104124:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104126:	eb 09                	jmp    f0104131 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104128:	83 ef 01             	sub    $0x1,%edi
f010412b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010412e:	fd                   	std    
f010412f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104131:	fc                   	cld    
f0104132:	eb 1d                	jmp    f0104151 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104134:	89 f2                	mov    %esi,%edx
f0104136:	09 c2                	or     %eax,%edx
f0104138:	f6 c2 03             	test   $0x3,%dl
f010413b:	75 0f                	jne    f010414c <memmove+0x5f>
f010413d:	f6 c1 03             	test   $0x3,%cl
f0104140:	75 0a                	jne    f010414c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104142:	c1 e9 02             	shr    $0x2,%ecx
f0104145:	89 c7                	mov    %eax,%edi
f0104147:	fc                   	cld    
f0104148:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010414a:	eb 05                	jmp    f0104151 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010414c:	89 c7                	mov    %eax,%edi
f010414e:	fc                   	cld    
f010414f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104151:	5e                   	pop    %esi
f0104152:	5f                   	pop    %edi
f0104153:	5d                   	pop    %ebp
f0104154:	c3                   	ret    

f0104155 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104155:	55                   	push   %ebp
f0104156:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104158:	ff 75 10             	pushl  0x10(%ebp)
f010415b:	ff 75 0c             	pushl  0xc(%ebp)
f010415e:	ff 75 08             	pushl  0x8(%ebp)
f0104161:	e8 87 ff ff ff       	call   f01040ed <memmove>
}
f0104166:	c9                   	leave  
f0104167:	c3                   	ret    

f0104168 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104168:	55                   	push   %ebp
f0104169:	89 e5                	mov    %esp,%ebp
f010416b:	56                   	push   %esi
f010416c:	53                   	push   %ebx
f010416d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104170:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104173:	89 c6                	mov    %eax,%esi
f0104175:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104178:	eb 1a                	jmp    f0104194 <memcmp+0x2c>
		if (*s1 != *s2)
f010417a:	0f b6 08             	movzbl (%eax),%ecx
f010417d:	0f b6 1a             	movzbl (%edx),%ebx
f0104180:	38 d9                	cmp    %bl,%cl
f0104182:	74 0a                	je     f010418e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104184:	0f b6 c1             	movzbl %cl,%eax
f0104187:	0f b6 db             	movzbl %bl,%ebx
f010418a:	29 d8                	sub    %ebx,%eax
f010418c:	eb 0f                	jmp    f010419d <memcmp+0x35>
		s1++, s2++;
f010418e:	83 c0 01             	add    $0x1,%eax
f0104191:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104194:	39 f0                	cmp    %esi,%eax
f0104196:	75 e2                	jne    f010417a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104198:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010419d:	5b                   	pop    %ebx
f010419e:	5e                   	pop    %esi
f010419f:	5d                   	pop    %ebp
f01041a0:	c3                   	ret    

f01041a1 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	53                   	push   %ebx
f01041a5:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01041a8:	89 c1                	mov    %eax,%ecx
f01041aa:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01041ad:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01041b1:	eb 0a                	jmp    f01041bd <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01041b3:	0f b6 10             	movzbl (%eax),%edx
f01041b6:	39 da                	cmp    %ebx,%edx
f01041b8:	74 07                	je     f01041c1 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01041ba:	83 c0 01             	add    $0x1,%eax
f01041bd:	39 c8                	cmp    %ecx,%eax
f01041bf:	72 f2                	jb     f01041b3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01041c1:	5b                   	pop    %ebx
f01041c2:	5d                   	pop    %ebp
f01041c3:	c3                   	ret    

f01041c4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01041c4:	55                   	push   %ebp
f01041c5:	89 e5                	mov    %esp,%ebp
f01041c7:	57                   	push   %edi
f01041c8:	56                   	push   %esi
f01041c9:	53                   	push   %ebx
f01041ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01041d0:	eb 03                	jmp    f01041d5 <strtol+0x11>
		s++;
f01041d2:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01041d5:	0f b6 01             	movzbl (%ecx),%eax
f01041d8:	3c 20                	cmp    $0x20,%al
f01041da:	74 f6                	je     f01041d2 <strtol+0xe>
f01041dc:	3c 09                	cmp    $0x9,%al
f01041de:	74 f2                	je     f01041d2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01041e0:	3c 2b                	cmp    $0x2b,%al
f01041e2:	75 0a                	jne    f01041ee <strtol+0x2a>
		s++;
f01041e4:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01041e7:	bf 00 00 00 00       	mov    $0x0,%edi
f01041ec:	eb 11                	jmp    f01041ff <strtol+0x3b>
f01041ee:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01041f3:	3c 2d                	cmp    $0x2d,%al
f01041f5:	75 08                	jne    f01041ff <strtol+0x3b>
		s++, neg = 1;
f01041f7:	83 c1 01             	add    $0x1,%ecx
f01041fa:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01041ff:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104205:	75 15                	jne    f010421c <strtol+0x58>
f0104207:	80 39 30             	cmpb   $0x30,(%ecx)
f010420a:	75 10                	jne    f010421c <strtol+0x58>
f010420c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104210:	75 7c                	jne    f010428e <strtol+0xca>
		s += 2, base = 16;
f0104212:	83 c1 02             	add    $0x2,%ecx
f0104215:	bb 10 00 00 00       	mov    $0x10,%ebx
f010421a:	eb 16                	jmp    f0104232 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010421c:	85 db                	test   %ebx,%ebx
f010421e:	75 12                	jne    f0104232 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104220:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104225:	80 39 30             	cmpb   $0x30,(%ecx)
f0104228:	75 08                	jne    f0104232 <strtol+0x6e>
		s++, base = 8;
f010422a:	83 c1 01             	add    $0x1,%ecx
f010422d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104232:	b8 00 00 00 00       	mov    $0x0,%eax
f0104237:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010423a:	0f b6 11             	movzbl (%ecx),%edx
f010423d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104240:	89 f3                	mov    %esi,%ebx
f0104242:	80 fb 09             	cmp    $0x9,%bl
f0104245:	77 08                	ja     f010424f <strtol+0x8b>
			dig = *s - '0';
f0104247:	0f be d2             	movsbl %dl,%edx
f010424a:	83 ea 30             	sub    $0x30,%edx
f010424d:	eb 22                	jmp    f0104271 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010424f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104252:	89 f3                	mov    %esi,%ebx
f0104254:	80 fb 19             	cmp    $0x19,%bl
f0104257:	77 08                	ja     f0104261 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104259:	0f be d2             	movsbl %dl,%edx
f010425c:	83 ea 57             	sub    $0x57,%edx
f010425f:	eb 10                	jmp    f0104271 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104261:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104264:	89 f3                	mov    %esi,%ebx
f0104266:	80 fb 19             	cmp    $0x19,%bl
f0104269:	77 16                	ja     f0104281 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010426b:	0f be d2             	movsbl %dl,%edx
f010426e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104271:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104274:	7d 0b                	jge    f0104281 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104276:	83 c1 01             	add    $0x1,%ecx
f0104279:	0f af 45 10          	imul   0x10(%ebp),%eax
f010427d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010427f:	eb b9                	jmp    f010423a <strtol+0x76>

	if (endptr)
f0104281:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104285:	74 0d                	je     f0104294 <strtol+0xd0>
		*endptr = (char *) s;
f0104287:	8b 75 0c             	mov    0xc(%ebp),%esi
f010428a:	89 0e                	mov    %ecx,(%esi)
f010428c:	eb 06                	jmp    f0104294 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010428e:	85 db                	test   %ebx,%ebx
f0104290:	74 98                	je     f010422a <strtol+0x66>
f0104292:	eb 9e                	jmp    f0104232 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104294:	89 c2                	mov    %eax,%edx
f0104296:	f7 da                	neg    %edx
f0104298:	85 ff                	test   %edi,%edi
f010429a:	0f 45 c2             	cmovne %edx,%eax
}
f010429d:	5b                   	pop    %ebx
f010429e:	5e                   	pop    %esi
f010429f:	5f                   	pop    %edi
f01042a0:	5d                   	pop    %ebp
f01042a1:	c3                   	ret    
f01042a2:	66 90                	xchg   %ax,%ax
f01042a4:	66 90                	xchg   %ax,%ax
f01042a6:	66 90                	xchg   %ax,%ax
f01042a8:	66 90                	xchg   %ax,%ax
f01042aa:	66 90                	xchg   %ax,%ax
f01042ac:	66 90                	xchg   %ax,%ax
f01042ae:	66 90                	xchg   %ax,%ax

f01042b0 <__udivdi3>:
f01042b0:	55                   	push   %ebp
f01042b1:	57                   	push   %edi
f01042b2:	56                   	push   %esi
f01042b3:	53                   	push   %ebx
f01042b4:	83 ec 1c             	sub    $0x1c,%esp
f01042b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01042bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01042bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01042c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01042c7:	85 f6                	test   %esi,%esi
f01042c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01042cd:	89 ca                	mov    %ecx,%edx
f01042cf:	89 f8                	mov    %edi,%eax
f01042d1:	75 3d                	jne    f0104310 <__udivdi3+0x60>
f01042d3:	39 cf                	cmp    %ecx,%edi
f01042d5:	0f 87 c5 00 00 00    	ja     f01043a0 <__udivdi3+0xf0>
f01042db:	85 ff                	test   %edi,%edi
f01042dd:	89 fd                	mov    %edi,%ebp
f01042df:	75 0b                	jne    f01042ec <__udivdi3+0x3c>
f01042e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01042e6:	31 d2                	xor    %edx,%edx
f01042e8:	f7 f7                	div    %edi
f01042ea:	89 c5                	mov    %eax,%ebp
f01042ec:	89 c8                	mov    %ecx,%eax
f01042ee:	31 d2                	xor    %edx,%edx
f01042f0:	f7 f5                	div    %ebp
f01042f2:	89 c1                	mov    %eax,%ecx
f01042f4:	89 d8                	mov    %ebx,%eax
f01042f6:	89 cf                	mov    %ecx,%edi
f01042f8:	f7 f5                	div    %ebp
f01042fa:	89 c3                	mov    %eax,%ebx
f01042fc:	89 d8                	mov    %ebx,%eax
f01042fe:	89 fa                	mov    %edi,%edx
f0104300:	83 c4 1c             	add    $0x1c,%esp
f0104303:	5b                   	pop    %ebx
f0104304:	5e                   	pop    %esi
f0104305:	5f                   	pop    %edi
f0104306:	5d                   	pop    %ebp
f0104307:	c3                   	ret    
f0104308:	90                   	nop
f0104309:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104310:	39 ce                	cmp    %ecx,%esi
f0104312:	77 74                	ja     f0104388 <__udivdi3+0xd8>
f0104314:	0f bd fe             	bsr    %esi,%edi
f0104317:	83 f7 1f             	xor    $0x1f,%edi
f010431a:	0f 84 98 00 00 00    	je     f01043b8 <__udivdi3+0x108>
f0104320:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104325:	89 f9                	mov    %edi,%ecx
f0104327:	89 c5                	mov    %eax,%ebp
f0104329:	29 fb                	sub    %edi,%ebx
f010432b:	d3 e6                	shl    %cl,%esi
f010432d:	89 d9                	mov    %ebx,%ecx
f010432f:	d3 ed                	shr    %cl,%ebp
f0104331:	89 f9                	mov    %edi,%ecx
f0104333:	d3 e0                	shl    %cl,%eax
f0104335:	09 ee                	or     %ebp,%esi
f0104337:	89 d9                	mov    %ebx,%ecx
f0104339:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010433d:	89 d5                	mov    %edx,%ebp
f010433f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104343:	d3 ed                	shr    %cl,%ebp
f0104345:	89 f9                	mov    %edi,%ecx
f0104347:	d3 e2                	shl    %cl,%edx
f0104349:	89 d9                	mov    %ebx,%ecx
f010434b:	d3 e8                	shr    %cl,%eax
f010434d:	09 c2                	or     %eax,%edx
f010434f:	89 d0                	mov    %edx,%eax
f0104351:	89 ea                	mov    %ebp,%edx
f0104353:	f7 f6                	div    %esi
f0104355:	89 d5                	mov    %edx,%ebp
f0104357:	89 c3                	mov    %eax,%ebx
f0104359:	f7 64 24 0c          	mull   0xc(%esp)
f010435d:	39 d5                	cmp    %edx,%ebp
f010435f:	72 10                	jb     f0104371 <__udivdi3+0xc1>
f0104361:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104365:	89 f9                	mov    %edi,%ecx
f0104367:	d3 e6                	shl    %cl,%esi
f0104369:	39 c6                	cmp    %eax,%esi
f010436b:	73 07                	jae    f0104374 <__udivdi3+0xc4>
f010436d:	39 d5                	cmp    %edx,%ebp
f010436f:	75 03                	jne    f0104374 <__udivdi3+0xc4>
f0104371:	83 eb 01             	sub    $0x1,%ebx
f0104374:	31 ff                	xor    %edi,%edi
f0104376:	89 d8                	mov    %ebx,%eax
f0104378:	89 fa                	mov    %edi,%edx
f010437a:	83 c4 1c             	add    $0x1c,%esp
f010437d:	5b                   	pop    %ebx
f010437e:	5e                   	pop    %esi
f010437f:	5f                   	pop    %edi
f0104380:	5d                   	pop    %ebp
f0104381:	c3                   	ret    
f0104382:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104388:	31 ff                	xor    %edi,%edi
f010438a:	31 db                	xor    %ebx,%ebx
f010438c:	89 d8                	mov    %ebx,%eax
f010438e:	89 fa                	mov    %edi,%edx
f0104390:	83 c4 1c             	add    $0x1c,%esp
f0104393:	5b                   	pop    %ebx
f0104394:	5e                   	pop    %esi
f0104395:	5f                   	pop    %edi
f0104396:	5d                   	pop    %ebp
f0104397:	c3                   	ret    
f0104398:	90                   	nop
f0104399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01043a0:	89 d8                	mov    %ebx,%eax
f01043a2:	f7 f7                	div    %edi
f01043a4:	31 ff                	xor    %edi,%edi
f01043a6:	89 c3                	mov    %eax,%ebx
f01043a8:	89 d8                	mov    %ebx,%eax
f01043aa:	89 fa                	mov    %edi,%edx
f01043ac:	83 c4 1c             	add    $0x1c,%esp
f01043af:	5b                   	pop    %ebx
f01043b0:	5e                   	pop    %esi
f01043b1:	5f                   	pop    %edi
f01043b2:	5d                   	pop    %ebp
f01043b3:	c3                   	ret    
f01043b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01043b8:	39 ce                	cmp    %ecx,%esi
f01043ba:	72 0c                	jb     f01043c8 <__udivdi3+0x118>
f01043bc:	31 db                	xor    %ebx,%ebx
f01043be:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01043c2:	0f 87 34 ff ff ff    	ja     f01042fc <__udivdi3+0x4c>
f01043c8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01043cd:	e9 2a ff ff ff       	jmp    f01042fc <__udivdi3+0x4c>
f01043d2:	66 90                	xchg   %ax,%ax
f01043d4:	66 90                	xchg   %ax,%ax
f01043d6:	66 90                	xchg   %ax,%ax
f01043d8:	66 90                	xchg   %ax,%ax
f01043da:	66 90                	xchg   %ax,%ax
f01043dc:	66 90                	xchg   %ax,%ax
f01043de:	66 90                	xchg   %ax,%ax

f01043e0 <__umoddi3>:
f01043e0:	55                   	push   %ebp
f01043e1:	57                   	push   %edi
f01043e2:	56                   	push   %esi
f01043e3:	53                   	push   %ebx
f01043e4:	83 ec 1c             	sub    $0x1c,%esp
f01043e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01043eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01043ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01043f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01043f7:	85 d2                	test   %edx,%edx
f01043f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104401:	89 f3                	mov    %esi,%ebx
f0104403:	89 3c 24             	mov    %edi,(%esp)
f0104406:	89 74 24 04          	mov    %esi,0x4(%esp)
f010440a:	75 1c                	jne    f0104428 <__umoddi3+0x48>
f010440c:	39 f7                	cmp    %esi,%edi
f010440e:	76 50                	jbe    f0104460 <__umoddi3+0x80>
f0104410:	89 c8                	mov    %ecx,%eax
f0104412:	89 f2                	mov    %esi,%edx
f0104414:	f7 f7                	div    %edi
f0104416:	89 d0                	mov    %edx,%eax
f0104418:	31 d2                	xor    %edx,%edx
f010441a:	83 c4 1c             	add    $0x1c,%esp
f010441d:	5b                   	pop    %ebx
f010441e:	5e                   	pop    %esi
f010441f:	5f                   	pop    %edi
f0104420:	5d                   	pop    %ebp
f0104421:	c3                   	ret    
f0104422:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104428:	39 f2                	cmp    %esi,%edx
f010442a:	89 d0                	mov    %edx,%eax
f010442c:	77 52                	ja     f0104480 <__umoddi3+0xa0>
f010442e:	0f bd ea             	bsr    %edx,%ebp
f0104431:	83 f5 1f             	xor    $0x1f,%ebp
f0104434:	75 5a                	jne    f0104490 <__umoddi3+0xb0>
f0104436:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010443a:	0f 82 e0 00 00 00    	jb     f0104520 <__umoddi3+0x140>
f0104440:	39 0c 24             	cmp    %ecx,(%esp)
f0104443:	0f 86 d7 00 00 00    	jbe    f0104520 <__umoddi3+0x140>
f0104449:	8b 44 24 08          	mov    0x8(%esp),%eax
f010444d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104451:	83 c4 1c             	add    $0x1c,%esp
f0104454:	5b                   	pop    %ebx
f0104455:	5e                   	pop    %esi
f0104456:	5f                   	pop    %edi
f0104457:	5d                   	pop    %ebp
f0104458:	c3                   	ret    
f0104459:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104460:	85 ff                	test   %edi,%edi
f0104462:	89 fd                	mov    %edi,%ebp
f0104464:	75 0b                	jne    f0104471 <__umoddi3+0x91>
f0104466:	b8 01 00 00 00       	mov    $0x1,%eax
f010446b:	31 d2                	xor    %edx,%edx
f010446d:	f7 f7                	div    %edi
f010446f:	89 c5                	mov    %eax,%ebp
f0104471:	89 f0                	mov    %esi,%eax
f0104473:	31 d2                	xor    %edx,%edx
f0104475:	f7 f5                	div    %ebp
f0104477:	89 c8                	mov    %ecx,%eax
f0104479:	f7 f5                	div    %ebp
f010447b:	89 d0                	mov    %edx,%eax
f010447d:	eb 99                	jmp    f0104418 <__umoddi3+0x38>
f010447f:	90                   	nop
f0104480:	89 c8                	mov    %ecx,%eax
f0104482:	89 f2                	mov    %esi,%edx
f0104484:	83 c4 1c             	add    $0x1c,%esp
f0104487:	5b                   	pop    %ebx
f0104488:	5e                   	pop    %esi
f0104489:	5f                   	pop    %edi
f010448a:	5d                   	pop    %ebp
f010448b:	c3                   	ret    
f010448c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104490:	8b 34 24             	mov    (%esp),%esi
f0104493:	bf 20 00 00 00       	mov    $0x20,%edi
f0104498:	89 e9                	mov    %ebp,%ecx
f010449a:	29 ef                	sub    %ebp,%edi
f010449c:	d3 e0                	shl    %cl,%eax
f010449e:	89 f9                	mov    %edi,%ecx
f01044a0:	89 f2                	mov    %esi,%edx
f01044a2:	d3 ea                	shr    %cl,%edx
f01044a4:	89 e9                	mov    %ebp,%ecx
f01044a6:	09 c2                	or     %eax,%edx
f01044a8:	89 d8                	mov    %ebx,%eax
f01044aa:	89 14 24             	mov    %edx,(%esp)
f01044ad:	89 f2                	mov    %esi,%edx
f01044af:	d3 e2                	shl    %cl,%edx
f01044b1:	89 f9                	mov    %edi,%ecx
f01044b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01044bb:	d3 e8                	shr    %cl,%eax
f01044bd:	89 e9                	mov    %ebp,%ecx
f01044bf:	89 c6                	mov    %eax,%esi
f01044c1:	d3 e3                	shl    %cl,%ebx
f01044c3:	89 f9                	mov    %edi,%ecx
f01044c5:	89 d0                	mov    %edx,%eax
f01044c7:	d3 e8                	shr    %cl,%eax
f01044c9:	89 e9                	mov    %ebp,%ecx
f01044cb:	09 d8                	or     %ebx,%eax
f01044cd:	89 d3                	mov    %edx,%ebx
f01044cf:	89 f2                	mov    %esi,%edx
f01044d1:	f7 34 24             	divl   (%esp)
f01044d4:	89 d6                	mov    %edx,%esi
f01044d6:	d3 e3                	shl    %cl,%ebx
f01044d8:	f7 64 24 04          	mull   0x4(%esp)
f01044dc:	39 d6                	cmp    %edx,%esi
f01044de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044e2:	89 d1                	mov    %edx,%ecx
f01044e4:	89 c3                	mov    %eax,%ebx
f01044e6:	72 08                	jb     f01044f0 <__umoddi3+0x110>
f01044e8:	75 11                	jne    f01044fb <__umoddi3+0x11b>
f01044ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01044ee:	73 0b                	jae    f01044fb <__umoddi3+0x11b>
f01044f0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01044f4:	1b 14 24             	sbb    (%esp),%edx
f01044f7:	89 d1                	mov    %edx,%ecx
f01044f9:	89 c3                	mov    %eax,%ebx
f01044fb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01044ff:	29 da                	sub    %ebx,%edx
f0104501:	19 ce                	sbb    %ecx,%esi
f0104503:	89 f9                	mov    %edi,%ecx
f0104505:	89 f0                	mov    %esi,%eax
f0104507:	d3 e0                	shl    %cl,%eax
f0104509:	89 e9                	mov    %ebp,%ecx
f010450b:	d3 ea                	shr    %cl,%edx
f010450d:	89 e9                	mov    %ebp,%ecx
f010450f:	d3 ee                	shr    %cl,%esi
f0104511:	09 d0                	or     %edx,%eax
f0104513:	89 f2                	mov    %esi,%edx
f0104515:	83 c4 1c             	add    $0x1c,%esp
f0104518:	5b                   	pop    %ebx
f0104519:	5e                   	pop    %esi
f010451a:	5f                   	pop    %edi
f010451b:	5d                   	pop    %ebp
f010451c:	c3                   	ret    
f010451d:	8d 76 00             	lea    0x0(%esi),%esi
f0104520:	29 f9                	sub    %edi,%ecx
f0104522:	19 d6                	sbb    %edx,%esi
f0104524:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104528:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010452c:	e9 18 ff ff ff       	jmp    f0104449 <__umoddi3+0x69>
