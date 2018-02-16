
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 3b 32 00 00       	call   f0103298 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 37 10 f0       	push   $0xf0103740
f010006f:	e8 e1 26 00 00       	call   f0102755 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 2b 10 00 00       	call   f01010a4 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 07 07 00 00       	call   f010078d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 5b 37 10 f0       	push   $0xf010375b
f01000b5:	e8 9b 26 00 00       	call   f0102755 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 6b 26 00 00       	call   f010272f <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 15 3f 10 f0 	movl   $0xf0103f15,(%esp)
f01000cb:	e8 85 26 00 00       	call   f0102755 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 b0 06 00 00       	call   f010078d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 73 37 10 f0       	push   $0xf0103773
f01000f7:	e8 59 26 00 00       	call   f0102755 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 27 26 00 00       	call   f010272f <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 15 3f 10 f0 	movl   $0xf0103f15,(%esp)
f010010f:	e8 41 26 00 00       	call   f0102755 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 e0 38 10 f0 	movzbl -0xfefc720(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 e0 38 10 f0 	movzbl -0xfefc720(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a e0 37 10 f0 	movzbl -0xfefc820(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d c0 37 10 f0 	mov    -0xfefc840(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 8d 37 10 f0       	push   $0xf010378d
f010026d:	e8 e3 24 00 00       	call   f0102755 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 c4 2e 00 00       	call   f01032e5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 99 37 10 f0       	push   $0xf0103799
f01005f0:	e8 60 21 00 00       	call   f0102755 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 e0 39 10 f0       	push   $0xf01039e0
f0100636:	68 fe 39 10 f0       	push   $0xf01039fe
f010063b:	68 03 3a 10 f0       	push   $0xf0103a03
f0100640:	e8 10 21 00 00       	call   f0102755 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 90 3a 10 f0       	push   $0xf0103a90
f010064d:	68 0c 3a 10 f0       	push   $0xf0103a0c
f0100652:	68 03 3a 10 f0       	push   $0xf0103a03
f0100657:	e8 f9 20 00 00       	call   f0102755 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 15 3a 10 f0       	push   $0xf0103a15
f010066e:	e8 e2 20 00 00       	call   f0102755 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 b8 3a 10 f0       	push   $0xf0103ab8
f0100680:	e8 d0 20 00 00       	call   f0102755 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 e0 3a 10 f0       	push   $0xf0103ae0
f0100697:	e8 b9 20 00 00       	call   f0102755 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 21 37 10 00       	push   $0x103721
f01006a4:	68 21 37 10 f0       	push   $0xf0103721
f01006a9:	68 04 3b 10 f0       	push   $0xf0103b04
f01006ae:	e8 a2 20 00 00       	call   f0102755 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 73 11 00       	push   $0x117300
f01006bb:	68 00 73 11 f0       	push   $0xf0117300
f01006c0:	68 28 3b 10 f0       	push   $0xf0103b28
f01006c5:	e8 8b 20 00 00       	call   f0102755 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 70 79 11 00       	push   $0x117970
f01006d2:	68 70 79 11 f0       	push   $0xf0117970
f01006d7:	68 4c 3b 10 f0       	push   $0xf0103b4c
f01006dc:	e8 74 20 00 00       	call   f0102755 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 70 3b 10 f0       	push   $0xf0103b70
f0100707:	e8 49 20 00 00       	call   f0102755 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	56                   	push   %esi
f0100717:	53                   	push   %ebx
f0100718:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010071b:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f010071d:	68 2e 3a 10 f0       	push   $0xf0103a2e
f0100722:	e8 2e 20 00 00       	call   f0102755 <cprintf>
	while(p)
f0100727:	83 c4 10             	add    $0x10,%esp
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
		debuginfo_eip(*(p+1), &info);
f010072a:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f010072d:	eb 4e                	jmp    f010077d <mon_backtrace+0x6a>
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
f010072f:	ff 73 18             	pushl  0x18(%ebx)
f0100732:	ff 73 14             	pushl  0x14(%ebx)
f0100735:	ff 73 10             	pushl  0x10(%ebx)
f0100738:	ff 73 0c             	pushl  0xc(%ebx)
f010073b:	ff 73 08             	pushl  0x8(%ebx)
f010073e:	ff 73 04             	pushl  0x4(%ebx)
f0100741:	53                   	push   %ebx
f0100742:	68 9c 3b 10 f0       	push   $0xf0103b9c
f0100747:	e8 09 20 00 00       	call   f0102755 <cprintf>
		debuginfo_eip(*(p+1), &info);
f010074c:	83 c4 18             	add    $0x18,%esp
f010074f:	56                   	push   %esi
f0100750:	ff 73 04             	pushl  0x4(%ebx)
f0100753:	e8 07 21 00 00       	call   f010285f <debuginfo_eip>
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
f0100758:	83 c4 08             	add    $0x8,%esp
f010075b:	8b 43 04             	mov    0x4(%ebx),%eax
f010075e:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100761:	50                   	push   %eax
f0100762:	ff 75 e8             	pushl  -0x18(%ebp)
f0100765:	ff 75 ec             	pushl  -0x14(%ebp)
f0100768:	ff 75 e4             	pushl  -0x1c(%ebp)
f010076b:	ff 75 e0             	pushl  -0x20(%ebp)
f010076e:	68 40 3a 10 f0       	push   $0xf0103a40
f0100773:	e8 dd 1f 00 00       	call   f0102755 <cprintf>
		p=(uint32_t*)*p;
f0100778:	8b 1b                	mov    (%ebx),%ebx
f010077a:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f010077d:	85 db                	test   %ebx,%ebx
f010077f:	75 ae                	jne    f010072f <mon_backtrace+0x1c>
		debuginfo_eip(*(p+1), &info);
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
		p=(uint32_t*)*p;
	}
	return 0;
}
f0100781:	b8 00 00 00 00       	mov    $0x0,%eax
f0100786:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100789:	5b                   	pop    %ebx
f010078a:	5e                   	pop    %esi
f010078b:	5d                   	pop    %ebp
f010078c:	c3                   	ret    

f010078d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010078d:	55                   	push   %ebp
f010078e:	89 e5                	mov    %esp,%ebp
f0100790:	57                   	push   %edi
f0100791:	56                   	push   %esi
f0100792:	53                   	push   %ebx
f0100793:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100796:	68 d0 3b 10 f0       	push   $0xf0103bd0
f010079b:	e8 b5 1f 00 00       	call   f0102755 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a0:	c7 04 24 f4 3b 10 f0 	movl   $0xf0103bf4,(%esp)
f01007a7:	e8 a9 1f 00 00       	call   f0102755 <cprintf>
f01007ac:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007af:	83 ec 0c             	sub    $0xc,%esp
f01007b2:	68 52 3a 10 f0       	push   $0xf0103a52
f01007b7:	e8 85 28 00 00       	call   f0103041 <readline>
f01007bc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007be:	83 c4 10             	add    $0x10,%esp
f01007c1:	85 c0                	test   %eax,%eax
f01007c3:	74 ea                	je     f01007af <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007cc:	be 00 00 00 00       	mov    $0x0,%esi
f01007d1:	eb 0a                	jmp    f01007dd <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007d3:	c6 03 00             	movb   $0x0,(%ebx)
f01007d6:	89 f7                	mov    %esi,%edi
f01007d8:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007db:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007dd:	0f b6 03             	movzbl (%ebx),%eax
f01007e0:	84 c0                	test   %al,%al
f01007e2:	74 63                	je     f0100847 <monitor+0xba>
f01007e4:	83 ec 08             	sub    $0x8,%esp
f01007e7:	0f be c0             	movsbl %al,%eax
f01007ea:	50                   	push   %eax
f01007eb:	68 56 3a 10 f0       	push   $0xf0103a56
f01007f0:	e8 66 2a 00 00       	call   f010325b <strchr>
f01007f5:	83 c4 10             	add    $0x10,%esp
f01007f8:	85 c0                	test   %eax,%eax
f01007fa:	75 d7                	jne    f01007d3 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007fc:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007ff:	74 46                	je     f0100847 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100801:	83 fe 0f             	cmp    $0xf,%esi
f0100804:	75 14                	jne    f010081a <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100806:	83 ec 08             	sub    $0x8,%esp
f0100809:	6a 10                	push   $0x10
f010080b:	68 5b 3a 10 f0       	push   $0xf0103a5b
f0100810:	e8 40 1f 00 00       	call   f0102755 <cprintf>
f0100815:	83 c4 10             	add    $0x10,%esp
f0100818:	eb 95                	jmp    f01007af <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010081a:	8d 7e 01             	lea    0x1(%esi),%edi
f010081d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100821:	eb 03                	jmp    f0100826 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100823:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100826:	0f b6 03             	movzbl (%ebx),%eax
f0100829:	84 c0                	test   %al,%al
f010082b:	74 ae                	je     f01007db <monitor+0x4e>
f010082d:	83 ec 08             	sub    $0x8,%esp
f0100830:	0f be c0             	movsbl %al,%eax
f0100833:	50                   	push   %eax
f0100834:	68 56 3a 10 f0       	push   $0xf0103a56
f0100839:	e8 1d 2a 00 00       	call   f010325b <strchr>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	74 de                	je     f0100823 <monitor+0x96>
f0100845:	eb 94                	jmp    f01007db <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100847:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010084e:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010084f:	85 f6                	test   %esi,%esi
f0100851:	0f 84 58 ff ff ff    	je     f01007af <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100857:	83 ec 08             	sub    $0x8,%esp
f010085a:	68 fe 39 10 f0       	push   $0xf01039fe
f010085f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100862:	e8 96 29 00 00       	call   f01031fd <strcmp>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 1e                	je     f010088c <monitor+0xff>
f010086e:	83 ec 08             	sub    $0x8,%esp
f0100871:	68 0c 3a 10 f0       	push   $0xf0103a0c
f0100876:	ff 75 a8             	pushl  -0x58(%ebp)
f0100879:	e8 7f 29 00 00       	call   f01031fd <strcmp>
f010087e:	83 c4 10             	add    $0x10,%esp
f0100881:	85 c0                	test   %eax,%eax
f0100883:	75 2f                	jne    f01008b4 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100885:	b8 01 00 00 00       	mov    $0x1,%eax
f010088a:	eb 05                	jmp    f0100891 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010088c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100891:	83 ec 04             	sub    $0x4,%esp
f0100894:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100897:	01 d0                	add    %edx,%eax
f0100899:	ff 75 08             	pushl  0x8(%ebp)
f010089c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010089f:	51                   	push   %ecx
f01008a0:	56                   	push   %esi
f01008a1:	ff 14 85 24 3c 10 f0 	call   *-0xfefc3dc(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008a8:	83 c4 10             	add    $0x10,%esp
f01008ab:	85 c0                	test   %eax,%eax
f01008ad:	78 1d                	js     f01008cc <monitor+0x13f>
f01008af:	e9 fb fe ff ff       	jmp    f01007af <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b4:	83 ec 08             	sub    $0x8,%esp
f01008b7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ba:	68 78 3a 10 f0       	push   $0xf0103a78
f01008bf:	e8 91 1e 00 00       	call   f0102755 <cprintf>
f01008c4:	83 c4 10             	add    $0x10,%esp
f01008c7:	e9 e3 fe ff ff       	jmp    f01007af <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008cf:	5b                   	pop    %ebx
f01008d0:	5e                   	pop    %esi
f01008d1:	5f                   	pop    %edi
f01008d2:	5d                   	pop    %ebp
f01008d3:	c3                   	ret    

f01008d4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008d4:	55                   	push   %ebp
f01008d5:	89 e5                	mov    %esp,%ebp
f01008d7:	56                   	push   %esi
f01008d8:	53                   	push   %ebx
f01008d9:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008db:	83 ec 0c             	sub    $0xc,%esp
f01008de:	50                   	push   %eax
f01008df:	e8 0a 1e 00 00       	call   f01026ee <mc146818_read>
f01008e4:	89 c6                	mov    %eax,%esi
f01008e6:	83 c3 01             	add    $0x1,%ebx
f01008e9:	89 1c 24             	mov    %ebx,(%esp)
f01008ec:	e8 fd 1d 00 00       	call   f01026ee <mc146818_read>
f01008f1:	c1 e0 08             	shl    $0x8,%eax
f01008f4:	09 f0                	or     %esi,%eax
}
f01008f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008f9:	5b                   	pop    %ebx
f01008fa:	5e                   	pop    %esi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008fd:	55                   	push   %ebp
f01008fe:	89 e5                	mov    %esp,%ebp
f0100900:	53                   	push   %ebx
f0100901:	83 ec 04             	sub    $0x4,%esp
f0100904:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100906:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f010090d:	75 0f                	jne    f010091e <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010090f:	b8 6f 89 11 f0       	mov    $0xf011896f,%eax
f0100914:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100919:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	

	cprintf("boot_allocated memory at %x\n", nextfree);
f010091e:	83 ec 08             	sub    $0x8,%esp
f0100921:	ff 35 38 75 11 f0    	pushl  0xf0117538
f0100927:	68 34 3c 10 f0       	push   $0xf0103c34
f010092c:	e8 24 1e 00 00       	call   f0102755 <cprintf>
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f0100931:	89 d8                	mov    %ebx,%eax
f0100933:	03 05 38 75 11 f0    	add    0xf0117538,%eax
f0100939:	05 ff 0f 00 00       	add    $0xfff,%eax
f010093e:	83 c4 08             	add    $0x8,%esp
f0100941:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100946:	50                   	push   %eax
f0100947:	68 51 3c 10 f0       	push   $0xf0103c51
f010094c:	e8 04 1e 00 00       	call   f0102755 <cprintf>
	if (n>0) {
f0100951:	83 c4 10             	add    $0x10,%esp
f0100954:	85 db                	test   %ebx,%ebx
f0100956:	74 1a                	je     f0100972 <boot_alloc+0x75>
		char *temp = nextfree;
f0100958:	a1 38 75 11 f0       	mov    0xf0117538,%eax
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f010095d:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f0100964:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010096a:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
		return temp;
f0100970:	eb 2c                	jmp    f010099e <boot_alloc+0xa1>
	} 
	if ((uint32_t)nextfree > KERNBASE + npages*PGSIZE){
f0100972:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100977:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010097d:	8d 91 00 00 0f 00    	lea    0xf0000(%ecx),%edx
f0100983:	c1 e2 0c             	shl    $0xc,%edx
f0100986:	39 d0                	cmp    %edx,%eax
f0100988:	76 14                	jbe    f010099e <boot_alloc+0xa1>
	panic ("boot_alloc failed - Out of memory");
f010098a:	83 ec 04             	sub    $0x4,%esp
f010098d:	68 48 3f 10 f0       	push   $0xf0103f48
f0100992:	6a 73                	push   $0x73
f0100994:	68 64 3c 10 f0       	push   $0xf0103c64
f0100999:	e8 ed f6 ff ff       	call   f010008b <_panic>
	}
	else
	return nextfree;
	}
f010099e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009a1:	c9                   	leave  
f01009a2:	c3                   	ret    

f01009a3 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009a3:	89 d1                	mov    %edx,%ecx
f01009a5:	c1 e9 16             	shr    $0x16,%ecx
f01009a8:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009ab:	a8 01                	test   $0x1,%al
f01009ad:	74 52                	je     f0100a01 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009b4:	89 c1                	mov    %eax,%ecx
f01009b6:	c1 e9 0c             	shr    $0xc,%ecx
f01009b9:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f01009bf:	72 1b                	jb     f01009dc <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009c1:	55                   	push   %ebp
f01009c2:	89 e5                	mov    %esp,%ebp
f01009c4:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009c7:	50                   	push   %eax
f01009c8:	68 6c 3f 10 f0       	push   $0xf0103f6c
f01009cd:	68 09 03 00 00       	push   $0x309
f01009d2:	68 64 3c 10 f0       	push   $0xf0103c64
f01009d7:	e8 af f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009dc:	c1 ea 0c             	shr    $0xc,%edx
f01009df:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009e5:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009ec:	89 c2                	mov    %eax,%edx
f01009ee:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f6:	85 d2                	test   %edx,%edx
f01009f8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009fd:	0f 44 c2             	cmove  %edx,%eax
f0100a00:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a06:	c3                   	ret    

f0100a07 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a07:	55                   	push   %ebp
f0100a08:	89 e5                	mov    %esp,%ebp
f0100a0a:	57                   	push   %edi
f0100a0b:	56                   	push   %esi
f0100a0c:	53                   	push   %ebx
f0100a0d:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a10:	84 c0                	test   %al,%al
f0100a12:	0f 85 81 02 00 00    	jne    f0100c99 <check_page_free_list+0x292>
f0100a18:	e9 8e 02 00 00       	jmp    f0100cab <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a1d:	83 ec 04             	sub    $0x4,%esp
f0100a20:	68 90 3f 10 f0       	push   $0xf0103f90
f0100a25:	68 4a 02 00 00       	push   $0x24a
f0100a2a:	68 64 3c 10 f0       	push   $0xf0103c64
f0100a2f:	e8 57 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a34:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a37:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a3a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a3d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a40:	89 c2                	mov    %eax,%edx
f0100a42:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100a48:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a4e:	0f 95 c2             	setne  %dl
f0100a51:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a54:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a58:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a5a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a5e:	8b 00                	mov    (%eax),%eax
f0100a60:	85 c0                	test   %eax,%eax
f0100a62:	75 dc                	jne    f0100a40 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a67:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a6d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a70:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a73:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a75:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a78:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a7d:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a82:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a88:	eb 53                	jmp    f0100add <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a8a:	89 d8                	mov    %ebx,%eax
f0100a8c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a92:	c1 f8 03             	sar    $0x3,%eax
f0100a95:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a98:	89 c2                	mov    %eax,%edx
f0100a9a:	c1 ea 16             	shr    $0x16,%edx
f0100a9d:	39 f2                	cmp    %esi,%edx
f0100a9f:	73 3a                	jae    f0100adb <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aa1:	89 c2                	mov    %eax,%edx
f0100aa3:	c1 ea 0c             	shr    $0xc,%edx
f0100aa6:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100aac:	72 12                	jb     f0100ac0 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aae:	50                   	push   %eax
f0100aaf:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0100ab4:	6a 52                	push   $0x52
f0100ab6:	68 70 3c 10 f0       	push   $0xf0103c70
f0100abb:	e8 cb f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ac0:	83 ec 04             	sub    $0x4,%esp
f0100ac3:	68 80 00 00 00       	push   $0x80
f0100ac8:	68 97 00 00 00       	push   $0x97
f0100acd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ad2:	50                   	push   %eax
f0100ad3:	e8 c0 27 00 00       	call   f0103298 <memset>
f0100ad8:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100adb:	8b 1b                	mov    (%ebx),%ebx
f0100add:	85 db                	test   %ebx,%ebx
f0100adf:	75 a9                	jne    f0100a8a <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ae1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae6:	e8 12 fe ff ff       	call   f01008fd <boot_alloc>
f0100aeb:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aee:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100af4:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100afa:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100aff:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b02:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b05:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b08:	be 00 00 00 00       	mov    $0x0,%esi
f0100b0d:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b10:	e9 30 01 00 00       	jmp    f0100c45 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b15:	39 ca                	cmp    %ecx,%edx
f0100b17:	73 19                	jae    f0100b32 <check_page_free_list+0x12b>
f0100b19:	68 7e 3c 10 f0       	push   $0xf0103c7e
f0100b1e:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100b23:	68 64 02 00 00       	push   $0x264
f0100b28:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b2d:	e8 59 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b32:	39 fa                	cmp    %edi,%edx
f0100b34:	72 19                	jb     f0100b4f <check_page_free_list+0x148>
f0100b36:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100b3b:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100b40:	68 65 02 00 00       	push   $0x265
f0100b45:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b4f:	89 d0                	mov    %edx,%eax
f0100b51:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b54:	a8 07                	test   $0x7,%al
f0100b56:	74 19                	je     f0100b71 <check_page_free_list+0x16a>
f0100b58:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0100b5d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100b62:	68 66 02 00 00       	push   $0x266
f0100b67:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b6c:	e8 1a f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b71:	c1 f8 03             	sar    $0x3,%eax
f0100b74:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b77:	85 c0                	test   %eax,%eax
f0100b79:	75 19                	jne    f0100b94 <check_page_free_list+0x18d>
f0100b7b:	68 b3 3c 10 f0       	push   $0xf0103cb3
f0100b80:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100b85:	68 69 02 00 00       	push   $0x269
f0100b8a:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b8f:	e8 f7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b94:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b99:	75 19                	jne    f0100bb4 <check_page_free_list+0x1ad>
f0100b9b:	68 c4 3c 10 f0       	push   $0xf0103cc4
f0100ba0:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100ba5:	68 6a 02 00 00       	push   $0x26a
f0100baa:	68 64 3c 10 f0       	push   $0xf0103c64
f0100baf:	e8 d7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bb4:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bb9:	75 19                	jne    f0100bd4 <check_page_free_list+0x1cd>
f0100bbb:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0100bc0:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100bc5:	68 6b 02 00 00       	push   $0x26b
f0100bca:	68 64 3c 10 f0       	push   $0xf0103c64
f0100bcf:	e8 b7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bd4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bd9:	75 19                	jne    f0100bf4 <check_page_free_list+0x1ed>
f0100bdb:	68 dd 3c 10 f0       	push   $0xf0103cdd
f0100be0:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100be5:	68 6c 02 00 00       	push   $0x26c
f0100bea:	68 64 3c 10 f0       	push   $0xf0103c64
f0100bef:	e8 97 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bf4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bf9:	76 3f                	jbe    f0100c3a <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bfb:	89 c3                	mov    %eax,%ebx
f0100bfd:	c1 eb 0c             	shr    $0xc,%ebx
f0100c00:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c03:	77 12                	ja     f0100c17 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c05:	50                   	push   %eax
f0100c06:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0100c0b:	6a 52                	push   $0x52
f0100c0d:	68 70 3c 10 f0       	push   $0xf0103c70
f0100c12:	e8 74 f4 ff ff       	call   f010008b <_panic>
f0100c17:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c1c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c1f:	76 1e                	jbe    f0100c3f <check_page_free_list+0x238>
f0100c21:	68 0c 40 10 f0       	push   $0xf010400c
f0100c26:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100c2b:	68 6d 02 00 00       	push   $0x26d
f0100c30:	68 64 3c 10 f0       	push   $0xf0103c64
f0100c35:	e8 51 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c3a:	83 c6 01             	add    $0x1,%esi
f0100c3d:	eb 04                	jmp    f0100c43 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c3f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c43:	8b 12                	mov    (%edx),%edx
f0100c45:	85 d2                	test   %edx,%edx
f0100c47:	0f 85 c8 fe ff ff    	jne    f0100b15 <check_page_free_list+0x10e>
f0100c4d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c50:	85 f6                	test   %esi,%esi
f0100c52:	7f 19                	jg     f0100c6d <check_page_free_list+0x266>
f0100c54:	68 f7 3c 10 f0       	push   $0xf0103cf7
f0100c59:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100c5e:	68 75 02 00 00       	push   $0x275
f0100c63:	68 64 3c 10 f0       	push   $0xf0103c64
f0100c68:	e8 1e f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c6d:	85 db                	test   %ebx,%ebx
f0100c6f:	7f 19                	jg     f0100c8a <check_page_free_list+0x283>
f0100c71:	68 09 3d 10 f0       	push   $0xf0103d09
f0100c76:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100c7b:	68 76 02 00 00       	push   $0x276
f0100c80:	68 64 3c 10 f0       	push   $0xf0103c64
f0100c85:	e8 01 f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c8a:	83 ec 0c             	sub    $0xc,%esp
f0100c8d:	68 54 40 10 f0       	push   $0xf0104054
f0100c92:	e8 be 1a 00 00       	call   f0102755 <cprintf>
}
f0100c97:	eb 29                	jmp    f0100cc2 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c99:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c9e:	85 c0                	test   %eax,%eax
f0100ca0:	0f 85 8e fd ff ff    	jne    f0100a34 <check_page_free_list+0x2d>
f0100ca6:	e9 72 fd ff ff       	jmp    f0100a1d <check_page_free_list+0x16>
f0100cab:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100cb2:	0f 84 65 fd ff ff    	je     f0100a1d <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cb8:	be 00 04 00 00       	mov    $0x400,%esi
f0100cbd:	e9 c0 fd ff ff       	jmp    f0100a82 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cc2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cc5:	5b                   	pop    %ebx
f0100cc6:	5e                   	pop    %esi
f0100cc7:	5f                   	pop    %edi
f0100cc8:	5d                   	pop    %ebp
f0100cc9:	c3                   	ret    

