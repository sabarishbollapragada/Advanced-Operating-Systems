
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 19 10 f0       	push   $0xf0101940
f0100050:	e8 13 09 00 00       	call   f0100968 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 f3 06 00 00       	call   f010076e <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 19 10 f0       	push   $0xf010195c
f0100087:	e8 dc 08 00 00       	call   f0100968 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 fa 13 00 00       	call   f01014ab <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 19 10 f0       	push   $0xf0101977
f01000c3:	e8 a0 08 00 00       	call   f0100968 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 07 07 00 00       	call   f01007e8 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 92 19 10 f0       	push   $0xf0101992
f0100110:	e8 53 08 00 00       	call   f0100968 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 23 08 00 00       	call   f0100942 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f0100126:	e8 3d 08 00 00       	call   f0100968 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 b0 06 00 00       	call   f01007e8 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 aa 19 10 f0       	push   $0xf01019aa
f0100152:	e8 11 08 00 00       	call   f0100968 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 df 07 00 00       	call   f0100942 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f010016a:	e8 f9 07 00 00       	call   f0100968 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d 00 1a 10 f0 	mov    -0xfefe600(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 c4 19 10 f0       	push   $0xf01019c4
f01002c8:	e8 9b 06 00 00       	call   f0100968 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 7c 10 00 00       	call   f01014f8 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 d0 19 10 f0       	push   $0xf01019d0
f010064b:	e8 18 03 00 00       	call   f0100968 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 20 1c 10 f0       	push   $0xf0101c20
f0100691:	68 3e 1c 10 f0       	push   $0xf0101c3e
f0100696:	68 43 1c 10 f0       	push   $0xf0101c43
f010069b:	e8 c8 02 00 00       	call   f0100968 <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 d0 1c 10 f0       	push   $0xf0101cd0
f01006a8:	68 4c 1c 10 f0       	push   $0xf0101c4c
f01006ad:	68 43 1c 10 f0       	push   $0xf0101c43
f01006b2:	e8 b1 02 00 00       	call   f0100968 <cprintf>
	return 0;
}
f01006b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006bc:	c9                   	leave  
f01006bd:	c3                   	ret    

f01006be <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006be:	55                   	push   %ebp
f01006bf:	89 e5                	mov    %esp,%ebp
f01006c1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006c4:	68 55 1c 10 f0       	push   $0xf0101c55
f01006c9:	e8 9a 02 00 00       	call   f0100968 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ce:	83 c4 08             	add    $0x8,%esp
f01006d1:	68 0c 00 10 00       	push   $0x10000c
f01006d6:	68 f8 1c 10 f0       	push   $0xf0101cf8
f01006db:	e8 88 02 00 00       	call   f0100968 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e0:	83 c4 0c             	add    $0xc,%esp
f01006e3:	68 0c 00 10 00       	push   $0x10000c
f01006e8:	68 0c 00 10 f0       	push   $0xf010000c
f01006ed:	68 20 1d 10 f0       	push   $0xf0101d20
f01006f2:	e8 71 02 00 00       	call   f0100968 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 31 19 10 00       	push   $0x101931
f01006ff:	68 31 19 10 f0       	push   $0xf0101931
f0100704:	68 44 1d 10 f0       	push   $0xf0101d44
f0100709:	e8 5a 02 00 00       	call   f0100968 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 00 23 11 00       	push   $0x112300
f0100716:	68 00 23 11 f0       	push   $0xf0112300
f010071b:	68 68 1d 10 f0       	push   $0xf0101d68
f0100720:	e8 43 02 00 00       	call   f0100968 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 44 29 11 00       	push   $0x112944
f010072d:	68 44 29 11 f0       	push   $0xf0112944
f0100732:	68 8c 1d 10 f0       	push   $0xf0101d8c
f0100737:	e8 2c 02 00 00       	call   f0100968 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010073c:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100741:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100746:	83 c4 08             	add    $0x8,%esp
f0100749:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010074e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100754:	85 c0                	test   %eax,%eax
f0100756:	0f 48 c2             	cmovs  %edx,%eax
f0100759:	c1 f8 0a             	sar    $0xa,%eax
f010075c:	50                   	push   %eax
f010075d:	68 b0 1d 10 f0       	push   $0xf0101db0
f0100762:	e8 01 02 00 00       	call   f0100968 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100767:	b8 00 00 00 00       	mov    $0x0,%eax
f010076c:	c9                   	leave  
f010076d:	c3                   	ret    

f010076e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076e:	55                   	push   %ebp
f010076f:	89 e5                	mov    %esp,%ebp
f0100771:	56                   	push   %esi
f0100772:	53                   	push   %ebx
f0100773:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100776:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f0100778:	68 6e 1c 10 f0       	push   $0xf0101c6e
f010077d:	e8 e6 01 00 00       	call   f0100968 <cprintf>
	while(p)
f0100782:	83 c4 10             	add    $0x10,%esp
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
		debuginfo_eip(*(p+1), &info);
f0100785:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f0100788:	eb 4e                	jmp    f01007d8 <mon_backtrace+0x6a>
	{
	 	struct Eipdebuginfo info;
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",p, *(p+1),*(p+2),*(p+3),*(p+4),*(p+5),*(p+6));
f010078a:	ff 73 18             	pushl  0x18(%ebx)
f010078d:	ff 73 14             	pushl  0x14(%ebx)
f0100790:	ff 73 10             	pushl  0x10(%ebx)
f0100793:	ff 73 0c             	pushl  0xc(%ebx)
f0100796:	ff 73 08             	pushl  0x8(%ebx)
f0100799:	ff 73 04             	pushl  0x4(%ebx)
f010079c:	53                   	push   %ebx
f010079d:	68 dc 1d 10 f0       	push   $0xf0101ddc
f01007a2:	e8 c1 01 00 00       	call   f0100968 <cprintf>
		debuginfo_eip(*(p+1), &info);
f01007a7:	83 c4 18             	add    $0x18,%esp
f01007aa:	56                   	push   %esi
f01007ab:	ff 73 04             	pushl  0x4(%ebx)
f01007ae:	e8 bf 02 00 00       	call   f0100a72 <debuginfo_eip>
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
f01007b3:	83 c4 08             	add    $0x8,%esp
f01007b6:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b9:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007bc:	50                   	push   %eax
f01007bd:	ff 75 e8             	pushl  -0x18(%ebp)
f01007c0:	ff 75 ec             	pushl  -0x14(%ebp)
f01007c3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01007c6:	ff 75 e0             	pushl  -0x20(%ebp)
f01007c9:	68 80 1c 10 f0       	push   $0xf0101c80
f01007ce:	e8 95 01 00 00       	call   f0100968 <cprintf>
		p=(uint32_t*)*p;
f01007d3:	8b 1b                	mov    (%ebx),%ebx
f01007d5:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* p=(uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while(p)
f01007d8:	85 db                	test   %ebx,%ebx
f01007da:	75 ae                	jne    f010078a <mon_backtrace+0x1c>
		debuginfo_eip(*(p+1), &info);
		cprintf("\t%s:%d : %.*s+%u\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (*(p+1)-info.eip_fn_addr));
		p=(uint32_t*)*p;
	}
	return 0;
}
f01007dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007e4:	5b                   	pop    %ebx
f01007e5:	5e                   	pop    %esi
f01007e6:	5d                   	pop    %ebp
f01007e7:	c3                   	ret    

f01007e8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e8:	55                   	push   %ebp
f01007e9:	89 e5                	mov    %esp,%ebp
f01007eb:	57                   	push   %edi
f01007ec:	56                   	push   %esi
f01007ed:	53                   	push   %ebx
f01007ee:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f1:	68 10 1e 10 f0       	push   $0xf0101e10
f01007f6:	e8 6d 01 00 00       	call   f0100968 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007fb:	c7 04 24 34 1e 10 f0 	movl   $0xf0101e34,(%esp)
f0100802:	e8 61 01 00 00       	call   f0100968 <cprintf>
f0100807:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010080a:	83 ec 0c             	sub    $0xc,%esp
f010080d:	68 92 1c 10 f0       	push   $0xf0101c92
f0100812:	e8 3d 0a 00 00       	call   f0101254 <readline>
f0100817:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100819:	83 c4 10             	add    $0x10,%esp
f010081c:	85 c0                	test   %eax,%eax
f010081e:	74 ea                	je     f010080a <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100820:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100827:	be 00 00 00 00       	mov    $0x0,%esi
f010082c:	eb 0a                	jmp    f0100838 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010082e:	c6 03 00             	movb   $0x0,(%ebx)
f0100831:	89 f7                	mov    %esi,%edi
f0100833:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100836:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100838:	0f b6 03             	movzbl (%ebx),%eax
f010083b:	84 c0                	test   %al,%al
f010083d:	74 63                	je     f01008a2 <monitor+0xba>
f010083f:	83 ec 08             	sub    $0x8,%esp
f0100842:	0f be c0             	movsbl %al,%eax
f0100845:	50                   	push   %eax
f0100846:	68 96 1c 10 f0       	push   $0xf0101c96
f010084b:	e8 1e 0c 00 00       	call   f010146e <strchr>
f0100850:	83 c4 10             	add    $0x10,%esp
f0100853:	85 c0                	test   %eax,%eax
f0100855:	75 d7                	jne    f010082e <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100857:	80 3b 00             	cmpb   $0x0,(%ebx)
f010085a:	74 46                	je     f01008a2 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010085c:	83 fe 0f             	cmp    $0xf,%esi
f010085f:	75 14                	jne    f0100875 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100861:	83 ec 08             	sub    $0x8,%esp
f0100864:	6a 10                	push   $0x10
f0100866:	68 9b 1c 10 f0       	push   $0xf0101c9b
f010086b:	e8 f8 00 00 00       	call   f0100968 <cprintf>
f0100870:	83 c4 10             	add    $0x10,%esp
f0100873:	eb 95                	jmp    f010080a <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100875:	8d 7e 01             	lea    0x1(%esi),%edi
f0100878:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010087c:	eb 03                	jmp    f0100881 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010087e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100881:	0f b6 03             	movzbl (%ebx),%eax
f0100884:	84 c0                	test   %al,%al
f0100886:	74 ae                	je     f0100836 <monitor+0x4e>
f0100888:	83 ec 08             	sub    $0x8,%esp
f010088b:	0f be c0             	movsbl %al,%eax
f010088e:	50                   	push   %eax
f010088f:	68 96 1c 10 f0       	push   $0xf0101c96
f0100894:	e8 d5 0b 00 00       	call   f010146e <strchr>
f0100899:	83 c4 10             	add    $0x10,%esp
f010089c:	85 c0                	test   %eax,%eax
f010089e:	74 de                	je     f010087e <monitor+0x96>
f01008a0:	eb 94                	jmp    f0100836 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008a2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008aa:	85 f6                	test   %esi,%esi
f01008ac:	0f 84 58 ff ff ff    	je     f010080a <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b2:	83 ec 08             	sub    $0x8,%esp
f01008b5:	68 3e 1c 10 f0       	push   $0xf0101c3e
f01008ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bd:	e8 4e 0b 00 00       	call   f0101410 <strcmp>
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 1e                	je     f01008e7 <monitor+0xff>
f01008c9:	83 ec 08             	sub    $0x8,%esp
f01008cc:	68 4c 1c 10 f0       	push   $0xf0101c4c
f01008d1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d4:	e8 37 0b 00 00       	call   f0101410 <strcmp>
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	75 2f                	jne    f010090f <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008e0:	b8 01 00 00 00       	mov    $0x1,%eax
f01008e5:	eb 05                	jmp    f01008ec <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008e7:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ec:	83 ec 04             	sub    $0x4,%esp
f01008ef:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008f2:	01 d0                	add    %edx,%eax
f01008f4:	ff 75 08             	pushl  0x8(%ebp)
f01008f7:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008fa:	51                   	push   %ecx
f01008fb:	56                   	push   %esi
f01008fc:	ff 14 85 64 1e 10 f0 	call   *-0xfefe19c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100903:	83 c4 10             	add    $0x10,%esp
f0100906:	85 c0                	test   %eax,%eax
f0100908:	78 1d                	js     f0100927 <monitor+0x13f>
f010090a:	e9 fb fe ff ff       	jmp    f010080a <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010090f:	83 ec 08             	sub    $0x8,%esp
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	68 b8 1c 10 f0       	push   $0xf0101cb8
f010091a:	e8 49 00 00 00       	call   f0100968 <cprintf>
f010091f:	83 c4 10             	add    $0x10,%esp
f0100922:	e9 e3 fe ff ff       	jmp    f010080a <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100927:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010092a:	5b                   	pop    %ebx
f010092b:	5e                   	pop    %esi
f010092c:	5f                   	pop    %edi
f010092d:	5d                   	pop    %ebp
f010092e:	c3                   	ret    

f010092f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010092f:	55                   	push   %ebp
f0100930:	89 e5                	mov    %esp,%ebp
f0100932:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100935:	ff 75 08             	pushl  0x8(%ebp)
f0100938:	e8 1e fd ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f010093d:	83 c4 10             	add    $0x10,%esp
f0100940:	c9                   	leave  
f0100941:	c3                   	ret    

f0100942 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100942:	55                   	push   %ebp
f0100943:	89 e5                	mov    %esp,%ebp
f0100945:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100948:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010094f:	ff 75 0c             	pushl  0xc(%ebp)
f0100952:	ff 75 08             	pushl  0x8(%ebp)
f0100955:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100958:	50                   	push   %eax
f0100959:	68 2f 09 10 f0       	push   $0xf010092f
f010095e:	e8 23 04 00 00       	call   f0100d86 <vprintfmt>
	return cnt;
}
f0100963:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100966:	c9                   	leave  
f0100967:	c3                   	ret    

