
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

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
f0100046:	b8 10 db 17 f0       	mov    $0xf017db10,%eax
f010004b:	2d ee cb 17 f0       	sub    $0xf017cbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee cb 17 f0       	push   $0xf017cbee
f0100058:	e8 20 43 00 00       	call   f010437d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 48 10 f0       	push   $0xf0104820
f010006f:	e8 2a 2f 00 00       	call   f0102f9e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 db 0f 00 00       	call   f0101054 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 6f 29 00 00       	call   f01029ed <env_init>
	trap_init();
f010007e:	e8 95 2f 00 00       	call   f0103018 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 7e 1b 13 f0       	push   $0xf0131b7e
f010008d:	e8 21 2b 00 00       	call   f0102bb3 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 4c ce 17 f0    	pushl  0xf017ce4c
f010009b:	e8 37 2e 00 00       	call   f0102ed7 <env_run>

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
f01000a8:	83 3d 00 db 17 f0 00 	cmpl   $0x0,0xf017db00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 db 17 f0    	mov    %esi,0xf017db00

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
f01000c5:	68 3b 48 10 f0       	push   $0xf010483b
f01000ca:	e8 cf 2e 00 00       	call   f0102f9e <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 9f 2e 00 00       	call   f0102f78 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 8a 50 10 f0 	movl   $0xf010508a,(%esp)
f01000e0:	e8 b9 2e 00 00       	call   f0102f9e <cprintf>
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
f0100107:	68 53 48 10 f0       	push   $0xf0104853
f010010c:	e8 8d 2e 00 00       	call   f0102f9e <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 5b 2e 00 00       	call   f0102f78 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 8a 50 10 f0 	movl   $0xf010508a,(%esp)
f0100124:	e8 75 2e 00 00       	call   f0102f9e <cprintf>
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
f010015f:	8b 0d 24 ce 17 f0    	mov    0xf017ce24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 ce 17 f0    	mov    %edx,0xf017ce24
f010016e:	88 81 20 cc 17 f0    	mov    %al,-0xfe833e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 ce 17 f0 00 	movl   $0x0,0xf017ce24
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
f01001b5:	83 0d 00 cc 17 f0 40 	orl    $0x40,0xf017cc00
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
f01001cd:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 c0 49 10 f0 	movzbl -0xfefb640(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 00 cc 17 f0    	mov    %ecx,0xf017cc00
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 c0 49 10 f0 	movzbl -0xfefb640(%edx),%eax
f0100226:	0b 05 00 cc 17 f0    	or     0xf017cc00,%eax
f010022c:	0f b6 8a c0 48 10 f0 	movzbl -0xfefb740(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d a0 48 10 f0 	mov    -0xfefb760(,%ecx,4),%ecx
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
f010027d:	68 6d 48 10 f0       	push   $0xf010486d
f0100282:	e8 17 2d 00 00       	call   f0102f9e <cprintf>
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
f0100369:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 28 ce 17 f0 	addw   $0x50,0xf017ce28
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
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
f01003f3:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 28 ce 17 f0 	mov    %dx,0xf017ce28
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 28 ce 17 f0 	cmpw   $0x7cf,0xf017ce28
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 2c ce 17 f0       	mov    0xf017ce2c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 94 3f 00 00       	call   f01043ca <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
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
f0100457:	66 83 2d 28 ce 17 f0 	subw   $0x50,0xf017ce28
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 30 ce 17 f0    	mov    0xf017ce30,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 28 ce 17 f0 	movzwl 0xf017ce28,%ebx
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
f0100495:	80 3d 34 ce 17 f0 00 	cmpb   $0x0,0xf017ce34
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
f01004d3:	a1 20 ce 17 f0       	mov    0xf017ce20,%eax
f01004d8:	3b 05 24 ce 17 f0    	cmp    0xf017ce24,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 20 ce 17 f0    	mov    %edx,0xf017ce20
f01004e9:	0f b6 88 20 cc 17 f0 	movzbl -0xfe833e0(%eax),%ecx
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
f01004fa:	c7 05 20 ce 17 f0 00 	movl   $0x0,0xf017ce20
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
f0100533:	c7 05 30 ce 17 f0 b4 	movl   $0x3b4,0xf017ce30
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
f010054b:	c7 05 30 ce 17 f0 d4 	movl   $0x3d4,0xf017ce30
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
f010055a:	8b 3d 30 ce 17 f0    	mov    0xf017ce30,%edi
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
f010057f:	89 35 2c ce 17 f0    	mov    %esi,0xf017ce2c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
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
f01005eb:	0f 95 05 34 ce 17 f0 	setne  0xf017ce34
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
f0100600:	68 79 48 10 f0       	push   $0xf0104879
f0100605:	e8 94 29 00 00       	call   f0102f9e <cprintf>
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
f0100646:	68 c0 4a 10 f0       	push   $0xf0104ac0
f010064b:	68 de 4a 10 f0       	push   $0xf0104ade
f0100650:	68 e3 4a 10 f0       	push   $0xf0104ae3
f0100655:	e8 44 29 00 00       	call   f0102f9e <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100662:	68 ec 4a 10 f0       	push   $0xf0104aec
f0100667:	68 e3 4a 10 f0       	push   $0xf0104ae3
f010066c:	e8 2d 29 00 00       	call   f0102f9e <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 f5 4a 10 f0       	push   $0xf0104af5
f0100679:	68 06 4b 10 f0       	push   $0xf0104b06
f010067e:	68 e3 4a 10 f0       	push   $0xf0104ae3
f0100683:	e8 16 29 00 00       	call   f0102f9e <cprintf>
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
f0100695:	68 10 4b 10 f0       	push   $0xf0104b10
f010069a:	e8 ff 28 00 00       	call   f0102f9e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 b4 4b 10 f0       	push   $0xf0104bb4
f01006ac:	e8 ed 28 00 00       	call   f0102f9e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 dc 4b 10 f0       	push   $0xf0104bdc
f01006c3:	e8 d6 28 00 00       	call   f0102f9e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 01 48 10 00       	push   $0x104801
f01006d0:	68 01 48 10 f0       	push   $0xf0104801
f01006d5:	68 00 4c 10 f0       	push   $0xf0104c00
f01006da:	e8 bf 28 00 00       	call   f0102f9e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 ee cb 17 00       	push   $0x17cbee
f01006e7:	68 ee cb 17 f0       	push   $0xf017cbee
f01006ec:	68 24 4c 10 f0       	push   $0xf0104c24
f01006f1:	e8 a8 28 00 00       	call   f0102f9e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 10 db 17 00       	push   $0x17db10
f01006fe:	68 10 db 17 f0       	push   $0xf017db10
f0100703:	68 48 4c 10 f0       	push   $0xf0104c48
f0100708:	e8 91 28 00 00       	call   f0102f9e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 0f df 17 f0       	mov    $0xf017df0f,%eax
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
f010072e:	68 6c 4c 10 f0       	push   $0xf0104c6c
f0100733:	e8 66 28 00 00       	call   f0102f9e <cprintf>
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
f0100749:	68 29 4b 10 f0       	push   $0xf0104b29
f010074e:	e8 4b 28 00 00       	call   f0102f9e <cprintf>
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
f010076e:	68 98 4c 10 f0       	push   $0xf0104c98
f0100773:	e8 26 28 00 00       	call   f0102f9e <cprintf>
		debuginfo_eip(*(p+1), &info);
f0100778:	83 c4 18             	add    $0x18,%esp
f010077b:	56                   	push   %esi
f010077c:	ff 73 04             	pushl  0x4(%ebx)
f010077f:	e8 29 31 00 00       	call   f01038ad <debuginfo_eip>
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
f0100784:	83 c4 08             	add    $0x8,%esp
f0100787:	8b 43 04             	mov    0x4(%ebx),%eax
f010078a:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010078d:	50                   	push   %eax
f010078e:	ff 75 e8             	pushl  -0x18(%ebp)
f0100791:	ff 75 ec             	pushl  -0x14(%ebp)
f0100794:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100797:	ff 75 e0             	pushl  -0x20(%ebp)
f010079a:	68 3b 4b 10 f0       	push   $0xf0104b3b
f010079f:	e8 fa 27 00 00       	call   f0102f9e <cprintf>
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
f01007c2:	68 cc 4c 10 f0       	push   $0xf0104ccc
f01007c7:	e8 d2 27 00 00       	call   f0102f9e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cc:	c7 04 24 f0 4c 10 f0 	movl   $0xf0104cf0,(%esp)
f01007d3:	e8 c6 27 00 00       	call   f0102f9e <cprintf>

	if (tf != NULL)
f01007d8:	83 c4 10             	add    $0x10,%esp
f01007db:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007df:	74 0e                	je     f01007ef <monitor+0x36>
		print_trapframe(tf);
f01007e1:	83 ec 0c             	sub    $0xc,%esp
f01007e4:	ff 75 08             	pushl  0x8(%ebp)
f01007e7:	e8 74 2b 00 00       	call   f0103360 <print_trapframe>
f01007ec:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007ef:	83 ec 0c             	sub    $0xc,%esp
f01007f2:	68 4d 4b 10 f0       	push   $0xf0104b4d
f01007f7:	e8 2a 39 00 00       	call   f0104126 <readline>
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
f010082b:	68 51 4b 10 f0       	push   $0xf0104b51
f0100830:	e8 0b 3b 00 00       	call   f0104340 <strchr>
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
f010084b:	68 56 4b 10 f0       	push   $0xf0104b56
f0100850:	e8 49 27 00 00       	call   f0102f9e <cprintf>
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
f0100874:	68 51 4b 10 f0       	push   $0xf0104b51
f0100879:	e8 c2 3a 00 00       	call   f0104340 <strchr>
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
f01008a2:	ff 34 85 20 4d 10 f0 	pushl  -0xfefb2e0(,%eax,4)
f01008a9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ac:	e8 31 3a 00 00       	call   f01042e2 <strcmp>
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
f01008c6:	ff 14 85 28 4d 10 f0 	call   *-0xfefb2d8(,%eax,4)
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
f01008e7:	68 73 4b 10 f0       	push   $0xf0104b73
f01008ec:	e8 ad 26 00 00       	call   f0102f9e <cprintf>
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
f010090a:	83 3d 38 ce 17 f0 00 	cmpl   $0x0,0xf017ce38
f0100911:	75 0f                	jne    f0100922 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100913:	b8 0f eb 17 f0       	mov    $0xf017eb0f,%eax
f0100918:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010091d:	a3 38 ce 17 f0       	mov    %eax,0xf017ce38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	cprintf("boot_alloc memory at %x\n", nextfree);
f0100922:	83 ec 08             	sub    $0x8,%esp
f0100925:	ff 35 38 ce 17 f0    	pushl  0xf017ce38
f010092b:	68 44 4d 10 f0       	push   $0xf0104d44
f0100930:	e8 69 26 00 00       	call   f0102f9e <cprintf>
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f0100935:	89 d8                	mov    %ebx,%eax
f0100937:	03 05 38 ce 17 f0    	add    0xf017ce38,%eax
f010093d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100942:	83 c4 08             	add    $0x8,%esp
f0100945:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010094a:	50                   	push   %eax
f010094b:	68 5d 4d 10 f0       	push   $0xf0104d5d
f0100950:	e8 49 26 00 00       	call   f0102f9e <cprintf>
	if (n != 0) {
f0100955:	83 c4 10             	add    $0x10,%esp
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;
f0100958:	a1 38 ce 17 f0       	mov    0xf017ce38,%eax
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
f010096e:	89 15 38 ce 17 f0    	mov    %edx,0xf017ce38
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
f010098f:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
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
f010099e:	68 e4 50 10 f0       	push   $0xf01050e4
f01009a3:	68 26 03 00 00       	push   $0x326
f01009a8:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01009f6:	68 08 51 10 f0       	push   $0xf0105108
f01009fb:	68 60 02 00 00       	push   $0x260
f0100a00:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100a18:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
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
f0100a4e:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
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
f0100a58:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100a5e:	eb 53                	jmp    f0100ab3 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a60:	89 d8                	mov    %ebx,%eax
f0100a62:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
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
f0100a7c:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100a82:	72 12                	jb     f0100a96 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a84:	50                   	push   %eax
f0100a85:	68 e4 50 10 f0       	push   $0xf01050e4
f0100a8a:	6a 56                	push   $0x56
f0100a8c:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0100a91:	e8 0a f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a96:	83 ec 04             	sub    $0x4,%esp
f0100a99:	68 80 00 00 00       	push   $0x80
f0100a9e:	68 97 00 00 00       	push   $0x97
f0100aa3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aa8:	50                   	push   %eax
f0100aa9:	e8 cf 38 00 00       	call   f010437d <memset>
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
f0100ac4:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aca:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
		assert(pp < pages + npages);
f0100ad0:	a1 04 db 17 f0       	mov    0xf017db04,%eax
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
f0100aef:	68 8a 4d 10 f0       	push   $0xf0104d8a
f0100af4:	68 96 4d 10 f0       	push   $0xf0104d96
f0100af9:	68 7a 02 00 00       	push   $0x27a
f0100afe:	68 70 4d 10 f0       	push   $0xf0104d70
f0100b03:	e8 98 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b08:	39 fa                	cmp    %edi,%edx
f0100b0a:	72 19                	jb     f0100b25 <check_page_free_list+0x148>
f0100b0c:	68 ab 4d 10 f0       	push   $0xf0104dab
f0100b11:	68 96 4d 10 f0       	push   $0xf0104d96
f0100b16:	68 7b 02 00 00       	push   $0x27b
f0100b1b:	68 70 4d 10 f0       	push   $0xf0104d70
f0100b20:	e8 7b f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b25:	89 d0                	mov    %edx,%eax
f0100b27:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b2a:	a8 07                	test   $0x7,%al
f0100b2c:	74 19                	je     f0100b47 <check_page_free_list+0x16a>
f0100b2e:	68 2c 51 10 f0       	push   $0xf010512c
f0100b33:	68 96 4d 10 f0       	push   $0xf0104d96
f0100b38:	68 7c 02 00 00       	push   $0x27c
f0100b3d:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100b51:	68 bf 4d 10 f0       	push   $0xf0104dbf
f0100b56:	68 96 4d 10 f0       	push   $0xf0104d96
f0100b5b:	68 7f 02 00 00       	push   $0x27f
f0100b60:	68 70 4d 10 f0       	push   $0xf0104d70
f0100b65:	e8 36 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b6a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b6f:	75 19                	jne    f0100b8a <check_page_free_list+0x1ad>
f0100b71:	68 d0 4d 10 f0       	push   $0xf0104dd0
f0100b76:	68 96 4d 10 f0       	push   $0xf0104d96
f0100b7b:	68 80 02 00 00       	push   $0x280
f0100b80:	68 70 4d 10 f0       	push   $0xf0104d70
f0100b85:	e8 16 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b8a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b8f:	75 19                	jne    f0100baa <check_page_free_list+0x1cd>
f0100b91:	68 60 51 10 f0       	push   $0xf0105160
f0100b96:	68 96 4d 10 f0       	push   $0xf0104d96
f0100b9b:	68 81 02 00 00       	push   $0x281
f0100ba0:	68 70 4d 10 f0       	push   $0xf0104d70
f0100ba5:	e8 f6 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100baa:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100baf:	75 19                	jne    f0100bca <check_page_free_list+0x1ed>
f0100bb1:	68 e9 4d 10 f0       	push   $0xf0104de9
f0100bb6:	68 96 4d 10 f0       	push   $0xf0104d96
f0100bbb:	68 82 02 00 00       	push   $0x282
f0100bc0:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100bdc:	68 e4 50 10 f0       	push   $0xf01050e4
f0100be1:	6a 56                	push   $0x56
f0100be3:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0100be8:	e8 b3 f4 ff ff       	call   f01000a0 <_panic>
f0100bed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bf2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bf5:	76 1e                	jbe    f0100c15 <check_page_free_list+0x238>
f0100bf7:	68 84 51 10 f0       	push   $0xf0105184
f0100bfc:	68 96 4d 10 f0       	push   $0xf0104d96
f0100c01:	68 85 02 00 00       	push   $0x285
f0100c06:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100c2a:	68 03 4e 10 f0       	push   $0xf0104e03
f0100c2f:	68 96 4d 10 f0       	push   $0xf0104d96
f0100c34:	68 8d 02 00 00       	push   $0x28d
f0100c39:	68 70 4d 10 f0       	push   $0xf0104d70
f0100c3e:	e8 5d f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c43:	85 db                	test   %ebx,%ebx
f0100c45:	7f 19                	jg     f0100c60 <check_page_free_list+0x283>
f0100c47:	68 15 4e 10 f0       	push   $0xf0104e15
f0100c4c:	68 96 4d 10 f0       	push   $0xf0104d96
f0100c51:	68 8e 02 00 00       	push   $0x28e
f0100c56:	68 70 4d 10 f0       	push   $0xf0104d70
f0100c5b:	e8 40 f4 ff ff       	call   f01000a0 <_panic>
	cprintf("check_page_free_list done\n");
f0100c60:	83 ec 0c             	sub    $0xc,%esp
f0100c63:	68 26 4e 10 f0       	push   $0xf0104e26
f0100c68:	e8 31 23 00 00       	call   f0102f9e <cprintf>
}
f0100c6d:	eb 29                	jmp    f0100c98 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c6f:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0100c74:	85 c0                	test   %eax,%eax
f0100c76:	0f 85 8e fd ff ff    	jne    f0100a0a <check_page_free_list+0x2d>
f0100c7c:	e9 72 fd ff ff       	jmp    f01009f3 <check_page_free_list+0x16>
f0100c81:	83 3d 40 ce 17 f0 00 	cmpl   $0x0,0xf017ce40
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
f0100ca5:	8b 35 44 ce 17 f0    	mov    0xf017ce44,%esi
f0100cab:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100cb1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cbb:	eb 27                	jmp    f0100ce4 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100cbd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cc4:	89 d1                	mov    %edx,%ecx
f0100cc6:	03 0d 0c db 17 f0    	add    0xf017db0c,%ecx
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
f0100cd9:	03 1d 0c db 17 f0    	add    0xf017db0c,%ebx
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
f0100cec:	89 1d 40 ce 17 f0    	mov    %ebx,0xf017ce40
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - 0xf0000000, PGSIZE)/PGSIZE;
f0100cf2:	8b 15 4c ce 17 f0    	mov    0xf017ce4c,%edx
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
f0100d1d:	68 ae 50 10 f0       	push   $0xf01050ae
f0100d22:	e8 77 22 00 00       	call   f0102f9e <cprintf>
	cprintf("med=%d\n", med);
f0100d27:	83 c4 08             	add    $0x8,%esp
f0100d2a:	53                   	push   %ebx
f0100d2b:	68 41 4e 10 f0       	push   $0xf0104e41
f0100d30:	e8 69 22 00 00       	call   f0102f9e <cprintf>
	for (i = med; i < npages; i++) {
f0100d35:	89 da                	mov    %ebx,%edx
f0100d37:	8b 35 40 ce 17 f0    	mov    0xf017ce40,%esi
f0100d3d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100d44:	83 c4 10             	add    $0x10,%esp
f0100d47:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d4c:	eb 23                	jmp    f0100d71 <page_init+0xd1>
		pages[i].pp_ref = 0;
f0100d4e:	89 c1                	mov    %eax,%ecx
f0100d50:	03 0d 0c db 17 f0    	add    0xf017db0c,%ecx
f0100d56:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d5c:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0100d5e:	89 c6                	mov    %eax,%esi
f0100d60:	03 35 0c db 17 f0    	add    0xf017db0c,%esi
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)envs) + (sizeof(struct Env) * NENV) - 0xf0000000, PGSIZE)/PGSIZE;
	cprintf("%x\n", ((char*)envs) + (sizeof(struct Env) * NENV));
	cprintf("med=%d\n", med);
	for (i = med; i < npages; i++) {
f0100d66:	83 c2 01             	add    $0x1,%edx
f0100d69:	83 c0 08             	add    $0x8,%eax
f0100d6c:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100d71:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100d77:	72 d5                	jb     f0100d4e <page_init+0xae>
f0100d79:	84 c9                	test   %cl,%cl
f0100d7b:	74 06                	je     f0100d83 <page_init+0xe3>
f0100d7d:	89 35 40 ce 17 f0    	mov    %esi,0xf017ce40
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
f0100d91:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100d97:	85 db                	test   %ebx,%ebx
f0100d99:	74 52                	je     f0100ded <page_alloc+0x63>
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d9b:	8b 03                	mov    (%ebx),%eax
f0100d9d:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
		if (alloc_flags & ALLOC_ZERO) 
f0100da2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100da6:	74 45                	je     f0100ded <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da8:	89 d8                	mov    %ebx,%eax
f0100daa:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100db0:	c1 f8 03             	sar    $0x3,%eax
f0100db3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db6:	89 c2                	mov    %eax,%edx
f0100db8:	c1 ea 0c             	shr    $0xc,%edx
f0100dbb:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100dc1:	72 12                	jb     f0100dd5 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc3:	50                   	push   %eax
f0100dc4:	68 e4 50 10 f0       	push   $0xf01050e4
f0100dc9:	6a 56                	push   $0x56
f0100dcb:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0100dd0:	e8 cb f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100dd5:	83 ec 04             	sub    $0x4,%esp
f0100dd8:	68 00 10 00 00       	push   $0x1000
f0100ddd:	6a 00                	push   $0x0
f0100ddf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100de4:	50                   	push   %eax
f0100de5:	e8 93 35 00 00       	call   f010437d <memset>
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
f0100dfa:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
f0100e00:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e02:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
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
f0100e67:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
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
f0100e84:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100e8a:	72 15                	jb     f0100ea1 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e8c:	50                   	push   %eax
f0100e8d:	68 e4 50 10 f0       	push   $0xf01050e4
f0100e92:	68 8b 01 00 00       	push   $0x18b
f0100e97:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100ed1:	68 cc 51 10 f0       	push   $0xf01051cc
f0100ed6:	e8 c3 20 00 00       	call   f0102f9e <cprintf>
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
f0100f14:	68 00 52 10 f0       	push   $0xf0105200
f0100f19:	68 a9 01 00 00       	push   $0x1a9
f0100f1e:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0100f73:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0100f79:	72 14                	jb     f0100f8f <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100f7b:	83 ec 04             	sub    $0x4,%esp
f0100f7e:	68 28 52 10 f0       	push   $0xf0105228
f0100f83:	6a 4f                	push   $0x4f
f0100f85:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0100f8a:	e8 11 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f8f:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
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
f010102a:	2b 1d 0c db 17 f0    	sub    0xf017db0c,%ebx
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
f010105f:	e8 d3 1e 00 00       	call   f0102f37 <mc146818_read>
f0101064:	89 c3                	mov    %eax,%ebx
f0101066:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010106d:	e8 c5 1e 00 00       	call   f0102f37 <mc146818_read>
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
f0101088:	a3 44 ce 17 f0       	mov    %eax,0xf017ce44
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010108d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101094:	e8 9e 1e 00 00       	call   f0102f37 <mc146818_read>
f0101099:	89 c3                	mov    %eax,%ebx
f010109b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010a2:	e8 90 1e 00 00       	call   f0102f37 <mc146818_read>
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
f01010ca:	89 15 04 db 17 f0    	mov    %edx,0xf017db04
f01010d0:	eb 0c                	jmp    f01010de <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010d2:	8b 15 44 ce 17 f0    	mov    0xf017ce44,%edx
f01010d8:	89 15 04 db 17 f0    	mov    %edx,0xf017db04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010de:	c1 e0 0c             	shl    $0xc,%eax
f01010e1:	c1 e8 0a             	shr    $0xa,%eax
f01010e4:	50                   	push   %eax
f01010e5:	a1 44 ce 17 f0       	mov    0xf017ce44,%eax
f01010ea:	c1 e0 0c             	shl    $0xc,%eax
f01010ed:	c1 e8 0a             	shr    $0xa,%eax
f01010f0:	50                   	push   %eax
f01010f1:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f01010f6:	c1 e0 0c             	shl    $0xc,%eax
f01010f9:	c1 e8 0a             	shr    $0xa,%eax
f01010fc:	50                   	push   %eax
f01010fd:	68 48 52 10 f0       	push   $0xf0105248
f0101102:	e8 97 1e 00 00       	call   f0102f9e <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101107:	b8 00 10 00 00       	mov    $0x1000,%eax
f010110c:	e8 f0 f7 ff ff       	call   f0100901 <boot_alloc>
f0101111:	a3 08 db 17 f0       	mov    %eax,0xf017db08
	memset(kern_pgdir, 0, PGSIZE);
f0101116:	83 c4 0c             	add    $0xc,%esp
f0101119:	68 00 10 00 00       	push   $0x1000
f010111e:	6a 00                	push   $0x0
f0101120:	50                   	push   %eax
f0101121:	e8 57 32 00 00       	call   f010437d <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101126:	a1 08 db 17 f0       	mov    0xf017db08,%eax
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
f0101136:	68 84 52 10 f0       	push   $0xf0105284
f010113b:	68 93 00 00 00       	push   $0x93
f0101140:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101159:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010115e:	c1 e0 03             	shl    $0x3,%eax
f0101161:	e8 9b f7 ff ff       	call   f0100901 <boot_alloc>
f0101166:	a3 0c db 17 f0       	mov    %eax,0xf017db0c

	cprintf("npages: %d\n", npages);
f010116b:	83 ec 08             	sub    $0x8,%esp
f010116e:	ff 35 04 db 17 f0    	pushl  0xf017db04
f0101174:	68 49 4e 10 f0       	push   $0xf0104e49
f0101179:	e8 20 1e 00 00       	call   f0102f9e <cprintf>
	cprintf("npages_basemem: %d\n", npages_basemem);
f010117e:	83 c4 08             	add    $0x8,%esp
f0101181:	ff 35 44 ce 17 f0    	pushl  0xf017ce44
f0101187:	68 55 4e 10 f0       	push   $0xf0104e55
f010118c:	e8 0d 1e 00 00       	call   f0102f9e <cprintf>
	cprintf("pages: %x\n", pages);
f0101191:	83 c4 08             	add    $0x8,%esp
f0101194:	ff 35 0c db 17 f0    	pushl  0xf017db0c
f010119a:	68 69 4e 10 f0       	push   $0xf0104e69
f010119f:	e8 fa 1d 00 00       	call   f0102f9e <cprintf>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f01011a4:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011a9:	e8 53 f7 ff ff       	call   f0100901 <boot_alloc>
f01011ae:	a3 4c ce 17 f0       	mov    %eax,0xf017ce4c
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
f01011c5:	83 3d 0c db 17 f0 00 	cmpl   $0x0,0xf017db0c
f01011cc:	75 17                	jne    f01011e5 <mem_init+0x191>
		panic("'pages' is a null pointer!");
f01011ce:	83 ec 04             	sub    $0x4,%esp
f01011d1:	68 74 4e 10 f0       	push   $0xf0104e74
f01011d6:	68 a0 02 00 00       	push   $0x2a0
f01011db:	68 70 4d 10 f0       	push   $0xf0104d70
f01011e0:	e8 bb ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e5:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
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
f010120d:	68 8f 4e 10 f0       	push   $0xf0104e8f
f0101212:	68 96 4d 10 f0       	push   $0xf0104d96
f0101217:	68 a8 02 00 00       	push   $0x2a8
f010121c:	68 70 4d 10 f0       	push   $0xf0104d70
f0101221:	e8 7a ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101226:	83 ec 0c             	sub    $0xc,%esp
f0101229:	6a 00                	push   $0x0
f010122b:	e8 5a fb ff ff       	call   f0100d8a <page_alloc>
f0101230:	89 c6                	mov    %eax,%esi
f0101232:	83 c4 10             	add    $0x10,%esp
f0101235:	85 c0                	test   %eax,%eax
f0101237:	75 19                	jne    f0101252 <mem_init+0x1fe>
f0101239:	68 a5 4e 10 f0       	push   $0xf0104ea5
f010123e:	68 96 4d 10 f0       	push   $0xf0104d96
f0101243:	68 a9 02 00 00       	push   $0x2a9
f0101248:	68 70 4d 10 f0       	push   $0xf0104d70
f010124d:	e8 4e ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101252:	83 ec 0c             	sub    $0xc,%esp
f0101255:	6a 00                	push   $0x0
f0101257:	e8 2e fb ff ff       	call   f0100d8a <page_alloc>
f010125c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010125f:	83 c4 10             	add    $0x10,%esp
f0101262:	85 c0                	test   %eax,%eax
f0101264:	75 19                	jne    f010127f <mem_init+0x22b>
f0101266:	68 bb 4e 10 f0       	push   $0xf0104ebb
f010126b:	68 96 4d 10 f0       	push   $0xf0104d96
f0101270:	68 aa 02 00 00       	push   $0x2aa
f0101275:	68 70 4d 10 f0       	push   $0xf0104d70
f010127a:	e8 21 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127f:	39 f7                	cmp    %esi,%edi
f0101281:	75 19                	jne    f010129c <mem_init+0x248>
f0101283:	68 d1 4e 10 f0       	push   $0xf0104ed1
f0101288:	68 96 4d 10 f0       	push   $0xf0104d96
f010128d:	68 ad 02 00 00       	push   $0x2ad
f0101292:	68 70 4d 10 f0       	push   $0xf0104d70
f0101297:	e8 04 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129f:	39 c6                	cmp    %eax,%esi
f01012a1:	74 04                	je     f01012a7 <mem_init+0x253>
f01012a3:	39 c7                	cmp    %eax,%edi
f01012a5:	75 19                	jne    f01012c0 <mem_init+0x26c>
f01012a7:	68 a8 52 10 f0       	push   $0xf01052a8
f01012ac:	68 96 4d 10 f0       	push   $0xf0104d96
f01012b1:	68 ae 02 00 00       	push   $0x2ae
f01012b6:	68 70 4d 10 f0       	push   $0xf0104d70
f01012bb:	e8 e0 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012c0:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012c6:	8b 15 04 db 17 f0    	mov    0xf017db04,%edx
f01012cc:	c1 e2 0c             	shl    $0xc,%edx
f01012cf:	89 f8                	mov    %edi,%eax
f01012d1:	29 c8                	sub    %ecx,%eax
f01012d3:	c1 f8 03             	sar    $0x3,%eax
f01012d6:	c1 e0 0c             	shl    $0xc,%eax
f01012d9:	39 d0                	cmp    %edx,%eax
f01012db:	72 19                	jb     f01012f6 <mem_init+0x2a2>
f01012dd:	68 e3 4e 10 f0       	push   $0xf0104ee3
f01012e2:	68 96 4d 10 f0       	push   $0xf0104d96
f01012e7:	68 af 02 00 00       	push   $0x2af
f01012ec:	68 70 4d 10 f0       	push   $0xf0104d70
f01012f1:	e8 aa ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012f6:	89 f0                	mov    %esi,%eax
f01012f8:	29 c8                	sub    %ecx,%eax
f01012fa:	c1 f8 03             	sar    $0x3,%eax
f01012fd:	c1 e0 0c             	shl    $0xc,%eax
f0101300:	39 c2                	cmp    %eax,%edx
f0101302:	77 19                	ja     f010131d <mem_init+0x2c9>
f0101304:	68 00 4f 10 f0       	push   $0xf0104f00
f0101309:	68 96 4d 10 f0       	push   $0xf0104d96
f010130e:	68 b0 02 00 00       	push   $0x2b0
f0101313:	68 70 4d 10 f0       	push   $0xf0104d70
f0101318:	e8 83 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010131d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101320:	29 c8                	sub    %ecx,%eax
f0101322:	c1 f8 03             	sar    $0x3,%eax
f0101325:	c1 e0 0c             	shl    $0xc,%eax
f0101328:	39 c2                	cmp    %eax,%edx
f010132a:	77 19                	ja     f0101345 <mem_init+0x2f1>
f010132c:	68 1d 4f 10 f0       	push   $0xf0104f1d
f0101331:	68 96 4d 10 f0       	push   $0xf0104d96
f0101336:	68 b1 02 00 00       	push   $0x2b1
f010133b:	68 70 4d 10 f0       	push   $0xf0104d70
f0101340:	e8 5b ed ff ff       	call   f01000a0 <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101345:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f010134a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010134d:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f0101354:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101357:	83 ec 0c             	sub    $0xc,%esp
f010135a:	6a 00                	push   $0x0
f010135c:	e8 29 fa ff ff       	call   f0100d8a <page_alloc>
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	74 19                	je     f0101381 <mem_init+0x32d>
f0101368:	68 3a 4f 10 f0       	push   $0xf0104f3a
f010136d:	68 96 4d 10 f0       	push   $0xf0104d96
f0101372:	68 b9 02 00 00       	push   $0x2b9
f0101377:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01013b2:	68 8f 4e 10 f0       	push   $0xf0104e8f
f01013b7:	68 96 4d 10 f0       	push   $0xf0104d96
f01013bc:	68 c0 02 00 00       	push   $0x2c0
f01013c1:	68 70 4d 10 f0       	push   $0xf0104d70
f01013c6:	e8 d5 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013cb:	83 ec 0c             	sub    $0xc,%esp
f01013ce:	6a 00                	push   $0x0
f01013d0:	e8 b5 f9 ff ff       	call   f0100d8a <page_alloc>
f01013d5:	89 c7                	mov    %eax,%edi
f01013d7:	83 c4 10             	add    $0x10,%esp
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	75 19                	jne    f01013f7 <mem_init+0x3a3>
f01013de:	68 a5 4e 10 f0       	push   $0xf0104ea5
f01013e3:	68 96 4d 10 f0       	push   $0xf0104d96
f01013e8:	68 c1 02 00 00       	push   $0x2c1
f01013ed:	68 70 4d 10 f0       	push   $0xf0104d70
f01013f2:	e8 a9 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f7:	83 ec 0c             	sub    $0xc,%esp
f01013fa:	6a 00                	push   $0x0
f01013fc:	e8 89 f9 ff ff       	call   f0100d8a <page_alloc>
f0101401:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101404:	83 c4 10             	add    $0x10,%esp
f0101407:	85 c0                	test   %eax,%eax
f0101409:	75 19                	jne    f0101424 <mem_init+0x3d0>
f010140b:	68 bb 4e 10 f0       	push   $0xf0104ebb
f0101410:	68 96 4d 10 f0       	push   $0xf0104d96
f0101415:	68 c2 02 00 00       	push   $0x2c2
f010141a:	68 70 4d 10 f0       	push   $0xf0104d70
f010141f:	e8 7c ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101424:	39 fe                	cmp    %edi,%esi
f0101426:	75 19                	jne    f0101441 <mem_init+0x3ed>
f0101428:	68 d1 4e 10 f0       	push   $0xf0104ed1
f010142d:	68 96 4d 10 f0       	push   $0xf0104d96
f0101432:	68 c4 02 00 00       	push   $0x2c4
f0101437:	68 70 4d 10 f0       	push   $0xf0104d70
f010143c:	e8 5f ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101441:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101444:	39 c7                	cmp    %eax,%edi
f0101446:	74 04                	je     f010144c <mem_init+0x3f8>
f0101448:	39 c6                	cmp    %eax,%esi
f010144a:	75 19                	jne    f0101465 <mem_init+0x411>
f010144c:	68 a8 52 10 f0       	push   $0xf01052a8
f0101451:	68 96 4d 10 f0       	push   $0xf0104d96
f0101456:	68 c5 02 00 00       	push   $0x2c5
f010145b:	68 70 4d 10 f0       	push   $0xf0104d70
f0101460:	e8 3b ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101465:	83 ec 0c             	sub    $0xc,%esp
f0101468:	6a 00                	push   $0x0
f010146a:	e8 1b f9 ff ff       	call   f0100d8a <page_alloc>
f010146f:	83 c4 10             	add    $0x10,%esp
f0101472:	85 c0                	test   %eax,%eax
f0101474:	74 19                	je     f010148f <mem_init+0x43b>
f0101476:	68 3a 4f 10 f0       	push   $0xf0104f3a
f010147b:	68 96 4d 10 f0       	push   $0xf0104d96
f0101480:	68 c6 02 00 00       	push   $0x2c6
f0101485:	68 70 4d 10 f0       	push   $0xf0104d70
f010148a:	e8 11 ec ff ff       	call   f01000a0 <_panic>
f010148f:	89 f0                	mov    %esi,%eax
f0101491:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101497:	c1 f8 03             	sar    $0x3,%eax
f010149a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149d:	89 c2                	mov    %eax,%edx
f010149f:	c1 ea 0c             	shr    $0xc,%edx
f01014a2:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01014a8:	72 12                	jb     f01014bc <mem_init+0x468>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014aa:	50                   	push   %eax
f01014ab:	68 e4 50 10 f0       	push   $0xf01050e4
f01014b0:	6a 56                	push   $0x56
f01014b2:	68 7c 4d 10 f0       	push   $0xf0104d7c
f01014b7:	e8 e4 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014bc:	83 ec 04             	sub    $0x4,%esp
f01014bf:	68 00 10 00 00       	push   $0x1000
f01014c4:	6a 01                	push   $0x1
f01014c6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014cb:	50                   	push   %eax
f01014cc:	e8 ac 2e 00 00       	call   f010437d <memset>
	page_free(pp0);
f01014d1:	89 34 24             	mov    %esi,(%esp)
f01014d4:	e8 1b f9 ff ff       	call   f0100df4 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014e0:	e8 a5 f8 ff ff       	call   f0100d8a <page_alloc>
f01014e5:	83 c4 10             	add    $0x10,%esp
f01014e8:	85 c0                	test   %eax,%eax
f01014ea:	75 19                	jne    f0101505 <mem_init+0x4b1>
f01014ec:	68 49 4f 10 f0       	push   $0xf0104f49
f01014f1:	68 96 4d 10 f0       	push   $0xf0104d96
f01014f6:	68 cb 02 00 00       	push   $0x2cb
f01014fb:	68 70 4d 10 f0       	push   $0xf0104d70
f0101500:	e8 9b eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101505:	39 c6                	cmp    %eax,%esi
f0101507:	74 19                	je     f0101522 <mem_init+0x4ce>
f0101509:	68 67 4f 10 f0       	push   $0xf0104f67
f010150e:	68 96 4d 10 f0       	push   $0xf0104d96
f0101513:	68 cc 02 00 00       	push   $0x2cc
f0101518:	68 70 4d 10 f0       	push   $0xf0104d70
f010151d:	e8 7e eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101522:	89 f0                	mov    %esi,%eax
f0101524:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f010152a:	c1 f8 03             	sar    $0x3,%eax
f010152d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101530:	89 c2                	mov    %eax,%edx
f0101532:	c1 ea 0c             	shr    $0xc,%edx
f0101535:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f010153b:	72 12                	jb     f010154f <mem_init+0x4fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010153d:	50                   	push   %eax
f010153e:	68 e4 50 10 f0       	push   $0xf01050e4
f0101543:	6a 56                	push   $0x56
f0101545:	68 7c 4d 10 f0       	push   $0xf0104d7c
f010154a:	e8 51 eb ff ff       	call   f01000a0 <_panic>
f010154f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101555:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010155b:	80 38 00             	cmpb   $0x0,(%eax)
f010155e:	74 19                	je     f0101579 <mem_init+0x525>
f0101560:	68 77 4f 10 f0       	push   $0xf0104f77
f0101565:	68 96 4d 10 f0       	push   $0xf0104d96
f010156a:	68 cf 02 00 00       	push   $0x2cf
f010156f:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101583:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40

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
f01015a4:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
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
f01015bb:	68 81 4f 10 f0       	push   $0xf0104f81
f01015c0:	68 96 4d 10 f0       	push   $0xf0104d96
f01015c5:	68 dc 02 00 00       	push   $0x2dc
f01015ca:	68 70 4d 10 f0       	push   $0xf0104d70
f01015cf:	e8 cc ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015d4:	83 ec 0c             	sub    $0xc,%esp
f01015d7:	68 c8 52 10 f0       	push   $0xf01052c8
f01015dc:	e8 bd 19 00 00       	call   f0102f9e <cprintf>
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	cprintf("so far so good\n");
f01015e1:	c7 04 24 8c 4f 10 f0 	movl   $0xf0104f8c,(%esp)
f01015e8:	e8 b1 19 00 00       	call   f0102f9e <cprintf>
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
f0101602:	68 8f 4e 10 f0       	push   $0xf0104e8f
f0101607:	68 96 4d 10 f0       	push   $0xf0104d96
f010160c:	68 3a 03 00 00       	push   $0x33a
f0101611:	68 70 4d 10 f0       	push   $0xf0104d70
f0101616:	e8 85 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	6a 00                	push   $0x0
f0101620:	e8 65 f7 ff ff       	call   f0100d8a <page_alloc>
f0101625:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101628:	83 c4 10             	add    $0x10,%esp
f010162b:	85 c0                	test   %eax,%eax
f010162d:	75 19                	jne    f0101648 <mem_init+0x5f4>
f010162f:	68 a5 4e 10 f0       	push   $0xf0104ea5
f0101634:	68 96 4d 10 f0       	push   $0xf0104d96
f0101639:	68 3b 03 00 00       	push   $0x33b
f010163e:	68 70 4d 10 f0       	push   $0xf0104d70
f0101643:	e8 58 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101648:	83 ec 0c             	sub    $0xc,%esp
f010164b:	6a 00                	push   $0x0
f010164d:	e8 38 f7 ff ff       	call   f0100d8a <page_alloc>
f0101652:	89 c3                	mov    %eax,%ebx
f0101654:	83 c4 10             	add    $0x10,%esp
f0101657:	85 c0                	test   %eax,%eax
f0101659:	75 19                	jne    f0101674 <mem_init+0x620>
f010165b:	68 bb 4e 10 f0       	push   $0xf0104ebb
f0101660:	68 96 4d 10 f0       	push   $0xf0104d96
f0101665:	68 3c 03 00 00       	push   $0x33c
f010166a:	68 70 4d 10 f0       	push   $0xf0104d70
f010166f:	e8 2c ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101674:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101677:	75 19                	jne    f0101692 <mem_init+0x63e>
f0101679:	68 d1 4e 10 f0       	push   $0xf0104ed1
f010167e:	68 96 4d 10 f0       	push   $0xf0104d96
f0101683:	68 3f 03 00 00       	push   $0x33f
f0101688:	68 70 4d 10 f0       	push   $0xf0104d70
f010168d:	e8 0e ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101692:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101695:	74 04                	je     f010169b <mem_init+0x647>
f0101697:	39 c6                	cmp    %eax,%esi
f0101699:	75 19                	jne    f01016b4 <mem_init+0x660>
f010169b:	68 a8 52 10 f0       	push   $0xf01052a8
f01016a0:	68 96 4d 10 f0       	push   $0xf0104d96
f01016a5:	68 40 03 00 00       	push   $0x340
f01016aa:	68 70 4d 10 f0       	push   $0xf0104d70
f01016af:	e8 ec e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016b4:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f01016b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016bc:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f01016c3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016c6:	83 ec 0c             	sub    $0xc,%esp
f01016c9:	6a 00                	push   $0x0
f01016cb:	e8 ba f6 ff ff       	call   f0100d8a <page_alloc>
f01016d0:	83 c4 10             	add    $0x10,%esp
f01016d3:	85 c0                	test   %eax,%eax
f01016d5:	74 19                	je     f01016f0 <mem_init+0x69c>
f01016d7:	68 3a 4f 10 f0       	push   $0xf0104f3a
f01016dc:	68 96 4d 10 f0       	push   $0xf0104d96
f01016e1:	68 47 03 00 00       	push   $0x347
f01016e6:	68 70 4d 10 f0       	push   $0xf0104d70
f01016eb:	e8 b0 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016f0:	83 ec 04             	sub    $0x4,%esp
f01016f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016f6:	50                   	push   %eax
f01016f7:	6a 00                	push   $0x0
f01016f9:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01016ff:	e8 41 f8 ff ff       	call   f0100f45 <page_lookup>
f0101704:	83 c4 10             	add    $0x10,%esp
f0101707:	85 c0                	test   %eax,%eax
f0101709:	74 19                	je     f0101724 <mem_init+0x6d0>
f010170b:	68 e8 52 10 f0       	push   $0xf01052e8
f0101710:	68 96 4d 10 f0       	push   $0xf0104d96
f0101715:	68 4a 03 00 00       	push   $0x34a
f010171a:	68 70 4d 10 f0       	push   $0xf0104d70
f010171f:	e8 7c e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101724:	6a 02                	push   $0x2
f0101726:	6a 00                	push   $0x0
f0101728:	ff 75 d4             	pushl  -0x2c(%ebp)
f010172b:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101731:	e8 b8 f8 ff ff       	call   f0100fee <page_insert>
f0101736:	83 c4 10             	add    $0x10,%esp
f0101739:	85 c0                	test   %eax,%eax
f010173b:	78 19                	js     f0101756 <mem_init+0x702>
f010173d:	68 20 53 10 f0       	push   $0xf0105320
f0101742:	68 96 4d 10 f0       	push   $0xf0104d96
f0101747:	68 4d 03 00 00       	push   $0x34d
f010174c:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101766:	ff 35 08 db 17 f0    	pushl  0xf017db08
f010176c:	e8 7d f8 ff ff       	call   f0100fee <page_insert>
f0101771:	83 c4 20             	add    $0x20,%esp
f0101774:	85 c0                	test   %eax,%eax
f0101776:	74 19                	je     f0101791 <mem_init+0x73d>
f0101778:	68 50 53 10 f0       	push   $0xf0105350
f010177d:	68 96 4d 10 f0       	push   $0xf0104d96
f0101782:	68 51 03 00 00       	push   $0x351
f0101787:	68 70 4d 10 f0       	push   $0xf0104d70
f010178c:	e8 0f e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101791:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101797:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
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
f01017b7:	68 80 53 10 f0       	push   $0xf0105380
f01017bc:	68 96 4d 10 f0       	push   $0xf0104d96
f01017c1:	68 52 03 00 00       	push   $0x352
f01017c6:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01017ec:	68 a8 53 10 f0       	push   $0xf01053a8
f01017f1:	68 96 4d 10 f0       	push   $0xf0104d96
f01017f6:	68 53 03 00 00       	push   $0x353
f01017fb:	68 70 4d 10 f0       	push   $0xf0104d70
f0101800:	e8 9b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101805:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101808:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010180d:	74 19                	je     f0101828 <mem_init+0x7d4>
f010180f:	68 9c 4f 10 f0       	push   $0xf0104f9c
f0101814:	68 96 4d 10 f0       	push   $0xf0104d96
f0101819:	68 54 03 00 00       	push   $0x354
f010181e:	68 70 4d 10 f0       	push   $0xf0104d70
f0101823:	e8 78 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101828:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010182d:	74 19                	je     f0101848 <mem_init+0x7f4>
f010182f:	68 ad 4f 10 f0       	push   $0xf0104fad
f0101834:	68 96 4d 10 f0       	push   $0xf0104d96
f0101839:	68 55 03 00 00       	push   $0x355
f010183e:	68 70 4d 10 f0       	push   $0xf0104d70
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
f010185d:	68 d8 53 10 f0       	push   $0xf01053d8
f0101862:	68 96 4d 10 f0       	push   $0xf0104d96
f0101867:	68 58 03 00 00       	push   $0x358
f010186c:	68 70 4d 10 f0       	push   $0xf0104d70
f0101871:	e8 2a e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101876:	ba 00 10 00 00       	mov    $0x1000,%edx
f010187b:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101880:	e8 f4 f0 ff ff       	call   f0100979 <check_va2pa>
f0101885:	89 da                	mov    %ebx,%edx
f0101887:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f010188d:	c1 fa 03             	sar    $0x3,%edx
f0101890:	c1 e2 0c             	shl    $0xc,%edx
f0101893:	39 d0                	cmp    %edx,%eax
f0101895:	74 19                	je     f01018b0 <mem_init+0x85c>
f0101897:	68 14 54 10 f0       	push   $0xf0105414
f010189c:	68 96 4d 10 f0       	push   $0xf0104d96
f01018a1:	68 59 03 00 00       	push   $0x359
f01018a6:	68 70 4d 10 f0       	push   $0xf0104d70
f01018ab:	e8 f0 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018b0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018b5:	74 19                	je     f01018d0 <mem_init+0x87c>
f01018b7:	68 be 4f 10 f0       	push   $0xf0104fbe
f01018bc:	68 96 4d 10 f0       	push   $0xf0104d96
f01018c1:	68 5a 03 00 00       	push   $0x35a
f01018c6:	68 70 4d 10 f0       	push   $0xf0104d70
f01018cb:	e8 d0 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018d0:	83 ec 0c             	sub    $0xc,%esp
f01018d3:	6a 00                	push   $0x0
f01018d5:	e8 b0 f4 ff ff       	call   f0100d8a <page_alloc>
f01018da:	83 c4 10             	add    $0x10,%esp
f01018dd:	85 c0                	test   %eax,%eax
f01018df:	74 19                	je     f01018fa <mem_init+0x8a6>
f01018e1:	68 3a 4f 10 f0       	push   $0xf0104f3a
f01018e6:	68 96 4d 10 f0       	push   $0xf0104d96
f01018eb:	68 5d 03 00 00       	push   $0x35d
f01018f0:	68 70 4d 10 f0       	push   $0xf0104d70
f01018f5:	e8 a6 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018fa:	6a 02                	push   $0x2
f01018fc:	68 00 10 00 00       	push   $0x1000
f0101901:	53                   	push   %ebx
f0101902:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101908:	e8 e1 f6 ff ff       	call   f0100fee <page_insert>
f010190d:	83 c4 10             	add    $0x10,%esp
f0101910:	85 c0                	test   %eax,%eax
f0101912:	74 19                	je     f010192d <mem_init+0x8d9>
f0101914:	68 d8 53 10 f0       	push   $0xf01053d8
f0101919:	68 96 4d 10 f0       	push   $0xf0104d96
f010191e:	68 60 03 00 00       	push   $0x360
f0101923:	68 70 4d 10 f0       	push   $0xf0104d70
f0101928:	e8 73 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010192d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101932:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101937:	e8 3d f0 ff ff       	call   f0100979 <check_va2pa>
f010193c:	89 da                	mov    %ebx,%edx
f010193e:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101944:	c1 fa 03             	sar    $0x3,%edx
f0101947:	c1 e2 0c             	shl    $0xc,%edx
f010194a:	39 d0                	cmp    %edx,%eax
f010194c:	74 19                	je     f0101967 <mem_init+0x913>
f010194e:	68 14 54 10 f0       	push   $0xf0105414
f0101953:	68 96 4d 10 f0       	push   $0xf0104d96
f0101958:	68 61 03 00 00       	push   $0x361
f010195d:	68 70 4d 10 f0       	push   $0xf0104d70
f0101962:	e8 39 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101967:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010196c:	74 19                	je     f0101987 <mem_init+0x933>
f010196e:	68 be 4f 10 f0       	push   $0xf0104fbe
f0101973:	68 96 4d 10 f0       	push   $0xf0104d96
f0101978:	68 62 03 00 00       	push   $0x362
f010197d:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101998:	68 3a 4f 10 f0       	push   $0xf0104f3a
f010199d:	68 96 4d 10 f0       	push   $0xf0104d96
f01019a2:	68 66 03 00 00       	push   $0x366
f01019a7:	68 70 4d 10 f0       	push   $0xf0104d70
f01019ac:	e8 ef e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019b1:	8b 15 08 db 17 f0    	mov    0xf017db08,%edx
f01019b7:	8b 02                	mov    (%edx),%eax
f01019b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019be:	89 c1                	mov    %eax,%ecx
f01019c0:	c1 e9 0c             	shr    $0xc,%ecx
f01019c3:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f01019c9:	72 15                	jb     f01019e0 <mem_init+0x98c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019cb:	50                   	push   %eax
f01019cc:	68 e4 50 10 f0       	push   $0xf01050e4
f01019d1:	68 69 03 00 00       	push   $0x369
f01019d6:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101a05:	68 44 54 10 f0       	push   $0xf0105444
f0101a0a:	68 96 4d 10 f0       	push   $0xf0104d96
f0101a0f:	68 6a 03 00 00       	push   $0x36a
f0101a14:	68 70 4d 10 f0       	push   $0xf0104d70
f0101a19:	e8 82 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a1e:	6a 06                	push   $0x6
f0101a20:	68 00 10 00 00       	push   $0x1000
f0101a25:	53                   	push   %ebx
f0101a26:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101a2c:	e8 bd f5 ff ff       	call   f0100fee <page_insert>
f0101a31:	83 c4 10             	add    $0x10,%esp
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	74 19                	je     f0101a51 <mem_init+0x9fd>
f0101a38:	68 84 54 10 f0       	push   $0xf0105484
f0101a3d:	68 96 4d 10 f0       	push   $0xf0104d96
f0101a42:	68 6d 03 00 00       	push   $0x36d
f0101a47:	68 70 4d 10 f0       	push   $0xf0104d70
f0101a4c:	e8 4f e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a51:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101a57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a5c:	89 f8                	mov    %edi,%eax
f0101a5e:	e8 16 ef ff ff       	call   f0100979 <check_va2pa>
f0101a63:	89 da                	mov    %ebx,%edx
f0101a65:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101a6b:	c1 fa 03             	sar    $0x3,%edx
f0101a6e:	c1 e2 0c             	shl    $0xc,%edx
f0101a71:	39 d0                	cmp    %edx,%eax
f0101a73:	74 19                	je     f0101a8e <mem_init+0xa3a>
f0101a75:	68 14 54 10 f0       	push   $0xf0105414
f0101a7a:	68 96 4d 10 f0       	push   $0xf0104d96
f0101a7f:	68 6e 03 00 00       	push   $0x36e
f0101a84:	68 70 4d 10 f0       	push   $0xf0104d70
f0101a89:	e8 12 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a8e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a93:	74 19                	je     f0101aae <mem_init+0xa5a>
f0101a95:	68 be 4f 10 f0       	push   $0xf0104fbe
f0101a9a:	68 96 4d 10 f0       	push   $0xf0104d96
f0101a9f:	68 6f 03 00 00       	push   $0x36f
f0101aa4:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101ac6:	68 c4 54 10 f0       	push   $0xf01054c4
f0101acb:	68 96 4d 10 f0       	push   $0xf0104d96
f0101ad0:	68 70 03 00 00       	push   $0x370
f0101ad5:	68 70 4d 10 f0       	push   $0xf0104d70
f0101ada:	e8 c1 e5 ff ff       	call   f01000a0 <_panic>
	cprintf("pp2 %x\n", pp2);
f0101adf:	83 ec 08             	sub    $0x8,%esp
f0101ae2:	53                   	push   %ebx
f0101ae3:	68 cf 4f 10 f0       	push   $0xf0104fcf
f0101ae8:	e8 b1 14 00 00       	call   f0102f9e <cprintf>
	cprintf("kern_pgdir %x\n", kern_pgdir);
f0101aed:	83 c4 08             	add    $0x8,%esp
f0101af0:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101af6:	68 d7 4f 10 f0       	push   $0xf0104fd7
f0101afb:	e8 9e 14 00 00       	call   f0102f9e <cprintf>
	cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
f0101b00:	83 c4 08             	add    $0x8,%esp
f0101b03:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101b08:	ff 30                	pushl  (%eax)
f0101b0a:	68 e6 4f 10 f0       	push   $0xf0104fe6
f0101b0f:	e8 8a 14 00 00       	call   f0102f9e <cprintf>
	assert(kern_pgdir[0] & PTE_U);
f0101b14:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101b19:	83 c4 10             	add    $0x10,%esp
f0101b1c:	f6 00 04             	testb  $0x4,(%eax)
f0101b1f:	75 19                	jne    f0101b3a <mem_init+0xae6>
f0101b21:	68 fb 4f 10 f0       	push   $0xf0104ffb
f0101b26:	68 96 4d 10 f0       	push   $0xf0104d96
f0101b2b:	68 74 03 00 00       	push   $0x374
f0101b30:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101b4f:	68 d8 53 10 f0       	push   $0xf01053d8
f0101b54:	68 96 4d 10 f0       	push   $0xf0104d96
f0101b59:	68 77 03 00 00       	push   $0x377
f0101b5e:	68 70 4d 10 f0       	push   $0xf0104d70
f0101b63:	e8 38 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b68:	83 ec 04             	sub    $0x4,%esp
f0101b6b:	6a 00                	push   $0x0
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101b78:	e8 ad f2 ff ff       	call   f0100e2a <pgdir_walk>
f0101b7d:	83 c4 10             	add    $0x10,%esp
f0101b80:	f6 00 02             	testb  $0x2,(%eax)
f0101b83:	75 19                	jne    f0101b9e <mem_init+0xb4a>
f0101b85:	68 f8 54 10 f0       	push   $0xf01054f8
f0101b8a:	68 96 4d 10 f0       	push   $0xf0104d96
f0101b8f:	68 78 03 00 00       	push   $0x378
f0101b94:	68 70 4d 10 f0       	push   $0xf0104d70
f0101b99:	e8 02 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b9e:	83 ec 04             	sub    $0x4,%esp
f0101ba1:	6a 00                	push   $0x0
f0101ba3:	68 00 10 00 00       	push   $0x1000
f0101ba8:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101bae:	e8 77 f2 ff ff       	call   f0100e2a <pgdir_walk>
f0101bb3:	83 c4 10             	add    $0x10,%esp
f0101bb6:	f6 00 04             	testb  $0x4,(%eax)
f0101bb9:	74 19                	je     f0101bd4 <mem_init+0xb80>
f0101bbb:	68 2c 55 10 f0       	push   $0xf010552c
f0101bc0:	68 96 4d 10 f0       	push   $0xf0104d96
f0101bc5:	68 79 03 00 00       	push   $0x379
f0101bca:	68 70 4d 10 f0       	push   $0xf0104d70
f0101bcf:	e8 cc e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bd4:	6a 02                	push   $0x2
f0101bd6:	68 00 00 40 00       	push   $0x400000
f0101bdb:	56                   	push   %esi
f0101bdc:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101be2:	e8 07 f4 ff ff       	call   f0100fee <page_insert>
f0101be7:	83 c4 10             	add    $0x10,%esp
f0101bea:	85 c0                	test   %eax,%eax
f0101bec:	78 19                	js     f0101c07 <mem_init+0xbb3>
f0101bee:	68 64 55 10 f0       	push   $0xf0105564
f0101bf3:	68 96 4d 10 f0       	push   $0xf0104d96
f0101bf8:	68 7c 03 00 00       	push   $0x37c
f0101bfd:	68 70 4d 10 f0       	push   $0xf0104d70
f0101c02:	e8 99 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c07:	6a 02                	push   $0x2
f0101c09:	68 00 10 00 00       	push   $0x1000
f0101c0e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c11:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c17:	e8 d2 f3 ff ff       	call   f0100fee <page_insert>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 19                	je     f0101c3c <mem_init+0xbe8>
f0101c23:	68 9c 55 10 f0       	push   $0xf010559c
f0101c28:	68 96 4d 10 f0       	push   $0xf0104d96
f0101c2d:	68 7f 03 00 00       	push   $0x37f
f0101c32:	68 70 4d 10 f0       	push   $0xf0104d70
f0101c37:	e8 64 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c4c:	e8 d9 f1 ff ff       	call   f0100e2a <pgdir_walk>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	f6 00 04             	testb  $0x4,(%eax)
f0101c57:	74 19                	je     f0101c72 <mem_init+0xc1e>
f0101c59:	68 2c 55 10 f0       	push   $0xf010552c
f0101c5e:	68 96 4d 10 f0       	push   $0xf0104d96
f0101c63:	68 80 03 00 00       	push   $0x380
f0101c68:	68 70 4d 10 f0       	push   $0xf0104d70
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c72:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101c78:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c7d:	89 f8                	mov    %edi,%eax
f0101c7f:	e8 f5 ec ff ff       	call   f0100979 <check_va2pa>
f0101c84:	89 c1                	mov    %eax,%ecx
f0101c86:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c8c:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101c92:	c1 f8 03             	sar    $0x3,%eax
f0101c95:	c1 e0 0c             	shl    $0xc,%eax
f0101c98:	39 c1                	cmp    %eax,%ecx
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0xc61>
f0101c9c:	68 d8 55 10 f0       	push   $0xf01055d8
f0101ca1:	68 96 4d 10 f0       	push   $0xf0104d96
f0101ca6:	68 83 03 00 00       	push   $0x383
f0101cab:	68 70 4d 10 f0       	push   $0xf0104d70
f0101cb0:	e8 eb e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cba:	89 f8                	mov    %edi,%eax
f0101cbc:	e8 b8 ec ff ff       	call   f0100979 <check_va2pa>
f0101cc1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xc8b>
f0101cc6:	68 04 56 10 f0       	push   $0xf0105604
f0101ccb:	68 96 4d 10 f0       	push   $0xf0104d96
f0101cd0:	68 84 03 00 00       	push   $0x384
f0101cd5:	68 70 4d 10 f0       	push   $0xf0104d70
f0101cda:	e8 c1 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ce2:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101ce7:	74 19                	je     f0101d02 <mem_init+0xcae>
f0101ce9:	68 11 50 10 f0       	push   $0xf0105011
f0101cee:	68 96 4d 10 f0       	push   $0xf0104d96
f0101cf3:	68 86 03 00 00       	push   $0x386
f0101cf8:	68 70 4d 10 f0       	push   $0xf0104d70
f0101cfd:	e8 9e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d02:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d07:	74 19                	je     f0101d22 <mem_init+0xcce>
f0101d09:	68 22 50 10 f0       	push   $0xf0105022
f0101d0e:	68 96 4d 10 f0       	push   $0xf0104d96
f0101d13:	68 87 03 00 00       	push   $0x387
f0101d18:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101d37:	68 34 56 10 f0       	push   $0xf0105634
f0101d3c:	68 96 4d 10 f0       	push   $0xf0104d96
f0101d41:	68 8a 03 00 00       	push   $0x38a
f0101d46:	68 70 4d 10 f0       	push   $0xf0104d70
f0101d4b:	e8 50 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d50:	83 ec 08             	sub    $0x8,%esp
f0101d53:	6a 00                	push   $0x0
f0101d55:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101d5b:	e8 4b f2 ff ff       	call   f0100fab <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d60:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101d66:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d6b:	89 f8                	mov    %edi,%eax
f0101d6d:	e8 07 ec ff ff       	call   f0100979 <check_va2pa>
f0101d72:	83 c4 10             	add    $0x10,%esp
f0101d75:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d78:	74 19                	je     f0101d93 <mem_init+0xd3f>
f0101d7a:	68 58 56 10 f0       	push   $0xf0105658
f0101d7f:	68 96 4d 10 f0       	push   $0xf0104d96
f0101d84:	68 8e 03 00 00       	push   $0x38e
f0101d89:	68 70 4d 10 f0       	push   $0xf0104d70
f0101d8e:	e8 0d e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d93:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d98:	89 f8                	mov    %edi,%eax
f0101d9a:	e8 da eb ff ff       	call   f0100979 <check_va2pa>
f0101d9f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101da2:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101da8:	c1 fa 03             	sar    $0x3,%edx
f0101dab:	c1 e2 0c             	shl    $0xc,%edx
f0101dae:	39 d0                	cmp    %edx,%eax
f0101db0:	74 19                	je     f0101dcb <mem_init+0xd77>
f0101db2:	68 04 56 10 f0       	push   $0xf0105604
f0101db7:	68 96 4d 10 f0       	push   $0xf0104d96
f0101dbc:	68 8f 03 00 00       	push   $0x38f
f0101dc1:	68 70 4d 10 f0       	push   $0xf0104d70
f0101dc6:	e8 d5 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dce:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101dd3:	74 19                	je     f0101dee <mem_init+0xd9a>
f0101dd5:	68 9c 4f 10 f0       	push   $0xf0104f9c
f0101dda:	68 96 4d 10 f0       	push   $0xf0104d96
f0101ddf:	68 90 03 00 00       	push   $0x390
f0101de4:	68 70 4d 10 f0       	push   $0xf0104d70
f0101de9:	e8 b2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dee:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df3:	74 19                	je     f0101e0e <mem_init+0xdba>
f0101df5:	68 22 50 10 f0       	push   $0xf0105022
f0101dfa:	68 96 4d 10 f0       	push   $0xf0104d96
f0101dff:	68 91 03 00 00       	push   $0x391
f0101e04:	68 70 4d 10 f0       	push   $0xf0104d70
f0101e09:	e8 92 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e0e:	83 ec 08             	sub    $0x8,%esp
f0101e11:	68 00 10 00 00       	push   $0x1000
f0101e16:	57                   	push   %edi
f0101e17:	e8 8f f1 ff ff       	call   f0100fab <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e1c:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101e22:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e27:	89 f8                	mov    %edi,%eax
f0101e29:	e8 4b eb ff ff       	call   f0100979 <check_va2pa>
f0101e2e:	83 c4 10             	add    $0x10,%esp
f0101e31:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e34:	74 19                	je     f0101e4f <mem_init+0xdfb>
f0101e36:	68 58 56 10 f0       	push   $0xf0105658
f0101e3b:	68 96 4d 10 f0       	push   $0xf0104d96
f0101e40:	68 95 03 00 00       	push   $0x395
f0101e45:	68 70 4d 10 f0       	push   $0xf0104d70
f0101e4a:	e8 51 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e4f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e54:	89 f8                	mov    %edi,%eax
f0101e56:	e8 1e eb ff ff       	call   f0100979 <check_va2pa>
f0101e5b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e5e:	74 19                	je     f0101e79 <mem_init+0xe25>
f0101e60:	68 7c 56 10 f0       	push   $0xf010567c
f0101e65:	68 96 4d 10 f0       	push   $0xf0104d96
f0101e6a:	68 96 03 00 00       	push   $0x396
f0101e6f:	68 70 4d 10 f0       	push   $0xf0104d70
f0101e74:	e8 27 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e79:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e7c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e81:	74 19                	je     f0101e9c <mem_init+0xe48>
f0101e83:	68 33 50 10 f0       	push   $0xf0105033
f0101e88:	68 96 4d 10 f0       	push   $0xf0104d96
f0101e8d:	68 97 03 00 00       	push   $0x397
f0101e92:	68 70 4d 10 f0       	push   $0xf0104d70
f0101e97:	e8 04 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e9c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ea1:	74 19                	je     f0101ebc <mem_init+0xe68>
f0101ea3:	68 22 50 10 f0       	push   $0xf0105022
f0101ea8:	68 96 4d 10 f0       	push   $0xf0104d96
f0101ead:	68 98 03 00 00       	push   $0x398
f0101eb2:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101ed2:	68 a4 56 10 f0       	push   $0xf01056a4
f0101ed7:	68 96 4d 10 f0       	push   $0xf0104d96
f0101edc:	68 9b 03 00 00       	push   $0x39b
f0101ee1:	68 70 4d 10 f0       	push   $0xf0104d70
f0101ee6:	e8 b5 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eeb:	83 ec 0c             	sub    $0xc,%esp
f0101eee:	6a 00                	push   $0x0
f0101ef0:	e8 95 ee ff ff       	call   f0100d8a <page_alloc>
f0101ef5:	83 c4 10             	add    $0x10,%esp
f0101ef8:	85 c0                	test   %eax,%eax
f0101efa:	74 19                	je     f0101f15 <mem_init+0xec1>
f0101efc:	68 3a 4f 10 f0       	push   $0xf0104f3a
f0101f01:	68 96 4d 10 f0       	push   $0xf0104d96
f0101f06:	68 9e 03 00 00       	push   $0x39e
f0101f0b:	68 70 4d 10 f0       	push   $0xf0104d70
f0101f10:	e8 8b e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f15:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0101f1b:	8b 11                	mov    (%ecx),%edx
f0101f1d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f23:	89 f0                	mov    %esi,%eax
f0101f25:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101f2b:	c1 f8 03             	sar    $0x3,%eax
f0101f2e:	c1 e0 0c             	shl    $0xc,%eax
f0101f31:	39 c2                	cmp    %eax,%edx
f0101f33:	74 19                	je     f0101f4e <mem_init+0xefa>
f0101f35:	68 80 53 10 f0       	push   $0xf0105380
f0101f3a:	68 96 4d 10 f0       	push   $0xf0104d96
f0101f3f:	68 a1 03 00 00       	push   $0x3a1
f0101f44:	68 70 4d 10 f0       	push   $0xf0104d70
f0101f49:	e8 52 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f4e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f54:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f59:	74 19                	je     f0101f74 <mem_init+0xf20>
f0101f5b:	68 ad 4f 10 f0       	push   $0xf0104fad
f0101f60:	68 96 4d 10 f0       	push   $0xf0104d96
f0101f65:	68 a3 03 00 00       	push   $0x3a3
f0101f6a:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0101f8d:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101f93:	e8 92 ee ff ff       	call   f0100e2a <pgdir_walk>
f0101f98:	89 c7                	mov    %eax,%edi
f0101f9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f9d:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101fa2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fa5:	8b 40 04             	mov    0x4(%eax),%eax
f0101fa8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fad:	8b 0d 04 db 17 f0    	mov    0xf017db04,%ecx
f0101fb3:	89 c2                	mov    %eax,%edx
f0101fb5:	c1 ea 0c             	shr    $0xc,%edx
f0101fb8:	83 c4 10             	add    $0x10,%esp
f0101fbb:	39 ca                	cmp    %ecx,%edx
f0101fbd:	72 15                	jb     f0101fd4 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbf:	50                   	push   %eax
f0101fc0:	68 e4 50 10 f0       	push   $0xf01050e4
f0101fc5:	68 aa 03 00 00       	push   $0x3aa
f0101fca:	68 70 4d 10 f0       	push   $0xf0104d70
f0101fcf:	e8 cc e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fd4:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fd9:	39 c7                	cmp    %eax,%edi
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xfa2>
f0101fdd:	68 44 50 10 f0       	push   $0xf0105044
f0101fe2:	68 96 4d 10 f0       	push   $0xf0104d96
f0101fe7:	68 ab 03 00 00       	push   $0x3ab
f0101fec:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0102008:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
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
f010201e:	68 e4 50 10 f0       	push   $0xf01050e4
f0102023:	6a 56                	push   $0x56
f0102025:	68 7c 4d 10 f0       	push   $0xf0104d7c
f010202a:	e8 71 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010202f:	83 ec 04             	sub    $0x4,%esp
f0102032:	68 00 10 00 00       	push   $0x1000
f0102037:	68 ff 00 00 00       	push   $0xff
f010203c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102041:	50                   	push   %eax
f0102042:	e8 36 23 00 00       	call   f010437d <memset>
	page_free(pp0);
f0102047:	89 34 24             	mov    %esi,(%esp)
f010204a:	e8 a5 ed ff ff       	call   f0100df4 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010204f:	83 c4 0c             	add    $0xc,%esp
f0102052:	6a 01                	push   $0x1
f0102054:	6a 00                	push   $0x0
f0102056:	ff 35 08 db 17 f0    	pushl  0xf017db08
f010205c:	e8 c9 ed ff ff       	call   f0100e2a <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102061:	89 f2                	mov    %esi,%edx
f0102063:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
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
f0102077:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f010207d:	72 12                	jb     f0102091 <mem_init+0x103d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010207f:	52                   	push   %edx
f0102080:	68 e4 50 10 f0       	push   $0xf01050e4
f0102085:	6a 56                	push   $0x56
f0102087:	68 7c 4d 10 f0       	push   $0xf0104d7c
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
f01020a5:	68 5c 50 10 f0       	push   $0xf010505c
f01020aa:	68 96 4d 10 f0       	push   $0xf0104d96
f01020af:	68 b5 03 00 00       	push   $0x3b5
f01020b4:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01020c5:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01020ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01020d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020d9:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40

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
f01020fa:	c7 04 24 73 50 10 f0 	movl   $0xf0105073,(%esp)
f0102101:	e8 98 0e 00 00       	call   f0102f9e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f0102106:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
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
f0102116:	68 84 52 10 f0       	push   $0xf0105284
f010211b:	68 c0 00 00 00       	push   $0xc0
f0102120:	68 70 4d 10 f0       	push   $0xf0104d70
f0102125:	e8 76 df ff ff       	call   f01000a0 <_panic>
f010212a:	83 ec 08             	sub    $0x8,%esp
f010212d:	6a 04                	push   $0x4
f010212f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102134:	50                   	push   %eax
f0102135:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010213a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010213f:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102144:	e8 74 ed ff ff       	call   f0100ebd <boot_map_region>
		UPAGES, 
		PTSIZE, 
		PADDR(pages), 
		PTE_U);
	cprintf("PADDR(pages) %x\n", PADDR(pages));