f0100cca <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cca:	55                   	push   %ebp
f0100ccb:	89 e5                	mov    %esp,%ebp
f0100ccd:	57                   	push   %edi
f0100cce:	56                   	push   %esi
f0100ccf:	53                   	push   %ebx
f0100cd0:	83 ec 1c             	sub    $0x1c,%esp
	size_t i;
	// 0xA0
	size_t io_hole_begin = IOPHYSMEM / PGSIZE;
	// 0x100
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
f0100cd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd8:	e8 20 fc ff ff       	call   f01008fd <boot_alloc>
f0100cdd:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ce2:	c1 e8 0c             	shr    $0xc,%eax
f0100ce5:	05 00 01 00 00       	add    $0x100,%eax
f0100cea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	page_free_list = NULL;
f0100ced:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0100cf4:	00 00 00 
		// 1)
		if (i == 0) {
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		// 2) i < 0xA0
		} else if (i < npages_basemem) {
f0100cf7:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
	page_free_list = NULL;

	// i < 0x40FF
	for (i = 0; i < npages; i++) {
f0100cfd:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d02:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d07:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d11:	e9 a4 00 00 00       	jmp    f0100dba <page_init+0xf0>
		// 1)
		if (i == 0) {
f0100d16:	85 c0                	test   %eax,%eax
f0100d18:	75 17                	jne    f0100d31 <page_init+0x67>
			pages[i].pp_ref = 1;
f0100d1a:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0100d20:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d26:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d2c:	e9 83 00 00 00       	jmp    f0100db4 <page_init+0xea>
		// 2) i < 0xA0
		} else if (i < npages_basemem) {
f0100d31:	39 f0                	cmp    %esi,%eax
f0100d33:	73 1f                	jae    f0100d54 <page_init+0x8a>
			pages[i].pp_ref = 0;
f0100d35:	89 d1                	mov    %edx,%ecx
f0100d37:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d3d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100d43:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100d45:	89 d3                	mov    %edx,%ebx
f0100d47:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
f0100d4d:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d52:	eb 60                	jmp    f0100db4 <page_init+0xea>
		// 3) 0xA0 <= i < 0x100
		} else if (io_hole_begin <= i && i < io_hole_end) {
f0100d54:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100d5a:	83 f9 5f             	cmp    $0x5f,%ecx
f0100d5d:	77 16                	ja     f0100d75 <page_init+0xab>
			pages[i].pp_ref = 1;
f0100d5f:	89 d1                	mov    %edx,%ecx
f0100d61:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d67:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d6d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d73:	eb 3f                	jmp    f0100db4 <page_init+0xea>
		// 4) 0x100 <= i < 0x400 (0xF0400000)
		} else if (io_hole_end <= i && i < kernel_end) {
f0100d75:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100d7a:	76 1b                	jbe    f0100d97 <page_init+0xcd>
f0100d7c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100d7f:	73 16                	jae    f0100d97 <page_init+0xcd>
			pages[i].pp_ref = 1;
f0100d81:	89 d1                	mov    %edx,%ecx
f0100d83:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d89:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d8f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d95:	eb 1d                	jmp    f0100db4 <page_init+0xea>
		// 4) 0x400 <= i
		} else {
			pages[i].pp_ref = 0;
f0100d97:	89 d1                	mov    %edx,%ecx
f0100d99:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d9f:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100da5:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100da7:	89 d3                	mov    %edx,%ebx
f0100da9:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
f0100daf:	bf 01 00 00 00       	mov    $0x1,%edi
	size_t io_hole_end = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t kernel_end = io_hole_end + (size_t) (boot_alloc(0) - KERNBASE) / PGSIZE;
	page_free_list = NULL;

	// i < 0x40FF
	for (i = 0; i < npages; i++) {
f0100db4:	83 c0 01             	add    $0x1,%eax
f0100db7:	83 c2 08             	add    $0x8,%edx
f0100dba:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100dc0:	0f 82 50 ff ff ff    	jb     f0100d16 <page_init+0x4c>
f0100dc6:	89 f8                	mov    %edi,%eax
f0100dc8:	84 c0                	test   %al,%al
f0100dca:	74 06                	je     f0100dd2 <page_init+0x108>
f0100dcc:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100dd2:	83 c4 1c             	add    $0x1c,%esp
f0100dd5:	5b                   	pop    %ebx
f0100dd6:	5e                   	pop    %esi
f0100dd7:	5f                   	pop    %edi
f0100dd8:	5d                   	pop    %ebp
f0100dd9:	c3                   	ret    

f0100dda <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dda:	55                   	push   %ebp
f0100ddb:	89 e5                	mov    %esp,%ebp
f0100ddd:	53                   	push   %ebx
f0100dde:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *page;
	
	if (page_free_list!=NULL){
f0100de1:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100de7:	85 db                	test   %ebx,%ebx
f0100de9:	74 58                	je     f0100e43 <page_alloc+0x69>
	page = page_free_list;
	page_free_list = page->pp_link;
f0100deb:	8b 03                	mov    (%ebx),%eax
f0100ded:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	page->pp_link = NULL;
f0100df2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	
	if (alloc_flags & ALLOC_ZERO) {
f0100df8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dfc:	74 45                	je     f0100e43 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dfe:	89 d8                	mov    %ebx,%eax
f0100e00:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e06:	c1 f8 03             	sar    $0x3,%eax
f0100e09:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e0c:	89 c2                	mov    %eax,%edx
f0100e0e:	c1 ea 0c             	shr    $0xc,%edx
f0100e11:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e17:	72 12                	jb     f0100e2b <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e19:	50                   	push   %eax
f0100e1a:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0100e1f:	6a 52                	push   $0x52
f0100e21:	68 70 3c 10 f0       	push   $0xf0103c70
f0100e26:	e8 60 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(page), '\0', PGSIZE);
f0100e2b:	83 ec 04             	sub    $0x4,%esp
f0100e2e:	68 00 10 00 00       	push   $0x1000
f0100e33:	6a 00                	push   $0x0
f0100e35:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e3a:	50                   	push   %eax
f0100e3b:	e8 58 24 00 00       	call   f0103298 <memset>
f0100e40:	83 c4 10             	add    $0x10,%esp
	}
	return page;
	}
	return NULL;
	
}
f0100e43:	89 d8                	mov    %ebx,%eax
f0100e45:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e48:	c9                   	leave  
f0100e49:	c3                   	ret    

f0100e4a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e4a:	55                   	push   %ebp
f0100e4b:	89 e5                	mov    %esp,%ebp
f0100e4d:	83 ec 08             	sub    $0x8,%esp
f0100e50:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref!= 0 || pp->pp_link != NULL) {
f0100e53:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e58:	75 05                	jne    f0100e5f <page_free+0x15>
f0100e5a:	83 38 00             	cmpl   $0x0,(%eax)
f0100e5d:	74 17                	je     f0100e76 <page_free+0x2c>
		panic("Page Free Failed: Tried to free page having either reference count>0 or linked");
f0100e5f:	83 ec 04             	sub    $0x4,%esp
f0100e62:	68 78 40 10 f0       	push   $0xf0104078
f0100e67:	68 65 01 00 00       	push   $0x165
f0100e6c:	68 64 3c 10 f0       	push   $0xf0103c64
f0100e71:	e8 15 f2 ff ff       	call   f010008b <_panic>
		
	}

	pp->pp_link = page_free_list;
f0100e76:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e7c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e7e:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e83:	c9                   	leave  
f0100e84:	c3                   	ret    

f0100e85 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e85:	55                   	push   %ebp
f0100e86:	89 e5                	mov    %esp,%ebp
f0100e88:	83 ec 08             	sub    $0x8,%esp
f0100e8b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e8e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e92:	83 e8 01             	sub    $0x1,%eax
f0100e95:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e99:	66 85 c0             	test   %ax,%ax
f0100e9c:	75 0c                	jne    f0100eaa <page_decref+0x25>
		page_free(pp);
f0100e9e:	83 ec 0c             	sub    $0xc,%esp
f0100ea1:	52                   	push   %edx
f0100ea2:	e8 a3 ff ff ff       	call   f0100e4a <page_free>
f0100ea7:	83 c4 10             	add    $0x10,%esp
}
f0100eaa:	c9                   	leave  
f0100eab:	c3                   	ret    

f0100eac <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100eac:	55                   	push   %ebp
f0100ead:	89 e5                	mov    %esp,%ebp
f0100eaf:	56                   	push   %esi
f0100eb0:	53                   	push   %ebx
f0100eb1:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte;
	pde_t *pde= pgdir+PDX(va); 	           //pde = &pgdir[PDX(va)]
f0100eb4:	89 f3                	mov    %esi,%ebx
f0100eb6:	c1 eb 16             	shr    $0x16,%ebx
f0100eb9:	c1 e3 02             	shl    $0x2,%ebx
f0100ebc:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pde & PTE_P)){ 			   //If directory entry not present and create==true
f0100ebf:	f6 03 01             	testb  $0x1,(%ebx)
f0100ec2:	75 2d                	jne    f0100ef1 <pgdir_walk+0x45>
		if (create){  
f0100ec4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ec8:	74 62                	je     f0100f2c <pgdir_walk+0x80>
			pp=page_alloc(ALLOC_ZERO); //Allocate a physical page with ALLOC_ZERO
f0100eca:	83 ec 0c             	sub    $0xc,%esp
f0100ecd:	6a 01                	push   $0x1
f0100ecf:	e8 06 ff ff ff       	call   f0100dda <page_alloc>
			if(pp){                    // If physical page allocated
f0100ed4:	83 c4 10             	add    $0x10,%esp
f0100ed7:	85 c0                	test   %eax,%eax
f0100ed9:	74 58                	je     f0100f33 <pgdir_walk+0x87>
				 
				pp->pp_ref++;      
f0100edb:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
				*pde=page2pa(pp)+PTE_P+PTE_W+PTE_U; //convert page address to physical address
f0100ee0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ee6:	c1 f8 03             	sar    $0x3,%eax
f0100ee9:	c1 e0 0c             	shl    $0xc,%eax
f0100eec:	83 c0 07             	add    $0x7,%eax
f0100eef:	89 03                	mov    %eax,(%ebx)
	else
		return NULL;                               //if create==false
	}

	
	pte=KADDR(PTE_ADDR(*pde));                         //if directory entry present calculate kernel virtual address
f0100ef1:	8b 03                	mov    (%ebx),%eax
f0100ef3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef8:	89 c2                	mov    %eax,%edx
f0100efa:	c1 ea 0c             	shr    $0xc,%edx
f0100efd:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f03:	72 15                	jb     f0100f1a <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f05:	50                   	push   %eax
f0100f06:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0100f0b:	68 a7 01 00 00       	push   $0x1a7
f0100f10:	68 64 3c 10 f0       	push   $0xf0103c64
f0100f15:	e8 71 f1 ff ff       	call   f010008b <_panic>
	
	return (pte + PTX(va));
f0100f1a:	c1 ee 0a             	shr    $0xa,%esi
f0100f1d:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f23:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f2a:	eb 0c                	jmp    f0100f38 <pgdir_walk+0x8c>
				return NULL;				//if not able to allocate page
			    }	
				
					                      
	else
		return NULL;                               //if create==false
f0100f2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f31:	eb 05                	jmp    f0100f38 <pgdir_walk+0x8c>
				 
				pp->pp_ref++;      
				*pde=page2pa(pp)+PTE_P+PTE_W+PTE_U; //convert page address to physical address
			      }
			else
				return NULL;				//if not able to allocate page
f0100f33:	b8 00 00 00 00       	mov    $0x0,%eax
	
	pte=KADDR(PTE_ADDR(*pde));                         //if directory entry present calculate kernel virtual address
	
	return (pte + PTX(va));
	
}
f0100f38:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f3b:	5b                   	pop    %ebx
f0100f3c:	5e                   	pop    %esi
f0100f3d:	5d                   	pop    %ebp
f0100f3e:	c3                   	ret    

f0100f3f <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f3f:	55                   	push   %ebp
f0100f40:	89 e5                	mov    %esp,%ebp
f0100f42:	57                   	push   %edi
f0100f43:	56                   	push   %esi
f0100f44:	53                   	push   %ebx
f0100f45:	83 ec 1c             	sub    $0x1c,%esp
f0100f48:	89 c7                	mov    %eax,%edi
f0100f4a:	89 d6                	mov    %edx,%esi
f0100f4c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100f4f:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte_t *pte = pgdir_walk(pgdir, (const void *) (va + i), 1);
		*pte = (pa + i) | perm | PTE_P;  //PTE_ADDR(pa)=physaddr(pa)&~0xFFF
f0100f54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f57:	83 c8 01             	or     $0x1,%eax
f0100f5a:	89 45 e0             	mov    %eax,-0x20(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100f5d:	eb 3d                	jmp    f0100f9c <boot_map_region+0x5d>
		pte_t *pte = pgdir_walk(pgdir, (const void *) (va + i), 1);
f0100f5f:	83 ec 04             	sub    $0x4,%esp
f0100f62:	6a 01                	push   $0x1
f0100f64:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0100f67:	50                   	push   %eax
f0100f68:	57                   	push   %edi
f0100f69:	e8 3e ff ff ff       	call   f0100eac <pgdir_walk>
		*pte = (pa + i) | perm | PTE_P;  //PTE_ADDR(pa)=physaddr(pa)&~0xFFF
f0100f6e:	89 da                	mov    %ebx,%edx
f0100f70:	03 55 08             	add    0x8(%ebp),%edx
f0100f73:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f76:	89 10                	mov    %edx,(%eax)
		if (!pte) {
f0100f78:	83 c4 10             	add    $0x10,%esp
f0100f7b:	85 c0                	test   %eax,%eax
f0100f7d:	75 17                	jne    f0100f96 <boot_map_region+0x57>
			panic("boot_map_region failed: out of memory");
f0100f7f:	83 ec 04             	sub    $0x4,%esp
f0100f82:	68 c8 40 10 f0       	push   $0xf01040c8
f0100f87:	68 c0 01 00 00       	push   $0x1c0
f0100f8c:	68 64 3c 10 f0       	push   $0xf0103c64
f0100f91:	e8 f5 f0 ff ff       	call   f010008b <_panic>
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (int i = 0; i < size; i+= PGSIZE) {
f0100f96:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f9c:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f9f:	77 be                	ja     f0100f5f <boot_map_region+0x20>
			panic("boot_map_region failed: out of memory");
			return;
		} 
	}
	
}
f0100fa1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fa4:	5b                   	pop    %ebx
f0100fa5:	5e                   	pop    %esi
f0100fa6:	5f                   	pop    %edi
f0100fa7:	5d                   	pop    %ebp
f0100fa8:	c3                   	ret    

f0100fa9 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fa9:	55                   	push   %ebp
f0100faa:	89 e5                	mov    %esp,%ebp
f0100fac:	53                   	push   %ebx
f0100fad:	83 ec 08             	sub    $0x8,%esp
f0100fb0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//Initially not created
f0100fb3:	6a 00                	push   $0x0
f0100fb5:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb8:	ff 75 08             	pushl  0x8(%ebp)
f0100fbb:	e8 ec fe ff ff       	call   f0100eac <pgdir_walk>
	if (!(pte)) 
f0100fc0:	83 c4 10             	add    $0x10,%esp
f0100fc3:	85 c0                	test   %eax,%eax
f0100fc5:	74 32                	je     f0100ff9 <page_lookup+0x50>
	return NULL;				//page not found
	if (pte_store!=NULL)
f0100fc7:	85 db                	test   %ebx,%ebx
f0100fc9:	74 02                	je     f0100fcd <page_lookup+0x24>
		*pte_store = pte;	        //if pte_store!=0 then address of pte of page is stored
f0100fcb:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcd:	8b 00                	mov    (%eax),%eax
f0100fcf:	c1 e8 0c             	shr    $0xc,%eax
f0100fd2:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fd8:	72 14                	jb     f0100fee <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fda:	83 ec 04             	sub    $0x4,%esp
f0100fdd:	68 f0 40 10 f0       	push   $0xf01040f0
f0100fe2:	6a 4b                	push   $0x4b
f0100fe4:	68 70 3c 10 f0       	push   $0xf0103c70
f0100fe9:	e8 9d f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fee:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100ff4:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));		//page mapped at virtual address va is returned
f0100ff7:	eb 05                	jmp    f0100ffe <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//Initially not created
	if (!(pte)) 
	return NULL;				//page not found
f0100ff9:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store!=NULL)
		*pte_store = pte;	        //if pte_store!=0 then address of pte of page is stored
	return pa2page(PTE_ADDR(*pte));		//page mapped at virtual address va is returned
}
f0100ffe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101001:	c9                   	leave  
f0101002:	c3                   	ret    

f0101003 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101003:	55                   	push   %ebp
f0101004:	89 e5                	mov    %esp,%ebp
f0101006:	53                   	push   %ebx
f0101007:	83 ec 18             	sub    $0x18,%esp
f010100a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f010100d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101010:	50                   	push   %eax
f0101011:	53                   	push   %ebx
f0101012:	ff 75 08             	pushl  0x8(%ebp)
f0101015:	e8 8f ff ff ff       	call   f0100fa9 <page_lookup>
	if (!pp)       			//if (!pp || !(*pte & PTE_P)) : page doesnt exist
f010101a:	83 c4 10             	add    $0x10,%esp
f010101d:	85 c0                	test   %eax,%eax
f010101f:	74 18                	je     f0101039 <page_remove+0x36>
	{
		return ;   		// do nothing
	}
	else
	{
		page_decref(pp);  	//decrement reference count and free page table if ref count==0
f0101021:	83 ec 0c             	sub    $0xc,%esp
f0101024:	50                   	push   %eax
f0101025:	e8 5b fe ff ff       	call   f0100e85 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010102a:	0f 01 3b             	invlpg (%ebx)
		tlb_invalidate(pgdir, va);//invalidate TLB if entry removed from page table
		*pte = 0; 		  // making PTE corresponding to that va as zero
f010102d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101030:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101036:	83 c4 10             	add    $0x10,%esp
	}	 
}
f0101039:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010103c:	c9                   	leave  
f010103d:	c3                   	ret    

f010103e <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010103e:	55                   	push   %ebp
f010103f:	89 e5                	mov    %esp,%ebp
f0101041:	57                   	push   %edi
f0101042:	56                   	push   %esi
f0101043:	53                   	push   %ebx
f0101044:	83 ec 10             	sub    $0x10,%esp
f0101047:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010104a:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010104d:	6a 01                	push   $0x1
f010104f:	57                   	push   %edi
f0101050:	ff 75 08             	pushl  0x8(%ebp)
f0101053:	e8 54 fe ff ff       	call   f0100eac <pgdir_walk>
	
	
	if(pte==NULL)
f0101058:	83 c4 10             	add    $0x10,%esp
f010105b:	85 c0                	test   %eax,%eax
f010105d:	74 38                	je     f0101097 <page_insert+0x59>
f010105f:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0101061:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*pte & PTE_P)
f0101066:	f6 00 01             	testb  $0x1,(%eax)
f0101069:	74 0f                	je     f010107a <page_insert+0x3c>
		page_remove(pgdir,va);
f010106b:	83 ec 08             	sub    $0x8,%esp
f010106e:	57                   	push   %edi
f010106f:	ff 75 08             	pushl  0x8(%ebp)
f0101072:	e8 8c ff ff ff       	call   f0101003 <page_remove>
f0101077:	83 c4 10             	add    $0x10,%esp
	
	*pte = page2pa(pp) | perm | PTE_P;
f010107a:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f0101080:	c1 fb 03             	sar    $0x3,%ebx
f0101083:	c1 e3 0c             	shl    $0xc,%ebx
f0101086:	8b 45 14             	mov    0x14(%ebp),%eax
f0101089:	83 c8 01             	or     $0x1,%eax
f010108c:	09 c3                	or     %eax,%ebx
f010108e:	89 1e                	mov    %ebx,(%esi)
	//pgdir[PDX(va)] |= perm;	
	
	return 0;
f0101090:	b8 00 00 00 00       	mov    $0x0,%eax
f0101095:	eb 05                	jmp    f010109c <page_insert+0x5e>
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	
	
	if(pte==NULL)
		return -E_NO_MEM;
f0101097:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
	//pgdir[PDX(va)] |= perm;	
	
	return 0;
	
}
f010109c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010109f:	5b                   	pop    %ebx
f01010a0:	5e                   	pop    %esi
f01010a1:	5f                   	pop    %edi
f01010a2:	5d                   	pop    %ebp
f01010a3:	c3                   	ret    

f01010a4 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010a4:	55                   	push   %ebp
f01010a5:	89 e5                	mov    %esp,%ebp
f01010a7:	57                   	push   %edi
f01010a8:	56                   	push   %esi
f01010a9:	53                   	push   %ebx
f01010aa:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010ad:	b8 15 00 00 00       	mov    $0x15,%eax
f01010b2:	e8 1d f8 ff ff       	call   f01008d4 <nvram_read>
f01010b7:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010b9:	b8 17 00 00 00       	mov    $0x17,%eax
f01010be:	e8 11 f8 ff ff       	call   f01008d4 <nvram_read>
f01010c3:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010c5:	b8 34 00 00 00       	mov    $0x34,%eax
f01010ca:	e8 05 f8 ff ff       	call   f01008d4 <nvram_read>
f01010cf:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010d2:	85 c0                	test   %eax,%eax
f01010d4:	74 07                	je     f01010dd <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010d6:	05 00 40 00 00       	add    $0x4000,%eax
f01010db:	eb 0b                	jmp    f01010e8 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010dd:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010e3:	85 f6                	test   %esi,%esi
f01010e5:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010e8:	89 c2                	mov    %eax,%edx
f01010ea:	c1 ea 02             	shr    $0x2,%edx
f01010ed:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f01010f3:	89 da                	mov    %ebx,%edx
f01010f5:	c1 ea 02             	shr    $0x2,%edx
f01010f8:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010fe:	89 c2                	mov    %eax,%edx
f0101100:	29 da                	sub    %ebx,%edx
f0101102:	52                   	push   %edx
f0101103:	53                   	push   %ebx
f0101104:	50                   	push   %eax
f0101105:	68 10 41 10 f0       	push   $0xf0104110
f010110a:	e8 46 16 00 00       	call   f0102755 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010110f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101114:	e8 e4 f7 ff ff       	call   f01008fd <boot_alloc>
f0101119:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f010111e:	83 c4 0c             	add    $0xc,%esp
f0101121:	68 00 10 00 00       	push   $0x1000
f0101126:	6a 00                	push   $0x0
f0101128:	50                   	push   %eax
f0101129:	e8 6a 21 00 00       	call   f0103298 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010112e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101133:	83 c4 10             	add    $0x10,%esp
f0101136:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010113b:	77 15                	ja     f0101152 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010113d:	50                   	push   %eax
f010113e:	68 4c 41 10 f0       	push   $0xf010414c
f0101143:	68 9a 00 00 00       	push   $0x9a
f0101148:	68 64 3c 10 f0       	push   $0xf0103c64
f010114d:	e8 39 ef ff ff       	call   f010008b <_panic>
f0101152:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101158:	83 ca 05             	or     $0x5,%edx
f010115b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

        pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f0101161:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101166:	c1 e0 03             	shl    $0x3,%eax