f0100968 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100968:	55                   	push   %ebp
f0100969:	89 e5                	mov    %esp,%ebp
f010096b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010096e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100971:	50                   	push   %eax
f0100972:	ff 75 08             	pushl  0x8(%ebp)
f0100975:	e8 c8 ff ff ff       	call   f0100942 <vcprintf>
	va_end(ap);

	return cnt;
}
f010097a:	c9                   	leave  
f010097b:	c3                   	ret    

f010097c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010097c:	55                   	push   %ebp
f010097d:	89 e5                	mov    %esp,%ebp
f010097f:	57                   	push   %edi
f0100980:	56                   	push   %esi
f0100981:	53                   	push   %ebx
f0100982:	83 ec 14             	sub    $0x14,%esp
f0100985:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100988:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010098b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010098e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100991:	8b 1a                	mov    (%edx),%ebx
f0100993:	8b 01                	mov    (%ecx),%eax
f0100995:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100998:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010099f:	eb 7f                	jmp    f0100a20 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009a4:	01 d8                	add    %ebx,%eax
f01009a6:	89 c6                	mov    %eax,%esi
f01009a8:	c1 ee 1f             	shr    $0x1f,%esi
f01009ab:	01 c6                	add    %eax,%esi
f01009ad:	d1 fe                	sar    %esi
f01009af:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009b2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009b5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009b8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ba:	eb 03                	jmp    f01009bf <stab_binsearch+0x43>
			m--;
f01009bc:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009bf:	39 c3                	cmp    %eax,%ebx
f01009c1:	7f 0d                	jg     f01009d0 <stab_binsearch+0x54>
f01009c3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009c7:	83 ea 0c             	sub    $0xc,%edx
f01009ca:	39 f9                	cmp    %edi,%ecx
f01009cc:	75 ee                	jne    f01009bc <stab_binsearch+0x40>
f01009ce:	eb 05                	jmp    f01009d5 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009d0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009d3:	eb 4b                	jmp    f0100a20 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009d5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009d8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009db:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009df:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009e2:	76 11                	jbe    f01009f5 <stab_binsearch+0x79>
			*region_left = m;
f01009e4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009e7:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009e9:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009ec:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009f3:	eb 2b                	jmp    f0100a20 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009f5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009f8:	73 14                	jae    f0100a0e <stab_binsearch+0x92>
			*region_right = m - 1;
f01009fa:	83 e8 01             	sub    $0x1,%eax
f01009fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a00:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a03:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a05:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a0c:	eb 12                	jmp    f0100a20 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a0e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a11:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a13:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a17:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a19:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a20:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a23:	0f 8e 78 ff ff ff    	jle    f01009a1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a29:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a2d:	75 0f                	jne    f0100a3e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a32:	8b 00                	mov    (%eax),%eax
f0100a34:	83 e8 01             	sub    $0x1,%eax
f0100a37:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a3a:	89 06                	mov    %eax,(%esi)
f0100a3c:	eb 2c                	jmp    f0100a6a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a3e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a41:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a43:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a46:	8b 0e                	mov    (%esi),%ecx
f0100a48:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a4b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a4e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a51:	eb 03                	jmp    f0100a56 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a53:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a56:	39 c8                	cmp    %ecx,%eax
f0100a58:	7e 0b                	jle    f0100a65 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a5a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a5e:	83 ea 0c             	sub    $0xc,%edx
f0100a61:	39 df                	cmp    %ebx,%edi
f0100a63:	75 ee                	jne    f0100a53 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a65:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a68:	89 06                	mov    %eax,(%esi)
	}
}
f0100a6a:	83 c4 14             	add    $0x14,%esp
f0100a6d:	5b                   	pop    %ebx
f0100a6e:	5e                   	pop    %esi
f0100a6f:	5f                   	pop    %edi
f0100a70:	5d                   	pop    %ebp
f0100a71:	c3                   	ret    

f0100a72 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a72:	55                   	push   %ebp
f0100a73:	89 e5                	mov    %esp,%ebp
f0100a75:	57                   	push   %edi
f0100a76:	56                   	push   %esi
f0100a77:	53                   	push   %ebx
f0100a78:	83 ec 3c             	sub    $0x3c,%esp
f0100a7b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a7e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a81:	c7 03 74 1e 10 f0    	movl   $0xf0101e74,(%ebx)
	info->eip_line = 0;
f0100a87:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a8e:	c7 43 08 74 1e 10 f0 	movl   $0xf0101e74,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a95:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a9c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a9f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aa6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100aac:	76 11                	jbe    f0100abf <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aae:	b8 bb 73 10 f0       	mov    $0xf01073bb,%eax
f0100ab3:	3d cd 5a 10 f0       	cmp    $0xf0105acd,%eax
f0100ab8:	77 19                	ja     f0100ad3 <debuginfo_eip+0x61>
f0100aba:	e9 b5 01 00 00       	jmp    f0100c74 <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100abf:	83 ec 04             	sub    $0x4,%esp
f0100ac2:	68 7e 1e 10 f0       	push   $0xf0101e7e
f0100ac7:	6a 7f                	push   $0x7f
f0100ac9:	68 8b 1e 10 f0       	push   $0xf0101e8b
f0100ace:	e8 13 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ad3:	80 3d ba 73 10 f0 00 	cmpb   $0x0,0xf01073ba
f0100ada:	0f 85 9b 01 00 00    	jne    f0100c7b <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ae0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ae7:	b8 cc 5a 10 f0       	mov    $0xf0105acc,%eax
f0100aec:	2d ac 20 10 f0       	sub    $0xf01020ac,%eax
f0100af1:	c1 f8 02             	sar    $0x2,%eax
f0100af4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100afa:	83 e8 01             	sub    $0x1,%eax
f0100afd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b00:	83 ec 08             	sub    $0x8,%esp
f0100b03:	56                   	push   %esi
f0100b04:	6a 64                	push   $0x64
f0100b06:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b09:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b0c:	b8 ac 20 10 f0       	mov    $0xf01020ac,%eax
f0100b11:	e8 66 fe ff ff       	call   f010097c <stab_binsearch>
	if (lfile == 0)
