
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
f0100058:	e8 bc 40 00 00       	call   f0104119 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 45 10 f0       	push   $0xf01045c0
f010006f:	e8 34 2e 00 00       	call   f0102ea8 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 54 10 00 00       	call   f01010cd <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 7a 28 00 00       	call   f01028f8 <env_init>
	trap_init();
f010007e:	e8 9f 2e 00 00       	call   f0102f22 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 7e 0b 13 f0       	push   $0xf0130b7e
f010008d:	e8 0e 2a 00 00       	call   f0102aa0 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 be 17 f0    	pushl  0xf017be48
f010009b:	e8 2b 2d 00 00       	call   f0102dcb <env_run>

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
f01000c5:	68 db 45 10 f0       	push   $0xf01045db
f01000ca:	e8 d9 2d 00 00       	call   f0102ea8 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 a9 2d 00 00       	call   f0102e82 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 95 4d 10 f0 	movl   $0xf0104d95,(%esp)
f01000e0:	e8 c3 2d 00 00       	call   f0102ea8 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 b0 06 00 00       	call   f01007a2 <monitor>
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
f0100107:	68 f3 45 10 f0       	push   $0xf01045f3
f010010c:	e8 97 2d 00 00       	call   f0102ea8 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 65 2d 00 00       	call   f0102e82 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 95 4d 10 f0 	movl   $0xf0104d95,(%esp)
f0100124:	e8 7f 2d 00 00       	call   f0102ea8 <cprintf>
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
f01001e3:	0f b6 82 60 47 10 f0 	movzbl -0xfefb8a0(%edx),%eax
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
f010021f:	0f b6 82 60 47 10 f0 	movzbl -0xfefb8a0(%edx),%eax
f0100226:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f010022c:	0f b6 8a 60 46 10 f0 	movzbl -0xfefb9a0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 40 46 10 f0 	mov    -0xfefb9c0(,%ecx,4),%ecx
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
f010027d:	68 0d 46 10 f0       	push   $0xf010460d
f0100282:	e8 21 2c 00 00       	call   f0102ea8 <cprintf>
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
f0100431:	e8 30 3d 00 00       	call   f0104166 <memmove>
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
f0100600:	68 19 46 10 f0       	push   $0xf0104619
f0100605:	e8 9e 28 00 00       	call   f0102ea8 <cprintf>
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
f0100646:	68 60 48 10 f0       	push   $0xf0104860
f010064b:	68 7e 48 10 f0       	push   $0xf010487e
f0100650:	68 83 48 10 f0       	push   $0xf0104883
f0100655:	e8 4e 28 00 00       	call   f0102ea8 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 10 49 10 f0       	push   $0xf0104910
f0100662:	68 8c 48 10 f0       	push   $0xf010488c
f0100667:	68 83 48 10 f0       	push   $0xf0104883
f010066c:	e8 37 28 00 00       	call   f0102ea8 <cprintf>
	return 0;
}
f0100671:	b8 00 00 00 00       	mov    $0x0,%eax
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067e:	68 95 48 10 f0       	push   $0xf0104895
f0100683:	e8 20 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 38 49 10 f0       	push   $0xf0104938
f0100695:	e8 0e 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 60 49 10 f0       	push   $0xf0104960
f01006ac:	e8 f7 27 00 00       	call   f0102ea8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 a1 45 10 00       	push   $0x1045a1
f01006b9:	68 a1 45 10 f0       	push   $0xf01045a1
f01006be:	68 84 49 10 f0       	push   $0xf0104984
f01006c3:	e8 e0 27 00 00       	call   f0102ea8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 ee bb 17 00       	push   $0x17bbee
f01006d0:	68 ee bb 17 f0       	push   $0xf017bbee
f01006d5:	68 a8 49 10 f0       	push   $0xf01049a8
f01006da:	e8 c9 27 00 00       	call   f0102ea8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 10 cb 17 00       	push   $0x17cb10
f01006e7:	68 10 cb 17 f0       	push   $0xf017cb10
f01006ec:	68 cc 49 10 f0       	push   $0xf01049cc
f01006f1:	e8 b2 27 00 00       	call   f0102ea8 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 0f cf 17 f0       	mov    $0xf017cf0f,%eax
f01006fb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100700:	83 c4 08             	add    $0x8,%esp
f0100703:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100708:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010070e:	85 c0                	test   %eax,%eax
f0100710:	0f 48 c2             	cmovs  %edx,%eax
f0100713:	c1 f8 0a             	sar    $0xa,%eax
f0100716:	50                   	push   %eax
f0100717:	68 f0 49 10 f0       	push   $0xf01049f0
f010071c:	e8 87 27 00 00       	call   f0102ea8 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	c9                   	leave  
f0100727:	c3                   	ret    

f0100728 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
f010072b:	56                   	push   %esi
f010072c:	53                   	push   %ebx
f010072d:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100730:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f0100732:	68 ae 48 10 f0       	push   $0xf01048ae
f0100737:	e8 6c 27 00 00       	call   f0102ea8 <cprintf>
	while(p)
f010073c:	83 c4 10             	add    $0x10,%esp
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
		debuginfo_eip(*(p+1), &info);
f010073f:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f0100742:	eb 4e                	jmp    f0100792 <mon_backtrace+0x6a>
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
f0100744:	ff 73 18             	pushl  0x18(%ebx)
f0100747:	ff 73 14             	pushl  0x14(%ebx)
f010074a:	ff 73 10             	pushl  0x10(%ebx)
f010074d:	ff 73 0c             	pushl  0xc(%ebx)
f0100750:	ff 73 08             	pushl  0x8(%ebx)
f0100753:	ff 73 04             	pushl  0x4(%ebx)
f0100756:	53                   	push   %ebx
f0100757:	68 1c 4a 10 f0       	push   $0xf0104a1c
f010075c:	e8 47 27 00 00       	call   f0102ea8 <cprintf>
		debuginfo_eip(*(p+1), &info);
f0100761:	83 c4 18             	add    $0x18,%esp
f0100764:	56                   	push   %esi
f0100765:	ff 73 04             	pushl  0x4(%ebx)
f0100768:	e8 55 2f 00 00       	call   f01036c2 <debuginfo_eip>
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
f010076d:	83 c4 08             	add    $0x8,%esp
f0100770:	8b 43 04             	mov    0x4(%ebx),%eax
f0100773:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100776:	50                   	push   %eax
f0100777:	ff 75 e8             	pushl  -0x18(%ebp)
f010077a:	ff 75 ec             	pushl  -0x14(%ebp)
f010077d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100780:	ff 75 e0             	pushl  -0x20(%ebp)
f0100783:	68 c0 48 10 f0       	push   $0xf01048c0
f0100788:	e8 1b 27 00 00       	call   f0102ea8 <cprintf>
		p=(uint32_t*)*p;
f010078d:	8b 1b                	mov    (%ebx),%ebx
f010078f:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f0100792:	85 db                	test   %ebx,%ebx
f0100794:	75 ae                	jne    f0100744 <mon_backtrace+0x1c>
		debuginfo_eip(*(p+1), &info);
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
		p=(uint32_t*)*p;
	}
	return 0;
}
f0100796:	b8 00 00 00 00       	mov    $0x0,%eax
f010079b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010079e:	5b                   	pop    %ebx
f010079f:	5e                   	pop    %esi
f01007a0:	5d                   	pop    %ebp
f01007a1:	c3                   	ret    

f01007a2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	57                   	push   %edi
f01007a6:	56                   	push   %esi
f01007a7:	53                   	push   %ebx
f01007a8:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ab:	68 50 4a 10 f0       	push   $0xf0104a50
f01007b0:	e8 f3 26 00 00       	call   f0102ea8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b5:	c7 04 24 74 4a 10 f0 	movl   $0xf0104a74,(%esp)
f01007bc:	e8 e7 26 00 00       	call   f0102ea8 <cprintf>

	if (tf != NULL)
f01007c1:	83 c4 10             	add    $0x10,%esp
f01007c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007c8:	74 0e                	je     f01007d8 <monitor+0x36>
		print_trapframe(tf);
f01007ca:	83 ec 0c             	sub    $0xc,%esp
f01007cd:	ff 75 08             	pushl  0x8(%ebp)
f01007d0:	e8 c0 2a 00 00       	call   f0103295 <print_trapframe>
f01007d5:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007d8:	83 ec 0c             	sub    $0xc,%esp
f01007db:	68 d2 48 10 f0       	push   $0xf01048d2
f01007e0:	e8 dd 36 00 00       	call   f0103ec2 <readline>
f01007e5:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e7:	83 c4 10             	add    $0x10,%esp
f01007ea:	85 c0                	test   %eax,%eax
f01007ec:	74 ea                	je     f01007d8 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ee:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f5:	be 00 00 00 00       	mov    $0x0,%esi
f01007fa:	eb 0a                	jmp    f0100806 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007fc:	c6 03 00             	movb   $0x0,(%ebx)
f01007ff:	89 f7                	mov    %esi,%edi
f0100801:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100804:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100806:	0f b6 03             	movzbl (%ebx),%eax
f0100809:	84 c0                	test   %al,%al
f010080b:	74 63                	je     f0100870 <monitor+0xce>
f010080d:	83 ec 08             	sub    $0x8,%esp
f0100810:	0f be c0             	movsbl %al,%eax
f0100813:	50                   	push   %eax
f0100814:	68 d6 48 10 f0       	push   $0xf01048d6
f0100819:	e8 be 38 00 00       	call   f01040dc <strchr>
f010081e:	83 c4 10             	add    $0x10,%esp
f0100821:	85 c0                	test   %eax,%eax
f0100823:	75 d7                	jne    f01007fc <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100825:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100828:	74 46                	je     f0100870 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082a:	83 fe 0f             	cmp    $0xf,%esi
f010082d:	75 14                	jne    f0100843 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010082f:	83 ec 08             	sub    $0x8,%esp
f0100832:	6a 10                	push   $0x10
f0100834:	68 db 48 10 f0       	push   $0xf01048db
f0100839:	e8 6a 26 00 00       	call   f0102ea8 <cprintf>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	eb 95                	jmp    f01007d8 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100843:	8d 7e 01             	lea    0x1(%esi),%edi
f0100846:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084a:	eb 03                	jmp    f010084f <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010084c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084f:	0f b6 03             	movzbl (%ebx),%eax
f0100852:	84 c0                	test   %al,%al
f0100854:	74 ae                	je     f0100804 <monitor+0x62>
f0100856:	83 ec 08             	sub    $0x8,%esp
f0100859:	0f be c0             	movsbl %al,%eax
f010085c:	50                   	push   %eax
f010085d:	68 d6 48 10 f0       	push   $0xf01048d6
f0100862:	e8 75 38 00 00       	call   f01040dc <strchr>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 de                	je     f010084c <monitor+0xaa>
f010086e:	eb 94                	jmp    f0100804 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100870:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100877:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100878:	85 f6                	test   %esi,%esi
f010087a:	0f 84 58 ff ff ff    	je     f01007d8 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100880:	83 ec 08             	sub    $0x8,%esp
f0100883:	68 7e 48 10 f0       	push   $0xf010487e
f0100888:	ff 75 a8             	pushl  -0x58(%ebp)
f010088b:	e8 ee 37 00 00       	call   f010407e <strcmp>
f0100890:	83 c4 10             	add    $0x10,%esp
f0100893:	85 c0                	test   %eax,%eax
f0100895:	74 1e                	je     f01008b5 <monitor+0x113>
f0100897:	83 ec 08             	sub    $0x8,%esp
f010089a:	68 8c 48 10 f0       	push   $0xf010488c
f010089f:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a2:	e8 d7 37 00 00       	call   f010407e <strcmp>
f01008a7:	83 c4 10             	add    $0x10,%esp
f01008aa:	85 c0                	test   %eax,%eax
f01008ac:	75 2f                	jne    f01008dd <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01008b3:	eb 05                	jmp    f01008ba <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b5:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ba:	83 ec 04             	sub    $0x4,%esp
f01008bd:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008c0:	01 d0                	add    %edx,%eax
f01008c2:	ff 75 08             	pushl  0x8(%ebp)
f01008c5:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008c8:	51                   	push   %ecx
f01008c9:	56                   	push   %esi
f01008ca:	ff 14 85 a4 4a 10 f0 	call   *-0xfefb55c(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d1:	83 c4 10             	add    $0x10,%esp
f01008d4:	85 c0                	test   %eax,%eax
f01008d6:	78 1d                	js     f01008f5 <monitor+0x153>
f01008d8:	e9 fb fe ff ff       	jmp    f01007d8 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008dd:	83 ec 08             	sub    $0x8,%esp
f01008e0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e3:	68 f8 48 10 f0       	push   $0xf01048f8
f01008e8:	e8 bb 25 00 00       	call   f0102ea8 <cprintf>
f01008ed:	83 c4 10             	add    $0x10,%esp
f01008f0:	e9 e3 fe ff ff       	jmp    f01007d8 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f8:	5b                   	pop    %ebx
f01008f9:	5e                   	pop    %esi
f01008fa:	5f                   	pop    %edi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008fd:	55                   	push   %ebp
f01008fe:	89 e5                	mov    %esp,%ebp
f0100900:	56                   	push   %esi
f0100901:	53                   	push   %ebx
f0100902:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	50                   	push   %eax
f0100908:	e8 34 25 00 00       	call   f0102e41 <mc146818_read>
f010090d:	89 c6                	mov    %eax,%esi
f010090f:	83 c3 01             	add    $0x1,%ebx
f0100912:	89 1c 24             	mov    %ebx,(%esp)
f0100915:	e8 27 25 00 00       	call   f0102e41 <mc146818_read>
f010091a:	c1 e0 08             	shl    $0x8,%eax
f010091d:	09 f0                	or     %esi,%eax
}
f010091f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100922:	5b                   	pop    %ebx
f0100923:	5e                   	pop    %esi
f0100924:	5d                   	pop    %ebp
f0100925:	c3                   	ret    

f0100926 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100926:	55                   	push   %ebp
f0100927:	89 e5                	mov    %esp,%ebp
f0100929:	53                   	push   %ebx
f010092a:	83 ec 04             	sub    $0x4,%esp
f010092d:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010092f:	83 3d 38 be 17 f0 00 	cmpl   $0x0,0xf017be38
f0100936:	75 0f                	jne    f0100947 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100938:	b8 0f db 17 f0       	mov    $0xf017db0f,%eax
f010093d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100942:	a3 38 be 17 f0       	mov    %eax,0xf017be38
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	

	cprintf("boot_allocated memory at %x\n", nextfree);
f0100947:	83 ec 08             	sub    $0x8,%esp
f010094a:	ff 35 38 be 17 f0    	pushl  0xf017be38
f0100950:	68 b4 4a 10 f0       	push   $0xf0104ab4
f0100955:	e8 4e 25 00 00       	call   f0102ea8 <cprintf>
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f010095a:	89 d8                	mov    %ebx,%eax
f010095c:	03 05 38 be 17 f0    	add    0xf017be38,%eax
f0100962:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100967:	83 c4 08             	add    $0x8,%esp
f010096a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010096f:	50                   	push   %eax
f0100970:	68 d1 4a 10 f0       	push   $0xf0104ad1
f0100975:	e8 2e 25 00 00       	call   f0102ea8 <cprintf>
	if (n>0) {
f010097a:	83 c4 10             	add    $0x10,%esp
f010097d:	85 db                	test   %ebx,%ebx
f010097f:	74 1a                	je     f010099b <boot_alloc+0x75>
		char *temp = nextfree;
f0100981:	a1 38 be 17 f0       	mov    0xf017be38,%eax
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f0100986:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f010098d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100993:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
		return temp;
f0100999:	eb 2c                	jmp    f01009c7 <boot_alloc+0xa1>
	} 
	if ((uint32_t)nextfree > KERNBASE + npages*PGSIZE){
f010099b:	a1 38 be 17 f0       	mov    0xf017be38,%eax
f01009a0:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f01009a6:	8d 91 00 00 0f 00    	lea    0xf0000(%ecx),%edx
f01009ac:	c1 e2 0c             	shl    $0xc,%edx
f01009af:	39 d0                	cmp    %edx,%eax
f01009b1:	76 14                	jbe    f01009c7 <boot_alloc+0xa1>
	panic ("boot_alloc failed - Out of memory");
f01009b3:	83 ec 04             	sub    $0x4,%esp
f01009b6:	68 c8 4d 10 f0       	push   $0xf0104dc8
f01009bb:	6a 74                	push   $0x74
f01009bd:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01009c2:	e8 d9 f6 ff ff       	call   f01000a0 <_panic>
	}
	else
	return nextfree;
	}
f01009c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009ca:	c9                   	leave  
f01009cb:	c3                   	ret    

f01009cc <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009cc:	89 d1                	mov    %edx,%ecx
f01009ce:	c1 e9 16             	shr    $0x16,%ecx
f01009d1:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009d4:	a8 01                	test   $0x1,%al
f01009d6:	74 52                	je     f0100a2a <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009d8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009dd:	89 c1                	mov    %eax,%ecx
f01009df:	c1 e9 0c             	shr    $0xc,%ecx
f01009e2:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f01009e8:	72 1b                	jb     f0100a05 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009ea:	55                   	push   %ebp
f01009eb:	89 e5                	mov    %esp,%ebp
f01009ed:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f0:	50                   	push   %eax
f01009f1:	68 ec 4d 10 f0       	push   $0xf0104dec
f01009f6:	68 4b 03 00 00       	push   $0x34b
f01009fb:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100a00:	e8 9b f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a05:	c1 ea 0c             	shr    $0xc,%edx
f0100a08:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a0e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a15:	89 c2                	mov    %eax,%edx
f0100a17:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a1a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a1f:	85 d2                	test   %edx,%edx
f0100a21:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a26:	0f 44 c2             	cmove  %edx,%eax
f0100a29:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a2f:	c3                   	ret    

f0100a30 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a30:	55                   	push   %ebp
f0100a31:	89 e5                	mov    %esp,%ebp
f0100a33:	57                   	push   %edi
f0100a34:	56                   	push   %esi
f0100a35:	53                   	push   %ebx
f0100a36:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a39:	84 c0                	test   %al,%al
f0100a3b:	0f 85 81 02 00 00    	jne    f0100cc2 <check_page_free_list+0x292>
f0100a41:	e9 8e 02 00 00       	jmp    f0100cd4 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a46:	83 ec 04             	sub    $0x4,%esp
f0100a49:	68 10 4e 10 f0       	push   $0xf0104e10
f0100a4e:	68 87 02 00 00       	push   $0x287
f0100a53:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100a58:	e8 43 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a5d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a60:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a63:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a66:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a69:	89 c2                	mov    %eax,%edx
f0100a6b:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0100a71:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a77:	0f 95 c2             	setne  %dl
f0100a7a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a7d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a81:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a83:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a87:	8b 00                	mov    (%eax),%eax
f0100a89:	85 c0                	test   %eax,%eax
f0100a8b:	75 dc                	jne    f0100a69 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a90:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a96:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a99:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a9c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a9e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100aa1:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aa6:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aab:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100ab1:	eb 53                	jmp    f0100b06 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ab3:	89 d8                	mov    %ebx,%eax
f0100ab5:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100abb:	c1 f8 03             	sar    $0x3,%eax
f0100abe:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ac1:	89 c2                	mov    %eax,%edx
f0100ac3:	c1 ea 16             	shr    $0x16,%edx
f0100ac6:	39 f2                	cmp    %esi,%edx
f0100ac8:	73 3a                	jae    f0100b04 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aca:	89 c2                	mov    %eax,%edx
f0100acc:	c1 ea 0c             	shr    $0xc,%edx
f0100acf:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100ad5:	72 12                	jb     f0100ae9 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ad7:	50                   	push   %eax
f0100ad8:	68 ec 4d 10 f0       	push   $0xf0104dec
f0100add:	6a 56                	push   $0x56
f0100adf:	68 f0 4a 10 f0       	push   $0xf0104af0
f0100ae4:	e8 b7 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ae9:	83 ec 04             	sub    $0x4,%esp
f0100aec:	68 80 00 00 00       	push   $0x80
f0100af1:	68 97 00 00 00       	push   $0x97
f0100af6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100afb:	50                   	push   %eax
f0100afc:	e8 18 36 00 00       	call   f0104119 <memset>
f0100b01:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b04:	8b 1b                	mov    (%ebx),%ebx
f0100b06:	85 db                	test   %ebx,%ebx
f0100b08:	75 a9                	jne    f0100ab3 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b0f:	e8 12 fe ff ff       	call   f0100926 <boot_alloc>
f0100b14:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b17:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b1d:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
		assert(pp < pages + npages);
f0100b23:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0100b28:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b2b:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b2e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b31:	be 00 00 00 00       	mov    $0x0,%esi
f0100b36:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b39:	e9 30 01 00 00       	jmp    f0100c6e <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b3e:	39 ca                	cmp    %ecx,%edx
f0100b40:	73 19                	jae    f0100b5b <check_page_free_list+0x12b>
f0100b42:	68 fe 4a 10 f0       	push   $0xf0104afe
f0100b47:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100b4c:	68 a1 02 00 00       	push   $0x2a1
f0100b51:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100b56:	e8 45 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b5b:	39 fa                	cmp    %edi,%edx
f0100b5d:	72 19                	jb     f0100b78 <check_page_free_list+0x148>
f0100b5f:	68 1f 4b 10 f0       	push   $0xf0104b1f
f0100b64:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100b69:	68 a2 02 00 00       	push   $0x2a2
f0100b6e:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100b73:	e8 28 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b78:	89 d0                	mov    %edx,%eax
f0100b7a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b7d:	a8 07                	test   $0x7,%al
f0100b7f:	74 19                	je     f0100b9a <check_page_free_list+0x16a>
f0100b81:	68 34 4e 10 f0       	push   $0xf0104e34
f0100b86:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100b8b:	68 a3 02 00 00       	push   $0x2a3
f0100b90:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100b95:	e8 06 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b9a:	c1 f8 03             	sar    $0x3,%eax
f0100b9d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba0:	85 c0                	test   %eax,%eax
f0100ba2:	75 19                	jne    f0100bbd <check_page_free_list+0x18d>
f0100ba4:	68 33 4b 10 f0       	push   $0xf0104b33
f0100ba9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100bae:	68 a6 02 00 00       	push   $0x2a6
f0100bb3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100bb8:	e8 e3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bbd:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bc2:	75 19                	jne    f0100bdd <check_page_free_list+0x1ad>
f0100bc4:	68 44 4b 10 f0       	push   $0xf0104b44
f0100bc9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100bce:	68 a7 02 00 00       	push   $0x2a7
f0100bd3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100bd8:	e8 c3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bdd:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100be2:	75 19                	jne    f0100bfd <check_page_free_list+0x1cd>
f0100be4:	68 68 4e 10 f0       	push   $0xf0104e68
f0100be9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100bee:	68 a8 02 00 00       	push   $0x2a8
f0100bf3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100bf8:	e8 a3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bfd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c02:	75 19                	jne    f0100c1d <check_page_free_list+0x1ed>
f0100c04:	68 5d 4b 10 f0       	push   $0xf0104b5d
f0100c09:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100c0e:	68 a9 02 00 00       	push   $0x2a9
f0100c13:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100c18:	e8 83 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c1d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c22:	76 3f                	jbe    f0100c63 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c24:	89 c3                	mov    %eax,%ebx
f0100c26:	c1 eb 0c             	shr    $0xc,%ebx
f0100c29:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c2c:	77 12                	ja     f0100c40 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c2e:	50                   	push   %eax
f0100c2f:	68 ec 4d 10 f0       	push   $0xf0104dec
f0100c34:	6a 56                	push   $0x56
f0100c36:	68 f0 4a 10 f0       	push   $0xf0104af0
f0100c3b:	e8 60 f4 ff ff       	call   f01000a0 <_panic>
f0100c40:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c45:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c48:	76 1e                	jbe    f0100c68 <check_page_free_list+0x238>
f0100c4a:	68 8c 4e 10 f0       	push   $0xf0104e8c
f0100c4f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100c54:	68 aa 02 00 00       	push   $0x2aa
f0100c59:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100c5e:	e8 3d f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c63:	83 c6 01             	add    $0x1,%esi
f0100c66:	eb 04                	jmp    f0100c6c <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c68:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c6c:	8b 12                	mov    (%edx),%edx
f0100c6e:	85 d2                	test   %edx,%edx
f0100c70:	0f 85 c8 fe ff ff    	jne    f0100b3e <check_page_free_list+0x10e>
f0100c76:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c79:	85 f6                	test   %esi,%esi
f0100c7b:	7f 19                	jg     f0100c96 <check_page_free_list+0x266>
f0100c7d:	68 77 4b 10 f0       	push   $0xf0104b77
f0100c82:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100c87:	68 b2 02 00 00       	push   $0x2b2
f0100c8c:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100c91:	e8 0a f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c96:	85 db                	test   %ebx,%ebx
f0100c98:	7f 19                	jg     f0100cb3 <check_page_free_list+0x283>
f0100c9a:	68 89 4b 10 f0       	push   $0xf0104b89
f0100c9f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100ca4:	68 b3 02 00 00       	push   $0x2b3
f0100ca9:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100cae:	e8 ed f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cb3:	83 ec 0c             	sub    $0xc,%esp
f0100cb6:	68 d4 4e 10 f0       	push   $0xf0104ed4
f0100cbb:	e8 e8 21 00 00       	call   f0102ea8 <cprintf>
}
f0100cc0:	eb 29                	jmp    f0100ceb <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cc2:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0100cc7:	85 c0                	test   %eax,%eax
f0100cc9:	0f 85 8e fd ff ff    	jne    f0100a5d <check_page_free_list+0x2d>
f0100ccf:	e9 72 fd ff ff       	jmp    f0100a46 <check_page_free_list+0x16>
f0100cd4:	83 3d 3c be 17 f0 00 	cmpl   $0x0,0xf017be3c
f0100cdb:	0f 84 65 fd ff ff    	je     f0100a46 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ce1:	be 00 04 00 00       	mov    $0x400,%esi
f0100ce6:	e9 c0 fd ff ff       	jmp    f0100aab <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100ceb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cee:	5b                   	pop    %ebx
f0100cef:	5e                   	pop    %esi
f0100cf0:	5f                   	pop    %edi
f0100cf1:	5d                   	pop    %ebp
f0100cf2:	c3                   	ret    

f0100cf3 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cf3:	55                   	push   %ebp
f0100cf4:	89 e5                	mov    %esp,%ebp
f0100cf6:	57                   	push   %edi
f0100cf7:	56                   	push   %esi
f0100cf8:	53                   	push   %ebx
f0100cf9:	83 ec 1c             	sub    $0x1c,%esp
	size_t i;
	// 0xA0
	size_t io_hole_begin = IOPHYSMEM / PGSIZE;
	// 0x100
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
f0100cfc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d01:	e8 20 fc ff ff       	call   f0100926 <boot_alloc>
f0100d06:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d0b:	c1 e8 0c             	shr    $0xc,%eax
f0100d0e:	05 00 01 00 00       	add    $0x100,%eax
f0100d13:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	page_free_list = NULL;
f0100d16:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0100d1d:	00 00 00 
		// 1)
		if (i == 0) {
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		// 2) i < 0xA0
		} else if (i < npages_basemem) {
f0100d20:	8b 35 40 be 17 f0    	mov    0xf017be40,%esi
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
	page_free_list = NULL;

	// i < 0x40FF
	for (i = 0; i < npages; i++) {
f0100d26:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d2b:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d30:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d35:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d3a:	e9 a4 00 00 00       	jmp    f0100de3 <page_init+0xf0>
		// 1)
		if (i == 0) {
f0100d3f:	85 c0                	test   %eax,%eax
f0100d41:	75 17                	jne    f0100d5a <page_init+0x67>
			pages[i].pp_ref = 1;
f0100d43:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
f0100d49:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d4f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d55:	e9 83 00 00 00       	jmp    f0100ddd <page_init+0xea>
		// 2) i < 0xA0
		} else if (i < npages_basemem) {
f0100d5a:	39 f0                	cmp    %esi,%eax
f0100d5c:	73 1f                	jae    f0100d7d <page_init+0x8a>
			pages[i].pp_ref = 0;
f0100d5e:	89 d1                	mov    %edx,%ecx
f0100d60:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100d66:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100d6c:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100d6e:	89 d3                	mov    %edx,%ebx
f0100d70:	03 1d 0c cb 17 f0    	add    0xf017cb0c,%ebx
f0100d76:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d7b:	eb 60                	jmp    f0100ddd <page_init+0xea>
		// 3) 0xA0 <= i < 0x100
		} else if (io_hole_begin <= i && i < io_hole_end) {
f0100d7d:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100d83:	83 f9 5f             	cmp    $0x5f,%ecx
f0100d86:	77 16                	ja     f0100d9e <page_init+0xab>
			pages[i].pp_ref = 1;
f0100d88:	89 d1                	mov    %edx,%ecx
f0100d8a:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100d90:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d96:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d9c:	eb 3f                	jmp    f0100ddd <page_init+0xea>
		// 4) 0x100 <= i < 0x400 (0xF0400000)
		} else if (io_hole_end <= i && i < kernel_end) {
f0100d9e:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100da3:	76 1b                	jbe    f0100dc0 <page_init+0xcd>
f0100da5:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100da8:	73 16                	jae    f0100dc0 <page_init+0xcd>
			pages[i].pp_ref = 1;
f0100daa:	89 d1                	mov    %edx,%ecx
f0100dac:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100db2:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100db8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100dbe:	eb 1d                	jmp    f0100ddd <page_init+0xea>
		// 4) 0x400 <= i
		} else {
			pages[i].pp_ref = 0;
f0100dc0:	89 d1                	mov    %edx,%ecx
f0100dc2:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100dc8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100dce:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100dd0:	89 d3                	mov    %edx,%ebx
f0100dd2:	03 1d 0c cb 17 f0    	add    0xf017cb0c,%ebx
f0100dd8:	bf 01 00 00 00       	mov    $0x1,%edi
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
	page_free_list = NULL;

	// i < 0x40FF
	for (i = 0; i < npages; i++) {
f0100ddd:	83 c0 01             	add    $0x1,%eax
f0100de0:	83 c2 08             	add    $0x8,%edx
f0100de3:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0100de9:	0f 82 50 ff ff ff    	jb     f0100d3f <page_init+0x4c>
f0100def:	89 f8                	mov    %edi,%eax
f0100df1:	84 c0                	test   %al,%al
f0100df3:	74 06                	je     f0100dfb <page_init+0x108>
f0100df5:	89 1d 3c be 17 f0    	mov    %ebx,0xf017be3c
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100dfb:	83 c4 1c             	add    $0x1c,%esp
f0100dfe:	5b                   	pop    %ebx
f0100dff:	5e                   	pop    %esi
f0100e00:	5f                   	pop    %edi
f0100e01:	5d                   	pop    %ebp
f0100e02:	c3                   	ret    

f0100e03 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e03:	55                   	push   %ebp
f0100e04:	89 e5                	mov    %esp,%ebp
f0100e06:	53                   	push   %ebx
f0100e07:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *page;
	
	if (page_free_list!=NULL){
f0100e0a:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100e10:	85 db                	test   %ebx,%ebx
f0100e12:	74 58                	je     f0100e6c <page_alloc+0x69>
	page = page_free_list;
	page_free_list = page->pp_link;
f0100e14:	8b 03                	mov    (%ebx),%eax
f0100e16:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
	page->pp_link = NULL;
f0100e1b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	
	if (alloc_flags & ALLOC_ZERO) {
f0100e21:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e25:	74 45                	je     f0100e6c <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e27:	89 d8                	mov    %ebx,%eax
f0100e29:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100e2f:	c1 f8 03             	sar    $0x3,%eax
f0100e32:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e35:	89 c2                	mov    %eax,%edx
f0100e37:	c1 ea 0c             	shr    $0xc,%edx
f0100e3a:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100e40:	72 12                	jb     f0100e54 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e42:	50                   	push   %eax
f0100e43:	68 ec 4d 10 f0       	push   $0xf0104dec
f0100e48:	6a 56                	push   $0x56
f0100e4a:	68 f0 4a 10 f0       	push   $0xf0104af0
f0100e4f:	e8 4c f2 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(page), '\0', PGSIZE);
f0100e54:	83 ec 04             	sub    $0x4,%esp
f0100e57:	68 00 10 00 00       	push   $0x1000
f0100e5c:	6a 00                	push   $0x0
f0100e5e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e63:	50                   	push   %eax
f0100e64:	e8 b0 32 00 00       	call   f0104119 <memset>
f0100e69:	83 c4 10             	add    $0x10,%esp
	}
	return page;
	}
	return NULL;
	
}
f0100e6c:	89 d8                	mov    %ebx,%eax
f0100e6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e71:	c9                   	leave  
f0100e72:	c3                   	ret    

f0100e73 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e73:	55                   	push   %ebp
f0100e74:	89 e5                	mov    %esp,%ebp
f0100e76:	83 ec 08             	sub    $0x8,%esp
f0100e79:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref!= 0 || pp->pp_link != NULL) {
f0100e7c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e81:	75 05                	jne    f0100e88 <page_free+0x15>
f0100e83:	83 38 00             	cmpl   $0x0,(%eax)
f0100e86:	74 17                	je     f0100e9f <page_free+0x2c>
		panic("Page Free Failed: Tried to free page having either reference count>0 or linked");
f0100e88:	83 ec 04             	sub    $0x4,%esp
f0100e8b:	68 f8 4e 10 f0       	push   $0xf0104ef8
f0100e90:	68 75 01 00 00       	push   $0x175
f0100e95:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100e9a:	e8 01 f2 ff ff       	call   f01000a0 <_panic>
		
	}

	pp->pp_link = page_free_list;
f0100e9f:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
f0100ea5:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ea7:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
}
f0100eac:	c9                   	leave  
f0100ead:	c3                   	ret    