f0101169:	e8 8f f7 ff ff       	call   f01008fd <boot_alloc>
f010116e:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
    	memset(pages, 0, sizeof(struct PageInfo) * npages);
f0101173:	83 ec 04             	sub    $0x4,%esp
f0101176:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010117c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101183:	52                   	push   %edx
f0101184:	6a 00                	push   $0x0
f0101186:	50                   	push   %eax
f0101187:	e8 0c 21 00 00       	call   f0103298 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010118c:	e8 39 fb ff ff       	call   f0100cca <page_init>

	check_page_free_list(1);
f0101191:	b8 01 00 00 00       	mov    $0x1,%eax
f0101196:	e8 6c f8 ff ff       	call   f0100a07 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010119b:	83 c4 10             	add    $0x10,%esp
f010119e:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01011a5:	75 17                	jne    f01011be <mem_init+0x11a>
		panic("'pages' is a null pointer!");
f01011a7:	83 ec 04             	sub    $0x4,%esp
f01011aa:	68 1a 3d 10 f0       	push   $0xf0103d1a
f01011af:	68 89 02 00 00       	push   $0x289
f01011b4:	68 64 3c 10 f0       	push   $0xf0103c64
f01011b9:	e8 cd ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011be:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011c3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011c8:	eb 05                	jmp    f01011cf <mem_init+0x12b>
		++nfree;
f01011ca:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011cd:	8b 00                	mov    (%eax),%eax
f01011cf:	85 c0                	test   %eax,%eax
f01011d1:	75 f7                	jne    f01011ca <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011d3:	83 ec 0c             	sub    $0xc,%esp
f01011d6:	6a 00                	push   $0x0
f01011d8:	e8 fd fb ff ff       	call   f0100dda <page_alloc>
f01011dd:	89 c7                	mov    %eax,%edi
f01011df:	83 c4 10             	add    $0x10,%esp
f01011e2:	85 c0                	test   %eax,%eax
f01011e4:	75 19                	jne    f01011ff <mem_init+0x15b>
f01011e6:	68 35 3d 10 f0       	push   $0xf0103d35
f01011eb:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01011f0:	68 91 02 00 00       	push   $0x291
f01011f5:	68 64 3c 10 f0       	push   $0xf0103c64
f01011fa:	e8 8c ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011ff:	83 ec 0c             	sub    $0xc,%esp
f0101202:	6a 00                	push   $0x0
f0101204:	e8 d1 fb ff ff       	call   f0100dda <page_alloc>
f0101209:	89 c6                	mov    %eax,%esi
f010120b:	83 c4 10             	add    $0x10,%esp
f010120e:	85 c0                	test   %eax,%eax
f0101210:	75 19                	jne    f010122b <mem_init+0x187>
f0101212:	68 4b 3d 10 f0       	push   $0xf0103d4b
f0101217:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010121c:	68 92 02 00 00       	push   $0x292
f0101221:	68 64 3c 10 f0       	push   $0xf0103c64
f0101226:	e8 60 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010122b:	83 ec 0c             	sub    $0xc,%esp
f010122e:	6a 00                	push   $0x0
f0101230:	e8 a5 fb ff ff       	call   f0100dda <page_alloc>
f0101235:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101238:	83 c4 10             	add    $0x10,%esp
f010123b:	85 c0                	test   %eax,%eax
f010123d:	75 19                	jne    f0101258 <mem_init+0x1b4>
f010123f:	68 61 3d 10 f0       	push   $0xf0103d61
f0101244:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101249:	68 93 02 00 00       	push   $0x293
f010124e:	68 64 3c 10 f0       	push   $0xf0103c64
f0101253:	e8 33 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101258:	39 f7                	cmp    %esi,%edi
f010125a:	75 19                	jne    f0101275 <mem_init+0x1d1>
f010125c:	68 77 3d 10 f0       	push   $0xf0103d77
f0101261:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101266:	68 96 02 00 00       	push   $0x296
f010126b:	68 64 3c 10 f0       	push   $0xf0103c64
f0101270:	e8 16 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101275:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101278:	39 c6                	cmp    %eax,%esi
f010127a:	74 04                	je     f0101280 <mem_init+0x1dc>
f010127c:	39 c7                	cmp    %eax,%edi
f010127e:	75 19                	jne    f0101299 <mem_init+0x1f5>
f0101280:	68 70 41 10 f0       	push   $0xf0104170
f0101285:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010128a:	68 97 02 00 00       	push   $0x297
f010128f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101294:	e8 f2 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101299:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010129f:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01012a5:	c1 e2 0c             	shl    $0xc,%edx
f01012a8:	89 f8                	mov    %edi,%eax
f01012aa:	29 c8                	sub    %ecx,%eax
f01012ac:	c1 f8 03             	sar    $0x3,%eax
f01012af:	c1 e0 0c             	shl    $0xc,%eax
f01012b2:	39 d0                	cmp    %edx,%eax
f01012b4:	72 19                	jb     f01012cf <mem_init+0x22b>
f01012b6:	68 89 3d 10 f0       	push   $0xf0103d89
f01012bb:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01012c0:	68 98 02 00 00       	push   $0x298
f01012c5:	68 64 3c 10 f0       	push   $0xf0103c64
f01012ca:	e8 bc ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012cf:	89 f0                	mov    %esi,%eax
f01012d1:	29 c8                	sub    %ecx,%eax
f01012d3:	c1 f8 03             	sar    $0x3,%eax
f01012d6:	c1 e0 0c             	shl    $0xc,%eax
f01012d9:	39 c2                	cmp    %eax,%edx
f01012db:	77 19                	ja     f01012f6 <mem_init+0x252>
f01012dd:	68 a6 3d 10 f0       	push   $0xf0103da6
f01012e2:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01012e7:	68 99 02 00 00       	push   $0x299
f01012ec:	68 64 3c 10 f0       	push   $0xf0103c64
f01012f1:	e8 95 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012f9:	29 c8                	sub    %ecx,%eax
f01012fb:	c1 f8 03             	sar    $0x3,%eax
f01012fe:	c1 e0 0c             	shl    $0xc,%eax
f0101301:	39 c2                	cmp    %eax,%edx
f0101303:	77 19                	ja     f010131e <mem_init+0x27a>
f0101305:	68 c3 3d 10 f0       	push   $0xf0103dc3
f010130a:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010130f:	68 9a 02 00 00       	push   $0x29a
f0101314:	68 64 3c 10 f0       	push   $0xf0103c64
f0101319:	e8 6d ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010131e:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101323:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101326:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010132d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101330:	83 ec 0c             	sub    $0xc,%esp
f0101333:	6a 00                	push   $0x0
f0101335:	e8 a0 fa ff ff       	call   f0100dda <page_alloc>
f010133a:	83 c4 10             	add    $0x10,%esp
f010133d:	85 c0                	test   %eax,%eax
f010133f:	74 19                	je     f010135a <mem_init+0x2b6>
f0101341:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101346:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010134b:	68 a1 02 00 00       	push   $0x2a1
f0101350:	68 64 3c 10 f0       	push   $0xf0103c64
f0101355:	e8 31 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010135a:	83 ec 0c             	sub    $0xc,%esp
f010135d:	57                   	push   %edi
f010135e:	e8 e7 fa ff ff       	call   f0100e4a <page_free>
	page_free(pp1);
f0101363:	89 34 24             	mov    %esi,(%esp)
f0101366:	e8 df fa ff ff       	call   f0100e4a <page_free>
	page_free(pp2);
f010136b:	83 c4 04             	add    $0x4,%esp
f010136e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101371:	e8 d4 fa ff ff       	call   f0100e4a <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101376:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010137d:	e8 58 fa ff ff       	call   f0100dda <page_alloc>
f0101382:	89 c6                	mov    %eax,%esi
f0101384:	83 c4 10             	add    $0x10,%esp
f0101387:	85 c0                	test   %eax,%eax
f0101389:	75 19                	jne    f01013a4 <mem_init+0x300>
f010138b:	68 35 3d 10 f0       	push   $0xf0103d35
f0101390:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101395:	68 a8 02 00 00       	push   $0x2a8
f010139a:	68 64 3c 10 f0       	push   $0xf0103c64
f010139f:	e8 e7 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013a4:	83 ec 0c             	sub    $0xc,%esp
f01013a7:	6a 00                	push   $0x0
f01013a9:	e8 2c fa ff ff       	call   f0100dda <page_alloc>
f01013ae:	89 c7                	mov    %eax,%edi
f01013b0:	83 c4 10             	add    $0x10,%esp
f01013b3:	85 c0                	test   %eax,%eax
f01013b5:	75 19                	jne    f01013d0 <mem_init+0x32c>
f01013b7:	68 4b 3d 10 f0       	push   $0xf0103d4b
f01013bc:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01013c1:	68 a9 02 00 00       	push   $0x2a9
f01013c6:	68 64 3c 10 f0       	push   $0xf0103c64
f01013cb:	e8 bb ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013d0:	83 ec 0c             	sub    $0xc,%esp
f01013d3:	6a 00                	push   $0x0
f01013d5:	e8 00 fa ff ff       	call   f0100dda <page_alloc>
f01013da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013dd:	83 c4 10             	add    $0x10,%esp
f01013e0:	85 c0                	test   %eax,%eax
f01013e2:	75 19                	jne    f01013fd <mem_init+0x359>
f01013e4:	68 61 3d 10 f0       	push   $0xf0103d61
f01013e9:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01013ee:	68 aa 02 00 00       	push   $0x2aa
f01013f3:	68 64 3c 10 f0       	push   $0xf0103c64
f01013f8:	e8 8e ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013fd:	39 fe                	cmp    %edi,%esi
f01013ff:	75 19                	jne    f010141a <mem_init+0x376>
f0101401:	68 77 3d 10 f0       	push   $0xf0103d77
f0101406:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010140b:	68 ac 02 00 00       	push   $0x2ac
f0101410:	68 64 3c 10 f0       	push   $0xf0103c64
f0101415:	e8 71 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010141a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010141d:	39 c7                	cmp    %eax,%edi
f010141f:	74 04                	je     f0101425 <mem_init+0x381>
f0101421:	39 c6                	cmp    %eax,%esi
f0101423:	75 19                	jne    f010143e <mem_init+0x39a>
f0101425:	68 70 41 10 f0       	push   $0xf0104170
f010142a:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010142f:	68 ad 02 00 00       	push   $0x2ad
f0101434:	68 64 3c 10 f0       	push   $0xf0103c64
f0101439:	e8 4d ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010143e:	83 ec 0c             	sub    $0xc,%esp
f0101441:	6a 00                	push   $0x0
f0101443:	e8 92 f9 ff ff       	call   f0100dda <page_alloc>
f0101448:	83 c4 10             	add    $0x10,%esp
f010144b:	85 c0                	test   %eax,%eax
f010144d:	74 19                	je     f0101468 <mem_init+0x3c4>
f010144f:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101454:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101459:	68 ae 02 00 00       	push   $0x2ae
f010145e:	68 64 3c 10 f0       	push   $0xf0103c64
f0101463:	e8 23 ec ff ff       	call   f010008b <_panic>
f0101468:	89 f0                	mov    %esi,%eax
f010146a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101470:	c1 f8 03             	sar    $0x3,%eax
f0101473:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101476:	89 c2                	mov    %eax,%edx
f0101478:	c1 ea 0c             	shr    $0xc,%edx
f010147b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101481:	72 12                	jb     f0101495 <mem_init+0x3f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101483:	50                   	push   %eax
f0101484:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0101489:	6a 52                	push   $0x52
f010148b:	68 70 3c 10 f0       	push   $0xf0103c70
f0101490:	e8 f6 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101495:	83 ec 04             	sub    $0x4,%esp
f0101498:	68 00 10 00 00       	push   $0x1000
f010149d:	6a 01                	push   $0x1
f010149f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014a4:	50                   	push   %eax
f01014a5:	e8 ee 1d 00 00       	call   f0103298 <memset>
	page_free(pp0);
f01014aa:	89 34 24             	mov    %esi,(%esp)
f01014ad:	e8 98 f9 ff ff       	call   f0100e4a <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014b2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014b9:	e8 1c f9 ff ff       	call   f0100dda <page_alloc>
f01014be:	83 c4 10             	add    $0x10,%esp
f01014c1:	85 c0                	test   %eax,%eax
f01014c3:	75 19                	jne    f01014de <mem_init+0x43a>
f01014c5:	68 ef 3d 10 f0       	push   $0xf0103def
f01014ca:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01014cf:	68 b3 02 00 00       	push   $0x2b3
f01014d4:	68 64 3c 10 f0       	push   $0xf0103c64
f01014d9:	e8 ad eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014de:	39 c6                	cmp    %eax,%esi
f01014e0:	74 19                	je     f01014fb <mem_init+0x457>
f01014e2:	68 0d 3e 10 f0       	push   $0xf0103e0d
f01014e7:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01014ec:	68 b4 02 00 00       	push   $0x2b4
f01014f1:	68 64 3c 10 f0       	push   $0xf0103c64
f01014f6:	e8 90 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014fb:	89 f0                	mov    %esi,%eax
f01014fd:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101503:	c1 f8 03             	sar    $0x3,%eax
f0101506:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101509:	89 c2                	mov    %eax,%edx
f010150b:	c1 ea 0c             	shr    $0xc,%edx
f010150e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101514:	72 12                	jb     f0101528 <mem_init+0x484>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101516:	50                   	push   %eax
f0101517:	68 6c 3f 10 f0       	push   $0xf0103f6c
f010151c:	6a 52                	push   $0x52
f010151e:	68 70 3c 10 f0       	push   $0xf0103c70
f0101523:	e8 63 eb ff ff       	call   f010008b <_panic>
f0101528:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010152e:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101534:	80 38 00             	cmpb   $0x0,(%eax)
f0101537:	74 19                	je     f0101552 <mem_init+0x4ae>
f0101539:	68 1d 3e 10 f0       	push   $0xf0103e1d
f010153e:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101543:	68 b7 02 00 00       	push   $0x2b7
f0101548:	68 64 3c 10 f0       	push   $0xf0103c64
f010154d:	e8 39 eb ff ff       	call   f010008b <_panic>
f0101552:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101555:	39 d0                	cmp    %edx,%eax
f0101557:	75 db                	jne    f0101534 <mem_init+0x490>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101559:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010155c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101561:	83 ec 0c             	sub    $0xc,%esp
f0101564:	56                   	push   %esi
f0101565:	e8 e0 f8 ff ff       	call   f0100e4a <page_free>
	page_free(pp1);
f010156a:	89 3c 24             	mov    %edi,(%esp)
f010156d:	e8 d8 f8 ff ff       	call   f0100e4a <page_free>
	page_free(pp2);
f0101572:	83 c4 04             	add    $0x4,%esp
f0101575:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101578:	e8 cd f8 ff ff       	call   f0100e4a <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010157d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101582:	83 c4 10             	add    $0x10,%esp
f0101585:	eb 05                	jmp    f010158c <mem_init+0x4e8>
		--nfree;
f0101587:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010158a:	8b 00                	mov    (%eax),%eax
f010158c:	85 c0                	test   %eax,%eax
f010158e:	75 f7                	jne    f0101587 <mem_init+0x4e3>
		--nfree;
	assert(nfree == 0);