f0100b16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b19:	83 c4 10             	add    $0x10,%esp
f0100b1c:	85 c0                	test   %eax,%eax
f0100b1e:	0f 84 5e 01 00 00    	je     f0100c82 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b24:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b27:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b2a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b2d:	83 ec 08             	sub    $0x8,%esp
f0100b30:	56                   	push   %esi
f0100b31:	6a 24                	push   $0x24
f0100b33:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b36:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b39:	b8 ac 20 10 f0       	mov    $0xf01020ac,%eax
f0100b3e:	e8 39 fe ff ff       	call   f010097c <stab_binsearch>

	if (lfun <= rfun) {
f0100b43:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b46:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b49:	83 c4 10             	add    $0x10,%esp
f0100b4c:	39 d0                	cmp    %edx,%eax
f0100b4e:	7f 40                	jg     f0100b90 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b50:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b53:	c1 e1 02             	shl    $0x2,%ecx
f0100b56:	8d b9 ac 20 10 f0    	lea    -0xfefdf54(%ecx),%edi
f0100b5c:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b5f:	8b b9 ac 20 10 f0    	mov    -0xfefdf54(%ecx),%edi
f0100b65:	b9 bb 73 10 f0       	mov    $0xf01073bb,%ecx
f0100b6a:	81 e9 cd 5a 10 f0    	sub    $0xf0105acd,%ecx
f0100b70:	39 cf                	cmp    %ecx,%edi
f0100b72:	73 09                	jae    f0100b7d <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b74:	81 c7 cd 5a 10 f0    	add    $0xf0105acd,%edi
f0100b7a:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b7d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b80:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b83:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b86:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b88:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b8b:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b8e:	eb 0f                	jmp    f0100b9f <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b90:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b96:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100b99:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b9c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b9f:	83 ec 08             	sub    $0x8,%esp
f0100ba2:	6a 3a                	push   $0x3a
f0100ba4:	ff 73 08             	pushl  0x8(%ebx)
f0100ba7:	e8 e3 08 00 00       	call   f010148f <strfind>
f0100bac:	2b 43 08             	sub    0x8(%ebx),%eax
f0100baf:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bb2:	83 c4 08             	add    $0x8,%esp
f0100bb5:	56                   	push   %esi
f0100bb6:	6a 44                	push   $0x44
f0100bb8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bbb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bbe:	b8 ac 20 10 f0       	mov    $0xf01020ac,%eax
f0100bc3:	e8 b4 fd ff ff       	call   f010097c <stab_binsearch>
        if(lline > rline)
f0100bc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bcb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100bce:	83 c4 10             	add    $0x10,%esp
f0100bd1:	39 d0                	cmp    %edx,%eax
f0100bd3:	0f 8f b0 00 00 00    	jg     f0100c89 <debuginfo_eip+0x217>
        return -1;
	info->eip_line = stabs[rline].n_desc;
f0100bd9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100bdc:	0f b7 14 95 b2 20 10 	movzwl -0xfefdf4e(,%edx,4),%edx
f0100be3:	f0 
f0100be4:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bea:	89 c2                	mov    %eax,%edx
f0100bec:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bef:	8d 04 85 ac 20 10 f0 	lea    -0xfefdf54(,%eax,4),%eax
f0100bf6:	eb 06                	jmp    f0100bfe <debuginfo_eip+0x18c>
f0100bf8:	83 ea 01             	sub    $0x1,%edx
f0100bfb:	83 e8 0c             	sub    $0xc,%eax
f0100bfe:	39 d7                	cmp    %edx,%edi
f0100c00:	7f 34                	jg     f0100c36 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100c02:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c06:	80 f9 84             	cmp    $0x84,%cl
f0100c09:	74 0b                	je     f0100c16 <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c0b:	80 f9 64             	cmp    $0x64,%cl
f0100c0e:	75 e8                	jne    f0100bf8 <debuginfo_eip+0x186>
f0100c10:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c14:	74 e2                	je     f0100bf8 <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c16:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c19:	8b 14 85 ac 20 10 f0 	mov    -0xfefdf54(,%eax,4),%edx
f0100c20:	b8 bb 73 10 f0       	mov    $0xf01073bb,%eax
f0100c25:	2d cd 5a 10 f0       	sub    $0xf0105acd,%eax
f0100c2a:	39 c2                	cmp    %eax,%edx
f0100c2c:	73 08                	jae    f0100c36 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c2e:	81 c2 cd 5a 10 f0    	add    $0xf0105acd,%edx
f0100c34:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c36:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c39:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c3c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c41:	39 f2                	cmp    %esi,%edx
f0100c43:	7d 50                	jge    f0100c95 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0100c45:	83 c2 01             	add    $0x1,%edx
f0100c48:	89 d0                	mov    %edx,%eax
f0100c4a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c4d:	8d 14 95 ac 20 10 f0 	lea    -0xfefdf54(,%edx,4),%edx
f0100c54:	eb 04                	jmp    f0100c5a <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c56:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c5a:	39 c6                	cmp    %eax,%esi
f0100c5c:	7e 32                	jle    f0100c90 <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c5e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c62:	83 c0 01             	add    $0x1,%eax
f0100c65:	83 c2 0c             	add    $0xc,%edx
f0100c68:	80 f9 a0             	cmp    $0xa0,%cl
f0100c6b:	74 e9                	je     f0100c56 <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c72:	eb 21                	jmp    f0100c95 <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c79:	eb 1a                	jmp    f0100c95 <debuginfo_eip+0x223>
f0100c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c80:	eb 13                	jmp    f0100c95 <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c87:	eb 0c                	jmp    f0100c95 <debuginfo_eip+0x223>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
        if(lline > rline)
        return -1;
f0100c89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c8e:	eb 05                	jmp    f0100c95 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c90:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c95:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c98:	5b                   	pop    %ebx
f0100c99:	5e                   	pop    %esi
f0100c9a:	5f                   	pop    %edi
f0100c9b:	5d                   	pop    %ebp
f0100c9c:	c3                   	ret    

f0100c9d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c9d:	55                   	push   %ebp
f0100c9e:	89 e5                	mov    %esp,%ebp
f0100ca0:	57                   	push   %edi
f0100ca1:	56                   	push   %esi
f0100ca2:	53                   	push   %ebx
f0100ca3:	83 ec 1c             	sub    $0x1c,%esp
f0100ca6:	89 c7                	mov    %eax,%edi
f0100ca8:	89 d6                	mov    %edx,%esi
f0100caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cad:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cb3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cb6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cb9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cbe:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cc1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cc4:	39 d3                	cmp    %edx,%ebx
f0100cc6:	72 05                	jb     f0100ccd <printnum+0x30>
f0100cc8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ccb:	77 45                	ja     f0100d12 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ccd:	83 ec 0c             	sub    $0xc,%esp
f0100cd0:	ff 75 18             	pushl  0x18(%ebp)
f0100cd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cd6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cd9:	53                   	push   %ebx
f0100cda:	ff 75 10             	pushl  0x10(%ebp)
f0100cdd:	83 ec 08             	sub    $0x8,%esp
f0100ce0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ce3:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ce6:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ce9:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cec:	e8 bf 09 00 00       	call   f01016b0 <__udivdi3>
f0100cf1:	83 c4 18             	add    $0x18,%esp
f0100cf4:	52                   	push   %edx
f0100cf5:	50                   	push   %eax
f0100cf6:	89 f2                	mov    %esi,%edx
f0100cf8:	89 f8                	mov    %edi,%eax
f0100cfa:	e8 9e ff ff ff       	call   f0100c9d <printnum>
f0100cff:	83 c4 20             	add    $0x20,%esp
f0100d02:	eb 18                	jmp    f0100d1c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d04:	83 ec 08             	sub    $0x8,%esp
f0100d07:	56                   	push   %esi
f0100d08:	ff 75 18             	pushl  0x18(%ebp)
f0100d0b:	ff d7                	call   *%edi
f0100d0d:	83 c4 10             	add    $0x10,%esp
f0100d10:	eb 03                	jmp    f0100d15 <printnum+0x78>
f0100d12:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d15:	83 eb 01             	sub    $0x1,%ebx
f0100d18:	85 db                	test   %ebx,%ebx
f0100d1a:	7f e8                	jg     f0100d04 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d1c:	83 ec 08             	sub    $0x8,%esp
f0100d1f:	56                   	push   %esi
f0100d20:	83 ec 04             	sub    $0x4,%esp
f0100d23:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d26:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d29:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d2c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d2f:	e8 ac 0a 00 00       	call   f01017e0 <__umoddi3>
f0100d34:	83 c4 14             	add    $0x14,%esp
f0100d37:	0f be 80 99 1e 10 f0 	movsbl -0xfefe167(%eax),%eax
f0100d3e:	50                   	push   %eax
f0100d3f:	ff d7                	call   *%edi
}
f0100d41:	83 c4 10             	add    $0x10,%esp
f0100d44:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d47:	5b                   	pop    %ebx
f0100d48:	5e                   	pop    %esi
f0100d49:	5f                   	pop    %edi
f0100d4a:	5d                   	pop    %ebp
f0100d4b:	c3                   	ret    

f0100d4c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d4c:	55                   	push   %ebp
f0100d4d:	89 e5                	mov    %esp,%ebp
f0100d4f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d52:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d56:	8b 10                	mov    (%eax),%edx
f0100d58:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d5b:	73 0a                	jae    f0100d67 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d5d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d60:	89 08                	mov    %ecx,(%eax)
f0100d62:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d65:	88 02                	mov    %al,(%edx)
}
f0100d67:	5d                   	pop    %ebp
f0100d68:	c3                   	ret    

f0100d69 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d69:	55                   	push   %ebp
f0100d6a:	89 e5                	mov    %esp,%ebp
f0100d6c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d6f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d72:	50                   	push   %eax
f0100d73:	ff 75 10             	pushl  0x10(%ebp)
f0100d76:	ff 75 0c             	pushl  0xc(%ebp)
f0100d79:	ff 75 08             	pushl  0x8(%ebp)
f0100d7c:	e8 05 00 00 00       	call   f0100d86 <vprintfmt>
	va_end(ap);
}
f0100d81:	83 c4 10             	add    $0x10,%esp
f0100d84:	c9                   	leave  
f0100d85:	c3                   	ret    

f0100d86 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d86:	55                   	push   %ebp
f0100d87:	89 e5                	mov    %esp,%ebp
f0100d89:	57                   	push   %edi
f0100d8a:	56                   	push   %esi
f0100d8b:	53                   	push   %ebx
f0100d8c:	83 ec 2c             	sub    $0x2c,%esp
f0100d8f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d92:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d95:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d98:	eb 12                	jmp    f0100dac <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d9a:	85 c0                	test   %eax,%eax
f0100d9c:	0f 84 42 04 00 00    	je     f01011e4 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100da2:	83 ec 08             	sub    $0x8,%esp
f0100da5:	53                   	push   %ebx
f0100da6:	50                   	push   %eax
f0100da7:	ff d6                	call   *%esi
f0100da9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dac:	83 c7 01             	add    $0x1,%edi
f0100daf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100db3:	83 f8 25             	cmp    $0x25,%eax
f0100db6:	75 e2                	jne    f0100d9a <vprintfmt+0x14>
f0100db8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100dbc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dc3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dca:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100dd1:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dd6:	eb 07                	jmp    f0100ddf <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dd8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ddb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ddf:	8d 47 01             	lea    0x1(%edi),%eax
f0100de2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100de5:	0f b6 07             	movzbl (%edi),%eax
f0100de8:	0f b6 d0             	movzbl %al,%edx
f0100deb:	83 e8 23             	sub    $0x23,%eax
f0100dee:	3c 55                	cmp    $0x55,%al
f0100df0:	0f 87 d3 03 00 00    	ja     f01011c9 <vprintfmt+0x443>
f0100df6:	0f b6 c0             	movzbl %al,%eax
f0100df9:	ff 24 85 28 1f 10 f0 	jmp    *-0xfefe0d8(,%eax,4)
f0100e00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e03:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e07:	eb d6                	jmp    f0100ddf <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e11:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e14:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e17:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100e1b:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100e1e:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100e21:	83 f9 09             	cmp    $0x9,%ecx
f0100e24:	77 3f                	ja     f0100e65 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e26:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e29:	eb e9                	jmp    f0100e14 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e2e:	8b 00                	mov    (%eax),%eax
f0100e30:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e33:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e36:	8d 40 04             	lea    0x4(%eax),%eax
f0100e39:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e3f:	eb 2a                	jmp    f0100e6b <vprintfmt+0xe5>
f0100e41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e44:	85 c0                	test   %eax,%eax
f0100e46:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e4b:	0f 49 d0             	cmovns %eax,%edx
f0100e4e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e54:	eb 89                	jmp    f0100ddf <vprintfmt+0x59>
f0100e56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e59:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e60:	e9 7a ff ff ff       	jmp    f0100ddf <vprintfmt+0x59>
f0100e65:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e68:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e6b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e6f:	0f 89 6a ff ff ff    	jns    f0100ddf <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e75:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e78:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e7b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e82:	e9 58 ff ff ff       	jmp    f0100ddf <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e87:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e8d:	e9 4d ff ff ff       	jmp    f0100ddf <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e92:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e95:	8d 78 04             	lea    0x4(%eax),%edi
f0100e98:	83 ec 08             	sub    $0x8,%esp
f0100e9b:	53                   	push   %ebx
f0100e9c:	ff 30                	pushl  (%eax)
f0100e9e:	ff d6                	call   *%esi
			break;