f0102149:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
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
f0102159:	68 84 52 10 f0       	push   $0xf0105284
f010215e:	68 c2 00 00 00       	push   $0xc2
f0102163:	68 70 4d 10 f0       	push   $0xf0104d70
f0102168:	e8 33 df ff ff       	call   f01000a0 <_panic>
f010216d:	83 ec 08             	sub    $0x8,%esp
f0102170:	05 00 00 00 10       	add    $0x10000000,%eax
f0102175:	50                   	push   %eax
f0102176:	68 8c 50 10 f0       	push   $0xf010508c
f010217b:	e8 1e 0e 00 00       	call   f0102f9e <cprintf>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,
f0102180:	a1 4c ce 17 f0       	mov    0xf017ce4c,%eax
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
f0102190:	68 84 52 10 f0       	push   $0xf0105284
f0102195:	68 cd 00 00 00       	push   $0xcd
f010219a:	68 70 4d 10 f0       	push   $0xf0104d70
f010219f:	e8 fc de ff ff       	call   f01000a0 <_panic>
f01021a4:	83 ec 08             	sub    $0x8,%esp
f01021a7:	6a 04                	push   $0x4
f01021a9:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ae:	50                   	push   %eax
f01021af:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021b4:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021b9:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01021be:	e8 fa ec ff ff       	call   f0100ebd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c3:	83 c4 10             	add    $0x10,%esp
f01021c6:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f01021cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d0:	77 15                	ja     f01021e7 <mem_init+0x1193>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d2:	50                   	push   %eax
f01021d3:	68 84 52 10 f0       	push   $0xf0105284
f01021d8:	68 df 00 00 00       	push   $0xdf
f01021dd:	68 70 4d 10 f0       	push   $0xf0104d70
f01021e2:	e8 b9 de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f01021e7:	83 ec 08             	sub    $0x8,%esp
f01021ea:	6a 02                	push   $0x2
f01021ec:	68 00 10 11 00       	push   $0x111000
f01021f1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021f6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021fb:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102200:	e8 b8 ec ff ff       	call   f0100ebd <boot_map_region>
		KSTACKTOP-KSTKSIZE, 
		KSTKSIZE, 
		PADDR(bootstack), 
		PTE_W);
	cprintf("PADDR(bootstack) %x\n", PADDR(bootstack));