f0100eae <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100eae:	55                   	push   %ebp
f0100eaf:	89 e5                	mov    %esp,%ebp
f0100eb1:	83 ec 08             	sub    $0x8,%esp
f0100eb4:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100eb7:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100ebb:	83 e8 01             	sub    $0x1,%eax
f0100ebe:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100ec2:	66 85 c0             	test   %ax,%ax
f0100ec5:	75 0c                	jne    f0100ed3 <page_decref+0x25>
		page_free(pp);
f0100ec7:	83 ec 0c             	sub    $0xc,%esp
f0100eca:	52                   	push   %edx
f0100ecb:	e8 a3 ff ff ff       	call   f0100e73 <page_free>
f0100ed0:	83 c4 10             	add    $0x10,%esp
}
f0100ed3:	c9                   	leave  
f0100ed4:	c3                   	ret    

f0100ed5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ed5:	55                   	push   %ebp
f0100ed6:	89 e5                	mov    %esp,%ebp
f0100ed8:	56                   	push   %esi
f0100ed9:	53                   	push   %ebx
f0100eda:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte;
	pde_t *pde= pgdir+PDX(va); 	           //pde = &pgdir[PDX(va)]
f0100edd:	89 f3                	mov    %esi,%ebx
f0100edf:	c1 eb 16             	shr    $0x16,%ebx
f0100ee2:	c1 e3 02             	shl    $0x2,%ebx
f0100ee5:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pde & PTE_P)){ 			   //If directory entry not present and create==true
f0100ee8:	f6 03 01             	testb  $0x1,(%ebx)
f0100eeb:	75 2d                	jne    f0100f1a <pgdir_walk+0x45>
		if (create){  
f0100eed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ef1:	74 62                	je     f0100f55 <pgdir_walk+0x80>
			pp=page_alloc(ALLOC_ZERO); //Allocate a physical page with ALLOC_ZERO
f0100ef3:	83 ec 0c             	sub    $0xc,%esp
f0100ef6:	6a 01                	push   $0x1
f0100ef8:	e8 06 ff ff ff       	call   f0100e03 <page_alloc>
			if(pp){                    // If physical page allocated
f0100efd:	83 c4 10             	add    $0x10,%esp
f0100f00:	85 c0                	test   %eax,%eax
f0100f02:	74 58                	je     f0100f5c <pgdir_walk+0x87>
				 
				pp->pp_ref++;      
f0100f04:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
				*pde=page2pa(pp)+PTE_P+PTE_W+PTE_U; //convert page address to physical address
f0100f09:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100f0f:	c1 f8 03             	sar    $0x3,%eax
f0100f12:	c1 e0 0c             	shl    $0xc,%eax
f0100f15:	83 c0 07             	add    $0x7,%eax
f0100f18:	89 03                	mov    %eax,(%ebx)
	else
		return NULL;                               //if create==false
	}

	
	pte=KADDR(PTE_ADDR(*pde));                         //if directory entry present calculate kernel virtual address
f0100f1a:	8b 03                	mov    (%ebx),%eax
f0100f1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f21:	89 c2                	mov    %eax,%edx
f0100f23:	c1 ea 0c             	shr    $0xc,%edx
f0100f26:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100f2c:	72 15                	jb     f0100f43 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f2e:	50                   	push   %eax
f0100f2f:	68 ec 4d 10 f0       	push   $0xf0104dec
f0100f34:	68 b7 01 00 00       	push   $0x1b7
f0100f39:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100f3e:	e8 5d f1 ff ff       	call   f01000a0 <_panic>
	
	return (pte + PTX(va));
f0100f43:	c1 ee 0a             	shr    $0xa,%esi
f0100f46:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f4c:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f53:	eb 0c                	jmp    f0100f61 <pgdir_walk+0x8c>
				return NULL;				//if not able to allocate page
			    }	
				
					                      
	else
		return NULL;                               //if create==false
f0100f55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5a:	eb 05                	jmp    f0100f61 <pgdir_walk+0x8c>
				 
				pp->pp_ref++;      
				*pde=page2pa(pp)+PTE_P+PTE_W+PTE_U; //convert page address to physical address
			      }
			else
				return NULL;				//if not able to allocate page
f0100f5c:	b8 00 00 00 00       	mov    $0x0,%eax
	
	pte=KADDR(PTE_ADDR(*pde));                         //if directory entry present calculate kernel virtual address
	
	return (pte + PTX(va));
	
}
f0100f61:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f64:	5b                   	pop    %ebx
f0100f65:	5e                   	pop    %esi
f0100f66:	5d                   	pop    %ebp
f0100f67:	c3                   	ret    

f0100f68 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f68:	55                   	push   %ebp
f0100f69:	89 e5                	mov    %esp,%ebp
f0100f6b:	57                   	push   %edi
f0100f6c:	56                   	push   %esi
f0100f6d:	53                   	push   %ebx
f0100f6e:	83 ec 1c             	sub    $0x1c,%esp
f0100f71:	89 c7                	mov    %eax,%edi
f0100f73:	89 d6                	mov    %edx,%esi
f0100f75:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100f78:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte_t *pte = pgdir_walk(pgdir, (const void *) (va + i), 1);
		*pte = (pa + i) | perm | PTE_P;  //PTE_ADDR(pa)=physaddr(pa)&~0xFFF
f0100f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f80:	83 c8 01             	or     $0x1,%eax
f0100f83:	89 45 e0             	mov    %eax,-0x20(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100f86:	eb 3d                	jmp    f0100fc5 <boot_map_region+0x5d>
		pte_t *pte = pgdir_walk(pgdir, (const void *) (va + i), 1);
f0100f88:	83 ec 04             	sub    $0x4,%esp
f0100f8b:	6a 01                	push   $0x1
f0100f8d:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0100f90:	50                   	push   %eax
f0100f91:	57                   	push   %edi
f0100f92:	e8 3e ff ff ff       	call   f0100ed5 <pgdir_walk>
		*pte = (pa + i) | perm | PTE_P;  //PTE_ADDR(pa)=physaddr(pa)&~0xFFF
f0100f97:	89 da                	mov    %ebx,%edx
f0100f99:	03 55 08             	add    0x8(%ebp),%edx
f0100f9c:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f9f:	89 10                	mov    %edx,(%eax)
		if (!pte) {
f0100fa1:	83 c4 10             	add    $0x10,%esp
f0100fa4:	85 c0                	test   %eax,%eax
f0100fa6:	75 17                	jne    f0100fbf <boot_map_region+0x57>
			panic("boot_map_region failed: out of memory");
f0100fa8:	83 ec 04             	sub    $0x4,%esp
f0100fab:	68 48 4f 10 f0       	push   $0xf0104f48
f0100fb0:	68 d0 01 00 00       	push   $0x1d0
f0100fb5:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0100fba:	e8 e1 f0 ff ff       	call   f01000a0 <_panic>
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100fbf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100fc5:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100fc8:	77 be                	ja     f0100f88 <boot_map_region+0x20>
			panic("boot_map_region failed: out of memory");
			return;
		} 
	}
	
}
f0100fca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fcd:	5b                   	pop    %ebx
f0100fce:	5e                   	pop    %esi
f0100fcf:	5f                   	pop    %edi
f0100fd0:	5d                   	pop    %ebp
f0100fd1:	c3                   	ret    

f0100fd2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fd2:	55                   	push   %ebp
f0100fd3:	89 e5                	mov    %esp,%ebp
f0100fd5:	53                   	push   %ebx
f0100fd6:	83 ec 08             	sub    $0x8,%esp
f0100fd9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//Initially not created
f0100fdc:	6a 00                	push   $0x0
f0100fde:	ff 75 0c             	pushl  0xc(%ebp)
f0100fe1:	ff 75 08             	pushl  0x8(%ebp)
f0100fe4:	e8 ec fe ff ff       	call   f0100ed5 <pgdir_walk>
	if (!(pte)) 
f0100fe9:	83 c4 10             	add    $0x10,%esp
f0100fec:	85 c0                	test   %eax,%eax
f0100fee:	74 32                	je     f0101022 <page_lookup+0x50>
	return NULL;				//page not found
	if (pte_store!=NULL)
f0100ff0:	85 db                	test   %ebx,%ebx
f0100ff2:	74 02                	je     f0100ff6 <page_lookup+0x24>
		*pte_store = pte;	        //if pte_store!=0 then address of pte of page is stored
f0100ff4:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ff6:	8b 00                	mov    (%eax),%eax
f0100ff8:	c1 e8 0c             	shr    $0xc,%eax
f0100ffb:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0101001:	72 14                	jb     f0101017 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101003:	83 ec 04             	sub    $0x4,%esp
f0101006:	68 70 4f 10 f0       	push   $0xf0104f70
f010100b:	6a 4f                	push   $0x4f
f010100d:	68 f0 4a 10 f0       	push   $0xf0104af0
f0101012:	e8 89 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0101017:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f010101d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));		//page mapped at virtual address va is returned
f0101020:	eb 05                	jmp    f0101027 <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//Initially not created
	if (!(pte)) 
	return NULL;				//page not found
f0101022:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store!=NULL)
		*pte_store = pte;	        //if pte_store!=0 then address of pte of page is stored
	return pa2page(PTE_ADDR(*pte));		//page mapped at virtual address va is returned
}
f0101027:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010102a:	c9                   	leave  
f010102b:	c3                   	ret    

f010102c <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	53                   	push   %ebx
f0101030:	83 ec 18             	sub    $0x18,%esp
f0101033:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101036:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101039:	50                   	push   %eax
f010103a:	53                   	push   %ebx
f010103b:	ff 75 08             	pushl  0x8(%ebp)
f010103e:	e8 8f ff ff ff       	call   f0100fd2 <page_lookup>
	if (!pp)       			//if (!pp || !(*pte & PTE_P)) : page doesnt exist
f0101043:	83 c4 10             	add    $0x10,%esp
f0101046:	85 c0                	test   %eax,%eax
f0101048:	74 18                	je     f0101062 <page_remove+0x36>
	{
		return ;   		// do nothing
	}
	else
	{
		page_decref(pp);  	//decrement reference count and free page table if ref count==0
f010104a:	83 ec 0c             	sub    $0xc,%esp
f010104d:	50                   	push   %eax
f010104e:	e8 5b fe ff ff       	call   f0100eae <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101053:	0f 01 3b             	invlpg (%ebx)
		tlb_invalidate(pgdir, va);//invalidate TLB if entry removed from page table
		*pte = 0; 		  // making PTE corresponding to that va as zero
f0101056:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101059:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010105f:	83 c4 10             	add    $0x10,%esp
	}	 
}
f0101062:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101065:	c9                   	leave  
f0101066:	c3                   	ret    

f0101067 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101067:	55                   	push   %ebp
f0101068:	89 e5                	mov    %esp,%ebp
f010106a:	57                   	push   %edi
f010106b:	56                   	push   %esi
f010106c:	53                   	push   %ebx
f010106d:	83 ec 10             	sub    $0x10,%esp
f0101070:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101073:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101076:	6a 01                	push   $0x1
f0101078:	57                   	push   %edi
f0101079:	ff 75 08             	pushl  0x8(%ebp)
f010107c:	e8 54 fe ff ff       	call   f0100ed5 <pgdir_walk>
	
	
	if(pte==NULL)
f0101081:	83 c4 10             	add    $0x10,%esp
f0101084:	85 c0                	test   %eax,%eax
f0101086:	74 38                	je     f01010c0 <page_insert+0x59>
f0101088:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f010108a:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*pte & PTE_P)
f010108f:	f6 00 01             	testb  $0x1,(%eax)
f0101092:	74 0f                	je     f01010a3 <page_insert+0x3c>
		page_remove(pgdir,va);
f0101094:	83 ec 08             	sub    $0x8,%esp
f0101097:	57                   	push   %edi
f0101098:	ff 75 08             	pushl  0x8(%ebp)
f010109b:	e8 8c ff ff ff       	call   f010102c <page_remove>
f01010a0:	83 c4 10             	add    $0x10,%esp
	
	*pte = page2pa(pp) | perm | PTE_P;
f01010a3:	2b 1d 0c cb 17 f0    	sub    0xf017cb0c,%ebx
f01010a9:	c1 fb 03             	sar    $0x3,%ebx
f01010ac:	c1 e3 0c             	shl    $0xc,%ebx
f01010af:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b2:	83 c8 01             	or     $0x1,%eax
f01010b5:	09 c3                	or     %eax,%ebx
f01010b7:	89 1e                	mov    %ebx,(%esi)
	//pgdir[PDX(va)] |= perm;	
	
	return 0;
f01010b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010be:	eb 05                	jmp    f01010c5 <page_insert+0x5e>
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	
	
	if(pte==NULL)
		return -E_NO_MEM;
f01010c0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
	//pgdir[PDX(va)] |= perm;	
	
	return 0;
	
}
f01010c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010c8:	5b                   	pop    %ebx
f01010c9:	5e                   	pop    %esi
f01010ca:	5f                   	pop    %edi
f01010cb:	5d                   	pop    %ebp
f01010cc:	c3                   	ret    

f01010cd <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010cd:	55                   	push   %ebp
f01010ce:	89 e5                	mov    %esp,%ebp
f01010d0:	57                   	push   %edi
f01010d1:	56                   	push   %esi
f01010d2:	53                   	push   %ebx
f01010d3:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010d6:	b8 15 00 00 00       	mov    $0x15,%eax
f01010db:	e8 1d f8 ff ff       	call   f01008fd <nvram_read>
f01010e0:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010e2:	b8 17 00 00 00       	mov    $0x17,%eax
f01010e7:	e8 11 f8 ff ff       	call   f01008fd <nvram_read>
f01010ec:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010ee:	b8 34 00 00 00       	mov    $0x34,%eax
f01010f3:	e8 05 f8 ff ff       	call   f01008fd <nvram_read>
f01010f8:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010fb:	85 c0                	test   %eax,%eax
f01010fd:	74 07                	je     f0101106 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010ff:	05 00 40 00 00       	add    $0x4000,%eax
f0101104:	eb 0b                	jmp    f0101111 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101106:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010110c:	85 f6                	test   %esi,%esi
f010110e:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101111:	89 c2                	mov    %eax,%edx
f0101113:	c1 ea 02             	shr    $0x2,%edx
f0101116:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04
	npages_basemem = basemem / (PGSIZE / 1024);
f010111c:	89 da                	mov    %ebx,%edx
f010111e:	c1 ea 02             	shr    $0x2,%edx
f0101121:	89 15 40 be 17 f0    	mov    %edx,0xf017be40

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101127:	89 c2                	mov    %eax,%edx
f0101129:	29 da                	sub    %ebx,%edx
f010112b:	52                   	push   %edx
f010112c:	53                   	push   %ebx
f010112d:	50                   	push   %eax
f010112e:	68 90 4f 10 f0       	push   $0xf0104f90
f0101133:	e8 70 1d 00 00       	call   f0102ea8 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101138:	b8 00 10 00 00       	mov    $0x1000,%eax
f010113d:	e8 e4 f7 ff ff       	call   f0100926 <boot_alloc>
f0101142:	a3 08 cb 17 f0       	mov    %eax,0xf017cb08
	memset(kern_pgdir, 0, PGSIZE);
f0101147:	83 c4 0c             	add    $0xc,%esp
f010114a:	68 00 10 00 00       	push   $0x1000
f010114f:	6a 00                	push   $0x0
f0101151:	50                   	push   %eax
f0101152:	e8 c2 2f 00 00       	call   f0104119 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101157:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010115c:	83 c4 10             	add    $0x10,%esp
f010115f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101164:	77 15                	ja     f010117b <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101166:	50                   	push   %eax
f0101167:	68 cc 4f 10 f0       	push   $0xf0104fcc
f010116c:	68 9b 00 00 00       	push   $0x9b
f0101171:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101176:	e8 25 ef ff ff       	call   f01000a0 <_panic>
f010117b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101181:	83 ca 05             	or     $0x5,%edx
f0101184:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

        pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f010118a:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f010118f:	c1 e0 03             	shl    $0x3,%eax
f0101192:	e8 8f f7 ff ff       	call   f0100926 <boot_alloc>
f0101197:	a3 0c cb 17 f0       	mov    %eax,0xf017cb0c
    	memset(pages, 0, sizeof(struct PageInfo) * npages);
f010119c:	83 ec 04             	sub    $0x4,%esp
f010119f:	8b 3d 04 cb 17 f0    	mov    0xf017cb04,%edi
f01011a5:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011ac:	52                   	push   %edx
f01011ad:	6a 00                	push   $0x0
f01011af:	50                   	push   %eax
f01011b0:	e8 64 2f 00 00       	call   f0104119 <memset>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
        envs = (struct Env *)boot_alloc(NENV*sizeof(struct Env));
f01011b5:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011ba:	e8 67 f7 ff ff       	call   f0100926 <boot_alloc>
f01011bf:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011c4:	e8 2a fb ff ff       	call   f0100cf3 <page_init>

	check_page_free_list(1);
f01011c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01011ce:	e8 5d f8 ff ff       	call   f0100a30 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011d3:	83 c4 10             	add    $0x10,%esp
f01011d6:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01011dd:	75 17                	jne    f01011f6 <mem_init+0x129>
		panic("'pages' is a null pointer!");
f01011df:	83 ec 04             	sub    $0x4,%esp
f01011e2:	68 9a 4b 10 f0       	push   $0xf0104b9a
f01011e7:	68 c6 02 00 00       	push   $0x2c6
f01011ec:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01011f1:	e8 aa ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f6:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01011fb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101200:	eb 05                	jmp    f0101207 <mem_init+0x13a>
		++nfree;
f0101202:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101205:	8b 00                	mov    (%eax),%eax
f0101207:	85 c0                	test   %eax,%eax
f0101209:	75 f7                	jne    f0101202 <mem_init+0x135>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010120b:	83 ec 0c             	sub    $0xc,%esp
f010120e:	6a 00                	push   $0x0
f0101210:	e8 ee fb ff ff       	call   f0100e03 <page_alloc>
f0101215:	89 c7                	mov    %eax,%edi
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	85 c0                	test   %eax,%eax
f010121c:	75 19                	jne    f0101237 <mem_init+0x16a>
f010121e:	68 b5 4b 10 f0       	push   $0xf0104bb5
f0101223:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101228:	68 ce 02 00 00       	push   $0x2ce
f010122d:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101232:	e8 69 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101237:	83 ec 0c             	sub    $0xc,%esp
f010123a:	6a 00                	push   $0x0
f010123c:	e8 c2 fb ff ff       	call   f0100e03 <page_alloc>
f0101241:	89 c6                	mov    %eax,%esi
f0101243:	83 c4 10             	add    $0x10,%esp
f0101246:	85 c0                	test   %eax,%eax
f0101248:	75 19                	jne    f0101263 <mem_init+0x196>
f010124a:	68 cb 4b 10 f0       	push   $0xf0104bcb
f010124f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101254:	68 cf 02 00 00       	push   $0x2cf
f0101259:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010125e:	e8 3d ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101263:	83 ec 0c             	sub    $0xc,%esp
f0101266:	6a 00                	push   $0x0
f0101268:	e8 96 fb ff ff       	call   f0100e03 <page_alloc>
f010126d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101270:	83 c4 10             	add    $0x10,%esp
f0101273:	85 c0                	test   %eax,%eax
f0101275:	75 19                	jne    f0101290 <mem_init+0x1c3>
f0101277:	68 e1 4b 10 f0       	push   $0xf0104be1
f010127c:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101281:	68 d0 02 00 00       	push   $0x2d0
f0101286:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010128b:	e8 10 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101290:	39 f7                	cmp    %esi,%edi
f0101292:	75 19                	jne    f01012ad <mem_init+0x1e0>
f0101294:	68 f7 4b 10 f0       	push   $0xf0104bf7
f0101299:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010129e:	68 d3 02 00 00       	push   $0x2d3
f01012a3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01012a8:	e8 f3 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012b0:	39 c6                	cmp    %eax,%esi
f01012b2:	74 04                	je     f01012b8 <mem_init+0x1eb>
f01012b4:	39 c7                	cmp    %eax,%edi
f01012b6:	75 19                	jne    f01012d1 <mem_init+0x204>
f01012b8:	68 f0 4f 10 f0       	push   $0xf0104ff0
f01012bd:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01012c2:	68 d4 02 00 00       	push   $0x2d4
f01012c7:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01012cc:	e8 cf ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012d1:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012d7:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01012dd:	c1 e2 0c             	shl    $0xc,%edx
f01012e0:	89 f8                	mov    %edi,%eax
f01012e2:	29 c8                	sub    %ecx,%eax
f01012e4:	c1 f8 03             	sar    $0x3,%eax
f01012e7:	c1 e0 0c             	shl    $0xc,%eax
f01012ea:	39 d0                	cmp    %edx,%eax
f01012ec:	72 19                	jb     f0101307 <mem_init+0x23a>
f01012ee:	68 09 4c 10 f0       	push   $0xf0104c09
f01012f3:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01012f8:	68 d5 02 00 00       	push   $0x2d5
f01012fd:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101302:	e8 99 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101307:	89 f0                	mov    %esi,%eax
f0101309:	29 c8                	sub    %ecx,%eax
f010130b:	c1 f8 03             	sar    $0x3,%eax
f010130e:	c1 e0 0c             	shl    $0xc,%eax
f0101311:	39 c2                	cmp    %eax,%edx
f0101313:	77 19                	ja     f010132e <mem_init+0x261>
f0101315:	68 26 4c 10 f0       	push   $0xf0104c26
f010131a:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010131f:	68 d6 02 00 00       	push   $0x2d6
f0101324:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101329:	e8 72 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010132e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101331:	29 c8                	sub    %ecx,%eax
f0101333:	c1 f8 03             	sar    $0x3,%eax
f0101336:	c1 e0 0c             	shl    $0xc,%eax
f0101339:	39 c2                	cmp    %eax,%edx
f010133b:	77 19                	ja     f0101356 <mem_init+0x289>
f010133d:	68 43 4c 10 f0       	push   $0xf0104c43
f0101342:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101347:	68 d7 02 00 00       	push   $0x2d7
f010134c:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101351:	e8 4a ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101356:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f010135b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010135e:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0101365:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101368:	83 ec 0c             	sub    $0xc,%esp
f010136b:	6a 00                	push   $0x0
f010136d:	e8 91 fa ff ff       	call   f0100e03 <page_alloc>
f0101372:	83 c4 10             	add    $0x10,%esp
f0101375:	85 c0                	test   %eax,%eax
f0101377:	74 19                	je     f0101392 <mem_init+0x2c5>
f0101379:	68 60 4c 10 f0       	push   $0xf0104c60
f010137e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101383:	68 de 02 00 00       	push   $0x2de
f0101388:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010138d:	e8 0e ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101392:	83 ec 0c             	sub    $0xc,%esp
f0101395:	57                   	push   %edi
f0101396:	e8 d8 fa ff ff       	call   f0100e73 <page_free>
	page_free(pp1);
f010139b:	89 34 24             	mov    %esi,(%esp)
f010139e:	e8 d0 fa ff ff       	call   f0100e73 <page_free>
	page_free(pp2);
f01013a3:	83 c4 04             	add    $0x4,%esp
f01013a6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013a9:	e8 c5 fa ff ff       	call   f0100e73 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013b5:	e8 49 fa ff ff       	call   f0100e03 <page_alloc>
f01013ba:	89 c6                	mov    %eax,%esi
f01013bc:	83 c4 10             	add    $0x10,%esp
f01013bf:	85 c0                	test   %eax,%eax
f01013c1:	75 19                	jne    f01013dc <mem_init+0x30f>
f01013c3:	68 b5 4b 10 f0       	push   $0xf0104bb5
f01013c8:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01013cd:	68 e5 02 00 00       	push   $0x2e5
f01013d2:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01013d7:	e8 c4 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013dc:	83 ec 0c             	sub    $0xc,%esp
f01013df:	6a 00                	push   $0x0
f01013e1:	e8 1d fa ff ff       	call   f0100e03 <page_alloc>
f01013e6:	89 c7                	mov    %eax,%edi
f01013e8:	83 c4 10             	add    $0x10,%esp
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	75 19                	jne    f0101408 <mem_init+0x33b>
f01013ef:	68 cb 4b 10 f0       	push   $0xf0104bcb
f01013f4:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01013f9:	68 e6 02 00 00       	push   $0x2e6
f01013fe:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101403:	e8 98 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101408:	83 ec 0c             	sub    $0xc,%esp
f010140b:	6a 00                	push   $0x0
f010140d:	e8 f1 f9 ff ff       	call   f0100e03 <page_alloc>
f0101412:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101415:	83 c4 10             	add    $0x10,%esp
f0101418:	85 c0                	test   %eax,%eax
f010141a:	75 19                	jne    f0101435 <mem_init+0x368>
f010141c:	68 e1 4b 10 f0       	push   $0xf0104be1
f0101421:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101426:	68 e7 02 00 00       	push   $0x2e7
f010142b:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101430:	e8 6b ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101435:	39 fe                	cmp    %edi,%esi
f0101437:	75 19                	jne    f0101452 <mem_init+0x385>
f0101439:	68 f7 4b 10 f0       	push   $0xf0104bf7
f010143e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101443:	68 e9 02 00 00       	push   $0x2e9
f0101448:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010144d:	e8 4e ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101452:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101455:	39 c7                	cmp    %eax,%edi
f0101457:	74 04                	je     f010145d <mem_init+0x390>
f0101459:	39 c6                	cmp    %eax,%esi
f010145b:	75 19                	jne    f0101476 <mem_init+0x3a9>
f010145d:	68 f0 4f 10 f0       	push   $0xf0104ff0
f0101462:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101467:	68 ea 02 00 00       	push   $0x2ea
f010146c:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101471:	e8 2a ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101476:	83 ec 0c             	sub    $0xc,%esp
f0101479:	6a 00                	push   $0x0
f010147b:	e8 83 f9 ff ff       	call   f0100e03 <page_alloc>
f0101480:	83 c4 10             	add    $0x10,%esp
f0101483:	85 c0                	test   %eax,%eax
f0101485:	74 19                	je     f01014a0 <mem_init+0x3d3>
f0101487:	68 60 4c 10 f0       	push   $0xf0104c60
f010148c:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101491:	68 eb 02 00 00       	push   $0x2eb
f0101496:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010149b:	e8 00 ec ff ff       	call   f01000a0 <_panic>
f01014a0:	89 f0                	mov    %esi,%eax
f01014a2:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01014a8:	c1 f8 03             	sar    $0x3,%eax
f01014ab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ae:	89 c2                	mov    %eax,%edx
f01014b0:	c1 ea 0c             	shr    $0xc,%edx
f01014b3:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01014b9:	72 12                	jb     f01014cd <mem_init+0x400>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014bb:	50                   	push   %eax
f01014bc:	68 ec 4d 10 f0       	push   $0xf0104dec
f01014c1:	6a 56                	push   $0x56
f01014c3:	68 f0 4a 10 f0       	push   $0xf0104af0
f01014c8:	e8 d3 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014cd:	83 ec 04             	sub    $0x4,%esp
f01014d0:	68 00 10 00 00       	push   $0x1000
f01014d5:	6a 01                	push   $0x1
f01014d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014dc:	50                   	push   %eax
f01014dd:	e8 37 2c 00 00       	call   f0104119 <memset>
	page_free(pp0);
f01014e2:	89 34 24             	mov    %esi,(%esp)
f01014e5:	e8 89 f9 ff ff       	call   f0100e73 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014f1:	e8 0d f9 ff ff       	call   f0100e03 <page_alloc>
f01014f6:	83 c4 10             	add    $0x10,%esp
f01014f9:	85 c0                	test   %eax,%eax
f01014fb:	75 19                	jne    f0101516 <mem_init+0x449>
f01014fd:	68 6f 4c 10 f0       	push   $0xf0104c6f
f0101502:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101507:	68 f0 02 00 00       	push   $0x2f0
f010150c:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101511:	e8 8a eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101516:	39 c6                	cmp    %eax,%esi
f0101518:	74 19                	je     f0101533 <mem_init+0x466>
f010151a:	68 8d 4c 10 f0       	push   $0xf0104c8d
f010151f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101524:	68 f1 02 00 00       	push   $0x2f1
f0101529:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010152e:	e8 6d eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101533:	89 f0                	mov    %esi,%eax
f0101535:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010153b:	c1 f8 03             	sar    $0x3,%eax
f010153e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101541:	89 c2                	mov    %eax,%edx
f0101543:	c1 ea 0c             	shr    $0xc,%edx
f0101546:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010154c:	72 12                	jb     f0101560 <mem_init+0x493>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010154e:	50                   	push   %eax
f010154f:	68 ec 4d 10 f0       	push   $0xf0104dec
f0101554:	6a 56                	push   $0x56
f0101556:	68 f0 4a 10 f0       	push   $0xf0104af0
f010155b:	e8 40 eb ff ff       	call   f01000a0 <_panic>
f0101560:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101566:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010156c:	80 38 00             	cmpb   $0x0,(%eax)
f010156f:	74 19                	je     f010158a <mem_init+0x4bd>
f0101571:	68 9d 4c 10 f0       	push   $0xf0104c9d
f0101576:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010157b:	68 f4 02 00 00       	push   $0x2f4
f0101580:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101585:	e8 16 eb ff ff       	call   f01000a0 <_panic>
f010158a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010158d:	39 d0                	cmp    %edx,%eax
f010158f:	75 db                	jne    f010156c <mem_init+0x49f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101591:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101594:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101599:	83 ec 0c             	sub    $0xc,%esp
f010159c:	56                   	push   %esi
f010159d:	e8 d1 f8 ff ff       	call   f0100e73 <page_free>
	page_free(pp1);