f0101590:	85 db                	test   %ebx,%ebx
f0101592:	74 19                	je     f01015ad <mem_init+0x509>
f0101594:	68 27 3e 10 f0       	push   $0xf0103e27
f0101599:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010159e:	68 c4 02 00 00       	push   $0x2c4
f01015a3:	68 64 3c 10 f0       	push   $0xf0103c64
f01015a8:	e8 de ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015ad:	83 ec 0c             	sub    $0xc,%esp
f01015b0:	68 90 41 10 f0       	push   $0xf0104190
f01015b5:	e8 9b 11 00 00       	call   f0102755 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c1:	e8 14 f8 ff ff       	call   f0100dda <page_alloc>
f01015c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c9:	83 c4 10             	add    $0x10,%esp
f01015cc:	85 c0                	test   %eax,%eax
f01015ce:	75 19                	jne    f01015e9 <mem_init+0x545>
f01015d0:	68 35 3d 10 f0       	push   $0xf0103d35
f01015d5:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01015da:	68 1d 03 00 00       	push   $0x31d
f01015df:	68 64 3c 10 f0       	push   $0xf0103c64
f01015e4:	e8 a2 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015e9:	83 ec 0c             	sub    $0xc,%esp
f01015ec:	6a 00                	push   $0x0
f01015ee:	e8 e7 f7 ff ff       	call   f0100dda <page_alloc>
f01015f3:	89 c3                	mov    %eax,%ebx
f01015f5:	83 c4 10             	add    $0x10,%esp
f01015f8:	85 c0                	test   %eax,%eax
f01015fa:	75 19                	jne    f0101615 <mem_init+0x571>
f01015fc:	68 4b 3d 10 f0       	push   $0xf0103d4b
f0101601:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101606:	68 1e 03 00 00       	push   $0x31e
f010160b:	68 64 3c 10 f0       	push   $0xf0103c64
f0101610:	e8 76 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101615:	83 ec 0c             	sub    $0xc,%esp
f0101618:	6a 00                	push   $0x0
f010161a:	e8 bb f7 ff ff       	call   f0100dda <page_alloc>
f010161f:	89 c6                	mov    %eax,%esi
f0101621:	83 c4 10             	add    $0x10,%esp
f0101624:	85 c0                	test   %eax,%eax
f0101626:	75 19                	jne    f0101641 <mem_init+0x59d>
f0101628:	68 61 3d 10 f0       	push   $0xf0103d61
f010162d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101632:	68 1f 03 00 00       	push   $0x31f
f0101637:	68 64 3c 10 f0       	push   $0xf0103c64
f010163c:	e8 4a ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101641:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101644:	75 19                	jne    f010165f <mem_init+0x5bb>
f0101646:	68 77 3d 10 f0       	push   $0xf0103d77
f010164b:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101650:	68 22 03 00 00       	push   $0x322
f0101655:	68 64 3c 10 f0       	push   $0xf0103c64
f010165a:	e8 2c ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010165f:	39 c3                	cmp    %eax,%ebx
f0101661:	74 05                	je     f0101668 <mem_init+0x5c4>
f0101663:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101666:	75 19                	jne    f0101681 <mem_init+0x5dd>
f0101668:	68 70 41 10 f0       	push   $0xf0104170
f010166d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101672:	68 23 03 00 00       	push   $0x323
f0101677:	68 64 3c 10 f0       	push   $0xf0103c64
f010167c:	e8 0a ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101681:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101686:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101689:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101690:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101693:	83 ec 0c             	sub    $0xc,%esp
f0101696:	6a 00                	push   $0x0
f0101698:	e8 3d f7 ff ff       	call   f0100dda <page_alloc>
f010169d:	83 c4 10             	add    $0x10,%esp
f01016a0:	85 c0                	test   %eax,%eax
f01016a2:	74 19                	je     f01016bd <mem_init+0x619>
f01016a4:	68 e0 3d 10 f0       	push   $0xf0103de0
f01016a9:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01016ae:	68 2a 03 00 00       	push   $0x32a
f01016b3:	68 64 3c 10 f0       	push   $0xf0103c64
f01016b8:	e8 ce e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016bd:	83 ec 04             	sub    $0x4,%esp
f01016c0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016c3:	50                   	push   %eax
f01016c4:	6a 00                	push   $0x0
f01016c6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016cc:	e8 d8 f8 ff ff       	call   f0100fa9 <page_lookup>
f01016d1:	83 c4 10             	add    $0x10,%esp
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	74 19                	je     f01016f1 <mem_init+0x64d>
f01016d8:	68 b0 41 10 f0       	push   $0xf01041b0
f01016dd:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01016e2:	68 2d 03 00 00       	push   $0x32d
f01016e7:	68 64 3c 10 f0       	push   $0xf0103c64
f01016ec:	e8 9a e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016f1:	6a 02                	push   $0x2
f01016f3:	6a 00                	push   $0x0
f01016f5:	53                   	push   %ebx
f01016f6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016fc:	e8 3d f9 ff ff       	call   f010103e <page_insert>
f0101701:	83 c4 10             	add    $0x10,%esp
f0101704:	85 c0                	test   %eax,%eax
f0101706:	78 19                	js     f0101721 <mem_init+0x67d>
f0101708:	68 e8 41 10 f0       	push   $0xf01041e8
f010170d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101712:	68 30 03 00 00       	push   $0x330
f0101717:	68 64 3c 10 f0       	push   $0xf0103c64
f010171c:	e8 6a e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101721:	83 ec 0c             	sub    $0xc,%esp
f0101724:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101727:	e8 1e f7 ff ff       	call   f0100e4a <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010172c:	6a 02                	push   $0x2
f010172e:	6a 00                	push   $0x0
f0101730:	53                   	push   %ebx
f0101731:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101737:	e8 02 f9 ff ff       	call   f010103e <page_insert>
f010173c:	83 c4 20             	add    $0x20,%esp
f010173f:	85 c0                	test   %eax,%eax
f0101741:	74 19                	je     f010175c <mem_init+0x6b8>
f0101743:	68 18 42 10 f0       	push   $0xf0104218
f0101748:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010174d:	68 34 03 00 00       	push   $0x334
f0101752:	68 64 3c 10 f0       	push   $0xf0103c64
f0101757:	e8 2f e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010175c:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101762:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101767:	89 c1                	mov    %eax,%ecx
f0101769:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010176c:	8b 17                	mov    (%edi),%edx
f010176e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101774:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101777:	29 c8                	sub    %ecx,%eax
f0101779:	c1 f8 03             	sar    $0x3,%eax
f010177c:	c1 e0 0c             	shl    $0xc,%eax
f010177f:	39 c2                	cmp    %eax,%edx
f0101781:	74 19                	je     f010179c <mem_init+0x6f8>
f0101783:	68 48 42 10 f0       	push   $0xf0104248
f0101788:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010178d:	68 35 03 00 00       	push   $0x335
f0101792:	68 64 3c 10 f0       	push   $0xf0103c64
f0101797:	e8 ef e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010179c:	ba 00 00 00 00       	mov    $0x0,%edx
f01017a1:	89 f8                	mov    %edi,%eax
f01017a3:	e8 fb f1 ff ff       	call   f01009a3 <check_va2pa>
f01017a8:	89 da                	mov    %ebx,%edx
f01017aa:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017ad:	c1 fa 03             	sar    $0x3,%edx
f01017b0:	c1 e2 0c             	shl    $0xc,%edx
f01017b3:	39 d0                	cmp    %edx,%eax
f01017b5:	74 19                	je     f01017d0 <mem_init+0x72c>
f01017b7:	68 70 42 10 f0       	push   $0xf0104270
f01017bc:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01017c1:	68 36 03 00 00       	push   $0x336
f01017c6:	68 64 3c 10 f0       	push   $0xf0103c64
f01017cb:	e8 bb e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017d0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017d5:	74 19                	je     f01017f0 <mem_init+0x74c>
f01017d7:	68 32 3e 10 f0       	push   $0xf0103e32
f01017dc:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01017e1:	68 37 03 00 00       	push   $0x337
f01017e6:	68 64 3c 10 f0       	push   $0xf0103c64
f01017eb:	e8 9b e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017f3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017f8:	74 19                	je     f0101813 <mem_init+0x76f>
f01017fa:	68 43 3e 10 f0       	push   $0xf0103e43
f01017ff:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101804:	68 38 03 00 00       	push   $0x338
f0101809:	68 64 3c 10 f0       	push   $0xf0103c64
f010180e:	e8 78 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101813:	6a 02                	push   $0x2
f0101815:	68 00 10 00 00       	push   $0x1000
f010181a:	56                   	push   %esi
f010181b:	57                   	push   %edi
f010181c:	e8 1d f8 ff ff       	call   f010103e <page_insert>
f0101821:	83 c4 10             	add    $0x10,%esp
f0101824:	85 c0                	test   %eax,%eax
f0101826:	74 19                	je     f0101841 <mem_init+0x79d>
f0101828:	68 a0 42 10 f0       	push   $0xf01042a0
f010182d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101832:	68 3b 03 00 00       	push   $0x33b
f0101837:	68 64 3c 10 f0       	push   $0xf0103c64
f010183c:	e8 4a e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101841:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101846:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010184b:	e8 53 f1 ff ff       	call   f01009a3 <check_va2pa>
f0101850:	89 f2                	mov    %esi,%edx
f0101852:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101858:	c1 fa 03             	sar    $0x3,%edx
f010185b:	c1 e2 0c             	shl    $0xc,%edx
f010185e:	39 d0                	cmp    %edx,%eax
f0101860:	74 19                	je     f010187b <mem_init+0x7d7>
f0101862:	68 dc 42 10 f0       	push   $0xf01042dc
f0101867:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010186c:	68 3c 03 00 00       	push   $0x33c
f0101871:	68 64 3c 10 f0       	push   $0xf0103c64
f0101876:	e8 10 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010187b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101880:	74 19                	je     f010189b <mem_init+0x7f7>
f0101882:	68 54 3e 10 f0       	push   $0xf0103e54
f0101887:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010188c:	68 3d 03 00 00       	push   $0x33d
f0101891:	68 64 3c 10 f0       	push   $0xf0103c64
f0101896:	e8 f0 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010189b:	83 ec 0c             	sub    $0xc,%esp
f010189e:	6a 00                	push   $0x0
f01018a0:	e8 35 f5 ff ff       	call   f0100dda <page_alloc>
f01018a5:	83 c4 10             	add    $0x10,%esp
f01018a8:	85 c0                	test   %eax,%eax
f01018aa:	74 19                	je     f01018c5 <mem_init+0x821>
f01018ac:	68 e0 3d 10 f0       	push   $0xf0103de0
f01018b1:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01018b6:	68 40 03 00 00       	push   $0x340
f01018bb:	68 64 3c 10 f0       	push   $0xf0103c64
f01018c0:	e8 c6 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018c5:	6a 02                	push   $0x2
f01018c7:	68 00 10 00 00       	push   $0x1000
f01018cc:	56                   	push   %esi
f01018cd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01018d3:	e8 66 f7 ff ff       	call   f010103e <page_insert>
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	74 19                	je     f01018f8 <mem_init+0x854>
f01018df:	68 a0 42 10 f0       	push   $0xf01042a0
f01018e4:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01018e9:	68 43 03 00 00       	push   $0x343
f01018ee:	68 64 3c 10 f0       	push   $0xf0103c64
f01018f3:	e8 93 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018f8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018fd:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101902:	e8 9c f0 ff ff       	call   f01009a3 <check_va2pa>
f0101907:	89 f2                	mov    %esi,%edx
f0101909:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010190f:	c1 fa 03             	sar    $0x3,%edx
f0101912:	c1 e2 0c             	shl    $0xc,%edx
f0101915:	39 d0                	cmp    %edx,%eax
f0101917:	74 19                	je     f0101932 <mem_init+0x88e>
f0101919:	68 dc 42 10 f0       	push   $0xf01042dc
f010191e:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101923:	68 44 03 00 00       	push   $0x344
f0101928:	68 64 3c 10 f0       	push   $0xf0103c64
f010192d:	e8 59 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101932:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101937:	74 19                	je     f0101952 <mem_init+0x8ae>
f0101939:	68 54 3e 10 f0       	push   $0xf0103e54
f010193e:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101943:	68 45 03 00 00       	push   $0x345
f0101948:	68 64 3c 10 f0       	push   $0xf0103c64
f010194d:	e8 39 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101952:	83 ec 0c             	sub    $0xc,%esp
f0101955:	6a 00                	push   $0x0
f0101957:	e8 7e f4 ff ff       	call   f0100dda <page_alloc>
f010195c:	83 c4 10             	add    $0x10,%esp
f010195f:	85 c0                	test   %eax,%eax
f0101961:	74 19                	je     f010197c <mem_init+0x8d8>
f0101963:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101968:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010196d:	68 49 03 00 00       	push   $0x349
f0101972:	68 64 3c 10 f0       	push   $0xf0103c64
f0101977:	e8 0f e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010197c:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101982:	8b 02                	mov    (%edx),%eax
f0101984:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101989:	89 c1                	mov    %eax,%ecx
f010198b:	c1 e9 0c             	shr    $0xc,%ecx
f010198e:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101994:	72 15                	jb     f01019ab <mem_init+0x907>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101996:	50                   	push   %eax
f0101997:	68 6c 3f 10 f0       	push   $0xf0103f6c
f010199c:	68 4c 03 00 00       	push   $0x34c
f01019a1:	68 64 3c 10 f0       	push   $0xf0103c64
f01019a6:	e8 e0 e6 ff ff       	call   f010008b <_panic>
f01019ab:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019b3:	83 ec 04             	sub    $0x4,%esp
f01019b6:	6a 00                	push   $0x0
f01019b8:	68 00 10 00 00       	push   $0x1000
f01019bd:	52                   	push   %edx
f01019be:	e8 e9 f4 ff ff       	call   f0100eac <pgdir_walk>
f01019c3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019c6:	8d 51 04             	lea    0x4(%ecx),%edx
f01019c9:	83 c4 10             	add    $0x10,%esp
f01019cc:	39 d0                	cmp    %edx,%eax
f01019ce:	74 19                	je     f01019e9 <mem_init+0x945>
f01019d0:	68 0c 43 10 f0       	push   $0xf010430c
f01019d5:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01019da:	68 4d 03 00 00       	push   $0x34d
f01019df:	68 64 3c 10 f0       	push   $0xf0103c64
f01019e4:	e8 a2 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019e9:	6a 06                	push   $0x6
f01019eb:	68 00 10 00 00       	push   $0x1000
f01019f0:	56                   	push   %esi
f01019f1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01019f7:	e8 42 f6 ff ff       	call   f010103e <page_insert>
f01019fc:	83 c4 10             	add    $0x10,%esp
f01019ff:	85 c0                	test   %eax,%eax
f0101a01:	74 19                	je     f0101a1c <mem_init+0x978>
f0101a03:	68 4c 43 10 f0       	push   $0xf010434c
f0101a08:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101a0d:	68 50 03 00 00       	push   $0x350
f0101a12:	68 64 3c 10 f0       	push   $0xf0103c64
f0101a17:	e8 6f e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a1c:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101a22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a27:	89 f8                	mov    %edi,%eax
f0101a29:	e8 75 ef ff ff       	call   f01009a3 <check_va2pa>
f0101a2e:	89 f2                	mov    %esi,%edx
f0101a30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a36:	c1 fa 03             	sar    $0x3,%edx
f0101a39:	c1 e2 0c             	shl    $0xc,%edx
f0101a3c:	39 d0                	cmp    %edx,%eax
f0101a3e:	74 19                	je     f0101a59 <mem_init+0x9b5>
f0101a40:	68 dc 42 10 f0       	push   $0xf01042dc
f0101a45:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101a4a:	68 51 03 00 00       	push   $0x351
f0101a4f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101a54:	e8 32 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a59:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a5e:	74 19                	je     f0101a79 <mem_init+0x9d5>
f0101a60:	68 54 3e 10 f0       	push   $0xf0103e54
f0101a65:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101a6a:	68 52 03 00 00       	push   $0x352
f0101a6f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101a74:	e8 12 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a79:	83 ec 04             	sub    $0x4,%esp
f0101a7c:	6a 00                	push   $0x0
f0101a7e:	68 00 10 00 00       	push   $0x1000
f0101a83:	57                   	push   %edi
f0101a84:	e8 23 f4 ff ff       	call   f0100eac <pgdir_walk>
f0101a89:	83 c4 10             	add    $0x10,%esp
f0101a8c:	f6 00 04             	testb  $0x4,(%eax)
f0101a8f:	75 19                	jne    f0101aaa <mem_init+0xa06>
f0101a91:	68 8c 43 10 f0       	push   $0xf010438c
f0101a96:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101a9b:	68 53 03 00 00       	push   $0x353
f0101aa0:	68 64 3c 10 f0       	push   $0xf0103c64
f0101aa5:	e8 e1 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aaa:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101aaf:	f6 00 04             	testb  $0x4,(%eax)
f0101ab2:	75 19                	jne    f0101acd <mem_init+0xa29>
f0101ab4:	68 65 3e 10 f0       	push   $0xf0103e65
f0101ab9:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101abe:	68 54 03 00 00       	push   $0x354
f0101ac3:	68 64 3c 10 f0       	push   $0xf0103c64
f0101ac8:	e8 be e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101acd:	6a 02                	push   $0x2
f0101acf:	68 00 10 00 00       	push   $0x1000
f0101ad4:	56                   	push   %esi
f0101ad5:	50                   	push   %eax
f0101ad6:	e8 63 f5 ff ff       	call   f010103e <page_insert>
f0101adb:	83 c4 10             	add    $0x10,%esp
f0101ade:	85 c0                	test   %eax,%eax
f0101ae0:	74 19                	je     f0101afb <mem_init+0xa57>
f0101ae2:	68 a0 42 10 f0       	push   $0xf01042a0
f0101ae7:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101aec:	68 57 03 00 00       	push   $0x357
f0101af1:	68 64 3c 10 f0       	push   $0xf0103c64
f0101af6:	e8 90 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101afb:	83 ec 04             	sub    $0x4,%esp
f0101afe:	6a 00                	push   $0x0
f0101b00:	68 00 10 00 00       	push   $0x1000
f0101b05:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b0b:	e8 9c f3 ff ff       	call   f0100eac <pgdir_walk>
f0101b10:	83 c4 10             	add    $0x10,%esp
f0101b13:	f6 00 02             	testb  $0x2,(%eax)
f0101b16:	75 19                	jne    f0101b31 <mem_init+0xa8d>
f0101b18:	68 c0 43 10 f0       	push   $0xf01043c0
f0101b1d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101b22:	68 58 03 00 00       	push   $0x358
f0101b27:	68 64 3c 10 f0       	push   $0xf0103c64
f0101b2c:	e8 5a e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b31:	83 ec 04             	sub    $0x4,%esp
f0101b34:	6a 00                	push   $0x0
f0101b36:	68 00 10 00 00       	push   $0x1000
f0101b3b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b41:	e8 66 f3 ff ff       	call   f0100eac <pgdir_walk>
f0101b46:	83 c4 10             	add    $0x10,%esp
f0101b49:	f6 00 04             	testb  $0x4,(%eax)
f0101b4c:	74 19                	je     f0101b67 <mem_init+0xac3>
f0101b4e:	68 f4 43 10 f0       	push   $0xf01043f4
f0101b53:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101b58:	68 59 03 00 00       	push   $0x359
f0101b5d:	68 64 3c 10 f0       	push   $0xf0103c64
f0101b62:	e8 24 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b67:	6a 02                	push   $0x2
f0101b69:	68 00 00 40 00       	push   $0x400000
f0101b6e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b71:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b77:	e8 c2 f4 ff ff       	call   f010103e <page_insert>
f0101b7c:	83 c4 10             	add    $0x10,%esp
f0101b7f:	85 c0                	test   %eax,%eax
f0101b81:	78 19                	js     f0101b9c <mem_init+0xaf8>
f0101b83:	68 2c 44 10 f0       	push   $0xf010442c
f0101b88:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101b8d:	68 5c 03 00 00       	push   $0x35c
f0101b92:	68 64 3c 10 f0       	push   $0xf0103c64
f0101b97:	e8 ef e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b9c:	6a 02                	push   $0x2
f0101b9e:	68 00 10 00 00       	push   $0x1000
f0101ba3:	53                   	push   %ebx
f0101ba4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101baa:	e8 8f f4 ff ff       	call   f010103e <page_insert>
f0101baf:	83 c4 10             	add    $0x10,%esp
f0101bb2:	85 c0                	test   %eax,%eax
f0101bb4:	74 19                	je     f0101bcf <mem_init+0xb2b>
f0101bb6:	68 64 44 10 f0       	push   $0xf0104464
f0101bbb:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101bc0:	68 5f 03 00 00       	push   $0x35f
f0101bc5:	68 64 3c 10 f0       	push   $0xf0103c64
f0101bca:	e8 bc e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bcf:	83 ec 04             	sub    $0x4,%esp
f0101bd2:	6a 00                	push   $0x0
f0101bd4:	68 00 10 00 00       	push   $0x1000
f0101bd9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bdf:	e8 c8 f2 ff ff       	call   f0100eac <pgdir_walk>
f0101be4:	83 c4 10             	add    $0x10,%esp
f0101be7:	f6 00 04             	testb  $0x4,(%eax)
f0101bea:	74 19                	je     f0101c05 <mem_init+0xb61>
f0101bec:	68 f4 43 10 f0       	push   $0xf01043f4
f0101bf1:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101bf6:	68 60 03 00 00       	push   $0x360
f0101bfb:	68 64 3c 10 f0       	push   $0xf0103c64
f0101c00:	e8 86 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c05:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c0b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c10:	89 f8                	mov    %edi,%eax
f0101c12:	e8 8c ed ff ff       	call   f01009a3 <check_va2pa>
f0101c17:	89 c1                	mov    %eax,%ecx
f0101c19:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c1c:	89 d8                	mov    %ebx,%eax
f0101c1e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101c24:	c1 f8 03             	sar    $0x3,%eax
f0101c27:	c1 e0 0c             	shl    $0xc,%eax
f0101c2a:	39 c1                	cmp    %eax,%ecx
f0101c2c:	74 19                	je     f0101c47 <mem_init+0xba3>
f0101c2e:	68 a0 44 10 f0       	push   $0xf01044a0
f0101c33:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101c38:	68 63 03 00 00       	push   $0x363
f0101c3d:	68 64 3c 10 f0       	push   $0xf0103c64
f0101c42:	e8 44 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c47:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c4c:	89 f8                	mov    %edi,%eax
f0101c4e:	e8 50 ed ff ff       	call   f01009a3 <check_va2pa>
f0101c53:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c56:	74 19                	je     f0101c71 <mem_init+0xbcd>
f0101c58:	68 cc 44 10 f0       	push   $0xf01044cc
f0101c5d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101c62:	68 64 03 00 00       	push   $0x364
f0101c67:	68 64 3c 10 f0       	push   $0xf0103c64
f0101c6c:	e8 1a e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c71:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c76:	74 19                	je     f0101c91 <mem_init+0xbed>
f0101c78:	68 7b 3e 10 f0       	push   $0xf0103e7b
f0101c7d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101c82:	68 66 03 00 00       	push   $0x366
f0101c87:	68 64 3c 10 f0       	push   $0xf0103c64
f0101c8c:	e8 fa e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c91:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c96:	74 19                	je     f0101cb1 <mem_init+0xc0d>
f0101c98:	68 8c 3e 10 f0       	push   $0xf0103e8c
f0101c9d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101ca2:	68 67 03 00 00       	push   $0x367
f0101ca7:	68 64 3c 10 f0       	push   $0xf0103c64
f0101cac:	e8 da e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cb1:	83 ec 0c             	sub    $0xc,%esp
f0101cb4:	6a 00                	push   $0x0
f0101cb6:	e8 1f f1 ff ff       	call   f0100dda <page_alloc>
f0101cbb:	83 c4 10             	add    $0x10,%esp
f0101cbe:	85 c0                	test   %eax,%eax
f0101cc0:	74 04                	je     f0101cc6 <mem_init+0xc22>
f0101cc2:	39 c6                	cmp    %eax,%esi
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xc3b>
f0101cc6:	68 fc 44 10 f0       	push   $0xf01044fc
f0101ccb:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101cd0:	68 6a 03 00 00       	push   $0x36a
f0101cd5:	68 64 3c 10 f0       	push   $0xf0103c64
f0101cda:	e8 ac e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cdf:	83 ec 08             	sub    $0x8,%esp
f0101ce2:	6a 00                	push   $0x0
f0101ce4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101cea:	e8 14 f3 ff ff       	call   f0101003 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cef:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101cf5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cfa:	89 f8                	mov    %edi,%eax
f0101cfc:	e8 a2 ec ff ff       	call   f01009a3 <check_va2pa>
f0101d01:	83 c4 10             	add    $0x10,%esp
f0101d04:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d07:	74 19                	je     f0101d22 <mem_init+0xc7e>
f0101d09:	68 20 45 10 f0       	push   $0xf0104520
f0101d0e:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101d13:	68 6e 03 00 00       	push   $0x36e
f0101d18:	68 64 3c 10 f0       	push   $0xf0103c64
f0101d1d:	e8 69 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d27:	89 f8                	mov    %edi,%eax
f0101d29:	e8 75 ec ff ff       	call   f01009a3 <check_va2pa>
f0101d2e:	89 da                	mov    %ebx,%edx
f0101d30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d36:	c1 fa 03             	sar    $0x3,%edx
f0101d39:	c1 e2 0c             	shl    $0xc,%edx
f0101d3c:	39 d0                	cmp    %edx,%eax
f0101d3e:	74 19                	je     f0101d59 <mem_init+0xcb5>
f0101d40:	68 cc 44 10 f0       	push   $0xf01044cc
f0101d45:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101d4a:	68 6f 03 00 00       	push   $0x36f
f0101d4f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101d54:	e8 32 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d59:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d5e:	74 19                	je     f0101d79 <mem_init+0xcd5>
f0101d60:	68 32 3e 10 f0       	push   $0xf0103e32
f0101d65:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101d6a:	68 70 03 00 00       	push   $0x370
f0101d6f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101d74:	e8 12 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d79:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d7e:	74 19                	je     f0101d99 <mem_init+0xcf5>
f0101d80:	68 8c 3e 10 f0       	push   $0xf0103e8c
f0101d85:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101d8a:	68 71 03 00 00       	push   $0x371
f0101d8f:	68 64 3c 10 f0       	push   $0xf0103c64
f0101d94:	e8 f2 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d99:	6a 00                	push   $0x0
f0101d9b:	68 00 10 00 00       	push   $0x1000
f0101da0:	53                   	push   %ebx
f0101da1:	57                   	push   %edi
f0101da2:	e8 97 f2 ff ff       	call   f010103e <page_insert>
f0101da7:	83 c4 10             	add    $0x10,%esp
f0101daa:	85 c0                	test   %eax,%eax
f0101dac:	74 19                	je     f0101dc7 <mem_init+0xd23>
f0101dae:	68 44 45 10 f0       	push   $0xf0104544
f0101db3:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101db8:	68 74 03 00 00       	push   $0x374
f0101dbd:	68 64 3c 10 f0       	push   $0xf0103c64
f0101dc2:	e8 c4 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dc7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dcc:	75 19                	jne    f0101de7 <mem_init+0xd43>
f0101dce:	68 9d 3e 10 f0       	push   $0xf0103e9d
f0101dd3:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101dd8:	68 75 03 00 00       	push   $0x375
f0101ddd:	68 64 3c 10 f0       	push   $0xf0103c64
f0101de2:	e8 a4 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101de7:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dea:	74 19                	je     f0101e05 <mem_init+0xd61>
f0101dec:	68 a9 3e 10 f0       	push   $0xf0103ea9
f0101df1:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101df6:	68 76 03 00 00       	push   $0x376
f0101dfb:	68 64 3c 10 f0       	push   $0xf0103c64
f0101e00:	e8 86 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e05:	83 ec 08             	sub    $0x8,%esp
f0101e08:	68 00 10 00 00       	push   $0x1000
f0101e0d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101e13:	e8 eb f1 ff ff       	call   f0101003 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e18:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e23:	89 f8                	mov    %edi,%eax
f0101e25:	e8 79 eb ff ff       	call   f01009a3 <check_va2pa>
f0101e2a:	83 c4 10             	add    $0x10,%esp
f0101e2d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e30:	74 19                	je     f0101e4b <mem_init+0xda7>
f0101e32:	68 20 45 10 f0       	push   $0xf0104520
f0101e37:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101e3c:	68 7a 03 00 00       	push   $0x37a
f0101e41:	68 64 3c 10 f0       	push   $0xf0103c64
f0101e46:	e8 40 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e50:	89 f8                	mov    %edi,%eax
f0101e52:	e8 4c eb ff ff       	call   f01009a3 <check_va2pa>
f0101e57:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e5a:	74 19                	je     f0101e75 <mem_init+0xdd1>
f0101e5c:	68 7c 45 10 f0       	push   $0xf010457c
f0101e61:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101e66:	68 7b 03 00 00       	push   $0x37b
f0101e6b:	68 64 3c 10 f0       	push   $0xf0103c64
f0101e70:	e8 16 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e75:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e7a:	74 19                	je     f0101e95 <mem_init+0xdf1>
f0101e7c:	68 be 3e 10 f0       	push   $0xf0103ebe
f0101e81:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101e86:	68 7c 03 00 00       	push   $0x37c
f0101e8b:	68 64 3c 10 f0       	push   $0xf0103c64
f0101e90:	e8 f6 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e95:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e9a:	74 19                	je     f0101eb5 <mem_init+0xe11>
f0101e9c:	68 8c 3e 10 f0       	push   $0xf0103e8c
f0101ea1:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101ea6:	68 7d 03 00 00       	push   $0x37d
f0101eab:	68 64 3c 10 f0       	push   $0xf0103c64
f0101eb0:	e8 d6 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eb5:	83 ec 0c             	sub    $0xc,%esp
f0101eb8:	6a 00                	push   $0x0
f0101eba:	e8 1b ef ff ff       	call   f0100dda <page_alloc>
f0101ebf:	83 c4 10             	add    $0x10,%esp
f0101ec2:	39 c3                	cmp    %eax,%ebx
f0101ec4:	75 04                	jne    f0101eca <mem_init+0xe26>
f0101ec6:	85 c0                	test   %eax,%eax
f0101ec8:	75 19                	jne    f0101ee3 <mem_init+0xe3f>
f0101eca:	68 a4 45 10 f0       	push   $0xf01045a4
f0101ecf:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101ed4:	68 80 03 00 00       	push   $0x380
f0101ed9:	68 64 3c 10 f0       	push   $0xf0103c64
f0101ede:	e8 a8 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ee3:	83 ec 0c             	sub    $0xc,%esp
f0101ee6:	6a 00                	push   $0x0
f0101ee8:	e8 ed ee ff ff       	call   f0100dda <page_alloc>
f0101eed:	83 c4 10             	add    $0x10,%esp
f0101ef0:	85 c0                	test   %eax,%eax
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xe69>
f0101ef4:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101ef9:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101efe:	68 83 03 00 00       	push   $0x383
f0101f03:	68 64 3c 10 f0       	push   $0xf0103c64
f0101f08:	e8 7e e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f0d:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101f13:	8b 11                	mov    (%ecx),%edx
f0101f15:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f1e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f24:	c1 f8 03             	sar    $0x3,%eax
f0101f27:	c1 e0 0c             	shl    $0xc,%eax
f0101f2a:	39 c2                	cmp    %eax,%edx
f0101f2c:	74 19                	je     f0101f47 <mem_init+0xea3>
f0101f2e:	68 48 42 10 f0       	push   $0xf0104248
f0101f33:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101f38:	68 86 03 00 00       	push   $0x386
f0101f3d:	68 64 3c 10 f0       	push   $0xf0103c64
f0101f42:	e8 44 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f47:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f50:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f55:	74 19                	je     f0101f70 <mem_init+0xecc>
f0101f57:	68 43 3e 10 f0       	push   $0xf0103e43
f0101f5c:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101f61:	68 88 03 00 00       	push   $0x388
f0101f66:	68 64 3c 10 f0       	push   $0xf0103c64
f0101f6b:	e8 1b e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f70:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f73:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f79:	83 ec 0c             	sub    $0xc,%esp
f0101f7c:	50                   	push   %eax
f0101f7d:	e8 c8 ee ff ff       	call   f0100e4a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f82:	83 c4 0c             	add    $0xc,%esp
f0101f85:	6a 01                	push   $0x1
f0101f87:	68 00 10 40 00       	push   $0x401000
f0101f8c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101f92:	e8 15 ef ff ff       	call   f0100eac <pgdir_walk>
f0101f97:	89 c7                	mov    %eax,%edi
f0101f99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f9c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fa1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fa4:	8b 40 04             	mov    0x4(%eax),%eax
f0101fa7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fac:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101fb2:	89 c2                	mov    %eax,%edx
f0101fb4:	c1 ea 0c             	shr    $0xc,%edx
f0101fb7:	83 c4 10             	add    $0x10,%esp
f0101fba:	39 ca                	cmp    %ecx,%edx
f0101fbc:	72 15                	jb     f0101fd3 <mem_init+0xf2f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbe:	50                   	push   %eax
f0101fbf:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0101fc4:	68 8f 03 00 00       	push   $0x38f
f0101fc9:	68 64 3c 10 f0       	push   $0xf0103c64
f0101fce:	e8 b8 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fd3:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fd8:	39 c7                	cmp    %eax,%edi
f0101fda:	74 19                	je     f0101ff5 <mem_init+0xf51>
f0101fdc:	68 cf 3e 10 f0       	push   $0xf0103ecf
f0101fe1:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0101fe6:	68 90 03 00 00       	push   $0x390
f0101feb:	68 64 3c 10 f0       	push   $0xf0103c64
f0101ff0:	e8 96 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ff5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ff8:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102002:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102008:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
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
f010201b:	77 12                	ja     f010202f <mem_init+0xf8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010201d:	50                   	push   %eax
f010201e:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0102023:	6a 52                	push   $0x52
f0102025:	68 70 3c 10 f0       	push   $0xf0103c70
f010202a:	e8 5c e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010202f:	83 ec 04             	sub    $0x4,%esp
f0102032:	68 00 10 00 00       	push   $0x1000
f0102037:	68 ff 00 00 00       	push   $0xff
f010203c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102041:	50                   	push   %eax
f0102042:	e8 51 12 00 00       	call   f0103298 <memset>
	page_free(pp0);