f0102205:	83 c4 08             	add    $0x8,%esp
f0102208:	68 00 10 11 00       	push   $0x111000
f010220d:	68 9d 50 10 f0       	push   $0xf010509d
f0102212:	e8 87 0d 00 00       	call   f0102f9e <cprintf>
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
f0102228:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010222d:	e8 8b ec ff ff       	call   f0100ebd <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102232:	8b 1d 08 db 17 f0    	mov    0xf017db08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102238:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010223d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102240:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102247:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010224c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010224f:	8b 3d 0c db 17 f0    	mov    0xf017db0c,%edi
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
f0102279:	68 84 52 10 f0       	push   $0xf0105284
f010227e:	68 f4 02 00 00       	push   $0x2f4
f0102283:	68 70 4d 10 f0       	push   $0xf0104d70
f0102288:	e8 13 de ff ff       	call   f01000a0 <_panic>
f010228d:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102294:	39 d0                	cmp    %edx,%eax
f0102296:	74 19                	je     f01022b1 <mem_init+0x125d>
f0102298:	68 c8 56 10 f0       	push   $0xf01056c8
f010229d:	68 96 4d 10 f0       	push   $0xf0104d96
f01022a2:	68 f4 02 00 00       	push   $0x2f4
f01022a7:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01022bc:	8b 3d 4c ce 17 f0    	mov    0xf017ce4c,%edi
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
f01022dd:	68 84 52 10 f0       	push   $0xf0105284
f01022e2:	68 f9 02 00 00       	push   $0x2f9
f01022e7:	68 70 4d 10 f0       	push   $0xf0104d70
f01022ec:	e8 af dd ff ff       	call   f01000a0 <_panic>
f01022f1:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022f8:	39 c2                	cmp    %eax,%edx
f01022fa:	74 19                	je     f0102315 <mem_init+0x12c1>
f01022fc:	68 fc 56 10 f0       	push   $0xf01056fc
f0102301:	68 96 4d 10 f0       	push   $0xf0104d96
f0102306:	68 f9 02 00 00       	push   $0x2f9
f010230b:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0102341:	68 30 57 10 f0       	push   $0xf0105730
f0102346:	68 96 4d 10 f0       	push   $0xf0104d96
f010234b:	68 fd 02 00 00       	push   $0x2fd
f0102350:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0102372:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f0102378:	39 c2                	cmp    %eax,%edx
f010237a:	74 19                	je     f0102395 <mem_init+0x1341>
f010237c:	68 58 57 10 f0       	push   $0xf0105758
f0102381:	68 96 4d 10 f0       	push   $0xf0104d96
f0102386:	68 01 03 00 00       	push   $0x301
f010238b:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01023b4:	68 a0 57 10 f0       	push   $0xf01057a0
f01023b9:	68 96 4d 10 f0       	push   $0xf0104d96
f01023be:	68 02 03 00 00       	push   $0x302
f01023c3:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01023ec:	68 b2 50 10 f0       	push   $0xf01050b2
f01023f1:	68 96 4d 10 f0       	push   $0xf0104d96
f01023f6:	68 0b 03 00 00       	push   $0x30b
f01023fb:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0102419:	68 b2 50 10 f0       	push   $0xf01050b2
f010241e:	68 96 4d 10 f0       	push   $0xf0104d96
f0102423:	68 0f 03 00 00       	push   $0x30f
f0102428:	68 70 4d 10 f0       	push   $0xf0104d70
f010242d:	e8 6e dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102432:	f6 c2 02             	test   $0x2,%dl
f0102435:	75 38                	jne    f010246f <mem_init+0x141b>
f0102437:	68 c3 50 10 f0       	push   $0xf01050c3
f010243c:	68 96 4d 10 f0       	push   $0xf0104d96
f0102441:	68 10 03 00 00       	push   $0x310
f0102446:	68 70 4d 10 f0       	push   $0xf0104d70
f010244b:	e8 50 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102450:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102454:	74 19                	je     f010246f <mem_init+0x141b>
f0102456:	68 d4 50 10 f0       	push   $0xf01050d4
f010245b:	68 96 4d 10 f0       	push   $0xf0104d96
f0102460:	68 12 03 00 00       	push   $0x312
f0102465:	68 70 4d 10 f0       	push   $0xf0104d70
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
f0102480:	68 d0 57 10 f0       	push   $0xf01057d0
f0102485:	e8 14 0b 00 00       	call   f0102f9e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010248a:	a1 08 db 17 f0       	mov    0xf017db08,%eax
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
f010249a:	68 84 52 10 f0       	push   $0xf0105284
f010249f:	68 fd 00 00 00       	push   $0xfd
f01024a4:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01024e1:	68 8f 4e 10 f0       	push   $0xf0104e8f
f01024e6:	68 96 4d 10 f0       	push   $0xf0104d96
f01024eb:	68 d0 03 00 00       	push   $0x3d0
f01024f0:	68 70 4d 10 f0       	push   $0xf0104d70
f01024f5:	e8 a6 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024fa:	83 ec 0c             	sub    $0xc,%esp
f01024fd:	6a 00                	push   $0x0
f01024ff:	e8 86 e8 ff ff       	call   f0100d8a <page_alloc>
f0102504:	89 c7                	mov    %eax,%edi
f0102506:	83 c4 10             	add    $0x10,%esp
f0102509:	85 c0                	test   %eax,%eax
f010250b:	75 19                	jne    f0102526 <mem_init+0x14d2>
f010250d:	68 a5 4e 10 f0       	push   $0xf0104ea5
f0102512:	68 96 4d 10 f0       	push   $0xf0104d96
f0102517:	68 d1 03 00 00       	push   $0x3d1
f010251c:	68 70 4d 10 f0       	push   $0xf0104d70
f0102521:	e8 7a db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102526:	83 ec 0c             	sub    $0xc,%esp
f0102529:	6a 00                	push   $0x0
f010252b:	e8 5a e8 ff ff       	call   f0100d8a <page_alloc>
f0102530:	89 c6                	mov    %eax,%esi
f0102532:	83 c4 10             	add    $0x10,%esp
f0102535:	85 c0                	test   %eax,%eax
f0102537:	75 19                	jne    f0102552 <mem_init+0x14fe>
f0102539:	68 bb 4e 10 f0       	push   $0xf0104ebb
f010253e:	68 96 4d 10 f0       	push   $0xf0104d96
f0102543:	68 d2 03 00 00       	push   $0x3d2
f0102548:	68 70 4d 10 f0       	push   $0xf0104d70
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
f010255d:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
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
f0102571:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0102577:	72 12                	jb     f010258b <mem_init+0x1537>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102579:	50                   	push   %eax
f010257a:	68 e4 50 10 f0       	push   $0xf01050e4
f010257f:	6a 56                	push   $0x56
f0102581:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0102586:	e8 15 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010258b:	83 ec 04             	sub    $0x4,%esp
f010258e:	68 00 10 00 00       	push   $0x1000
f0102593:	6a 01                	push   $0x1
f0102595:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010259a:	50                   	push   %eax
f010259b:	e8 dd 1d 00 00       	call   f010437d <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025a0:	89 f0                	mov    %esi,%eax
f01025a2:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
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
f01025b6:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01025bc:	72 12                	jb     f01025d0 <mem_init+0x157c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025be:	50                   	push   %eax
f01025bf:	68 e4 50 10 f0       	push   $0xf01050e4
f01025c4:	6a 56                	push   $0x56
f01025c6:	68 7c 4d 10 f0       	push   $0xf0104d7c
f01025cb:	e8 d0 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025d0:	83 ec 04             	sub    $0x4,%esp
f01025d3:	68 00 10 00 00       	push   $0x1000
f01025d8:	6a 02                	push   $0x2
f01025da:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025df:	50                   	push   %eax
f01025e0:	e8 98 1d 00 00       	call   f010437d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025e5:	6a 02                	push   $0x2
f01025e7:	68 00 10 00 00       	push   $0x1000
f01025ec:	57                   	push   %edi
f01025ed:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01025f3:	e8 f6 e9 ff ff       	call   f0100fee <page_insert>
	assert(pp1->pp_ref == 1);
f01025f8:	83 c4 20             	add    $0x20,%esp
f01025fb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102600:	74 19                	je     f010261b <mem_init+0x15c7>
f0102602:	68 9c 4f 10 f0       	push   $0xf0104f9c
f0102607:	68 96 4d 10 f0       	push   $0xf0104d96
f010260c:	68 d7 03 00 00       	push   $0x3d7
f0102611:	68 70 4d 10 f0       	push   $0xf0104d70
f0102616:	e8 85 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010261b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102622:	01 01 01 
f0102625:	74 19                	je     f0102640 <mem_init+0x15ec>
f0102627:	68 f0 57 10 f0       	push   $0xf01057f0
f010262c:	68 96 4d 10 f0       	push   $0xf0104d96
f0102631:	68 d8 03 00 00       	push   $0x3d8
f0102636:	68 70 4d 10 f0       	push   $0xf0104d70
f010263b:	e8 60 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102640:	6a 02                	push   $0x2
f0102642:	68 00 10 00 00       	push   $0x1000
f0102647:	56                   	push   %esi
f0102648:	ff 35 08 db 17 f0    	pushl  0xf017db08
f010264e:	e8 9b e9 ff ff       	call   f0100fee <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102653:	83 c4 10             	add    $0x10,%esp
f0102656:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010265d:	02 02 02 
f0102660:	74 19                	je     f010267b <mem_init+0x1627>
f0102662:	68 14 58 10 f0       	push   $0xf0105814
f0102667:	68 96 4d 10 f0       	push   $0xf0104d96
f010266c:	68 da 03 00 00       	push   $0x3da
f0102671:	68 70 4d 10 f0       	push   $0xf0104d70
f0102676:	e8 25 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010267b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102680:	74 19                	je     f010269b <mem_init+0x1647>
f0102682:	68 be 4f 10 f0       	push   $0xf0104fbe
f0102687:	68 96 4d 10 f0       	push   $0xf0104d96
f010268c:	68 db 03 00 00       	push   $0x3db
f0102691:	68 70 4d 10 f0       	push   $0xf0104d70
f0102696:	e8 05 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010269b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026a0:	74 19                	je     f01026bb <mem_init+0x1667>
f01026a2:	68 33 50 10 f0       	push   $0xf0105033
f01026a7:	68 96 4d 10 f0       	push   $0xf0104d96
f01026ac:	68 dc 03 00 00       	push   $0x3dc
f01026b1:	68 70 4d 10 f0       	push   $0xf0104d70
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
f01026c7:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01026cd:	c1 f8 03             	sar    $0x3,%eax
f01026d0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026d3:	89 c2                	mov    %eax,%edx
f01026d5:	c1 ea 0c             	shr    $0xc,%edx
f01026d8:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01026de:	72 12                	jb     f01026f2 <mem_init+0x169e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026e0:	50                   	push   %eax
f01026e1:	68 e4 50 10 f0       	push   $0xf01050e4
f01026e6:	6a 56                	push   $0x56
f01026e8:	68 7c 4d 10 f0       	push   $0xf0104d7c
f01026ed:	e8 ae d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026f2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026f9:	03 03 03 
f01026fc:	74 19                	je     f0102717 <mem_init+0x16c3>
f01026fe:	68 38 58 10 f0       	push   $0xf0105838
f0102703:	68 96 4d 10 f0       	push   $0xf0104d96
f0102708:	68 de 03 00 00       	push   $0x3de
f010270d:	68 70 4d 10 f0       	push   $0xf0104d70
f0102712:	e8 89 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102717:	83 ec 08             	sub    $0x8,%esp
f010271a:	68 00 10 00 00       	push   $0x1000
f010271f:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102725:	e8 81 e8 ff ff       	call   f0100fab <page_remove>
	assert(pp2->pp_ref == 0);