f01015a2:	89 3c 24             	mov    %edi,(%esp)
f01015a5:	e8 c9 f8 ff ff       	call   f0100e73 <page_free>
	page_free(pp2);
f01015aa:	83 c4 04             	add    $0x4,%esp
f01015ad:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015b0:	e8 be f8 ff ff       	call   f0100e73 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015b5:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	eb 05                	jmp    f01015c4 <mem_init+0x4f7>
		--nfree;
f01015bf:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015c2:	8b 00                	mov    (%eax),%eax
f01015c4:	85 c0                	test   %eax,%eax
f01015c6:	75 f7                	jne    f01015bf <mem_init+0x4f2>
		--nfree;
	assert(nfree == 0);
f01015c8:	85 db                	test   %ebx,%ebx
f01015ca:	74 19                	je     f01015e5 <mem_init+0x518>
f01015cc:	68 a7 4c 10 f0       	push   $0xf0104ca7
f01015d1:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01015d6:	68 01 03 00 00       	push   $0x301
f01015db:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01015e0:	e8 bb ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015e5:	83 ec 0c             	sub    $0xc,%esp
f01015e8:	68 10 50 10 f0       	push   $0xf0105010
f01015ed:	e8 b6 18 00 00       	call   f0102ea8 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f9:	e8 05 f8 ff ff       	call   f0100e03 <page_alloc>
f01015fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101601:	83 c4 10             	add    $0x10,%esp
f0101604:	85 c0                	test   %eax,%eax
f0101606:	75 19                	jne    f0101621 <mem_init+0x554>
f0101608:	68 b5 4b 10 f0       	push   $0xf0104bb5
f010160d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101612:	68 5f 03 00 00       	push   $0x35f
f0101617:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010161c:	e8 7f ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 d8 f7 ff ff       	call   f0100e03 <page_alloc>
f010162b:	89 c3                	mov    %eax,%ebx
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x580>
f0101634:	68 cb 4b 10 f0       	push   $0xf0104bcb
f0101639:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010163e:	68 60 03 00 00       	push   $0x360
f0101643:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101648:	e8 53 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010164d:	83 ec 0c             	sub    $0xc,%esp
f0101650:	6a 00                	push   $0x0
f0101652:	e8 ac f7 ff ff       	call   f0100e03 <page_alloc>
f0101657:	89 c6                	mov    %eax,%esi
f0101659:	83 c4 10             	add    $0x10,%esp
f010165c:	85 c0                	test   %eax,%eax
f010165e:	75 19                	jne    f0101679 <mem_init+0x5ac>
f0101660:	68 e1 4b 10 f0       	push   $0xf0104be1
f0101665:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010166a:	68 61 03 00 00       	push   $0x361
f010166f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101674:	e8 27 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101679:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010167c:	75 19                	jne    f0101697 <mem_init+0x5ca>
f010167e:	68 f7 4b 10 f0       	push   $0xf0104bf7
f0101683:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101688:	68 64 03 00 00       	push   $0x364
f010168d:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101697:	39 c3                	cmp    %eax,%ebx
f0101699:	74 05                	je     f01016a0 <mem_init+0x5d3>
f010169b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010169e:	75 19                	jne    f01016b9 <mem_init+0x5ec>
f01016a0:	68 f0 4f 10 f0       	push   $0xf0104ff0
f01016a5:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01016aa:	68 65 03 00 00       	push   $0x365
f01016af:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01016b4:	e8 e7 e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016b9:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01016be:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016c1:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f01016c8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016cb:	83 ec 0c             	sub    $0xc,%esp
f01016ce:	6a 00                	push   $0x0
f01016d0:	e8 2e f7 ff ff       	call   f0100e03 <page_alloc>
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	74 19                	je     f01016f5 <mem_init+0x628>
f01016dc:	68 60 4c 10 f0       	push   $0xf0104c60
f01016e1:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01016e6:	68 6c 03 00 00       	push   $0x36c
f01016eb:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01016f0:	e8 ab e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016f5:	83 ec 04             	sub    $0x4,%esp
f01016f8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016fb:	50                   	push   %eax
f01016fc:	6a 00                	push   $0x0
f01016fe:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101704:	e8 c9 f8 ff ff       	call   f0100fd2 <page_lookup>
f0101709:	83 c4 10             	add    $0x10,%esp
f010170c:	85 c0                	test   %eax,%eax
f010170e:	74 19                	je     f0101729 <mem_init+0x65c>
f0101710:	68 30 50 10 f0       	push   $0xf0105030
f0101715:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010171a:	68 6f 03 00 00       	push   $0x36f
f010171f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101724:	e8 77 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101729:	6a 02                	push   $0x2
f010172b:	6a 00                	push   $0x0
f010172d:	53                   	push   %ebx
f010172e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101734:	e8 2e f9 ff ff       	call   f0101067 <page_insert>
f0101739:	83 c4 10             	add    $0x10,%esp
f010173c:	85 c0                	test   %eax,%eax
f010173e:	78 19                	js     f0101759 <mem_init+0x68c>
f0101740:	68 68 50 10 f0       	push   $0xf0105068
f0101745:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010174a:	68 72 03 00 00       	push   $0x372
f010174f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101754:	e8 47 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101759:	83 ec 0c             	sub    $0xc,%esp
f010175c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010175f:	e8 0f f7 ff ff       	call   f0100e73 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101764:	6a 02                	push   $0x2
f0101766:	6a 00                	push   $0x0
f0101768:	53                   	push   %ebx
f0101769:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010176f:	e8 f3 f8 ff ff       	call   f0101067 <page_insert>
f0101774:	83 c4 20             	add    $0x20,%esp
f0101777:	85 c0                	test   %eax,%eax
f0101779:	74 19                	je     f0101794 <mem_init+0x6c7>
f010177b:	68 98 50 10 f0       	push   $0xf0105098
f0101780:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101785:	68 76 03 00 00       	push   $0x376
f010178a:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010178f:	e8 0c e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101794:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010179a:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f010179f:	89 c1                	mov    %eax,%ecx
f01017a1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017a4:	8b 17                	mov    (%edi),%edx
f01017a6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017af:	29 c8                	sub    %ecx,%eax
f01017b1:	c1 f8 03             	sar    $0x3,%eax
f01017b4:	c1 e0 0c             	shl    $0xc,%eax
f01017b7:	39 c2                	cmp    %eax,%edx
f01017b9:	74 19                	je     f01017d4 <mem_init+0x707>
f01017bb:	68 c8 50 10 f0       	push   $0xf01050c8
f01017c0:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01017c5:	68 77 03 00 00       	push   $0x377
f01017ca:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01017cf:	e8 cc e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01017d9:	89 f8                	mov    %edi,%eax
f01017db:	e8 ec f1 ff ff       	call   f01009cc <check_va2pa>
f01017e0:	89 da                	mov    %ebx,%edx
f01017e2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017e5:	c1 fa 03             	sar    $0x3,%edx
f01017e8:	c1 e2 0c             	shl    $0xc,%edx
f01017eb:	39 d0                	cmp    %edx,%eax
f01017ed:	74 19                	je     f0101808 <mem_init+0x73b>
f01017ef:	68 f0 50 10 f0       	push   $0xf01050f0
f01017f4:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01017f9:	68 78 03 00 00       	push   $0x378
f01017fe:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101803:	e8 98 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101808:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010180d:	74 19                	je     f0101828 <mem_init+0x75b>
f010180f:	68 b2 4c 10 f0       	push   $0xf0104cb2
f0101814:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101819:	68 79 03 00 00       	push   $0x379
f010181e:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101823:	e8 78 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101828:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101830:	74 19                	je     f010184b <mem_init+0x77e>
f0101832:	68 c3 4c 10 f0       	push   $0xf0104cc3
f0101837:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010183c:	68 7a 03 00 00       	push   $0x37a
f0101841:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101846:	e8 55 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010184b:	6a 02                	push   $0x2
f010184d:	68 00 10 00 00       	push   $0x1000
f0101852:	56                   	push   %esi
f0101853:	57                   	push   %edi
f0101854:	e8 0e f8 ff ff       	call   f0101067 <page_insert>
f0101859:	83 c4 10             	add    $0x10,%esp
f010185c:	85 c0                	test   %eax,%eax
f010185e:	74 19                	je     f0101879 <mem_init+0x7ac>
f0101860:	68 20 51 10 f0       	push   $0xf0105120
f0101865:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010186a:	68 7d 03 00 00       	push   $0x37d
f010186f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101874:	e8 27 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101879:	ba 00 10 00 00       	mov    $0x1000,%edx
f010187e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101883:	e8 44 f1 ff ff       	call   f01009cc <check_va2pa>
f0101888:	89 f2                	mov    %esi,%edx
f010188a:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101890:	c1 fa 03             	sar    $0x3,%edx
f0101893:	c1 e2 0c             	shl    $0xc,%edx
f0101896:	39 d0                	cmp    %edx,%eax
f0101898:	74 19                	je     f01018b3 <mem_init+0x7e6>
f010189a:	68 5c 51 10 f0       	push   $0xf010515c
f010189f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01018a4:	68 7e 03 00 00       	push   $0x37e
f01018a9:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01018ae:	e8 ed e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018b3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018b8:	74 19                	je     f01018d3 <mem_init+0x806>
f01018ba:	68 d4 4c 10 f0       	push   $0xf0104cd4
f01018bf:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01018c4:	68 7f 03 00 00       	push   $0x37f
f01018c9:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01018ce:	e8 cd e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018d3:	83 ec 0c             	sub    $0xc,%esp
f01018d6:	6a 00                	push   $0x0
f01018d8:	e8 26 f5 ff ff       	call   f0100e03 <page_alloc>
f01018dd:	83 c4 10             	add    $0x10,%esp
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	74 19                	je     f01018fd <mem_init+0x830>
f01018e4:	68 60 4c 10 f0       	push   $0xf0104c60
f01018e9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01018ee:	68 82 03 00 00       	push   $0x382
f01018f3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01018f8:	e8 a3 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018fd:	6a 02                	push   $0x2
f01018ff:	68 00 10 00 00       	push   $0x1000
f0101904:	56                   	push   %esi
f0101905:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010190b:	e8 57 f7 ff ff       	call   f0101067 <page_insert>
f0101910:	83 c4 10             	add    $0x10,%esp
f0101913:	85 c0                	test   %eax,%eax
f0101915:	74 19                	je     f0101930 <mem_init+0x863>
f0101917:	68 20 51 10 f0       	push   $0xf0105120
f010191c:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101921:	68 85 03 00 00       	push   $0x385
f0101926:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010192b:	e8 70 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101930:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101935:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010193a:	e8 8d f0 ff ff       	call   f01009cc <check_va2pa>
f010193f:	89 f2                	mov    %esi,%edx
f0101941:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101947:	c1 fa 03             	sar    $0x3,%edx
f010194a:	c1 e2 0c             	shl    $0xc,%edx
f010194d:	39 d0                	cmp    %edx,%eax
f010194f:	74 19                	je     f010196a <mem_init+0x89d>
f0101951:	68 5c 51 10 f0       	push   $0xf010515c
f0101956:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010195b:	68 86 03 00 00       	push   $0x386
f0101960:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101965:	e8 36 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010196a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010196f:	74 19                	je     f010198a <mem_init+0x8bd>
f0101971:	68 d4 4c 10 f0       	push   $0xf0104cd4
f0101976:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010197b:	68 87 03 00 00       	push   $0x387
f0101980:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101985:	e8 16 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010198a:	83 ec 0c             	sub    $0xc,%esp
f010198d:	6a 00                	push   $0x0
f010198f:	e8 6f f4 ff ff       	call   f0100e03 <page_alloc>
f0101994:	83 c4 10             	add    $0x10,%esp
f0101997:	85 c0                	test   %eax,%eax
f0101999:	74 19                	je     f01019b4 <mem_init+0x8e7>
f010199b:	68 60 4c 10 f0       	push   $0xf0104c60
f01019a0:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01019a5:	68 8b 03 00 00       	push   $0x38b
f01019aa:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01019af:	e8 ec e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019b4:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f01019ba:	8b 02                	mov    (%edx),%eax
f01019bc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019c1:	89 c1                	mov    %eax,%ecx
f01019c3:	c1 e9 0c             	shr    $0xc,%ecx
f01019c6:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f01019cc:	72 15                	jb     f01019e3 <mem_init+0x916>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019ce:	50                   	push   %eax
f01019cf:	68 ec 4d 10 f0       	push   $0xf0104dec
f01019d4:	68 8e 03 00 00       	push   $0x38e
f01019d9:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01019de:	e8 bd e6 ff ff       	call   f01000a0 <_panic>
f01019e3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019eb:	83 ec 04             	sub    $0x4,%esp
f01019ee:	6a 00                	push   $0x0
f01019f0:	68 00 10 00 00       	push   $0x1000
f01019f5:	52                   	push   %edx
f01019f6:	e8 da f4 ff ff       	call   f0100ed5 <pgdir_walk>
f01019fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019fe:	8d 57 04             	lea    0x4(%edi),%edx
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	39 d0                	cmp    %edx,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x954>
f0101a08:	68 8c 51 10 f0       	push   $0xf010518c
f0101a0d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101a12:	68 8f 03 00 00       	push   $0x38f
f0101a17:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101a1c:	e8 7f e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a21:	6a 06                	push   $0x6
f0101a23:	68 00 10 00 00       	push   $0x1000
f0101a28:	56                   	push   %esi
f0101a29:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a2f:	e8 33 f6 ff ff       	call   f0101067 <page_insert>
f0101a34:	83 c4 10             	add    $0x10,%esp
f0101a37:	85 c0                	test   %eax,%eax
f0101a39:	74 19                	je     f0101a54 <mem_init+0x987>
f0101a3b:	68 cc 51 10 f0       	push   $0xf01051cc
f0101a40:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101a45:	68 92 03 00 00       	push   $0x392
f0101a4a:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101a4f:	e8 4c e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a54:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101a5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a5f:	89 f8                	mov    %edi,%eax
f0101a61:	e8 66 ef ff ff       	call   f01009cc <check_va2pa>
f0101a66:	89 f2                	mov    %esi,%edx
f0101a68:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101a6e:	c1 fa 03             	sar    $0x3,%edx
f0101a71:	c1 e2 0c             	shl    $0xc,%edx
f0101a74:	39 d0                	cmp    %edx,%eax
f0101a76:	74 19                	je     f0101a91 <mem_init+0x9c4>
f0101a78:	68 5c 51 10 f0       	push   $0xf010515c
f0101a7d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101a82:	68 93 03 00 00       	push   $0x393
f0101a87:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101a8c:	e8 0f e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a91:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a96:	74 19                	je     f0101ab1 <mem_init+0x9e4>
f0101a98:	68 d4 4c 10 f0       	push   $0xf0104cd4
f0101a9d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101aa2:	68 94 03 00 00       	push   $0x394
f0101aa7:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101aac:	e8 ef e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ab1:	83 ec 04             	sub    $0x4,%esp
f0101ab4:	6a 00                	push   $0x0
f0101ab6:	68 00 10 00 00       	push   $0x1000
f0101abb:	57                   	push   %edi
f0101abc:	e8 14 f4 ff ff       	call   f0100ed5 <pgdir_walk>
f0101ac1:	83 c4 10             	add    $0x10,%esp
f0101ac4:	f6 00 04             	testb  $0x4,(%eax)
f0101ac7:	75 19                	jne    f0101ae2 <mem_init+0xa15>
f0101ac9:	68 0c 52 10 f0       	push   $0xf010520c
f0101ace:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101ad3:	68 95 03 00 00       	push   $0x395
f0101ad8:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101add:	e8 be e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ae2:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101ae7:	f6 00 04             	testb  $0x4,(%eax)
f0101aea:	75 19                	jne    f0101b05 <mem_init+0xa38>
f0101aec:	68 e5 4c 10 f0       	push   $0xf0104ce5
f0101af1:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101af6:	68 96 03 00 00       	push   $0x396
f0101afb:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101b00:	e8 9b e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b05:	6a 02                	push   $0x2
f0101b07:	68 00 10 00 00       	push   $0x1000
f0101b0c:	56                   	push   %esi
f0101b0d:	50                   	push   %eax
f0101b0e:	e8 54 f5 ff ff       	call   f0101067 <page_insert>
f0101b13:	83 c4 10             	add    $0x10,%esp
f0101b16:	85 c0                	test   %eax,%eax
f0101b18:	74 19                	je     f0101b33 <mem_init+0xa66>
f0101b1a:	68 20 51 10 f0       	push   $0xf0105120
f0101b1f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101b24:	68 99 03 00 00       	push   $0x399
f0101b29:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101b2e:	e8 6d e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b33:	83 ec 04             	sub    $0x4,%esp
f0101b36:	6a 00                	push   $0x0
f0101b38:	68 00 10 00 00       	push   $0x1000
f0101b3d:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b43:	e8 8d f3 ff ff       	call   f0100ed5 <pgdir_walk>
f0101b48:	83 c4 10             	add    $0x10,%esp
f0101b4b:	f6 00 02             	testb  $0x2,(%eax)
f0101b4e:	75 19                	jne    f0101b69 <mem_init+0xa9c>
f0101b50:	68 40 52 10 f0       	push   $0xf0105240
f0101b55:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101b5a:	68 9a 03 00 00       	push   $0x39a
f0101b5f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101b64:	e8 37 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b69:	83 ec 04             	sub    $0x4,%esp
f0101b6c:	6a 00                	push   $0x0
f0101b6e:	68 00 10 00 00       	push   $0x1000
f0101b73:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b79:	e8 57 f3 ff ff       	call   f0100ed5 <pgdir_walk>
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	f6 00 04             	testb  $0x4,(%eax)
f0101b84:	74 19                	je     f0101b9f <mem_init+0xad2>
f0101b86:	68 74 52 10 f0       	push   $0xf0105274
f0101b8b:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101b90:	68 9b 03 00 00       	push   $0x39b
f0101b95:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101b9a:	e8 01 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b9f:	6a 02                	push   $0x2
f0101ba1:	68 00 00 40 00       	push   $0x400000
f0101ba6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ba9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101baf:	e8 b3 f4 ff ff       	call   f0101067 <page_insert>
f0101bb4:	83 c4 10             	add    $0x10,%esp
f0101bb7:	85 c0                	test   %eax,%eax
f0101bb9:	78 19                	js     f0101bd4 <mem_init+0xb07>
f0101bbb:	68 ac 52 10 f0       	push   $0xf01052ac
f0101bc0:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101bc5:	68 9e 03 00 00       	push   $0x39e
f0101bca:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101bcf:	e8 cc e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bd4:	6a 02                	push   $0x2
f0101bd6:	68 00 10 00 00       	push   $0x1000
f0101bdb:	53                   	push   %ebx
f0101bdc:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101be2:	e8 80 f4 ff ff       	call   f0101067 <page_insert>
f0101be7:	83 c4 10             	add    $0x10,%esp
f0101bea:	85 c0                	test   %eax,%eax
f0101bec:	74 19                	je     f0101c07 <mem_init+0xb3a>
f0101bee:	68 e4 52 10 f0       	push   $0xf01052e4
f0101bf3:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101bf8:	68 a1 03 00 00       	push   $0x3a1
f0101bfd:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101c02:	e8 99 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c07:	83 ec 04             	sub    $0x4,%esp
f0101c0a:	6a 00                	push   $0x0
f0101c0c:	68 00 10 00 00       	push   $0x1000
f0101c11:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c17:	e8 b9 f2 ff ff       	call   f0100ed5 <pgdir_walk>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	f6 00 04             	testb  $0x4,(%eax)
f0101c22:	74 19                	je     f0101c3d <mem_init+0xb70>
f0101c24:	68 74 52 10 f0       	push   $0xf0105274
f0101c29:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101c2e:	68 a2 03 00 00       	push   $0x3a2
f0101c33:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101c38:	e8 63 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c3d:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101c43:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c48:	89 f8                	mov    %edi,%eax
f0101c4a:	e8 7d ed ff ff       	call   f01009cc <check_va2pa>
f0101c4f:	89 c1                	mov    %eax,%ecx
f0101c51:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c54:	89 d8                	mov    %ebx,%eax
f0101c56:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101c5c:	c1 f8 03             	sar    $0x3,%eax
f0101c5f:	c1 e0 0c             	shl    $0xc,%eax
f0101c62:	39 c1                	cmp    %eax,%ecx
f0101c64:	74 19                	je     f0101c7f <mem_init+0xbb2>
f0101c66:	68 20 53 10 f0       	push   $0xf0105320
f0101c6b:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101c70:	68 a5 03 00 00       	push   $0x3a5
f0101c75:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101c7a:	e8 21 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c7f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c84:	89 f8                	mov    %edi,%eax
f0101c86:	e8 41 ed ff ff       	call   f01009cc <check_va2pa>
f0101c8b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c8e:	74 19                	je     f0101ca9 <mem_init+0xbdc>
f0101c90:	68 4c 53 10 f0       	push   $0xf010534c
f0101c95:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101c9a:	68 a6 03 00 00       	push   $0x3a6
f0101c9f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101ca4:	e8 f7 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ca9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cae:	74 19                	je     f0101cc9 <mem_init+0xbfc>
f0101cb0:	68 fb 4c 10 f0       	push   $0xf0104cfb
f0101cb5:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101cba:	68 a8 03 00 00       	push   $0x3a8
f0101cbf:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101cc4:	e8 d7 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cc9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cce:	74 19                	je     f0101ce9 <mem_init+0xc1c>
f0101cd0:	68 0c 4d 10 f0       	push   $0xf0104d0c
f0101cd5:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101cda:	68 a9 03 00 00       	push   $0x3a9
f0101cdf:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101ce4:	e8 b7 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ce9:	83 ec 0c             	sub    $0xc,%esp
f0101cec:	6a 00                	push   $0x0
f0101cee:	e8 10 f1 ff ff       	call   f0100e03 <page_alloc>
f0101cf3:	83 c4 10             	add    $0x10,%esp
f0101cf6:	85 c0                	test   %eax,%eax
f0101cf8:	74 04                	je     f0101cfe <mem_init+0xc31>
f0101cfa:	39 c6                	cmp    %eax,%esi
f0101cfc:	74 19                	je     f0101d17 <mem_init+0xc4a>
f0101cfe:	68 7c 53 10 f0       	push   $0xf010537c
f0101d03:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101d08:	68 ac 03 00 00       	push   $0x3ac
f0101d0d:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101d12:	e8 89 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d17:	83 ec 08             	sub    $0x8,%esp
f0101d1a:	6a 00                	push   $0x0
f0101d1c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d22:	e8 05 f3 ff ff       	call   f010102c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d27:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d2d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d32:	89 f8                	mov    %edi,%eax
f0101d34:	e8 93 ec ff ff       	call   f01009cc <check_va2pa>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xc8d>
f0101d41:	68 a0 53 10 f0       	push   $0xf01053a0
f0101d46:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101d4b:	68 b0 03 00 00       	push   $0x3b0
f0101d50:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101d55:	e8 46 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d5f:	89 f8                	mov    %edi,%eax
f0101d61:	e8 66 ec ff ff       	call   f01009cc <check_va2pa>
f0101d66:	89 da                	mov    %ebx,%edx
f0101d68:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101d6e:	c1 fa 03             	sar    $0x3,%edx
f0101d71:	c1 e2 0c             	shl    $0xc,%edx
f0101d74:	39 d0                	cmp    %edx,%eax
f0101d76:	74 19                	je     f0101d91 <mem_init+0xcc4>
f0101d78:	68 4c 53 10 f0       	push   $0xf010534c
f0101d7d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101d82:	68 b1 03 00 00       	push   $0x3b1
f0101d87:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101d8c:	e8 0f e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d91:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d96:	74 19                	je     f0101db1 <mem_init+0xce4>
f0101d98:	68 b2 4c 10 f0       	push   $0xf0104cb2
f0101d9d:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101da2:	68 b2 03 00 00       	push   $0x3b2
f0101da7:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101dac:	e8 ef e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101db1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101db6:	74 19                	je     f0101dd1 <mem_init+0xd04>
f0101db8:	68 0c 4d 10 f0       	push   $0xf0104d0c
f0101dbd:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101dc2:	68 b3 03 00 00       	push   $0x3b3
f0101dc7:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101dcc:	e8 cf e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dd1:	6a 00                	push   $0x0
f0101dd3:	68 00 10 00 00       	push   $0x1000
f0101dd8:	53                   	push   %ebx
f0101dd9:	57                   	push   %edi
f0101dda:	e8 88 f2 ff ff       	call   f0101067 <page_insert>
f0101ddf:	83 c4 10             	add    $0x10,%esp
f0101de2:	85 c0                	test   %eax,%eax
f0101de4:	74 19                	je     f0101dff <mem_init+0xd32>
f0101de6:	68 c4 53 10 f0       	push   $0xf01053c4
f0101deb:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101df0:	68 b6 03 00 00       	push   $0x3b6
f0101df5:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101dfa:	e8 a1 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101dff:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e04:	75 19                	jne    f0101e1f <mem_init+0xd52>
f0101e06:	68 1d 4d 10 f0       	push   $0xf0104d1d
f0101e0b:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101e10:	68 b7 03 00 00       	push   $0x3b7
f0101e15:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101e1a:	e8 81 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e1f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e22:	74 19                	je     f0101e3d <mem_init+0xd70>
f0101e24:	68 29 4d 10 f0       	push   $0xf0104d29
f0101e29:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101e2e:	68 b8 03 00 00       	push   $0x3b8
f0101e33:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101e38:	e8 63 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e3d:	83 ec 08             	sub    $0x8,%esp
f0101e40:	68 00 10 00 00       	push   $0x1000
f0101e45:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101e4b:	e8 dc f1 ff ff       	call   f010102c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e50:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101e56:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e5b:	89 f8                	mov    %edi,%eax
f0101e5d:	e8 6a eb ff ff       	call   f01009cc <check_va2pa>
f0101e62:	83 c4 10             	add    $0x10,%esp
f0101e65:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e68:	74 19                	je     f0101e83 <mem_init+0xdb6>
f0101e6a:	68 a0 53 10 f0       	push   $0xf01053a0
f0101e6f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101e74:	68 bc 03 00 00       	push   $0x3bc
f0101e79:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101e7e:	e8 1d e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e83:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e88:	89 f8                	mov    %edi,%eax
f0101e8a:	e8 3d eb ff ff       	call   f01009cc <check_va2pa>
f0101e8f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e92:	74 19                	je     f0101ead <mem_init+0xde0>
f0101e94:	68 fc 53 10 f0       	push   $0xf01053fc
f0101e99:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101e9e:	68 bd 03 00 00       	push   $0x3bd
f0101ea3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101ea8:	e8 f3 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ead:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eb2:	74 19                	je     f0101ecd <mem_init+0xe00>
f0101eb4:	68 3e 4d 10 f0       	push   $0xf0104d3e
f0101eb9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101ebe:	68 be 03 00 00       	push   $0x3be
f0101ec3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101ec8:	e8 d3 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ecd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ed2:	74 19                	je     f0101eed <mem_init+0xe20>
f0101ed4:	68 0c 4d 10 f0       	push   $0xf0104d0c
f0101ed9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101ede:	68 bf 03 00 00       	push   $0x3bf
f0101ee3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101ee8:	e8 b3 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eed:	83 ec 0c             	sub    $0xc,%esp
f0101ef0:	6a 00                	push   $0x0
f0101ef2:	e8 0c ef ff ff       	call   f0100e03 <page_alloc>
f0101ef7:	83 c4 10             	add    $0x10,%esp
f0101efa:	39 c3                	cmp    %eax,%ebx
f0101efc:	75 04                	jne    f0101f02 <mem_init+0xe35>
f0101efe:	85 c0                	test   %eax,%eax
f0101f00:	75 19                	jne    f0101f1b <mem_init+0xe4e>
f0101f02:	68 24 54 10 f0       	push   $0xf0105424
f0101f07:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101f0c:	68 c2 03 00 00       	push   $0x3c2
f0101f11:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101f16:	e8 85 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f1b:	83 ec 0c             	sub    $0xc,%esp
f0101f1e:	6a 00                	push   $0x0
f0101f20:	e8 de ee ff ff       	call   f0100e03 <page_alloc>
f0101f25:	83 c4 10             	add    $0x10,%esp
f0101f28:	85 c0                	test   %eax,%eax
f0101f2a:	74 19                	je     f0101f45 <mem_init+0xe78>
f0101f2c:	68 60 4c 10 f0       	push   $0xf0104c60
f0101f31:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101f36:	68 c5 03 00 00       	push   $0x3c5
f0101f3b:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101f40:	e8 5b e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f45:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0101f4b:	8b 11                	mov    (%ecx),%edx
f0101f4d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f56:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101f5c:	c1 f8 03             	sar    $0x3,%eax
f0101f5f:	c1 e0 0c             	shl    $0xc,%eax
f0101f62:	39 c2                	cmp    %eax,%edx
f0101f64:	74 19                	je     f0101f7f <mem_init+0xeb2>
f0101f66:	68 c8 50 10 f0       	push   $0xf01050c8
f0101f6b:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101f70:	68 c8 03 00 00       	push   $0x3c8
f0101f75:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101f7a:	e8 21 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f7f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f88:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f8d:	74 19                	je     f0101fa8 <mem_init+0xedb>
f0101f8f:	68 c3 4c 10 f0       	push   $0xf0104cc3
f0101f94:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0101f99:	68 ca 03 00 00       	push   $0x3ca
f0101f9e:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0101fa3:	e8 f8 e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101fa8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fb1:	83 ec 0c             	sub    $0xc,%esp
f0101fb4:	50                   	push   %eax
f0101fb5:	e8 b9 ee ff ff       	call   f0100e73 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fba:	83 c4 0c             	add    $0xc,%esp
f0101fbd:	6a 01                	push   $0x1
f0101fbf:	68 00 10 40 00       	push   $0x401000
f0101fc4:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101fca:	e8 06 ef ff ff       	call   f0100ed5 <pgdir_walk>
f0101fcf:	89 c7                	mov    %eax,%edi
f0101fd1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fd4:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101fd9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fdc:	8b 40 04             	mov    0x4(%eax),%eax
f0101fdf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fe4:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0101fea:	89 c2                	mov    %eax,%edx
f0101fec:	c1 ea 0c             	shr    $0xc,%edx
f0101fef:	83 c4 10             	add    $0x10,%esp
f0101ff2:	39 ca                	cmp    %ecx,%edx
f0101ff4:	72 15                	jb     f010200b <mem_init+0xf3e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ff6:	50                   	push   %eax
f0101ff7:	68 ec 4d 10 f0       	push   $0xf0104dec
f0101ffc:	68 d1 03 00 00       	push   $0x3d1
f0102001:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102006:	e8 95 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010200b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102010:	39 c7                	cmp    %eax,%edi
f0102012:	74 19                	je     f010202d <mem_init+0xf60>
f0102014:	68 4f 4d 10 f0       	push   $0xf0104d4f
f0102019:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010201e:	68 d2 03 00 00       	push   $0x3d2
f0102023:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102028:	e8 73 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010202d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102030:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102037:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010203a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102040:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102046:	c1 f8 03             	sar    $0x3,%eax
f0102049:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010204c:	89 c2                	mov    %eax,%edx
f010204e:	c1 ea 0c             	shr    $0xc,%edx
f0102051:	39 d1                	cmp    %edx,%ecx
f0102053:	77 12                	ja     f0102067 <mem_init+0xf9a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102055:	50                   	push   %eax
f0102056:	68 ec 4d 10 f0       	push   $0xf0104dec
f010205b:	6a 56                	push   $0x56
f010205d:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102062:	e8 39 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102067:	83 ec 04             	sub    $0x4,%esp
f010206a:	68 00 10 00 00       	push   $0x1000
f010206f:	68 ff 00 00 00       	push   $0xff
f0102074:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102079:	50                   	push   %eax
f010207a:	e8 9a 20 00 00       	call   f0104119 <memset>
	page_free(pp0);