f0102047:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010204a:	89 3c 24             	mov    %edi,(%esp)
f010204d:	e8 f8 ed ff ff       	call   f0100e4a <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102052:	83 c4 0c             	add    $0xc,%esp
f0102055:	6a 01                	push   $0x1
f0102057:	6a 00                	push   $0x0
f0102059:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010205f:	e8 48 ee ff ff       	call   f0100eac <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102064:	89 fa                	mov    %edi,%edx
f0102066:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010206c:	c1 fa 03             	sar    $0x3,%edx
f010206f:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102072:	89 d0                	mov    %edx,%eax
f0102074:	c1 e8 0c             	shr    $0xc,%eax
f0102077:	83 c4 10             	add    $0x10,%esp
f010207a:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102080:	72 12                	jb     f0102094 <mem_init+0xff0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102082:	52                   	push   %edx
f0102083:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0102088:	6a 52                	push   $0x52
f010208a:	68 70 3c 10 f0       	push   $0xf0103c70
f010208f:	e8 f7 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102094:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010209a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010209d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020a3:	f6 00 01             	testb  $0x1,(%eax)
f01020a6:	74 19                	je     f01020c1 <mem_init+0x101d>
f01020a8:	68 e7 3e 10 f0       	push   $0xf0103ee7
f01020ad:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01020b2:	68 9a 03 00 00       	push   $0x39a
f01020b7:	68 64 3c 10 f0       	push   $0xf0103c64
f01020bc:	e8 ca df ff ff       	call   f010008b <_panic>
f01020c1:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020c4:	39 d0                	cmp    %edx,%eax
f01020c6:	75 db                	jne    f01020a3 <mem_init+0xfff>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020c8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020dc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020df:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01020e5:	83 ec 0c             	sub    $0xc,%esp
f01020e8:	50                   	push   %eax
f01020e9:	e8 5c ed ff ff       	call   f0100e4a <page_free>
	page_free(pp1);
f01020ee:	89 1c 24             	mov    %ebx,(%esp)
f01020f1:	e8 54 ed ff ff       	call   f0100e4a <page_free>
	page_free(pp2);
f01020f6:	89 34 24             	mov    %esi,(%esp)
f01020f9:	e8 4c ed ff ff       	call   f0100e4a <page_free>

	cprintf("check_page() succeeded!\n");
f01020fe:	c7 04 24 fe 3e 10 f0 	movl   $0xf0103efe,(%esp)
f0102105:	e8 4b 06 00 00       	call   f0102755 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

       boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f010210a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210f:	83 c4 10             	add    $0x10,%esp
f0102112:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102117:	77 15                	ja     f010212e <mem_init+0x108a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102119:	50                   	push   %eax
f010211a:	68 4c 41 10 f0       	push   $0xf010414c
f010211f:	68 c2 00 00 00       	push   $0xc2
f0102124:	68 64 3c 10 f0       	push   $0xf0103c64
f0102129:	e8 5d df ff ff       	call   f010008b <_panic>
f010212e:	83 ec 08             	sub    $0x8,%esp
f0102131:	6a 05                	push   $0x5
f0102133:	05 00 00 00 10       	add    $0x10000000,%eax
f0102138:	50                   	push   %eax
f0102139:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010213e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102143:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102148:	e8 f2 ed ff ff       	call   f0100f3f <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010214d:	83 c4 10             	add    $0x10,%esp
f0102150:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102155:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010215a:	77 15                	ja     f0102171 <mem_init+0x10cd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010215c:	50                   	push   %eax
f010215d:	68 4c 41 10 f0       	push   $0xf010414c
f0102162:	68 d0 00 00 00       	push   $0xd0
f0102167:	68 64 3c 10 f0       	push   $0xf0103c64
f010216c:	e8 1a df ff ff       	call   f010008b <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

        boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102171:	83 ec 08             	sub    $0x8,%esp
f0102174:	6a 03                	push   $0x3
f0102176:	68 00 d0 10 00       	push   $0x10d000
f010217b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102180:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102185:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010218a:	e8 b0 ed ff ff       	call   f0100f3f <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

        boot_map_region(kern_pgdir, KERNBASE, 0xFFFFFFFF-KERNBASE, 0, PTE_W | PTE_P);
f010218f:	83 c4 08             	add    $0x8,%esp
f0102192:	6a 03                	push   $0x3
f0102194:	6a 00                	push   $0x0
f0102196:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021a5:	e8 95 ed ff ff       	call   f0100f3f <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021aa:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01021b5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021b8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021c7:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021cd:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021d0:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021d8:	eb 55                	jmp    f010222f <mem_init+0x118b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021da:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021e0:	89 f0                	mov    %esi,%eax
f01021e2:	e8 bc e7 ff ff       	call   f01009a3 <check_va2pa>
f01021e7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021ee:	77 15                	ja     f0102205 <mem_init+0x1161>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021f0:	57                   	push   %edi
f01021f1:	68 4c 41 10 f0       	push   $0xf010414c
f01021f6:	68 dc 02 00 00       	push   $0x2dc
f01021fb:	68 64 3c 10 f0       	push   $0xf0103c64
f0102200:	e8 86 de ff ff       	call   f010008b <_panic>
f0102205:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010220c:	39 c2                	cmp    %eax,%edx
f010220e:	74 19                	je     f0102229 <mem_init+0x1185>
f0102210:	68 c8 45 10 f0       	push   $0xf01045c8
f0102215:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010221a:	68 dc 02 00 00       	push   $0x2dc
f010221f:	68 64 3c 10 f0       	push   $0xf0103c64
f0102224:	e8 62 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102229:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010222f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102232:	77 a6                	ja     f01021da <mem_init+0x1136>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102234:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102237:	c1 e7 0c             	shl    $0xc,%edi
f010223a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010223f:	eb 30                	jmp    f0102271 <mem_init+0x11cd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102241:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102247:	89 f0                	mov    %esi,%eax
f0102249:	e8 55 e7 ff ff       	call   f01009a3 <check_va2pa>
f010224e:	39 c3                	cmp    %eax,%ebx
f0102250:	74 19                	je     f010226b <mem_init+0x11c7>
f0102252:	68 fc 45 10 f0       	push   $0xf01045fc
f0102257:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010225c:	68 e1 02 00 00       	push   $0x2e1
f0102261:	68 64 3c 10 f0       	push   $0xf0103c64
f0102266:	e8 20 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010226b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102271:	39 fb                	cmp    %edi,%ebx
f0102273:	72 cc                	jb     f0102241 <mem_init+0x119d>
f0102275:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010227a:	89 da                	mov    %ebx,%edx
f010227c:	89 f0                	mov    %esi,%eax
f010227e:	e8 20 e7 ff ff       	call   f01009a3 <check_va2pa>
f0102283:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102289:	39 c2                	cmp    %eax,%edx
f010228b:	74 19                	je     f01022a6 <mem_init+0x1202>
f010228d:	68 24 46 10 f0       	push   $0xf0104624
f0102292:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102297:	68 e5 02 00 00       	push   $0x2e5
f010229c:	68 64 3c 10 f0       	push   $0xf0103c64
f01022a1:	e8 e5 dd ff ff       	call   f010008b <_panic>
f01022a6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022ac:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022b2:	75 c6                	jne    f010227a <mem_init+0x11d6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022b4:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022b9:	89 f0                	mov    %esi,%eax
f01022bb:	e8 e3 e6 ff ff       	call   f01009a3 <check_va2pa>
f01022c0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022c3:	74 51                	je     f0102316 <mem_init+0x1272>
f01022c5:	68 6c 46 10 f0       	push   $0xf010466c
f01022ca:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01022cf:	68 e6 02 00 00       	push   $0x2e6
f01022d4:	68 64 3c 10 f0       	push   $0xf0103c64
f01022d9:	e8 ad dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022de:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022e3:	72 36                	jb     f010231b <mem_init+0x1277>
f01022e5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022ea:	76 07                	jbe    f01022f3 <mem_init+0x124f>
f01022ec:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022f1:	75 28                	jne    f010231b <mem_init+0x1277>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022f3:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022f7:	0f 85 83 00 00 00    	jne    f0102380 <mem_init+0x12dc>
f01022fd:	68 17 3f 10 f0       	push   $0xf0103f17
f0102302:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102307:	68 ee 02 00 00       	push   $0x2ee
f010230c:	68 64 3c 10 f0       	push   $0xf0103c64
f0102311:	e8 75 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102316:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010231b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102320:	76 3f                	jbe    f0102361 <mem_init+0x12bd>
				assert(pgdir[i] & PTE_P);
f0102322:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102325:	f6 c2 01             	test   $0x1,%dl
f0102328:	75 19                	jne    f0102343 <mem_init+0x129f>
f010232a:	68 17 3f 10 f0       	push   $0xf0103f17
f010232f:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102334:	68 f2 02 00 00       	push   $0x2f2
f0102339:	68 64 3c 10 f0       	push   $0xf0103c64
f010233e:	e8 48 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102343:	f6 c2 02             	test   $0x2,%dl
f0102346:	75 38                	jne    f0102380 <mem_init+0x12dc>
f0102348:	68 28 3f 10 f0       	push   $0xf0103f28
f010234d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102352:	68 f3 02 00 00       	push   $0x2f3
f0102357:	68 64 3c 10 f0       	push   $0xf0103c64
f010235c:	e8 2a dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102361:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102365:	74 19                	je     f0102380 <mem_init+0x12dc>
f0102367:	68 39 3f 10 f0       	push   $0xf0103f39
f010236c:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102371:	68 f5 02 00 00       	push   $0x2f5
f0102376:	68 64 3c 10 f0       	push   $0xf0103c64
f010237b:	e8 0b dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102380:	83 c0 01             	add    $0x1,%eax
f0102383:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102388:	0f 86 50 ff ff ff    	jbe    f01022de <mem_init+0x123a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010238e:	83 ec 0c             	sub    $0xc,%esp
f0102391:	68 9c 46 10 f0       	push   $0xf010469c
f0102396:	e8 ba 03 00 00       	call   f0102755 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010239b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023a0:	83 c4 10             	add    $0x10,%esp
f01023a3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023a8:	77 15                	ja     f01023bf <mem_init+0x131b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023aa:	50                   	push   %eax
f01023ab:	68 4c 41 10 f0       	push   $0xf010414c
f01023b0:	68 e7 00 00 00       	push   $0xe7
f01023b5:	68 64 3c 10 f0       	push   $0xf0103c64
f01023ba:	e8 cc dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023bf:	05 00 00 00 10       	add    $0x10000000,%eax
f01023c4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01023cc:	e8 36 e6 ff ff       	call   f0100a07 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023d1:	0f 20 c0             	mov    %cr0,%eax
f01023d4:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023d7:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023dc:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023df:	83 ec 0c             	sub    $0xc,%esp
f01023e2:	6a 00                	push   $0x0
f01023e4:	e8 f1 e9 ff ff       	call   f0100dda <page_alloc>
f01023e9:	89 c3                	mov    %eax,%ebx
f01023eb:	83 c4 10             	add    $0x10,%esp
f01023ee:	85 c0                	test   %eax,%eax
f01023f0:	75 19                	jne    f010240b <mem_init+0x1367>
f01023f2:	68 35 3d 10 f0       	push   $0xf0103d35
f01023f7:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01023fc:	68 b5 03 00 00       	push   $0x3b5
f0102401:	68 64 3c 10 f0       	push   $0xf0103c64
f0102406:	e8 80 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010240b:	83 ec 0c             	sub    $0xc,%esp
f010240e:	6a 00                	push   $0x0
f0102410:	e8 c5 e9 ff ff       	call   f0100dda <page_alloc>
f0102415:	89 c7                	mov    %eax,%edi
f0102417:	83 c4 10             	add    $0x10,%esp
f010241a:	85 c0                	test   %eax,%eax
f010241c:	75 19                	jne    f0102437 <mem_init+0x1393>
f010241e:	68 4b 3d 10 f0       	push   $0xf0103d4b
f0102423:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102428:	68 b6 03 00 00       	push   $0x3b6
f010242d:	68 64 3c 10 f0       	push   $0xf0103c64
f0102432:	e8 54 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102437:	83 ec 0c             	sub    $0xc,%esp
f010243a:	6a 00                	push   $0x0
f010243c:	e8 99 e9 ff ff       	call   f0100dda <page_alloc>
f0102441:	89 c6                	mov    %eax,%esi
f0102443:	83 c4 10             	add    $0x10,%esp
f0102446:	85 c0                	test   %eax,%eax
f0102448:	75 19                	jne    f0102463 <mem_init+0x13bf>
f010244a:	68 61 3d 10 f0       	push   $0xf0103d61
f010244f:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102454:	68 b7 03 00 00       	push   $0x3b7
f0102459:	68 64 3c 10 f0       	push   $0xf0103c64
f010245e:	e8 28 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102463:	83 ec 0c             	sub    $0xc,%esp
f0102466:	53                   	push   %ebx
f0102467:	e8 de e9 ff ff       	call   f0100e4a <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010246c:	89 f8                	mov    %edi,%eax
f010246e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102474:	c1 f8 03             	sar    $0x3,%eax
f0102477:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010247a:	89 c2                	mov    %eax,%edx
f010247c:	c1 ea 0c             	shr    $0xc,%edx
f010247f:	83 c4 10             	add    $0x10,%esp
f0102482:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102488:	72 12                	jb     f010249c <mem_init+0x13f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010248a:	50                   	push   %eax
f010248b:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0102490:	6a 52                	push   $0x52
f0102492:	68 70 3c 10 f0       	push   $0xf0103c70
f0102497:	e8 ef db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010249c:	83 ec 04             	sub    $0x4,%esp
f010249f:	68 00 10 00 00       	push   $0x1000
f01024a4:	6a 01                	push   $0x1
f01024a6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ab:	50                   	push   %eax
f01024ac:	e8 e7 0d 00 00       	call   f0103298 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024b1:	89 f0                	mov    %esi,%eax
f01024b3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024b9:	c1 f8 03             	sar    $0x3,%eax
f01024bc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024bf:	89 c2                	mov    %eax,%edx
f01024c1:	c1 ea 0c             	shr    $0xc,%edx
f01024c4:	83 c4 10             	add    $0x10,%esp
f01024c7:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024cd:	72 12                	jb     f01024e1 <mem_init+0x143d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024cf:	50                   	push   %eax
f01024d0:	68 6c 3f 10 f0       	push   $0xf0103f6c
f01024d5:	6a 52                	push   $0x52
f01024d7:	68 70 3c 10 f0       	push   $0xf0103c70
f01024dc:	e8 aa db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024e1:	83 ec 04             	sub    $0x4,%esp
f01024e4:	68 00 10 00 00       	push   $0x1000
f01024e9:	6a 02                	push   $0x2
f01024eb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f0:	50                   	push   %eax
f01024f1:	e8 a2 0d 00 00       	call   f0103298 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024f6:	6a 02                	push   $0x2
f01024f8:	68 00 10 00 00       	push   $0x1000
f01024fd:	57                   	push   %edi
f01024fe:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102504:	e8 35 eb ff ff       	call   f010103e <page_insert>
	assert(pp1->pp_ref == 1);
f0102509:	83 c4 20             	add    $0x20,%esp
f010250c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102511:	74 19                	je     f010252c <mem_init+0x1488>
f0102513:	68 32 3e 10 f0       	push   $0xf0103e32
f0102518:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010251d:	68 bc 03 00 00       	push   $0x3bc
f0102522:	68 64 3c 10 f0       	push   $0xf0103c64
f0102527:	e8 5f db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010252c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102533:	01 01 01 
f0102536:	74 19                	je     f0102551 <mem_init+0x14ad>
f0102538:	68 bc 46 10 f0       	push   $0xf01046bc
f010253d:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102542:	68 bd 03 00 00       	push   $0x3bd
f0102547:	68 64 3c 10 f0       	push   $0xf0103c64
f010254c:	e8 3a db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102551:	6a 02                	push   $0x2
f0102553:	68 00 10 00 00       	push   $0x1000
f0102558:	56                   	push   %esi
f0102559:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010255f:	e8 da ea ff ff       	call   f010103e <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102564:	83 c4 10             	add    $0x10,%esp
f0102567:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010256e:	02 02 02 
f0102571:	74 19                	je     f010258c <mem_init+0x14e8>
f0102573:	68 e0 46 10 f0       	push   $0xf01046e0
f0102578:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010257d:	68 bf 03 00 00       	push   $0x3bf
f0102582:	68 64 3c 10 f0       	push   $0xf0103c64
f0102587:	e8 ff da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010258c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102591:	74 19                	je     f01025ac <mem_init+0x1508>
f0102593:	68 54 3e 10 f0       	push   $0xf0103e54
f0102598:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010259d:	68 c0 03 00 00       	push   $0x3c0
f01025a2:	68 64 3c 10 f0       	push   $0xf0103c64
f01025a7:	e8 df da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025ac:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025b1:	74 19                	je     f01025cc <mem_init+0x1528>
f01025b3:	68 be 3e 10 f0       	push   $0xf0103ebe
f01025b8:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01025bd:	68 c1 03 00 00       	push   $0x3c1
f01025c2:	68 64 3c 10 f0       	push   $0xf0103c64
f01025c7:	e8 bf da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025cc:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025d3:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d6:	89 f0                	mov    %esi,%eax
f01025d8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01025de:	c1 f8 03             	sar    $0x3,%eax
f01025e1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e4:	89 c2                	mov    %eax,%edx
f01025e6:	c1 ea 0c             	shr    $0xc,%edx
f01025e9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01025ef:	72 12                	jb     f0102603 <mem_init+0x155f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f1:	50                   	push   %eax
f01025f2:	68 6c 3f 10 f0       	push   $0xf0103f6c
f01025f7:	6a 52                	push   $0x52
f01025f9:	68 70 3c 10 f0       	push   $0xf0103c70
f01025fe:	e8 88 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102603:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010260a:	03 03 03 
f010260d:	74 19                	je     f0102628 <mem_init+0x1584>
f010260f:	68 04 47 10 f0       	push   $0xf0104704
f0102614:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102619:	68 c3 03 00 00       	push   $0x3c3
f010261e:	68 64 3c 10 f0       	push   $0xf0103c64
f0102623:	e8 63 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102628:	83 ec 08             	sub    $0x8,%esp
f010262b:	68 00 10 00 00       	push   $0x1000
f0102630:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102636:	e8 c8 e9 ff ff       	call   f0101003 <page_remove>
	assert(pp2->pp_ref == 0);
f010263b:	83 c4 10             	add    $0x10,%esp
f010263e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102643:	74 19                	je     f010265e <mem_init+0x15ba>
f0102645:	68 8c 3e 10 f0       	push   $0xf0103e8c
f010264a:	68 8a 3c 10 f0       	push   $0xf0103c8a
f010264f:	68 c5 03 00 00       	push   $0x3c5
f0102654:	68 64 3c 10 f0       	push   $0xf0103c64
f0102659:	e8 2d da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010265e:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102664:	8b 11                	mov    (%ecx),%edx
f0102666:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010266c:	89 d8                	mov    %ebx,%eax
f010266e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102674:	c1 f8 03             	sar    $0x3,%eax
f0102677:	c1 e0 0c             	shl    $0xc,%eax
f010267a:	39 c2                	cmp    %eax,%edx
f010267c:	74 19                	je     f0102697 <mem_init+0x15f3>
f010267e:	68 48 42 10 f0       	push   $0xf0104248
f0102683:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0102688:	68 c8 03 00 00       	push   $0x3c8
f010268d:	68 64 3c 10 f0       	push   $0xf0103c64
f0102692:	e8 f4 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102697:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010269d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026a2:	74 19                	je     f01026bd <mem_init+0x1619>
f01026a4:	68 43 3e 10 f0       	push   $0xf0103e43
f01026a9:	68 8a 3c 10 f0       	push   $0xf0103c8a
f01026ae:	68 ca 03 00 00       	push   $0x3ca
f01026b3:	68 64 3c 10 f0       	push   $0xf0103c64
f01026b8:	e8 ce d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026bd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026c3:	83 ec 0c             	sub    $0xc,%esp
f01026c6:	53                   	push   %ebx
f01026c7:	e8 7e e7 ff ff       	call   f0100e4a <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026cc:	c7 04 24 30 47 10 f0 	movl   $0xf0104730,(%esp)
f01026d3:	e8 7d 00 00 00       	call   f0102755 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026d8:	83 c4 10             	add    $0x10,%esp
f01026db:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026de:	5b                   	pop    %ebx
f01026df:	5e                   	pop    %esi
f01026e0:	5f                   	pop    %edi
f01026e1:	5d                   	pop    %ebp
f01026e2:	c3                   	ret    

f01026e3 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026e3:	55                   	push   %ebp
f01026e4:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026e9:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026ec:	5d                   	pop    %ebp
f01026ed:	c3                   	ret    

f01026ee <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026ee:	55                   	push   %ebp
f01026ef:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026f1:	ba 70 00 00 00       	mov    $0x70,%edx
f01026f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01026f9:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026fa:	ba 71 00 00 00       	mov    $0x71,%edx
f01026ff:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102700:	0f b6 c0             	movzbl %al,%eax
}
f0102703:	5d                   	pop    %ebp
f0102704:	c3                   	ret    

f0102705 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102705:	55                   	push   %ebp
f0102706:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102708:	ba 70 00 00 00       	mov    $0x70,%edx
f010270d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102710:	ee                   	out    %al,(%dx)
f0102711:	ba 71 00 00 00       	mov    $0x71,%edx
f0102716:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102719:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010271a:	5d                   	pop    %ebp
f010271b:	c3                   	ret    

f010271c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010271c:	55                   	push   %ebp
f010271d:	89 e5                	mov    %esp,%ebp
f010271f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102722:	ff 75 08             	pushl  0x8(%ebp)
f0102725:	e8 d6 de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010272a:	83 c4 10             	add    $0x10,%esp
f010272d:	c9                   	leave  
f010272e:	c3                   	ret    