f010272a:	83 c4 10             	add    $0x10,%esp
f010272d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102732:	74 19                	je     f010274d <mem_init+0x16f9>
f0102734:	68 22 50 10 f0       	push   $0xf0105022
f0102739:	68 96 4d 10 f0       	push   $0xf0104d96
f010273e:	68 e0 03 00 00       	push   $0x3e0
f0102743:	68 70 4d 10 f0       	push   $0xf0104d70
f0102748:	e8 53 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010274d:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0102753:	8b 11                	mov    (%ecx),%edx
f0102755:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010275b:	89 d8                	mov    %ebx,%eax
f010275d:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102763:	c1 f8 03             	sar    $0x3,%eax
f0102766:	c1 e0 0c             	shl    $0xc,%eax
f0102769:	39 c2                	cmp    %eax,%edx
f010276b:	74 19                	je     f0102786 <mem_init+0x1732>
f010276d:	68 80 53 10 f0       	push   $0xf0105380
f0102772:	68 96 4d 10 f0       	push   $0xf0104d96
f0102777:	68 e3 03 00 00       	push   $0x3e3
f010277c:	68 70 4d 10 f0       	push   $0xf0104d70
f0102781:	e8 1a d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102786:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010278c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102791:	74 19                	je     f01027ac <mem_init+0x1758>
f0102793:	68 ad 4f 10 f0       	push   $0xf0104fad
f0102798:	68 96 4d 10 f0       	push   $0xf0104d96
f010279d:	68 e5 03 00 00       	push   $0x3e5
f01027a2:	68 70 4d 10 f0       	push   $0xf0104d70
f01027a7:	e8 f4 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027ac:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027b2:	83 ec 0c             	sub    $0xc,%esp
f01027b5:	53                   	push   %ebx
f01027b6:	e8 39 e6 ff ff       	call   f0100df4 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027bb:	c7 04 24 64 58 10 f0 	movl   $0xf0105864,(%esp)
f01027c2:	e8 d7 07 00 00       	call   f0102f9e <cprintf>
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
f01027e0:	57                   	push   %edi
f01027e1:	56                   	push   %esi
f01027e2:	53                   	push   %ebx
f01027e3:	83 ec 20             	sub    $0x20,%esp
f01027e6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01027e9:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
f01027ec:	ff 75 10             	pushl  0x10(%ebp)
f01027ef:	ff 75 0c             	pushl  0xc(%ebp)
f01027f2:	68 90 58 10 f0       	push   $0xf0105890
f01027f7:	e8 a2 07 00 00       	call   f0102f9e <cprintf>
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
f01027fc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027ff:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
f0102805:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102808:	8b 55 10             	mov    0x10(%ebp),%edx
f010280b:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
f0102812:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102817:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f010281a:	83 c4 10             	add    $0x10,%esp
f010281d:	eb 43                	jmp    f0102862 <user_mem_check+0x85>
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f010281f:	83 ec 04             	sub    $0x4,%esp
f0102822:	6a 00                	push   $0x0
f0102824:	53                   	push   %ebx
f0102825:	ff 77 5c             	pushl  0x5c(%edi)
f0102828:	e8 fd e5 ff ff       	call   f0100e2a <pgdir_walk>
		// pprint(pte);
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
f010282d:	83 c4 10             	add    $0x10,%esp
f0102830:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102836:	77 10                	ja     f0102848 <user_mem_check+0x6b>
f0102838:	85 c0                	test   %eax,%eax
f010283a:	74 0c                	je     f0102848 <user_mem_check+0x6b>
f010283c:	8b 00                	mov    (%eax),%eax
f010283e:	a8 01                	test   $0x1,%al
f0102840:	74 06                	je     f0102848 <user_mem_check+0x6b>
f0102842:	21 f0                	and    %esi,%eax
f0102844:	39 c6                	cmp    %eax,%esi
f0102846:	74 14                	je     f010285c <user_mem_check+0x7f>
			user_mem_check_addr = (i<(uint32_t)va?(uint32_t)va:i);
f0102848:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f010284b:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f010284f:	89 1d 3c ce 17 f0    	mov    %ebx,0xf017ce3c
			return -E_FAULT;
f0102855:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010285a:	eb 26                	jmp    f0102882 <user_mem_check+0xa5>
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f010285c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102862:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102865:	72 b8                	jb     f010281f <user_mem_check+0x42>
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
			user_mem_check_addr = (i<(uint32_t)va?(uint32_t)va:i);
			return -E_FAULT;
		}
	}
	cprintf("user_mem_check success va: %x, len: %x\n", va, len);
f0102867:	83 ec 04             	sub    $0x4,%esp
f010286a:	ff 75 10             	pushl  0x10(%ebp)
f010286d:	ff 75 0c             	pushl  0xc(%ebp)
f0102870:	68 b0 58 10 f0       	push   $0xf01058b0
f0102875:	e8 24 07 00 00       	call   f0102f9e <cprintf>
	return 0;
f010287a:	83 c4 10             	add    $0x10,%esp
f010287d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102882:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102885:	5b                   	pop    %ebx
f0102886:	5e                   	pop    %esi
f0102887:	5f                   	pop    %edi
f0102888:	5d                   	pop    %ebp
f0102889:	c3                   	ret    

f010288a <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010288a:	55                   	push   %ebp
f010288b:	89 e5                	mov    %esp,%ebp
f010288d:	53                   	push   %ebx
f010288e:	83 ec 04             	sub    $0x4,%esp
f0102891:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102894:	8b 45 14             	mov    0x14(%ebp),%eax
f0102897:	83 c8 04             	or     $0x4,%eax
f010289a:	50                   	push   %eax
f010289b:	ff 75 10             	pushl  0x10(%ebp)
f010289e:	ff 75 0c             	pushl  0xc(%ebp)
f01028a1:	53                   	push   %ebx
f01028a2:	e8 36 ff ff ff       	call   f01027dd <user_mem_check>
f01028a7:	83 c4 10             	add    $0x10,%esp
f01028aa:	85 c0                	test   %eax,%eax
f01028ac:	79 21                	jns    f01028cf <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01028ae:	83 ec 04             	sub    $0x4,%esp
f01028b1:	ff 35 3c ce 17 f0    	pushl  0xf017ce3c
f01028b7:	ff 73 48             	pushl  0x48(%ebx)
f01028ba:	68 d8 58 10 f0       	push   $0xf01058d8
f01028bf:	e8 da 06 00 00       	call   f0102f9e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01028c4:	89 1c 24             	mov    %ebx,(%esp)
f01028c7:	e8 bb 05 00 00       	call   f0102e87 <env_destroy>
f01028cc:	83 c4 10             	add    $0x10,%esp
	}
}
f01028cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028d2:	c9                   	leave  
f01028d3:	c3                   	ret    

f01028d4 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01028d4:	55                   	push   %ebp
f01028d5:	89 e5                	mov    %esp,%ebp
f01028d7:	57                   	push   %edi
f01028d8:	56                   	push   %esi
f01028d9:	53                   	push   %ebx
f01028da:	83 ec 0c             	sub    $0xc,%esp
f01028dd:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
f01028df:	89 d3                	mov    %edx,%ebx
f01028e1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01028e7:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01028ee:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (; begin < end; begin += PGSIZE) {
f01028f4:	eb 3d                	jmp    f0102933 <region_alloc+0x5f>
		struct PageInfo *pg = page_alloc(0);
f01028f6:	83 ec 0c             	sub    $0xc,%esp
f01028f9:	6a 00                	push   $0x0
f01028fb:	e8 8a e4 ff ff       	call   f0100d8a <page_alloc>
		if (!pg) panic("region_alloc failed!");
f0102900:	83 c4 10             	add    $0x10,%esp
f0102903:	85 c0                	test   %eax,%eax
f0102905:	75 17                	jne    f010291e <region_alloc+0x4a>
f0102907:	83 ec 04             	sub    $0x4,%esp
f010290a:	68 0d 59 10 f0       	push   $0xf010590d
f010290f:	68 15 01 00 00       	push   $0x115
f0102914:	68 22 59 10 f0       	push   $0xf0105922
f0102919:	e8 82 d7 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, pg, begin, PTE_W | PTE_U);
f010291e:	6a 06                	push   $0x6
f0102920:	53                   	push   %ebx
f0102921:	50                   	push   %eax
f0102922:	ff 77 5c             	pushl  0x5c(%edi)
f0102925:	e8 c4 e6 ff ff       	call   f0100fee <page_insert>
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
	for (; begin < end; begin += PGSIZE) {
f010292a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102930:	83 c4 10             	add    $0x10,%esp
f0102933:	39 f3                	cmp    %esi,%ebx
f0102935:	72 bf                	jb     f01028f6 <region_alloc+0x22>
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102937:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010293a:	5b                   	pop    %ebx
f010293b:	5e                   	pop    %esi
f010293c:	5f                   	pop    %edi
f010293d:	5d                   	pop    %ebp
f010293e:	c3                   	ret    

f010293f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010293f:	55                   	push   %ebp
f0102940:	89 e5                	mov    %esp,%ebp
f0102942:	8b 55 08             	mov    0x8(%ebp),%edx
f0102945:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102948:	85 d2                	test   %edx,%edx
f010294a:	75 11                	jne    f010295d <envid2env+0x1e>
		*env_store = curenv;
f010294c:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0102951:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102954:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102956:	b8 00 00 00 00       	mov    $0x0,%eax
f010295b:	eb 5e                	jmp    f01029bb <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010295d:	89 d0                	mov    %edx,%eax
f010295f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102964:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102967:	c1 e0 05             	shl    $0x5,%eax
f010296a:	03 05 4c ce 17 f0    	add    0xf017ce4c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102970:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102974:	74 05                	je     f010297b <envid2env+0x3c>
f0102976:	3b 50 48             	cmp    0x48(%eax),%edx
f0102979:	74 10                	je     f010298b <envid2env+0x4c>
		*env_store = 0;
f010297b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010297e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102984:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102989:	eb 30                	jmp    f01029bb <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010298b:	84 c9                	test   %cl,%cl
f010298d:	74 22                	je     f01029b1 <envid2env+0x72>
f010298f:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102995:	39 d0                	cmp    %edx,%eax
f0102997:	74 18                	je     f01029b1 <envid2env+0x72>
f0102999:	8b 4a 48             	mov    0x48(%edx),%ecx
f010299c:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010299f:	74 10                	je     f01029b1 <envid2env+0x72>
		*env_store = 0;
f01029a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029aa:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029af:	eb 0a                	jmp    f01029bb <envid2env+0x7c>
	}

	*env_store = e;
f01029b1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029b4:	89 01                	mov    %eax,(%ecx)
	return 0;
f01029b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029bb:	5d                   	pop    %ebp
f01029bc:	c3                   	ret    

f01029bd <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01029bd:	55                   	push   %ebp
f01029be:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01029c0:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01029c5:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01029c8:	b8 23 00 00 00       	mov    $0x23,%eax
f01029cd:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01029cf:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01029d1:	b8 10 00 00 00       	mov    $0x10,%eax
f01029d6:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01029d8:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01029da:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01029dc:	ea e3 29 10 f0 08 00 	ljmp   $0x8,$0xf01029e3
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01029e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01029e8:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01029eb:	5d                   	pop    %ebp
f01029ec:	c3                   	ret    

f01029ed <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01029ed:	55                   	push   %ebp
f01029ee:	89 e5                	mov    %esp,%ebp
f01029f0:	56                   	push   %esi
f01029f1:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV-1;i >= 0; --i) {
		envs[i].env_id = 0;
f01029f2:	8b 35 4c ce 17 f0    	mov    0xf017ce4c,%esi
f01029f8:	8b 15 50 ce 17 f0    	mov    0xf017ce50,%edx
f01029fe:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a04:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a07:	89 c1                	mov    %eax,%ecx
f0102a09:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102a10:	89 50 44             	mov    %edx,0x44(%eax)
f0102a13:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs+i;
f0102a16:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = NENV-1;i >= 0; --i) {
f0102a18:	39 d8                	cmp    %ebx,%eax
f0102a1a:	75 eb                	jne    f0102a07 <env_init+0x1a>
f0102a1c:	89 35 50 ce 17 f0    	mov    %esi,0xf017ce50
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = envs+i;
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102a22:	e8 96 ff ff ff       	call   f01029bd <env_init_percpu>
}
f0102a27:	5b                   	pop    %ebx
f0102a28:	5e                   	pop    %esi
f0102a29:	5d                   	pop    %ebp
f0102a2a:	c3                   	ret    

f0102a2b <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102a2b:	55                   	push   %ebp
f0102a2c:	89 e5                	mov    %esp,%ebp
f0102a2e:	53                   	push   %ebx
f0102a2f:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102a32:	8b 1d 50 ce 17 f0    	mov    0xf017ce50,%ebx
f0102a38:	85 db                	test   %ebx,%ebx
f0102a3a:	0f 84 62 01 00 00    	je     f0102ba2 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a40:	83 ec 0c             	sub    $0xc,%esp
f0102a43:	6a 01                	push   $0x1
f0102a45:	e8 40 e3 ff ff       	call   f0100d8a <page_alloc>
f0102a4a:	83 c4 10             	add    $0x10,%esp
f0102a4d:	85 c0                	test   %eax,%eax
f0102a4f:	0f 84 54 01 00 00    	je     f0102ba9 <env_alloc+0x17e>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102a55:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a5a:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102a60:	c1 f8 03             	sar    $0x3,%eax
f0102a63:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a66:	89 c2                	mov    %eax,%edx
f0102a68:	c1 ea 0c             	shr    $0xc,%edx
f0102a6b:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0102a71:	72 12                	jb     f0102a85 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a73:	50                   	push   %eax
f0102a74:	68 e4 50 10 f0       	push   $0xf01050e4
f0102a79:	6a 56                	push   $0x56
f0102a7b:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0102a80:	e8 1b d6 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102a85:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f0102a8a:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102a8d:	83 ec 04             	sub    $0x4,%esp
f0102a90:	68 00 10 00 00       	push   $0x1000
f0102a95:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102a9b:	50                   	push   %eax
f0102a9c:	e8 91 19 00 00       	call   f0104432 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102aa1:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aa4:	83 c4 10             	add    $0x10,%esp
f0102aa7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aac:	77 15                	ja     f0102ac3 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aae:	50                   	push   %eax
f0102aaf:	68 84 52 10 f0       	push   $0xf0105284
f0102ab4:	68 c1 00 00 00       	push   $0xc1
f0102ab9:	68 22 59 10 f0       	push   $0xf0105922
f0102abe:	e8 dd d5 ff ff       	call   f01000a0 <_panic>
f0102ac3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102ac9:	83 ca 05             	or     $0x5,%edx
f0102acc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102ad2:	8b 43 48             	mov    0x48(%ebx),%eax
f0102ad5:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102ada:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102adf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102ae4:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102ae7:	8b 0d 4c ce 17 f0    	mov    0xf017ce4c,%ecx
f0102aed:	89 da                	mov    %ebx,%edx
f0102aef:	29 ca                	sub    %ecx,%edx
f0102af1:	c1 fa 05             	sar    $0x5,%edx
f0102af4:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102afa:	09 d0                	or     %edx,%eax
f0102afc:	89 43 48             	mov    %eax,0x48(%ebx)
	cprintf("envs: %x, e: %x, e->env_id: %x\n", envs, e, e->env_id);
f0102aff:	50                   	push   %eax
f0102b00:	53                   	push   %ebx
f0102b01:	51                   	push   %ecx
f0102b02:	68 9c 59 10 f0       	push   $0xf010599c
f0102b07:	e8 92 04 00 00       	call   f0102f9e <cprintf>

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b0f:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b12:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b19:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102b20:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b27:	83 c4 0c             	add    $0xc,%esp
f0102b2a:	6a 44                	push   $0x44
f0102b2c:	6a 00                	push   $0x0
f0102b2e:	53                   	push   %ebx
f0102b2f:	e8 49 18 00 00       	call   f010437d <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b34:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b3a:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b40:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b46:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b4d:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b53:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b56:	a3 50 ce 17 f0       	mov    %eax,0xf017ce50
	*newenv_store = e;
f0102b5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b5e:	89 18                	mov    %ebx,(%eax)

	cprintf("env_id, %x\n", e->env_id);
f0102b60:	83 c4 08             	add    $0x8,%esp
f0102b63:	ff 73 48             	pushl  0x48(%ebx)
f0102b66:	68 2d 59 10 f0       	push   $0xf010592d
f0102b6b:	e8 2e 04 00 00       	call   f0102f9e <cprintf>
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b70:	8b 53 48             	mov    0x48(%ebx),%edx
f0102b73:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0102b78:	83 c4 10             	add    $0x10,%esp
f0102b7b:	85 c0                	test   %eax,%eax
f0102b7d:	74 05                	je     f0102b84 <env_alloc+0x159>
f0102b7f:	8b 40 48             	mov    0x48(%eax),%eax
f0102b82:	eb 05                	jmp    f0102b89 <env_alloc+0x15e>
f0102b84:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b89:	83 ec 04             	sub    $0x4,%esp
f0102b8c:	52                   	push   %edx
f0102b8d:	50                   	push   %eax
f0102b8e:	68 39 59 10 f0       	push   $0xf0105939
f0102b93:	e8 06 04 00 00       	call   f0102f9e <cprintf>
	return 0;
f0102b98:	83 c4 10             	add    $0x10,%esp
f0102b9b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ba0:	eb 0c                	jmp    f0102bae <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102ba2:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102ba7:	eb 05                	jmp    f0102bae <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102ba9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*newenv_store = e;

	cprintf("env_id, %x\n", e->env_id);
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102bae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102bb1:	c9                   	leave  
f0102bb2:	c3                   	ret    

f0102bb3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102bb3:	55                   	push   %ebp
f0102bb4:	89 e5                	mov    %esp,%ebp
f0102bb6:	57                   	push   %edi
f0102bb7:	56                   	push   %esi
f0102bb8:	53                   	push   %ebx
f0102bb9:	83 ec 34             	sub    $0x34,%esp
f0102bbc:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
f0102bbf:	6a 00                	push   $0x0
f0102bc1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102bc4:	50                   	push   %eax
f0102bc5:	e8 61 fe ff ff       	call   f0102a2b <env_alloc>
	load_icode(penv, binary);
f0102bca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bcd:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;

	if (ELFHDR->e_magic != ELF_MAGIC)
f0102bd0:	83 c4 10             	add    $0x10,%esp
f0102bd3:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102bd9:	74 17                	je     f0102bf2 <env_create+0x3f>
		panic("Not executable!");
f0102bdb:	83 ec 04             	sub    $0x4,%esp
f0102bde:	68 4e 59 10 f0       	push   $0xf010594e
f0102be3:	68 52 01 00 00       	push   $0x152
f0102be8:	68 22 59 10 f0       	push   $0xf0105922
f0102bed:	e8 ae d4 ff ff       	call   f01000a0 <_panic>
	
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102bf2:	89 fb                	mov    %edi,%ebx
f0102bf4:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102bf7:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102bfb:	c1 e6 05             	shl    $0x5,%esi
f0102bfe:	01 de                	add    %ebx,%esi
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
f0102c00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c03:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c06:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c0b:	77 15                	ja     f0102c22 <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c0d:	50                   	push   %eax
f0102c0e:	68 84 52 10 f0       	push   $0xf0105284
f0102c13:	68 5e 01 00 00       	push   $0x15e
f0102c18:	68 22 59 10 f0       	push   $0xf0105922
f0102c1d:	e8 7e d4 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c22:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c27:	0f 22 d8             	mov    %eax,%cr3
f0102c2a:	eb 50                	jmp    f0102c7c <env_create+0xc9>
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
f0102c2c:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c2f:	75 48                	jne    f0102c79 <env_create+0xc6>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102c31:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c34:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c3a:	e8 95 fc ff ff       	call   f01028d4 <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f0102c3f:	83 ec 04             	sub    $0x4,%esp
f0102c42:	ff 73 14             	pushl  0x14(%ebx)
f0102c45:	6a 00                	push   $0x0
f0102c47:	ff 73 08             	pushl  0x8(%ebx)
f0102c4a:	e8 2e 17 00 00       	call   f010437d <memset>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0102c4f:	83 c4 0c             	add    $0xc,%esp
f0102c52:	ff 73 10             	pushl  0x10(%ebx)
f0102c55:	89 f8                	mov    %edi,%eax
f0102c57:	03 43 04             	add    0x4(%ebx),%eax
f0102c5a:	50                   	push   %eax
f0102c5b:	ff 73 08             	pushl  0x8(%ebx)
f0102c5e:	e8 cf 17 00 00       	call   f0104432 <memcpy>
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
f0102c63:	83 c4 0c             	add    $0xc,%esp
f0102c66:	ff 73 10             	pushl  0x10(%ebx)
f0102c69:	ff 73 14             	pushl  0x14(%ebx)
f0102c6c:	68 5e 59 10 f0       	push   $0xf010595e
f0102c71:	e8 28 03 00 00       	call   f0102f9e <cprintf>
f0102c76:	83 c4 10             	add    $0x10,%esp
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
f0102c79:	83 c3 20             	add    $0x20,%ebx
f0102c7c:	39 de                	cmp    %ebx,%esi
f0102c7e:	77 ac                	ja     f0102c2c <env_create+0x79>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
		}
	//we can use this because kern_pgdir is a subset of e->env_pgdir
	lcr3(PADDR(kern_pgdir));
f0102c80:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c85:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c8a:	77 15                	ja     f0102ca1 <env_create+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c8c:	50                   	push   %eax
f0102c8d:	68 84 52 10 f0       	push   $0xf0105284
f0102c92:	68 69 01 00 00       	push   $0x169
f0102c97:	68 22 59 10 f0       	push   $0xf0105922
f0102c9c:	e8 ff d3 ff ff       	call   f01000a0 <_panic>
f0102ca1:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ca6:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102ca9:	8b 47 18             	mov    0x18(%edi),%eax
f0102cac:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102caf:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102cb2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102cb7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102cbc:	89 f8                	mov    %edi,%eax
f0102cbe:	e8 11 fc ff ff       	call   f01028d4 <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *penv;
	env_alloc(&penv, 0);
	load_icode(penv, binary);
}
f0102cc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cc6:	5b                   	pop    %ebx
f0102cc7:	5e                   	pop    %esi
f0102cc8:	5f                   	pop    %edi
f0102cc9:	5d                   	pop    %ebp
f0102cca:	c3                   	ret    

f0102ccb <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102ccb:	55                   	push   %ebp
f0102ccc:	89 e5                	mov    %esp,%ebp
f0102cce:	57                   	push   %edi
f0102ccf:	56                   	push   %esi
f0102cd0:	53                   	push   %ebx
f0102cd1:	83 ec 1c             	sub    $0x1c,%esp
f0102cd4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102cd7:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102cdd:	39 fa                	cmp    %edi,%edx
f0102cdf:	75 29                	jne    f0102d0a <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102ce1:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ce6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ceb:	77 15                	ja     f0102d02 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ced:	50                   	push   %eax
f0102cee:	68 84 52 10 f0       	push   $0xf0105284
f0102cf3:	68 8f 01 00 00       	push   $0x18f
f0102cf8:	68 22 59 10 f0       	push   $0xf0105922
f0102cfd:	e8 9e d3 ff ff       	call   f01000a0 <_panic>
f0102d02:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d07:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d0a:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102d0d:	85 d2                	test   %edx,%edx
f0102d0f:	74 05                	je     f0102d16 <env_free+0x4b>
f0102d11:	8b 42 48             	mov    0x48(%edx),%eax
f0102d14:	eb 05                	jmp    f0102d1b <env_free+0x50>
f0102d16:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d1b:	83 ec 04             	sub    $0x4,%esp
f0102d1e:	51                   	push   %ecx
f0102d1f:	50                   	push   %eax
f0102d20:	68 79 59 10 f0       	push   $0xf0105979
f0102d25:	e8 74 02 00 00       	call   f0102f9e <cprintf>
f0102d2a:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d2d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d34:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d37:	89 d0                	mov    %edx,%eax
f0102d39:	c1 e0 02             	shl    $0x2,%eax
f0102d3c:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d3f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d42:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d45:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d4b:	0f 84 a8 00 00 00    	je     f0102df9 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d51:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d57:	89 f0                	mov    %esi,%eax
f0102d59:	c1 e8 0c             	shr    $0xc,%eax
f0102d5c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d5f:	39 05 04 db 17 f0    	cmp    %eax,0xf017db04
f0102d65:	77 15                	ja     f0102d7c <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d67:	56                   	push   %esi
f0102d68:	68 e4 50 10 f0       	push   $0xf01050e4
f0102d6d:	68 9e 01 00 00       	push   $0x19e
f0102d72:	68 22 59 10 f0       	push   $0xf0105922
f0102d77:	e8 24 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d7f:	c1 e0 16             	shl    $0x16,%eax
f0102d82:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d85:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d8a:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d91:	01 
f0102d92:	74 17                	je     f0102dab <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d94:	83 ec 08             	sub    $0x8,%esp
f0102d97:	89 d8                	mov    %ebx,%eax
f0102d99:	c1 e0 0c             	shl    $0xc,%eax
f0102d9c:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d9f:	50                   	push   %eax
f0102da0:	ff 77 5c             	pushl  0x5c(%edi)
f0102da3:	e8 03 e2 ff ff       	call   f0100fab <page_remove>
f0102da8:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dab:	83 c3 01             	add    $0x1,%ebx
f0102dae:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102db4:	75 d4                	jne    f0102d8a <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102db6:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102db9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102dbc:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dc3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dc6:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102dcc:	72 14                	jb     f0102de2 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102dce:	83 ec 04             	sub    $0x4,%esp
f0102dd1:	68 28 52 10 f0       	push   $0xf0105228
f0102dd6:	6a 4f                	push   $0x4f
f0102dd8:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0102ddd:	e8 be d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102de2:	83 ec 0c             	sub    $0xc,%esp
f0102de5:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f0102dea:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ded:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102df0:	50                   	push   %eax
f0102df1:	e8 13 e0 ff ff       	call   f0100e09 <page_decref>
f0102df6:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102df9:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102dfd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e00:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e05:	0f 85 29 ff ff ff    	jne    f0102d34 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e0b:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e0e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e13:	77 15                	ja     f0102e2a <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e15:	50                   	push   %eax
f0102e16:	68 84 52 10 f0       	push   $0xf0105284
f0102e1b:	68 ac 01 00 00       	push   $0x1ac
f0102e20:	68 22 59 10 f0       	push   $0xf0105922
f0102e25:	e8 76 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102e2a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e31:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e36:	c1 e8 0c             	shr    $0xc,%eax
f0102e39:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102e3f:	72 14                	jb     f0102e55 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e41:	83 ec 04             	sub    $0x4,%esp
f0102e44:	68 28 52 10 f0       	push   $0xf0105228
f0102e49:	6a 4f                	push   $0x4f
f0102e4b:	68 7c 4d 10 f0       	push   $0xf0104d7c
f0102e50:	e8 4b d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e55:	83 ec 0c             	sub    $0xc,%esp
f0102e58:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
f0102e5e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102e61:	50                   	push   %eax
f0102e62:	e8 a2 df ff ff       	call   f0100e09 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e67:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e6e:	a1 50 ce 17 f0       	mov    0xf017ce50,%eax
f0102e73:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e76:	89 3d 50 ce 17 f0    	mov    %edi,0xf017ce50
}
f0102e7c:	83 c4 10             	add    $0x10,%esp
f0102e7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e82:	5b                   	pop    %ebx
f0102e83:	5e                   	pop    %esi
f0102e84:	5f                   	pop    %edi
f0102e85:	5d                   	pop    %ebp
f0102e86:	c3                   	ret    

f0102e87 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e87:	55                   	push   %ebp
f0102e88:	89 e5                	mov    %esp,%ebp
f0102e8a:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e8d:	ff 75 08             	pushl  0x8(%ebp)
f0102e90:	e8 36 fe ff ff       	call   f0102ccb <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e95:	c7 04 24 bc 59 10 f0 	movl   $0xf01059bc,(%esp)
f0102e9c:	e8 fd 00 00 00       	call   f0102f9e <cprintf>
f0102ea1:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102ea4:	83 ec 0c             	sub    $0xc,%esp
f0102ea7:	6a 00                	push   $0x0
f0102ea9:	e8 0b d9 ff ff       	call   f01007b9 <monitor>
f0102eae:	83 c4 10             	add    $0x10,%esp
f0102eb1:	eb f1                	jmp    f0102ea4 <env_destroy+0x1d>

f0102eb3 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102eb3:	55                   	push   %ebp
f0102eb4:	89 e5                	mov    %esp,%ebp
f0102eb6:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102eb9:	8b 65 08             	mov    0x8(%ebp),%esp
f0102ebc:	61                   	popa   
f0102ebd:	07                   	pop    %es
f0102ebe:	1f                   	pop    %ds
f0102ebf:	83 c4 08             	add    $0x8,%esp
f0102ec2:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102ec3:	68 8f 59 10 f0       	push   $0xf010598f
f0102ec8:	68 d4 01 00 00       	push   $0x1d4
f0102ecd:	68 22 59 10 f0       	push   $0xf0105922
f0102ed2:	e8 c9 d1 ff ff       	call   f01000a0 <_panic>

f0102ed7 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102ed7:	55                   	push   %ebp
f0102ed8:	89 e5                	mov    %esp,%ebp
f0102eda:	53                   	push   %ebx
f0102edb:	83 ec 10             	sub    $0x10,%esp
f0102ede:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// cprintf("curenv: %x, e: %x\n", curenv, e);
	cprintf("\n");
f0102ee1:	68 8a 50 10 f0       	push   $0xf010508a
f0102ee6:	e8 b3 00 00 00       	call   f0102f9e <cprintf>
	if (curenv != e) {
f0102eeb:	83 c4 10             	add    $0x10,%esp
f0102eee:	39 1d 48 ce 17 f0    	cmp    %ebx,0xf017ce48
f0102ef4:	74 38                	je     f0102f2e <env_run+0x57>
		// if (curenv->env_status == ENV_RUNNING)
		// 	curenv->env_status = ENV_RUNNABLE;
		curenv = e;
f0102ef6:	89 1d 48 ce 17 f0    	mov    %ebx,0xf017ce48
		e->env_status = ENV_RUNNING;
f0102efc:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
		e->env_runs++;
f0102f03:	83 43 58 01          	addl   $0x1,0x58(%ebx)
		lcr3(PADDR(e->env_pgdir));
f0102f07:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f0a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f0f:	77 15                	ja     f0102f26 <env_run+0x4f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f11:	50                   	push   %eax
f0102f12:	68 84 52 10 f0       	push   $0xf0105284
f0102f17:	68 fa 01 00 00       	push   $0x1fa
f0102f1c:	68 22 59 10 f0       	push   $0xf0105922
f0102f21:	e8 7a d1 ff ff       	call   f01000a0 <_panic>
f0102f26:	05 00 00 00 10       	add    $0x10000000,%eax
f0102f2b:	0f 22 d8             	mov    %eax,%cr3
	}
	env_pop_tf(&e->env_tf);