f010207f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102082:	89 3c 24             	mov    %edi,(%esp)
f0102085:	e8 e9 ed ff ff       	call   f0100e73 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010208a:	83 c4 0c             	add    $0xc,%esp
f010208d:	6a 01                	push   $0x1
f010208f:	6a 00                	push   $0x0
f0102091:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102097:	e8 39 ee ff ff       	call   f0100ed5 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010209c:	89 fa                	mov    %edi,%edx
f010209e:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f01020a4:	c1 fa 03             	sar    $0x3,%edx
f01020a7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020aa:	89 d0                	mov    %edx,%eax
f01020ac:	c1 e8 0c             	shr    $0xc,%eax
f01020af:	83 c4 10             	add    $0x10,%esp
f01020b2:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f01020b8:	72 12                	jb     f01020cc <mem_init+0xfff>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020ba:	52                   	push   %edx
f01020bb:	68 ec 4d 10 f0       	push   $0xf0104dec
f01020c0:	6a 56                	push   $0x56
f01020c2:	68 f0 4a 10 f0       	push   $0xf0104af0
f01020c7:	e8 d4 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01020cc:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020d5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020db:	f6 00 01             	testb  $0x1,(%eax)
f01020de:	74 19                	je     f01020f9 <mem_init+0x102c>
f01020e0:	68 67 4d 10 f0       	push   $0xf0104d67
f01020e5:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01020ea:	68 dc 03 00 00       	push   $0x3dc
f01020ef:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01020f4:	e8 a7 df ff ff       	call   f01000a0 <_panic>
f01020f9:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020fc:	39 c2                	cmp    %eax,%edx
f01020fe:	75 db                	jne    f01020db <mem_init+0x100e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102100:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102105:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010210b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010210e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102114:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102117:	89 3d 3c be 17 f0    	mov    %edi,0xf017be3c

	// free the pages we took
	page_free(pp0);
f010211d:	83 ec 0c             	sub    $0xc,%esp
f0102120:	50                   	push   %eax
f0102121:	e8 4d ed ff ff       	call   f0100e73 <page_free>
	page_free(pp1);
f0102126:	89 1c 24             	mov    %ebx,(%esp)
f0102129:	e8 45 ed ff ff       	call   f0100e73 <page_free>
	page_free(pp2);
f010212e:	89 34 24             	mov    %esi,(%esp)
f0102131:	e8 3d ed ff ff       	call   f0100e73 <page_free>

	cprintf("check_page() succeeded!\n");
f0102136:	c7 04 24 7e 4d 10 f0 	movl   $0xf0104d7e,(%esp)
f010213d:	e8 66 0d 00 00       	call   f0102ea8 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

       boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102142:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102147:	83 c4 10             	add    $0x10,%esp
f010214a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010214f:	77 15                	ja     f0102166 <mem_init+0x1099>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102151:	50                   	push   %eax
f0102152:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102157:	68 ca 00 00 00       	push   $0xca
f010215c:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102161:	e8 3a df ff ff       	call   f01000a0 <_panic>
f0102166:	83 ec 08             	sub    $0x8,%esp
f0102169:	6a 05                	push   $0x5
f010216b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102170:	50                   	push   %eax
f0102171:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102176:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010217b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102180:	e8 e3 ed ff ff       	call   f0100f68 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102185:	a1 48 be 17 f0       	mov    0xf017be48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218a:	83 c4 10             	add    $0x10,%esp
f010218d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102192:	77 15                	ja     f01021a9 <mem_init+0x10dc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102194:	50                   	push   %eax
f0102195:	68 cc 4f 10 f0       	push   $0xf0104fcc
f010219a:	68 d3 00 00 00       	push   $0xd3
f010219f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01021a4:	e8 f7 de ff ff       	call   f01000a0 <_panic>
f01021a9:	83 ec 08             	sub    $0x8,%esp
f01021ac:	6a 05                	push   $0x5
f01021ae:	05 00 00 00 10       	add    $0x10000000,%eax
f01021b3:	50                   	push   %eax
f01021b4:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021b9:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021be:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01021c3:	e8 a0 ed ff ff       	call   f0100f68 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c8:	83 c4 10             	add    $0x10,%esp
f01021cb:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01021d0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d5:	77 15                	ja     f01021ec <mem_init+0x111f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d7:	50                   	push   %eax
f01021d8:	68 cc 4f 10 f0       	push   $0xf0104fcc
f01021dd:	68 e0 00 00 00       	push   $0xe0
f01021e2:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01021e7:	e8 b4 de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

        boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f01021ec:	83 ec 08             	sub    $0x8,%esp
f01021ef:	6a 03                	push   $0x3
f01021f1:	68 00 00 11 00       	push   $0x110000
f01021f6:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021fb:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102200:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102205:	e8 5e ed ff ff       	call   f0100f68 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

        boot_map_region(kern_pgdir, KERNBASE, 0xFFFFFFFF-KERNBASE, 0, PTE_W | PTE_P);
f010220a:	83 c4 08             	add    $0x8,%esp
f010220d:	6a 03                	push   $0x3
f010220f:	6a 00                	push   $0x0
f0102211:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102216:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010221b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102220:	e8 43 ed ff ff       	call   f0100f68 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102225:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010222b:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0102230:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102233:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010223a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010223f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102242:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102248:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010224b:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010224e:	be 00 00 00 00       	mov    $0x0,%esi
f0102253:	eb 55                	jmp    f01022aa <mem_init+0x11dd>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102255:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010225b:	89 d8                	mov    %ebx,%eax
f010225d:	e8 6a e7 ff ff       	call   f01009cc <check_va2pa>
f0102262:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102269:	77 15                	ja     f0102280 <mem_init+0x11b3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010226b:	57                   	push   %edi
f010226c:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102271:	68 19 03 00 00       	push   $0x319
f0102276:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010227b:	e8 20 de ff ff       	call   f01000a0 <_panic>
f0102280:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102287:	39 d0                	cmp    %edx,%eax
f0102289:	74 19                	je     f01022a4 <mem_init+0x11d7>
f010228b:	68 48 54 10 f0       	push   $0xf0105448
f0102290:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102295:	68 19 03 00 00       	push   $0x319
f010229a:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010229f:	e8 fc dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022a4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022aa:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022ad:	77 a6                	ja     f0102255 <mem_init+0x1188>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022af:	8b 3d 48 be 17 f0    	mov    0xf017be48,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022b5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022b8:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022bd:	89 f2                	mov    %esi,%edx
f01022bf:	89 d8                	mov    %ebx,%eax
f01022c1:	e8 06 e7 ff ff       	call   f01009cc <check_va2pa>
f01022c6:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01022cd:	77 15                	ja     f01022e4 <mem_init+0x1217>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022cf:	57                   	push   %edi
f01022d0:	68 cc 4f 10 f0       	push   $0xf0104fcc
f01022d5:	68 1e 03 00 00       	push   $0x31e
f01022da:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01022df:	e8 bc dd ff ff       	call   f01000a0 <_panic>
f01022e4:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022eb:	39 c2                	cmp    %eax,%edx
f01022ed:	74 19                	je     f0102308 <mem_init+0x123b>
f01022ef:	68 7c 54 10 f0       	push   $0xf010547c
f01022f4:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01022f9:	68 1e 03 00 00       	push   $0x31e
f01022fe:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102303:	e8 98 dd ff ff       	call   f01000a0 <_panic>
f0102308:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010230e:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102314:	75 a7                	jne    f01022bd <mem_init+0x11f0>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102316:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102319:	c1 e7 0c             	shl    $0xc,%edi
f010231c:	be 00 00 00 00       	mov    $0x0,%esi
f0102321:	eb 30                	jmp    f0102353 <mem_init+0x1286>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102323:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102329:	89 d8                	mov    %ebx,%eax
f010232b:	e8 9c e6 ff ff       	call   f01009cc <check_va2pa>
f0102330:	39 c6                	cmp    %eax,%esi
f0102332:	74 19                	je     f010234d <mem_init+0x1280>
f0102334:	68 b0 54 10 f0       	push   $0xf01054b0
f0102339:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010233e:	68 22 03 00 00       	push   $0x322
f0102343:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102348:	e8 53 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010234d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102353:	39 fe                	cmp    %edi,%esi
f0102355:	72 cc                	jb     f0102323 <mem_init+0x1256>
f0102357:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010235c:	89 f2                	mov    %esi,%edx
f010235e:	89 d8                	mov    %ebx,%eax
f0102360:	e8 67 e6 ff ff       	call   f01009cc <check_va2pa>
f0102365:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f010236b:	39 c2                	cmp    %eax,%edx
f010236d:	74 19                	je     f0102388 <mem_init+0x12bb>
f010236f:	68 d8 54 10 f0       	push   $0xf01054d8
f0102374:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102379:	68 26 03 00 00       	push   $0x326
f010237e:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102383:	e8 18 dd ff ff       	call   f01000a0 <_panic>
f0102388:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010238e:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102394:	75 c6                	jne    f010235c <mem_init+0x128f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102396:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010239b:	89 d8                	mov    %ebx,%eax
f010239d:	e8 2a e6 ff ff       	call   f01009cc <check_va2pa>
f01023a2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023a5:	74 51                	je     f01023f8 <mem_init+0x132b>
f01023a7:	68 20 55 10 f0       	push   $0xf0105520
f01023ac:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01023b1:	68 27 03 00 00       	push   $0x327
f01023b6:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01023bb:	e8 e0 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023c0:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023c5:	72 36                	jb     f01023fd <mem_init+0x1330>
f01023c7:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023cc:	76 07                	jbe    f01023d5 <mem_init+0x1308>
f01023ce:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023d3:	75 28                	jne    f01023fd <mem_init+0x1330>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01023d5:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01023d9:	0f 85 83 00 00 00    	jne    f0102462 <mem_init+0x1395>
f01023df:	68 97 4d 10 f0       	push   $0xf0104d97
f01023e4:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01023e9:	68 30 03 00 00       	push   $0x330
f01023ee:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01023f3:	e8 a8 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023f8:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023fd:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102402:	76 3f                	jbe    f0102443 <mem_init+0x1376>
				assert(pgdir[i] & PTE_P);
f0102404:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102407:	f6 c2 01             	test   $0x1,%dl
f010240a:	75 19                	jne    f0102425 <mem_init+0x1358>
f010240c:	68 97 4d 10 f0       	push   $0xf0104d97
f0102411:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102416:	68 34 03 00 00       	push   $0x334
f010241b:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102420:	e8 7b dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102425:	f6 c2 02             	test   $0x2,%dl
f0102428:	75 38                	jne    f0102462 <mem_init+0x1395>
f010242a:	68 a8 4d 10 f0       	push   $0xf0104da8
f010242f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102434:	68 35 03 00 00       	push   $0x335
f0102439:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010243e:	e8 5d dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102443:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102447:	74 19                	je     f0102462 <mem_init+0x1395>
f0102449:	68 b9 4d 10 f0       	push   $0xf0104db9
f010244e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102453:	68 37 03 00 00       	push   $0x337
f0102458:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010245d:	e8 3e dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102462:	83 c0 01             	add    $0x1,%eax
f0102465:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010246a:	0f 86 50 ff ff ff    	jbe    f01023c0 <mem_init+0x12f3>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102470:	83 ec 0c             	sub    $0xc,%esp
f0102473:	68 50 55 10 f0       	push   $0xf0105550
f0102478:	e8 2b 0a 00 00       	call   f0102ea8 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010247d:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102482:	83 c4 10             	add    $0x10,%esp
f0102485:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010248a:	77 15                	ja     f01024a1 <mem_init+0x13d4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010248c:	50                   	push   %eax
f010248d:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102492:	68 f7 00 00 00       	push   $0xf7
f0102497:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010249c:	e8 ff db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01024a6:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01024ae:	e8 7d e5 ff ff       	call   f0100a30 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01024b3:	0f 20 c0             	mov    %cr0,%eax
f01024b6:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01024b9:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024be:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024c1:	83 ec 0c             	sub    $0xc,%esp
f01024c4:	6a 00                	push   $0x0
f01024c6:	e8 38 e9 ff ff       	call   f0100e03 <page_alloc>
f01024cb:	89 c3                	mov    %eax,%ebx
f01024cd:	83 c4 10             	add    $0x10,%esp
f01024d0:	85 c0                	test   %eax,%eax
f01024d2:	75 19                	jne    f01024ed <mem_init+0x1420>
f01024d4:	68 b5 4b 10 f0       	push   $0xf0104bb5
f01024d9:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01024de:	68 f7 03 00 00       	push   $0x3f7
f01024e3:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01024e8:	e8 b3 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024ed:	83 ec 0c             	sub    $0xc,%esp
f01024f0:	6a 00                	push   $0x0
f01024f2:	e8 0c e9 ff ff       	call   f0100e03 <page_alloc>
f01024f7:	89 c7                	mov    %eax,%edi
f01024f9:	83 c4 10             	add    $0x10,%esp
f01024fc:	85 c0                	test   %eax,%eax
f01024fe:	75 19                	jne    f0102519 <mem_init+0x144c>
f0102500:	68 cb 4b 10 f0       	push   $0xf0104bcb
f0102505:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010250a:	68 f8 03 00 00       	push   $0x3f8
f010250f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102514:	e8 87 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102519:	83 ec 0c             	sub    $0xc,%esp
f010251c:	6a 00                	push   $0x0
f010251e:	e8 e0 e8 ff ff       	call   f0100e03 <page_alloc>
f0102523:	89 c6                	mov    %eax,%esi
f0102525:	83 c4 10             	add    $0x10,%esp
f0102528:	85 c0                	test   %eax,%eax
f010252a:	75 19                	jne    f0102545 <mem_init+0x1478>
f010252c:	68 e1 4b 10 f0       	push   $0xf0104be1
f0102531:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102536:	68 f9 03 00 00       	push   $0x3f9
f010253b:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102540:	e8 5b db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102545:	83 ec 0c             	sub    $0xc,%esp
f0102548:	53                   	push   %ebx
f0102549:	e8 25 e9 ff ff       	call   f0100e73 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010254e:	89 f8                	mov    %edi,%eax
f0102550:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102556:	c1 f8 03             	sar    $0x3,%eax
f0102559:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010255c:	89 c2                	mov    %eax,%edx
f010255e:	c1 ea 0c             	shr    $0xc,%edx
f0102561:	83 c4 10             	add    $0x10,%esp
f0102564:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010256a:	72 12                	jb     f010257e <mem_init+0x14b1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010256c:	50                   	push   %eax
f010256d:	68 ec 4d 10 f0       	push   $0xf0104dec
f0102572:	6a 56                	push   $0x56
f0102574:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102579:	e8 22 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010257e:	83 ec 04             	sub    $0x4,%esp
f0102581:	68 00 10 00 00       	push   $0x1000
f0102586:	6a 01                	push   $0x1
f0102588:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010258d:	50                   	push   %eax
f010258e:	e8 86 1b 00 00       	call   f0104119 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102593:	89 f0                	mov    %esi,%eax
f0102595:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010259b:	c1 f8 03             	sar    $0x3,%eax
f010259e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a1:	89 c2                	mov    %eax,%edx
f01025a3:	c1 ea 0c             	shr    $0xc,%edx
f01025a6:	83 c4 10             	add    $0x10,%esp
f01025a9:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01025af:	72 12                	jb     f01025c3 <mem_init+0x14f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b1:	50                   	push   %eax
f01025b2:	68 ec 4d 10 f0       	push   $0xf0104dec
f01025b7:	6a 56                	push   $0x56
f01025b9:	68 f0 4a 10 f0       	push   $0xf0104af0
f01025be:	e8 dd da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025c3:	83 ec 04             	sub    $0x4,%esp
f01025c6:	68 00 10 00 00       	push   $0x1000
f01025cb:	6a 02                	push   $0x2
f01025cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025d2:	50                   	push   %eax
f01025d3:	e8 41 1b 00 00       	call   f0104119 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025d8:	6a 02                	push   $0x2
f01025da:	68 00 10 00 00       	push   $0x1000
f01025df:	57                   	push   %edi
f01025e0:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01025e6:	e8 7c ea ff ff       	call   f0101067 <page_insert>
	assert(pp1->pp_ref == 1);
f01025eb:	83 c4 20             	add    $0x20,%esp
f01025ee:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025f3:	74 19                	je     f010260e <mem_init+0x1541>
f01025f5:	68 b2 4c 10 f0       	push   $0xf0104cb2
f01025fa:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01025ff:	68 fe 03 00 00       	push   $0x3fe
f0102604:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102609:	e8 92 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010260e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102615:	01 01 01 
f0102618:	74 19                	je     f0102633 <mem_init+0x1566>
f010261a:	68 70 55 10 f0       	push   $0xf0105570
f010261f:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102624:	68 ff 03 00 00       	push   $0x3ff
f0102629:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010262e:	e8 6d da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102633:	6a 02                	push   $0x2
f0102635:	68 00 10 00 00       	push   $0x1000
f010263a:	56                   	push   %esi
f010263b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102641:	e8 21 ea ff ff       	call   f0101067 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102646:	83 c4 10             	add    $0x10,%esp
f0102649:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102650:	02 02 02 
f0102653:	74 19                	je     f010266e <mem_init+0x15a1>
f0102655:	68 94 55 10 f0       	push   $0xf0105594
f010265a:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010265f:	68 01 04 00 00       	push   $0x401
f0102664:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102669:	e8 32 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010266e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102673:	74 19                	je     f010268e <mem_init+0x15c1>
f0102675:	68 d4 4c 10 f0       	push   $0xf0104cd4
f010267a:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010267f:	68 02 04 00 00       	push   $0x402
f0102684:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102689:	e8 12 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010268e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102693:	74 19                	je     f01026ae <mem_init+0x15e1>
f0102695:	68 3e 4d 10 f0       	push   $0xf0104d3e
f010269a:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010269f:	68 03 04 00 00       	push   $0x403
f01026a4:	68 e4 4a 10 f0       	push   $0xf0104ae4
f01026a9:	e8 f2 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026ae:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026b5:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026b8:	89 f0                	mov    %esi,%eax
f01026ba:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01026c0:	c1 f8 03             	sar    $0x3,%eax
f01026c3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026c6:	89 c2                	mov    %eax,%edx
f01026c8:	c1 ea 0c             	shr    $0xc,%edx
f01026cb:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01026d1:	72 12                	jb     f01026e5 <mem_init+0x1618>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026d3:	50                   	push   %eax
f01026d4:	68 ec 4d 10 f0       	push   $0xf0104dec
f01026d9:	6a 56                	push   $0x56
f01026db:	68 f0 4a 10 f0       	push   $0xf0104af0
f01026e0:	e8 bb d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026e5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026ec:	03 03 03 
f01026ef:	74 19                	je     f010270a <mem_init+0x163d>
f01026f1:	68 b8 55 10 f0       	push   $0xf01055b8
f01026f6:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01026fb:	68 05 04 00 00       	push   $0x405
f0102700:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102705:	e8 96 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010270a:	83 ec 08             	sub    $0x8,%esp
f010270d:	68 00 10 00 00       	push   $0x1000
f0102712:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102718:	e8 0f e9 ff ff       	call   f010102c <page_remove>
	assert(pp2->pp_ref == 0);
f010271d:	83 c4 10             	add    $0x10,%esp
f0102720:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102725:	74 19                	je     f0102740 <mem_init+0x1673>
f0102727:	68 0c 4d 10 f0       	push   $0xf0104d0c
f010272c:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102731:	68 07 04 00 00       	push   $0x407
f0102736:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010273b:	e8 60 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102740:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0102746:	8b 11                	mov    (%ecx),%edx
f0102748:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010274e:	89 d8                	mov    %ebx,%eax
f0102750:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102756:	c1 f8 03             	sar    $0x3,%eax
f0102759:	c1 e0 0c             	shl    $0xc,%eax
f010275c:	39 c2                	cmp    %eax,%edx
f010275e:	74 19                	je     f0102779 <mem_init+0x16ac>
f0102760:	68 c8 50 10 f0       	push   $0xf01050c8
f0102765:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010276a:	68 0a 04 00 00       	push   $0x40a
f010276f:	68 e4 4a 10 f0       	push   $0xf0104ae4
f0102774:	e8 27 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102779:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010277f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102784:	74 19                	je     f010279f <mem_init+0x16d2>
f0102786:	68 c3 4c 10 f0       	push   $0xf0104cc3
f010278b:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0102790:	68 0c 04 00 00       	push   $0x40c
f0102795:	68 e4 4a 10 f0       	push   $0xf0104ae4
f010279a:	e8 01 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f010279f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027a5:	83 ec 0c             	sub    $0xc,%esp
f01027a8:	53                   	push   %ebx
f01027a9:	e8 c5 e6 ff ff       	call   f0100e73 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027ae:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f01027b5:	e8 ee 06 00 00       	call   f0102ea8 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027ba:	83 c4 10             	add    $0x10,%esp
f01027bd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027c0:	5b                   	pop    %ebx
f01027c1:	5e                   	pop    %esi
f01027c2:	5f                   	pop    %edi
f01027c3:	5d                   	pop    %ebp
f01027c4:	c3                   	ret    

f01027c5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027c5:	55                   	push   %ebp
f01027c6:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027cb:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027ce:	5d                   	pop    %ebp
f01027cf:	c3                   	ret    

f01027d0 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01027d0:	55                   	push   %ebp
f01027d1:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01027d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01027d8:	5d                   	pop    %ebp
f01027d9:	c3                   	ret    

f01027da <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01027da:	55                   	push   %ebp
f01027db:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01027dd:	5d                   	pop    %ebp
f01027de:	c3                   	ret    

f01027df <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027df:	55                   	push   %ebp
f01027e0:	89 e5                	mov    %esp,%ebp
f01027e2:	57                   	push   %edi
f01027e3:	56                   	push   %esi
f01027e4:	53                   	push   %ebx
f01027e5:	83 ec 0c             	sub    $0xc,%esp
f01027e8:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *start = ROUNDDOWN(va,PGSIZE);
f01027ea:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027f0:	89 d3                	mov    %edx,%ebx
	void *end = ROUNDUP(start+len,PGSIZE);
f01027f2:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01027f9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	for(start ; start<end ; start += PGSIZE){
f01027ff:	eb 3d                	jmp    f010283e <region_alloc+0x5f>
		p=page_alloc(0);
f0102801:	83 ec 0c             	sub    $0xc,%esp
f0102804:	6a 00                	push   $0x0
f0102806:	e8 f8 e5 ff ff       	call   f0100e03 <page_alloc>
		if(p==NULL)
f010280b:	83 c4 10             	add    $0x10,%esp
f010280e:	85 c0                	test   %eax,%eax
f0102810:	75 17                	jne    f0102829 <region_alloc+0x4a>
			panic("Could not allocate a page");
f0102812:	83 ec 04             	sub    $0x4,%esp
f0102815:	68 0d 56 10 f0       	push   $0xf010560d
f010281a:	68 1e 01 00 00       	push   $0x11e
f010281f:	68 27 56 10 f0       	push   $0xf0105627
f0102824:	e8 77 d8 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir , p , start , PTE_W | PTE_U | PTE_P);
f0102829:	6a 07                	push   $0x7
f010282b:	53                   	push   %ebx
f010282c:	50                   	push   %eax
f010282d:	ff 77 5c             	pushl  0x5c(%edi)
f0102830:	e8 32 e8 ff ff       	call   f0101067 <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *start = ROUNDDOWN(va,PGSIZE);
	void *end = ROUNDUP(start+len,PGSIZE);
	struct PageInfo *p = NULL;
	for(start ; start<end ; start += PGSIZE){
f0102835:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010283b:	83 c4 10             	add    $0x10,%esp
f010283e:	39 f3                	cmp    %esi,%ebx
f0102840:	72 bf                	jb     f0102801 <region_alloc+0x22>
		if(p==NULL)
			panic("Could not allocate a page");
		page_insert(e->env_pgdir , p , start , PTE_W | PTE_U | PTE_P);
		
	}
}
f0102842:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102845:	5b                   	pop    %ebx
f0102846:	5e                   	pop    %esi
f0102847:	5f                   	pop    %edi
f0102848:	5d                   	pop    %ebp
f0102849:	c3                   	ret    

f010284a <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010284a:	55                   	push   %ebp
f010284b:	89 e5                	mov    %esp,%ebp
f010284d:	8b 55 08             	mov    0x8(%ebp),%edx
f0102850:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102853:	85 d2                	test   %edx,%edx
f0102855:	75 11                	jne    f0102868 <envid2env+0x1e>
		*env_store = curenv;
f0102857:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010285c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010285f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102861:	b8 00 00 00 00       	mov    $0x0,%eax
f0102866:	eb 5e                	jmp    f01028c6 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102868:	89 d0                	mov    %edx,%eax
f010286a:	25 ff 03 00 00       	and    $0x3ff,%eax
f010286f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102872:	c1 e0 05             	shl    $0x5,%eax
f0102875:	03 05 48 be 17 f0    	add    0xf017be48,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010287b:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010287f:	74 05                	je     f0102886 <envid2env+0x3c>
f0102881:	3b 50 48             	cmp    0x48(%eax),%edx
f0102884:	74 10                	je     f0102896 <envid2env+0x4c>
		*env_store = 0;
f0102886:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102889:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010288f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102894:	eb 30                	jmp    f01028c6 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102896:	84 c9                	test   %cl,%cl
f0102898:	74 22                	je     f01028bc <envid2env+0x72>
f010289a:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f01028a0:	39 d0                	cmp    %edx,%eax
f01028a2:	74 18                	je     f01028bc <envid2env+0x72>
f01028a4:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028a7:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028aa:	74 10                	je     f01028bc <envid2env+0x72>
		*env_store = 0;
f01028ac:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028af:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028b5:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028ba:	eb 0a                	jmp    f01028c6 <envid2env+0x7c>
	}

	*env_store = e;
f01028bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028bf:	89 01                	mov    %eax,(%ecx)
	return 0;
f01028c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028c6:	5d                   	pop    %ebp
f01028c7:	c3                   	ret    

f01028c8 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01028c8:	55                   	push   %ebp
f01028c9:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01028cb:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01028d0:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01028d3:	b8 23 00 00 00       	mov    $0x23,%eax
f01028d8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01028da:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01028dc:	b8 10 00 00 00       	mov    $0x10,%eax
f01028e1:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01028e3:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01028e5:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01028e7:	ea ee 28 10 f0 08 00 	ljmp   $0x8,$0xf01028ee
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01028ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01028f3:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01028f6:	5d                   	pop    %ebp
f01028f7:	c3                   	ret    

f01028f8 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01028f8:	55                   	push   %ebp
f01028f9:	89 e5                	mov    %esp,%ebp
f01028fb:	56                   	push   %esi
f01028fc:	53                   	push   %ebx
	// LAB 3: Your code here.
	int32_t i;
	env_free_list =NULL;
	
	for(i=NENV; i>=0;i--){
	envs[i].env_id=0;                 //setting the ID to 0
f01028fd:	8b 35 48 be 17 f0    	mov    0xf017be48,%esi
f0102903:	8d 86 00 80 01 00    	lea    0x18000(%esi),%eax
f0102909:	8d 5e a0             	lea    -0x60(%esi),%ebx
f010290c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102911:	89 c1                	mov    %eax,%ecx
f0102913:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
	envs[i].env_link = env_free_list; 
f010291a:	89 50 44             	mov    %edx,0x44(%eax)
f010291d:	83 e8 60             	sub    $0x60,%eax
	env_free_list= &envs[i];	
f0102920:	89 ca                	mov    %ecx,%edx
	// Set up envs array
	// LAB 3: Your code here.
	int32_t i;
	env_free_list =NULL;
	
	for(i=NENV; i>=0;i--){
f0102922:	39 d8                	cmp    %ebx,%eax
f0102924:	75 eb                	jne    f0102911 <env_init+0x19>
f0102926:	89 35 4c be 17 f0    	mov    %esi,0xf017be4c
	envs[i].env_link = env_free_list; 
	env_free_list= &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f010292c:	e8 97 ff ff ff       	call   f01028c8 <env_init_percpu>
}
f0102931:	5b                   	pop    %ebx
f0102932:	5e                   	pop    %esi
f0102933:	5d                   	pop    %ebp
f0102934:	c3                   	ret    

f0102935 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102935:	55                   	push   %ebp
f0102936:	89 e5                	mov    %esp,%ebp
f0102938:	56                   	push   %esi
f0102939:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010293a:	8b 1d 4c be 17 f0    	mov    0xf017be4c,%ebx
f0102940:	85 db                	test   %ebx,%ebx
f0102942:	0f 84 45 01 00 00    	je     f0102a8d <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102948:	83 ec 0c             	sub    $0xc,%esp
f010294b:	6a 01                	push   $0x1
f010294d:	e8 b1 e4 ff ff       	call   f0100e03 <page_alloc>
f0102952:	89 c6                	mov    %eax,%esi
f0102954:	83 c4 10             	add    $0x10,%esp
f0102957:	85 c0                	test   %eax,%eax
f0102959:	0f 84 35 01 00 00    	je     f0102a94 <env_alloc+0x15f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010295f:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102965:	c1 f8 03             	sar    $0x3,%eax
f0102968:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010296b:	89 c2                	mov    %eax,%edx
f010296d:	c1 ea 0c             	shr    $0xc,%edx
f0102970:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102976:	72 12                	jb     f010298a <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102978:	50                   	push   %eax
f0102979:	68 ec 4d 10 f0       	push   $0xf0104dec
f010297e:	6a 56                	push   $0x56
f0102980:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102985:	e8 16 d7 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010298a:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t*) page2kva(p);
f010298f:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102992:	83 ec 04             	sub    $0x4,%esp
f0102995:	68 00 10 00 00       	push   $0x1000
f010299a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01029a0:	50                   	push   %eax
f01029a1:	e8 28 18 00 00       	call   f01041ce <memcpy>
	p->pp_ref++;