f0100ea0:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ea3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ea9:	e9 fe fe ff ff       	jmp    f0100dac <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eae:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eb1:	8d 78 04             	lea    0x4(%eax),%edi
f0100eb4:	8b 00                	mov    (%eax),%eax
f0100eb6:	99                   	cltd   
f0100eb7:	31 d0                	xor    %edx,%eax
f0100eb9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ebb:	83 f8 06             	cmp    $0x6,%eax
f0100ebe:	7f 0b                	jg     f0100ecb <vprintfmt+0x145>
f0100ec0:	8b 14 85 80 20 10 f0 	mov    -0xfefdf80(,%eax,4),%edx
f0100ec7:	85 d2                	test   %edx,%edx
f0100ec9:	75 1b                	jne    f0100ee6 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100ecb:	50                   	push   %eax
f0100ecc:	68 b1 1e 10 f0       	push   $0xf0101eb1
f0100ed1:	53                   	push   %ebx
f0100ed2:	56                   	push   %esi
f0100ed3:	e8 91 fe ff ff       	call   f0100d69 <printfmt>
f0100ed8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100edb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ede:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ee1:	e9 c6 fe ff ff       	jmp    f0100dac <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100ee6:	52                   	push   %edx
f0100ee7:	68 ba 1e 10 f0       	push   $0xf0101eba
f0100eec:	53                   	push   %ebx
f0100eed:	56                   	push   %esi
f0100eee:	e8 76 fe ff ff       	call   f0100d69 <printfmt>
f0100ef3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ef6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100efc:	e9 ab fe ff ff       	jmp    f0100dac <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f01:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f04:	83 c0 04             	add    $0x4,%eax
f0100f07:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f0f:	85 ff                	test   %edi,%edi
f0100f11:	b8 aa 1e 10 f0       	mov    $0xf0101eaa,%eax
f0100f16:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f19:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f1d:	0f 8e 94 00 00 00    	jle    f0100fb7 <vprintfmt+0x231>
f0100f23:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f27:	0f 84 98 00 00 00    	je     f0100fc5 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f2d:	83 ec 08             	sub    $0x8,%esp
f0100f30:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f33:	57                   	push   %edi
f0100f34:	e8 0c 04 00 00       	call   f0101345 <strnlen>
f0100f39:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f3c:	29 c1                	sub    %eax,%ecx
f0100f3e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100f41:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f44:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f48:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f4b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f4e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f50:	eb 0f                	jmp    f0100f61 <vprintfmt+0x1db>
					putch(padc, putdat);
f0100f52:	83 ec 08             	sub    $0x8,%esp
f0100f55:	53                   	push   %ebx
f0100f56:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f59:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f5b:	83 ef 01             	sub    $0x1,%edi
f0100f5e:	83 c4 10             	add    $0x10,%esp
f0100f61:	85 ff                	test   %edi,%edi
f0100f63:	7f ed                	jg     f0100f52 <vprintfmt+0x1cc>
f0100f65:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f68:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100f6b:	85 c9                	test   %ecx,%ecx
f0100f6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f72:	0f 49 c1             	cmovns %ecx,%eax
f0100f75:	29 c1                	sub    %eax,%ecx
f0100f77:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f7a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f7d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f80:	89 cb                	mov    %ecx,%ebx
f0100f82:	eb 4d                	jmp    f0100fd1 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f84:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f88:	74 1b                	je     f0100fa5 <vprintfmt+0x21f>
f0100f8a:	0f be c0             	movsbl %al,%eax
f0100f8d:	83 e8 20             	sub    $0x20,%eax
f0100f90:	83 f8 5e             	cmp    $0x5e,%eax
f0100f93:	76 10                	jbe    f0100fa5 <vprintfmt+0x21f>
					putch('?', putdat);
f0100f95:	83 ec 08             	sub    $0x8,%esp
f0100f98:	ff 75 0c             	pushl  0xc(%ebp)
f0100f9b:	6a 3f                	push   $0x3f
f0100f9d:	ff 55 08             	call   *0x8(%ebp)
f0100fa0:	83 c4 10             	add    $0x10,%esp
f0100fa3:	eb 0d                	jmp    f0100fb2 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100fa5:	83 ec 08             	sub    $0x8,%esp
f0100fa8:	ff 75 0c             	pushl  0xc(%ebp)
f0100fab:	52                   	push   %edx
f0100fac:	ff 55 08             	call   *0x8(%ebp)
f0100faf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb2:	83 eb 01             	sub    $0x1,%ebx
f0100fb5:	eb 1a                	jmp    f0100fd1 <vprintfmt+0x24b>
f0100fb7:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fba:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fbd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fc0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fc3:	eb 0c                	jmp    f0100fd1 <vprintfmt+0x24b>
f0100fc5:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fcb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fce:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fd1:	83 c7 01             	add    $0x1,%edi
f0100fd4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fd8:	0f be d0             	movsbl %al,%edx
f0100fdb:	85 d2                	test   %edx,%edx
f0100fdd:	74 23                	je     f0101002 <vprintfmt+0x27c>
f0100fdf:	85 f6                	test   %esi,%esi
f0100fe1:	78 a1                	js     f0100f84 <vprintfmt+0x1fe>
f0100fe3:	83 ee 01             	sub    $0x1,%esi
f0100fe6:	79 9c                	jns    f0100f84 <vprintfmt+0x1fe>
f0100fe8:	89 df                	mov    %ebx,%edi
f0100fea:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff0:	eb 18                	jmp    f010100a <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ff2:	83 ec 08             	sub    $0x8,%esp
f0100ff5:	53                   	push   %ebx
f0100ff6:	6a 20                	push   $0x20
f0100ff8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100ffa:	83 ef 01             	sub    $0x1,%edi
f0100ffd:	83 c4 10             	add    $0x10,%esp
f0101000:	eb 08                	jmp    f010100a <vprintfmt+0x284>
f0101002:	89 df                	mov    %ebx,%edi
f0101004:	8b 75 08             	mov    0x8(%ebp),%esi
f0101007:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010100a:	85 ff                	test   %edi,%edi
f010100c:	7f e4                	jg     f0100ff2 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010100e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101011:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101014:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101017:	e9 90 fd ff ff       	jmp    f0100dac <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010101c:	83 f9 01             	cmp    $0x1,%ecx
f010101f:	7e 19                	jle    f010103a <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0101021:	8b 45 14             	mov    0x14(%ebp),%eax
f0101024:	8b 50 04             	mov    0x4(%eax),%edx
f0101027:	8b 00                	mov    (%eax),%eax
f0101029:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010102c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010102f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101032:	8d 40 08             	lea    0x8(%eax),%eax
f0101035:	89 45 14             	mov    %eax,0x14(%ebp)
f0101038:	eb 38                	jmp    f0101072 <vprintfmt+0x2ec>
	else if (lflag)
f010103a:	85 c9                	test   %ecx,%ecx
f010103c:	74 1b                	je     f0101059 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f010103e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101041:	8b 00                	mov    (%eax),%eax
f0101043:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101046:	89 c1                	mov    %eax,%ecx
f0101048:	c1 f9 1f             	sar    $0x1f,%ecx
f010104b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010104e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101051:	8d 40 04             	lea    0x4(%eax),%eax
f0101054:	89 45 14             	mov    %eax,0x14(%ebp)
f0101057:	eb 19                	jmp    f0101072 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0101059:	8b 45 14             	mov    0x14(%ebp),%eax
f010105c:	8b 00                	mov    (%eax),%eax
f010105e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101061:	89 c1                	mov    %eax,%ecx
f0101063:	c1 f9 1f             	sar    $0x1f,%ecx
f0101066:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101069:	8b 45 14             	mov    0x14(%ebp),%eax
f010106c:	8d 40 04             	lea    0x4(%eax),%eax
f010106f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101072:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101075:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101078:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010107d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101081:	0f 89 0e 01 00 00    	jns    f0101195 <vprintfmt+0x40f>
				putch('-', putdat);
f0101087:	83 ec 08             	sub    $0x8,%esp
f010108a:	53                   	push   %ebx
f010108b:	6a 2d                	push   $0x2d
f010108d:	ff d6                	call   *%esi
				num = -(long long) num;
f010108f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101092:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101095:	f7 da                	neg    %edx
f0101097:	83 d1 00             	adc    $0x0,%ecx
f010109a:	f7 d9                	neg    %ecx
f010109c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010109f:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010a4:	e9 ec 00 00 00       	jmp    f0101195 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010a9:	83 f9 01             	cmp    $0x1,%ecx
f01010ac:	7e 18                	jle    f01010c6 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f01010ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b1:	8b 10                	mov    (%eax),%edx
f01010b3:	8b 48 04             	mov    0x4(%eax),%ecx
f01010b6:	8d 40 08             	lea    0x8(%eax),%eax
f01010b9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010bc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010c1:	e9 cf 00 00 00       	jmp    f0101195 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010c6:	85 c9                	test   %ecx,%ecx
f01010c8:	74 1a                	je     f01010e4 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f01010ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01010cd:	8b 10                	mov    (%eax),%edx
f01010cf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010d4:	8d 40 04             	lea    0x4(%eax),%eax
f01010d7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010da:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010df:	e9 b1 00 00 00       	jmp    f0101195 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e7:	8b 10                	mov    (%eax),%edx
f01010e9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010ee:	8d 40 04             	lea    0x4(%eax),%eax
f01010f1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010f4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010f9:	e9 97 00 00 00       	jmp    f0101195 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010fe:	83 ec 08             	sub    $0x8,%esp
f0101101:	53                   	push   %ebx
f0101102:	6a 58                	push   $0x58
f0101104:	ff d6                	call   *%esi
			putch('X', putdat);
f0101106:	83 c4 08             	add    $0x8,%esp
f0101109:	53                   	push   %ebx
f010110a:	6a 58                	push   $0x58
f010110c:	ff d6                	call   *%esi
			putch('X', putdat);
f010110e:	83 c4 08             	add    $0x8,%esp
f0101111:	53                   	push   %ebx
f0101112:	6a 58                	push   $0x58
f0101114:	ff d6                	call   *%esi
			break;