f0102f2e:	83 ec 0c             	sub    $0xc,%esp
f0102f31:	53                   	push   %ebx
f0102f32:	e8 7c ff ff ff       	call   f0102eb3 <env_pop_tf>

f0102f37 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f37:	55                   	push   %ebp
f0102f38:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f3a:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f42:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f43:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f48:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f49:	0f b6 c0             	movzbl %al,%eax
}
f0102f4c:	5d                   	pop    %ebp
f0102f4d:	c3                   	ret    

f0102f4e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f4e:	55                   	push   %ebp
f0102f4f:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f51:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f56:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f59:	ee                   	out    %al,(%dx)
f0102f5a:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f5f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f62:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f63:	5d                   	pop    %ebp
f0102f64:	c3                   	ret    

f0102f65 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f65:	55                   	push   %ebp
f0102f66:	89 e5                	mov    %esp,%ebp
f0102f68:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f6b:	ff 75 08             	pushl  0x8(%ebp)
f0102f6e:	e8 a2 d6 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102f73:	83 c4 10             	add    $0x10,%esp
f0102f76:	c9                   	leave  
f0102f77:	c3                   	ret    

f0102f78 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f78:	55                   	push   %ebp
f0102f79:	89 e5                	mov    %esp,%ebp
f0102f7b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f85:	ff 75 0c             	pushl  0xc(%ebp)
f0102f88:	ff 75 08             	pushl  0x8(%ebp)
f0102f8b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f8e:	50                   	push   %eax
f0102f8f:	68 65 2f 10 f0       	push   $0xf0102f65
f0102f94:	e8 bf 0c 00 00       	call   f0103c58 <vprintfmt>
	return cnt;
}
f0102f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f9c:	c9                   	leave  
f0102f9d:	c3                   	ret    

f0102f9e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f9e:	55                   	push   %ebp
f0102f9f:	89 e5                	mov    %esp,%ebp
f0102fa1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fa4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fa7:	50                   	push   %eax
f0102fa8:	ff 75 08             	pushl  0x8(%ebp)
f0102fab:	e8 c8 ff ff ff       	call   f0102f78 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fb0:	c9                   	leave  
f0102fb1:	c3                   	ret    

f0102fb2 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102fb2:	55                   	push   %ebp
f0102fb3:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102fb5:	b8 80 d6 17 f0       	mov    $0xf017d680,%eax
f0102fba:	c7 05 84 d6 17 f0 00 	movl   $0xf0000000,0xf017d684
f0102fc1:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102fc4:	66 c7 05 88 d6 17 f0 	movw   $0x10,0xf017d688
f0102fcb:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0102fcd:	66 c7 05 e6 d6 17 f0 	movw   $0x68,0xf017d6e6
f0102fd4:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102fd6:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102fdd:	67 00 
f0102fdf:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0102fe5:	89 c2                	mov    %eax,%edx
f0102fe7:	c1 ea 10             	shr    $0x10,%edx
f0102fea:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0102ff0:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0102ff7:	c1 e8 18             	shr    $0x18,%eax
f0102ffa:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102fff:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103006:	b8 28 00 00 00       	mov    $0x28,%eax
f010300b:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010300e:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103013:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103016:	5d                   	pop    %ebp
f0103017:	c3                   	ret    

f0103018 <trap_init>:
}


void
trap_init(void)
{
f0103018:	55                   	push   %ebp
f0103019:	89 e5                	mov    %esp,%ebp
	void th12();
	void th13();
	void th14();
	void th16();
	void th48();
	SETGATE(idt[0], 0, GD_KT, th0, 0);
f010301b:	b8 72 36 10 f0       	mov    $0xf0103672,%eax
f0103020:	66 a3 60 ce 17 f0    	mov    %ax,0xf017ce60
f0103026:	66 c7 05 62 ce 17 f0 	movw   $0x8,0xf017ce62
f010302d:	08 00 
f010302f:	c6 05 64 ce 17 f0 00 	movb   $0x0,0xf017ce64
f0103036:	c6 05 65 ce 17 f0 8e 	movb   $0x8e,0xf017ce65
f010303d:	c1 e8 10             	shr    $0x10,%eax
f0103040:	66 a3 66 ce 17 f0    	mov    %ax,0xf017ce66
	SETGATE(idt[1], 0, GD_KT, th1, 0);
f0103046:	b8 78 36 10 f0       	mov    $0xf0103678,%eax
f010304b:	66 a3 68 ce 17 f0    	mov    %ax,0xf017ce68
f0103051:	66 c7 05 6a ce 17 f0 	movw   $0x8,0xf017ce6a
f0103058:	08 00 
f010305a:	c6 05 6c ce 17 f0 00 	movb   $0x0,0xf017ce6c
f0103061:	c6 05 6d ce 17 f0 8e 	movb   $0x8e,0xf017ce6d
f0103068:	c1 e8 10             	shr    $0x10,%eax
f010306b:	66 a3 6e ce 17 f0    	mov    %ax,0xf017ce6e
	SETGATE(idt[3], 0, GD_KT, th3, 3);
f0103071:	b8 7e 36 10 f0       	mov    $0xf010367e,%eax
f0103076:	66 a3 78 ce 17 f0    	mov    %ax,0xf017ce78
f010307c:	66 c7 05 7a ce 17 f0 	movw   $0x8,0xf017ce7a
f0103083:	08 00 
f0103085:	c6 05 7c ce 17 f0 00 	movb   $0x0,0xf017ce7c
f010308c:	c6 05 7d ce 17 f0 ee 	movb   $0xee,0xf017ce7d
f0103093:	c1 e8 10             	shr    $0x10,%eax
f0103096:	66 a3 7e ce 17 f0    	mov    %ax,0xf017ce7e
	SETGATE(idt[4], 0, GD_KT, th4, 0);
f010309c:	b8 84 36 10 f0       	mov    $0xf0103684,%eax
f01030a1:	66 a3 80 ce 17 f0    	mov    %ax,0xf017ce80
f01030a7:	66 c7 05 82 ce 17 f0 	movw   $0x8,0xf017ce82
f01030ae:	08 00 
f01030b0:	c6 05 84 ce 17 f0 00 	movb   $0x0,0xf017ce84
f01030b7:	c6 05 85 ce 17 f0 8e 	movb   $0x8e,0xf017ce85
f01030be:	c1 e8 10             	shr    $0x10,%eax
f01030c1:	66 a3 86 ce 17 f0    	mov    %ax,0xf017ce86
	SETGATE(idt[5], 0, GD_KT, th5, 0);
f01030c7:	b8 8a 36 10 f0       	mov    $0xf010368a,%eax
f01030cc:	66 a3 88 ce 17 f0    	mov    %ax,0xf017ce88
f01030d2:	66 c7 05 8a ce 17 f0 	movw   $0x8,0xf017ce8a
f01030d9:	08 00 
f01030db:	c6 05 8c ce 17 f0 00 	movb   $0x0,0xf017ce8c
f01030e2:	c6 05 8d ce 17 f0 8e 	movb   $0x8e,0xf017ce8d
f01030e9:	c1 e8 10             	shr    $0x10,%eax
f01030ec:	66 a3 8e ce 17 f0    	mov    %ax,0xf017ce8e
	SETGATE(idt[6], 0, GD_KT, th6, 0);
f01030f2:	b8 90 36 10 f0       	mov    $0xf0103690,%eax
f01030f7:	66 a3 90 ce 17 f0    	mov    %ax,0xf017ce90
f01030fd:	66 c7 05 92 ce 17 f0 	movw   $0x8,0xf017ce92
f0103104:	08 00 
f0103106:	c6 05 94 ce 17 f0 00 	movb   $0x0,0xf017ce94
f010310d:	c6 05 95 ce 17 f0 8e 	movb   $0x8e,0xf017ce95
f0103114:	c1 e8 10             	shr    $0x10,%eax
f0103117:	66 a3 96 ce 17 f0    	mov    %ax,0xf017ce96
	SETGATE(idt[7], 0, GD_KT, th7, 0);
f010311d:	b8 96 36 10 f0       	mov    $0xf0103696,%eax
f0103122:	66 a3 98 ce 17 f0    	mov    %ax,0xf017ce98
f0103128:	66 c7 05 9a ce 17 f0 	movw   $0x8,0xf017ce9a
f010312f:	08 00 
f0103131:	c6 05 9c ce 17 f0 00 	movb   $0x0,0xf017ce9c
f0103138:	c6 05 9d ce 17 f0 8e 	movb   $0x8e,0xf017ce9d
f010313f:	c1 e8 10             	shr    $0x10,%eax
f0103142:	66 a3 9e ce 17 f0    	mov    %ax,0xf017ce9e
	SETGATE(idt[8], 0, GD_KT, th8, 0);
f0103148:	b8 9c 36 10 f0       	mov    $0xf010369c,%eax
f010314d:	66 a3 a0 ce 17 f0    	mov    %ax,0xf017cea0
f0103153:	66 c7 05 a2 ce 17 f0 	movw   $0x8,0xf017cea2
f010315a:	08 00 
f010315c:	c6 05 a4 ce 17 f0 00 	movb   $0x0,0xf017cea4
f0103163:	c6 05 a5 ce 17 f0 8e 	movb   $0x8e,0xf017cea5
f010316a:	c1 e8 10             	shr    $0x10,%eax
f010316d:	66 a3 a6 ce 17 f0    	mov    %ax,0xf017cea6
	SETGATE(idt[9], 0, GD_KT, th9, 0);
f0103173:	b8 a0 36 10 f0       	mov    $0xf01036a0,%eax
f0103178:	66 a3 a8 ce 17 f0    	mov    %ax,0xf017cea8
f010317e:	66 c7 05 aa ce 17 f0 	movw   $0x8,0xf017ceaa
f0103185:	08 00 
f0103187:	c6 05 ac ce 17 f0 00 	movb   $0x0,0xf017ceac
f010318e:	c6 05 ad ce 17 f0 8e 	movb   $0x8e,0xf017cead
f0103195:	c1 e8 10             	shr    $0x10,%eax
f0103198:	66 a3 ae ce 17 f0    	mov    %ax,0xf017ceae
	SETGATE(idt[10], 0, GD_KT, th10, 0);
f010319e:	b8 a6 36 10 f0       	mov    $0xf01036a6,%eax
f01031a3:	66 a3 b0 ce 17 f0    	mov    %ax,0xf017ceb0
f01031a9:	66 c7 05 b2 ce 17 f0 	movw   $0x8,0xf017ceb2
f01031b0:	08 00 
f01031b2:	c6 05 b4 ce 17 f0 00 	movb   $0x0,0xf017ceb4
f01031b9:	c6 05 b5 ce 17 f0 8e 	movb   $0x8e,0xf017ceb5
f01031c0:	c1 e8 10             	shr    $0x10,%eax
f01031c3:	66 a3 b6 ce 17 f0    	mov    %ax,0xf017ceb6
	SETGATE(idt[11], 0, GD_KT, th11, 0);
f01031c9:	b8 aa 36 10 f0       	mov    $0xf01036aa,%eax
f01031ce:	66 a3 b8 ce 17 f0    	mov    %ax,0xf017ceb8
f01031d4:	66 c7 05 ba ce 17 f0 	movw   $0x8,0xf017ceba
f01031db:	08 00 
f01031dd:	c6 05 bc ce 17 f0 00 	movb   $0x0,0xf017cebc
f01031e4:	c6 05 bd ce 17 f0 8e 	movb   $0x8e,0xf017cebd
f01031eb:	c1 e8 10             	shr    $0x10,%eax
f01031ee:	66 a3 be ce 17 f0    	mov    %ax,0xf017cebe
	SETGATE(idt[12], 0, GD_KT, th12, 0);
f01031f4:	b8 ae 36 10 f0       	mov    $0xf01036ae,%eax
f01031f9:	66 a3 c0 ce 17 f0    	mov    %ax,0xf017cec0
f01031ff:	66 c7 05 c2 ce 17 f0 	movw   $0x8,0xf017cec2
f0103206:	08 00 
f0103208:	c6 05 c4 ce 17 f0 00 	movb   $0x0,0xf017cec4
f010320f:	c6 05 c5 ce 17 f0 8e 	movb   $0x8e,0xf017cec5
f0103216:	c1 e8 10             	shr    $0x10,%eax
f0103219:	66 a3 c6 ce 17 f0    	mov    %ax,0xf017cec6
	SETGATE(idt[13], 0, GD_KT, th13, 0);
f010321f:	b8 b2 36 10 f0       	mov    $0xf01036b2,%eax
f0103224:	66 a3 c8 ce 17 f0    	mov    %ax,0xf017cec8
f010322a:	66 c7 05 ca ce 17 f0 	movw   $0x8,0xf017ceca
f0103231:	08 00 
f0103233:	c6 05 cc ce 17 f0 00 	movb   $0x0,0xf017cecc
f010323a:	c6 05 cd ce 17 f0 8e 	movb   $0x8e,0xf017cecd
f0103241:	c1 e8 10             	shr    $0x10,%eax
f0103244:	66 a3 ce ce 17 f0    	mov    %ax,0xf017cece
	SETGATE(idt[14], 0, GD_KT, th14, 0);
f010324a:	b8 b6 36 10 f0       	mov    $0xf01036b6,%eax
f010324f:	66 a3 d0 ce 17 f0    	mov    %ax,0xf017ced0
f0103255:	66 c7 05 d2 ce 17 f0 	movw   $0x8,0xf017ced2
f010325c:	08 00 
f010325e:	c6 05 d4 ce 17 f0 00 	movb   $0x0,0xf017ced4
f0103265:	c6 05 d5 ce 17 f0 8e 	movb   $0x8e,0xf017ced5
f010326c:	c1 e8 10             	shr    $0x10,%eax
f010326f:	66 a3 d6 ce 17 f0    	mov    %ax,0xf017ced6
	SETGATE(idt[16], 0, GD_KT, th16, 0);
f0103275:	b8 ba 36 10 f0       	mov    $0xf01036ba,%eax
f010327a:	66 a3 e0 ce 17 f0    	mov    %ax,0xf017cee0
f0103280:	66 c7 05 e2 ce 17 f0 	movw   $0x8,0xf017cee2
f0103287:	08 00 
f0103289:	c6 05 e4 ce 17 f0 00 	movb   $0x0,0xf017cee4
f0103290:	c6 05 e5 ce 17 f0 8e 	movb   $0x8e,0xf017cee5
f0103297:	c1 e8 10             	shr    $0x10,%eax
f010329a:	66 a3 e6 ce 17 f0    	mov    %ax,0xf017cee6
	SETGATE(idt[48], 0, GD_KT, th48, 3);
f01032a0:	b8 c0 36 10 f0       	mov    $0xf01036c0,%eax
f01032a5:	66 a3 e0 cf 17 f0    	mov    %ax,0xf017cfe0
f01032ab:	66 c7 05 e2 cf 17 f0 	movw   $0x8,0xf017cfe2
f01032b2:	08 00 
f01032b4:	c6 05 e4 cf 17 f0 00 	movb   $0x0,0xf017cfe4
f01032bb:	c6 05 e5 cf 17 f0 ee 	movb   $0xee,0xf017cfe5
f01032c2:	c1 e8 10             	shr    $0x10,%eax
f01032c5:	66 a3 e6 cf 17 f0    	mov    %ax,0xf017cfe6


	// Per-CPU setup 
	trap_init_percpu();
f01032cb:	e8 e2 fc ff ff       	call   f0102fb2 <trap_init_percpu>
}
f01032d0:	5d                   	pop    %ebp
f01032d1:	c3                   	ret    

f01032d2 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01032d2:	55                   	push   %ebp
f01032d3:	89 e5                	mov    %esp,%ebp
f01032d5:	53                   	push   %ebx
f01032d6:	83 ec 0c             	sub    $0xc,%esp
f01032d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032dc:	ff 33                	pushl  (%ebx)
f01032de:	68 f2 59 10 f0       	push   $0xf01059f2
f01032e3:	e8 b6 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032e8:	83 c4 08             	add    $0x8,%esp
f01032eb:	ff 73 04             	pushl  0x4(%ebx)
f01032ee:	68 01 5a 10 f0       	push   $0xf0105a01
f01032f3:	e8 a6 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01032f8:	83 c4 08             	add    $0x8,%esp
f01032fb:	ff 73 08             	pushl  0x8(%ebx)
f01032fe:	68 10 5a 10 f0       	push   $0xf0105a10
f0103303:	e8 96 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103308:	83 c4 08             	add    $0x8,%esp
f010330b:	ff 73 0c             	pushl  0xc(%ebx)
f010330e:	68 1f 5a 10 f0       	push   $0xf0105a1f
f0103313:	e8 86 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103318:	83 c4 08             	add    $0x8,%esp
f010331b:	ff 73 10             	pushl  0x10(%ebx)
f010331e:	68 2e 5a 10 f0       	push   $0xf0105a2e
f0103323:	e8 76 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103328:	83 c4 08             	add    $0x8,%esp
f010332b:	ff 73 14             	pushl  0x14(%ebx)
f010332e:	68 3d 5a 10 f0       	push   $0xf0105a3d
f0103333:	e8 66 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103338:	83 c4 08             	add    $0x8,%esp
f010333b:	ff 73 18             	pushl  0x18(%ebx)
f010333e:	68 4c 5a 10 f0       	push   $0xf0105a4c
f0103343:	e8 56 fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103348:	83 c4 08             	add    $0x8,%esp
f010334b:	ff 73 1c             	pushl  0x1c(%ebx)
f010334e:	68 5b 5a 10 f0       	push   $0xf0105a5b
f0103353:	e8 46 fc ff ff       	call   f0102f9e <cprintf>
}
f0103358:	83 c4 10             	add    $0x10,%esp
f010335b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010335e:	c9                   	leave  
f010335f:	c3                   	ret    

f0103360 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103360:	55                   	push   %ebp
f0103361:	89 e5                	mov    %esp,%ebp
f0103363:	56                   	push   %esi
f0103364:	53                   	push   %ebx
f0103365:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103368:	83 ec 08             	sub    $0x8,%esp
f010336b:	53                   	push   %ebx
f010336c:	68 a7 5b 10 f0       	push   $0xf0105ba7
f0103371:	e8 28 fc ff ff       	call   f0102f9e <cprintf>
	print_regs(&tf->tf_regs);
f0103376:	89 1c 24             	mov    %ebx,(%esp)
f0103379:	e8 54 ff ff ff       	call   f01032d2 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010337e:	83 c4 08             	add    $0x8,%esp
f0103381:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103385:	50                   	push   %eax
f0103386:	68 ac 5a 10 f0       	push   $0xf0105aac
f010338b:	e8 0e fc ff ff       	call   f0102f9e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103390:	83 c4 08             	add    $0x8,%esp
f0103393:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103397:	50                   	push   %eax
f0103398:	68 bf 5a 10 f0       	push   $0xf0105abf
f010339d:	e8 fc fb ff ff       	call   f0102f9e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033a2:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01033a5:	83 c4 10             	add    $0x10,%esp
f01033a8:	83 f8 13             	cmp    $0x13,%eax
f01033ab:	77 09                	ja     f01033b6 <print_trapframe+0x56>
		return excnames[trapno];
f01033ad:	8b 14 85 80 5d 10 f0 	mov    -0xfefa280(,%eax,4),%edx
f01033b4:	eb 10                	jmp    f01033c6 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01033b6:	83 f8 30             	cmp    $0x30,%eax
f01033b9:	b9 76 5a 10 f0       	mov    $0xf0105a76,%ecx
f01033be:	ba 6a 5a 10 f0       	mov    $0xf0105a6a,%edx
f01033c3:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033c6:	83 ec 04             	sub    $0x4,%esp
f01033c9:	52                   	push   %edx
f01033ca:	50                   	push   %eax
f01033cb:	68 d2 5a 10 f0       	push   $0xf0105ad2
f01033d0:	e8 c9 fb ff ff       	call   f0102f9e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01033d5:	83 c4 10             	add    $0x10,%esp
f01033d8:	3b 1d 60 d6 17 f0    	cmp    0xf017d660,%ebx
f01033de:	75 1a                	jne    f01033fa <print_trapframe+0x9a>
f01033e0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033e4:	75 14                	jne    f01033fa <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01033e6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033e9:	83 ec 08             	sub    $0x8,%esp
f01033ec:	50                   	push   %eax
f01033ed:	68 e4 5a 10 f0       	push   $0xf0105ae4
f01033f2:	e8 a7 fb ff ff       	call   f0102f9e <cprintf>
f01033f7:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01033fa:	83 ec 08             	sub    $0x8,%esp
f01033fd:	ff 73 2c             	pushl  0x2c(%ebx)
f0103400:	68 f3 5a 10 f0       	push   $0xf0105af3
f0103405:	e8 94 fb ff ff       	call   f0102f9e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010340a:	83 c4 10             	add    $0x10,%esp
f010340d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103411:	75 49                	jne    f010345c <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103413:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103416:	89 c2                	mov    %eax,%edx
f0103418:	83 e2 01             	and    $0x1,%edx
f010341b:	ba 90 5a 10 f0       	mov    $0xf0105a90,%edx
f0103420:	b9 85 5a 10 f0       	mov    $0xf0105a85,%ecx
f0103425:	0f 44 ca             	cmove  %edx,%ecx
f0103428:	89 c2                	mov    %eax,%edx
f010342a:	83 e2 02             	and    $0x2,%edx
f010342d:	ba a2 5a 10 f0       	mov    $0xf0105aa2,%edx
f0103432:	be 9c 5a 10 f0       	mov    $0xf0105a9c,%esi
f0103437:	0f 45 d6             	cmovne %esi,%edx
f010343a:	83 e0 04             	and    $0x4,%eax
f010343d:	be d2 5b 10 f0       	mov    $0xf0105bd2,%esi
f0103442:	b8 a7 5a 10 f0       	mov    $0xf0105aa7,%eax
f0103447:	0f 44 c6             	cmove  %esi,%eax
f010344a:	51                   	push   %ecx
f010344b:	52                   	push   %edx
f010344c:	50                   	push   %eax
f010344d:	68 01 5b 10 f0       	push   $0xf0105b01
f0103452:	e8 47 fb ff ff       	call   f0102f9e <cprintf>
f0103457:	83 c4 10             	add    $0x10,%esp
f010345a:	eb 10                	jmp    f010346c <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010345c:	83 ec 0c             	sub    $0xc,%esp
f010345f:	68 8a 50 10 f0       	push   $0xf010508a
f0103464:	e8 35 fb ff ff       	call   f0102f9e <cprintf>
f0103469:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010346c:	83 ec 08             	sub    $0x8,%esp
f010346f:	ff 73 30             	pushl  0x30(%ebx)
f0103472:	68 10 5b 10 f0       	push   $0xf0105b10
f0103477:	e8 22 fb ff ff       	call   f0102f9e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010347c:	83 c4 08             	add    $0x8,%esp
f010347f:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103483:	50                   	push   %eax
f0103484:	68 1f 5b 10 f0       	push   $0xf0105b1f
f0103489:	e8 10 fb ff ff       	call   f0102f9e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010348e:	83 c4 08             	add    $0x8,%esp
f0103491:	ff 73 38             	pushl  0x38(%ebx)
f0103494:	68 32 5b 10 f0       	push   $0xf0105b32
f0103499:	e8 00 fb ff ff       	call   f0102f9e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010349e:	83 c4 10             	add    $0x10,%esp
f01034a1:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034a5:	74 25                	je     f01034cc <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01034a7:	83 ec 08             	sub    $0x8,%esp
f01034aa:	ff 73 3c             	pushl  0x3c(%ebx)
f01034ad:	68 41 5b 10 f0       	push   $0xf0105b41
f01034b2:	e8 e7 fa ff ff       	call   f0102f9e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01034b7:	83 c4 08             	add    $0x8,%esp
f01034ba:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01034be:	50                   	push   %eax
f01034bf:	68 50 5b 10 f0       	push   $0xf0105b50
f01034c4:	e8 d5 fa ff ff       	call   f0102f9e <cprintf>
f01034c9:	83 c4 10             	add    $0x10,%esp
	}
}
f01034cc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034cf:	5b                   	pop    %ebx
f01034d0:	5e                   	pop    %esi
f01034d1:	5d                   	pop    %ebp
f01034d2:	c3                   	ret    

f01034d3 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034d3:	55                   	push   %ebp
f01034d4:	89 e5                	mov    %esp,%ebp
f01034d6:	56                   	push   %esi
f01034d7:	53                   	push   %ebx
f01034d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034db:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f01034de:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f01034e3:	75 1e                	jne    f0103503 <page_fault_handler+0x30>
		print_trapframe(tf);
f01034e5:	83 ec 0c             	sub    $0xc,%esp
f01034e8:	53                   	push   %ebx
f01034e9:	e8 72 fe ff ff       	call   f0103360 <print_trapframe>
		panic("kernel fault va %08x\n", fault_va);
f01034ee:	56                   	push   %esi
f01034ef:	68 63 5b 10 f0       	push   $0xf0105b63
f01034f4:	68 03 01 00 00       	push   $0x103
f01034f9:	68 79 5b 10 f0       	push   $0xf0105b79
f01034fe:	e8 9d cb ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103503:	ff 73 30             	pushl  0x30(%ebx)
f0103506:	56                   	push   %esi
f0103507:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f010350c:	ff 70 48             	pushl  0x48(%eax)
f010350f:	68 1c 5d 10 f0       	push   $0xf0105d1c
f0103514:	e8 85 fa ff ff       	call   f0102f9e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103519:	89 1c 24             	mov    %ebx,(%esp)
f010351c:	e8 3f fe ff ff       	call   f0103360 <print_trapframe>
	env_destroy(curenv);
f0103521:	83 c4 04             	add    $0x4,%esp
f0103524:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f010352a:	e8 58 f9 ff ff       	call   f0102e87 <env_destroy>
}
f010352f:	83 c4 10             	add    $0x10,%esp
f0103532:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103535:	5b                   	pop    %ebx
f0103536:	5e                   	pop    %esi
f0103537:	5d                   	pop    %ebp
f0103538:	c3                   	ret    