f010272f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010272f:	55                   	push   %ebp
f0102730:	89 e5                	mov    %esp,%ebp
f0102732:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102735:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010273c:	ff 75 0c             	pushl  0xc(%ebp)
f010273f:	ff 75 08             	pushl  0x8(%ebp)
f0102742:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102745:	50                   	push   %eax
f0102746:	68 1c 27 10 f0       	push   $0xf010271c
f010274b:	e8 23 04 00 00       	call   f0102b73 <vprintfmt>
	return cnt;
}
f0102750:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102753:	c9                   	leave  
f0102754:	c3                   	ret    

f0102755 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102755:	55                   	push   %ebp
f0102756:	89 e5                	mov    %esp,%ebp
f0102758:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010275b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010275e:	50                   	push   %eax
f010275f:	ff 75 08             	pushl  0x8(%ebp)
f0102762:	e8 c8 ff ff ff       	call   f010272f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102767:	c9                   	leave  
f0102768:	c3                   	ret    

f0102769 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102769:	55                   	push   %ebp
f010276a:	89 e5                	mov    %esp,%ebp
f010276c:	57                   	push   %edi
f010276d:	56                   	push   %esi
f010276e:	53                   	push   %ebx
f010276f:	83 ec 14             	sub    $0x14,%esp
f0102772:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102775:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102778:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010277b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010277e:	8b 1a                	mov    (%edx),%ebx
f0102780:	8b 01                	mov    (%ecx),%eax
f0102782:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102785:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010278c:	eb 7f                	jmp    f010280d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010278e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102791:	01 d8                	add    %ebx,%eax
f0102793:	89 c6                	mov    %eax,%esi
f0102795:	c1 ee 1f             	shr    $0x1f,%esi
f0102798:	01 c6                	add    %eax,%esi
f010279a:	d1 fe                	sar    %esi
f010279c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010279f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027a2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027a5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027a7:	eb 03                	jmp    f01027ac <stab_binsearch+0x43>
			m--;
f01027a9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027ac:	39 c3                	cmp    %eax,%ebx
f01027ae:	7f 0d                	jg     f01027bd <stab_binsearch+0x54>
f01027b0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027b4:	83 ea 0c             	sub    $0xc,%edx
f01027b7:	39 f9                	cmp    %edi,%ecx
f01027b9:	75 ee                	jne    f01027a9 <stab_binsearch+0x40>
f01027bb:	eb 05                	jmp    f01027c2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027bd:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027c0:	eb 4b                	jmp    f010280d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027c2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027c5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027c8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027cc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027cf:	76 11                	jbe    f01027e2 <stab_binsearch+0x79>
			*region_left = m;
f01027d1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027d4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027d6:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027d9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027e0:	eb 2b                	jmp    f010280d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027e2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027e5:	73 14                	jae    f01027fb <stab_binsearch+0x92>
			*region_right = m - 1;
f01027e7:	83 e8 01             	sub    $0x1,%eax
f01027ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027f0:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027f2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027f9:	eb 12                	jmp    f010280d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027fe:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102800:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102804:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102806:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010280d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102810:	0f 8e 78 ff ff ff    	jle    f010278e <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102816:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010281a:	75 0f                	jne    f010282b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010281c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010281f:	8b 00                	mov    (%eax),%eax
f0102821:	83 e8 01             	sub    $0x1,%eax
f0102824:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102827:	89 06                	mov    %eax,(%esi)
f0102829:	eb 2c                	jmp    f0102857 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010282b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010282e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102830:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102833:	8b 0e                	mov    (%esi),%ecx
f0102835:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102838:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010283b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010283e:	eb 03                	jmp    f0102843 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102840:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102843:	39 c8                	cmp    %ecx,%eax
f0102845:	7e 0b                	jle    f0102852 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102847:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010284b:	83 ea 0c             	sub    $0xc,%edx
f010284e:	39 df                	cmp    %ebx,%edi
f0102850:	75 ee                	jne    f0102840 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102852:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102855:	89 06                	mov    %eax,(%esi)
	}
}
f0102857:	83 c4 14             	add    $0x14,%esp
f010285a:	5b                   	pop    %ebx
f010285b:	5e                   	pop    %esi
f010285c:	5f                   	pop    %edi
f010285d:	5d                   	pop    %ebp
f010285e:	c3                   	ret    

f010285f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010285f:	55                   	push   %ebp
f0102860:	89 e5                	mov    %esp,%ebp
f0102862:	57                   	push   %edi
f0102863:	56                   	push   %esi
f0102864:	53                   	push   %ebx
f0102865:	83 ec 3c             	sub    $0x3c,%esp
f0102868:	8b 75 08             	mov    0x8(%ebp),%esi
f010286b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010286e:	c7 03 5c 47 10 f0    	movl   $0xf010475c,(%ebx)
	info->eip_line = 0;
f0102874:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010287b:	c7 43 08 5c 47 10 f0 	movl   $0xf010475c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102882:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102889:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010288c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102893:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102899:	76 11                	jbe    f01028ac <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010289b:	b8 14 c1 10 f0       	mov    $0xf010c114,%eax
f01028a0:	3d 85 a3 10 f0       	cmp    $0xf010a385,%eax
f01028a5:	77 19                	ja     f01028c0 <debuginfo_eip+0x61>
f01028a7:	e9 b5 01 00 00       	jmp    f0102a61 <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028ac:	83 ec 04             	sub    $0x4,%esp
f01028af:	68 66 47 10 f0       	push   $0xf0104766
f01028b4:	6a 7f                	push   $0x7f
f01028b6:	68 73 47 10 f0       	push   $0xf0104773
f01028bb:	e8 cb d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028c0:	80 3d 13 c1 10 f0 00 	cmpb   $0x0,0xf010c113
f01028c7:	0f 85 9b 01 00 00    	jne    f0102a68 <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028cd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028d4:	b8 84 a3 10 f0       	mov    $0xf010a384,%eax
f01028d9:	2d 90 49 10 f0       	sub    $0xf0104990,%eax
f01028de:	c1 f8 02             	sar    $0x2,%eax
f01028e1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028e7:	83 e8 01             	sub    $0x1,%eax
f01028ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028ed:	83 ec 08             	sub    $0x8,%esp
f01028f0:	56                   	push   %esi
f01028f1:	6a 64                	push   $0x64
f01028f3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028f6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028f9:	b8 90 49 10 f0       	mov    $0xf0104990,%eax
f01028fe:	e8 66 fe ff ff       	call   f0102769 <stab_binsearch>
	if (lfile == 0)
f0102903:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102906:	83 c4 10             	add    $0x10,%esp
f0102909:	85 c0                	test   %eax,%eax
f010290b:	0f 84 5e 01 00 00    	je     f0102a6f <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102911:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102914:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102917:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010291a:	83 ec 08             	sub    $0x8,%esp
f010291d:	56                   	push   %esi
f010291e:	6a 24                	push   $0x24
f0102920:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102923:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102926:	b8 90 49 10 f0       	mov    $0xf0104990,%eax
f010292b:	e8 39 fe ff ff       	call   f0102769 <stab_binsearch>

	if (lfun <= rfun) {
f0102930:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102933:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102936:	83 c4 10             	add    $0x10,%esp
f0102939:	39 d0                	cmp    %edx,%eax
f010293b:	7f 40                	jg     f010297d <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010293d:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102940:	c1 e1 02             	shl    $0x2,%ecx
f0102943:	8d b9 90 49 10 f0    	lea    -0xfefb670(%ecx),%edi
f0102949:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010294c:	8b b9 90 49 10 f0    	mov    -0xfefb670(%ecx),%edi
f0102952:	b9 14 c1 10 f0       	mov    $0xf010c114,%ecx
f0102957:	81 e9 85 a3 10 f0    	sub    $0xf010a385,%ecx
f010295d:	39 cf                	cmp    %ecx,%edi
f010295f:	73 09                	jae    f010296a <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102961:	81 c7 85 a3 10 f0    	add    $0xf010a385,%edi
f0102967:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010296a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010296d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102970:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102973:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102975:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102978:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010297b:	eb 0f                	jmp    f010298c <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010297d:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102980:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102983:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102986:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102989:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010298c:	83 ec 08             	sub    $0x8,%esp
f010298f:	6a 3a                	push   $0x3a
f0102991:	ff 73 08             	pushl  0x8(%ebx)
f0102994:	e8 e3 08 00 00       	call   f010327c <strfind>
f0102999:	2b 43 08             	sub    0x8(%ebx),%eax
f010299c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010299f:	83 c4 08             	add    $0x8,%esp
f01029a2:	56                   	push   %esi
f01029a3:	6a 44                	push   $0x44
f01029a5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029a8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029ab:	b8 90 49 10 f0       	mov    $0xf0104990,%eax
f01029b0:	e8 b4 fd ff ff       	call   f0102769 <stab_binsearch>
        if(lline > rline)
f01029b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029b8:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01029bb:	83 c4 10             	add    $0x10,%esp
f01029be:	39 d0                	cmp    %edx,%eax
f01029c0:	0f 8f b0 00 00 00    	jg     f0102a76 <debuginfo_eip+0x217>
        return -1;
	info->eip_line = stabs[rline].n_desc;
f01029c6:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029c9:	0f b7 14 95 96 49 10 	movzwl -0xfefb66a(,%edx,4),%edx
f01029d0:	f0 
f01029d1:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029d7:	89 c2                	mov    %eax,%edx
f01029d9:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01029dc:	8d 04 85 90 49 10 f0 	lea    -0xfefb670(,%eax,4),%eax
f01029e3:	eb 06                	jmp    f01029eb <debuginfo_eip+0x18c>
f01029e5:	83 ea 01             	sub    $0x1,%edx
f01029e8:	83 e8 0c             	sub    $0xc,%eax
f01029eb:	39 d7                	cmp    %edx,%edi
f01029ed:	7f 34                	jg     f0102a23 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f01029ef:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029f3:	80 f9 84             	cmp    $0x84,%cl
f01029f6:	74 0b                	je     f0102a03 <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029f8:	80 f9 64             	cmp    $0x64,%cl
f01029fb:	75 e8                	jne    f01029e5 <debuginfo_eip+0x186>
f01029fd:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a01:	74 e2                	je     f01029e5 <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a03:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a06:	8b 14 85 90 49 10 f0 	mov    -0xfefb670(,%eax,4),%edx
f0102a0d:	b8 14 c1 10 f0       	mov    $0xf010c114,%eax
f0102a12:	2d 85 a3 10 f0       	sub    $0xf010a385,%eax
f0102a17:	39 c2                	cmp    %eax,%edx
f0102a19:	73 08                	jae    f0102a23 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a1b:	81 c2 85 a3 10 f0    	add    $0xf010a385,%edx
f0102a21:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a23:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a26:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a29:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a2e:	39 f2                	cmp    %esi,%edx
f0102a30:	7d 50                	jge    f0102a82 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0102a32:	83 c2 01             	add    $0x1,%edx
f0102a35:	89 d0                	mov    %edx,%eax
f0102a37:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a3a:	8d 14 95 90 49 10 f0 	lea    -0xfefb670(,%edx,4),%edx
f0102a41:	eb 04                	jmp    f0102a47 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a43:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a47:	39 c6                	cmp    %eax,%esi
f0102a49:	7e 32                	jle    f0102a7d <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a4b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a4f:	83 c0 01             	add    $0x1,%eax
f0102a52:	83 c2 0c             	add    $0xc,%edx
f0102a55:	80 f9 a0             	cmp    $0xa0,%cl
f0102a58:	74 e9                	je     f0102a43 <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5f:	eb 21                	jmp    f0102a82 <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a66:	eb 1a                	jmp    f0102a82 <debuginfo_eip+0x223>
f0102a68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a6d:	eb 13                	jmp    f0102a82 <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a74:	eb 0c                	jmp    f0102a82 <debuginfo_eip+0x223>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
        if(lline > rline)
        return -1;
f0102a76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a7b:	eb 05                	jmp    f0102a82 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a82:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a85:	5b                   	pop    %ebx
f0102a86:	5e                   	pop    %esi
f0102a87:	5f                   	pop    %edi
f0102a88:	5d                   	pop    %ebp
f0102a89:	c3                   	ret    

f0102a8a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a8a:	55                   	push   %ebp
f0102a8b:	89 e5                	mov    %esp,%ebp
f0102a8d:	57                   	push   %edi
f0102a8e:	56                   	push   %esi
f0102a8f:	53                   	push   %ebx
f0102a90:	83 ec 1c             	sub    $0x1c,%esp
f0102a93:	89 c7                	mov    %eax,%edi
f0102a95:	89 d6                	mov    %edx,%esi
f0102a97:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a9a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102aa0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102aa3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102aa6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102aab:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102aae:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ab1:	39 d3                	cmp    %edx,%ebx
f0102ab3:	72 05                	jb     f0102aba <printnum+0x30>
f0102ab5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102ab8:	77 45                	ja     f0102aff <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102aba:	83 ec 0c             	sub    $0xc,%esp
f0102abd:	ff 75 18             	pushl  0x18(%ebp)
f0102ac0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ac3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102ac6:	53                   	push   %ebx
f0102ac7:	ff 75 10             	pushl  0x10(%ebp)
f0102aca:	83 ec 08             	sub    $0x8,%esp
f0102acd:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ad0:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ad3:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ad6:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ad9:	e8 c2 09 00 00       	call   f01034a0 <__udivdi3>
f0102ade:	83 c4 18             	add    $0x18,%esp
f0102ae1:	52                   	push   %edx
f0102ae2:	50                   	push   %eax
f0102ae3:	89 f2                	mov    %esi,%edx
f0102ae5:	89 f8                	mov    %edi,%eax
f0102ae7:	e8 9e ff ff ff       	call   f0102a8a <printnum>
f0102aec:	83 c4 20             	add    $0x20,%esp
f0102aef:	eb 18                	jmp    f0102b09 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102af1:	83 ec 08             	sub    $0x8,%esp
f0102af4:	56                   	push   %esi
f0102af5:	ff 75 18             	pushl  0x18(%ebp)
f0102af8:	ff d7                	call   *%edi
f0102afa:	83 c4 10             	add    $0x10,%esp
f0102afd:	eb 03                	jmp    f0102b02 <printnum+0x78>
f0102aff:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b02:	83 eb 01             	sub    $0x1,%ebx
f0102b05:	85 db                	test   %ebx,%ebx
f0102b07:	7f e8                	jg     f0102af1 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b09:	83 ec 08             	sub    $0x8,%esp
f0102b0c:	56                   	push   %esi
f0102b0d:	83 ec 04             	sub    $0x4,%esp
f0102b10:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b13:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b16:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b19:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b1c:	e8 af 0a 00 00       	call   f01035d0 <__umoddi3>
f0102b21:	83 c4 14             	add    $0x14,%esp
f0102b24:	0f be 80 81 47 10 f0 	movsbl -0xfefb87f(%eax),%eax
f0102b2b:	50                   	push   %eax
f0102b2c:	ff d7                	call   *%edi
}
f0102b2e:	83 c4 10             	add    $0x10,%esp
f0102b31:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b34:	5b                   	pop    %ebx
f0102b35:	5e                   	pop    %esi
f0102b36:	5f                   	pop    %edi
f0102b37:	5d                   	pop    %ebp
f0102b38:	c3                   	ret    

f0102b39 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b39:	55                   	push   %ebp
f0102b3a:	89 e5                	mov    %esp,%ebp
f0102b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b3f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b43:	8b 10                	mov    (%eax),%edx
f0102b45:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b48:	73 0a                	jae    f0102b54 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b4a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b4d:	89 08                	mov    %ecx,(%eax)
f0102b4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b52:	88 02                	mov    %al,(%edx)
}
f0102b54:	5d                   	pop    %ebp
f0102b55:	c3                   	ret    

f0102b56 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b56:	55                   	push   %ebp
f0102b57:	89 e5                	mov    %esp,%ebp
f0102b59:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b5c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b5f:	50                   	push   %eax
f0102b60:	ff 75 10             	pushl  0x10(%ebp)
f0102b63:	ff 75 0c             	pushl  0xc(%ebp)
f0102b66:	ff 75 08             	pushl  0x8(%ebp)
f0102b69:	e8 05 00 00 00       	call   f0102b73 <vprintfmt>
	va_end(ap);
}
f0102b6e:	83 c4 10             	add    $0x10,%esp
f0102b71:	c9                   	leave  
f0102b72:	c3                   	ret    

f0102b73 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b73:	55                   	push   %ebp
f0102b74:	89 e5                	mov    %esp,%ebp
f0102b76:	57                   	push   %edi
f0102b77:	56                   	push   %esi
f0102b78:	53                   	push   %ebx
f0102b79:	83 ec 2c             	sub    $0x2c,%esp
f0102b7c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b7f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b82:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b85:	eb 12                	jmp    f0102b99 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b87:	85 c0                	test   %eax,%eax
f0102b89:	0f 84 42 04 00 00    	je     f0102fd1 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102b8f:	83 ec 08             	sub    $0x8,%esp
f0102b92:	53                   	push   %ebx
f0102b93:	50                   	push   %eax
f0102b94:	ff d6                	call   *%esi
f0102b96:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b99:	83 c7 01             	add    $0x1,%edi
f0102b9c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ba0:	83 f8 25             	cmp    $0x25,%eax
f0102ba3:	75 e2                	jne    f0102b87 <vprintfmt+0x14>
f0102ba5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102ba9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bb0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bb7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bbe:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bc3:	eb 07                	jmp    f0102bcc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bc8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bcc:	8d 47 01             	lea    0x1(%edi),%eax
f0102bcf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bd2:	0f b6 07             	movzbl (%edi),%eax
f0102bd5:	0f b6 d0             	movzbl %al,%edx
f0102bd8:	83 e8 23             	sub    $0x23,%eax
f0102bdb:	3c 55                	cmp    $0x55,%al
f0102bdd:	0f 87 d3 03 00 00    	ja     f0102fb6 <vprintfmt+0x443>
f0102be3:	0f b6 c0             	movzbl %al,%eax
f0102be6:	ff 24 85 0c 48 10 f0 	jmp    *-0xfefb7f4(,%eax,4)
f0102bed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bf0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bf4:	eb d6                	jmp    f0102bcc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bf9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bfe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c01:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c04:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102c08:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102c0b:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102c0e:	83 f9 09             	cmp    $0x9,%ecx
f0102c11:	77 3f                	ja     f0102c52 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c13:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c16:	eb e9                	jmp    f0102c01 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c1b:	8b 00                	mov    (%eax),%eax
f0102c1d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c20:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c23:	8d 40 04             	lea    0x4(%eax),%eax
f0102c26:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c2c:	eb 2a                	jmp    f0102c58 <vprintfmt+0xe5>
f0102c2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c31:	85 c0                	test   %eax,%eax
f0102c33:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c38:	0f 49 d0             	cmovns %eax,%edx
f0102c3b:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c41:	eb 89                	jmp    f0102bcc <vprintfmt+0x59>
f0102c43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c46:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c4d:	e9 7a ff ff ff       	jmp    f0102bcc <vprintfmt+0x59>
f0102c52:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c55:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c58:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c5c:	0f 89 6a ff ff ff    	jns    f0102bcc <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c62:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c65:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c68:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c6f:	e9 58 ff ff ff       	jmp    f0102bcc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c74:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c7a:	e9 4d ff ff ff       	jmp    f0102bcc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c82:	8d 78 04             	lea    0x4(%eax),%edi
f0102c85:	83 ec 08             	sub    $0x8,%esp
f0102c88:	53                   	push   %ebx
f0102c89:	ff 30                	pushl  (%eax)
f0102c8b:	ff d6                	call   *%esi
			break;
f0102c8d:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c90:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c96:	e9 fe fe ff ff       	jmp    f0102b99 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c9e:	8d 78 04             	lea    0x4(%eax),%edi
f0102ca1:	8b 00                	mov    (%eax),%eax
f0102ca3:	99                   	cltd   
f0102ca4:	31 d0                	xor    %edx,%eax
f0102ca6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ca8:	83 f8 06             	cmp    $0x6,%eax
f0102cab:	7f 0b                	jg     f0102cb8 <vprintfmt+0x145>
f0102cad:	8b 14 85 64 49 10 f0 	mov    -0xfefb69c(,%eax,4),%edx
f0102cb4:	85 d2                	test   %edx,%edx
f0102cb6:	75 1b                	jne    f0102cd3 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102cb8:	50                   	push   %eax
f0102cb9:	68 99 47 10 f0       	push   $0xf0104799
f0102cbe:	53                   	push   %ebx
f0102cbf:	56                   	push   %esi
f0102cc0:	e8 91 fe ff ff       	call   f0102b56 <printfmt>
f0102cc5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cc8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ccb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102cce:	e9 c6 fe ff ff       	jmp    f0102b99 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cd3:	52                   	push   %edx
f0102cd4:	68 9c 3c 10 f0       	push   $0xf0103c9c
f0102cd9:	53                   	push   %ebx
f0102cda:	56                   	push   %esi
f0102cdb:	e8 76 fe ff ff       	call   f0102b56 <printfmt>
f0102ce0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ce3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ce6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ce9:	e9 ab fe ff ff       	jmp    f0102b99 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf1:	83 c0 04             	add    $0x4,%eax
f0102cf4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102cf7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cfa:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cfc:	85 ff                	test   %edi,%edi
f0102cfe:	b8 92 47 10 f0       	mov    $0xf0104792,%eax
f0102d03:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d06:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d0a:	0f 8e 94 00 00 00    	jle    f0102da4 <vprintfmt+0x231>
f0102d10:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d14:	0f 84 98 00 00 00    	je     f0102db2 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d1a:	83 ec 08             	sub    $0x8,%esp
f0102d1d:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d20:	57                   	push   %edi
f0102d21:	e8 0c 04 00 00       	call   f0103132 <strnlen>
f0102d26:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d29:	29 c1                	sub    %eax,%ecx
f0102d2b:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d2e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d31:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d35:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d38:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d3b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d3d:	eb 0f                	jmp    f0102d4e <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d3f:	83 ec 08             	sub    $0x8,%esp
f0102d42:	53                   	push   %ebx
f0102d43:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d46:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d48:	83 ef 01             	sub    $0x1,%edi
f0102d4b:	83 c4 10             	add    $0x10,%esp
f0102d4e:	85 ff                	test   %edi,%edi
f0102d50:	7f ed                	jg     f0102d3f <vprintfmt+0x1cc>
f0102d52:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d55:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d58:	85 c9                	test   %ecx,%ecx
f0102d5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d5f:	0f 49 c1             	cmovns %ecx,%eax
f0102d62:	29 c1                	sub    %eax,%ecx
f0102d64:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d67:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d6a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d6d:	89 cb                	mov    %ecx,%ebx
f0102d6f:	eb 4d                	jmp    f0102dbe <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d71:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d75:	74 1b                	je     f0102d92 <vprintfmt+0x21f>
f0102d77:	0f be c0             	movsbl %al,%eax
f0102d7a:	83 e8 20             	sub    $0x20,%eax
f0102d7d:	83 f8 5e             	cmp    $0x5e,%eax
f0102d80:	76 10                	jbe    f0102d92 <vprintfmt+0x21f>
					putch('?', putdat);