f01029a6:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029ab:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029ae:	83 c4 10             	add    $0x10,%esp
f01029b1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029b6:	77 15                	ja     f01029cd <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029b8:	50                   	push   %eax
f01029b9:	68 cc 4f 10 f0       	push   $0xf0104fcc
f01029be:	68 c3 00 00 00       	push   $0xc3
f01029c3:	68 27 56 10 f0       	push   $0xf0105627
f01029c8:	e8 d3 d6 ff ff       	call   f01000a0 <_panic>
f01029cd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029d3:	83 ca 05             	or     $0x5,%edx
f01029d6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029dc:	8b 43 48             	mov    0x48(%ebx),%eax
f01029df:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029e4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029e9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029ee:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029f1:	89 da                	mov    %ebx,%edx
f01029f3:	2b 15 48 be 17 f0    	sub    0xf017be48,%edx
f01029f9:	c1 fa 05             	sar    $0x5,%edx
f01029fc:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a02:	09 d0                	or     %edx,%eax
f0102a04:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a0a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a0d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a14:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a1b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a22:	83 ec 04             	sub    $0x4,%esp
f0102a25:	6a 44                	push   $0x44
f0102a27:	6a 00                	push   $0x0
f0102a29:	53                   	push   %ebx
f0102a2a:	e8 ea 16 00 00       	call   f0104119 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a2f:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a35:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a3b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a41:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a48:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a4e:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a51:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	*newenv_store = e;
f0102a56:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a59:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a5b:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a5e:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102a63:	83 c4 10             	add    $0x10,%esp
f0102a66:	85 c0                	test   %eax,%eax
f0102a68:	74 05                	je     f0102a6f <env_alloc+0x13a>
f0102a6a:	8b 40 48             	mov    0x48(%eax),%eax
f0102a6d:	eb 05                	jmp    f0102a74 <env_alloc+0x13f>
f0102a6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a74:	83 ec 04             	sub    $0x4,%esp
f0102a77:	52                   	push   %edx
f0102a78:	50                   	push   %eax
f0102a79:	68 32 56 10 f0       	push   $0xf0105632
f0102a7e:	e8 25 04 00 00       	call   f0102ea8 <cprintf>
	return 0;
f0102a83:	83 c4 10             	add    $0x10,%esp
f0102a86:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a8b:	eb 0c                	jmp    f0102a99 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a8d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a92:	eb 05                	jmp    f0102a99 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a94:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a99:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102a9c:	5b                   	pop    %ebx
f0102a9d:	5e                   	pop    %esi
f0102a9e:	5d                   	pop    %ebp
f0102a9f:	c3                   	ret    

f0102aa0 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102aa0:	55                   	push   %ebp
f0102aa1:	89 e5                	mov    %esp,%ebp
f0102aa3:	57                   	push   %edi
f0102aa4:	56                   	push   %esi
f0102aa5:	53                   	push   %ebx
f0102aa6:	83 ec 34             	sub    $0x34,%esp
f0102aa9:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
f0102aac:	6a 00                	push   $0x0
f0102aae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ab1:	50                   	push   %eax
f0102ab2:	e8 7e fe ff ff       	call   f0102935 <env_alloc>
	load_icode(penv, binary);
f0102ab7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102aba:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	struct Elf *elfhdr = (struct Elf *) binary;
	if (elfhdr->e_magic != ELF_MAGIC) {
f0102abd:	83 c4 10             	add    $0x10,%esp
f0102ac0:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102ac6:	74 15                	je     f0102add <env_create+0x3d>
		panic("load_icode failed: %p not a valid ELF file", binary);
f0102ac8:	57                   	push   %edi
f0102ac9:	68 70 56 10 f0       	push   $0xf0105670
f0102ace:	68 61 01 00 00       	push   $0x161
f0102ad3:	68 27 56 10 f0       	push   $0xf0105627
f0102ad8:	e8 c3 d5 ff ff       	call   f01000a0 <_panic>
		return;
	}

	struct Proghdr *ph = (struct Proghdr *) ((uint8_t *) elfhdr + elfhdr->e_phoff);
f0102add:	89 fb                	mov    %edi,%ebx
f0102adf:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elfhdr->e_phnum;
f0102ae2:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102ae6:	c1 e6 05             	shl    $0x5,%esi
f0102ae9:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir));
f0102aeb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aee:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102af1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af6:	77 15                	ja     f0102b0d <env_create+0x6d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af8:	50                   	push   %eax
f0102af9:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102afe:	68 67 01 00 00       	push   $0x167
f0102b03:	68 27 56 10 f0       	push   $0xf0105627
f0102b08:	e8 93 d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b0d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b12:	0f 22 d8             	mov    %eax,%cr3
f0102b15:	eb 59                	jmp    f0102b70 <env_create+0xd0>
	
	for (; ph < eph; ph++) {
		if (ph->p_type == ELF_PROG_LOAD) {
f0102b17:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b1a:	75 51                	jne    f0102b6d <env_create+0xcd>
			if (ph->p_filesz > ph->p_memsz) {
f0102b1c:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b1f:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0102b22:	76 17                	jbe    f0102b3b <env_create+0x9b>
				panic("load_icode failed: the ELF header should satisfies"
f0102b24:	83 ec 04             	sub    $0x4,%esp
f0102b27:	68 9c 56 10 f0       	push   $0xf010569c
f0102b2c:	68 6d 01 00 00       	push   $0x16d
f0102b31:	68 27 56 10 f0       	push   $0xf0105627
f0102b36:	e8 65 d5 ff ff       	call   f01000a0 <_panic>
				      "ph->p_filesz <= ph->p_memsz");
				return;
			}

			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0102b3b:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b41:	e8 99 fc ff ff       	call   f01027df <region_alloc>
			
			memcpy((void *) ph->p_va, (void *) (binary + ph->p_offset), ph->p_filesz);
f0102b46:	83 ec 04             	sub    $0x4,%esp
f0102b49:	ff 73 10             	pushl  0x10(%ebx)
f0102b4c:	89 f8                	mov    %edi,%eax
f0102b4e:	03 43 04             	add    0x4(%ebx),%eax
f0102b51:	50                   	push   %eax
f0102b52:	ff 73 08             	pushl  0x8(%ebx)
f0102b55:	e8 74 16 00 00       	call   f01041ce <memcpy>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0102b5a:	83 c4 0c             	add    $0xc,%esp
f0102b5d:	ff 73 14             	pushl  0x14(%ebx)
f0102b60:	6a 00                	push   $0x0
f0102b62:	ff 73 08             	pushl  0x8(%ebx)
f0102b65:	e8 af 15 00 00       	call   f0104119 <memset>
f0102b6a:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) ((uint8_t *) elfhdr + elfhdr->e_phoff);
	struct Proghdr *eph = ph + elfhdr->e_phnum;
	lcr3(PADDR(e->env_pgdir));
	
	for (; ph < eph; ph++) {
f0102b6d:	83 c3 20             	add    $0x20,%ebx
f0102b70:	39 de                	cmp    %ebx,%esi
f0102b72:	77 a3                	ja     f0102b17 <env_create+0x77>
			
			memcpy((void *) ph->p_va, (void *) (binary + ph->p_offset), ph->p_filesz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0102b74:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b79:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b7e:	77 15                	ja     f0102b95 <env_create+0xf5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b80:	50                   	push   %eax
f0102b81:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102b86:	68 77 01 00 00       	push   $0x177
f0102b8b:	68 27 56 10 f0       	push   $0xf0105627
f0102b90:	e8 0b d5 ff ff       	call   f01000a0 <_panic>
f0102b95:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b9a:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elfhdr->e_entry;
f0102b9d:	8b 47 18             	mov    0x18(%edi),%eax
f0102ba0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ba3:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102ba6:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bab:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bb0:	89 f8                	mov    %edi,%eax
f0102bb2:	e8 28 fc ff ff       	call   f01027df <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
	load_icode(penv, binary);
}
f0102bb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bba:	5b                   	pop    %ebx
f0102bbb:	5e                   	pop    %esi
f0102bbc:	5f                   	pop    %edi
f0102bbd:	5d                   	pop    %ebp
f0102bbe:	c3                   	ret    

f0102bbf <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102bbf:	55                   	push   %ebp
f0102bc0:	89 e5                	mov    %esp,%ebp
f0102bc2:	57                   	push   %edi
f0102bc3:	56                   	push   %esi
f0102bc4:	53                   	push   %ebx
f0102bc5:	83 ec 1c             	sub    $0x1c,%esp
f0102bc8:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102bcb:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102bd1:	39 fa                	cmp    %edi,%edx
f0102bd3:	75 29                	jne    f0102bfe <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102bd5:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bda:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bdf:	77 15                	ja     f0102bf6 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102be1:	50                   	push   %eax
f0102be2:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102be7:	68 9a 01 00 00       	push   $0x19a
f0102bec:	68 27 56 10 f0       	push   $0xf0105627
f0102bf1:	e8 aa d4 ff ff       	call   f01000a0 <_panic>
f0102bf6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bfb:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102bfe:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c01:	85 d2                	test   %edx,%edx
f0102c03:	74 05                	je     f0102c0a <env_free+0x4b>
f0102c05:	8b 42 48             	mov    0x48(%edx),%eax
f0102c08:	eb 05                	jmp    f0102c0f <env_free+0x50>
f0102c0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c0f:	83 ec 04             	sub    $0x4,%esp
f0102c12:	51                   	push   %ecx
f0102c13:	50                   	push   %eax
f0102c14:	68 47 56 10 f0       	push   $0xf0105647
f0102c19:	e8 8a 02 00 00       	call   f0102ea8 <cprintf>
f0102c1e:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c21:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c28:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c2b:	89 d0                	mov    %edx,%eax
f0102c2d:	c1 e0 02             	shl    $0x2,%eax
f0102c30:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c33:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c36:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c39:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c3f:	0f 84 a8 00 00 00    	je     f0102ced <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c45:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c4b:	89 f0                	mov    %esi,%eax
f0102c4d:	c1 e8 0c             	shr    $0xc,%eax
f0102c50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c53:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102c59:	77 15                	ja     f0102c70 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c5b:	56                   	push   %esi
f0102c5c:	68 ec 4d 10 f0       	push   $0xf0104dec
f0102c61:	68 a9 01 00 00       	push   $0x1a9
f0102c66:	68 27 56 10 f0       	push   $0xf0105627
f0102c6b:	e8 30 d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c70:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c73:	c1 e0 16             	shl    $0x16,%eax
f0102c76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c79:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102c7e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102c85:	01 
f0102c86:	74 17                	je     f0102c9f <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c88:	83 ec 08             	sub    $0x8,%esp
f0102c8b:	89 d8                	mov    %ebx,%eax
f0102c8d:	c1 e0 0c             	shl    $0xc,%eax
f0102c90:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102c93:	50                   	push   %eax
f0102c94:	ff 77 5c             	pushl  0x5c(%edi)
f0102c97:	e8 90 e3 ff ff       	call   f010102c <page_remove>
f0102c9c:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c9f:	83 c3 01             	add    $0x1,%ebx
f0102ca2:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102ca8:	75 d4                	jne    f0102c7e <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102caa:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102cb0:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cb7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102cba:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102cc0:	72 14                	jb     f0102cd6 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102cc2:	83 ec 04             	sub    $0x4,%esp
f0102cc5:	68 70 4f 10 f0       	push   $0xf0104f70
f0102cca:	6a 4f                	push   $0x4f
f0102ccc:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102cd1:	e8 ca d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102cd6:	83 ec 0c             	sub    $0xc,%esp
f0102cd9:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102cde:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ce1:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102ce4:	50                   	push   %eax
f0102ce5:	e8 c4 e1 ff ff       	call   f0100eae <page_decref>
f0102cea:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ced:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102cf1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cf4:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102cf9:	0f 85 29 ff ff ff    	jne    f0102c28 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102cff:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d02:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d07:	77 15                	ja     f0102d1e <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d09:	50                   	push   %eax
f0102d0a:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102d0f:	68 b7 01 00 00       	push   $0x1b7
f0102d14:	68 27 56 10 f0       	push   $0xf0105627
f0102d19:	e8 82 d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d1e:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d25:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d2a:	c1 e8 0c             	shr    $0xc,%eax
f0102d2d:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102d33:	72 14                	jb     f0102d49 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d35:	83 ec 04             	sub    $0x4,%esp
f0102d38:	68 70 4f 10 f0       	push   $0xf0104f70
f0102d3d:	6a 4f                	push   $0x4f
f0102d3f:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102d44:	e8 57 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102d49:	83 ec 0c             	sub    $0xc,%esp
f0102d4c:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102d52:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d55:	50                   	push   %eax
f0102d56:	e8 53 e1 ff ff       	call   f0100eae <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d5b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d62:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
f0102d67:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d6a:	89 3d 4c be 17 f0    	mov    %edi,0xf017be4c
}
f0102d70:	83 c4 10             	add    $0x10,%esp
f0102d73:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d76:	5b                   	pop    %ebx
f0102d77:	5e                   	pop    %esi
f0102d78:	5f                   	pop    %edi
f0102d79:	5d                   	pop    %ebp
f0102d7a:	c3                   	ret    

f0102d7b <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102d7b:	55                   	push   %ebp
f0102d7c:	89 e5                	mov    %esp,%ebp
f0102d7e:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102d81:	ff 75 08             	pushl  0x8(%ebp)
f0102d84:	e8 36 fe ff ff       	call   f0102bbf <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102d89:	c7 04 24 ec 56 10 f0 	movl   $0xf01056ec,(%esp)
f0102d90:	e8 13 01 00 00       	call   f0102ea8 <cprintf>
f0102d95:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102d98:	83 ec 0c             	sub    $0xc,%esp
f0102d9b:	6a 00                	push   $0x0
f0102d9d:	e8 00 da ff ff       	call   f01007a2 <monitor>
f0102da2:	83 c4 10             	add    $0x10,%esp
f0102da5:	eb f1                	jmp    f0102d98 <env_destroy+0x1d>

f0102da7 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102da7:	55                   	push   %ebp
f0102da8:	89 e5                	mov    %esp,%ebp
f0102daa:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102dad:	8b 65 08             	mov    0x8(%ebp),%esp
f0102db0:	61                   	popa   
f0102db1:	07                   	pop    %es
f0102db2:	1f                   	pop    %ds
f0102db3:	83 c4 08             	add    $0x8,%esp
f0102db6:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102db7:	68 5d 56 10 f0       	push   $0xf010565d
f0102dbc:	68 e0 01 00 00       	push   $0x1e0
f0102dc1:	68 27 56 10 f0       	push   $0xf0105627
f0102dc6:	e8 d5 d2 ff ff       	call   f01000a0 <_panic>

f0102dcb <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102dcb:	55                   	push   %ebp
f0102dcc:	89 e5                	mov    %esp,%ebp
f0102dce:	83 ec 08             	sub    $0x8,%esp
f0102dd1:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
if(curenv != e) {
f0102dd4:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102dda:	39 c2                	cmp    %eax,%edx
f0102ddc:	74 48                	je     f0102e26 <env_run+0x5b>
		if(curenv && curenv->env_status 
f0102dde:	85 d2                	test   %edx,%edx
f0102de0:	74 0d                	je     f0102def <env_run+0x24>
f0102de2:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102de6:	75 07                	jne    f0102def <env_run+0x24>
				== ENV_RUNNING) {
			curenv->env_status = ENV_RUNNABLE;
f0102de8:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
		}
		curenv = e;
f0102def:	a3 44 be 17 f0       	mov    %eax,0xf017be44
		curenv->env_status = ENV_RUNNING;
f0102df4:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		curenv->env_runs += 1;
f0102dfb:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f0102dff:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e02:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e07:	77 15                	ja     f0102e1e <env_run+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e09:	50                   	push   %eax
f0102e0a:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0102e0f:	68 06 02 00 00       	push   $0x206
f0102e14:	68 27 56 10 f0       	push   $0xf0105627
f0102e19:	e8 82 d2 ff ff       	call   f01000a0 <_panic>
f0102e1e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e23:	0f 22 d8             	mov    %eax,%cr3
	}
	cprintf("FLAG\n");
f0102e26:	83 ec 0c             	sub    $0xc,%esp
f0102e29:	68 69 56 10 f0       	push   $0xf0105669
f0102e2e:	e8 75 00 00 00       	call   f0102ea8 <cprintf>
	env_pop_tf(&(curenv->env_tf));
f0102e33:	83 c4 04             	add    $0x4,%esp
f0102e36:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0102e3c:	e8 66 ff ff ff       	call   f0102da7 <env_pop_tf>

f0102e41 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e41:	55                   	push   %ebp
f0102e42:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e44:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e49:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e4c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e4d:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e52:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e53:	0f b6 c0             	movzbl %al,%eax
}
f0102e56:	5d                   	pop    %ebp
f0102e57:	c3                   	ret    

f0102e58 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e58:	55                   	push   %ebp
f0102e59:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e5b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e60:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e63:	ee                   	out    %al,(%dx)
f0102e64:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e6c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e6d:	5d                   	pop    %ebp
f0102e6e:	c3                   	ret    

f0102e6f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e6f:	55                   	push   %ebp
f0102e70:	89 e5                	mov    %esp,%ebp
f0102e72:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e75:	ff 75 08             	pushl  0x8(%ebp)
f0102e78:	e8 98 d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102e7d:	83 c4 10             	add    $0x10,%esp
f0102e80:	c9                   	leave  
f0102e81:	c3                   	ret    

f0102e82 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e82:	55                   	push   %ebp
f0102e83:	89 e5                	mov    %esp,%ebp
f0102e85:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e88:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e8f:	ff 75 0c             	pushl  0xc(%ebp)
f0102e92:	ff 75 08             	pushl  0x8(%ebp)
f0102e95:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e98:	50                   	push   %eax
f0102e99:	68 6f 2e 10 f0       	push   $0xf0102e6f
f0102e9e:	e8 51 0b 00 00       	call   f01039f4 <vprintfmt>
	return cnt;
}
f0102ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ea6:	c9                   	leave  
f0102ea7:	c3                   	ret    

f0102ea8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ea8:	55                   	push   %ebp
f0102ea9:	89 e5                	mov    %esp,%ebp
f0102eab:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102eae:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102eb1:	50                   	push   %eax
f0102eb2:	ff 75 08             	pushl  0x8(%ebp)
f0102eb5:	e8 c8 ff ff ff       	call   f0102e82 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102eba:	c9                   	leave  
f0102ebb:	c3                   	ret    

f0102ebc <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102ebc:	55                   	push   %ebp
f0102ebd:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ebf:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102ec4:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102ecb:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102ece:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102ed5:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0102ed7:	66 c7 05 e6 c6 17 f0 	movw   $0x68,0xf017c6e6
f0102ede:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102ee0:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102ee7:	67 00 
f0102ee9:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102eef:	89 c2                	mov    %eax,%edx
f0102ef1:	c1 ea 10             	shr    $0x10,%edx
f0102ef4:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102efa:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f01:	c1 e8 18             	shr    $0x18,%eax
f0102f04:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f09:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f10:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f15:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f18:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f1d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f20:	5d                   	pop    %ebp
f0102f21:	c3                   	ret    

f0102f22 <trap_init>:
}


void
trap_init(void)
{
f0102f22:	55                   	push   %ebp
f0102f23:	89 e5                	mov    %esp,%ebp
	void trap_mchk();
	void trap_simderr();
	

	// SETGATE(gate, istrap, sel, off, dpl)
	SETGATE(idt[T_DIVIDE], 0, GD_KT, trap_divide, 0);
f0102f25:	b8 48 35 10 f0       	mov    $0xf0103548,%eax
f0102f2a:	66 a3 60 be 17 f0    	mov    %ax,0xf017be60
f0102f30:	66 c7 05 62 be 17 f0 	movw   $0x8,0xf017be62
f0102f37:	08 00 
f0102f39:	c6 05 64 be 17 f0 00 	movb   $0x0,0xf017be64
f0102f40:	c6 05 65 be 17 f0 8e 	movb   $0x8e,0xf017be65
f0102f47:	c1 e8 10             	shr    $0x10,%eax
f0102f4a:	66 a3 66 be 17 f0    	mov    %ax,0xf017be66
	SETGATE(idt[T_DEBUG] , 0, GD_KT, trap_debug , 0);
f0102f50:	b8 4e 35 10 f0       	mov    $0xf010354e,%eax
f0102f55:	66 a3 68 be 17 f0    	mov    %ax,0xf017be68
f0102f5b:	66 c7 05 6a be 17 f0 	movw   $0x8,0xf017be6a
f0102f62:	08 00 
f0102f64:	c6 05 6c be 17 f0 00 	movb   $0x0,0xf017be6c
f0102f6b:	c6 05 6d be 17 f0 8e 	movb   $0x8e,0xf017be6d
f0102f72:	c1 e8 10             	shr    $0x10,%eax
f0102f75:	66 a3 6e be 17 f0    	mov    %ax,0xf017be6e
	SETGATE(idt[T_NMI]   , 0, GD_KT, trap_nmi   , 0);
f0102f7b:	b8 54 35 10 f0       	mov    $0xf0103554,%eax
f0102f80:	66 a3 70 be 17 f0    	mov    %ax,0xf017be70
f0102f86:	66 c7 05 72 be 17 f0 	movw   $0x8,0xf017be72
f0102f8d:	08 00 
f0102f8f:	c6 05 74 be 17 f0 00 	movb   $0x0,0xf017be74
f0102f96:	c6 05 75 be 17 f0 8e 	movb   $0x8e,0xf017be75
f0102f9d:	c1 e8 10             	shr    $0x10,%eax
f0102fa0:	66 a3 76 be 17 f0    	mov    %ax,0xf017be76
	SETGATE(idt[T_OFLOW] , 0, GD_KT, trap_oflow , 0);
f0102fa6:	b8 60 35 10 f0       	mov    $0xf0103560,%eax
f0102fab:	66 a3 80 be 17 f0    	mov    %ax,0xf017be80
f0102fb1:	66 c7 05 82 be 17 f0 	movw   $0x8,0xf017be82
f0102fb8:	08 00 
f0102fba:	c6 05 84 be 17 f0 00 	movb   $0x0,0xf017be84
f0102fc1:	c6 05 85 be 17 f0 8e 	movb   $0x8e,0xf017be85
f0102fc8:	c1 e8 10             	shr    $0x10,%eax
f0102fcb:	66 a3 86 be 17 f0    	mov    %ax,0xf017be86
	SETGATE(idt[T_BOUND] , 0, GD_KT, trap_bound , 0);
f0102fd1:	b8 66 35 10 f0       	mov    $0xf0103566,%eax
f0102fd6:	66 a3 88 be 17 f0    	mov    %ax,0xf017be88
f0102fdc:	66 c7 05 8a be 17 f0 	movw   $0x8,0xf017be8a
f0102fe3:	08 00 
f0102fe5:	c6 05 8c be 17 f0 00 	movb   $0x0,0xf017be8c
f0102fec:	c6 05 8d be 17 f0 8e 	movb   $0x8e,0xf017be8d
f0102ff3:	c1 e8 10             	shr    $0x10,%eax
f0102ff6:	66 a3 8e be 17 f0    	mov    %ax,0xf017be8e
	SETGATE(idt[T_ILLOP] , 0, GD_KT, trap_illop , 0);
f0102ffc:	b8 6c 35 10 f0       	mov    $0xf010356c,%eax
f0103001:	66 a3 90 be 17 f0    	mov    %ax,0xf017be90
f0103007:	66 c7 05 92 be 17 f0 	movw   $0x8,0xf017be92
f010300e:	08 00 
f0103010:	c6 05 94 be 17 f0 00 	movb   $0x0,0xf017be94
f0103017:	c6 05 95 be 17 f0 8e 	movb   $0x8e,0xf017be95
f010301e:	c1 e8 10             	shr    $0x10,%eax
f0103021:	66 a3 96 be 17 f0    	mov    %ax,0xf017be96
	SETGATE(idt[T_DEVICE], 0, GD_KT, trap_device, 0);
f0103027:	b8 72 35 10 f0       	mov    $0xf0103572,%eax
f010302c:	66 a3 98 be 17 f0    	mov    %ax,0xf017be98
f0103032:	66 c7 05 9a be 17 f0 	movw   $0x8,0xf017be9a
f0103039:	08 00 
f010303b:	c6 05 9c be 17 f0 00 	movb   $0x0,0xf017be9c
f0103042:	c6 05 9d be 17 f0 8e 	movb   $0x8e,0xf017be9d
f0103049:	c1 e8 10             	shr    $0x10,%eax
f010304c:	66 a3 9e be 17 f0    	mov    %ax,0xf017be9e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, trap_dblflt, 0);
f0103052:	b8 78 35 10 f0       	mov    $0xf0103578,%eax
f0103057:	66 a3 a0 be 17 f0    	mov    %ax,0xf017bea0
f010305d:	66 c7 05 a2 be 17 f0 	movw   $0x8,0xf017bea2
f0103064:	08 00 
f0103066:	c6 05 a4 be 17 f0 00 	movb   $0x0,0xf017bea4
f010306d:	c6 05 a5 be 17 f0 8e 	movb   $0x8e,0xf017bea5
f0103074:	c1 e8 10             	shr    $0x10,%eax
f0103077:	66 a3 a6 be 17 f0    	mov    %ax,0xf017bea6
	SETGATE(idt[T_TSS]   , 0, GD_KT, trap_tss,    0);
f010307d:	b8 7c 35 10 f0       	mov    $0xf010357c,%eax
f0103082:	66 a3 b0 be 17 f0    	mov    %ax,0xf017beb0
f0103088:	66 c7 05 b2 be 17 f0 	movw   $0x8,0xf017beb2
f010308f:	08 00 
f0103091:	c6 05 b4 be 17 f0 00 	movb   $0x0,0xf017beb4
f0103098:	c6 05 b5 be 17 f0 8e 	movb   $0x8e,0xf017beb5
f010309f:	c1 e8 10             	shr    $0x10,%eax
f01030a2:	66 a3 b6 be 17 f0    	mov    %ax,0xf017beb6
	SETGATE(idt[T_SEGNP] , 0, GD_KT, trap_segnp,  0);
f01030a8:	b8 80 35 10 f0       	mov    $0xf0103580,%eax
f01030ad:	66 a3 b8 be 17 f0    	mov    %ax,0xf017beb8
f01030b3:	66 c7 05 ba be 17 f0 	movw   $0x8,0xf017beba
f01030ba:	08 00 
f01030bc:	c6 05 bc be 17 f0 00 	movb   $0x0,0xf017bebc
f01030c3:	c6 05 bd be 17 f0 8e 	movb   $0x8e,0xf017bebd
f01030ca:	c1 e8 10             	shr    $0x10,%eax
f01030cd:	66 a3 be be 17 f0    	mov    %ax,0xf017bebe
	SETGATE(idt[T_STACK] , 0, GD_KT, trap_stack,  0);
f01030d3:	b8 84 35 10 f0       	mov    $0xf0103584,%eax
f01030d8:	66 a3 c0 be 17 f0    	mov    %ax,0xf017bec0
f01030de:	66 c7 05 c2 be 17 f0 	movw   $0x8,0xf017bec2
f01030e5:	08 00 
f01030e7:	c6 05 c4 be 17 f0 00 	movb   $0x0,0xf017bec4
f01030ee:	c6 05 c5 be 17 f0 8e 	movb   $0x8e,0xf017bec5
f01030f5:	c1 e8 10             	shr    $0x10,%eax
f01030f8:	66 a3 c6 be 17 f0    	mov    %ax,0xf017bec6
	SETGATE(idt[T_GPFLT] , 0, GD_KT, trap_gpflt,  0);
f01030fe:	b8 88 35 10 f0       	mov    $0xf0103588,%eax
f0103103:	66 a3 c8 be 17 f0    	mov    %ax,0xf017bec8
f0103109:	66 c7 05 ca be 17 f0 	movw   $0x8,0xf017beca
f0103110:	08 00 
f0103112:	c6 05 cc be 17 f0 00 	movb   $0x0,0xf017becc
f0103119:	c6 05 cd be 17 f0 8e 	movb   $0x8e,0xf017becd
f0103120:	c1 e8 10             	shr    $0x10,%eax
f0103123:	66 a3 ce be 17 f0    	mov    %ax,0xf017bece
	SETGATE(idt[T_PGFLT] , 0, GD_KT, trap_pgflt,  0);
f0103129:	b8 8c 35 10 f0       	mov    $0xf010358c,%eax
f010312e:	66 a3 d0 be 17 f0    	mov    %ax,0xf017bed0
f0103134:	66 c7 05 d2 be 17 f0 	movw   $0x8,0xf017bed2
f010313b:	08 00 
f010313d:	c6 05 d4 be 17 f0 00 	movb   $0x0,0xf017bed4
f0103144:	c6 05 d5 be 17 f0 8e 	movb   $0x8e,0xf017bed5
f010314b:	c1 e8 10             	shr    $0x10,%eax
f010314e:	66 a3 d6 be 17 f0    	mov    %ax,0xf017bed6
	SETGATE(idt[T_FPERR] , 0, GD_KT, trap_fperr,  0);
f0103154:	b8 90 35 10 f0       	mov    $0xf0103590,%eax
f0103159:	66 a3 e0 be 17 f0    	mov    %ax,0xf017bee0
f010315f:	66 c7 05 e2 be 17 f0 	movw   $0x8,0xf017bee2
f0103166:	08 00 
f0103168:	c6 05 e4 be 17 f0 00 	movb   $0x0,0xf017bee4
f010316f:	c6 05 e5 be 17 f0 8e 	movb   $0x8e,0xf017bee5
f0103176:	c1 e8 10             	shr    $0x10,%eax
f0103179:	66 a3 e6 be 17 f0    	mov    %ax,0xf017bee6
	SETGATE(idt[T_ALIGN] , 0, GD_KT, trap_align,  0);
f010317f:	b8 96 35 10 f0       	mov    $0xf0103596,%eax
f0103184:	66 a3 e8 be 17 f0    	mov    %ax,0xf017bee8
f010318a:	66 c7 05 ea be 17 f0 	movw   $0x8,0xf017beea
f0103191:	08 00 
f0103193:	c6 05 ec be 17 f0 00 	movb   $0x0,0xf017beec
f010319a:	c6 05 ed be 17 f0 8e 	movb   $0x8e,0xf017beed
f01031a1:	c1 e8 10             	shr    $0x10,%eax
f01031a4:	66 a3 ee be 17 f0    	mov    %ax,0xf017beee
	SETGATE(idt[T_MCHK]  , 0, GD_KT, trap_mchk ,  0);