f0103539 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103539:	55                   	push   %ebp
f010353a:	89 e5                	mov    %esp,%ebp
f010353c:	57                   	push   %edi
f010353d:	56                   	push   %esi
f010353e:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103541:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103542:	9c                   	pushf  
f0103543:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103544:	f6 c4 02             	test   $0x2,%ah
f0103547:	74 19                	je     f0103562 <trap+0x29>
f0103549:	68 85 5b 10 f0       	push   $0xf0105b85
f010354e:	68 96 4d 10 f0       	push   $0xf0104d96
f0103553:	68 d9 00 00 00       	push   $0xd9
f0103558:	68 79 5b 10 f0       	push   $0xf0105b79
f010355d:	e8 3e cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103562:	83 ec 08             	sub    $0x8,%esp
f0103565:	56                   	push   %esi
f0103566:	68 9e 5b 10 f0       	push   $0xf0105b9e
f010356b:	e8 2e fa ff ff       	call   f0102f9e <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103570:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103574:	83 e0 03             	and    $0x3,%eax
f0103577:	83 c4 10             	add    $0x10,%esp
f010357a:	66 83 f8 03          	cmp    $0x3,%ax
f010357e:	75 31                	jne    f01035b1 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103580:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0103585:	85 c0                	test   %eax,%eax
f0103587:	75 19                	jne    f01035a2 <trap+0x69>
f0103589:	68 b9 5b 10 f0       	push   $0xf0105bb9
f010358e:	68 96 4d 10 f0       	push   $0xf0104d96
f0103593:	68 df 00 00 00       	push   $0xdf
f0103598:	68 79 5b 10 f0       	push   $0xf0105b79
f010359d:	e8 fe ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01035a2:	b9 11 00 00 00       	mov    $0x11,%ecx
f01035a7:	89 c7                	mov    %eax,%edi
f01035a9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01035ab:	8b 35 48 ce 17 f0    	mov    0xf017ce48,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01035b1:	89 35 60 d6 17 f0    	mov    %esi,0xf017d660
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) {
f01035b7:	8b 46 28             	mov    0x28(%esi),%eax
f01035ba:	83 f8 0e             	cmp    $0xe,%eax
f01035bd:	75 0e                	jne    f01035cd <trap+0x94>
		page_fault_handler(tf);
f01035bf:	83 ec 0c             	sub    $0xc,%esp
f01035c2:	56                   	push   %esi
f01035c3:	e8 0b ff ff ff       	call   f01034d3 <page_fault_handler>
f01035c8:	83 c4 10             	add    $0x10,%esp
f01035cb:	eb 74                	jmp    f0103641 <trap+0x108>
		return;
	}
	if (tf->tf_trapno == T_BRKPT) {
f01035cd:	83 f8 03             	cmp    $0x3,%eax
f01035d0:	75 0e                	jne    f01035e0 <trap+0xa7>
	monitor(tf);
f01035d2:	83 ec 0c             	sub    $0xc,%esp
f01035d5:	56                   	push   %esi
f01035d6:	e8 de d1 ff ff       	call   f01007b9 <monitor>
f01035db:	83 c4 10             	add    $0x10,%esp
f01035de:	eb 61                	jmp    f0103641 <trap+0x108>
	return;
	}
	if (tf->tf_trapno == T_SYSCALL) {
f01035e0:	83 f8 30             	cmp    $0x30,%eax
f01035e3:	75 21                	jne    f0103606 <trap+0xcd>
		
		tf->tf_regs.reg_eax = 
			syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f01035e5:	83 ec 08             	sub    $0x8,%esp
f01035e8:	ff 76 04             	pushl  0x4(%esi)
f01035eb:	ff 36                	pushl  (%esi)
f01035ed:	ff 76 10             	pushl  0x10(%esi)
f01035f0:	ff 76 18             	pushl  0x18(%esi)
f01035f3:	ff 76 14             	pushl  0x14(%esi)
f01035f6:	ff 76 1c             	pushl  0x1c(%esi)
f01035f9:	e8 d7 00 00 00       	call   f01036d5 <syscall>
	monitor(tf);
	return;
	}
	if (tf->tf_trapno == T_SYSCALL) {
		
		tf->tf_regs.reg_eax = 
f01035fe:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103601:	83 c4 20             	add    $0x20,%esp
f0103604:	eb 3b                	jmp    f0103641 <trap+0x108>
			syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
				tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103606:	83 ec 0c             	sub    $0xc,%esp
f0103609:	56                   	push   %esi
f010360a:	e8 51 fd ff ff       	call   f0103360 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010360f:	83 c4 10             	add    $0x10,%esp
f0103612:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103617:	75 17                	jne    f0103630 <trap+0xf7>
		panic("unhandled trap in kernel");
f0103619:	83 ec 04             	sub    $0x4,%esp
f010361c:	68 c0 5b 10 f0       	push   $0xf0105bc0
f0103621:	68 c8 00 00 00       	push   $0xc8
f0103626:	68 79 5b 10 f0       	push   $0xf0105b79
f010362b:	e8 70 ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103630:	83 ec 0c             	sub    $0xc,%esp
f0103633:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f0103639:	e8 49 f8 ff ff       	call   f0102e87 <env_destroy>
f010363e:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103641:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0103646:	85 c0                	test   %eax,%eax
f0103648:	74 06                	je     f0103650 <trap+0x117>
f010364a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010364e:	74 19                	je     f0103669 <trap+0x130>
f0103650:	68 40 5d 10 f0       	push   $0xf0105d40
f0103655:	68 96 4d 10 f0       	push   $0xf0104d96
f010365a:	68 f1 00 00 00       	push   $0xf1
f010365f:	68 79 5b 10 f0       	push   $0xf0105b79
f0103664:	e8 37 ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103669:	83 ec 0c             	sub    $0xc,%esp
f010366c:	50                   	push   %eax
f010366d:	e8 65 f8 ff ff       	call   f0102ed7 <env_run>

f0103672 <th0>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

	TRAPHANDLER_NOEC(th0, 0)
f0103672:	6a 00                	push   $0x0
f0103674:	6a 00                	push   $0x0
f0103676:	eb 4e                	jmp    f01036c6 <_alltraps>

f0103678 <th1>:
	TRAPHANDLER_NOEC(th1, 1)
f0103678:	6a 00                	push   $0x0
f010367a:	6a 01                	push   $0x1
f010367c:	eb 48                	jmp    f01036c6 <_alltraps>

f010367e <th3>:
	TRAPHANDLER_NOEC(th3, 3)
f010367e:	6a 00                	push   $0x0
f0103680:	6a 03                	push   $0x3
f0103682:	eb 42                	jmp    f01036c6 <_alltraps>

f0103684 <th4>:
	TRAPHANDLER_NOEC(th4, 4)
f0103684:	6a 00                	push   $0x0
f0103686:	6a 04                	push   $0x4
f0103688:	eb 3c                	jmp    f01036c6 <_alltraps>

f010368a <th5>:
	TRAPHANDLER_NOEC(th5, 5)
f010368a:	6a 00                	push   $0x0
f010368c:	6a 05                	push   $0x5
f010368e:	eb 36                	jmp    f01036c6 <_alltraps>

f0103690 <th6>:
	TRAPHANDLER_NOEC(th6, 6)
f0103690:	6a 00                	push   $0x0
f0103692:	6a 06                	push   $0x6
f0103694:	eb 30                	jmp    f01036c6 <_alltraps>

f0103696 <th7>:
	TRAPHANDLER_NOEC(th7, 7)
f0103696:	6a 00                	push   $0x0
f0103698:	6a 07                	push   $0x7
f010369a:	eb 2a                	jmp    f01036c6 <_alltraps>

f010369c <th8>:
	TRAPHANDLER(th8, 8)
f010369c:	6a 08                	push   $0x8
f010369e:	eb 26                	jmp    f01036c6 <_alltraps>

f01036a0 <th9>:
	TRAPHANDLER_NOEC(th9, 9)
f01036a0:	6a 00                	push   $0x0
f01036a2:	6a 09                	push   $0x9
f01036a4:	eb 20                	jmp    f01036c6 <_alltraps>

f01036a6 <th10>:
	TRAPHANDLER(th10, 10)
f01036a6:	6a 0a                	push   $0xa
f01036a8:	eb 1c                	jmp    f01036c6 <_alltraps>

f01036aa <th11>:
	TRAPHANDLER(th11, 11)
f01036aa:	6a 0b                	push   $0xb
f01036ac:	eb 18                	jmp    f01036c6 <_alltraps>

f01036ae <th12>:
	TRAPHANDLER(th12, 12)
f01036ae:	6a 0c                	push   $0xc
f01036b0:	eb 14                	jmp    f01036c6 <_alltraps>

f01036b2 <th13>:
	TRAPHANDLER(th13, 13)
f01036b2:	6a 0d                	push   $0xd
f01036b4:	eb 10                	jmp    f01036c6 <_alltraps>

f01036b6 <th14>:
	TRAPHANDLER(th14, 14)
f01036b6:	6a 0e                	push   $0xe
f01036b8:	eb 0c                	jmp    f01036c6 <_alltraps>

f01036ba <th16>:
	TRAPHANDLER_NOEC(th16, 16)
f01036ba:	6a 00                	push   $0x0
f01036bc:	6a 10                	push   $0x10
f01036be:	eb 06                	jmp    f01036c6 <_alltraps>

f01036c0 <th48>:
	TRAPHANDLER_NOEC(th48,48)
f01036c0:	6a 00                	push   $0x0
f01036c2:	6a 30                	push   $0x30
f01036c4:	eb 00                	jmp    f01036c6 <_alltraps>

f01036c6 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f01036c6:	1e                   	push   %ds
	pushl %es
f01036c7:	06                   	push   %es
	pushal
f01036c8:	60                   	pusha  
	pushl $GD_KD
f01036c9:	6a 10                	push   $0x10
	popl %ds
f01036cb:	1f                   	pop    %ds
	pushl $GD_KD
f01036cc:	6a 10                	push   $0x10
	popl %es
f01036ce:	07                   	pop    %es
	pushl %esp
f01036cf:	54                   	push   %esp
	call trap
f01036d0:	e8 64 fe ff ff       	call   f0103539 <trap>

f01036d5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01036d5:	55                   	push   %ebp
f01036d6:	89 e5                	mov    %esp,%ebp
f01036d8:	83 ec 18             	sub    $0x18,%esp
f01036db:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int ret = 0;
	switch (syscallno) {
f01036de:	83 f8 01             	cmp    $0x1,%eax
f01036e1:	74 57                	je     f010373a <syscall+0x65>
f01036e3:	83 f8 01             	cmp    $0x1,%eax
f01036e6:	72 0f                	jb     f01036f7 <syscall+0x22>
f01036e8:	83 f8 02             	cmp    $0x2,%eax
f01036eb:	74 54                	je     f0103741 <syscall+0x6c>
f01036ed:	83 f8 03             	cmp    $0x3,%eax
f01036f0:	74 59                	je     f010374b <syscall+0x76>
f01036f2:	e9 b9 00 00 00       	jmp    f01037b0 <syscall+0xdb>
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	struct Env *e;
	envid2env(sys_getenvid(), &e, 1);
f01036f7:	83 ec 04             	sub    $0x4,%esp
f01036fa:	6a 01                	push   $0x1
f01036fc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036ff:	50                   	push   %eax
// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	// cprintf("sys curenv_id: %x\n", curenv->env_id);
	return curenv->env_id;
f0103700:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	struct Env *e;
	envid2env(sys_getenvid(), &e, 1);
f0103705:	ff 70 48             	pushl  0x48(%eax)
f0103708:	e8 32 f2 ff ff       	call   f010293f <envid2env>
	user_mem_assert(e, s, len, PTE_U);
f010370d:	6a 04                	push   $0x4
f010370f:	ff 75 10             	pushl  0x10(%ebp)
f0103712:	ff 75 0c             	pushl  0xc(%ebp)
f0103715:	ff 75 f4             	pushl  -0xc(%ebp)
f0103718:	e8 6d f1 ff ff       	call   f010288a <user_mem_assert>
	//user_mem_check(struct Env *env, const void *va, size_t len, int perm)

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010371d:	83 c4 1c             	add    $0x1c,%esp
f0103720:	ff 75 0c             	pushl  0xc(%ebp)
f0103723:	ff 75 10             	pushl  0x10(%ebp)
f0103726:	68 d0 5d 10 f0       	push   $0xf0105dd0
f010372b:	e8 6e f8 ff ff       	call   f0102f9e <cprintf>
f0103730:	83 c4 10             	add    $0x10,%esp
	// LAB 3: Your code here.
	int ret = 0;
	switch (syscallno) {
		case SYS_cputs: 
			sys_cputs((char*)a1, a2);
			ret = 0;
f0103733:	b8 00 00 00 00       	mov    $0x0,%eax
f0103738:	eb 7b                	jmp    f01037b5 <syscall+0xe0>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010373a:	e8 84 cd ff ff       	call   f01004c3 <cons_getc>
			sys_cputs((char*)a1, a2);
			ret = 0;
			break;
		case SYS_cgetc:
			ret = sys_cgetc();
			break;
f010373f:	eb 74                	jmp    f01037b5 <syscall+0xe0>
// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	// cprintf("sys curenv_id: %x\n", curenv->env_id);
	return curenv->env_id;
f0103741:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0103746:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_cgetc:
			ret = sys_cgetc();
			break;
		case SYS_getenvid:
			ret = sys_getenvid();
			break;
f0103749:	eb 6a                	jmp    f01037b5 <syscall+0xe0>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010374b:	83 ec 04             	sub    $0x4,%esp
f010374e:	6a 01                	push   $0x1
f0103750:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103753:	50                   	push   %eax
f0103754:	ff 75 0c             	pushl  0xc(%ebp)
f0103757:	e8 e3 f1 ff ff       	call   f010293f <envid2env>
f010375c:	83 c4 10             	add    $0x10,%esp
f010375f:	85 c0                	test   %eax,%eax
f0103761:	78 46                	js     f01037a9 <syscall+0xd4>
		return r;
	if (e == curenv)
f0103763:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103766:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f010376c:	39 d0                	cmp    %edx,%eax
f010376e:	75 15                	jne    f0103785 <syscall+0xb0>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103770:	83 ec 08             	sub    $0x8,%esp
f0103773:	ff 70 48             	pushl  0x48(%eax)
f0103776:	68 d5 5d 10 f0       	push   $0xf0105dd5
f010377b:	e8 1e f8 ff ff       	call   f0102f9e <cprintf>
f0103780:	83 c4 10             	add    $0x10,%esp
f0103783:	eb 16                	jmp    f010379b <syscall+0xc6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103785:	83 ec 04             	sub    $0x4,%esp
f0103788:	ff 70 48             	pushl  0x48(%eax)
f010378b:	ff 72 48             	pushl  0x48(%edx)
f010378e:	68 f0 5d 10 f0       	push   $0xf0105df0
f0103793:	e8 06 f8 ff ff       	call   f0102f9e <cprintf>
f0103798:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010379b:	83 ec 0c             	sub    $0xc,%esp
f010379e:	ff 75 f4             	pushl  -0xc(%ebp)
f01037a1:	e8 e1 f6 ff ff       	call   f0102e87 <env_destroy>
f01037a6:	83 c4 10             	add    $0x10,%esp
		case SYS_getenvid:
			ret = sys_getenvid();
			break;
		case SYS_env_destroy:
			sys_env_destroy(a1);
			ret = 0;
f01037a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01037ae:	eb 05                	jmp    f01037b5 <syscall+0xe0>
			break;
		default:
			ret = -E_INVAL;
f01037b0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	// cprintf("ret: %x\n", ret);
	return ret;
	panic("syscall not implemented");
}
f01037b5:	c9                   	leave  
f01037b6:	c3                   	ret    

f01037b7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01037b7:	55                   	push   %ebp
f01037b8:	89 e5                	mov    %esp,%ebp
f01037ba:	57                   	push   %edi
f01037bb:	56                   	push   %esi
f01037bc:	53                   	push   %ebx
f01037bd:	83 ec 14             	sub    $0x14,%esp
f01037c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037c3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01037c6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01037c9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01037cc:	8b 1a                	mov    (%edx),%ebx
f01037ce:	8b 01                	mov    (%ecx),%eax
f01037d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037d3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01037da:	eb 7f                	jmp    f010385b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01037dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01037df:	01 d8                	add    %ebx,%eax
f01037e1:	89 c6                	mov    %eax,%esi
f01037e3:	c1 ee 1f             	shr    $0x1f,%esi
f01037e6:	01 c6                	add    %eax,%esi
f01037e8:	d1 fe                	sar    %esi
f01037ea:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01037ed:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037f0:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01037f3:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037f5:	eb 03                	jmp    f01037fa <stab_binsearch+0x43>
			m--;
f01037f7:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037fa:	39 c3                	cmp    %eax,%ebx
f01037fc:	7f 0d                	jg     f010380b <stab_binsearch+0x54>
f01037fe:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103802:	83 ea 0c             	sub    $0xc,%edx
f0103805:	39 f9                	cmp    %edi,%ecx
f0103807:	75 ee                	jne    f01037f7 <stab_binsearch+0x40>
f0103809:	eb 05                	jmp    f0103810 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010380b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010380e:	eb 4b                	jmp    f010385b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103810:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103813:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103816:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010381a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010381d:	76 11                	jbe    f0103830 <stab_binsearch+0x79>
			*region_left = m;
f010381f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103822:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103824:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103827:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010382e:	eb 2b                	jmp    f010385b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103830:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103833:	73 14                	jae    f0103849 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103835:	83 e8 01             	sub    $0x1,%eax
f0103838:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010383b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010383e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103840:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103847:	eb 12                	jmp    f010385b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103849:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010384c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010384e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103852:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103854:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010385b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010385e:	0f 8e 78 ff ff ff    	jle    f01037dc <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103864:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103868:	75 0f                	jne    f0103879 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010386a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010386d:	8b 00                	mov    (%eax),%eax
f010386f:	83 e8 01             	sub    $0x1,%eax
f0103872:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103875:	89 06                	mov    %eax,(%esi)
f0103877:	eb 2c                	jmp    f01038a5 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103879:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010387c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010387e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103881:	8b 0e                	mov    (%esi),%ecx
f0103883:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103886:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103889:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010388c:	eb 03                	jmp    f0103891 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010388e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103891:	39 c8                	cmp    %ecx,%eax
f0103893:	7e 0b                	jle    f01038a0 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103895:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103899:	83 ea 0c             	sub    $0xc,%edx
f010389c:	39 df                	cmp    %ebx,%edi
f010389e:	75 ee                	jne    f010388e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01038a0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038a3:	89 06                	mov    %eax,(%esi)
	}
}
f01038a5:	83 c4 14             	add    $0x14,%esp
f01038a8:	5b                   	pop    %ebx
f01038a9:	5e                   	pop    %esi
f01038aa:	5f                   	pop    %edi
f01038ab:	5d                   	pop    %ebp
f01038ac:	c3                   	ret    

f01038ad <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01038ad:	55                   	push   %ebp
f01038ae:	89 e5                	mov    %esp,%ebp
f01038b0:	57                   	push   %edi
f01038b1:	56                   	push   %esi
f01038b2:	53                   	push   %ebx
f01038b3:	83 ec 3c             	sub    $0x3c,%esp
f01038b6:	8b 75 08             	mov    0x8(%ebp),%esi
f01038b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01038bc:	c7 03 08 5e 10 f0    	movl   $0xf0105e08,(%ebx)
	info->eip_line = 0;
f01038c2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01038c9:	c7 43 08 08 5e 10 f0 	movl   $0xf0105e08,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01038d0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01038d7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01038da:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01038e1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01038e7:	77 7e                	ja     f0103967 <debuginfo_eip+0xba>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01038e9:	a1 00 00 20 00       	mov    0x200000,%eax
f01038ee:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01038f1:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f01038f7:	a1 08 00 20 00       	mov    0x200008,%eax
f01038fc:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01038ff:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0103905:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f0103908:	6a 04                	push   $0x4
f010390a:	6a 10                	push   $0x10
f010390c:	68 00 00 20 00       	push   $0x200000
f0103911:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f0103917:	e8 c1 ee ff ff       	call   f01027dd <user_mem_check>
f010391c:	83 c4 10             	add    $0x10,%esp
f010391f:	85 c0                	test   %eax,%eax
f0103921:	0f 85 0a 02 00 00    	jne    f0103b31 <debuginfo_eip+0x284>
		return -1;
		

		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
f0103927:	6a 04                	push   $0x4
f0103929:	6a 0c                	push   $0xc
f010392b:	ff 75 c0             	pushl  -0x40(%ebp)
f010392e:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f0103934:	e8 a4 ee ff ff       	call   f01027dd <user_mem_check>
f0103939:	83 c4 10             	add    $0x10,%esp
f010393c:	85 c0                	test   %eax,%eax
f010393e:	0f 85 f4 01 00 00    	jne    f0103b38 <debuginfo_eip+0x28b>
		return -1;

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
f0103944:	6a 04                	push   $0x4
f0103946:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103949:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010394c:	29 ca                	sub    %ecx,%edx
f010394e:	52                   	push   %edx
f010394f:	51                   	push   %ecx
f0103950:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f0103956:	e8 82 ee ff ff       	call   f01027dd <user_mem_check>
f010395b:	83 c4 10             	add    $0x10,%esp
f010395e:	85 c0                	test   %eax,%eax
f0103960:	74 1f                	je     f0103981 <debuginfo_eip+0xd4>
f0103962:	e9 d8 01 00 00       	jmp    f0103b3f <debuginfo_eip+0x292>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103967:	c7 45 bc 63 03 11 f0 	movl   $0xf0110363,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010396e:	c7 45 b8 59 d9 10 f0 	movl   $0xf010d959,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103975:	bf 58 d9 10 f0       	mov    $0xf010d958,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010397a:	c7 45 c0 20 60 10 f0 	movl   $0xf0106020,-0x40(%ebp)
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
		return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103981:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103984:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103987:	0f 83 b9 01 00 00    	jae    f0103b46 <debuginfo_eip+0x299>
f010398d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103991:	0f 85 b6 01 00 00    	jne    f0103b4d <debuginfo_eip+0x2a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103997:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010399e:	2b 7d c0             	sub    -0x40(%ebp),%edi
f01039a1:	c1 ff 02             	sar    $0x2,%edi
f01039a4:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f01039aa:	83 e8 01             	sub    $0x1,%eax
f01039ad:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01039b0:	83 ec 08             	sub    $0x8,%esp
f01039b3:	56                   	push   %esi
f01039b4:	6a 64                	push   $0x64
f01039b6:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01039b9:	89 d1                	mov    %edx,%ecx
f01039bb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039be:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01039c1:	89 f8                	mov    %edi,%eax
f01039c3:	e8 ef fd ff ff       	call   f01037b7 <stab_binsearch>
	if (lfile == 0)
f01039c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039cb:	83 c4 10             	add    $0x10,%esp
f01039ce:	85 c0                	test   %eax,%eax
f01039d0:	0f 84 7e 01 00 00    	je     f0103b54 <debuginfo_eip+0x2a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039df:	83 ec 08             	sub    $0x8,%esp
f01039e2:	56                   	push   %esi
f01039e3:	6a 24                	push   $0x24
f01039e5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01039e8:	89 d1                	mov    %edx,%ecx
f01039ea:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039ed:	89 f8                	mov    %edi,%eax
f01039ef:	e8 c3 fd ff ff       	call   f01037b7 <stab_binsearch>

	if (lfun <= rfun) {
f01039f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039f7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039fa:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01039fd:	83 c4 10             	add    $0x10,%esp
f0103a00:	39 d0                	cmp    %edx,%eax
f0103a02:	7f 2b                	jg     f0103a2f <debuginfo_eip+0x182>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103a04:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a07:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103a0a:	8b 11                	mov    (%ecx),%edx
f0103a0c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a0f:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103a12:	39 fa                	cmp    %edi,%edx
f0103a14:	73 06                	jae    f0103a1c <debuginfo_eip+0x16f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103a16:	03 55 b8             	add    -0x48(%ebp),%edx
f0103a19:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a1c:	8b 51 08             	mov    0x8(%ecx),%edx
f0103a1f:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103a22:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103a24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103a27:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103a2a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a2d:	eb 0f                	jmp    f0103a3e <debuginfo_eip+0x191>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a2f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103a32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a35:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103a38:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a3b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a3e:	83 ec 08             	sub    $0x8,%esp
f0103a41:	6a 3a                	push   $0x3a
f0103a43:	ff 73 08             	pushl  0x8(%ebx)
f0103a46:	e8 16 09 00 00       	call   f0104361 <strfind>
f0103a4b:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a4e:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	which one.
	// Your code here.
 
//	If *region_left > *region_right, then 'addr' is not contained in any
//	matching stab.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103a51:	83 c4 08             	add    $0x8,%esp
f0103a54:	56                   	push   %esi
f0103a55:	6a 44                	push   $0x44
f0103a57:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a5a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a5d:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103a60:	89 f0                	mov    %esi,%eax
f0103a62:	e8 50 fd ff ff       	call   f01037b7 <stab_binsearch>
                 if(lline > rline)
f0103a67:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103a6a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a6d:	83 c4 10             	add    $0x10,%esp
f0103a70:	39 c2                	cmp    %eax,%edx
f0103a72:	0f 8f e3 00 00 00    	jg     f0103b5b <debuginfo_eip+0x2ae>
                 return -1;
		 info->eip_line = stabs[rline].n_desc;
f0103a78:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a7b:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103a80:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a86:	89 d0                	mov    %edx,%eax
f0103a88:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103a8b:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103a8e:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103a92:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a95:	eb 0a                	jmp    f0103aa1 <debuginfo_eip+0x1f4>
f0103a97:	83 e8 01             	sub    $0x1,%eax
f0103a9a:	83 ea 0c             	sub    $0xc,%edx
f0103a9d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103aa1:	39 c7                	cmp    %eax,%edi
f0103aa3:	7e 05                	jle    f0103aaa <debuginfo_eip+0x1fd>
f0103aa5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aa8:	eb 47                	jmp    f0103af1 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0103aaa:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103aae:	80 f9 84             	cmp    $0x84,%cl
f0103ab1:	75 0e                	jne    f0103ac1 <debuginfo_eip+0x214>
f0103ab3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ab6:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103aba:	74 1c                	je     f0103ad8 <debuginfo_eip+0x22b>
f0103abc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103abf:	eb 17                	jmp    f0103ad8 <debuginfo_eip+0x22b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103ac1:	80 f9 64             	cmp    $0x64,%cl
f0103ac4:	75 d1                	jne    f0103a97 <debuginfo_eip+0x1ea>
f0103ac6:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103aca:	74 cb                	je     f0103a97 <debuginfo_eip+0x1ea>
f0103acc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103acf:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103ad3:	74 03                	je     f0103ad8 <debuginfo_eip+0x22b>
f0103ad5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ad8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103adb:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103ade:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103ae1:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103ae4:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ae7:	29 f8                	sub    %edi,%eax
f0103ae9:	39 c2                	cmp    %eax,%edx
f0103aeb:	73 04                	jae    f0103af1 <debuginfo_eip+0x244>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103aed:	01 fa                	add    %edi,%edx
f0103aef:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103af1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103af4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103af7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103afc:	39 f2                	cmp    %esi,%edx
f0103afe:	7d 67                	jge    f0103b67 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
f0103b00:	83 c2 01             	add    $0x1,%edx
f0103b03:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103b06:	89 d0                	mov    %edx,%eax
f0103b08:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103b0b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b0e:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103b11:	eb 04                	jmp    f0103b17 <debuginfo_eip+0x26a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103b13:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103b17:	39 c6                	cmp    %eax,%esi
f0103b19:	7e 47                	jle    f0103b62 <debuginfo_eip+0x2b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103b1b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103b1f:	83 c0 01             	add    $0x1,%eax
f0103b22:	83 c2 0c             	add    $0xc,%edx
f0103b25:	80 f9 a0             	cmp    $0xa0,%cl
f0103b28:	74 e9                	je     f0103b13 <debuginfo_eip+0x266>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b2f:	eb 36                	jmp    f0103b67 <debuginfo_eip+0x2ba>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
		return -1;
f0103b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b36:	eb 2f                	jmp    f0103b67 <debuginfo_eip+0x2ba>
		

		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
		return -1;
f0103b38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b3d:	eb 28                	jmp    f0103b67 <debuginfo_eip+0x2ba>

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
		return -1;
f0103b3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b44:	eb 21                	jmp    f0103b67 <debuginfo_eip+0x2ba>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b46:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b4b:	eb 1a                	jmp    f0103b67 <debuginfo_eip+0x2ba>
f0103b4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b52:	eb 13                	jmp    f0103b67 <debuginfo_eip+0x2ba>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b59:	eb 0c                	jmp    f0103b67 <debuginfo_eip+0x2ba>
 
//	If *region_left > *region_right, then 'addr' is not contained in any
//	matching stab.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
                 if(lline > rline)
                 return -1;
f0103b5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b60:	eb 05                	jmp    f0103b67 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b62:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b67:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b6a:	5b                   	pop    %ebx
f0103b6b:	5e                   	pop    %esi
f0103b6c:	5f                   	pop    %edi
f0103b6d:	5d                   	pop    %ebp
f0103b6e:	c3                   	ret    

f0103b6f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b6f:	55                   	push   %ebp
f0103b70:	89 e5                	mov    %esp,%ebp
f0103b72:	57                   	push   %edi
f0103b73:	56                   	push   %esi
f0103b74:	53                   	push   %ebx
f0103b75:	83 ec 1c             	sub    $0x1c,%esp
f0103b78:	89 c7                	mov    %eax,%edi
f0103b7a:	89 d6                	mov    %edx,%esi
f0103b7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b7f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b82:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b85:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b88:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b8b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b90:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b93:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b96:	39 d3                	cmp    %edx,%ebx
f0103b98:	72 05                	jb     f0103b9f <printnum+0x30>
f0103b9a:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b9d:	77 45                	ja     f0103be4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b9f:	83 ec 0c             	sub    $0xc,%esp
f0103ba2:	ff 75 18             	pushl  0x18(%ebp)
f0103ba5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ba8:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103bab:	53                   	push   %ebx
f0103bac:	ff 75 10             	pushl  0x10(%ebp)
f0103baf:	83 ec 08             	sub    $0x8,%esp
f0103bb2:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bb5:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bb8:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bbb:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bbe:	e8 bd 09 00 00       	call   f0104580 <__udivdi3>
f0103bc3:	83 c4 18             	add    $0x18,%esp
f0103bc6:	52                   	push   %edx
f0103bc7:	50                   	push   %eax
f0103bc8:	89 f2                	mov    %esi,%edx
f0103bca:	89 f8                	mov    %edi,%eax
f0103bcc:	e8 9e ff ff ff       	call   f0103b6f <printnum>
f0103bd1:	83 c4 20             	add    $0x20,%esp
f0103bd4:	eb 18                	jmp    f0103bee <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103bd6:	83 ec 08             	sub    $0x8,%esp
f0103bd9:	56                   	push   %esi
f0103bda:	ff 75 18             	pushl  0x18(%ebp)
f0103bdd:	ff d7                	call   *%edi
f0103bdf:	83 c4 10             	add    $0x10,%esp
f0103be2:	eb 03                	jmp    f0103be7 <printnum+0x78>
f0103be4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103be7:	83 eb 01             	sub    $0x1,%ebx
f0103bea:	85 db                	test   %ebx,%ebx
f0103bec:	7f e8                	jg     f0103bd6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103bee:	83 ec 08             	sub    $0x8,%esp
f0103bf1:	56                   	push   %esi
f0103bf2:	83 ec 04             	sub    $0x4,%esp
f0103bf5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bf8:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bfb:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bfe:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c01:	e8 aa 0a 00 00       	call   f01046b0 <__umoddi3>
f0103c06:	83 c4 14             	add    $0x14,%esp
f0103c09:	0f be 80 12 5e 10 f0 	movsbl -0xfefa1ee(%eax),%eax
f0103c10:	50                   	push   %eax
f0103c11:	ff d7                	call   *%edi
}
f0103c13:	83 c4 10             	add    $0x10,%esp
f0103c16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c19:	5b                   	pop    %ebx
f0103c1a:	5e                   	pop    %esi
f0103c1b:	5f                   	pop    %edi
f0103c1c:	5d                   	pop    %ebp
f0103c1d:	c3                   	ret    