f0102d82:	83 ec 08             	sub    $0x8,%esp
f0102d85:	ff 75 0c             	pushl  0xc(%ebp)
f0102d88:	6a 3f                	push   $0x3f
f0102d8a:	ff 55 08             	call   *0x8(%ebp)
f0102d8d:	83 c4 10             	add    $0x10,%esp
f0102d90:	eb 0d                	jmp    f0102d9f <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d92:	83 ec 08             	sub    $0x8,%esp
f0102d95:	ff 75 0c             	pushl  0xc(%ebp)
f0102d98:	52                   	push   %edx
f0102d99:	ff 55 08             	call   *0x8(%ebp)
f0102d9c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d9f:	83 eb 01             	sub    $0x1,%ebx
f0102da2:	eb 1a                	jmp    f0102dbe <vprintfmt+0x24b>
f0102da4:	89 75 08             	mov    %esi,0x8(%ebp)
f0102da7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102daa:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dad:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102db0:	eb 0c                	jmp    f0102dbe <vprintfmt+0x24b>
f0102db2:	89 75 08             	mov    %esi,0x8(%ebp)
f0102db5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102db8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dbb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102dbe:	83 c7 01             	add    $0x1,%edi
f0102dc1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102dc5:	0f be d0             	movsbl %al,%edx
f0102dc8:	85 d2                	test   %edx,%edx
f0102dca:	74 23                	je     f0102def <vprintfmt+0x27c>
f0102dcc:	85 f6                	test   %esi,%esi
f0102dce:	78 a1                	js     f0102d71 <vprintfmt+0x1fe>
f0102dd0:	83 ee 01             	sub    $0x1,%esi
f0102dd3:	79 9c                	jns    f0102d71 <vprintfmt+0x1fe>
f0102dd5:	89 df                	mov    %ebx,%edi
f0102dd7:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dda:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ddd:	eb 18                	jmp    f0102df7 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102ddf:	83 ec 08             	sub    $0x8,%esp
f0102de2:	53                   	push   %ebx
f0102de3:	6a 20                	push   $0x20
f0102de5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102de7:	83 ef 01             	sub    $0x1,%edi
f0102dea:	83 c4 10             	add    $0x10,%esp
f0102ded:	eb 08                	jmp    f0102df7 <vprintfmt+0x284>
f0102def:	89 df                	mov    %ebx,%edi
f0102df1:	8b 75 08             	mov    0x8(%ebp),%esi
f0102df4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102df7:	85 ff                	test   %edi,%edi
f0102df9:	7f e4                	jg     f0102ddf <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dfb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102dfe:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e04:	e9 90 fd ff ff       	jmp    f0102b99 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e09:	83 f9 01             	cmp    $0x1,%ecx
f0102e0c:	7e 19                	jle    f0102e27 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102e0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e11:	8b 50 04             	mov    0x4(%eax),%edx
f0102e14:	8b 00                	mov    (%eax),%eax
f0102e16:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e19:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1f:	8d 40 08             	lea    0x8(%eax),%eax
f0102e22:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e25:	eb 38                	jmp    f0102e5f <vprintfmt+0x2ec>
	else if (lflag)
f0102e27:	85 c9                	test   %ecx,%ecx
f0102e29:	74 1b                	je     f0102e46 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e2e:	8b 00                	mov    (%eax),%eax
f0102e30:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e33:	89 c1                	mov    %eax,%ecx
f0102e35:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e38:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e3e:	8d 40 04             	lea    0x4(%eax),%eax
f0102e41:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e44:	eb 19                	jmp    f0102e5f <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e46:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e49:	8b 00                	mov    (%eax),%eax
f0102e4b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e4e:	89 c1                	mov    %eax,%ecx
f0102e50:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e53:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e56:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e59:	8d 40 04             	lea    0x4(%eax),%eax
f0102e5c:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e5f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e62:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e65:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e6a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e6e:	0f 89 0e 01 00 00    	jns    f0102f82 <vprintfmt+0x40f>
				putch('-', putdat);
f0102e74:	83 ec 08             	sub    $0x8,%esp
f0102e77:	53                   	push   %ebx
f0102e78:	6a 2d                	push   $0x2d
f0102e7a:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e7c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e7f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e82:	f7 da                	neg    %edx
f0102e84:	83 d1 00             	adc    $0x0,%ecx
f0102e87:	f7 d9                	neg    %ecx
f0102e89:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e8c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e91:	e9 ec 00 00 00       	jmp    f0102f82 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e96:	83 f9 01             	cmp    $0x1,%ecx
f0102e99:	7e 18                	jle    f0102eb3 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e9e:	8b 10                	mov    (%eax),%edx
f0102ea0:	8b 48 04             	mov    0x4(%eax),%ecx
f0102ea3:	8d 40 08             	lea    0x8(%eax),%eax
f0102ea6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ea9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102eae:	e9 cf 00 00 00       	jmp    f0102f82 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102eb3:	85 c9                	test   %ecx,%ecx
f0102eb5:	74 1a                	je     f0102ed1 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eba:	8b 10                	mov    (%eax),%edx
f0102ebc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ec1:	8d 40 04             	lea    0x4(%eax),%eax
f0102ec4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ec7:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ecc:	e9 b1 00 00 00       	jmp    f0102f82 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102ed1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ed4:	8b 10                	mov    (%eax),%edx
f0102ed6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102edb:	8d 40 04             	lea    0x4(%eax),%eax
f0102ede:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ee1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ee6:	e9 97 00 00 00       	jmp    f0102f82 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102eeb:	83 ec 08             	sub    $0x8,%esp
f0102eee:	53                   	push   %ebx
f0102eef:	6a 58                	push   $0x58
f0102ef1:	ff d6                	call   *%esi
			putch('X', putdat);
f0102ef3:	83 c4 08             	add    $0x8,%esp
f0102ef6:	53                   	push   %ebx
f0102ef7:	6a 58                	push   $0x58
f0102ef9:	ff d6                	call   *%esi
			putch('X', putdat);
f0102efb:	83 c4 08             	add    $0x8,%esp
f0102efe:	53                   	push   %ebx
f0102eff:	6a 58                	push   $0x58
f0102f01:	ff d6                	call   *%esi
			break;
f0102f03:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f06:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102f09:	e9 8b fc ff ff       	jmp    f0102b99 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102f0e:	83 ec 08             	sub    $0x8,%esp
f0102f11:	53                   	push   %ebx
f0102f12:	6a 30                	push   $0x30
f0102f14:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f16:	83 c4 08             	add    $0x8,%esp
f0102f19:	53                   	push   %ebx
f0102f1a:	6a 78                	push   $0x78
f0102f1c:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102f1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f21:	8b 10                	mov    (%eax),%edx
f0102f23:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f28:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f2b:	8d 40 04             	lea    0x4(%eax),%eax
f0102f2e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102f31:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102f36:	eb 4a                	jmp    f0102f82 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f38:	83 f9 01             	cmp    $0x1,%ecx
f0102f3b:	7e 15                	jle    f0102f52 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102f3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f40:	8b 10                	mov    (%eax),%edx
f0102f42:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f45:	8d 40 08             	lea    0x8(%eax),%eax
f0102f48:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f4b:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f50:	eb 30                	jmp    f0102f82 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f52:	85 c9                	test   %ecx,%ecx
f0102f54:	74 17                	je     f0102f6d <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102f56:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f59:	8b 10                	mov    (%eax),%edx
f0102f5b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f60:	8d 40 04             	lea    0x4(%eax),%eax
f0102f63:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f66:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f6b:	eb 15                	jmp    f0102f82 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f70:	8b 10                	mov    (%eax),%edx
f0102f72:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f77:	8d 40 04             	lea    0x4(%eax),%eax
f0102f7a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f7d:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f82:	83 ec 0c             	sub    $0xc,%esp
f0102f85:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f89:	57                   	push   %edi
f0102f8a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f8d:	50                   	push   %eax
f0102f8e:	51                   	push   %ecx
f0102f8f:	52                   	push   %edx
f0102f90:	89 da                	mov    %ebx,%edx
f0102f92:	89 f0                	mov    %esi,%eax
f0102f94:	e8 f1 fa ff ff       	call   f0102a8a <printnum>
			break;
f0102f99:	83 c4 20             	add    $0x20,%esp
f0102f9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f9f:	e9 f5 fb ff ff       	jmp    f0102b99 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102fa4:	83 ec 08             	sub    $0x8,%esp
f0102fa7:	53                   	push   %ebx
f0102fa8:	52                   	push   %edx
f0102fa9:	ff d6                	call   *%esi
			break;
f0102fab:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fb1:	e9 e3 fb ff ff       	jmp    f0102b99 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fb6:	83 ec 08             	sub    $0x8,%esp
f0102fb9:	53                   	push   %ebx
f0102fba:	6a 25                	push   $0x25
f0102fbc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102fbe:	83 c4 10             	add    $0x10,%esp
f0102fc1:	eb 03                	jmp    f0102fc6 <vprintfmt+0x453>
f0102fc3:	83 ef 01             	sub    $0x1,%edi
f0102fc6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102fca:	75 f7                	jne    f0102fc3 <vprintfmt+0x450>
f0102fcc:	e9 c8 fb ff ff       	jmp    f0102b99 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102fd1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fd4:	5b                   	pop    %ebx
f0102fd5:	5e                   	pop    %esi
f0102fd6:	5f                   	pop    %edi
f0102fd7:	5d                   	pop    %ebp
f0102fd8:	c3                   	ret    

f0102fd9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102fd9:	55                   	push   %ebp
f0102fda:	89 e5                	mov    %esp,%ebp
f0102fdc:	83 ec 18             	sub    $0x18,%esp
f0102fdf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fe2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fe5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fe8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fec:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102ff6:	85 c0                	test   %eax,%eax
f0102ff8:	74 26                	je     f0103020 <vsnprintf+0x47>
f0102ffa:	85 d2                	test   %edx,%edx
f0102ffc:	7e 22                	jle    f0103020 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102ffe:	ff 75 14             	pushl  0x14(%ebp)
f0103001:	ff 75 10             	pushl  0x10(%ebp)
f0103004:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103007:	50                   	push   %eax
f0103008:	68 39 2b 10 f0       	push   $0xf0102b39
f010300d:	e8 61 fb ff ff       	call   f0102b73 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103012:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103015:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103018:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010301b:	83 c4 10             	add    $0x10,%esp
f010301e:	eb 05                	jmp    f0103025 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103020:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103025:	c9                   	leave  
f0103026:	c3                   	ret    

f0103027 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103027:	55                   	push   %ebp
f0103028:	89 e5                	mov    %esp,%ebp
f010302a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010302d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103030:	50                   	push   %eax
f0103031:	ff 75 10             	pushl  0x10(%ebp)
f0103034:	ff 75 0c             	pushl  0xc(%ebp)
f0103037:	ff 75 08             	pushl  0x8(%ebp)
f010303a:	e8 9a ff ff ff       	call   f0102fd9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010303f:	c9                   	leave  
f0103040:	c3                   	ret    

f0103041 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103041:	55                   	push   %ebp
f0103042:	89 e5                	mov    %esp,%ebp
f0103044:	57                   	push   %edi
f0103045:	56                   	push   %esi
f0103046:	53                   	push   %ebx
f0103047:	83 ec 0c             	sub    $0xc,%esp
f010304a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010304d:	85 c0                	test   %eax,%eax
f010304f:	74 11                	je     f0103062 <readline+0x21>
		cprintf("%s", prompt);
f0103051:	83 ec 08             	sub    $0x8,%esp
f0103054:	50                   	push   %eax
f0103055:	68 9c 3c 10 f0       	push   $0xf0103c9c
f010305a:	e8 f6 f6 ff ff       	call   f0102755 <cprintf>
f010305f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103062:	83 ec 0c             	sub    $0xc,%esp
f0103065:	6a 00                	push   $0x0
f0103067:	e8 b5 d5 ff ff       	call   f0100621 <iscons>
f010306c:	89 c7                	mov    %eax,%edi
f010306e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103071:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103076:	e8 95 d5 ff ff       	call   f0100610 <getchar>
f010307b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010307d:	85 c0                	test   %eax,%eax
f010307f:	79 18                	jns    f0103099 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103081:	83 ec 08             	sub    $0x8,%esp
f0103084:	50                   	push   %eax
f0103085:	68 80 49 10 f0       	push   $0xf0104980
f010308a:	e8 c6 f6 ff ff       	call   f0102755 <cprintf>
			return NULL;
f010308f:	83 c4 10             	add    $0x10,%esp
f0103092:	b8 00 00 00 00       	mov    $0x0,%eax
f0103097:	eb 79                	jmp    f0103112 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103099:	83 f8 08             	cmp    $0x8,%eax
f010309c:	0f 94 c2             	sete   %dl
f010309f:	83 f8 7f             	cmp    $0x7f,%eax
f01030a2:	0f 94 c0             	sete   %al
f01030a5:	08 c2                	or     %al,%dl
f01030a7:	74 1a                	je     f01030c3 <readline+0x82>
f01030a9:	85 f6                	test   %esi,%esi
f01030ab:	7e 16                	jle    f01030c3 <readline+0x82>
			if (echoing)
f01030ad:	85 ff                	test   %edi,%edi
f01030af:	74 0d                	je     f01030be <readline+0x7d>
				cputchar('\b');
f01030b1:	83 ec 0c             	sub    $0xc,%esp
f01030b4:	6a 08                	push   $0x8
f01030b6:	e8 45 d5 ff ff       	call   f0100600 <cputchar>
f01030bb:	83 c4 10             	add    $0x10,%esp
			i--;
f01030be:	83 ee 01             	sub    $0x1,%esi
f01030c1:	eb b3                	jmp    f0103076 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030c3:	83 fb 1f             	cmp    $0x1f,%ebx
f01030c6:	7e 23                	jle    f01030eb <readline+0xaa>
f01030c8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030ce:	7f 1b                	jg     f01030eb <readline+0xaa>
			if (echoing)
f01030d0:	85 ff                	test   %edi,%edi
f01030d2:	74 0c                	je     f01030e0 <readline+0x9f>
				cputchar(c);
f01030d4:	83 ec 0c             	sub    $0xc,%esp
f01030d7:	53                   	push   %ebx
f01030d8:	e8 23 d5 ff ff       	call   f0100600 <cputchar>
f01030dd:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030e0:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01030e6:	8d 76 01             	lea    0x1(%esi),%esi
f01030e9:	eb 8b                	jmp    f0103076 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030eb:	83 fb 0a             	cmp    $0xa,%ebx
f01030ee:	74 05                	je     f01030f5 <readline+0xb4>
f01030f0:	83 fb 0d             	cmp    $0xd,%ebx
f01030f3:	75 81                	jne    f0103076 <readline+0x35>
			if (echoing)
f01030f5:	85 ff                	test   %edi,%edi
f01030f7:	74 0d                	je     f0103106 <readline+0xc5>
				cputchar('\n');
f01030f9:	83 ec 0c             	sub    $0xc,%esp
f01030fc:	6a 0a                	push   $0xa
f01030fe:	e8 fd d4 ff ff       	call   f0100600 <cputchar>
f0103103:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103106:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010310d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103112:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103115:	5b                   	pop    %ebx
f0103116:	5e                   	pop    %esi
f0103117:	5f                   	pop    %edi
f0103118:	5d                   	pop    %ebp
f0103119:	c3                   	ret    

f010311a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010311a:	55                   	push   %ebp
f010311b:	89 e5                	mov    %esp,%ebp
f010311d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103120:	b8 00 00 00 00       	mov    $0x0,%eax
f0103125:	eb 03                	jmp    f010312a <strlen+0x10>
		n++;
f0103127:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010312a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010312e:	75 f7                	jne    f0103127 <strlen+0xd>
		n++;
	return n;
}
f0103130:	5d                   	pop    %ebp
f0103131:	c3                   	ret    

f0103132 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103132:	55                   	push   %ebp
f0103133:	89 e5                	mov    %esp,%ebp
f0103135:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103138:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010313b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103140:	eb 03                	jmp    f0103145 <strnlen+0x13>
		n++;
f0103142:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103145:	39 c2                	cmp    %eax,%edx
f0103147:	74 08                	je     f0103151 <strnlen+0x1f>
f0103149:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010314d:	75 f3                	jne    f0103142 <strnlen+0x10>
f010314f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103151:	5d                   	pop    %ebp
f0103152:	c3                   	ret    

f0103153 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103153:	55                   	push   %ebp
f0103154:	89 e5                	mov    %esp,%ebp
f0103156:	53                   	push   %ebx
f0103157:	8b 45 08             	mov    0x8(%ebp),%eax
f010315a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010315d:	89 c2                	mov    %eax,%edx
f010315f:	83 c2 01             	add    $0x1,%edx
f0103162:	83 c1 01             	add    $0x1,%ecx
f0103165:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103169:	88 5a ff             	mov    %bl,-0x1(%edx)
f010316c:	84 db                	test   %bl,%bl
f010316e:	75 ef                	jne    f010315f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103170:	5b                   	pop    %ebx
f0103171:	5d                   	pop    %ebp
f0103172:	c3                   	ret    

f0103173 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103173:	55                   	push   %ebp
f0103174:	89 e5                	mov    %esp,%ebp
f0103176:	53                   	push   %ebx
f0103177:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010317a:	53                   	push   %ebx
f010317b:	e8 9a ff ff ff       	call   f010311a <strlen>
f0103180:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103183:	ff 75 0c             	pushl  0xc(%ebp)
f0103186:	01 d8                	add    %ebx,%eax
f0103188:	50                   	push   %eax
f0103189:	e8 c5 ff ff ff       	call   f0103153 <strcpy>
	return dst;
}
f010318e:	89 d8                	mov    %ebx,%eax
f0103190:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103193:	c9                   	leave  
f0103194:	c3                   	ret    

f0103195 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103195:	55                   	push   %ebp
f0103196:	89 e5                	mov    %esp,%ebp
f0103198:	56                   	push   %esi
f0103199:	53                   	push   %ebx
f010319a:	8b 75 08             	mov    0x8(%ebp),%esi
f010319d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031a0:	89 f3                	mov    %esi,%ebx
f01031a2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031a5:	89 f2                	mov    %esi,%edx
f01031a7:	eb 0f                	jmp    f01031b8 <strncpy+0x23>
		*dst++ = *src;
f01031a9:	83 c2 01             	add    $0x1,%edx
f01031ac:	0f b6 01             	movzbl (%ecx),%eax
f01031af:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031b2:	80 39 01             	cmpb   $0x1,(%ecx)
f01031b5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031b8:	39 da                	cmp    %ebx,%edx
f01031ba:	75 ed                	jne    f01031a9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031bc:	89 f0                	mov    %esi,%eax
f01031be:	5b                   	pop    %ebx
f01031bf:	5e                   	pop    %esi
f01031c0:	5d                   	pop    %ebp
f01031c1:	c3                   	ret    

f01031c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031c2:	55                   	push   %ebp
f01031c3:	89 e5                	mov    %esp,%ebp
f01031c5:	56                   	push   %esi
f01031c6:	53                   	push   %ebx
f01031c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01031ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031cd:	8b 55 10             	mov    0x10(%ebp),%edx
f01031d0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031d2:	85 d2                	test   %edx,%edx
f01031d4:	74 21                	je     f01031f7 <strlcpy+0x35>
f01031d6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031da:	89 f2                	mov    %esi,%edx
f01031dc:	eb 09                	jmp    f01031e7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031de:	83 c2 01             	add    $0x1,%edx
f01031e1:	83 c1 01             	add    $0x1,%ecx
f01031e4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031e7:	39 c2                	cmp    %eax,%edx
f01031e9:	74 09                	je     f01031f4 <strlcpy+0x32>
f01031eb:	0f b6 19             	movzbl (%ecx),%ebx
f01031ee:	84 db                	test   %bl,%bl
f01031f0:	75 ec                	jne    f01031de <strlcpy+0x1c>
f01031f2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031f4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031f7:	29 f0                	sub    %esi,%eax
}
f01031f9:	5b                   	pop    %ebx
f01031fa:	5e                   	pop    %esi
f01031fb:	5d                   	pop    %ebp
f01031fc:	c3                   	ret    

f01031fd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031fd:	55                   	push   %ebp
f01031fe:	89 e5                	mov    %esp,%ebp
f0103200:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103203:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103206:	eb 06                	jmp    f010320e <strcmp+0x11>
		p++, q++;
f0103208:	83 c1 01             	add    $0x1,%ecx
f010320b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010320e:	0f b6 01             	movzbl (%ecx),%eax
f0103211:	84 c0                	test   %al,%al
f0103213:	74 04                	je     f0103219 <strcmp+0x1c>
f0103215:	3a 02                	cmp    (%edx),%al
f0103217:	74 ef                	je     f0103208 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103219:	0f b6 c0             	movzbl %al,%eax
f010321c:	0f b6 12             	movzbl (%edx),%edx
f010321f:	29 d0                	sub    %edx,%eax
}
f0103221:	5d                   	pop    %ebp
f0103222:	c3                   	ret    

f0103223 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103223:	55                   	push   %ebp
f0103224:	89 e5                	mov    %esp,%ebp
f0103226:	53                   	push   %ebx
f0103227:	8b 45 08             	mov    0x8(%ebp),%eax
f010322a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010322d:	89 c3                	mov    %eax,%ebx
f010322f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103232:	eb 06                	jmp    f010323a <strncmp+0x17>
		n--, p++, q++;
f0103234:	83 c0 01             	add    $0x1,%eax
f0103237:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010323a:	39 d8                	cmp    %ebx,%eax
f010323c:	74 15                	je     f0103253 <strncmp+0x30>
f010323e:	0f b6 08             	movzbl (%eax),%ecx
f0103241:	84 c9                	test   %cl,%cl
f0103243:	74 04                	je     f0103249 <strncmp+0x26>
f0103245:	3a 0a                	cmp    (%edx),%cl
f0103247:	74 eb                	je     f0103234 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103249:	0f b6 00             	movzbl (%eax),%eax
f010324c:	0f b6 12             	movzbl (%edx),%edx
f010324f:	29 d0                	sub    %edx,%eax
f0103251:	eb 05                	jmp    f0103258 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103253:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103258:	5b                   	pop    %ebx
f0103259:	5d                   	pop    %ebp
f010325a:	c3                   	ret    

f010325b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010325b:	55                   	push   %ebp
f010325c:	89 e5                	mov    %esp,%ebp
f010325e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103261:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103265:	eb 07                	jmp    f010326e <strchr+0x13>
		if (*s == c)
f0103267:	38 ca                	cmp    %cl,%dl
f0103269:	74 0f                	je     f010327a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010326b:	83 c0 01             	add    $0x1,%eax
f010326e:	0f b6 10             	movzbl (%eax),%edx
f0103271:	84 d2                	test   %dl,%dl
f0103273:	75 f2                	jne    f0103267 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103275:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010327a:	5d                   	pop    %ebp
f010327b:	c3                   	ret    

f010327c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010327c:	55                   	push   %ebp
f010327d:	89 e5                	mov    %esp,%ebp
f010327f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103282:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103286:	eb 03                	jmp    f010328b <strfind+0xf>
f0103288:	83 c0 01             	add    $0x1,%eax
f010328b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010328e:	38 ca                	cmp    %cl,%dl
f0103290:	74 04                	je     f0103296 <strfind+0x1a>
f0103292:	84 d2                	test   %dl,%dl
f0103294:	75 f2                	jne    f0103288 <strfind+0xc>
			break;
	return (char *) s;
}
f0103296:	5d                   	pop    %ebp
f0103297:	c3                   	ret    

f0103298 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103298:	55                   	push   %ebp
f0103299:	89 e5                	mov    %esp,%ebp
f010329b:	57                   	push   %edi
f010329c:	56                   	push   %esi
f010329d:	53                   	push   %ebx
f010329e:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032a1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01032a4:	85 c9                	test   %ecx,%ecx
f01032a6:	74 36                	je     f01032de <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01032a8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01032ae:	75 28                	jne    f01032d8 <memset+0x40>
f01032b0:	f6 c1 03             	test   $0x3,%cl
f01032b3:	75 23                	jne    f01032d8 <memset+0x40>
		c &= 0xFF;
f01032b5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032b9:	89 d3                	mov    %edx,%ebx
f01032bb:	c1 e3 08             	shl    $0x8,%ebx
f01032be:	89 d6                	mov    %edx,%esi
f01032c0:	c1 e6 18             	shl    $0x18,%esi
f01032c3:	89 d0                	mov    %edx,%eax
f01032c5:	c1 e0 10             	shl    $0x10,%eax
f01032c8:	09 f0                	or     %esi,%eax
f01032ca:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032cc:	89 d8                	mov    %ebx,%eax
f01032ce:	09 d0                	or     %edx,%eax
f01032d0:	c1 e9 02             	shr    $0x2,%ecx
f01032d3:	fc                   	cld    
f01032d4:	f3 ab                	rep stos %eax,%es:(%edi)
f01032d6:	eb 06                	jmp    f01032de <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032db:	fc                   	cld    
f01032dc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01032de:	89 f8                	mov    %edi,%eax
f01032e0:	5b                   	pop    %ebx
f01032e1:	5e                   	pop    %esi
f01032e2:	5f                   	pop    %edi
f01032e3:	5d                   	pop    %ebp
f01032e4:	c3                   	ret    