f01031aa:	b8 9a 35 10 f0       	mov    $0xf010359a,%eax
f01031af:	66 a3 f0 be 17 f0    	mov    %ax,0xf017bef0
f01031b5:	66 c7 05 f2 be 17 f0 	movw   $0x8,0xf017bef2
f01031bc:	08 00 
f01031be:	c6 05 f4 be 17 f0 00 	movb   $0x0,0xf017bef4
f01031c5:	c6 05 f5 be 17 f0 8e 	movb   $0x8e,0xf017bef5
f01031cc:	c1 e8 10             	shr    $0x10,%eax
f01031cf:	66 a3 f6 be 17 f0    	mov    %ax,0xf017bef6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, trap_simderr, 0); 
f01031d5:	b8 a0 35 10 f0       	mov    $0xf01035a0,%eax
f01031da:	66 a3 f8 be 17 f0    	mov    %ax,0xf017bef8
f01031e0:	66 c7 05 fa be 17 f0 	movw   $0x8,0xf017befa
f01031e7:	08 00 
f01031e9:	c6 05 fc be 17 f0 00 	movb   $0x0,0xf017befc
f01031f0:	c6 05 fd be 17 f0 8e 	movb   $0x8e,0xf017befd
f01031f7:	c1 e8 10             	shr    $0x10,%eax
f01031fa:	66 a3 fe be 17 f0    	mov    %ax,0xf017befe

	// Per-CPU setup 
	trap_init_percpu();
f0103200:	e8 b7 fc ff ff       	call   f0102ebc <trap_init_percpu>
}
f0103205:	5d                   	pop    %ebp
f0103206:	c3                   	ret    

f0103207 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103207:	55                   	push   %ebp
f0103208:	89 e5                	mov    %esp,%ebp
f010320a:	53                   	push   %ebx
f010320b:	83 ec 0c             	sub    $0xc,%esp
f010320e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103211:	ff 33                	pushl  (%ebx)
f0103213:	68 22 57 10 f0       	push   $0xf0105722
f0103218:	e8 8b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010321d:	83 c4 08             	add    $0x8,%esp
f0103220:	ff 73 04             	pushl  0x4(%ebx)
f0103223:	68 31 57 10 f0       	push   $0xf0105731
f0103228:	e8 7b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010322d:	83 c4 08             	add    $0x8,%esp
f0103230:	ff 73 08             	pushl  0x8(%ebx)
f0103233:	68 40 57 10 f0       	push   $0xf0105740
f0103238:	e8 6b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010323d:	83 c4 08             	add    $0x8,%esp
f0103240:	ff 73 0c             	pushl  0xc(%ebx)
f0103243:	68 4f 57 10 f0       	push   $0xf010574f
f0103248:	e8 5b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010324d:	83 c4 08             	add    $0x8,%esp
f0103250:	ff 73 10             	pushl  0x10(%ebx)
f0103253:	68 5e 57 10 f0       	push   $0xf010575e
f0103258:	e8 4b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010325d:	83 c4 08             	add    $0x8,%esp
f0103260:	ff 73 14             	pushl  0x14(%ebx)
f0103263:	68 6d 57 10 f0       	push   $0xf010576d
f0103268:	e8 3b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010326d:	83 c4 08             	add    $0x8,%esp
f0103270:	ff 73 18             	pushl  0x18(%ebx)
f0103273:	68 7c 57 10 f0       	push   $0xf010577c
f0103278:	e8 2b fc ff ff       	call   f0102ea8 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010327d:	83 c4 08             	add    $0x8,%esp
f0103280:	ff 73 1c             	pushl  0x1c(%ebx)
f0103283:	68 8b 57 10 f0       	push   $0xf010578b
f0103288:	e8 1b fc ff ff       	call   f0102ea8 <cprintf>
}
f010328d:	83 c4 10             	add    $0x10,%esp
f0103290:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103293:	c9                   	leave  
f0103294:	c3                   	ret    

f0103295 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103295:	55                   	push   %ebp
f0103296:	89 e5                	mov    %esp,%ebp
f0103298:	56                   	push   %esi
f0103299:	53                   	push   %ebx
f010329a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010329d:	83 ec 08             	sub    $0x8,%esp
f01032a0:	53                   	push   %ebx
f01032a1:	68 c1 58 10 f0       	push   $0xf01058c1
f01032a6:	e8 fd fb ff ff       	call   f0102ea8 <cprintf>
	print_regs(&tf->tf_regs);
f01032ab:	89 1c 24             	mov    %ebx,(%esp)
f01032ae:	e8 54 ff ff ff       	call   f0103207 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01032b3:	83 c4 08             	add    $0x8,%esp
f01032b6:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01032ba:	50                   	push   %eax
f01032bb:	68 dc 57 10 f0       	push   $0xf01057dc
f01032c0:	e8 e3 fb ff ff       	call   f0102ea8 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032c5:	83 c4 08             	add    $0x8,%esp
f01032c8:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01032cc:	50                   	push   %eax
f01032cd:	68 ef 57 10 f0       	push   $0xf01057ef
f01032d2:	e8 d1 fb ff ff       	call   f0102ea8 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032d7:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01032da:	83 c4 10             	add    $0x10,%esp
f01032dd:	83 f8 13             	cmp    $0x13,%eax
f01032e0:	77 09                	ja     f01032eb <print_trapframe+0x56>
		return excnames[trapno];
f01032e2:	8b 14 85 a0 5a 10 f0 	mov    -0xfefa560(,%eax,4),%edx
f01032e9:	eb 10                	jmp    f01032fb <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01032eb:	83 f8 30             	cmp    $0x30,%eax
f01032ee:	b9 a6 57 10 f0       	mov    $0xf01057a6,%ecx
f01032f3:	ba 9a 57 10 f0       	mov    $0xf010579a,%edx
f01032f8:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032fb:	83 ec 04             	sub    $0x4,%esp
f01032fe:	52                   	push   %edx
f01032ff:	50                   	push   %eax
f0103300:	68 02 58 10 f0       	push   $0xf0105802
f0103305:	e8 9e fb ff ff       	call   f0102ea8 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010330a:	83 c4 10             	add    $0x10,%esp
f010330d:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0103313:	75 1a                	jne    f010332f <print_trapframe+0x9a>
f0103315:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103319:	75 14                	jne    f010332f <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010331b:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010331e:	83 ec 08             	sub    $0x8,%esp
f0103321:	50                   	push   %eax
f0103322:	68 14 58 10 f0       	push   $0xf0105814
f0103327:	e8 7c fb ff ff       	call   f0102ea8 <cprintf>
f010332c:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010332f:	83 ec 08             	sub    $0x8,%esp
f0103332:	ff 73 2c             	pushl  0x2c(%ebx)
f0103335:	68 23 58 10 f0       	push   $0xf0105823
f010333a:	e8 69 fb ff ff       	call   f0102ea8 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010333f:	83 c4 10             	add    $0x10,%esp
f0103342:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103346:	75 49                	jne    f0103391 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103348:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010334b:	89 c2                	mov    %eax,%edx
f010334d:	83 e2 01             	and    $0x1,%edx
f0103350:	ba c0 57 10 f0       	mov    $0xf01057c0,%edx
f0103355:	b9 b5 57 10 f0       	mov    $0xf01057b5,%ecx
f010335a:	0f 44 ca             	cmove  %edx,%ecx
f010335d:	89 c2                	mov    %eax,%edx
f010335f:	83 e2 02             	and    $0x2,%edx
f0103362:	ba d2 57 10 f0       	mov    $0xf01057d2,%edx
f0103367:	be cc 57 10 f0       	mov    $0xf01057cc,%esi
f010336c:	0f 45 d6             	cmovne %esi,%edx
f010336f:	83 e0 04             	and    $0x4,%eax
f0103372:	be ec 58 10 f0       	mov    $0xf01058ec,%esi
f0103377:	b8 d7 57 10 f0       	mov    $0xf01057d7,%eax
f010337c:	0f 44 c6             	cmove  %esi,%eax
f010337f:	51                   	push   %ecx
f0103380:	52                   	push   %edx
f0103381:	50                   	push   %eax
f0103382:	68 31 58 10 f0       	push   $0xf0105831
f0103387:	e8 1c fb ff ff       	call   f0102ea8 <cprintf>
f010338c:	83 c4 10             	add    $0x10,%esp
f010338f:	eb 10                	jmp    f01033a1 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103391:	83 ec 0c             	sub    $0xc,%esp
f0103394:	68 95 4d 10 f0       	push   $0xf0104d95
f0103399:	e8 0a fb ff ff       	call   f0102ea8 <cprintf>
f010339e:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01033a1:	83 ec 08             	sub    $0x8,%esp
f01033a4:	ff 73 30             	pushl  0x30(%ebx)
f01033a7:	68 40 58 10 f0       	push   $0xf0105840
f01033ac:	e8 f7 fa ff ff       	call   f0102ea8 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01033b1:	83 c4 08             	add    $0x8,%esp
f01033b4:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01033b8:	50                   	push   %eax
f01033b9:	68 4f 58 10 f0       	push   $0xf010584f
f01033be:	e8 e5 fa ff ff       	call   f0102ea8 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01033c3:	83 c4 08             	add    $0x8,%esp
f01033c6:	ff 73 38             	pushl  0x38(%ebx)
f01033c9:	68 62 58 10 f0       	push   $0xf0105862
f01033ce:	e8 d5 fa ff ff       	call   f0102ea8 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01033d3:	83 c4 10             	add    $0x10,%esp
f01033d6:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01033da:	74 25                	je     f0103401 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01033dc:	83 ec 08             	sub    $0x8,%esp
f01033df:	ff 73 3c             	pushl  0x3c(%ebx)
f01033e2:	68 71 58 10 f0       	push   $0xf0105871
f01033e7:	e8 bc fa ff ff       	call   f0102ea8 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01033ec:	83 c4 08             	add    $0x8,%esp
f01033ef:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01033f3:	50                   	push   %eax
f01033f4:	68 80 58 10 f0       	push   $0xf0105880
f01033f9:	e8 aa fa ff ff       	call   f0102ea8 <cprintf>
f01033fe:	83 c4 10             	add    $0x10,%esp
	}
}
f0103401:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103404:	5b                   	pop    %ebx
f0103405:	5e                   	pop    %esi
f0103406:	5d                   	pop    %ebp
f0103407:	c3                   	ret    

f0103408 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103408:	55                   	push   %ebp
f0103409:	89 e5                	mov    %esp,%ebp
f010340b:	53                   	push   %ebx
f010340c:	83 ec 04             	sub    $0x4,%esp
f010340f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103412:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103415:	ff 73 30             	pushl  0x30(%ebx)
f0103418:	50                   	push   %eax
f0103419:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010341e:	ff 70 48             	pushl  0x48(%eax)
f0103421:	68 38 5a 10 f0       	push   $0xf0105a38
f0103426:	e8 7d fa ff ff       	call   f0102ea8 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010342b:	89 1c 24             	mov    %ebx,(%esp)
f010342e:	e8 62 fe ff ff       	call   f0103295 <print_trapframe>
	env_destroy(curenv);
f0103433:	83 c4 04             	add    $0x4,%esp
f0103436:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010343c:	e8 3a f9 ff ff       	call   f0102d7b <env_destroy>
}
f0103441:	83 c4 10             	add    $0x10,%esp
f0103444:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103447:	c9                   	leave  
f0103448:	c3                   	ret    

f0103449 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103449:	55                   	push   %ebp
f010344a:	89 e5                	mov    %esp,%ebp
f010344c:	57                   	push   %edi
f010344d:	56                   	push   %esi
f010344e:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103451:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103452:	9c                   	pushf  
f0103453:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103454:	f6 c4 02             	test   $0x2,%ah
f0103457:	74 19                	je     f0103472 <trap+0x29>
f0103459:	68 93 58 10 f0       	push   $0xf0105893
f010345e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0103463:	68 d2 00 00 00       	push   $0xd2
f0103468:	68 ac 58 10 f0       	push   $0xf01058ac
f010346d:	e8 2e cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103472:	83 ec 08             	sub    $0x8,%esp
f0103475:	56                   	push   %esi
f0103476:	68 b8 58 10 f0       	push   $0xf01058b8
f010347b:	e8 28 fa ff ff       	call   f0102ea8 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103480:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103484:	83 e0 03             	and    $0x3,%eax
f0103487:	83 c4 10             	add    $0x10,%esp
f010348a:	66 83 f8 03          	cmp    $0x3,%ax
f010348e:	75 31                	jne    f01034c1 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103490:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103495:	85 c0                	test   %eax,%eax
f0103497:	75 19                	jne    f01034b2 <trap+0x69>
f0103499:	68 d3 58 10 f0       	push   $0xf01058d3
f010349e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f01034a3:	68 d8 00 00 00       	push   $0xd8
f01034a8:	68 ac 58 10 f0       	push   $0xf01058ac
f01034ad:	e8 ee cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01034b2:	b9 11 00 00 00       	mov    $0x11,%ecx
f01034b7:	89 c7                	mov    %eax,%edi
f01034b9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01034bb:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01034c1:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) {
f01034c7:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01034cb:	75 0e                	jne    f01034db <trap+0x92>
		page_fault_handler(tf);
f01034cd:	83 ec 0c             	sub    $0xc,%esp
f01034d0:	56                   	push   %esi
f01034d1:	e8 32 ff ff ff       	call   f0103408 <page_fault_handler>
f01034d6:	83 c4 10             	add    $0x10,%esp
f01034d9:	eb 3b                	jmp    f0103516 <trap+0xcd>
		return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01034db:	83 ec 0c             	sub    $0xc,%esp
f01034de:	56                   	push   %esi
f01034df:	e8 b1 fd ff ff       	call   f0103295 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01034e4:	83 c4 10             	add    $0x10,%esp
f01034e7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01034ec:	75 17                	jne    f0103505 <trap+0xbc>
		panic("unhandled trap in kernel");
f01034ee:	83 ec 04             	sub    $0x4,%esp
f01034f1:	68 da 58 10 f0       	push   $0xf01058da
f01034f6:	68 c1 00 00 00       	push   $0xc1
f01034fb:	68 ac 58 10 f0       	push   $0xf01058ac
f0103500:	e8 9b cb ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103505:	83 ec 0c             	sub    $0xc,%esp
f0103508:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010350e:	e8 68 f8 ff ff       	call   f0102d7b <env_destroy>
f0103513:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103516:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010351b:	85 c0                	test   %eax,%eax
f010351d:	74 06                	je     f0103525 <trap+0xdc>
f010351f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103523:	74 19                	je     f010353e <trap+0xf5>
f0103525:	68 5c 5a 10 f0       	push   $0xf0105a5c
f010352a:	68 0a 4b 10 f0       	push   $0xf0104b0a
f010352f:	68 ea 00 00 00       	push   $0xea
f0103534:	68 ac 58 10 f0       	push   $0xf01058ac
f0103539:	e8 62 cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010353e:	83 ec 0c             	sub    $0xc,%esp
f0103541:	50                   	push   %eax
f0103542:	e8 84 f8 ff ff       	call   f0102dcb <env_run>
f0103547:	90                   	nop

f0103548 <trap_divide>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	
	TRAPHANDLER_NOEC(trap_divide, T_DIVIDE)
f0103548:	6a 00                	push   $0x0
f010354a:	6a 00                	push   $0x0
f010354c:	eb 58                	jmp    f01035a6 <_alltraps>

f010354e <trap_debug>:
	TRAPHANDLER_NOEC(trap_debug, T_DEBUG)
f010354e:	6a 00                	push   $0x0
f0103550:	6a 01                	push   $0x1
f0103552:	eb 52                	jmp    f01035a6 <_alltraps>

f0103554 <trap_nmi>:
	TRAPHANDLER_NOEC(trap_nmi, T_NMI)
f0103554:	6a 00                	push   $0x0
f0103556:	6a 02                	push   $0x2
f0103558:	eb 4c                	jmp    f01035a6 <_alltraps>

f010355a <trap_brkpt>:
	TRAPHANDLER_NOEC(trap_brkpt, T_BRKPT)
f010355a:	6a 00                	push   $0x0
f010355c:	6a 03                	push   $0x3
f010355e:	eb 46                	jmp    f01035a6 <_alltraps>

f0103560 <trap_oflow>:
	TRAPHANDLER_NOEC(trap_oflow, T_OFLOW)
f0103560:	6a 00                	push   $0x0
f0103562:	6a 04                	push   $0x4
f0103564:	eb 40                	jmp    f01035a6 <_alltraps>

f0103566 <trap_bound>:
	TRAPHANDLER_NOEC(trap_bound, T_BOUND)
f0103566:	6a 00                	push   $0x0
f0103568:	6a 05                	push   $0x5
f010356a:	eb 3a                	jmp    f01035a6 <_alltraps>

f010356c <trap_illop>:
	TRAPHANDLER_NOEC(trap_illop, T_ILLOP)
f010356c:	6a 00                	push   $0x0
f010356e:	6a 06                	push   $0x6
f0103570:	eb 34                	jmp    f01035a6 <_alltraps>

f0103572 <trap_device>:
	TRAPHANDLER_NOEC(trap_device, T_DEVICE)
f0103572:	6a 00                	push   $0x0
f0103574:	6a 07                	push   $0x7
f0103576:	eb 2e                	jmp    f01035a6 <_alltraps>

f0103578 <trap_dblflt>:
	TRAPHANDLER(trap_dblflt, T_DBLFLT)
f0103578:	6a 08                	push   $0x8
f010357a:	eb 2a                	jmp    f01035a6 <_alltraps>

f010357c <trap_tss>:
	TRAPHANDLER(trap_tss, T_TSS)
f010357c:	6a 0a                	push   $0xa
f010357e:	eb 26                	jmp    f01035a6 <_alltraps>

f0103580 <trap_segnp>:
	TRAPHANDLER(trap_segnp, T_SEGNP)
f0103580:	6a 0b                	push   $0xb
f0103582:	eb 22                	jmp    f01035a6 <_alltraps>

f0103584 <trap_stack>:
	TRAPHANDLER(trap_stack, T_STACK)
f0103584:	6a 0c                	push   $0xc
f0103586:	eb 1e                	jmp    f01035a6 <_alltraps>

f0103588 <trap_gpflt>:
	TRAPHANDLER(trap_gpflt, T_GPFLT)
f0103588:	6a 0d                	push   $0xd
f010358a:	eb 1a                	jmp    f01035a6 <_alltraps>

f010358c <trap_pgflt>:
	TRAPHANDLER(trap_pgflt, T_PGFLT)
f010358c:	6a 0e                	push   $0xe
f010358e:	eb 16                	jmp    f01035a6 <_alltraps>

f0103590 <trap_fperr>:
	TRAPHANDLER_NOEC(trap_fperr, T_FPERR)
f0103590:	6a 00                	push   $0x0
f0103592:	6a 10                	push   $0x10
f0103594:	eb 10                	jmp    f01035a6 <_alltraps>

f0103596 <trap_align>:
	TRAPHANDLER(trap_align, T_ALIGN)
f0103596:	6a 11                	push   $0x11
f0103598:	eb 0c                	jmp    f01035a6 <_alltraps>

f010359a <trap_mchk>:
	TRAPHANDLER_NOEC(trap_mchk, T_MCHK)
f010359a:	6a 00                	push   $0x0
f010359c:	6a 12                	push   $0x12
f010359e:	eb 06                	jmp    f01035a6 <_alltraps>

f01035a0 <trap_simderr>:
	TRAPHANDLER_NOEC(trap_simderr, T_SIMDERR)
f01035a0:	6a 00                	push   $0x0
f01035a2:	6a 13                	push   $0x13
f01035a4:	eb 00                	jmp    f01035a6 <_alltraps>

f01035a6 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f01035a6:	1e                   	push   %ds
	pushl %es
f01035a7:	06                   	push   %es
	pushal
f01035a8:	60                   	pusha  
	pushl $GD_KD
f01035a9:	6a 10                	push   $0x10
	popl %ds
f01035ab:	1f                   	pop    %ds
	pushl $GD_KD
f01035ac:	6a 10                	push   $0x10
	popl %es
f01035ae:	07                   	pop    %es
	pushl %esp
f01035af:	54                   	push   %esp
	call trap
f01035b0:	e8 94 fe ff ff       	call   f0103449 <trap>

f01035b5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01035b5:	55                   	push   %ebp
f01035b6:	89 e5                	mov    %esp,%ebp
f01035b8:	83 ec 0c             	sub    $0xc,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f01035bb:	68 f0 5a 10 f0       	push   $0xf0105af0
f01035c0:	6a 49                	push   $0x49
f01035c2:	68 08 5b 10 f0       	push   $0xf0105b08
f01035c7:	e8 d4 ca ff ff       	call   f01000a0 <_panic>

f01035cc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01035cc:	55                   	push   %ebp
f01035cd:	89 e5                	mov    %esp,%ebp
f01035cf:	57                   	push   %edi
f01035d0:	56                   	push   %esi
f01035d1:	53                   	push   %ebx
f01035d2:	83 ec 14             	sub    $0x14,%esp
f01035d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01035d8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01035db:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01035de:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01035e1:	8b 1a                	mov    (%edx),%ebx
f01035e3:	8b 01                	mov    (%ecx),%eax
f01035e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035e8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01035ef:	eb 7f                	jmp    f0103670 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01035f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035f4:	01 d8                	add    %ebx,%eax
f01035f6:	89 c6                	mov    %eax,%esi
f01035f8:	c1 ee 1f             	shr    $0x1f,%esi
f01035fb:	01 c6                	add    %eax,%esi
f01035fd:	d1 fe                	sar    %esi
f01035ff:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103602:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103605:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103608:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010360a:	eb 03                	jmp    f010360f <stab_binsearch+0x43>
			m--;
f010360c:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010360f:	39 c3                	cmp    %eax,%ebx
f0103611:	7f 0d                	jg     f0103620 <stab_binsearch+0x54>
f0103613:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103617:	83 ea 0c             	sub    $0xc,%edx
f010361a:	39 f9                	cmp    %edi,%ecx
f010361c:	75 ee                	jne    f010360c <stab_binsearch+0x40>
f010361e:	eb 05                	jmp    f0103625 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103620:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103623:	eb 4b                	jmp    f0103670 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103625:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103628:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010362b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010362f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103632:	76 11                	jbe    f0103645 <stab_binsearch+0x79>
			*region_left = m;
f0103634:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103637:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103639:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010363c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103643:	eb 2b                	jmp    f0103670 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103645:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103648:	73 14                	jae    f010365e <stab_binsearch+0x92>
			*region_right = m - 1;
f010364a:	83 e8 01             	sub    $0x1,%eax
f010364d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103650:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103653:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103655:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010365c:	eb 12                	jmp    f0103670 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010365e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103661:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103663:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103667:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103669:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103670:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103673:	0f 8e 78 ff ff ff    	jle    f01035f1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103679:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010367d:	75 0f                	jne    f010368e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010367f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103682:	8b 00                	mov    (%eax),%eax
f0103684:	83 e8 01             	sub    $0x1,%eax
f0103687:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010368a:	89 06                	mov    %eax,(%esi)
f010368c:	eb 2c                	jmp    f01036ba <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010368e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103691:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103693:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103696:	8b 0e                	mov    (%esi),%ecx
f0103698:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010369b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010369e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01036a1:	eb 03                	jmp    f01036a6 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01036a3:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01036a6:	39 c8                	cmp    %ecx,%eax
f01036a8:	7e 0b                	jle    f01036b5 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01036aa:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01036ae:	83 ea 0c             	sub    $0xc,%edx
f01036b1:	39 df                	cmp    %ebx,%edi
f01036b3:	75 ee                	jne    f01036a3 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01036b5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01036b8:	89 06                	mov    %eax,(%esi)
	}
}
f01036ba:	83 c4 14             	add    $0x14,%esp
f01036bd:	5b                   	pop    %ebx
f01036be:	5e                   	pop    %esi
f01036bf:	5f                   	pop    %edi
f01036c0:	5d                   	pop    %ebp
f01036c1:	c3                   	ret    

f01036c2 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01036c2:	55                   	push   %ebp
f01036c3:	89 e5                	mov    %esp,%ebp
f01036c5:	57                   	push   %edi
f01036c6:	56                   	push   %esi
f01036c7:	53                   	push   %ebx
f01036c8:	83 ec 3c             	sub    $0x3c,%esp
f01036cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01036ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01036d1:	c7 03 17 5b 10 f0    	movl   $0xf0105b17,(%ebx)
	info->eip_line = 0;
f01036d7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01036de:	c7 43 08 17 5b 10 f0 	movl   $0xf0105b17,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01036e5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036ec:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036ef:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036f6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036fc:	77 21                	ja     f010371f <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01036fe:	a1 00 00 20 00       	mov    0x200000,%eax
f0103703:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0103706:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010370b:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103711:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103714:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f010371a:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010371d:	eb 1a                	jmp    f0103739 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010371f:	c7 45 c0 1c fd 10 f0 	movl   $0xf010fd1c,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103726:	c7 45 b8 5d d3 10 f0 	movl   $0xf010d35d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010372d:	b8 5c d3 10 f0       	mov    $0xf010d35c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103732:	c7 45 bc 30 5d 10 f0 	movl   $0xf0105d30,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103739:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010373c:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f010373f:	0f 83 9d 01 00 00    	jae    f01038e2 <debuginfo_eip+0x220>
f0103745:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103749:	0f 85 9a 01 00 00    	jne    f01038e9 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010374f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103756:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103759:	29 f8                	sub    %edi,%eax
f010375b:	c1 f8 02             	sar    $0x2,%eax
f010375e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103764:	83 e8 01             	sub    $0x1,%eax
f0103767:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010376a:	56                   	push   %esi
f010376b:	6a 64                	push   $0x64
f010376d:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103770:	89 c1                	mov    %eax,%ecx
f0103772:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103775:	89 f8                	mov    %edi,%eax
f0103777:	e8 50 fe ff ff       	call   f01035cc <stab_binsearch>
	if (lfile == 0)
f010377c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010377f:	83 c4 08             	add    $0x8,%esp
f0103782:	85 c0                	test   %eax,%eax
f0103784:	0f 84 66 01 00 00    	je     f01038f0 <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010378a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010378d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103790:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103793:	56                   	push   %esi
f0103794:	6a 24                	push   $0x24
f0103796:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103799:	89 c1                	mov    %eax,%ecx
f010379b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010379e:	89 f8                	mov    %edi,%eax
f01037a0:	e8 27 fe ff ff       	call   f01035cc <stab_binsearch>

	if (lfun <= rfun) {
f01037a5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01037a8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037ab:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01037ae:	83 c4 08             	add    $0x8,%esp
f01037b1:	39 d0                	cmp    %edx,%eax
f01037b3:	7f 2b                	jg     f01037e0 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01037b5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037b8:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f01037bb:	8b 11                	mov    (%ecx),%edx
f01037bd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01037c0:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01037c3:	39 fa                	cmp    %edi,%edx
f01037c5:	73 06                	jae    f01037cd <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01037c7:	03 55 b8             	add    -0x48(%ebp),%edx
f01037ca:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01037cd:	8b 51 08             	mov    0x8(%ecx),%edx
f01037d0:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01037d3:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01037d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01037d8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01037db:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01037de:	eb 0f                	jmp    f01037ef <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01037e0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01037e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037e6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01037e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037ef:	83 ec 08             	sub    $0x8,%esp
f01037f2:	6a 3a                	push   $0x3a
f01037f4:	ff 73 08             	pushl  0x8(%ebx)
f01037f7:	e8 01 09 00 00       	call   f01040fd <strfind>
f01037fc:	2b 43 08             	sub    0x8(%ebx),%eax
f01037ff:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103802:	83 c4 08             	add    $0x8,%esp
f0103805:	56                   	push   %esi
f0103806:	6a 44                	push   $0x44
f0103808:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010380b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010380e:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103811:	89 f0                	mov    %esi,%eax
f0103813:	e8 b4 fd ff ff       	call   f01035cc <stab_binsearch>
        if(lline > rline)
f0103818:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010381b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010381e:	83 c4 10             	add    $0x10,%esp
f0103821:	39 c2                	cmp    %eax,%edx
f0103823:	0f 8f ce 00 00 00    	jg     f01038f7 <debuginfo_eip+0x235>
        return -1;
	info->eip_line = stabs[rline].n_desc;
f0103829:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010382c:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103831:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103834:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103837:	89 d0                	mov    %edx,%eax
f0103839:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010383c:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010383f:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103843:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103846:	eb 0a                	jmp    f0103852 <debuginfo_eip+0x190>
f0103848:	83 e8 01             	sub    $0x1,%eax
f010384b:	83 ea 0c             	sub    $0xc,%edx
f010384e:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103852:	39 c7                	cmp    %eax,%edi
f0103854:	7e 05                	jle    f010385b <debuginfo_eip+0x199>
f0103856:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103859:	eb 47                	jmp    f01038a2 <debuginfo_eip+0x1e0>
	       && stabs[lline].n_type != N_SOL
f010385b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010385f:	80 f9 84             	cmp    $0x84,%cl
f0103862:	75 0e                	jne    f0103872 <debuginfo_eip+0x1b0>
f0103864:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103867:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010386b:	74 1c                	je     f0103889 <debuginfo_eip+0x1c7>
f010386d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103870:	eb 17                	jmp    f0103889 <debuginfo_eip+0x1c7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103872:	80 f9 64             	cmp    $0x64,%cl
f0103875:	75 d1                	jne    f0103848 <debuginfo_eip+0x186>
f0103877:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010387b:	74 cb                	je     f0103848 <debuginfo_eip+0x186>
f010387d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103880:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103884:	74 03                	je     f0103889 <debuginfo_eip+0x1c7>
f0103886:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103889:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010388c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010388f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103892:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103895:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103898:	29 f8                	sub    %edi,%eax
f010389a:	39 c2                	cmp    %eax,%edx
f010389c:	73 04                	jae    f01038a2 <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010389e:	01 fa                	add    %edi,%edx
f01038a0:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01038a2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01038a5:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038a8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01038ad:	39 f2                	cmp    %esi,%edx
f01038af:	7d 52                	jge    f0103903 <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f01038b1:	83 c2 01             	add    $0x1,%edx
f01038b4:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01038b7:	89 d0                	mov    %edx,%eax
f01038b9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01038bc:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01038bf:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01038c2:	eb 04                	jmp    f01038c8 <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01038c4:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01038c8:	39 c6                	cmp    %eax,%esi
f01038ca:	7e 32                	jle    f01038fe <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038cc:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01038d0:	83 c0 01             	add    $0x1,%eax
f01038d3:	83 c2 0c             	add    $0xc,%edx
f01038d6:	80 f9 a0             	cmp    $0xa0,%cl
f01038d9:	74 e9                	je     f01038c4 <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038db:	b8 00 00 00 00       	mov    $0x0,%eax
f01038e0:	eb 21                	jmp    f0103903 <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01038e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038e7:	eb 1a                	jmp    f0103903 <debuginfo_eip+0x241>
f01038e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038ee:	eb 13                	jmp    f0103903 <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01038f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038f5:	eb 0c                	jmp    f0103903 <debuginfo_eip+0x241>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
        if(lline > rline)
        return -1;
f01038f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038fc:	eb 05                	jmp    f0103903 <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103903:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103906:	5b                   	pop    %ebx
f0103907:	5e                   	pop    %esi
f0103908:	5f                   	pop    %edi
f0103909:	5d                   	pop    %ebp
f010390a:	c3                   	ret    

f010390b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010390b:	55                   	push   %ebp
f010390c:	89 e5                	mov    %esp,%ebp
f010390e:	57                   	push   %edi
f010390f:	56                   	push   %esi
f0103910:	53                   	push   %ebx
f0103911:	83 ec 1c             	sub    $0x1c,%esp
f0103914:	89 c7                	mov    %eax,%edi
f0103916:	89 d6                	mov    %edx,%esi
f0103918:	8b 45 08             	mov    0x8(%ebp),%eax
f010391b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010391e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103921:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103924:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103927:	bb 00 00 00 00       	mov    $0x0,%ebx
f010392c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010392f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103932:	39 d3                	cmp    %edx,%ebx
f0103934:	72 05                	jb     f010393b <printnum+0x30>
f0103936:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103939:	77 45                	ja     f0103980 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010393b:	83 ec 0c             	sub    $0xc,%esp
f010393e:	ff 75 18             	pushl  0x18(%ebp)
f0103941:	8b 45 14             	mov    0x14(%ebp),%eax
f0103944:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103947:	53                   	push   %ebx
f0103948:	ff 75 10             	pushl  0x10(%ebp)
f010394b:	83 ec 08             	sub    $0x8,%esp
f010394e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103951:	ff 75 e0             	pushl  -0x20(%ebp)
f0103954:	ff 75 dc             	pushl  -0x24(%ebp)
f0103957:	ff 75 d8             	pushl  -0x28(%ebp)
f010395a:	e8 c1 09 00 00       	call   f0104320 <__udivdi3>
f010395f:	83 c4 18             	add    $0x18,%esp
f0103962:	52                   	push   %edx
f0103963:	50                   	push   %eax
f0103964:	89 f2                	mov    %esi,%edx
f0103966:	89 f8                	mov    %edi,%eax
f0103968:	e8 9e ff ff ff       	call   f010390b <printnum>
f010396d:	83 c4 20             	add    $0x20,%esp
f0103970:	eb 18                	jmp    f010398a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103972:	83 ec 08             	sub    $0x8,%esp
f0103975:	56                   	push   %esi
f0103976:	ff 75 18             	pushl  0x18(%ebp)
f0103979:	ff d7                	call   *%edi
f010397b:	83 c4 10             	add    $0x10,%esp
f010397e:	eb 03                	jmp    f0103983 <printnum+0x78>
f0103980:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103983:	83 eb 01             	sub    $0x1,%ebx
f0103986:	85 db                	test   %ebx,%ebx
f0103988:	7f e8                	jg     f0103972 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010398a:	83 ec 08             	sub    $0x8,%esp
f010398d:	56                   	push   %esi
f010398e:	83 ec 04             	sub    $0x4,%esp
f0103991:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103994:	ff 75 e0             	pushl  -0x20(%ebp)
f0103997:	ff 75 dc             	pushl  -0x24(%ebp)
f010399a:	ff 75 d8             	pushl  -0x28(%ebp)
f010399d:	e8 ae 0a 00 00       	call   f0104450 <__umoddi3>
f01039a2:	83 c4 14             	add    $0x14,%esp
f01039a5:	0f be 80 21 5b 10 f0 	movsbl -0xfefa4df(%eax),%eax
f01039ac:	50                   	push   %eax
f01039ad:	ff d7                	call   *%edi
}
f01039af:	83 c4 10             	add    $0x10,%esp
f01039b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039b5:	5b                   	pop    %ebx
f01039b6:	5e                   	pop    %esi
f01039b7:	5f                   	pop    %edi
f01039b8:	5d                   	pop    %ebp
f01039b9:	c3                   	ret    