f0103c1e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c1e:	55                   	push   %ebp
f0103c1f:	89 e5                	mov    %esp,%ebp
f0103c21:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c24:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c28:	8b 10                	mov    (%eax),%edx
f0103c2a:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c2d:	73 0a                	jae    f0103c39 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c2f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c32:	89 08                	mov    %ecx,(%eax)
f0103c34:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c37:	88 02                	mov    %al,(%edx)
}
f0103c39:	5d                   	pop    %ebp
f0103c3a:	c3                   	ret    

f0103c3b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c3b:	55                   	push   %ebp
f0103c3c:	89 e5                	mov    %esp,%ebp
f0103c3e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c41:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c44:	50                   	push   %eax
f0103c45:	ff 75 10             	pushl  0x10(%ebp)
f0103c48:	ff 75 0c             	pushl  0xc(%ebp)
f0103c4b:	ff 75 08             	pushl  0x8(%ebp)
f0103c4e:	e8 05 00 00 00       	call   f0103c58 <vprintfmt>
	va_end(ap);
}
f0103c53:	83 c4 10             	add    $0x10,%esp
f0103c56:	c9                   	leave  
f0103c57:	c3                   	ret    

f0103c58 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c58:	55                   	push   %ebp
f0103c59:	89 e5                	mov    %esp,%ebp
f0103c5b:	57                   	push   %edi
f0103c5c:	56                   	push   %esi
f0103c5d:	53                   	push   %ebx
f0103c5e:	83 ec 2c             	sub    $0x2c,%esp
f0103c61:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c64:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c67:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c6a:	eb 12                	jmp    f0103c7e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c6c:	85 c0                	test   %eax,%eax
f0103c6e:	0f 84 42 04 00 00    	je     f01040b6 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103c74:	83 ec 08             	sub    $0x8,%esp
f0103c77:	53                   	push   %ebx
f0103c78:	50                   	push   %eax
f0103c79:	ff d6                	call   *%esi
f0103c7b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c7e:	83 c7 01             	add    $0x1,%edi
f0103c81:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c85:	83 f8 25             	cmp    $0x25,%eax
f0103c88:	75 e2                	jne    f0103c6c <vprintfmt+0x14>
f0103c8a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c8e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c95:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c9c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103ca3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ca8:	eb 07                	jmp    f0103cb1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103caa:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103cad:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cb1:	8d 47 01             	lea    0x1(%edi),%eax
f0103cb4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103cb7:	0f b6 07             	movzbl (%edi),%eax
f0103cba:	0f b6 d0             	movzbl %al,%edx
f0103cbd:	83 e8 23             	sub    $0x23,%eax
f0103cc0:	3c 55                	cmp    $0x55,%al
f0103cc2:	0f 87 d3 03 00 00    	ja     f010409b <vprintfmt+0x443>
f0103cc8:	0f b6 c0             	movzbl %al,%eax
f0103ccb:	ff 24 85 9c 5e 10 f0 	jmp    *-0xfefa164(,%eax,4)
f0103cd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103cd5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103cd9:	eb d6                	jmp    f0103cb1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cdb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cde:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ce3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ce6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ce9:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103ced:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103cf0:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103cf3:	83 f9 09             	cmp    $0x9,%ecx
f0103cf6:	77 3f                	ja     f0103d37 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103cf8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103cfb:	eb e9                	jmp    f0103ce6 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103cfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d00:	8b 00                	mov    (%eax),%eax
f0103d02:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103d05:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d08:	8d 40 04             	lea    0x4(%eax),%eax
f0103d0b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d11:	eb 2a                	jmp    f0103d3d <vprintfmt+0xe5>
f0103d13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d16:	85 c0                	test   %eax,%eax
f0103d18:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d1d:	0f 49 d0             	cmovns %eax,%edx
f0103d20:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d26:	eb 89                	jmp    f0103cb1 <vprintfmt+0x59>
f0103d28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d2b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d32:	e9 7a ff ff ff       	jmp    f0103cb1 <vprintfmt+0x59>
f0103d37:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103d3a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d41:	0f 89 6a ff ff ff    	jns    f0103cb1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d47:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d4a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d4d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d54:	e9 58 ff ff ff       	jmp    f0103cb1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d59:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d5f:	e9 4d ff ff ff       	jmp    f0103cb1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d64:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d67:	8d 78 04             	lea    0x4(%eax),%edi
f0103d6a:	83 ec 08             	sub    $0x8,%esp
f0103d6d:	53                   	push   %ebx
f0103d6e:	ff 30                	pushl  (%eax)
f0103d70:	ff d6                	call   *%esi
			break;
f0103d72:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d75:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d78:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d7b:	e9 fe fe ff ff       	jmp    f0103c7e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d80:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d83:	8d 78 04             	lea    0x4(%eax),%edi
f0103d86:	8b 00                	mov    (%eax),%eax
f0103d88:	99                   	cltd   
f0103d89:	31 d0                	xor    %edx,%eax
f0103d8b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d8d:	83 f8 06             	cmp    $0x6,%eax
f0103d90:	7f 0b                	jg     f0103d9d <vprintfmt+0x145>
f0103d92:	8b 14 85 f4 5f 10 f0 	mov    -0xfefa00c(,%eax,4),%edx
f0103d99:	85 d2                	test   %edx,%edx
f0103d9b:	75 1b                	jne    f0103db8 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103d9d:	50                   	push   %eax
f0103d9e:	68 2a 5e 10 f0       	push   $0xf0105e2a
f0103da3:	53                   	push   %ebx
f0103da4:	56                   	push   %esi
f0103da5:	e8 91 fe ff ff       	call   f0103c3b <printfmt>
f0103daa:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dad:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103db0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103db3:	e9 c6 fe ff ff       	jmp    f0103c7e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103db8:	52                   	push   %edx
f0103db9:	68 a8 4d 10 f0       	push   $0xf0104da8
f0103dbe:	53                   	push   %ebx
f0103dbf:	56                   	push   %esi
f0103dc0:	e8 76 fe ff ff       	call   f0103c3b <printfmt>
f0103dc5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dc8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dcb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103dce:	e9 ab fe ff ff       	jmp    f0103c7e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103dd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dd6:	83 c0 04             	add    $0x4,%eax
f0103dd9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103ddc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ddf:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103de1:	85 ff                	test   %edi,%edi
f0103de3:	b8 23 5e 10 f0       	mov    $0xf0105e23,%eax
f0103de8:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103deb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103def:	0f 8e 94 00 00 00    	jle    f0103e89 <vprintfmt+0x231>
f0103df5:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103df9:	0f 84 98 00 00 00    	je     f0103e97 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dff:	83 ec 08             	sub    $0x8,%esp
f0103e02:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e05:	57                   	push   %edi
f0103e06:	e8 0c 04 00 00       	call   f0104217 <strnlen>
f0103e0b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e0e:	29 c1                	sub    %eax,%ecx
f0103e10:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103e13:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e16:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e1a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e1d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e20:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e22:	eb 0f                	jmp    f0103e33 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103e24:	83 ec 08             	sub    $0x8,%esp
f0103e27:	53                   	push   %ebx
f0103e28:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e2b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e2d:	83 ef 01             	sub    $0x1,%edi
f0103e30:	83 c4 10             	add    $0x10,%esp
f0103e33:	85 ff                	test   %edi,%edi
f0103e35:	7f ed                	jg     f0103e24 <vprintfmt+0x1cc>
f0103e37:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e3a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103e3d:	85 c9                	test   %ecx,%ecx
f0103e3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e44:	0f 49 c1             	cmovns %ecx,%eax
f0103e47:	29 c1                	sub    %eax,%ecx
f0103e49:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e4c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e4f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e52:	89 cb                	mov    %ecx,%ebx
f0103e54:	eb 4d                	jmp    f0103ea3 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e56:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e5a:	74 1b                	je     f0103e77 <vprintfmt+0x21f>
f0103e5c:	0f be c0             	movsbl %al,%eax
f0103e5f:	83 e8 20             	sub    $0x20,%eax
f0103e62:	83 f8 5e             	cmp    $0x5e,%eax
f0103e65:	76 10                	jbe    f0103e77 <vprintfmt+0x21f>
					putch('?', putdat);
f0103e67:	83 ec 08             	sub    $0x8,%esp
f0103e6a:	ff 75 0c             	pushl  0xc(%ebp)
f0103e6d:	6a 3f                	push   $0x3f
f0103e6f:	ff 55 08             	call   *0x8(%ebp)
f0103e72:	83 c4 10             	add    $0x10,%esp
f0103e75:	eb 0d                	jmp    f0103e84 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103e77:	83 ec 08             	sub    $0x8,%esp
f0103e7a:	ff 75 0c             	pushl  0xc(%ebp)
f0103e7d:	52                   	push   %edx
f0103e7e:	ff 55 08             	call   *0x8(%ebp)
f0103e81:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e84:	83 eb 01             	sub    $0x1,%ebx
f0103e87:	eb 1a                	jmp    f0103ea3 <vprintfmt+0x24b>
f0103e89:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e8c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e8f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e92:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e95:	eb 0c                	jmp    f0103ea3 <vprintfmt+0x24b>
f0103e97:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e9a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e9d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ea0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ea3:	83 c7 01             	add    $0x1,%edi
f0103ea6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103eaa:	0f be d0             	movsbl %al,%edx
f0103ead:	85 d2                	test   %edx,%edx
f0103eaf:	74 23                	je     f0103ed4 <vprintfmt+0x27c>
f0103eb1:	85 f6                	test   %esi,%esi
f0103eb3:	78 a1                	js     f0103e56 <vprintfmt+0x1fe>
f0103eb5:	83 ee 01             	sub    $0x1,%esi
f0103eb8:	79 9c                	jns    f0103e56 <vprintfmt+0x1fe>
f0103eba:	89 df                	mov    %ebx,%edi
f0103ebc:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ebf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ec2:	eb 18                	jmp    f0103edc <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103ec4:	83 ec 08             	sub    $0x8,%esp
f0103ec7:	53                   	push   %ebx
f0103ec8:	6a 20                	push   $0x20
f0103eca:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ecc:	83 ef 01             	sub    $0x1,%edi
f0103ecf:	83 c4 10             	add    $0x10,%esp
f0103ed2:	eb 08                	jmp    f0103edc <vprintfmt+0x284>
f0103ed4:	89 df                	mov    %ebx,%edi
f0103ed6:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ed9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103edc:	85 ff                	test   %edi,%edi
f0103ede:	7f e4                	jg     f0103ec4 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103ee0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103ee3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ee6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ee9:	e9 90 fd ff ff       	jmp    f0103c7e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103eee:	83 f9 01             	cmp    $0x1,%ecx
f0103ef1:	7e 19                	jle    f0103f0c <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103ef3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ef6:	8b 50 04             	mov    0x4(%eax),%edx
f0103ef9:	8b 00                	mov    (%eax),%eax
f0103efb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103efe:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f01:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f04:	8d 40 08             	lea    0x8(%eax),%eax
f0103f07:	89 45 14             	mov    %eax,0x14(%ebp)
f0103f0a:	eb 38                	jmp    f0103f44 <vprintfmt+0x2ec>
	else if (lflag)
f0103f0c:	85 c9                	test   %ecx,%ecx
f0103f0e:	74 1b                	je     f0103f2b <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103f10:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f13:	8b 00                	mov    (%eax),%eax
f0103f15:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f18:	89 c1                	mov    %eax,%ecx
f0103f1a:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f1d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f20:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f23:	8d 40 04             	lea    0x4(%eax),%eax
f0103f26:	89 45 14             	mov    %eax,0x14(%ebp)
f0103f29:	eb 19                	jmp    f0103f44 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103f2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f2e:	8b 00                	mov    (%eax),%eax
f0103f30:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f33:	89 c1                	mov    %eax,%ecx
f0103f35:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f38:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f3e:	8d 40 04             	lea    0x4(%eax),%eax
f0103f41:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f44:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f47:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f4a:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f4f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f53:	0f 89 0e 01 00 00    	jns    f0104067 <vprintfmt+0x40f>
				putch('-', putdat);
f0103f59:	83 ec 08             	sub    $0x8,%esp
f0103f5c:	53                   	push   %ebx
f0103f5d:	6a 2d                	push   $0x2d
f0103f5f:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f61:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f64:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103f67:	f7 da                	neg    %edx
f0103f69:	83 d1 00             	adc    $0x0,%ecx
f0103f6c:	f7 d9                	neg    %ecx
f0103f6e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f71:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f76:	e9 ec 00 00 00       	jmp    f0104067 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f7b:	83 f9 01             	cmp    $0x1,%ecx
f0103f7e:	7e 18                	jle    f0103f98 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103f80:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f83:	8b 10                	mov    (%eax),%edx
f0103f85:	8b 48 04             	mov    0x4(%eax),%ecx
f0103f88:	8d 40 08             	lea    0x8(%eax),%eax
f0103f8b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103f8e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f93:	e9 cf 00 00 00       	jmp    f0104067 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103f98:	85 c9                	test   %ecx,%ecx
f0103f9a:	74 1a                	je     f0103fb6 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103f9c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f9f:	8b 10                	mov    (%eax),%edx
f0103fa1:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103fa6:	8d 40 04             	lea    0x4(%eax),%eax
f0103fa9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103fac:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103fb1:	e9 b1 00 00 00       	jmp    f0104067 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103fb6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fb9:	8b 10                	mov    (%eax),%edx
f0103fbb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103fc0:	8d 40 04             	lea    0x4(%eax),%eax
f0103fc3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103fc6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103fcb:	e9 97 00 00 00       	jmp    f0104067 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103fd0:	83 ec 08             	sub    $0x8,%esp
f0103fd3:	53                   	push   %ebx
f0103fd4:	6a 58                	push   $0x58
f0103fd6:	ff d6                	call   *%esi
			putch('X', putdat);
f0103fd8:	83 c4 08             	add    $0x8,%esp
f0103fdb:	53                   	push   %ebx
f0103fdc:	6a 58                	push   $0x58
f0103fde:	ff d6                	call   *%esi
			putch('X', putdat);
f0103fe0:	83 c4 08             	add    $0x8,%esp
f0103fe3:	53                   	push   %ebx
f0103fe4:	6a 58                	push   $0x58
f0103fe6:	ff d6                	call   *%esi
			break;
f0103fe8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103feb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103fee:	e9 8b fc ff ff       	jmp    f0103c7e <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103ff3:	83 ec 08             	sub    $0x8,%esp
f0103ff6:	53                   	push   %ebx
f0103ff7:	6a 30                	push   $0x30
f0103ff9:	ff d6                	call   *%esi
			putch('x', putdat);
f0103ffb:	83 c4 08             	add    $0x8,%esp
f0103ffe:	53                   	push   %ebx
f0103fff:	6a 78                	push   $0x78
f0104001:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104003:	8b 45 14             	mov    0x14(%ebp),%eax
f0104006:	8b 10                	mov    (%eax),%edx
f0104008:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010400d:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104010:	8d 40 04             	lea    0x4(%eax),%eax
f0104013:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104016:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010401b:	eb 4a                	jmp    f0104067 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010401d:	83 f9 01             	cmp    $0x1,%ecx
f0104020:	7e 15                	jle    f0104037 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0104022:	8b 45 14             	mov    0x14(%ebp),%eax
f0104025:	8b 10                	mov    (%eax),%edx
f0104027:	8b 48 04             	mov    0x4(%eax),%ecx
f010402a:	8d 40 08             	lea    0x8(%eax),%eax
f010402d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104030:	b8 10 00 00 00       	mov    $0x10,%eax
f0104035:	eb 30                	jmp    f0104067 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104037:	85 c9                	test   %ecx,%ecx
f0104039:	74 17                	je     f0104052 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f010403b:	8b 45 14             	mov    0x14(%ebp),%eax
f010403e:	8b 10                	mov    (%eax),%edx
f0104040:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104045:	8d 40 04             	lea    0x4(%eax),%eax
f0104048:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010404b:	b8 10 00 00 00       	mov    $0x10,%eax
f0104050:	eb 15                	jmp    f0104067 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104052:	8b 45 14             	mov    0x14(%ebp),%eax
f0104055:	8b 10                	mov    (%eax),%edx
f0104057:	b9 00 00 00 00       	mov    $0x0,%ecx
f010405c:	8d 40 04             	lea    0x4(%eax),%eax
f010405f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104062:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104067:	83 ec 0c             	sub    $0xc,%esp
f010406a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010406e:	57                   	push   %edi
f010406f:	ff 75 e0             	pushl  -0x20(%ebp)
f0104072:	50                   	push   %eax
f0104073:	51                   	push   %ecx
f0104074:	52                   	push   %edx
f0104075:	89 da                	mov    %ebx,%edx
f0104077:	89 f0                	mov    %esi,%eax
f0104079:	e8 f1 fa ff ff       	call   f0103b6f <printnum>
			break;
f010407e:	83 c4 20             	add    $0x20,%esp
f0104081:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104084:	e9 f5 fb ff ff       	jmp    f0103c7e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104089:	83 ec 08             	sub    $0x8,%esp
f010408c:	53                   	push   %ebx
f010408d:	52                   	push   %edx
f010408e:	ff d6                	call   *%esi
			break;
f0104090:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104093:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104096:	e9 e3 fb ff ff       	jmp    f0103c7e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010409b:	83 ec 08             	sub    $0x8,%esp
f010409e:	53                   	push   %ebx
f010409f:	6a 25                	push   $0x25
f01040a1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01040a3:	83 c4 10             	add    $0x10,%esp
f01040a6:	eb 03                	jmp    f01040ab <vprintfmt+0x453>
f01040a8:	83 ef 01             	sub    $0x1,%edi
f01040ab:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01040af:	75 f7                	jne    f01040a8 <vprintfmt+0x450>
f01040b1:	e9 c8 fb ff ff       	jmp    f0103c7e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01040b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040b9:	5b                   	pop    %ebx
f01040ba:	5e                   	pop    %esi
f01040bb:	5f                   	pop    %edi
f01040bc:	5d                   	pop    %ebp
f01040bd:	c3                   	ret    

f01040be <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01040be:	55                   	push   %ebp
f01040bf:	89 e5                	mov    %esp,%ebp
f01040c1:	83 ec 18             	sub    $0x18,%esp
f01040c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01040ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040cd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01040d1:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01040d4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01040db:	85 c0                	test   %eax,%eax
f01040dd:	74 26                	je     f0104105 <vsnprintf+0x47>
f01040df:	85 d2                	test   %edx,%edx
f01040e1:	7e 22                	jle    f0104105 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01040e3:	ff 75 14             	pushl  0x14(%ebp)
f01040e6:	ff 75 10             	pushl  0x10(%ebp)
f01040e9:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01040ec:	50                   	push   %eax
f01040ed:	68 1e 3c 10 f0       	push   $0xf0103c1e
f01040f2:	e8 61 fb ff ff       	call   f0103c58 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01040f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040fa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01040fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104100:	83 c4 10             	add    $0x10,%esp
f0104103:	eb 05                	jmp    f010410a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104105:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010410a:	c9                   	leave  
f010410b:	c3                   	ret    

f010410c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010410c:	55                   	push   %ebp
f010410d:	89 e5                	mov    %esp,%ebp
f010410f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104112:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104115:	50                   	push   %eax
f0104116:	ff 75 10             	pushl  0x10(%ebp)
f0104119:	ff 75 0c             	pushl  0xc(%ebp)
f010411c:	ff 75 08             	pushl  0x8(%ebp)
f010411f:	e8 9a ff ff ff       	call   f01040be <vsnprintf>
	va_end(ap);

	return rc;
}
f0104124:	c9                   	leave  
f0104125:	c3                   	ret    

f0104126 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104126:	55                   	push   %ebp
f0104127:	89 e5                	mov    %esp,%ebp
f0104129:	57                   	push   %edi
f010412a:	56                   	push   %esi
f010412b:	53                   	push   %ebx
f010412c:	83 ec 0c             	sub    $0xc,%esp
f010412f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104132:	85 c0                	test   %eax,%eax
f0104134:	74 11                	je     f0104147 <readline+0x21>
		cprintf("%s", prompt);
f0104136:	83 ec 08             	sub    $0x8,%esp
f0104139:	50                   	push   %eax
f010413a:	68 a8 4d 10 f0       	push   $0xf0104da8
f010413f:	e8 5a ee ff ff       	call   f0102f9e <cprintf>
f0104144:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104147:	83 ec 0c             	sub    $0xc,%esp
f010414a:	6a 00                	push   $0x0
f010414c:	e8 e5 c4 ff ff       	call   f0100636 <iscons>
f0104151:	89 c7                	mov    %eax,%edi
f0104153:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104156:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010415b:	e8 c5 c4 ff ff       	call   f0100625 <getchar>
f0104160:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104162:	85 c0                	test   %eax,%eax
f0104164:	79 18                	jns    f010417e <readline+0x58>
			cprintf("read error: %e\n", c);
f0104166:	83 ec 08             	sub    $0x8,%esp
f0104169:	50                   	push   %eax
f010416a:	68 10 60 10 f0       	push   $0xf0106010
f010416f:	e8 2a ee ff ff       	call   f0102f9e <cprintf>
			return NULL;
f0104174:	83 c4 10             	add    $0x10,%esp
f0104177:	b8 00 00 00 00       	mov    $0x0,%eax
f010417c:	eb 79                	jmp    f01041f7 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010417e:	83 f8 08             	cmp    $0x8,%eax
f0104181:	0f 94 c2             	sete   %dl
f0104184:	83 f8 7f             	cmp    $0x7f,%eax
f0104187:	0f 94 c0             	sete   %al
f010418a:	08 c2                	or     %al,%dl
f010418c:	74 1a                	je     f01041a8 <readline+0x82>
f010418e:	85 f6                	test   %esi,%esi
f0104190:	7e 16                	jle    f01041a8 <readline+0x82>
			if (echoing)
f0104192:	85 ff                	test   %edi,%edi
f0104194:	74 0d                	je     f01041a3 <readline+0x7d>
				cputchar('\b');
f0104196:	83 ec 0c             	sub    $0xc,%esp
f0104199:	6a 08                	push   $0x8
f010419b:	e8 75 c4 ff ff       	call   f0100615 <cputchar>
f01041a0:	83 c4 10             	add    $0x10,%esp
			i--;
f01041a3:	83 ee 01             	sub    $0x1,%esi
f01041a6:	eb b3                	jmp    f010415b <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01041a8:	83 fb 1f             	cmp    $0x1f,%ebx
f01041ab:	7e 23                	jle    f01041d0 <readline+0xaa>
f01041ad:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01041b3:	7f 1b                	jg     f01041d0 <readline+0xaa>
			if (echoing)
f01041b5:	85 ff                	test   %edi,%edi
f01041b7:	74 0c                	je     f01041c5 <readline+0x9f>
				cputchar(c);
f01041b9:	83 ec 0c             	sub    $0xc,%esp
f01041bc:	53                   	push   %ebx
f01041bd:	e8 53 c4 ff ff       	call   f0100615 <cputchar>
f01041c2:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01041c5:	88 9e 00 d7 17 f0    	mov    %bl,-0xfe82900(%esi)
f01041cb:	8d 76 01             	lea    0x1(%esi),%esi
f01041ce:	eb 8b                	jmp    f010415b <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01041d0:	83 fb 0a             	cmp    $0xa,%ebx
f01041d3:	74 05                	je     f01041da <readline+0xb4>
f01041d5:	83 fb 0d             	cmp    $0xd,%ebx
f01041d8:	75 81                	jne    f010415b <readline+0x35>
			if (echoing)
f01041da:	85 ff                	test   %edi,%edi
f01041dc:	74 0d                	je     f01041eb <readline+0xc5>
				cputchar('\n');
f01041de:	83 ec 0c             	sub    $0xc,%esp
f01041e1:	6a 0a                	push   $0xa
f01041e3:	e8 2d c4 ff ff       	call   f0100615 <cputchar>
f01041e8:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01041eb:	c6 86 00 d7 17 f0 00 	movb   $0x0,-0xfe82900(%esi)
			return buf;
f01041f2:	b8 00 d7 17 f0       	mov    $0xf017d700,%eax
		}
	}
}
f01041f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041fa:	5b                   	pop    %ebx
f01041fb:	5e                   	pop    %esi
f01041fc:	5f                   	pop    %edi
f01041fd:	5d                   	pop    %ebp
f01041fe:	c3                   	ret    

f01041ff <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01041ff:	55                   	push   %ebp
f0104200:	89 e5                	mov    %esp,%ebp
f0104202:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104205:	b8 00 00 00 00       	mov    $0x0,%eax
f010420a:	eb 03                	jmp    f010420f <strlen+0x10>
		n++;
f010420c:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010420f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104213:	75 f7                	jne    f010420c <strlen+0xd>
		n++;
	return n;
}
f0104215:	5d                   	pop    %ebp
f0104216:	c3                   	ret    

f0104217 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104217:	55                   	push   %ebp
f0104218:	89 e5                	mov    %esp,%ebp
f010421a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010421d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104220:	ba 00 00 00 00       	mov    $0x0,%edx
f0104225:	eb 03                	jmp    f010422a <strnlen+0x13>
		n++;
f0104227:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010422a:	39 c2                	cmp    %eax,%edx
f010422c:	74 08                	je     f0104236 <strnlen+0x1f>
f010422e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104232:	75 f3                	jne    f0104227 <strnlen+0x10>
f0104234:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104236:	5d                   	pop    %ebp
f0104237:	c3                   	ret    

f0104238 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104238:	55                   	push   %ebp
f0104239:	89 e5                	mov    %esp,%ebp
f010423b:	53                   	push   %ebx
f010423c:	8b 45 08             	mov    0x8(%ebp),%eax
f010423f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104242:	89 c2                	mov    %eax,%edx
f0104244:	83 c2 01             	add    $0x1,%edx
f0104247:	83 c1 01             	add    $0x1,%ecx
f010424a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010424e:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104251:	84 db                	test   %bl,%bl
f0104253:	75 ef                	jne    f0104244 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104255:	5b                   	pop    %ebx
f0104256:	5d                   	pop    %ebp
f0104257:	c3                   	ret    

f0104258 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104258:	55                   	push   %ebp
f0104259:	89 e5                	mov    %esp,%ebp
f010425b:	53                   	push   %ebx
f010425c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010425f:	53                   	push   %ebx
f0104260:	e8 9a ff ff ff       	call   f01041ff <strlen>
f0104265:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104268:	ff 75 0c             	pushl  0xc(%ebp)
f010426b:	01 d8                	add    %ebx,%eax
f010426d:	50                   	push   %eax
f010426e:	e8 c5 ff ff ff       	call   f0104238 <strcpy>
	return dst;
}
f0104273:	89 d8                	mov    %ebx,%eax
f0104275:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104278:	c9                   	leave  
f0104279:	c3                   	ret    

f010427a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010427a:	55                   	push   %ebp
f010427b:	89 e5                	mov    %esp,%ebp
f010427d:	56                   	push   %esi
f010427e:	53                   	push   %ebx
f010427f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104282:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104285:	89 f3                	mov    %esi,%ebx
f0104287:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010428a:	89 f2                	mov    %esi,%edx
f010428c:	eb 0f                	jmp    f010429d <strncpy+0x23>
		*dst++ = *src;
f010428e:	83 c2 01             	add    $0x1,%edx
f0104291:	0f b6 01             	movzbl (%ecx),%eax
f0104294:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104297:	80 39 01             	cmpb   $0x1,(%ecx)
f010429a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010429d:	39 da                	cmp    %ebx,%edx
f010429f:	75 ed                	jne    f010428e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01042a1:	89 f0                	mov    %esi,%eax
f01042a3:	5b                   	pop    %ebx
f01042a4:	5e                   	pop    %esi
f01042a5:	5d                   	pop    %ebp
f01042a6:	c3                   	ret    

f01042a7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01042a7:	55                   	push   %ebp
f01042a8:	89 e5                	mov    %esp,%ebp
f01042aa:	56                   	push   %esi
f01042ab:	53                   	push   %ebx
f01042ac:	8b 75 08             	mov    0x8(%ebp),%esi
f01042af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042b2:	8b 55 10             	mov    0x10(%ebp),%edx
f01042b5:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01042b7:	85 d2                	test   %edx,%edx
f01042b9:	74 21                	je     f01042dc <strlcpy+0x35>
f01042bb:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01042bf:	89 f2                	mov    %esi,%edx
f01042c1:	eb 09                	jmp    f01042cc <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01042c3:	83 c2 01             	add    $0x1,%edx
f01042c6:	83 c1 01             	add    $0x1,%ecx
f01042c9:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01042cc:	39 c2                	cmp    %eax,%edx
f01042ce:	74 09                	je     f01042d9 <strlcpy+0x32>
f01042d0:	0f b6 19             	movzbl (%ecx),%ebx
f01042d3:	84 db                	test   %bl,%bl
f01042d5:	75 ec                	jne    f01042c3 <strlcpy+0x1c>
f01042d7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01042d9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01042dc:	29 f0                	sub    %esi,%eax
}
f01042de:	5b                   	pop    %ebx
f01042df:	5e                   	pop    %esi
f01042e0:	5d                   	pop    %ebp
f01042e1:	c3                   	ret    