f01032e5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032e5:	55                   	push   %ebp
f01032e6:	89 e5                	mov    %esp,%ebp
f01032e8:	57                   	push   %edi
f01032e9:	56                   	push   %esi
f01032ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01032ed:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032f3:	39 c6                	cmp    %eax,%esi
f01032f5:	73 35                	jae    f010332c <memmove+0x47>
f01032f7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032fa:	39 d0                	cmp    %edx,%eax
f01032fc:	73 2e                	jae    f010332c <memmove+0x47>
		s += n;
		d += n;
f01032fe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103301:	89 d6                	mov    %edx,%esi
f0103303:	09 fe                	or     %edi,%esi
f0103305:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010330b:	75 13                	jne    f0103320 <memmove+0x3b>
f010330d:	f6 c1 03             	test   $0x3,%cl
f0103310:	75 0e                	jne    f0103320 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103312:	83 ef 04             	sub    $0x4,%edi
f0103315:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103318:	c1 e9 02             	shr    $0x2,%ecx
f010331b:	fd                   	std    
f010331c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010331e:	eb 09                	jmp    f0103329 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103320:	83 ef 01             	sub    $0x1,%edi
f0103323:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103326:	fd                   	std    
f0103327:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103329:	fc                   	cld    
f010332a:	eb 1d                	jmp    f0103349 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010332c:	89 f2                	mov    %esi,%edx
f010332e:	09 c2                	or     %eax,%edx
f0103330:	f6 c2 03             	test   $0x3,%dl
f0103333:	75 0f                	jne    f0103344 <memmove+0x5f>
f0103335:	f6 c1 03             	test   $0x3,%cl
f0103338:	75 0a                	jne    f0103344 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010333a:	c1 e9 02             	shr    $0x2,%ecx
f010333d:	89 c7                	mov    %eax,%edi
f010333f:	fc                   	cld    
f0103340:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103342:	eb 05                	jmp    f0103349 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103344:	89 c7                	mov    %eax,%edi
f0103346:	fc                   	cld    
f0103347:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103349:	5e                   	pop    %esi
f010334a:	5f                   	pop    %edi
f010334b:	5d                   	pop    %ebp
f010334c:	c3                   	ret    

f010334d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010334d:	55                   	push   %ebp
f010334e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103350:	ff 75 10             	pushl  0x10(%ebp)
f0103353:	ff 75 0c             	pushl  0xc(%ebp)
f0103356:	ff 75 08             	pushl  0x8(%ebp)
f0103359:	e8 87 ff ff ff       	call   f01032e5 <memmove>
}
f010335e:	c9                   	leave  
f010335f:	c3                   	ret    

f0103360 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103360:	55                   	push   %ebp
f0103361:	89 e5                	mov    %esp,%ebp
f0103363:	56                   	push   %esi
f0103364:	53                   	push   %ebx
f0103365:	8b 45 08             	mov    0x8(%ebp),%eax
f0103368:	8b 55 0c             	mov    0xc(%ebp),%edx
f010336b:	89 c6                	mov    %eax,%esi
f010336d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103370:	eb 1a                	jmp    f010338c <memcmp+0x2c>
		if (*s1 != *s2)
f0103372:	0f b6 08             	movzbl (%eax),%ecx
f0103375:	0f b6 1a             	movzbl (%edx),%ebx
f0103378:	38 d9                	cmp    %bl,%cl
f010337a:	74 0a                	je     f0103386 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010337c:	0f b6 c1             	movzbl %cl,%eax
f010337f:	0f b6 db             	movzbl %bl,%ebx
f0103382:	29 d8                	sub    %ebx,%eax
f0103384:	eb 0f                	jmp    f0103395 <memcmp+0x35>
		s1++, s2++;
f0103386:	83 c0 01             	add    $0x1,%eax
f0103389:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010338c:	39 f0                	cmp    %esi,%eax
f010338e:	75 e2                	jne    f0103372 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103390:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103395:	5b                   	pop    %ebx
f0103396:	5e                   	pop    %esi
f0103397:	5d                   	pop    %ebp
f0103398:	c3                   	ret    

f0103399 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103399:	55                   	push   %ebp
f010339a:	89 e5                	mov    %esp,%ebp
f010339c:	53                   	push   %ebx
f010339d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01033a0:	89 c1                	mov    %eax,%ecx
f01033a2:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01033a5:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033a9:	eb 0a                	jmp    f01033b5 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033ab:	0f b6 10             	movzbl (%eax),%edx
f01033ae:	39 da                	cmp    %ebx,%edx
f01033b0:	74 07                	je     f01033b9 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033b2:	83 c0 01             	add    $0x1,%eax
f01033b5:	39 c8                	cmp    %ecx,%eax
f01033b7:	72 f2                	jb     f01033ab <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033b9:	5b                   	pop    %ebx
f01033ba:	5d                   	pop    %ebp
f01033bb:	c3                   	ret    

f01033bc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033bc:	55                   	push   %ebp
f01033bd:	89 e5                	mov    %esp,%ebp
f01033bf:	57                   	push   %edi
f01033c0:	56                   	push   %esi
f01033c1:	53                   	push   %ebx
f01033c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033c5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033c8:	eb 03                	jmp    f01033cd <strtol+0x11>
		s++;
f01033ca:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033cd:	0f b6 01             	movzbl (%ecx),%eax
f01033d0:	3c 20                	cmp    $0x20,%al
f01033d2:	74 f6                	je     f01033ca <strtol+0xe>
f01033d4:	3c 09                	cmp    $0x9,%al
f01033d6:	74 f2                	je     f01033ca <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033d8:	3c 2b                	cmp    $0x2b,%al
f01033da:	75 0a                	jne    f01033e6 <strtol+0x2a>
		s++;
f01033dc:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033df:	bf 00 00 00 00       	mov    $0x0,%edi
f01033e4:	eb 11                	jmp    f01033f7 <strtol+0x3b>
f01033e6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033eb:	3c 2d                	cmp    $0x2d,%al
f01033ed:	75 08                	jne    f01033f7 <strtol+0x3b>
		s++, neg = 1;
f01033ef:	83 c1 01             	add    $0x1,%ecx
f01033f2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033f7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033fd:	75 15                	jne    f0103414 <strtol+0x58>
f01033ff:	80 39 30             	cmpb   $0x30,(%ecx)
f0103402:	75 10                	jne    f0103414 <strtol+0x58>
f0103404:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103408:	75 7c                	jne    f0103486 <strtol+0xca>
		s += 2, base = 16;
f010340a:	83 c1 02             	add    $0x2,%ecx
f010340d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103412:	eb 16                	jmp    f010342a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103414:	85 db                	test   %ebx,%ebx
f0103416:	75 12                	jne    f010342a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103418:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010341d:	80 39 30             	cmpb   $0x30,(%ecx)
f0103420:	75 08                	jne    f010342a <strtol+0x6e>
		s++, base = 8;
f0103422:	83 c1 01             	add    $0x1,%ecx
f0103425:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010342a:	b8 00 00 00 00       	mov    $0x0,%eax
f010342f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103432:	0f b6 11             	movzbl (%ecx),%edx
f0103435:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103438:	89 f3                	mov    %esi,%ebx
f010343a:	80 fb 09             	cmp    $0x9,%bl
f010343d:	77 08                	ja     f0103447 <strtol+0x8b>
			dig = *s - '0';
f010343f:	0f be d2             	movsbl %dl,%edx
f0103442:	83 ea 30             	sub    $0x30,%edx
f0103445:	eb 22                	jmp    f0103469 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103447:	8d 72 9f             	lea    -0x61(%edx),%esi
f010344a:	89 f3                	mov    %esi,%ebx
f010344c:	80 fb 19             	cmp    $0x19,%bl
f010344f:	77 08                	ja     f0103459 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103451:	0f be d2             	movsbl %dl,%edx
f0103454:	83 ea 57             	sub    $0x57,%edx
f0103457:	eb 10                	jmp    f0103469 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103459:	8d 72 bf             	lea    -0x41(%edx),%esi
f010345c:	89 f3                	mov    %esi,%ebx
f010345e:	80 fb 19             	cmp    $0x19,%bl
f0103461:	77 16                	ja     f0103479 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103463:	0f be d2             	movsbl %dl,%edx
f0103466:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103469:	3b 55 10             	cmp    0x10(%ebp),%edx
f010346c:	7d 0b                	jge    f0103479 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010346e:	83 c1 01             	add    $0x1,%ecx
f0103471:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103475:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103477:	eb b9                	jmp    f0103432 <strtol+0x76>

	if (endptr)
f0103479:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010347d:	74 0d                	je     f010348c <strtol+0xd0>
		*endptr = (char *) s;
f010347f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103482:	89 0e                	mov    %ecx,(%esi)
f0103484:	eb 06                	jmp    f010348c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103486:	85 db                	test   %ebx,%ebx
f0103488:	74 98                	je     f0103422 <strtol+0x66>
f010348a:	eb 9e                	jmp    f010342a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010348c:	89 c2                	mov    %eax,%edx
f010348e:	f7 da                	neg    %edx
f0103490:	85 ff                	test   %edi,%edi
f0103492:	0f 45 c2             	cmovne %edx,%eax
}
f0103495:	5b                   	pop    %ebx
f0103496:	5e                   	pop    %esi
f0103497:	5f                   	pop    %edi
f0103498:	5d                   	pop    %ebp
f0103499:	c3                   	ret    
f010349a:	66 90                	xchg   %ax,%ax
f010349c:	66 90                	xchg   %ax,%ax
f010349e:	66 90                	xchg   %ax,%ax

f01034a0 <__udivdi3>:
f01034a0:	55                   	push   %ebp
f01034a1:	57                   	push   %edi
f01034a2:	56                   	push   %esi
f01034a3:	53                   	push   %ebx
f01034a4:	83 ec 1c             	sub    $0x1c,%esp
f01034a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034b7:	85 f6                	test   %esi,%esi
f01034b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034bd:	89 ca                	mov    %ecx,%edx
f01034bf:	89 f8                	mov    %edi,%eax
f01034c1:	75 3d                	jne    f0103500 <__udivdi3+0x60>
f01034c3:	39 cf                	cmp    %ecx,%edi
f01034c5:	0f 87 c5 00 00 00    	ja     f0103590 <__udivdi3+0xf0>
f01034cb:	85 ff                	test   %edi,%edi
f01034cd:	89 fd                	mov    %edi,%ebp
f01034cf:	75 0b                	jne    f01034dc <__udivdi3+0x3c>
f01034d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034d6:	31 d2                	xor    %edx,%edx
f01034d8:	f7 f7                	div    %edi
f01034da:	89 c5                	mov    %eax,%ebp
f01034dc:	89 c8                	mov    %ecx,%eax
f01034de:	31 d2                	xor    %edx,%edx
f01034e0:	f7 f5                	div    %ebp
f01034e2:	89 c1                	mov    %eax,%ecx
f01034e4:	89 d8                	mov    %ebx,%eax
f01034e6:	89 cf                	mov    %ecx,%edi
f01034e8:	f7 f5                	div    %ebp
f01034ea:	89 c3                	mov    %eax,%ebx
f01034ec:	89 d8                	mov    %ebx,%eax
f01034ee:	89 fa                	mov    %edi,%edx
f01034f0:	83 c4 1c             	add    $0x1c,%esp
f01034f3:	5b                   	pop    %ebx
f01034f4:	5e                   	pop    %esi
f01034f5:	5f                   	pop    %edi
f01034f6:	5d                   	pop    %ebp
f01034f7:	c3                   	ret    
f01034f8:	90                   	nop
f01034f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103500:	39 ce                	cmp    %ecx,%esi
f0103502:	77 74                	ja     f0103578 <__udivdi3+0xd8>
f0103504:	0f bd fe             	bsr    %esi,%edi
f0103507:	83 f7 1f             	xor    $0x1f,%edi
f010350a:	0f 84 98 00 00 00    	je     f01035a8 <__udivdi3+0x108>
f0103510:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	89 c5                	mov    %eax,%ebp
f0103519:	29 fb                	sub    %edi,%ebx
f010351b:	d3 e6                	shl    %cl,%esi
f010351d:	89 d9                	mov    %ebx,%ecx
f010351f:	d3 ed                	shr    %cl,%ebp
f0103521:	89 f9                	mov    %edi,%ecx
f0103523:	d3 e0                	shl    %cl,%eax
f0103525:	09 ee                	or     %ebp,%esi
f0103527:	89 d9                	mov    %ebx,%ecx
f0103529:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010352d:	89 d5                	mov    %edx,%ebp
f010352f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103533:	d3 ed                	shr    %cl,%ebp
f0103535:	89 f9                	mov    %edi,%ecx
f0103537:	d3 e2                	shl    %cl,%edx
f0103539:	89 d9                	mov    %ebx,%ecx
f010353b:	d3 e8                	shr    %cl,%eax
f010353d:	09 c2                	or     %eax,%edx
f010353f:	89 d0                	mov    %edx,%eax
f0103541:	89 ea                	mov    %ebp,%edx
f0103543:	f7 f6                	div    %esi
f0103545:	89 d5                	mov    %edx,%ebp
f0103547:	89 c3                	mov    %eax,%ebx
f0103549:	f7 64 24 0c          	mull   0xc(%esp)
f010354d:	39 d5                	cmp    %edx,%ebp
f010354f:	72 10                	jb     f0103561 <__udivdi3+0xc1>
f0103551:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103555:	89 f9                	mov    %edi,%ecx
f0103557:	d3 e6                	shl    %cl,%esi
f0103559:	39 c6                	cmp    %eax,%esi
f010355b:	73 07                	jae    f0103564 <__udivdi3+0xc4>
f010355d:	39 d5                	cmp    %edx,%ebp
f010355f:	75 03                	jne    f0103564 <__udivdi3+0xc4>
f0103561:	83 eb 01             	sub    $0x1,%ebx
f0103564:	31 ff                	xor    %edi,%edi
f0103566:	89 d8                	mov    %ebx,%eax
f0103568:	89 fa                	mov    %edi,%edx
f010356a:	83 c4 1c             	add    $0x1c,%esp
f010356d:	5b                   	pop    %ebx
f010356e:	5e                   	pop    %esi
f010356f:	5f                   	pop    %edi
f0103570:	5d                   	pop    %ebp
f0103571:	c3                   	ret    
f0103572:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103578:	31 ff                	xor    %edi,%edi
f010357a:	31 db                	xor    %ebx,%ebx
f010357c:	89 d8                	mov    %ebx,%eax
f010357e:	89 fa                	mov    %edi,%edx
f0103580:	83 c4 1c             	add    $0x1c,%esp
f0103583:	5b                   	pop    %ebx
f0103584:	5e                   	pop    %esi
f0103585:	5f                   	pop    %edi
f0103586:	5d                   	pop    %ebp
f0103587:	c3                   	ret    
f0103588:	90                   	nop
f0103589:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103590:	89 d8                	mov    %ebx,%eax
f0103592:	f7 f7                	div    %edi
f0103594:	31 ff                	xor    %edi,%edi
f0103596:	89 c3                	mov    %eax,%ebx
f0103598:	89 d8                	mov    %ebx,%eax
f010359a:	89 fa                	mov    %edi,%edx
f010359c:	83 c4 1c             	add    $0x1c,%esp
f010359f:	5b                   	pop    %ebx
f01035a0:	5e                   	pop    %esi
f01035a1:	5f                   	pop    %edi
f01035a2:	5d                   	pop    %ebp
f01035a3:	c3                   	ret    
f01035a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035a8:	39 ce                	cmp    %ecx,%esi
f01035aa:	72 0c                	jb     f01035b8 <__udivdi3+0x118>
f01035ac:	31 db                	xor    %ebx,%ebx
f01035ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035b2:	0f 87 34 ff ff ff    	ja     f01034ec <__udivdi3+0x4c>
f01035b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035bd:	e9 2a ff ff ff       	jmp    f01034ec <__udivdi3+0x4c>
f01035c2:	66 90                	xchg   %ax,%ax
f01035c4:	66 90                	xchg   %ax,%ax
f01035c6:	66 90                	xchg   %ax,%ax
f01035c8:	66 90                	xchg   %ax,%ax
f01035ca:	66 90                	xchg   %ax,%ax
f01035cc:	66 90                	xchg   %ax,%ax
f01035ce:	66 90                	xchg   %ax,%ax

f01035d0 <__umoddi3>:
f01035d0:	55                   	push   %ebp
f01035d1:	57                   	push   %edi
f01035d2:	56                   	push   %esi
f01035d3:	53                   	push   %ebx
f01035d4:	83 ec 1c             	sub    $0x1c,%esp
f01035d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035e7:	85 d2                	test   %edx,%edx
f01035e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035f1:	89 f3                	mov    %esi,%ebx
f01035f3:	89 3c 24             	mov    %edi,(%esp)
f01035f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035fa:	75 1c                	jne    f0103618 <__umoddi3+0x48>
f01035fc:	39 f7                	cmp    %esi,%edi
f01035fe:	76 50                	jbe    f0103650 <__umoddi3+0x80>
f0103600:	89 c8                	mov    %ecx,%eax
f0103602:	89 f2                	mov    %esi,%edx
f0103604:	f7 f7                	div    %edi
f0103606:	89 d0                	mov    %edx,%eax
f0103608:	31 d2                	xor    %edx,%edx
f010360a:	83 c4 1c             	add    $0x1c,%esp
f010360d:	5b                   	pop    %ebx
f010360e:	5e                   	pop    %esi
f010360f:	5f                   	pop    %edi
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    
f0103612:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103618:	39 f2                	cmp    %esi,%edx
f010361a:	89 d0                	mov    %edx,%eax
f010361c:	77 52                	ja     f0103670 <__umoddi3+0xa0>
f010361e:	0f bd ea             	bsr    %edx,%ebp
f0103621:	83 f5 1f             	xor    $0x1f,%ebp
f0103624:	75 5a                	jne    f0103680 <__umoddi3+0xb0>
f0103626:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010362a:	0f 82 e0 00 00 00    	jb     f0103710 <__umoddi3+0x140>
f0103630:	39 0c 24             	cmp    %ecx,(%esp)
f0103633:	0f 86 d7 00 00 00    	jbe    f0103710 <__umoddi3+0x140>
f0103639:	8b 44 24 08          	mov    0x8(%esp),%eax
f010363d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103641:	83 c4 1c             	add    $0x1c,%esp
f0103644:	5b                   	pop    %ebx
f0103645:	5e                   	pop    %esi
f0103646:	5f                   	pop    %edi
f0103647:	5d                   	pop    %ebp
f0103648:	c3                   	ret    
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	85 ff                	test   %edi,%edi
f0103652:	89 fd                	mov    %edi,%ebp
f0103654:	75 0b                	jne    f0103661 <__umoddi3+0x91>
f0103656:	b8 01 00 00 00       	mov    $0x1,%eax
f010365b:	31 d2                	xor    %edx,%edx
f010365d:	f7 f7                	div    %edi
f010365f:	89 c5                	mov    %eax,%ebp
f0103661:	89 f0                	mov    %esi,%eax
f0103663:	31 d2                	xor    %edx,%edx
f0103665:	f7 f5                	div    %ebp
f0103667:	89 c8                	mov    %ecx,%eax
f0103669:	f7 f5                	div    %ebp
f010366b:	89 d0                	mov    %edx,%eax
f010366d:	eb 99                	jmp    f0103608 <__umoddi3+0x38>
f010366f:	90                   	nop
f0103670:	89 c8                	mov    %ecx,%eax
f0103672:	89 f2                	mov    %esi,%edx
f0103674:	83 c4 1c             	add    $0x1c,%esp
f0103677:	5b                   	pop    %ebx
f0103678:	5e                   	pop    %esi
f0103679:	5f                   	pop    %edi
f010367a:	5d                   	pop    %ebp
f010367b:	c3                   	ret    
f010367c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103680:	8b 34 24             	mov    (%esp),%esi
f0103683:	bf 20 00 00 00       	mov    $0x20,%edi
f0103688:	89 e9                	mov    %ebp,%ecx
f010368a:	29 ef                	sub    %ebp,%edi
f010368c:	d3 e0                	shl    %cl,%eax
f010368e:	89 f9                	mov    %edi,%ecx
f0103690:	89 f2                	mov    %esi,%edx
f0103692:	d3 ea                	shr    %cl,%edx
f0103694:	89 e9                	mov    %ebp,%ecx
f0103696:	09 c2                	or     %eax,%edx
f0103698:	89 d8                	mov    %ebx,%eax
f010369a:	89 14 24             	mov    %edx,(%esp)
f010369d:	89 f2                	mov    %esi,%edx
f010369f:	d3 e2                	shl    %cl,%edx
f01036a1:	89 f9                	mov    %edi,%ecx
f01036a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036ab:	d3 e8                	shr    %cl,%eax
f01036ad:	89 e9                	mov    %ebp,%ecx
f01036af:	89 c6                	mov    %eax,%esi
f01036b1:	d3 e3                	shl    %cl,%ebx
f01036b3:	89 f9                	mov    %edi,%ecx
f01036b5:	89 d0                	mov    %edx,%eax
f01036b7:	d3 e8                	shr    %cl,%eax
f01036b9:	89 e9                	mov    %ebp,%ecx
f01036bb:	09 d8                	or     %ebx,%eax
f01036bd:	89 d3                	mov    %edx,%ebx
f01036bf:	89 f2                	mov    %esi,%edx
f01036c1:	f7 34 24             	divl   (%esp)
f01036c4:	89 d6                	mov    %edx,%esi
f01036c6:	d3 e3                	shl    %cl,%ebx
f01036c8:	f7 64 24 04          	mull   0x4(%esp)
f01036cc:	39 d6                	cmp    %edx,%esi
f01036ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036d2:	89 d1                	mov    %edx,%ecx
f01036d4:	89 c3                	mov    %eax,%ebx
f01036d6:	72 08                	jb     f01036e0 <__umoddi3+0x110>
f01036d8:	75 11                	jne    f01036eb <__umoddi3+0x11b>
f01036da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036de:	73 0b                	jae    f01036eb <__umoddi3+0x11b>
f01036e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036e4:	1b 14 24             	sbb    (%esp),%edx
f01036e7:	89 d1                	mov    %edx,%ecx
f01036e9:	89 c3                	mov    %eax,%ebx
f01036eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036ef:	29 da                	sub    %ebx,%edx
f01036f1:	19 ce                	sbb    %ecx,%esi
f01036f3:	89 f9                	mov    %edi,%ecx
f01036f5:	89 f0                	mov    %esi,%eax
f01036f7:	d3 e0                	shl    %cl,%eax
f01036f9:	89 e9                	mov    %ebp,%ecx
f01036fb:	d3 ea                	shr    %cl,%edx
f01036fd:	89 e9                	mov    %ebp,%ecx
f01036ff:	d3 ee                	shr    %cl,%esi
f0103701:	09 d0                	or     %edx,%eax
f0103703:	89 f2                	mov    %esi,%edx
f0103705:	83 c4 1c             	add    $0x1c,%esp
f0103708:	5b                   	pop    %ebx
f0103709:	5e                   	pop    %esi
f010370a:	5f                   	pop    %edi
f010370b:	5d                   	pop    %ebp
f010370c:	c3                   	ret    
f010370d:	8d 76 00             	lea    0x0(%esi),%esi
f0103710:	29 f9                	sub    %edi,%ecx
f0103712:	19 d6                	sbb    %edx,%esi
f0103714:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103718:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010371c:	e9 18 ff ff ff       	jmp    f0103639 <__umoddi3+0x69>