f01039ba <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01039ba:	55                   	push   %ebp
f01039bb:	89 e5                	mov    %esp,%ebp
f01039bd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01039c0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01039c4:	8b 10                	mov    (%eax),%edx
f01039c6:	3b 50 04             	cmp    0x4(%eax),%edx
f01039c9:	73 0a                	jae    f01039d5 <sprintputch+0x1b>
		*b->buf++ = ch;
f01039cb:	8d 4a 01             	lea    0x1(%edx),%ecx
f01039ce:	89 08                	mov    %ecx,(%eax)
f01039d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039d3:	88 02                	mov    %al,(%edx)
}
f01039d5:	5d                   	pop    %ebp
f01039d6:	c3                   	ret    

f01039d7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01039d7:	55                   	push   %ebp
f01039d8:	89 e5                	mov    %esp,%ebp
f01039da:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01039dd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01039e0:	50                   	push   %eax
f01039e1:	ff 75 10             	pushl  0x10(%ebp)
f01039e4:	ff 75 0c             	pushl  0xc(%ebp)
f01039e7:	ff 75 08             	pushl  0x8(%ebp)
f01039ea:	e8 05 00 00 00       	call   f01039f4 <vprintfmt>
	va_end(ap);
}
f01039ef:	83 c4 10             	add    $0x10,%esp
f01039f2:	c9                   	leave  
f01039f3:	c3                   	ret    

f01039f4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01039f4:	55                   	push   %ebp
f01039f5:	89 e5                	mov    %esp,%ebp
f01039f7:	57                   	push   %edi
f01039f8:	56                   	push   %esi
f01039f9:	53                   	push   %ebx
f01039fa:	83 ec 2c             	sub    $0x2c,%esp
f01039fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a00:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a03:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103a06:	eb 12                	jmp    f0103a1a <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103a08:	85 c0                	test   %eax,%eax
f0103a0a:	0f 84 42 04 00 00    	je     f0103e52 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103a10:	83 ec 08             	sub    $0x8,%esp
f0103a13:	53                   	push   %ebx
f0103a14:	50                   	push   %eax
f0103a15:	ff d6                	call   *%esi
f0103a17:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a1a:	83 c7 01             	add    $0x1,%edi
f0103a1d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103a21:	83 f8 25             	cmp    $0x25,%eax
f0103a24:	75 e2                	jne    f0103a08 <vprintfmt+0x14>
f0103a26:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103a2a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103a31:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103a38:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103a3f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a44:	eb 07                	jmp    f0103a4d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a46:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103a49:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a4d:	8d 47 01             	lea    0x1(%edi),%eax
f0103a50:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a53:	0f b6 07             	movzbl (%edi),%eax
f0103a56:	0f b6 d0             	movzbl %al,%edx
f0103a59:	83 e8 23             	sub    $0x23,%eax
f0103a5c:	3c 55                	cmp    $0x55,%al
f0103a5e:	0f 87 d3 03 00 00    	ja     f0103e37 <vprintfmt+0x443>
f0103a64:	0f b6 c0             	movzbl %al,%eax
f0103a67:	ff 24 85 ac 5b 10 f0 	jmp    *-0xfefa454(,%eax,4)
f0103a6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103a71:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103a75:	eb d6                	jmp    f0103a4d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a7f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103a82:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103a85:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103a89:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103a8c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103a8f:	83 f9 09             	cmp    $0x9,%ecx
f0103a92:	77 3f                	ja     f0103ad3 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103a94:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103a97:	eb e9                	jmp    f0103a82 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103a99:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a9c:	8b 00                	mov    (%eax),%eax
f0103a9e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103aa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aa4:	8d 40 04             	lea    0x4(%eax),%eax
f0103aa7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aaa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103aad:	eb 2a                	jmp    f0103ad9 <vprintfmt+0xe5>
f0103aaf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ab2:	85 c0                	test   %eax,%eax
f0103ab4:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ab9:	0f 49 d0             	cmovns %eax,%edx
f0103abc:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103abf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ac2:	eb 89                	jmp    f0103a4d <vprintfmt+0x59>
f0103ac4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103ac7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103ace:	e9 7a ff ff ff       	jmp    f0103a4d <vprintfmt+0x59>
f0103ad3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103ad6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103ad9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103add:	0f 89 6a ff ff ff    	jns    f0103a4d <vprintfmt+0x59>
				width = precision, precision = -1;
f0103ae3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103ae6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103ae9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103af0:	e9 58 ff ff ff       	jmp    f0103a4d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103af5:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103af8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103afb:	e9 4d ff ff ff       	jmp    f0103a4d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103b00:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b03:	8d 78 04             	lea    0x4(%eax),%edi
f0103b06:	83 ec 08             	sub    $0x8,%esp
f0103b09:	53                   	push   %ebx
f0103b0a:	ff 30                	pushl  (%eax)
f0103b0c:	ff d6                	call   *%esi
			break;
f0103b0e:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103b11:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103b17:	e9 fe fe ff ff       	jmp    f0103a1a <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b1f:	8d 78 04             	lea    0x4(%eax),%edi
f0103b22:	8b 00                	mov    (%eax),%eax
f0103b24:	99                   	cltd   
f0103b25:	31 d0                	xor    %edx,%eax
f0103b27:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103b29:	83 f8 06             	cmp    $0x6,%eax
f0103b2c:	7f 0b                	jg     f0103b39 <vprintfmt+0x145>
f0103b2e:	8b 14 85 04 5d 10 f0 	mov    -0xfefa2fc(,%eax,4),%edx
f0103b35:	85 d2                	test   %edx,%edx
f0103b37:	75 1b                	jne    f0103b54 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103b39:	50                   	push   %eax
f0103b3a:	68 39 5b 10 f0       	push   $0xf0105b39
f0103b3f:	53                   	push   %ebx
f0103b40:	56                   	push   %esi
f0103b41:	e8 91 fe ff ff       	call   f01039d7 <printfmt>
f0103b46:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b49:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103b4f:	e9 c6 fe ff ff       	jmp    f0103a1a <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103b54:	52                   	push   %edx
f0103b55:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0103b5a:	53                   	push   %ebx
f0103b5b:	56                   	push   %esi
f0103b5c:	e8 76 fe ff ff       	call   f01039d7 <printfmt>
f0103b61:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b64:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b67:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b6a:	e9 ab fe ff ff       	jmp    f0103a1a <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103b6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b72:	83 c0 04             	add    $0x4,%eax
f0103b75:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103b78:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b7b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103b7d:	85 ff                	test   %edi,%edi
f0103b7f:	b8 32 5b 10 f0       	mov    $0xf0105b32,%eax
f0103b84:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103b87:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103b8b:	0f 8e 94 00 00 00    	jle    f0103c25 <vprintfmt+0x231>
f0103b91:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103b95:	0f 84 98 00 00 00    	je     f0103c33 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b9b:	83 ec 08             	sub    $0x8,%esp
f0103b9e:	ff 75 d0             	pushl  -0x30(%ebp)
f0103ba1:	57                   	push   %edi
f0103ba2:	e8 0c 04 00 00       	call   f0103fb3 <strnlen>
f0103ba7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103baa:	29 c1                	sub    %eax,%ecx
f0103bac:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103baf:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103bb2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103bb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103bb9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103bbc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103bbe:	eb 0f                	jmp    f0103bcf <vprintfmt+0x1db>
					putch(padc, putdat);
f0103bc0:	83 ec 08             	sub    $0x8,%esp
f0103bc3:	53                   	push   %ebx
f0103bc4:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bc7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103bc9:	83 ef 01             	sub    $0x1,%edi
f0103bcc:	83 c4 10             	add    $0x10,%esp
f0103bcf:	85 ff                	test   %edi,%edi
f0103bd1:	7f ed                	jg     f0103bc0 <vprintfmt+0x1cc>
f0103bd3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103bd6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103bd9:	85 c9                	test   %ecx,%ecx
f0103bdb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103be0:	0f 49 c1             	cmovns %ecx,%eax
f0103be3:	29 c1                	sub    %eax,%ecx
f0103be5:	89 75 08             	mov    %esi,0x8(%ebp)
f0103be8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103beb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103bee:	89 cb                	mov    %ecx,%ebx
f0103bf0:	eb 4d                	jmp    f0103c3f <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103bf2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103bf6:	74 1b                	je     f0103c13 <vprintfmt+0x21f>
f0103bf8:	0f be c0             	movsbl %al,%eax
f0103bfb:	83 e8 20             	sub    $0x20,%eax
f0103bfe:	83 f8 5e             	cmp    $0x5e,%eax
f0103c01:	76 10                	jbe    f0103c13 <vprintfmt+0x21f>
					putch('?', putdat);
f0103c03:	83 ec 08             	sub    $0x8,%esp
f0103c06:	ff 75 0c             	pushl  0xc(%ebp)
f0103c09:	6a 3f                	push   $0x3f
f0103c0b:	ff 55 08             	call   *0x8(%ebp)
f0103c0e:	83 c4 10             	add    $0x10,%esp
f0103c11:	eb 0d                	jmp    f0103c20 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103c13:	83 ec 08             	sub    $0x8,%esp
f0103c16:	ff 75 0c             	pushl  0xc(%ebp)
f0103c19:	52                   	push   %edx
f0103c1a:	ff 55 08             	call   *0x8(%ebp)
f0103c1d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c20:	83 eb 01             	sub    $0x1,%ebx
f0103c23:	eb 1a                	jmp    f0103c3f <vprintfmt+0x24b>
f0103c25:	89 75 08             	mov    %esi,0x8(%ebp)
f0103c28:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103c2b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103c2e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103c31:	eb 0c                	jmp    f0103c3f <vprintfmt+0x24b>
f0103c33:	89 75 08             	mov    %esi,0x8(%ebp)
f0103c36:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103c39:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103c3c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103c3f:	83 c7 01             	add    $0x1,%edi
f0103c42:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c46:	0f be d0             	movsbl %al,%edx
f0103c49:	85 d2                	test   %edx,%edx
f0103c4b:	74 23                	je     f0103c70 <vprintfmt+0x27c>
f0103c4d:	85 f6                	test   %esi,%esi
f0103c4f:	78 a1                	js     f0103bf2 <vprintfmt+0x1fe>
f0103c51:	83 ee 01             	sub    $0x1,%esi
f0103c54:	79 9c                	jns    f0103bf2 <vprintfmt+0x1fe>
f0103c56:	89 df                	mov    %ebx,%edi
f0103c58:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c5e:	eb 18                	jmp    f0103c78 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103c60:	83 ec 08             	sub    $0x8,%esp
f0103c63:	53                   	push   %ebx
f0103c64:	6a 20                	push   $0x20
f0103c66:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103c68:	83 ef 01             	sub    $0x1,%edi
f0103c6b:	83 c4 10             	add    $0x10,%esp
f0103c6e:	eb 08                	jmp    f0103c78 <vprintfmt+0x284>
f0103c70:	89 df                	mov    %ebx,%edi
f0103c72:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c75:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c78:	85 ff                	test   %edi,%edi
f0103c7a:	7f e4                	jg     f0103c60 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c7c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103c7f:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c82:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c85:	e9 90 fd ff ff       	jmp    f0103a1a <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103c8a:	83 f9 01             	cmp    $0x1,%ecx
f0103c8d:	7e 19                	jle    f0103ca8 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103c8f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c92:	8b 50 04             	mov    0x4(%eax),%edx
f0103c95:	8b 00                	mov    (%eax),%eax
f0103c97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c9a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ca0:	8d 40 08             	lea    0x8(%eax),%eax
f0103ca3:	89 45 14             	mov    %eax,0x14(%ebp)
f0103ca6:	eb 38                	jmp    f0103ce0 <vprintfmt+0x2ec>
	else if (lflag)
f0103ca8:	85 c9                	test   %ecx,%ecx
f0103caa:	74 1b                	je     f0103cc7 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103cac:	8b 45 14             	mov    0x14(%ebp),%eax
f0103caf:	8b 00                	mov    (%eax),%eax
f0103cb1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103cb4:	89 c1                	mov    %eax,%ecx
f0103cb6:	c1 f9 1f             	sar    $0x1f,%ecx
f0103cb9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103cbc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cbf:	8d 40 04             	lea    0x4(%eax),%eax
f0103cc2:	89 45 14             	mov    %eax,0x14(%ebp)
f0103cc5:	eb 19                	jmp    f0103ce0 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103cc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cca:	8b 00                	mov    (%eax),%eax
f0103ccc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ccf:	89 c1                	mov    %eax,%ecx
f0103cd1:	c1 f9 1f             	sar    $0x1f,%ecx
f0103cd4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103cd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cda:	8d 40 04             	lea    0x4(%eax),%eax
f0103cdd:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103ce0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ce3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103ce6:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103ceb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103cef:	0f 89 0e 01 00 00    	jns    f0103e03 <vprintfmt+0x40f>
				putch('-', putdat);
f0103cf5:	83 ec 08             	sub    $0x8,%esp
f0103cf8:	53                   	push   %ebx
f0103cf9:	6a 2d                	push   $0x2d
f0103cfb:	ff d6                	call   *%esi
				num = -(long long) num;
f0103cfd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d00:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103d03:	f7 da                	neg    %edx
f0103d05:	83 d1 00             	adc    $0x0,%ecx
f0103d08:	f7 d9                	neg    %ecx
f0103d0a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103d0d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d12:	e9 ec 00 00 00       	jmp    f0103e03 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103d17:	83 f9 01             	cmp    $0x1,%ecx
f0103d1a:	7e 18                	jle    f0103d34 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103d1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d1f:	8b 10                	mov    (%eax),%edx
f0103d21:	8b 48 04             	mov    0x4(%eax),%ecx
f0103d24:	8d 40 08             	lea    0x8(%eax),%eax
f0103d27:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103d2a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d2f:	e9 cf 00 00 00       	jmp    f0103e03 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103d34:	85 c9                	test   %ecx,%ecx
f0103d36:	74 1a                	je     f0103d52 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103d38:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d3b:	8b 10                	mov    (%eax),%edx
f0103d3d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d42:	8d 40 04             	lea    0x4(%eax),%eax
f0103d45:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103d48:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d4d:	e9 b1 00 00 00       	jmp    f0103e03 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103d52:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d55:	8b 10                	mov    (%eax),%edx
f0103d57:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d5c:	8d 40 04             	lea    0x4(%eax),%eax
f0103d5f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103d62:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d67:	e9 97 00 00 00       	jmp    f0103e03 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103d6c:	83 ec 08             	sub    $0x8,%esp
f0103d6f:	53                   	push   %ebx
f0103d70:	6a 58                	push   $0x58
f0103d72:	ff d6                	call   *%esi
			putch('X', putdat);
f0103d74:	83 c4 08             	add    $0x8,%esp
f0103d77:	53                   	push   %ebx
f0103d78:	6a 58                	push   $0x58
f0103d7a:	ff d6                	call   *%esi
			putch('X', putdat);
f0103d7c:	83 c4 08             	add    $0x8,%esp
f0103d7f:	53                   	push   %ebx
f0103d80:	6a 58                	push   $0x58
f0103d82:	ff d6                	call   *%esi
			break;
f0103d84:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103d8a:	e9 8b fc ff ff       	jmp    f0103a1a <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103d8f:	83 ec 08             	sub    $0x8,%esp
f0103d92:	53                   	push   %ebx
f0103d93:	6a 30                	push   $0x30
f0103d95:	ff d6                	call   *%esi
			putch('x', putdat);
f0103d97:	83 c4 08             	add    $0x8,%esp
f0103d9a:	53                   	push   %ebx
f0103d9b:	6a 78                	push   $0x78
f0103d9d:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103d9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103da2:	8b 10                	mov    (%eax),%edx
f0103da4:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103da9:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103dac:	8d 40 04             	lea    0x4(%eax),%eax
f0103daf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103db2:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103db7:	eb 4a                	jmp    f0103e03 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103db9:	83 f9 01             	cmp    $0x1,%ecx
f0103dbc:	7e 15                	jle    f0103dd3 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103dbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dc1:	8b 10                	mov    (%eax),%edx
f0103dc3:	8b 48 04             	mov    0x4(%eax),%ecx
f0103dc6:	8d 40 08             	lea    0x8(%eax),%eax
f0103dc9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103dcc:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dd1:	eb 30                	jmp    f0103e03 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103dd3:	85 c9                	test   %ecx,%ecx
f0103dd5:	74 17                	je     f0103dee <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103dd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dda:	8b 10                	mov    (%eax),%edx
f0103ddc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103de1:	8d 40 04             	lea    0x4(%eax),%eax
f0103de4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103de7:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dec:	eb 15                	jmp    f0103e03 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103dee:	8b 45 14             	mov    0x14(%ebp),%eax
f0103df1:	8b 10                	mov    (%eax),%edx
f0103df3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103df8:	8d 40 04             	lea    0x4(%eax),%eax
f0103dfb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103dfe:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103e03:	83 ec 0c             	sub    $0xc,%esp
f0103e06:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103e0a:	57                   	push   %edi
f0103e0b:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e0e:	50                   	push   %eax
f0103e0f:	51                   	push   %ecx
f0103e10:	52                   	push   %edx
f0103e11:	89 da                	mov    %ebx,%edx
f0103e13:	89 f0                	mov    %esi,%eax
f0103e15:	e8 f1 fa ff ff       	call   f010390b <printnum>
			break;
f0103e1a:	83 c4 20             	add    $0x20,%esp
f0103e1d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e20:	e9 f5 fb ff ff       	jmp    f0103a1a <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103e25:	83 ec 08             	sub    $0x8,%esp
f0103e28:	53                   	push   %ebx
f0103e29:	52                   	push   %edx
f0103e2a:	ff d6                	call   *%esi
			break;
f0103e2c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e2f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103e32:	e9 e3 fb ff ff       	jmp    f0103a1a <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103e37:	83 ec 08             	sub    $0x8,%esp
f0103e3a:	53                   	push   %ebx
f0103e3b:	6a 25                	push   $0x25
f0103e3d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103e3f:	83 c4 10             	add    $0x10,%esp
f0103e42:	eb 03                	jmp    f0103e47 <vprintfmt+0x453>
f0103e44:	83 ef 01             	sub    $0x1,%edi
f0103e47:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103e4b:	75 f7                	jne    f0103e44 <vprintfmt+0x450>
f0103e4d:	e9 c8 fb ff ff       	jmp    f0103a1a <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103e52:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e55:	5b                   	pop    %ebx
f0103e56:	5e                   	pop    %esi
f0103e57:	5f                   	pop    %edi
f0103e58:	5d                   	pop    %ebp
f0103e59:	c3                   	ret    

f0103e5a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e5a:	55                   	push   %ebp
f0103e5b:	89 e5                	mov    %esp,%ebp
f0103e5d:	83 ec 18             	sub    $0x18,%esp
f0103e60:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e63:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e66:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e69:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e6d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e77:	85 c0                	test   %eax,%eax
f0103e79:	74 26                	je     f0103ea1 <vsnprintf+0x47>
f0103e7b:	85 d2                	test   %edx,%edx
f0103e7d:	7e 22                	jle    f0103ea1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e7f:	ff 75 14             	pushl  0x14(%ebp)
f0103e82:	ff 75 10             	pushl  0x10(%ebp)
f0103e85:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e88:	50                   	push   %eax
f0103e89:	68 ba 39 10 f0       	push   $0xf01039ba
f0103e8e:	e8 61 fb ff ff       	call   f01039f4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e93:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e96:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e9c:	83 c4 10             	add    $0x10,%esp
f0103e9f:	eb 05                	jmp    f0103ea6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103ea1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103ea6:	c9                   	leave  
f0103ea7:	c3                   	ret    

f0103ea8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103ea8:	55                   	push   %ebp
f0103ea9:	89 e5                	mov    %esp,%ebp
f0103eab:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103eae:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103eb1:	50                   	push   %eax
f0103eb2:	ff 75 10             	pushl  0x10(%ebp)
f0103eb5:	ff 75 0c             	pushl  0xc(%ebp)
f0103eb8:	ff 75 08             	pushl  0x8(%ebp)
f0103ebb:	e8 9a ff ff ff       	call   f0103e5a <vsnprintf>
	va_end(ap);

	return rc;
}
f0103ec0:	c9                   	leave  
f0103ec1:	c3                   	ret    

f0103ec2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103ec2:	55                   	push   %ebp
f0103ec3:	89 e5                	mov    %esp,%ebp
f0103ec5:	57                   	push   %edi
f0103ec6:	56                   	push   %esi
f0103ec7:	53                   	push   %ebx
f0103ec8:	83 ec 0c             	sub    $0xc,%esp
f0103ecb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ece:	85 c0                	test   %eax,%eax
f0103ed0:	74 11                	je     f0103ee3 <readline+0x21>
		cprintf("%s", prompt);
f0103ed2:	83 ec 08             	sub    $0x8,%esp
f0103ed5:	50                   	push   %eax
f0103ed6:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0103edb:	e8 c8 ef ff ff       	call   f0102ea8 <cprintf>
f0103ee0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103ee3:	83 ec 0c             	sub    $0xc,%esp
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	e8 49 c7 ff ff       	call   f0100636 <iscons>
f0103eed:	89 c7                	mov    %eax,%edi
f0103eef:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103ef2:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ef7:	e8 29 c7 ff ff       	call   f0100625 <getchar>
f0103efc:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103efe:	85 c0                	test   %eax,%eax
f0103f00:	79 18                	jns    f0103f1a <readline+0x58>
			cprintf("read error: %e\n", c);
f0103f02:	83 ec 08             	sub    $0x8,%esp
f0103f05:	50                   	push   %eax
f0103f06:	68 20 5d 10 f0       	push   $0xf0105d20
f0103f0b:	e8 98 ef ff ff       	call   f0102ea8 <cprintf>
			return NULL;
f0103f10:	83 c4 10             	add    $0x10,%esp
f0103f13:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f18:	eb 79                	jmp    f0103f93 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103f1a:	83 f8 08             	cmp    $0x8,%eax
f0103f1d:	0f 94 c2             	sete   %dl
f0103f20:	83 f8 7f             	cmp    $0x7f,%eax
f0103f23:	0f 94 c0             	sete   %al
f0103f26:	08 c2                	or     %al,%dl
f0103f28:	74 1a                	je     f0103f44 <readline+0x82>
f0103f2a:	85 f6                	test   %esi,%esi
f0103f2c:	7e 16                	jle    f0103f44 <readline+0x82>
			if (echoing)
f0103f2e:	85 ff                	test   %edi,%edi
f0103f30:	74 0d                	je     f0103f3f <readline+0x7d>
				cputchar('\b');
f0103f32:	83 ec 0c             	sub    $0xc,%esp
f0103f35:	6a 08                	push   $0x8
f0103f37:	e8 d9 c6 ff ff       	call   f0100615 <cputchar>
f0103f3c:	83 c4 10             	add    $0x10,%esp
			i--;
f0103f3f:	83 ee 01             	sub    $0x1,%esi
f0103f42:	eb b3                	jmp    f0103ef7 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f44:	83 fb 1f             	cmp    $0x1f,%ebx
f0103f47:	7e 23                	jle    f0103f6c <readline+0xaa>
f0103f49:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f4f:	7f 1b                	jg     f0103f6c <readline+0xaa>
			if (echoing)
f0103f51:	85 ff                	test   %edi,%edi
f0103f53:	74 0c                	je     f0103f61 <readline+0x9f>
				cputchar(c);
f0103f55:	83 ec 0c             	sub    $0xc,%esp
f0103f58:	53                   	push   %ebx
f0103f59:	e8 b7 c6 ff ff       	call   f0100615 <cputchar>
f0103f5e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103f61:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0103f67:	8d 76 01             	lea    0x1(%esi),%esi
f0103f6a:	eb 8b                	jmp    f0103ef7 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103f6c:	83 fb 0a             	cmp    $0xa,%ebx
f0103f6f:	74 05                	je     f0103f76 <readline+0xb4>
f0103f71:	83 fb 0d             	cmp    $0xd,%ebx
f0103f74:	75 81                	jne    f0103ef7 <readline+0x35>
			if (echoing)
f0103f76:	85 ff                	test   %edi,%edi
f0103f78:	74 0d                	je     f0103f87 <readline+0xc5>
				cputchar('\n');
f0103f7a:	83 ec 0c             	sub    $0xc,%esp
f0103f7d:	6a 0a                	push   $0xa
f0103f7f:	e8 91 c6 ff ff       	call   f0100615 <cputchar>
f0103f84:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103f87:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0103f8e:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f0103f93:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f96:	5b                   	pop    %ebx
f0103f97:	5e                   	pop    %esi
f0103f98:	5f                   	pop    %edi
f0103f99:	5d                   	pop    %ebp
f0103f9a:	c3                   	ret    

f0103f9b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f9b:	55                   	push   %ebp
f0103f9c:	89 e5                	mov    %esp,%ebp
f0103f9e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103fa1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fa6:	eb 03                	jmp    f0103fab <strlen+0x10>
		n++;
f0103fa8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103fab:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103faf:	75 f7                	jne    f0103fa8 <strlen+0xd>
		n++;
	return n;
}
f0103fb1:	5d                   	pop    %ebp
f0103fb2:	c3                   	ret    

f0103fb3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103fb3:	55                   	push   %ebp
f0103fb4:	89 e5                	mov    %esp,%ebp
f0103fb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fb9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fc1:	eb 03                	jmp    f0103fc6 <strnlen+0x13>
		n++;
f0103fc3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fc6:	39 c2                	cmp    %eax,%edx
f0103fc8:	74 08                	je     f0103fd2 <strnlen+0x1f>
f0103fca:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103fce:	75 f3                	jne    f0103fc3 <strnlen+0x10>
f0103fd0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103fd2:	5d                   	pop    %ebp
f0103fd3:	c3                   	ret    

f0103fd4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103fd4:	55                   	push   %ebp
f0103fd5:	89 e5                	mov    %esp,%ebp
f0103fd7:	53                   	push   %ebx
f0103fd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fdb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103fde:	89 c2                	mov    %eax,%edx
f0103fe0:	83 c2 01             	add    $0x1,%edx
f0103fe3:	83 c1 01             	add    $0x1,%ecx
f0103fe6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103fea:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103fed:	84 db                	test   %bl,%bl
f0103fef:	75 ef                	jne    f0103fe0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103ff1:	5b                   	pop    %ebx
f0103ff2:	5d                   	pop    %ebp
f0103ff3:	c3                   	ret    

f0103ff4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ff4:	55                   	push   %ebp
f0103ff5:	89 e5                	mov    %esp,%ebp
f0103ff7:	53                   	push   %ebx
f0103ff8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103ffb:	53                   	push   %ebx
f0103ffc:	e8 9a ff ff ff       	call   f0103f9b <strlen>
f0104001:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104004:	ff 75 0c             	pushl  0xc(%ebp)
f0104007:	01 d8                	add    %ebx,%eax
f0104009:	50                   	push   %eax
f010400a:	e8 c5 ff ff ff       	call   f0103fd4 <strcpy>
	return dst;
}
f010400f:	89 d8                	mov    %ebx,%eax
f0104011:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104014:	c9                   	leave  
f0104015:	c3                   	ret    

f0104016 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104016:	55                   	push   %ebp
f0104017:	89 e5                	mov    %esp,%ebp
f0104019:	56                   	push   %esi
f010401a:	53                   	push   %ebx
f010401b:	8b 75 08             	mov    0x8(%ebp),%esi
f010401e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104021:	89 f3                	mov    %esi,%ebx
f0104023:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104026:	89 f2                	mov    %esi,%edx
f0104028:	eb 0f                	jmp    f0104039 <strncpy+0x23>
		*dst++ = *src;