f01042e2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01042e2:	55                   	push   %ebp
f01042e3:	89 e5                	mov    %esp,%ebp
f01042e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042e8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01042eb:	eb 06                	jmp    f01042f3 <strcmp+0x11>
		p++, q++;
f01042ed:	83 c1 01             	add    $0x1,%ecx
f01042f0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042f3:	0f b6 01             	movzbl (%ecx),%eax
f01042f6:	84 c0                	test   %al,%al
f01042f8:	74 04                	je     f01042fe <strcmp+0x1c>
f01042fa:	3a 02                	cmp    (%edx),%al
f01042fc:	74 ef                	je     f01042ed <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01042fe:	0f b6 c0             	movzbl %al,%eax
f0104301:	0f b6 12             	movzbl (%edx),%edx
f0104304:	29 d0                	sub    %edx,%eax
}
f0104306:	5d                   	pop    %ebp
f0104307:	c3                   	ret    

f0104308 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104308:	55                   	push   %ebp
f0104309:	89 e5                	mov    %esp,%ebp
f010430b:	53                   	push   %ebx
f010430c:	8b 45 08             	mov    0x8(%ebp),%eax
f010430f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104312:	89 c3                	mov    %eax,%ebx
f0104314:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104317:	eb 06                	jmp    f010431f <strncmp+0x17>
		n--, p++, q++;
f0104319:	83 c0 01             	add    $0x1,%eax
f010431c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010431f:	39 d8                	cmp    %ebx,%eax
f0104321:	74 15                	je     f0104338 <strncmp+0x30>
f0104323:	0f b6 08             	movzbl (%eax),%ecx
f0104326:	84 c9                	test   %cl,%cl
f0104328:	74 04                	je     f010432e <strncmp+0x26>
f010432a:	3a 0a                	cmp    (%edx),%cl
f010432c:	74 eb                	je     f0104319 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010432e:	0f b6 00             	movzbl (%eax),%eax
f0104331:	0f b6 12             	movzbl (%edx),%edx
f0104334:	29 d0                	sub    %edx,%eax
f0104336:	eb 05                	jmp    f010433d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104338:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010433d:	5b                   	pop    %ebx
f010433e:	5d                   	pop    %ebp
f010433f:	c3                   	ret    

f0104340 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104340:	55                   	push   %ebp
f0104341:	89 e5                	mov    %esp,%ebp
f0104343:	8b 45 08             	mov    0x8(%ebp),%eax
f0104346:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010434a:	eb 07                	jmp    f0104353 <strchr+0x13>
		if (*s == c)
f010434c:	38 ca                	cmp    %cl,%dl
f010434e:	74 0f                	je     f010435f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104350:	83 c0 01             	add    $0x1,%eax
f0104353:	0f b6 10             	movzbl (%eax),%edx
f0104356:	84 d2                	test   %dl,%dl
f0104358:	75 f2                	jne    f010434c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010435a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010435f:	5d                   	pop    %ebp
f0104360:	c3                   	ret    

f0104361 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104361:	55                   	push   %ebp
f0104362:	89 e5                	mov    %esp,%ebp
f0104364:	8b 45 08             	mov    0x8(%ebp),%eax
f0104367:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010436b:	eb 03                	jmp    f0104370 <strfind+0xf>
f010436d:	83 c0 01             	add    $0x1,%eax
f0104370:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104373:	38 ca                	cmp    %cl,%dl
f0104375:	74 04                	je     f010437b <strfind+0x1a>
f0104377:	84 d2                	test   %dl,%dl
f0104379:	75 f2                	jne    f010436d <strfind+0xc>
			break;
	return (char *) s;
}
f010437b:	5d                   	pop    %ebp
f010437c:	c3                   	ret    

f010437d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010437d:	55                   	push   %ebp
f010437e:	89 e5                	mov    %esp,%ebp
f0104380:	57                   	push   %edi
f0104381:	56                   	push   %esi
f0104382:	53                   	push   %ebx
f0104383:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104386:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104389:	85 c9                	test   %ecx,%ecx
f010438b:	74 36                	je     f01043c3 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010438d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104393:	75 28                	jne    f01043bd <memset+0x40>
f0104395:	f6 c1 03             	test   $0x3,%cl
f0104398:	75 23                	jne    f01043bd <memset+0x40>
		c &= 0xFF;
f010439a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010439e:	89 d3                	mov    %edx,%ebx
f01043a0:	c1 e3 08             	shl    $0x8,%ebx
f01043a3:	89 d6                	mov    %edx,%esi
f01043a5:	c1 e6 18             	shl    $0x18,%esi
f01043a8:	89 d0                	mov    %edx,%eax
f01043aa:	c1 e0 10             	shl    $0x10,%eax
f01043ad:	09 f0                	or     %esi,%eax
f01043af:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01043b1:	89 d8                	mov    %ebx,%eax
f01043b3:	09 d0                	or     %edx,%eax
f01043b5:	c1 e9 02             	shr    $0x2,%ecx
f01043b8:	fc                   	cld    
f01043b9:	f3 ab                	rep stos %eax,%es:(%edi)
f01043bb:	eb 06                	jmp    f01043c3 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01043bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043c0:	fc                   	cld    
f01043c1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01043c3:	89 f8                	mov    %edi,%eax
f01043c5:	5b                   	pop    %ebx
f01043c6:	5e                   	pop    %esi
f01043c7:	5f                   	pop    %edi
f01043c8:	5d                   	pop    %ebp
f01043c9:	c3                   	ret    

f01043ca <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01043ca:	55                   	push   %ebp
f01043cb:	89 e5                	mov    %esp,%ebp
f01043cd:	57                   	push   %edi
f01043ce:	56                   	push   %esi
f01043cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01043d2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01043d8:	39 c6                	cmp    %eax,%esi
f01043da:	73 35                	jae    f0104411 <memmove+0x47>
f01043dc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01043df:	39 d0                	cmp    %edx,%eax
f01043e1:	73 2e                	jae    f0104411 <memmove+0x47>
		s += n;
		d += n;
f01043e3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043e6:	89 d6                	mov    %edx,%esi
f01043e8:	09 fe                	or     %edi,%esi
f01043ea:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01043f0:	75 13                	jne    f0104405 <memmove+0x3b>
f01043f2:	f6 c1 03             	test   $0x3,%cl
f01043f5:	75 0e                	jne    f0104405 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01043f7:	83 ef 04             	sub    $0x4,%edi
f01043fa:	8d 72 fc             	lea    -0x4(%edx),%esi
f01043fd:	c1 e9 02             	shr    $0x2,%ecx
f0104400:	fd                   	std    
f0104401:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104403:	eb 09                	jmp    f010440e <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104405:	83 ef 01             	sub    $0x1,%edi
f0104408:	8d 72 ff             	lea    -0x1(%edx),%esi
f010440b:	fd                   	std    
f010440c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010440e:	fc                   	cld    
f010440f:	eb 1d                	jmp    f010442e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104411:	89 f2                	mov    %esi,%edx
f0104413:	09 c2                	or     %eax,%edx
f0104415:	f6 c2 03             	test   $0x3,%dl
f0104418:	75 0f                	jne    f0104429 <memmove+0x5f>
f010441a:	f6 c1 03             	test   $0x3,%cl
f010441d:	75 0a                	jne    f0104429 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010441f:	c1 e9 02             	shr    $0x2,%ecx
f0104422:	89 c7                	mov    %eax,%edi
f0104424:	fc                   	cld    
f0104425:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104427:	eb 05                	jmp    f010442e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104429:	89 c7                	mov    %eax,%edi
f010442b:	fc                   	cld    
f010442c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010442e:	5e                   	pop    %esi
f010442f:	5f                   	pop    %edi
f0104430:	5d                   	pop    %ebp
f0104431:	c3                   	ret    

f0104432 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104432:	55                   	push   %ebp
f0104433:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104435:	ff 75 10             	pushl  0x10(%ebp)
f0104438:	ff 75 0c             	pushl  0xc(%ebp)
f010443b:	ff 75 08             	pushl  0x8(%ebp)
f010443e:	e8 87 ff ff ff       	call   f01043ca <memmove>
}
f0104443:	c9                   	leave  
f0104444:	c3                   	ret    

f0104445 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104445:	55                   	push   %ebp
f0104446:	89 e5                	mov    %esp,%ebp
f0104448:	56                   	push   %esi
f0104449:	53                   	push   %ebx
f010444a:	8b 45 08             	mov    0x8(%ebp),%eax
f010444d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104450:	89 c6                	mov    %eax,%esi
f0104452:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104455:	eb 1a                	jmp    f0104471 <memcmp+0x2c>
		if (*s1 != *s2)
f0104457:	0f b6 08             	movzbl (%eax),%ecx
f010445a:	0f b6 1a             	movzbl (%edx),%ebx
f010445d:	38 d9                	cmp    %bl,%cl
f010445f:	74 0a                	je     f010446b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104461:	0f b6 c1             	movzbl %cl,%eax
f0104464:	0f b6 db             	movzbl %bl,%ebx
f0104467:	29 d8                	sub    %ebx,%eax
f0104469:	eb 0f                	jmp    f010447a <memcmp+0x35>
		s1++, s2++;
f010446b:	83 c0 01             	add    $0x1,%eax
f010446e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104471:	39 f0                	cmp    %esi,%eax
f0104473:	75 e2                	jne    f0104457 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104475:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010447a:	5b                   	pop    %ebx
f010447b:	5e                   	pop    %esi
f010447c:	5d                   	pop    %ebp
f010447d:	c3                   	ret    

f010447e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010447e:	55                   	push   %ebp
f010447f:	89 e5                	mov    %esp,%ebp
f0104481:	53                   	push   %ebx
f0104482:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104485:	89 c1                	mov    %eax,%ecx
f0104487:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010448a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010448e:	eb 0a                	jmp    f010449a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104490:	0f b6 10             	movzbl (%eax),%edx
f0104493:	39 da                	cmp    %ebx,%edx
f0104495:	74 07                	je     f010449e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104497:	83 c0 01             	add    $0x1,%eax
f010449a:	39 c8                	cmp    %ecx,%eax
f010449c:	72 f2                	jb     f0104490 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010449e:	5b                   	pop    %ebx
f010449f:	5d                   	pop    %ebp
f01044a0:	c3                   	ret    

f01044a1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01044a1:	55                   	push   %ebp
f01044a2:	89 e5                	mov    %esp,%ebp
f01044a4:	57                   	push   %edi
f01044a5:	56                   	push   %esi
f01044a6:	53                   	push   %ebx
f01044a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01044aa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044ad:	eb 03                	jmp    f01044b2 <strtol+0x11>
		s++;
f01044af:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044b2:	0f b6 01             	movzbl (%ecx),%eax
f01044b5:	3c 20                	cmp    $0x20,%al
f01044b7:	74 f6                	je     f01044af <strtol+0xe>
f01044b9:	3c 09                	cmp    $0x9,%al
f01044bb:	74 f2                	je     f01044af <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01044bd:	3c 2b                	cmp    $0x2b,%al
f01044bf:	75 0a                	jne    f01044cb <strtol+0x2a>
		s++;
f01044c1:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01044c4:	bf 00 00 00 00       	mov    $0x0,%edi
f01044c9:	eb 11                	jmp    f01044dc <strtol+0x3b>
f01044cb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01044d0:	3c 2d                	cmp    $0x2d,%al
f01044d2:	75 08                	jne    f01044dc <strtol+0x3b>
		s++, neg = 1;
f01044d4:	83 c1 01             	add    $0x1,%ecx
f01044d7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01044dc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01044e2:	75 15                	jne    f01044f9 <strtol+0x58>
f01044e4:	80 39 30             	cmpb   $0x30,(%ecx)
f01044e7:	75 10                	jne    f01044f9 <strtol+0x58>
f01044e9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01044ed:	75 7c                	jne    f010456b <strtol+0xca>
		s += 2, base = 16;
f01044ef:	83 c1 02             	add    $0x2,%ecx
f01044f2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01044f7:	eb 16                	jmp    f010450f <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01044f9:	85 db                	test   %ebx,%ebx
f01044fb:	75 12                	jne    f010450f <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01044fd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104502:	80 39 30             	cmpb   $0x30,(%ecx)
f0104505:	75 08                	jne    f010450f <strtol+0x6e>
		s++, base = 8;
f0104507:	83 c1 01             	add    $0x1,%ecx
f010450a:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010450f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104514:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104517:	0f b6 11             	movzbl (%ecx),%edx
f010451a:	8d 72 d0             	lea    -0x30(%edx),%esi
f010451d:	89 f3                	mov    %esi,%ebx
f010451f:	80 fb 09             	cmp    $0x9,%bl
f0104522:	77 08                	ja     f010452c <strtol+0x8b>
			dig = *s - '0';
f0104524:	0f be d2             	movsbl %dl,%edx
f0104527:	83 ea 30             	sub    $0x30,%edx
f010452a:	eb 22                	jmp    f010454e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010452c:	8d 72 9f             	lea    -0x61(%edx),%esi
f010452f:	89 f3                	mov    %esi,%ebx
f0104531:	80 fb 19             	cmp    $0x19,%bl
f0104534:	77 08                	ja     f010453e <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104536:	0f be d2             	movsbl %dl,%edx
f0104539:	83 ea 57             	sub    $0x57,%edx
f010453c:	eb 10                	jmp    f010454e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010453e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104541:	89 f3                	mov    %esi,%ebx
f0104543:	80 fb 19             	cmp    $0x19,%bl
f0104546:	77 16                	ja     f010455e <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104548:	0f be d2             	movsbl %dl,%edx
f010454b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010454e:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104551:	7d 0b                	jge    f010455e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104553:	83 c1 01             	add    $0x1,%ecx
f0104556:	0f af 45 10          	imul   0x10(%ebp),%eax
f010455a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010455c:	eb b9                	jmp    f0104517 <strtol+0x76>

	if (endptr)
f010455e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104562:	74 0d                	je     f0104571 <strtol+0xd0>
		*endptr = (char *) s;
f0104564:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104567:	89 0e                	mov    %ecx,(%esi)
f0104569:	eb 06                	jmp    f0104571 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010456b:	85 db                	test   %ebx,%ebx
f010456d:	74 98                	je     f0104507 <strtol+0x66>
f010456f:	eb 9e                	jmp    f010450f <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104571:	89 c2                	mov    %eax,%edx
f0104573:	f7 da                	neg    %edx
f0104575:	85 ff                	test   %edi,%edi
f0104577:	0f 45 c2             	cmovne %edx,%eax
}
f010457a:	5b                   	pop    %ebx
f010457b:	5e                   	pop    %esi
f010457c:	5f                   	pop    %edi
f010457d:	5d                   	pop    %ebp
f010457e:	c3                   	ret    
f010457f:	90                   	nop

f0104580 <__udivdi3>:
f0104580:	55                   	push   %ebp
f0104581:	57                   	push   %edi
f0104582:	56                   	push   %esi
f0104583:	53                   	push   %ebx
f0104584:	83 ec 1c             	sub    $0x1c,%esp
f0104587:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010458b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010458f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104593:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104597:	85 f6                	test   %esi,%esi
f0104599:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010459d:	89 ca                	mov    %ecx,%edx
f010459f:	89 f8                	mov    %edi,%eax
f01045a1:	75 3d                	jne    f01045e0 <__udivdi3+0x60>
f01045a3:	39 cf                	cmp    %ecx,%edi
f01045a5:	0f 87 c5 00 00 00    	ja     f0104670 <__udivdi3+0xf0>
f01045ab:	85 ff                	test   %edi,%edi
f01045ad:	89 fd                	mov    %edi,%ebp
f01045af:	75 0b                	jne    f01045bc <__udivdi3+0x3c>
f01045b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01045b6:	31 d2                	xor    %edx,%edx
f01045b8:	f7 f7                	div    %edi
f01045ba:	89 c5                	mov    %eax,%ebp
f01045bc:	89 c8                	mov    %ecx,%eax
f01045be:	31 d2                	xor    %edx,%edx
f01045c0:	f7 f5                	div    %ebp
f01045c2:	89 c1                	mov    %eax,%ecx
f01045c4:	89 d8                	mov    %ebx,%eax
f01045c6:	89 cf                	mov    %ecx,%edi
f01045c8:	f7 f5                	div    %ebp
f01045ca:	89 c3                	mov    %eax,%ebx
f01045cc:	89 d8                	mov    %ebx,%eax
f01045ce:	89 fa                	mov    %edi,%edx
f01045d0:	83 c4 1c             	add    $0x1c,%esp
f01045d3:	5b                   	pop    %ebx
f01045d4:	5e                   	pop    %esi
f01045d5:	5f                   	pop    %edi
f01045d6:	5d                   	pop    %ebp
f01045d7:	c3                   	ret    
f01045d8:	90                   	nop
f01045d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045e0:	39 ce                	cmp    %ecx,%esi
f01045e2:	77 74                	ja     f0104658 <__udivdi3+0xd8>
f01045e4:	0f bd fe             	bsr    %esi,%edi
f01045e7:	83 f7 1f             	xor    $0x1f,%edi
f01045ea:	0f 84 98 00 00 00    	je     f0104688 <__udivdi3+0x108>
f01045f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01045f5:	89 f9                	mov    %edi,%ecx
f01045f7:	89 c5                	mov    %eax,%ebp
f01045f9:	29 fb                	sub    %edi,%ebx
f01045fb:	d3 e6                	shl    %cl,%esi
f01045fd:	89 d9                	mov    %ebx,%ecx
f01045ff:	d3 ed                	shr    %cl,%ebp
f0104601:	89 f9                	mov    %edi,%ecx
f0104603:	d3 e0                	shl    %cl,%eax
f0104605:	09 ee                	or     %ebp,%esi
f0104607:	89 d9                	mov    %ebx,%ecx
f0104609:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010460d:	89 d5                	mov    %edx,%ebp
f010460f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104613:	d3 ed                	shr    %cl,%ebp
f0104615:	89 f9                	mov    %edi,%ecx
f0104617:	d3 e2                	shl    %cl,%edx
f0104619:	89 d9                	mov    %ebx,%ecx
f010461b:	d3 e8                	shr    %cl,%eax
f010461d:	09 c2                	or     %eax,%edx
f010461f:	89 d0                	mov    %edx,%eax
f0104621:	89 ea                	mov    %ebp,%edx
f0104623:	f7 f6                	div    %esi
f0104625:	89 d5                	mov    %edx,%ebp
f0104627:	89 c3                	mov    %eax,%ebx
f0104629:	f7 64 24 0c          	mull   0xc(%esp)
f010462d:	39 d5                	cmp    %edx,%ebp
f010462f:	72 10                	jb     f0104641 <__udivdi3+0xc1>
f0104631:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104635:	89 f9                	mov    %edi,%ecx
f0104637:	d3 e6                	shl    %cl,%esi
f0104639:	39 c6                	cmp    %eax,%esi
f010463b:	73 07                	jae    f0104644 <__udivdi3+0xc4>
f010463d:	39 d5                	cmp    %edx,%ebp
f010463f:	75 03                	jne    f0104644 <__udivdi3+0xc4>
f0104641:	83 eb 01             	sub    $0x1,%ebx
f0104644:	31 ff                	xor    %edi,%edi
f0104646:	89 d8                	mov    %ebx,%eax
f0104648:	89 fa                	mov    %edi,%edx
f010464a:	83 c4 1c             	add    $0x1c,%esp
f010464d:	5b                   	pop    %ebx
f010464e:	5e                   	pop    %esi
f010464f:	5f                   	pop    %edi
f0104650:	5d                   	pop    %ebp
f0104651:	c3                   	ret    
f0104652:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104658:	31 ff                	xor    %edi,%edi
f010465a:	31 db                	xor    %ebx,%ebx
f010465c:	89 d8                	mov    %ebx,%eax
f010465e:	89 fa                	mov    %edi,%edx
f0104660:	83 c4 1c             	add    $0x1c,%esp
f0104663:	5b                   	pop    %ebx
f0104664:	5e                   	pop    %esi
f0104665:	5f                   	pop    %edi
f0104666:	5d                   	pop    %ebp
f0104667:	c3                   	ret    
f0104668:	90                   	nop
f0104669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104670:	89 d8                	mov    %ebx,%eax
f0104672:	f7 f7                	div    %edi
f0104674:	31 ff                	xor    %edi,%edi
f0104676:	89 c3                	mov    %eax,%ebx
f0104678:	89 d8                	mov    %ebx,%eax
f010467a:	89 fa                	mov    %edi,%edx
f010467c:	83 c4 1c             	add    $0x1c,%esp
f010467f:	5b                   	pop    %ebx
f0104680:	5e                   	pop    %esi
f0104681:	5f                   	pop    %edi
f0104682:	5d                   	pop    %ebp
f0104683:	c3                   	ret    
f0104684:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104688:	39 ce                	cmp    %ecx,%esi
f010468a:	72 0c                	jb     f0104698 <__udivdi3+0x118>
f010468c:	31 db                	xor    %ebx,%ebx
f010468e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104692:	0f 87 34 ff ff ff    	ja     f01045cc <__udivdi3+0x4c>
f0104698:	bb 01 00 00 00       	mov    $0x1,%ebx
f010469d:	e9 2a ff ff ff       	jmp    f01045cc <__udivdi3+0x4c>
f01046a2:	66 90                	xchg   %ax,%ax
f01046a4:	66 90                	xchg   %ax,%ax
f01046a6:	66 90                	xchg   %ax,%ax
f01046a8:	66 90                	xchg   %ax,%ax
f01046aa:	66 90                	xchg   %ax,%ax
f01046ac:	66 90                	xchg   %ax,%ax
f01046ae:	66 90                	xchg   %ax,%ax

f01046b0 <__umoddi3>:
f01046b0:	55                   	push   %ebp
f01046b1:	57                   	push   %edi
f01046b2:	56                   	push   %esi
f01046b3:	53                   	push   %ebx
f01046b4:	83 ec 1c             	sub    $0x1c,%esp
f01046b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01046bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01046bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01046c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01046c7:	85 d2                	test   %edx,%edx
f01046c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01046cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01046d1:	89 f3                	mov    %esi,%ebx
f01046d3:	89 3c 24             	mov    %edi,(%esp)
f01046d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01046da:	75 1c                	jne    f01046f8 <__umoddi3+0x48>
f01046dc:	39 f7                	cmp    %esi,%edi
f01046de:	76 50                	jbe    f0104730 <__umoddi3+0x80>
f01046e0:	89 c8                	mov    %ecx,%eax
f01046e2:	89 f2                	mov    %esi,%edx
f01046e4:	f7 f7                	div    %edi
f01046e6:	89 d0                	mov    %edx,%eax
f01046e8:	31 d2                	xor    %edx,%edx
f01046ea:	83 c4 1c             	add    $0x1c,%esp
f01046ed:	5b                   	pop    %ebx
f01046ee:	5e                   	pop    %esi
f01046ef:	5f                   	pop    %edi
f01046f0:	5d                   	pop    %ebp
f01046f1:	c3                   	ret    
f01046f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046f8:	39 f2                	cmp    %esi,%edx
f01046fa:	89 d0                	mov    %edx,%eax
f01046fc:	77 52                	ja     f0104750 <__umoddi3+0xa0>
f01046fe:	0f bd ea             	bsr    %edx,%ebp
f0104701:	83 f5 1f             	xor    $0x1f,%ebp
f0104704:	75 5a                	jne    f0104760 <__umoddi3+0xb0>
f0104706:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010470a:	0f 82 e0 00 00 00    	jb     f01047f0 <__umoddi3+0x140>
f0104710:	39 0c 24             	cmp    %ecx,(%esp)
f0104713:	0f 86 d7 00 00 00    	jbe    f01047f0 <__umoddi3+0x140>
f0104719:	8b 44 24 08          	mov    0x8(%esp),%eax
f010471d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104721:	83 c4 1c             	add    $0x1c,%esp
f0104724:	5b                   	pop    %ebx
f0104725:	5e                   	pop    %esi
f0104726:	5f                   	pop    %edi
f0104727:	5d                   	pop    %ebp
f0104728:	c3                   	ret    
f0104729:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104730:	85 ff                	test   %edi,%edi
f0104732:	89 fd                	mov    %edi,%ebp
f0104734:	75 0b                	jne    f0104741 <__umoddi3+0x91>
f0104736:	b8 01 00 00 00       	mov    $0x1,%eax
f010473b:	31 d2                	xor    %edx,%edx
f010473d:	f7 f7                	div    %edi
f010473f:	89 c5                	mov    %eax,%ebp
f0104741:	89 f0                	mov    %esi,%eax
f0104743:	31 d2                	xor    %edx,%edx
f0104745:	f7 f5                	div    %ebp
f0104747:	89 c8                	mov    %ecx,%eax
f0104749:	f7 f5                	div    %ebp
f010474b:	89 d0                	mov    %edx,%eax
f010474d:	eb 99                	jmp    f01046e8 <__umoddi3+0x38>
f010474f:	90                   	nop
f0104750:	89 c8                	mov    %ecx,%eax
f0104752:	89 f2                	mov    %esi,%edx
f0104754:	83 c4 1c             	add    $0x1c,%esp
f0104757:	5b                   	pop    %ebx
f0104758:	5e                   	pop    %esi
f0104759:	5f                   	pop    %edi
f010475a:	5d                   	pop    %ebp
f010475b:	c3                   	ret    
f010475c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104760:	8b 34 24             	mov    (%esp),%esi
f0104763:	bf 20 00 00 00       	mov    $0x20,%edi
f0104768:	89 e9                	mov    %ebp,%ecx
f010476a:	29 ef                	sub    %ebp,%edi
f010476c:	d3 e0                	shl    %cl,%eax
f010476e:	89 f9                	mov    %edi,%ecx
f0104770:	89 f2                	mov    %esi,%edx
f0104772:	d3 ea                	shr    %cl,%edx
f0104774:	89 e9                	mov    %ebp,%ecx
f0104776:	09 c2                	or     %eax,%edx
f0104778:	89 d8                	mov    %ebx,%eax
f010477a:	89 14 24             	mov    %edx,(%esp)
f010477d:	89 f2                	mov    %esi,%edx
f010477f:	d3 e2                	shl    %cl,%edx
f0104781:	89 f9                	mov    %edi,%ecx
f0104783:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104787:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010478b:	d3 e8                	shr    %cl,%eax
f010478d:	89 e9                	mov    %ebp,%ecx
f010478f:	89 c6                	mov    %eax,%esi
f0104791:	d3 e3                	shl    %cl,%ebx
f0104793:	89 f9                	mov    %edi,%ecx
f0104795:	89 d0                	mov    %edx,%eax
f0104797:	d3 e8                	shr    %cl,%eax
f0104799:	89 e9                	mov    %ebp,%ecx
f010479b:	09 d8                	or     %ebx,%eax
f010479d:	89 d3                	mov    %edx,%ebx
f010479f:	89 f2                	mov    %esi,%edx
f01047a1:	f7 34 24             	divl   (%esp)
f01047a4:	89 d6                	mov    %edx,%esi
f01047a6:	d3 e3                	shl    %cl,%ebx
f01047a8:	f7 64 24 04          	mull   0x4(%esp)
f01047ac:	39 d6                	cmp    %edx,%esi
f01047ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01047b2:	89 d1                	mov    %edx,%ecx
f01047b4:	89 c3                	mov    %eax,%ebx
f01047b6:	72 08                	jb     f01047c0 <__umoddi3+0x110>
f01047b8:	75 11                	jne    f01047cb <__umoddi3+0x11b>
f01047ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01047be:	73 0b                	jae    f01047cb <__umoddi3+0x11b>
f01047c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01047c4:	1b 14 24             	sbb    (%esp),%edx
f01047c7:	89 d1                	mov    %edx,%ecx
f01047c9:	89 c3                	mov    %eax,%ebx
f01047cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01047cf:	29 da                	sub    %ebx,%edx
f01047d1:	19 ce                	sbb    %ecx,%esi
f01047d3:	89 f9                	mov    %edi,%ecx
f01047d5:	89 f0                	mov    %esi,%eax
f01047d7:	d3 e0                	shl    %cl,%eax
f01047d9:	89 e9                	mov    %ebp,%ecx
f01047db:	d3 ea                	shr    %cl,%edx
f01047dd:	89 e9                	mov    %ebp,%ecx
f01047df:	d3 ee                	shr    %cl,%esi
f01047e1:	09 d0                	or     %edx,%eax
f01047e3:	89 f2                	mov    %esi,%edx
f01047e5:	83 c4 1c             	add    $0x1c,%esp
f01047e8:	5b                   	pop    %ebx
f01047e9:	5e                   	pop    %esi
f01047ea:	5f                   	pop    %edi
f01047eb:	5d                   	pop    %ebp
f01047ec:	c3                   	ret    
f01047ed:	8d 76 00             	lea    0x0(%esi),%esi
f01047f0:	29 f9                	sub    %edi,%ecx
f01047f2:	19 d6                	sbb    %edx,%esi
f01047f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047fc:	e9 18 ff ff ff       	jmp    f0104719 <__umoddi3+0x69>