f0101116:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101119:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f010111c:	e9 8b fc ff ff       	jmp    f0100dac <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101121:	83 ec 08             	sub    $0x8,%esp
f0101124:	53                   	push   %ebx
f0101125:	6a 30                	push   $0x30
f0101127:	ff d6                	call   *%esi
			putch('x', putdat);
f0101129:	83 c4 08             	add    $0x8,%esp
f010112c:	53                   	push   %ebx
f010112d:	6a 78                	push   $0x78
f010112f:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101131:	8b 45 14             	mov    0x14(%ebp),%eax
f0101134:	8b 10                	mov    (%eax),%edx
f0101136:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010113b:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010113e:	8d 40 04             	lea    0x4(%eax),%eax
f0101141:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101144:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101149:	eb 4a                	jmp    f0101195 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010114b:	83 f9 01             	cmp    $0x1,%ecx
f010114e:	7e 15                	jle    f0101165 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0101150:	8b 45 14             	mov    0x14(%ebp),%eax
f0101153:	8b 10                	mov    (%eax),%edx
f0101155:	8b 48 04             	mov    0x4(%eax),%ecx
f0101158:	8d 40 08             	lea    0x8(%eax),%eax
f010115b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010115e:	b8 10 00 00 00       	mov    $0x10,%eax
f0101163:	eb 30                	jmp    f0101195 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101165:	85 c9                	test   %ecx,%ecx
f0101167:	74 17                	je     f0101180 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0101169:	8b 45 14             	mov    0x14(%ebp),%eax
f010116c:	8b 10                	mov    (%eax),%edx
f010116e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101173:	8d 40 04             	lea    0x4(%eax),%eax
f0101176:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101179:	b8 10 00 00 00       	mov    $0x10,%eax
f010117e:	eb 15                	jmp    f0101195 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101180:	8b 45 14             	mov    0x14(%ebp),%eax
f0101183:	8b 10                	mov    (%eax),%edx
f0101185:	b9 00 00 00 00       	mov    $0x0,%ecx
f010118a:	8d 40 04             	lea    0x4(%eax),%eax
f010118d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101190:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101195:	83 ec 0c             	sub    $0xc,%esp
f0101198:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010119c:	57                   	push   %edi
f010119d:	ff 75 e0             	pushl  -0x20(%ebp)
f01011a0:	50                   	push   %eax
f01011a1:	51                   	push   %ecx
f01011a2:	52                   	push   %edx
f01011a3:	89 da                	mov    %ebx,%edx
f01011a5:	89 f0                	mov    %esi,%eax
f01011a7:	e8 f1 fa ff ff       	call   f0100c9d <printnum>
			break;
f01011ac:	83 c4 20             	add    $0x20,%esp
f01011af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01011b2:	e9 f5 fb ff ff       	jmp    f0100dac <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011b7:	83 ec 08             	sub    $0x8,%esp
f01011ba:	53                   	push   %ebx
f01011bb:	52                   	push   %edx
f01011bc:	ff d6                	call   *%esi
			break;
f01011be:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011c4:	e9 e3 fb ff ff       	jmp    f0100dac <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011c9:	83 ec 08             	sub    $0x8,%esp
f01011cc:	53                   	push   %ebx
f01011cd:	6a 25                	push   $0x25
f01011cf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011d1:	83 c4 10             	add    $0x10,%esp
f01011d4:	eb 03                	jmp    f01011d9 <vprintfmt+0x453>
f01011d6:	83 ef 01             	sub    $0x1,%edi
f01011d9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011dd:	75 f7                	jne    f01011d6 <vprintfmt+0x450>
f01011df:	e9 c8 fb ff ff       	jmp    f0100dac <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011e7:	5b                   	pop    %ebx
f01011e8:	5e                   	pop    %esi
f01011e9:	5f                   	pop    %edi
f01011ea:	5d                   	pop    %ebp
f01011eb:	c3                   	ret    

f01011ec <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011ec:	55                   	push   %ebp
f01011ed:	89 e5                	mov    %esp,%ebp
f01011ef:	83 ec 18             	sub    $0x18,%esp
f01011f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011fb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011ff:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101202:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101209:	85 c0                	test   %eax,%eax
f010120b:	74 26                	je     f0101233 <vsnprintf+0x47>
f010120d:	85 d2                	test   %edx,%edx
f010120f:	7e 22                	jle    f0101233 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101211:	ff 75 14             	pushl  0x14(%ebp)
f0101214:	ff 75 10             	pushl  0x10(%ebp)
f0101217:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010121a:	50                   	push   %eax
f010121b:	68 4c 0d 10 f0       	push   $0xf0100d4c
f0101220:	e8 61 fb ff ff       	call   f0100d86 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101225:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101228:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010122b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010122e:	83 c4 10             	add    $0x10,%esp
f0101231:	eb 05                	jmp    f0101238 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101233:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101238:	c9                   	leave  
f0101239:	c3                   	ret    

f010123a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010123a:	55                   	push   %ebp
f010123b:	89 e5                	mov    %esp,%ebp
f010123d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101240:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101243:	50                   	push   %eax
f0101244:	ff 75 10             	pushl  0x10(%ebp)
f0101247:	ff 75 0c             	pushl  0xc(%ebp)
f010124a:	ff 75 08             	pushl  0x8(%ebp)
f010124d:	e8 9a ff ff ff       	call   f01011ec <vsnprintf>
	va_end(ap);

	return rc;
}
f0101252:	c9                   	leave  
f0101253:	c3                   	ret    

f0101254 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101254:	55                   	push   %ebp
f0101255:	89 e5                	mov    %esp,%ebp
f0101257:	57                   	push   %edi
f0101258:	56                   	push   %esi
f0101259:	53                   	push   %ebx
f010125a:	83 ec 0c             	sub    $0xc,%esp
f010125d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101260:	85 c0                	test   %eax,%eax
f0101262:	74 11                	je     f0101275 <readline+0x21>
		cprintf("%s", prompt);
f0101264:	83 ec 08             	sub    $0x8,%esp
f0101267:	50                   	push   %eax
f0101268:	68 ba 1e 10 f0       	push   $0xf0101eba
f010126d:	e8 f6 f6 ff ff       	call   f0100968 <cprintf>
f0101272:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101275:	83 ec 0c             	sub    $0xc,%esp
f0101278:	6a 00                	push   $0x0
f010127a:	e8 fd f3 ff ff       	call   f010067c <iscons>
f010127f:	89 c7                	mov    %eax,%edi
f0101281:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101284:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101289:	e8 dd f3 ff ff       	call   f010066b <getchar>
f010128e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101290:	85 c0                	test   %eax,%eax
f0101292:	79 18                	jns    f01012ac <readline+0x58>
			cprintf("read error: %e\n", c);
f0101294:	83 ec 08             	sub    $0x8,%esp
f0101297:	50                   	push   %eax
f0101298:	68 9c 20 10 f0       	push   $0xf010209c
f010129d:	e8 c6 f6 ff ff       	call   f0100968 <cprintf>
			return NULL;
f01012a2:	83 c4 10             	add    $0x10,%esp
f01012a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012aa:	eb 79                	jmp    f0101325 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012ac:	83 f8 08             	cmp    $0x8,%eax
f01012af:	0f 94 c2             	sete   %dl
f01012b2:	83 f8 7f             	cmp    $0x7f,%eax
f01012b5:	0f 94 c0             	sete   %al
f01012b8:	08 c2                	or     %al,%dl
f01012ba:	74 1a                	je     f01012d6 <readline+0x82>
f01012bc:	85 f6                	test   %esi,%esi
f01012be:	7e 16                	jle    f01012d6 <readline+0x82>
			if (echoing)
f01012c0:	85 ff                	test   %edi,%edi
f01012c2:	74 0d                	je     f01012d1 <readline+0x7d>
				cputchar('\b');
f01012c4:	83 ec 0c             	sub    $0xc,%esp
f01012c7:	6a 08                	push   $0x8
f01012c9:	e8 8d f3 ff ff       	call   f010065b <cputchar>
f01012ce:	83 c4 10             	add    $0x10,%esp
			i--;
f01012d1:	83 ee 01             	sub    $0x1,%esi
f01012d4:	eb b3                	jmp    f0101289 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012d6:	83 fb 1f             	cmp    $0x1f,%ebx
f01012d9:	7e 23                	jle    f01012fe <readline+0xaa>
f01012db:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012e1:	7f 1b                	jg     f01012fe <readline+0xaa>
			if (echoing)
f01012e3:	85 ff                	test   %edi,%edi
f01012e5:	74 0c                	je     f01012f3 <readline+0x9f>
				cputchar(c);
f01012e7:	83 ec 0c             	sub    $0xc,%esp
f01012ea:	53                   	push   %ebx
f01012eb:	e8 6b f3 ff ff       	call   f010065b <cputchar>
f01012f0:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012f3:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012f9:	8d 76 01             	lea    0x1(%esi),%esi
f01012fc:	eb 8b                	jmp    f0101289 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012fe:	83 fb 0a             	cmp    $0xa,%ebx
f0101301:	74 05                	je     f0101308 <readline+0xb4>
f0101303:	83 fb 0d             	cmp    $0xd,%ebx
f0101306:	75 81                	jne    f0101289 <readline+0x35>
			if (echoing)
f0101308:	85 ff                	test   %edi,%edi
f010130a:	74 0d                	je     f0101319 <readline+0xc5>
				cputchar('\n');
f010130c:	83 ec 0c             	sub    $0xc,%esp
f010130f:	6a 0a                	push   $0xa
f0101311:	e8 45 f3 ff ff       	call   f010065b <cputchar>
f0101316:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101319:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101320:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101325:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101328:	5b                   	pop    %ebx
f0101329:	5e                   	pop    %esi
f010132a:	5f                   	pop    %edi
f010132b:	5d                   	pop    %ebp
f010132c:	c3                   	ret    

f010132d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010132d:	55                   	push   %ebp
f010132e:	89 e5                	mov    %esp,%ebp
f0101330:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101333:	b8 00 00 00 00       	mov    $0x0,%eax
f0101338:	eb 03                	jmp    f010133d <strlen+0x10>
		n++;
f010133a:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010133d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101341:	75 f7                	jne    f010133a <strlen+0xd>
		n++;
	return n;
}
f0101343:	5d                   	pop    %ebp
f0101344:	c3                   	ret    

f0101345 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101345:	55                   	push   %ebp
f0101346:	89 e5                	mov    %esp,%ebp
f0101348:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010134b:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010134e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101353:	eb 03                	jmp    f0101358 <strnlen+0x13>
		n++;
f0101355:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101358:	39 c2                	cmp    %eax,%edx
f010135a:	74 08                	je     f0101364 <strnlen+0x1f>
f010135c:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101360:	75 f3                	jne    f0101355 <strnlen+0x10>
f0101362:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101364:	5d                   	pop    %ebp
f0101365:	c3                   	ret    