f010402a:	83 c2 01             	add    $0x1,%edx
f010402d:	0f b6 01             	movzbl (%ecx),%eax
f0104030:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104033:	80 39 01             	cmpb   $0x1,(%ecx)
f0104036:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104039:	39 da                	cmp    %ebx,%edx
f010403b:	75 ed                	jne    f010402a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010403d:	89 f0                	mov    %esi,%eax
f010403f:	5b                   	pop    %ebx
f0104040:	5e                   	pop    %esi
f0104041:	5d                   	pop    %ebp
f0104042:	c3                   	ret    

f0104043 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104043:	55                   	push   %ebp
f0104044:	89 e5                	mov    %esp,%ebp
f0104046:	56                   	push   %esi
f0104047:	53                   	push   %ebx
f0104048:	8b 75 08             	mov    0x8(%ebp),%esi
f010404b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010404e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104051:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104053:	85 d2                	test   %edx,%edx
f0104055:	74 21                	je     f0104078 <strlcpy+0x35>
f0104057:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010405b:	89 f2                	mov    %esi,%edx
f010405d:	eb 09                	jmp    f0104068 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010405f:	83 c2 01             	add    $0x1,%edx
f0104062:	83 c1 01             	add    $0x1,%ecx
f0104065:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104068:	39 c2                	cmp    %eax,%edx
f010406a:	74 09                	je     f0104075 <strlcpy+0x32>
f010406c:	0f b6 19             	movzbl (%ecx),%ebx
f010406f:	84 db                	test   %bl,%bl
f0104071:	75 ec                	jne    f010405f <strlcpy+0x1c>
f0104073:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104075:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104078:	29 f0                	sub    %esi,%eax
}
f010407a:	5b                   	pop    %ebx
f010407b:	5e                   	pop    %esi
f010407c:	5d                   	pop    %ebp
f010407d:	c3                   	ret    

f010407e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010407e:	55                   	push   %ebp
f010407f:	89 e5                	mov    %esp,%ebp
f0104081:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104084:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104087:	eb 06                	jmp    f010408f <strcmp+0x11>
		p++, q++;
f0104089:	83 c1 01             	add    $0x1,%ecx
f010408c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010408f:	0f b6 01             	movzbl (%ecx),%eax
f0104092:	84 c0                	test   %al,%al
f0104094:	74 04                	je     f010409a <strcmp+0x1c>
f0104096:	3a 02                	cmp    (%edx),%al
f0104098:	74 ef                	je     f0104089 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010409a:	0f b6 c0             	movzbl %al,%eax
f010409d:	0f b6 12             	movzbl (%edx),%edx
f01040a0:	29 d0                	sub    %edx,%eax
}
f01040a2:	5d                   	pop    %ebp
f01040a3:	c3                   	ret    

f01040a4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01040a4:	55                   	push   %ebp
f01040a5:	89 e5                	mov    %esp,%ebp
f01040a7:	53                   	push   %ebx
f01040a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ab:	8b 55 0c             	mov    0xc(%ebp),%edx
f01040ae:	89 c3                	mov    %eax,%ebx
f01040b0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01040b3:	eb 06                	jmp    f01040bb <strncmp+0x17>
		n--, p++, q++;
f01040b5:	83 c0 01             	add    $0x1,%eax
f01040b8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040bb:	39 d8                	cmp    %ebx,%eax
f01040bd:	74 15                	je     f01040d4 <strncmp+0x30>
f01040bf:	0f b6 08             	movzbl (%eax),%ecx
f01040c2:	84 c9                	test   %cl,%cl
f01040c4:	74 04                	je     f01040ca <strncmp+0x26>
f01040c6:	3a 0a                	cmp    (%edx),%cl
f01040c8:	74 eb                	je     f01040b5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040ca:	0f b6 00             	movzbl (%eax),%eax
f01040cd:	0f b6 12             	movzbl (%edx),%edx
f01040d0:	29 d0                	sub    %edx,%eax
f01040d2:	eb 05                	jmp    f01040d9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040d4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01040d9:	5b                   	pop    %ebx
f01040da:	5d                   	pop    %ebp
f01040db:	c3                   	ret    

f01040dc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040dc:	55                   	push   %ebp
f01040dd:	89 e5                	mov    %esp,%ebp
f01040df:	8b 45 08             	mov    0x8(%ebp),%eax
f01040e2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040e6:	eb 07                	jmp    f01040ef <strchr+0x13>
		if (*s == c)
f01040e8:	38 ca                	cmp    %cl,%dl
f01040ea:	74 0f                	je     f01040fb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01040ec:	83 c0 01             	add    $0x1,%eax
f01040ef:	0f b6 10             	movzbl (%eax),%edx
f01040f2:	84 d2                	test   %dl,%dl
f01040f4:	75 f2                	jne    f01040e8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01040f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01040fb:	5d                   	pop    %ebp
f01040fc:	c3                   	ret    

f01040fd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01040fd:	55                   	push   %ebp
f01040fe:	89 e5                	mov    %esp,%ebp
f0104100:	8b 45 08             	mov    0x8(%ebp),%eax
f0104103:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104107:	eb 03                	jmp    f010410c <strfind+0xf>
f0104109:	83 c0 01             	add    $0x1,%eax
f010410c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010410f:	38 ca                	cmp    %cl,%dl
f0104111:	74 04                	je     f0104117 <strfind+0x1a>
f0104113:	84 d2                	test   %dl,%dl
f0104115:	75 f2                	jne    f0104109 <strfind+0xc>
			break;
	return (char *) s;
}
f0104117:	5d                   	pop    %ebp
f0104118:	c3                   	ret    

f0104119 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104119:	55                   	push   %ebp
f010411a:	89 e5                	mov    %esp,%ebp
f010411c:	57                   	push   %edi
f010411d:	56                   	push   %esi
f010411e:	53                   	push   %ebx
f010411f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104122:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104125:	85 c9                	test   %ecx,%ecx
f0104127:	74 36                	je     f010415f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104129:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010412f:	75 28                	jne    f0104159 <memset+0x40>
f0104131:	f6 c1 03             	test   $0x3,%cl
f0104134:	75 23                	jne    f0104159 <memset+0x40>
		c &= 0xFF;
f0104136:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010413a:	89 d3                	mov    %edx,%ebx
f010413c:	c1 e3 08             	shl    $0x8,%ebx
f010413f:	89 d6                	mov    %edx,%esi
f0104141:	c1 e6 18             	shl    $0x18,%esi
f0104144:	89 d0                	mov    %edx,%eax
f0104146:	c1 e0 10             	shl    $0x10,%eax
f0104149:	09 f0                	or     %esi,%eax
f010414b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010414d:	89 d8                	mov    %ebx,%eax
f010414f:	09 d0                	or     %edx,%eax
f0104151:	c1 e9 02             	shr    $0x2,%ecx
f0104154:	fc                   	cld    
f0104155:	f3 ab                	rep stos %eax,%es:(%edi)
f0104157:	eb 06                	jmp    f010415f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104159:	8b 45 0c             	mov    0xc(%ebp),%eax
f010415c:	fc                   	cld    
f010415d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010415f:	89 f8                	mov    %edi,%eax
f0104161:	5b                   	pop    %ebx
f0104162:	5e                   	pop    %esi
f0104163:	5f                   	pop    %edi
f0104164:	5d                   	pop    %ebp
f0104165:	c3                   	ret    

f0104166 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104166:	55                   	push   %ebp
f0104167:	89 e5                	mov    %esp,%ebp
f0104169:	57                   	push   %edi
f010416a:	56                   	push   %esi
f010416b:	8b 45 08             	mov    0x8(%ebp),%eax
f010416e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104171:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104174:	39 c6                	cmp    %eax,%esi
f0104176:	73 35                	jae    f01041ad <memmove+0x47>
f0104178:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010417b:	39 d0                	cmp    %edx,%eax
f010417d:	73 2e                	jae    f01041ad <memmove+0x47>
		s += n;
		d += n;
f010417f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104182:	89 d6                	mov    %edx,%esi
f0104184:	09 fe                	or     %edi,%esi
f0104186:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010418c:	75 13                	jne    f01041a1 <memmove+0x3b>
f010418e:	f6 c1 03             	test   $0x3,%cl
f0104191:	75 0e                	jne    f01041a1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104193:	83 ef 04             	sub    $0x4,%edi
f0104196:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104199:	c1 e9 02             	shr    $0x2,%ecx
f010419c:	fd                   	std    
f010419d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010419f:	eb 09                	jmp    f01041aa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041a1:	83 ef 01             	sub    $0x1,%edi
f01041a4:	8d 72 ff             	lea    -0x1(%edx),%esi
f01041a7:	fd                   	std    
f01041a8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041aa:	fc                   	cld    
f01041ab:	eb 1d                	jmp    f01041ca <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041ad:	89 f2                	mov    %esi,%edx
f01041af:	09 c2                	or     %eax,%edx
f01041b1:	f6 c2 03             	test   $0x3,%dl
f01041b4:	75 0f                	jne    f01041c5 <memmove+0x5f>
f01041b6:	f6 c1 03             	test   $0x3,%cl
f01041b9:	75 0a                	jne    f01041c5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01041bb:	c1 e9 02             	shr    $0x2,%ecx
f01041be:	89 c7                	mov    %eax,%edi
f01041c0:	fc                   	cld    
f01041c1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041c3:	eb 05                	jmp    f01041ca <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01041c5:	89 c7                	mov    %eax,%edi
f01041c7:	fc                   	cld    
f01041c8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01041ca:	5e                   	pop    %esi
f01041cb:	5f                   	pop    %edi
f01041cc:	5d                   	pop    %ebp
f01041cd:	c3                   	ret    

f01041ce <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01041ce:	55                   	push   %ebp
f01041cf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01041d1:	ff 75 10             	pushl  0x10(%ebp)
f01041d4:	ff 75 0c             	pushl  0xc(%ebp)
f01041d7:	ff 75 08             	pushl  0x8(%ebp)
f01041da:	e8 87 ff ff ff       	call   f0104166 <memmove>
}
f01041df:	c9                   	leave  
f01041e0:	c3                   	ret    

f01041e1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01041e1:	55                   	push   %ebp
f01041e2:	89 e5                	mov    %esp,%ebp
f01041e4:	56                   	push   %esi
f01041e5:	53                   	push   %ebx
f01041e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01041e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041ec:	89 c6                	mov    %eax,%esi
f01041ee:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01041f1:	eb 1a                	jmp    f010420d <memcmp+0x2c>
		if (*s1 != *s2)
f01041f3:	0f b6 08             	movzbl (%eax),%ecx
f01041f6:	0f b6 1a             	movzbl (%edx),%ebx
f01041f9:	38 d9                	cmp    %bl,%cl
f01041fb:	74 0a                	je     f0104207 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01041fd:	0f b6 c1             	movzbl %cl,%eax
f0104200:	0f b6 db             	movzbl %bl,%ebx
f0104203:	29 d8                	sub    %ebx,%eax
f0104205:	eb 0f                	jmp    f0104216 <memcmp+0x35>
		s1++, s2++;
f0104207:	83 c0 01             	add    $0x1,%eax
f010420a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010420d:	39 f0                	cmp    %esi,%eax
f010420f:	75 e2                	jne    f01041f3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104211:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104216:	5b                   	pop    %ebx
f0104217:	5e                   	pop    %esi
f0104218:	5d                   	pop    %ebp
f0104219:	c3                   	ret    

f010421a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010421a:	55                   	push   %ebp
f010421b:	89 e5                	mov    %esp,%ebp
f010421d:	53                   	push   %ebx
f010421e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104221:	89 c1                	mov    %eax,%ecx
f0104223:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104226:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010422a:	eb 0a                	jmp    f0104236 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010422c:	0f b6 10             	movzbl (%eax),%edx
f010422f:	39 da                	cmp    %ebx,%edx
f0104231:	74 07                	je     f010423a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104233:	83 c0 01             	add    $0x1,%eax
f0104236:	39 c8                	cmp    %ecx,%eax
f0104238:	72 f2                	jb     f010422c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010423a:	5b                   	pop    %ebx
f010423b:	5d                   	pop    %ebp
f010423c:	c3                   	ret    

f010423d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010423d:	55                   	push   %ebp
f010423e:	89 e5                	mov    %esp,%ebp
f0104240:	57                   	push   %edi
f0104241:	56                   	push   %esi
f0104242:	53                   	push   %ebx
f0104243:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104246:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104249:	eb 03                	jmp    f010424e <strtol+0x11>
		s++;
f010424b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010424e:	0f b6 01             	movzbl (%ecx),%eax
f0104251:	3c 20                	cmp    $0x20,%al
f0104253:	74 f6                	je     f010424b <strtol+0xe>
f0104255:	3c 09                	cmp    $0x9,%al
f0104257:	74 f2                	je     f010424b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104259:	3c 2b                	cmp    $0x2b,%al
f010425b:	75 0a                	jne    f0104267 <strtol+0x2a>
		s++;
f010425d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104260:	bf 00 00 00 00       	mov    $0x0,%edi
f0104265:	eb 11                	jmp    f0104278 <strtol+0x3b>
f0104267:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010426c:	3c 2d                	cmp    $0x2d,%al
f010426e:	75 08                	jne    f0104278 <strtol+0x3b>
		s++, neg = 1;
f0104270:	83 c1 01             	add    $0x1,%ecx
f0104273:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104278:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010427e:	75 15                	jne    f0104295 <strtol+0x58>
f0104280:	80 39 30             	cmpb   $0x30,(%ecx)
f0104283:	75 10                	jne    f0104295 <strtol+0x58>
f0104285:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104289:	75 7c                	jne    f0104307 <strtol+0xca>
		s += 2, base = 16;
f010428b:	83 c1 02             	add    $0x2,%ecx
f010428e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104293:	eb 16                	jmp    f01042ab <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104295:	85 db                	test   %ebx,%ebx
f0104297:	75 12                	jne    f01042ab <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104299:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010429e:	80 39 30             	cmpb   $0x30,(%ecx)
f01042a1:	75 08                	jne    f01042ab <strtol+0x6e>
		s++, base = 8;
f01042a3:	83 c1 01             	add    $0x1,%ecx
f01042a6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01042ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01042b0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01042b3:	0f b6 11             	movzbl (%ecx),%edx
f01042b6:	8d 72 d0             	lea    -0x30(%edx),%esi
f01042b9:	89 f3                	mov    %esi,%ebx
f01042bb:	80 fb 09             	cmp    $0x9,%bl
f01042be:	77 08                	ja     f01042c8 <strtol+0x8b>
			dig = *s - '0';
f01042c0:	0f be d2             	movsbl %dl,%edx
f01042c3:	83 ea 30             	sub    $0x30,%edx
f01042c6:	eb 22                	jmp    f01042ea <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01042c8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01042cb:	89 f3                	mov    %esi,%ebx
f01042cd:	80 fb 19             	cmp    $0x19,%bl
f01042d0:	77 08                	ja     f01042da <strtol+0x9d>
			dig = *s - 'a' + 10;
f01042d2:	0f be d2             	movsbl %dl,%edx
f01042d5:	83 ea 57             	sub    $0x57,%edx
f01042d8:	eb 10                	jmp    f01042ea <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01042da:	8d 72 bf             	lea    -0x41(%edx),%esi
f01042dd:	89 f3                	mov    %esi,%ebx
f01042df:	80 fb 19             	cmp    $0x19,%bl
f01042e2:	77 16                	ja     f01042fa <strtol+0xbd>
			dig = *s - 'A' + 10;
f01042e4:	0f be d2             	movsbl %dl,%edx
f01042e7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01042ea:	3b 55 10             	cmp    0x10(%ebp),%edx
f01042ed:	7d 0b                	jge    f01042fa <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01042ef:	83 c1 01             	add    $0x1,%ecx
f01042f2:	0f af 45 10          	imul   0x10(%ebp),%eax
f01042f6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01042f8:	eb b9                	jmp    f01042b3 <strtol+0x76>

	if (endptr)
f01042fa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01042fe:	74 0d                	je     f010430d <strtol+0xd0>
		*endptr = (char *) s;
f0104300:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104303:	89 0e                	mov    %ecx,(%esi)
f0104305:	eb 06                	jmp    f010430d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104307:	85 db                	test   %ebx,%ebx
f0104309:	74 98                	je     f01042a3 <strtol+0x66>
f010430b:	eb 9e                	jmp    f01042ab <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010430d:	89 c2                	mov    %eax,%edx
f010430f:	f7 da                	neg    %edx
f0104311:	85 ff                	test   %edi,%edi
f0104313:	0f 45 c2             	cmovne %edx,%eax
}
f0104316:	5b                   	pop    %ebx
f0104317:	5e                   	pop    %esi
f0104318:	5f                   	pop    %edi
f0104319:	5d                   	pop    %ebp
f010431a:	c3                   	ret    
f010431b:	66 90                	xchg   %ax,%ax
f010431d:	66 90                	xchg   %ax,%ax
f010431f:	90                   	nop

f0104320 <__udivdi3>:
f0104320:	55                   	push   %ebp
f0104321:	57                   	push   %edi
f0104322:	56                   	push   %esi
f0104323:	53                   	push   %ebx
f0104324:	83 ec 1c             	sub    $0x1c,%esp
f0104327:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010432b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010432f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104333:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104337:	85 f6                	test   %esi,%esi
f0104339:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010433d:	89 ca                	mov    %ecx,%edx
f010433f:	89 f8                	mov    %edi,%eax
f0104341:	75 3d                	jne    f0104380 <__udivdi3+0x60>
f0104343:	39 cf                	cmp    %ecx,%edi
f0104345:	0f 87 c5 00 00 00    	ja     f0104410 <__udivdi3+0xf0>
f010434b:	85 ff                	test   %edi,%edi
f010434d:	89 fd                	mov    %edi,%ebp
f010434f:	75 0b                	jne    f010435c <__udivdi3+0x3c>
f0104351:	b8 01 00 00 00       	mov    $0x1,%eax
f0104356:	31 d2                	xor    %edx,%edx
f0104358:	f7 f7                	div    %edi
f010435a:	89 c5                	mov    %eax,%ebp
f010435c:	89 c8                	mov    %ecx,%eax
f010435e:	31 d2                	xor    %edx,%edx
f0104360:	f7 f5                	div    %ebp
f0104362:	89 c1                	mov    %eax,%ecx
f0104364:	89 d8                	mov    %ebx,%eax
f0104366:	89 cf                	mov    %ecx,%edi
f0104368:	f7 f5                	div    %ebp
f010436a:	89 c3                	mov    %eax,%ebx
f010436c:	89 d8                	mov    %ebx,%eax
f010436e:	89 fa                	mov    %edi,%edx
f0104370:	83 c4 1c             	add    $0x1c,%esp
f0104373:	5b                   	pop    %ebx
f0104374:	5e                   	pop    %esi
f0104375:	5f                   	pop    %edi
f0104376:	5d                   	pop    %ebp
f0104377:	c3                   	ret    
f0104378:	90                   	nop
f0104379:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104380:	39 ce                	cmp    %ecx,%esi
f0104382:	77 74                	ja     f01043f8 <__udivdi3+0xd8>
f0104384:	0f bd fe             	bsr    %esi,%edi
f0104387:	83 f7 1f             	xor    $0x1f,%edi
f010438a:	0f 84 98 00 00 00    	je     f0104428 <__udivdi3+0x108>
f0104390:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104395:	89 f9                	mov    %edi,%ecx
f0104397:	89 c5                	mov    %eax,%ebp
f0104399:	29 fb                	sub    %edi,%ebx
f010439b:	d3 e6                	shl    %cl,%esi
f010439d:	89 d9                	mov    %ebx,%ecx
f010439f:	d3 ed                	shr    %cl,%ebp
f01043a1:	89 f9                	mov    %edi,%ecx
f01043a3:	d3 e0                	shl    %cl,%eax
f01043a5:	09 ee                	or     %ebp,%esi
f01043a7:	89 d9                	mov    %ebx,%ecx
f01043a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01043ad:	89 d5                	mov    %edx,%ebp
f01043af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043b3:	d3 ed                	shr    %cl,%ebp
f01043b5:	89 f9                	mov    %edi,%ecx
f01043b7:	d3 e2                	shl    %cl,%edx
f01043b9:	89 d9                	mov    %ebx,%ecx
f01043bb:	d3 e8                	shr    %cl,%eax
f01043bd:	09 c2                	or     %eax,%edx
f01043bf:	89 d0                	mov    %edx,%eax
f01043c1:	89 ea                	mov    %ebp,%edx
f01043c3:	f7 f6                	div    %esi
f01043c5:	89 d5                	mov    %edx,%ebp
f01043c7:	89 c3                	mov    %eax,%ebx
f01043c9:	f7 64 24 0c          	mull   0xc(%esp)
f01043cd:	39 d5                	cmp    %edx,%ebp
f01043cf:	72 10                	jb     f01043e1 <__udivdi3+0xc1>
f01043d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01043d5:	89 f9                	mov    %edi,%ecx
f01043d7:	d3 e6                	shl    %cl,%esi
f01043d9:	39 c6                	cmp    %eax,%esi
f01043db:	73 07                	jae    f01043e4 <__udivdi3+0xc4>
f01043dd:	39 d5                	cmp    %edx,%ebp
f01043df:	75 03                	jne    f01043e4 <__udivdi3+0xc4>
f01043e1:	83 eb 01             	sub    $0x1,%ebx
f01043e4:	31 ff                	xor    %edi,%edi
f01043e6:	89 d8                	mov    %ebx,%eax
f01043e8:	89 fa                	mov    %edi,%edx
f01043ea:	83 c4 1c             	add    $0x1c,%esp
f01043ed:	5b                   	pop    %ebx
f01043ee:	5e                   	pop    %esi
f01043ef:	5f                   	pop    %edi
f01043f0:	5d                   	pop    %ebp
f01043f1:	c3                   	ret    
f01043f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01043f8:	31 ff                	xor    %edi,%edi
f01043fa:	31 db                	xor    %ebx,%ebx
f01043fc:	89 d8                	mov    %ebx,%eax
f01043fe:	89 fa                	mov    %edi,%edx
f0104400:	83 c4 1c             	add    $0x1c,%esp
f0104403:	5b                   	pop    %ebx
f0104404:	5e                   	pop    %esi
f0104405:	5f                   	pop    %edi
f0104406:	5d                   	pop    %ebp
f0104407:	c3                   	ret    
f0104408:	90                   	nop
f0104409:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104410:	89 d8                	mov    %ebx,%eax
f0104412:	f7 f7                	div    %edi
f0104414:	31 ff                	xor    %edi,%edi
f0104416:	89 c3                	mov    %eax,%ebx
f0104418:	89 d8                	mov    %ebx,%eax
f010441a:	89 fa                	mov    %edi,%edx
f010441c:	83 c4 1c             	add    $0x1c,%esp
f010441f:	5b                   	pop    %ebx
f0104420:	5e                   	pop    %esi
f0104421:	5f                   	pop    %edi
f0104422:	5d                   	pop    %ebp
f0104423:	c3                   	ret    
f0104424:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104428:	39 ce                	cmp    %ecx,%esi
f010442a:	72 0c                	jb     f0104438 <__udivdi3+0x118>
f010442c:	31 db                	xor    %ebx,%ebx
f010442e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104432:	0f 87 34 ff ff ff    	ja     f010436c <__udivdi3+0x4c>
f0104438:	bb 01 00 00 00       	mov    $0x1,%ebx
f010443d:	e9 2a ff ff ff       	jmp    f010436c <__udivdi3+0x4c>
f0104442:	66 90                	xchg   %ax,%ax
f0104444:	66 90                	xchg   %ax,%ax
f0104446:	66 90                	xchg   %ax,%ax
f0104448:	66 90                	xchg   %ax,%ax
f010444a:	66 90                	xchg   %ax,%ax
f010444c:	66 90                	xchg   %ax,%ax
f010444e:	66 90                	xchg   %ax,%ax

f0104450 <__umoddi3>:
f0104450:	55                   	push   %ebp
f0104451:	57                   	push   %edi
f0104452:	56                   	push   %esi
f0104453:	53                   	push   %ebx
f0104454:	83 ec 1c             	sub    $0x1c,%esp
f0104457:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010445b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010445f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104463:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104467:	85 d2                	test   %edx,%edx
f0104469:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010446d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104471:	89 f3                	mov    %esi,%ebx
f0104473:	89 3c 24             	mov    %edi,(%esp)
f0104476:	89 74 24 04          	mov    %esi,0x4(%esp)
f010447a:	75 1c                	jne    f0104498 <__umoddi3+0x48>
f010447c:	39 f7                	cmp    %esi,%edi
f010447e:	76 50                	jbe    f01044d0 <__umoddi3+0x80>
f0104480:	89 c8                	mov    %ecx,%eax
f0104482:	89 f2                	mov    %esi,%edx
f0104484:	f7 f7                	div    %edi
f0104486:	89 d0                	mov    %edx,%eax
f0104488:	31 d2                	xor    %edx,%edx
f010448a:	83 c4 1c             	add    $0x1c,%esp
f010448d:	5b                   	pop    %ebx
f010448e:	5e                   	pop    %esi
f010448f:	5f                   	pop    %edi
f0104490:	5d                   	pop    %ebp
f0104491:	c3                   	ret    
f0104492:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104498:	39 f2                	cmp    %esi,%edx
f010449a:	89 d0                	mov    %edx,%eax
f010449c:	77 52                	ja     f01044f0 <__umoddi3+0xa0>
f010449e:	0f bd ea             	bsr    %edx,%ebp
f01044a1:	83 f5 1f             	xor    $0x1f,%ebp
f01044a4:	75 5a                	jne    f0104500 <__umoddi3+0xb0>
f01044a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01044aa:	0f 82 e0 00 00 00    	jb     f0104590 <__umoddi3+0x140>
f01044b0:	39 0c 24             	cmp    %ecx,(%esp)
f01044b3:	0f 86 d7 00 00 00    	jbe    f0104590 <__umoddi3+0x140>
f01044b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01044bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01044c1:	83 c4 1c             	add    $0x1c,%esp
f01044c4:	5b                   	pop    %ebx
f01044c5:	5e                   	pop    %esi
f01044c6:	5f                   	pop    %edi
f01044c7:	5d                   	pop    %ebp
f01044c8:	c3                   	ret    
f01044c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01044d0:	85 ff                	test   %edi,%edi
f01044d2:	89 fd                	mov    %edi,%ebp
f01044d4:	75 0b                	jne    f01044e1 <__umoddi3+0x91>
f01044d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01044db:	31 d2                	xor    %edx,%edx
f01044dd:	f7 f7                	div    %edi
f01044df:	89 c5                	mov    %eax,%ebp
f01044e1:	89 f0                	mov    %esi,%eax
f01044e3:	31 d2                	xor    %edx,%edx
f01044e5:	f7 f5                	div    %ebp
f01044e7:	89 c8                	mov    %ecx,%eax
f01044e9:	f7 f5                	div    %ebp
f01044eb:	89 d0                	mov    %edx,%eax
f01044ed:	eb 99                	jmp    f0104488 <__umoddi3+0x38>
f01044ef:	90                   	nop
f01044f0:	89 c8                	mov    %ecx,%eax
f01044f2:	89 f2                	mov    %esi,%edx
f01044f4:	83 c4 1c             	add    $0x1c,%esp
f01044f7:	5b                   	pop    %ebx
f01044f8:	5e                   	pop    %esi
f01044f9:	5f                   	pop    %edi
f01044fa:	5d                   	pop    %ebp
f01044fb:	c3                   	ret    
f01044fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104500:	8b 34 24             	mov    (%esp),%esi
f0104503:	bf 20 00 00 00       	mov    $0x20,%edi
f0104508:	89 e9                	mov    %ebp,%ecx
f010450a:	29 ef                	sub    %ebp,%edi
f010450c:	d3 e0                	shl    %cl,%eax
f010450e:	89 f9                	mov    %edi,%ecx
f0104510:	89 f2                	mov    %esi,%edx
f0104512:	d3 ea                	shr    %cl,%edx
f0104514:	89 e9                	mov    %ebp,%ecx
f0104516:	09 c2                	or     %eax,%edx
f0104518:	89 d8                	mov    %ebx,%eax
f010451a:	89 14 24             	mov    %edx,(%esp)
f010451d:	89 f2                	mov    %esi,%edx
f010451f:	d3 e2                	shl    %cl,%edx
f0104521:	89 f9                	mov    %edi,%ecx
f0104523:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104527:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010452b:	d3 e8                	shr    %cl,%eax
f010452d:	89 e9                	mov    %ebp,%ecx
f010452f:	89 c6                	mov    %eax,%esi
f0104531:	d3 e3                	shl    %cl,%ebx
f0104533:	89 f9                	mov    %edi,%ecx
f0104535:	89 d0                	mov    %edx,%eax
f0104537:	d3 e8                	shr    %cl,%eax
f0104539:	89 e9                	mov    %ebp,%ecx
f010453b:	09 d8                	or     %ebx,%eax
f010453d:	89 d3                	mov    %edx,%ebx
f010453f:	89 f2                	mov    %esi,%edx
f0104541:	f7 34 24             	divl   (%esp)
f0104544:	89 d6                	mov    %edx,%esi
f0104546:	d3 e3                	shl    %cl,%ebx
f0104548:	f7 64 24 04          	mull   0x4(%esp)
f010454c:	39 d6                	cmp    %edx,%esi
f010454e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104552:	89 d1                	mov    %edx,%ecx
f0104554:	89 c3                	mov    %eax,%ebx
f0104556:	72 08                	jb     f0104560 <__umoddi3+0x110>
f0104558:	75 11                	jne    f010456b <__umoddi3+0x11b>
f010455a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010455e:	73 0b                	jae    f010456b <__umoddi3+0x11b>
f0104560:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104564:	1b 14 24             	sbb    (%esp),%edx
f0104567:	89 d1                	mov    %edx,%ecx
f0104569:	89 c3                	mov    %eax,%ebx
f010456b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010456f:	29 da                	sub    %ebx,%edx
f0104571:	19 ce                	sbb    %ecx,%esi
f0104573:	89 f9                	mov    %edi,%ecx
f0104575:	89 f0                	mov    %esi,%eax
f0104577:	d3 e0                	shl    %cl,%eax
f0104579:	89 e9                	mov    %ebp,%ecx
f010457b:	d3 ea                	shr    %cl,%edx
f010457d:	89 e9                	mov    %ebp,%ecx
f010457f:	d3 ee                	shr    %cl,%esi
f0104581:	09 d0                	or     %edx,%eax
f0104583:	89 f2                	mov    %esi,%edx
f0104585:	83 c4 1c             	add    $0x1c,%esp
f0104588:	5b                   	pop    %ebx
f0104589:	5e                   	pop    %esi
f010458a:	5f                   	pop    %edi
f010458b:	5d                   	pop    %ebp
f010458c:	c3                   	ret    
f010458d:	8d 76 00             	lea    0x0(%esi),%esi
f0104590:	29 f9                	sub    %edi,%ecx
f0104592:	19 d6                	sbb    %edx,%esi
f0104594:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104598:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010459c:	e9 18 ff ff ff       	jmp    f01044b9 <__umoddi3+0x69>