f0101366 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101366:	55                   	push   %ebp
f0101367:	89 e5                	mov    %esp,%ebp
f0101369:	53                   	push   %ebx
f010136a:	8b 45 08             	mov    0x8(%ebp),%eax
f010136d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101370:	89 c2                	mov    %eax,%edx
f0101372:	83 c2 01             	add    $0x1,%edx
f0101375:	83 c1 01             	add    $0x1,%ecx
f0101378:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010137c:	88 5a ff             	mov    %bl,-0x1(%edx)
f010137f:	84 db                	test   %bl,%bl
f0101381:	75 ef                	jne    f0101372 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101383:	5b                   	pop    %ebx
f0101384:	5d                   	pop    %ebp
f0101385:	c3                   	ret    

f0101386 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101386:	55                   	push   %ebp
f0101387:	89 e5                	mov    %esp,%ebp
f0101389:	53                   	push   %ebx
f010138a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010138d:	53                   	push   %ebx
f010138e:	e8 9a ff ff ff       	call   f010132d <strlen>
f0101393:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101396:	ff 75 0c             	pushl  0xc(%ebp)
f0101399:	01 d8                	add    %ebx,%eax
f010139b:	50                   	push   %eax
f010139c:	e8 c5 ff ff ff       	call   f0101366 <strcpy>
	return dst;
}
f01013a1:	89 d8                	mov    %ebx,%eax
f01013a3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013a6:	c9                   	leave  
f01013a7:	c3                   	ret    

f01013a8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013a8:	55                   	push   %ebp
f01013a9:	89 e5                	mov    %esp,%ebp
f01013ab:	56                   	push   %esi
f01013ac:	53                   	push   %ebx
f01013ad:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013b3:	89 f3                	mov    %esi,%ebx
f01013b5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b8:	89 f2                	mov    %esi,%edx
f01013ba:	eb 0f                	jmp    f01013cb <strncpy+0x23>
		*dst++ = *src;
f01013bc:	83 c2 01             	add    $0x1,%edx
f01013bf:	0f b6 01             	movzbl (%ecx),%eax
f01013c2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013c5:	80 39 01             	cmpb   $0x1,(%ecx)
f01013c8:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013cb:	39 da                	cmp    %ebx,%edx
f01013cd:	75 ed                	jne    f01013bc <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013cf:	89 f0                	mov    %esi,%eax
f01013d1:	5b                   	pop    %ebx
f01013d2:	5e                   	pop    %esi
f01013d3:	5d                   	pop    %ebp
f01013d4:	c3                   	ret    

f01013d5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013d5:	55                   	push   %ebp
f01013d6:	89 e5                	mov    %esp,%ebp
f01013d8:	56                   	push   %esi
f01013d9:	53                   	push   %ebx
f01013da:	8b 75 08             	mov    0x8(%ebp),%esi
f01013dd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013e0:	8b 55 10             	mov    0x10(%ebp),%edx
f01013e3:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013e5:	85 d2                	test   %edx,%edx
f01013e7:	74 21                	je     f010140a <strlcpy+0x35>
f01013e9:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013ed:	89 f2                	mov    %esi,%edx
f01013ef:	eb 09                	jmp    f01013fa <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013f1:	83 c2 01             	add    $0x1,%edx
f01013f4:	83 c1 01             	add    $0x1,%ecx
f01013f7:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013fa:	39 c2                	cmp    %eax,%edx
f01013fc:	74 09                	je     f0101407 <strlcpy+0x32>
f01013fe:	0f b6 19             	movzbl (%ecx),%ebx
f0101401:	84 db                	test   %bl,%bl
f0101403:	75 ec                	jne    f01013f1 <strlcpy+0x1c>
f0101405:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101407:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010140a:	29 f0                	sub    %esi,%eax
}
f010140c:	5b                   	pop    %ebx
f010140d:	5e                   	pop    %esi
f010140e:	5d                   	pop    %ebp
f010140f:	c3                   	ret    

f0101410 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101410:	55                   	push   %ebp
f0101411:	89 e5                	mov    %esp,%ebp
f0101413:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101416:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101419:	eb 06                	jmp    f0101421 <strcmp+0x11>
		p++, q++;
f010141b:	83 c1 01             	add    $0x1,%ecx
f010141e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101421:	0f b6 01             	movzbl (%ecx),%eax
f0101424:	84 c0                	test   %al,%al
f0101426:	74 04                	je     f010142c <strcmp+0x1c>
f0101428:	3a 02                	cmp    (%edx),%al
f010142a:	74 ef                	je     f010141b <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010142c:	0f b6 c0             	movzbl %al,%eax
f010142f:	0f b6 12             	movzbl (%edx),%edx
f0101432:	29 d0                	sub    %edx,%eax
}
f0101434:	5d                   	pop    %ebp
f0101435:	c3                   	ret    

f0101436 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101436:	55                   	push   %ebp
f0101437:	89 e5                	mov    %esp,%ebp
f0101439:	53                   	push   %ebx
f010143a:	8b 45 08             	mov    0x8(%ebp),%eax
f010143d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101440:	89 c3                	mov    %eax,%ebx
f0101442:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101445:	eb 06                	jmp    f010144d <strncmp+0x17>
		n--, p++, q++;
f0101447:	83 c0 01             	add    $0x1,%eax
f010144a:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010144d:	39 d8                	cmp    %ebx,%eax
f010144f:	74 15                	je     f0101466 <strncmp+0x30>
f0101451:	0f b6 08             	movzbl (%eax),%ecx
f0101454:	84 c9                	test   %cl,%cl
f0101456:	74 04                	je     f010145c <strncmp+0x26>
f0101458:	3a 0a                	cmp    (%edx),%cl
f010145a:	74 eb                	je     f0101447 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010145c:	0f b6 00             	movzbl (%eax),%eax
f010145f:	0f b6 12             	movzbl (%edx),%edx
f0101462:	29 d0                	sub    %edx,%eax
f0101464:	eb 05                	jmp    f010146b <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101466:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010146b:	5b                   	pop    %ebx
f010146c:	5d                   	pop    %ebp
f010146d:	c3                   	ret    

f010146e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010146e:	55                   	push   %ebp
f010146f:	89 e5                	mov    %esp,%ebp
f0101471:	8b 45 08             	mov    0x8(%ebp),%eax
f0101474:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101478:	eb 07                	jmp    f0101481 <strchr+0x13>
		if (*s == c)
f010147a:	38 ca                	cmp    %cl,%dl
f010147c:	74 0f                	je     f010148d <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010147e:	83 c0 01             	add    $0x1,%eax
f0101481:	0f b6 10             	movzbl (%eax),%edx
f0101484:	84 d2                	test   %dl,%dl
f0101486:	75 f2                	jne    f010147a <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101488:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010148d:	5d                   	pop    %ebp
f010148e:	c3                   	ret    

f010148f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	8b 45 08             	mov    0x8(%ebp),%eax
f0101495:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101499:	eb 03                	jmp    f010149e <strfind+0xf>
f010149b:	83 c0 01             	add    $0x1,%eax
f010149e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01014a1:	38 ca                	cmp    %cl,%dl
f01014a3:	74 04                	je     f01014a9 <strfind+0x1a>
f01014a5:	84 d2                	test   %dl,%dl
f01014a7:	75 f2                	jne    f010149b <strfind+0xc>
			break;
	return (char *) s;
}
f01014a9:	5d                   	pop    %ebp
f01014aa:	c3                   	ret    

f01014ab <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014ab:	55                   	push   %ebp
f01014ac:	89 e5                	mov    %esp,%ebp
f01014ae:	57                   	push   %edi
f01014af:	56                   	push   %esi
f01014b0:	53                   	push   %ebx
f01014b1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014b4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014b7:	85 c9                	test   %ecx,%ecx
f01014b9:	74 36                	je     f01014f1 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014bb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014c1:	75 28                	jne    f01014eb <memset+0x40>
f01014c3:	f6 c1 03             	test   $0x3,%cl
f01014c6:	75 23                	jne    f01014eb <memset+0x40>
		c &= 0xFF;
f01014c8:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014cc:	89 d3                	mov    %edx,%ebx
f01014ce:	c1 e3 08             	shl    $0x8,%ebx
f01014d1:	89 d6                	mov    %edx,%esi
f01014d3:	c1 e6 18             	shl    $0x18,%esi
f01014d6:	89 d0                	mov    %edx,%eax
f01014d8:	c1 e0 10             	shl    $0x10,%eax
f01014db:	09 f0                	or     %esi,%eax
f01014dd:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014df:	89 d8                	mov    %ebx,%eax
f01014e1:	09 d0                	or     %edx,%eax
f01014e3:	c1 e9 02             	shr    $0x2,%ecx
f01014e6:	fc                   	cld    
f01014e7:	f3 ab                	rep stos %eax,%es:(%edi)
f01014e9:	eb 06                	jmp    f01014f1 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ee:	fc                   	cld    
f01014ef:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014f1:	89 f8                	mov    %edi,%eax
f01014f3:	5b                   	pop    %ebx
f01014f4:	5e                   	pop    %esi
f01014f5:	5f                   	pop    %edi
f01014f6:	5d                   	pop    %ebp
f01014f7:	c3                   	ret    

f01014f8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014f8:	55                   	push   %ebp
f01014f9:	89 e5                	mov    %esp,%ebp
f01014fb:	57                   	push   %edi
f01014fc:	56                   	push   %esi
f01014fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101500:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101503:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101506:	39 c6                	cmp    %eax,%esi
f0101508:	73 35                	jae    f010153f <memmove+0x47>
f010150a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010150d:	39 d0                	cmp    %edx,%eax
f010150f:	73 2e                	jae    f010153f <memmove+0x47>
		s += n;
		d += n;
f0101511:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101514:	89 d6                	mov    %edx,%esi
f0101516:	09 fe                	or     %edi,%esi
f0101518:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010151e:	75 13                	jne    f0101533 <memmove+0x3b>
f0101520:	f6 c1 03             	test   $0x3,%cl
f0101523:	75 0e                	jne    f0101533 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101525:	83 ef 04             	sub    $0x4,%edi
f0101528:	8d 72 fc             	lea    -0x4(%edx),%esi
f010152b:	c1 e9 02             	shr    $0x2,%ecx
f010152e:	fd                   	std    
f010152f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101531:	eb 09                	jmp    f010153c <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101533:	83 ef 01             	sub    $0x1,%edi
f0101536:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101539:	fd                   	std    
f010153a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010153c:	fc                   	cld    
f010153d:	eb 1d                	jmp    f010155c <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010153f:	89 f2                	mov    %esi,%edx
f0101541:	09 c2                	or     %eax,%edx
f0101543:	f6 c2 03             	test   $0x3,%dl
f0101546:	75 0f                	jne    f0101557 <memmove+0x5f>
f0101548:	f6 c1 03             	test   $0x3,%cl
f010154b:	75 0a                	jne    f0101557 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010154d:	c1 e9 02             	shr    $0x2,%ecx
f0101550:	89 c7                	mov    %eax,%edi
f0101552:	fc                   	cld    
f0101553:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101555:	eb 05                	jmp    f010155c <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101557:	89 c7                	mov    %eax,%edi
f0101559:	fc                   	cld    
f010155a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010155c:	5e                   	pop    %esi
f010155d:	5f                   	pop    %edi
f010155e:	5d                   	pop    %ebp
f010155f:	c3                   	ret    

f0101560 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101560:	55                   	push   %ebp
f0101561:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101563:	ff 75 10             	pushl  0x10(%ebp)
f0101566:	ff 75 0c             	pushl  0xc(%ebp)
f0101569:	ff 75 08             	pushl  0x8(%ebp)
f010156c:	e8 87 ff ff ff       	call   f01014f8 <memmove>
}
f0101571:	c9                   	leave  
f0101572:	c3                   	ret    

f0101573 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101573:	55                   	push   %ebp
f0101574:	89 e5                	mov    %esp,%ebp
f0101576:	56                   	push   %esi
f0101577:	53                   	push   %ebx
f0101578:	8b 45 08             	mov    0x8(%ebp),%eax
f010157b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010157e:	89 c6                	mov    %eax,%esi
f0101580:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101583:	eb 1a                	jmp    f010159f <memcmp+0x2c>
		if (*s1 != *s2)
f0101585:	0f b6 08             	movzbl (%eax),%ecx
f0101588:	0f b6 1a             	movzbl (%edx),%ebx
f010158b:	38 d9                	cmp    %bl,%cl
f010158d:	74 0a                	je     f0101599 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010158f:	0f b6 c1             	movzbl %cl,%eax
f0101592:	0f b6 db             	movzbl %bl,%ebx
f0101595:	29 d8                	sub    %ebx,%eax
f0101597:	eb 0f                	jmp    f01015a8 <memcmp+0x35>
		s1++, s2++;
f0101599:	83 c0 01             	add    $0x1,%eax
f010159c:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010159f:	39 f0                	cmp    %esi,%eax
f01015a1:	75 e2                	jne    f0101585 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015a8:	5b                   	pop    %ebx
f01015a9:	5e                   	pop    %esi
f01015aa:	5d                   	pop    %ebp
f01015ab:	c3                   	ret    

f01015ac <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015ac:	55                   	push   %ebp
f01015ad:	89 e5                	mov    %esp,%ebp
f01015af:	53                   	push   %ebx
f01015b0:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01015b3:	89 c1                	mov    %eax,%ecx
f01015b5:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01015b8:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015bc:	eb 0a                	jmp    f01015c8 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015be:	0f b6 10             	movzbl (%eax),%edx
f01015c1:	39 da                	cmp    %ebx,%edx
f01015c3:	74 07                	je     f01015cc <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015c5:	83 c0 01             	add    $0x1,%eax
f01015c8:	39 c8                	cmp    %ecx,%eax
f01015ca:	72 f2                	jb     f01015be <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015cc:	5b                   	pop    %ebx
f01015cd:	5d                   	pop    %ebp
f01015ce:	c3                   	ret    

f01015cf <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015cf:	55                   	push   %ebp
f01015d0:	89 e5                	mov    %esp,%ebp
f01015d2:	57                   	push   %edi
f01015d3:	56                   	push   %esi
f01015d4:	53                   	push   %ebx
f01015d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015db:	eb 03                	jmp    f01015e0 <strtol+0x11>
		s++;
f01015dd:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015e0:	0f b6 01             	movzbl (%ecx),%eax
f01015e3:	3c 20                	cmp    $0x20,%al
f01015e5:	74 f6                	je     f01015dd <strtol+0xe>
f01015e7:	3c 09                	cmp    $0x9,%al
f01015e9:	74 f2                	je     f01015dd <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015eb:	3c 2b                	cmp    $0x2b,%al
f01015ed:	75 0a                	jne    f01015f9 <strtol+0x2a>
		s++;
f01015ef:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015f2:	bf 00 00 00 00       	mov    $0x0,%edi
f01015f7:	eb 11                	jmp    f010160a <strtol+0x3b>
f01015f9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015fe:	3c 2d                	cmp    $0x2d,%al
f0101600:	75 08                	jne    f010160a <strtol+0x3b>
		s++, neg = 1;
f0101602:	83 c1 01             	add    $0x1,%ecx
f0101605:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010160a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101610:	75 15                	jne    f0101627 <strtol+0x58>
f0101612:	80 39 30             	cmpb   $0x30,(%ecx)
f0101615:	75 10                	jne    f0101627 <strtol+0x58>
f0101617:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010161b:	75 7c                	jne    f0101699 <strtol+0xca>
		s += 2, base = 16;
f010161d:	83 c1 02             	add    $0x2,%ecx
f0101620:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101625:	eb 16                	jmp    f010163d <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101627:	85 db                	test   %ebx,%ebx
f0101629:	75 12                	jne    f010163d <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010162b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101630:	80 39 30             	cmpb   $0x30,(%ecx)
f0101633:	75 08                	jne    f010163d <strtol+0x6e>
		s++, base = 8;
f0101635:	83 c1 01             	add    $0x1,%ecx
f0101638:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010163d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101642:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101645:	0f b6 11             	movzbl (%ecx),%edx
f0101648:	8d 72 d0             	lea    -0x30(%edx),%esi
f010164b:	89 f3                	mov    %esi,%ebx
f010164d:	80 fb 09             	cmp    $0x9,%bl
f0101650:	77 08                	ja     f010165a <strtol+0x8b>
			dig = *s - '0';
f0101652:	0f be d2             	movsbl %dl,%edx
f0101655:	83 ea 30             	sub    $0x30,%edx
f0101658:	eb 22                	jmp    f010167c <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010165a:	8d 72 9f             	lea    -0x61(%edx),%esi
f010165d:	89 f3                	mov    %esi,%ebx
f010165f:	80 fb 19             	cmp    $0x19,%bl
f0101662:	77 08                	ja     f010166c <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101664:	0f be d2             	movsbl %dl,%edx
f0101667:	83 ea 57             	sub    $0x57,%edx
f010166a:	eb 10                	jmp    f010167c <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010166c:	8d 72 bf             	lea    -0x41(%edx),%esi
f010166f:	89 f3                	mov    %esi,%ebx
f0101671:	80 fb 19             	cmp    $0x19,%bl
f0101674:	77 16                	ja     f010168c <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101676:	0f be d2             	movsbl %dl,%edx
f0101679:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010167c:	3b 55 10             	cmp    0x10(%ebp),%edx
f010167f:	7d 0b                	jge    f010168c <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101681:	83 c1 01             	add    $0x1,%ecx
f0101684:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101688:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010168a:	eb b9                	jmp    f0101645 <strtol+0x76>

	if (endptr)
f010168c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101690:	74 0d                	je     f010169f <strtol+0xd0>
		*endptr = (char *) s;
f0101692:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101695:	89 0e                	mov    %ecx,(%esi)
f0101697:	eb 06                	jmp    f010169f <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101699:	85 db                	test   %ebx,%ebx
f010169b:	74 98                	je     f0101635 <strtol+0x66>
f010169d:	eb 9e                	jmp    f010163d <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010169f:	89 c2                	mov    %eax,%edx
f01016a1:	f7 da                	neg    %edx
f01016a3:	85 ff                	test   %edi,%edi
f01016a5:	0f 45 c2             	cmovne %edx,%eax
}
f01016a8:	5b                   	pop    %ebx
f01016a9:	5e                   	pop    %esi
f01016aa:	5f                   	pop    %edi
f01016ab:	5d                   	pop    %ebp
f01016ac:	c3                   	ret    
f01016ad:	66 90                	xchg   %ax,%ax
f01016af:	90                   	nop

f01016b0 <__udivdi3>:
f01016b0:	55                   	push   %ebp
f01016b1:	57                   	push   %edi
f01016b2:	56                   	push   %esi
f01016b3:	53                   	push   %ebx
f01016b4:	83 ec 1c             	sub    $0x1c,%esp
f01016b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01016bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01016bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016c7:	85 f6                	test   %esi,%esi
f01016c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016cd:	89 ca                	mov    %ecx,%edx
f01016cf:	89 f8                	mov    %edi,%eax
f01016d1:	75 3d                	jne    f0101710 <__udivdi3+0x60>
f01016d3:	39 cf                	cmp    %ecx,%edi
f01016d5:	0f 87 c5 00 00 00    	ja     f01017a0 <__udivdi3+0xf0>
f01016db:	85 ff                	test   %edi,%edi
f01016dd:	89 fd                	mov    %edi,%ebp
f01016df:	75 0b                	jne    f01016ec <__udivdi3+0x3c>
f01016e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016e6:	31 d2                	xor    %edx,%edx
f01016e8:	f7 f7                	div    %edi
f01016ea:	89 c5                	mov    %eax,%ebp
f01016ec:	89 c8                	mov    %ecx,%eax
f01016ee:	31 d2                	xor    %edx,%edx
f01016f0:	f7 f5                	div    %ebp
f01016f2:	89 c1                	mov    %eax,%ecx
f01016f4:	89 d8                	mov    %ebx,%eax
f01016f6:	89 cf                	mov    %ecx,%edi
f01016f8:	f7 f5                	div    %ebp
f01016fa:	89 c3                	mov    %eax,%ebx
f01016fc:	89 d8                	mov    %ebx,%eax
f01016fe:	89 fa                	mov    %edi,%edx
f0101700:	83 c4 1c             	add    $0x1c,%esp
f0101703:	5b                   	pop    %ebx
f0101704:	5e                   	pop    %esi
f0101705:	5f                   	pop    %edi
f0101706:	5d                   	pop    %ebp
f0101707:	c3                   	ret    
f0101708:	90                   	nop
f0101709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101710:	39 ce                	cmp    %ecx,%esi
f0101712:	77 74                	ja     f0101788 <__udivdi3+0xd8>
f0101714:	0f bd fe             	bsr    %esi,%edi
f0101717:	83 f7 1f             	xor    $0x1f,%edi
f010171a:	0f 84 98 00 00 00    	je     f01017b8 <__udivdi3+0x108>
f0101720:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	89 c5                	mov    %eax,%ebp
f0101729:	29 fb                	sub    %edi,%ebx
f010172b:	d3 e6                	shl    %cl,%esi
f010172d:	89 d9                	mov    %ebx,%ecx
f010172f:	d3 ed                	shr    %cl,%ebp
f0101731:	89 f9                	mov    %edi,%ecx
f0101733:	d3 e0                	shl    %cl,%eax
f0101735:	09 ee                	or     %ebp,%esi
f0101737:	89 d9                	mov    %ebx,%ecx
f0101739:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010173d:	89 d5                	mov    %edx,%ebp
f010173f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101743:	d3 ed                	shr    %cl,%ebp
f0101745:	89 f9                	mov    %edi,%ecx
f0101747:	d3 e2                	shl    %cl,%edx
f0101749:	89 d9                	mov    %ebx,%ecx
f010174b:	d3 e8                	shr    %cl,%eax
f010174d:	09 c2                	or     %eax,%edx
f010174f:	89 d0                	mov    %edx,%eax
f0101751:	89 ea                	mov    %ebp,%edx
f0101753:	f7 f6                	div    %esi
f0101755:	89 d5                	mov    %edx,%ebp
f0101757:	89 c3                	mov    %eax,%ebx
f0101759:	f7 64 24 0c          	mull   0xc(%esp)
f010175d:	39 d5                	cmp    %edx,%ebp
f010175f:	72 10                	jb     f0101771 <__udivdi3+0xc1>
f0101761:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101765:	89 f9                	mov    %edi,%ecx
f0101767:	d3 e6                	shl    %cl,%esi
f0101769:	39 c6                	cmp    %eax,%esi
f010176b:	73 07                	jae    f0101774 <__udivdi3+0xc4>
f010176d:	39 d5                	cmp    %edx,%ebp
f010176f:	75 03                	jne    f0101774 <__udivdi3+0xc4>
f0101771:	83 eb 01             	sub    $0x1,%ebx
f0101774:	31 ff                	xor    %edi,%edi
f0101776:	89 d8                	mov    %ebx,%eax
f0101778:	89 fa                	mov    %edi,%edx
f010177a:	83 c4 1c             	add    $0x1c,%esp
f010177d:	5b                   	pop    %ebx
f010177e:	5e                   	pop    %esi
f010177f:	5f                   	pop    %edi
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	31 ff                	xor    %edi,%edi
f010178a:	31 db                	xor    %ebx,%ebx
f010178c:	89 d8                	mov    %ebx,%eax
f010178e:	89 fa                	mov    %edi,%edx
f0101790:	83 c4 1c             	add    $0x1c,%esp
f0101793:	5b                   	pop    %ebx
f0101794:	5e                   	pop    %esi
f0101795:	5f                   	pop    %edi
f0101796:	5d                   	pop    %ebp
f0101797:	c3                   	ret    
f0101798:	90                   	nop
f0101799:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017a0:	89 d8                	mov    %ebx,%eax
f01017a2:	f7 f7                	div    %edi
f01017a4:	31 ff                	xor    %edi,%edi
f01017a6:	89 c3                	mov    %eax,%ebx
f01017a8:	89 d8                	mov    %ebx,%eax
f01017aa:	89 fa                	mov    %edi,%edx
f01017ac:	83 c4 1c             	add    $0x1c,%esp
f01017af:	5b                   	pop    %ebx
f01017b0:	5e                   	pop    %esi
f01017b1:	5f                   	pop    %edi
f01017b2:	5d                   	pop    %ebp
f01017b3:	c3                   	ret    
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	39 ce                	cmp    %ecx,%esi
f01017ba:	72 0c                	jb     f01017c8 <__udivdi3+0x118>
f01017bc:	31 db                	xor    %ebx,%ebx
f01017be:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017c2:	0f 87 34 ff ff ff    	ja     f01016fc <__udivdi3+0x4c>
f01017c8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017cd:	e9 2a ff ff ff       	jmp    f01016fc <__udivdi3+0x4c>
f01017d2:	66 90                	xchg   %ax,%ax
f01017d4:	66 90                	xchg   %ax,%ax
f01017d6:	66 90                	xchg   %ax,%ax
f01017d8:	66 90                	xchg   %ax,%ax
f01017da:	66 90                	xchg   %ax,%ax
f01017dc:	66 90                	xchg   %ax,%ax
f01017de:	66 90                	xchg   %ax,%ax

f01017e0 <__umoddi3>:
f01017e0:	55                   	push   %ebp
f01017e1:	57                   	push   %edi
f01017e2:	56                   	push   %esi
f01017e3:	53                   	push   %ebx
f01017e4:	83 ec 1c             	sub    $0x1c,%esp
f01017e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017f7:	85 d2                	test   %edx,%edx
f01017f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101801:	89 f3                	mov    %esi,%ebx
f0101803:	89 3c 24             	mov    %edi,(%esp)
f0101806:	89 74 24 04          	mov    %esi,0x4(%esp)
f010180a:	75 1c                	jne    f0101828 <__umoddi3+0x48>
f010180c:	39 f7                	cmp    %esi,%edi
f010180e:	76 50                	jbe    f0101860 <__umoddi3+0x80>
f0101810:	89 c8                	mov    %ecx,%eax
f0101812:	89 f2                	mov    %esi,%edx
f0101814:	f7 f7                	div    %edi
f0101816:	89 d0                	mov    %edx,%eax
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	83 c4 1c             	add    $0x1c,%esp
f010181d:	5b                   	pop    %ebx
f010181e:	5e                   	pop    %esi
f010181f:	5f                   	pop    %edi
f0101820:	5d                   	pop    %ebp
f0101821:	c3                   	ret    
f0101822:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101828:	39 f2                	cmp    %esi,%edx
f010182a:	89 d0                	mov    %edx,%eax
f010182c:	77 52                	ja     f0101880 <__umoddi3+0xa0>
f010182e:	0f bd ea             	bsr    %edx,%ebp
f0101831:	83 f5 1f             	xor    $0x1f,%ebp
f0101834:	75 5a                	jne    f0101890 <__umoddi3+0xb0>
f0101836:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010183a:	0f 82 e0 00 00 00    	jb     f0101920 <__umoddi3+0x140>
f0101840:	39 0c 24             	cmp    %ecx,(%esp)
f0101843:	0f 86 d7 00 00 00    	jbe    f0101920 <__umoddi3+0x140>
f0101849:	8b 44 24 08          	mov    0x8(%esp),%eax
f010184d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101851:	83 c4 1c             	add    $0x1c,%esp
f0101854:	5b                   	pop    %ebx
f0101855:	5e                   	pop    %esi
f0101856:	5f                   	pop    %edi
f0101857:	5d                   	pop    %ebp
f0101858:	c3                   	ret    
f0101859:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101860:	85 ff                	test   %edi,%edi
f0101862:	89 fd                	mov    %edi,%ebp
f0101864:	75 0b                	jne    f0101871 <__umoddi3+0x91>
f0101866:	b8 01 00 00 00       	mov    $0x1,%eax
f010186b:	31 d2                	xor    %edx,%edx
f010186d:	f7 f7                	div    %edi
f010186f:	89 c5                	mov    %eax,%ebp
f0101871:	89 f0                	mov    %esi,%eax
f0101873:	31 d2                	xor    %edx,%edx
f0101875:	f7 f5                	div    %ebp
f0101877:	89 c8                	mov    %ecx,%eax
f0101879:	f7 f5                	div    %ebp
f010187b:	89 d0                	mov    %edx,%eax
f010187d:	eb 99                	jmp    f0101818 <__umoddi3+0x38>
f010187f:	90                   	nop
f0101880:	89 c8                	mov    %ecx,%eax
f0101882:	89 f2                	mov    %esi,%edx
f0101884:	83 c4 1c             	add    $0x1c,%esp
f0101887:	5b                   	pop    %ebx
f0101888:	5e                   	pop    %esi
f0101889:	5f                   	pop    %edi
f010188a:	5d                   	pop    %ebp
f010188b:	c3                   	ret    
f010188c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101890:	8b 34 24             	mov    (%esp),%esi
f0101893:	bf 20 00 00 00       	mov    $0x20,%edi
f0101898:	89 e9                	mov    %ebp,%ecx
f010189a:	29 ef                	sub    %ebp,%edi
f010189c:	d3 e0                	shl    %cl,%eax
f010189e:	89 f9                	mov    %edi,%ecx
f01018a0:	89 f2                	mov    %esi,%edx
f01018a2:	d3 ea                	shr    %cl,%edx
f01018a4:	89 e9                	mov    %ebp,%ecx
f01018a6:	09 c2                	or     %eax,%edx
f01018a8:	89 d8                	mov    %ebx,%eax
f01018aa:	89 14 24             	mov    %edx,(%esp)
f01018ad:	89 f2                	mov    %esi,%edx
f01018af:	d3 e2                	shl    %cl,%edx
f01018b1:	89 f9                	mov    %edi,%ecx
f01018b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018bb:	d3 e8                	shr    %cl,%eax
f01018bd:	89 e9                	mov    %ebp,%ecx
f01018bf:	89 c6                	mov    %eax,%esi
f01018c1:	d3 e3                	shl    %cl,%ebx
f01018c3:	89 f9                	mov    %edi,%ecx
f01018c5:	89 d0                	mov    %edx,%eax
f01018c7:	d3 e8                	shr    %cl,%eax
f01018c9:	89 e9                	mov    %ebp,%ecx
f01018cb:	09 d8                	or     %ebx,%eax
f01018cd:	89 d3                	mov    %edx,%ebx
f01018cf:	89 f2                	mov    %esi,%edx
f01018d1:	f7 34 24             	divl   (%esp)
f01018d4:	89 d6                	mov    %edx,%esi
f01018d6:	d3 e3                	shl    %cl,%ebx
f01018d8:	f7 64 24 04          	mull   0x4(%esp)
f01018dc:	39 d6                	cmp    %edx,%esi
f01018de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018e2:	89 d1                	mov    %edx,%ecx
f01018e4:	89 c3                	mov    %eax,%ebx
f01018e6:	72 08                	jb     f01018f0 <__umoddi3+0x110>
f01018e8:	75 11                	jne    f01018fb <__umoddi3+0x11b>
f01018ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ee:	73 0b                	jae    f01018fb <__umoddi3+0x11b>
f01018f0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018f4:	1b 14 24             	sbb    (%esp),%edx
f01018f7:	89 d1                	mov    %edx,%ecx
f01018f9:	89 c3                	mov    %eax,%ebx
f01018fb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018ff:	29 da                	sub    %ebx,%edx
f0101901:	19 ce                	sbb    %ecx,%esi
f0101903:	89 f9                	mov    %edi,%ecx
f0101905:	89 f0                	mov    %esi,%eax
f0101907:	d3 e0                	shl    %cl,%eax
f0101909:	89 e9                	mov    %ebp,%ecx
f010190b:	d3 ea                	shr    %cl,%edx
f010190d:	89 e9                	mov    %ebp,%ecx
f010190f:	d3 ee                	shr    %cl,%esi
f0101911:	09 d0                	or     %edx,%eax
f0101913:	89 f2                	mov    %esi,%edx
f0101915:	83 c4 1c             	add    $0x1c,%esp
f0101918:	5b                   	pop    %ebx
f0101919:	5e                   	pop    %esi
f010191a:	5f                   	pop    %edi
f010191b:	5d                   	pop    %ebp
f010191c:	c3                   	ret    
f010191d:	8d 76 00             	lea    0x0(%esi),%esi
f0101920:	29 f9                	sub    %edi,%ecx
f0101922:	19 d6                	sbb    %edx,%esi
f0101924:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101928:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010192c:	e9 18 ff ff ff       	jmp    f0101849 <__umoddi3+0x69>
