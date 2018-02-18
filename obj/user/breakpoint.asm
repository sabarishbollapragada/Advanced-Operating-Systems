
obj/user/breakpoint:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	83 ec 08             	sub    $0x8,%esp
  80003f:	8b 45 08             	mov    0x8(%ebp),%eax
  800042:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800045:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80004c:	00 00 00 
	

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80004f:	85 c0                	test   %eax,%eax
  800051:	7e 08                	jle    80005b <libmain+0x22>
		binaryname = argv[0];
  800053:	8b 0a                	mov    (%edx),%ecx
  800055:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80005b:	83 ec 08             	sub    $0x8,%esp
  80005e:	52                   	push   %edx
  80005f:	50                   	push   %eax
  800060:	e8 ce ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800065:	e8 05 00 00 00       	call   80006f <exit>
}
  80006a:	83 c4 10             	add    $0x10,%esp
  80006d:	c9                   	leave  
  80006e:	c3                   	ret    

0080006f <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80006f:	55                   	push   %ebp
  800070:	89 e5                	mov    %esp,%ebp
  800072:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800075:	6a 00                	push   $0x0
  800077:	e8 42 00 00 00       	call   8000be <sys_env_destroy>
}
  80007c:	83 c4 10             	add    $0x10,%esp
  80007f:	c9                   	leave  
  800080:	c3                   	ret    

00800081 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800081:	55                   	push   %ebp
  800082:	89 e5                	mov    %esp,%ebp
  800084:	57                   	push   %edi
  800085:	56                   	push   %esi
  800086:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
  80008c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80008f:	8b 55 08             	mov    0x8(%ebp),%edx
  800092:	89 c3                	mov    %eax,%ebx
  800094:	89 c7                	mov    %eax,%edi
  800096:	89 c6                	mov    %eax,%esi
  800098:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009a:	5b                   	pop    %ebx
  80009b:	5e                   	pop    %esi
  80009c:	5f                   	pop    %edi
  80009d:	5d                   	pop    %ebp
  80009e:	c3                   	ret    

0080009f <sys_cgetc>:

int
sys_cgetc(void)
{
  80009f:	55                   	push   %ebp
  8000a0:	89 e5                	mov    %esp,%ebp
  8000a2:	57                   	push   %edi
  8000a3:	56                   	push   %esi
  8000a4:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a5:	ba 00 00 00 00       	mov    $0x0,%edx
  8000aa:	b8 01 00 00 00       	mov    $0x1,%eax
  8000af:	89 d1                	mov    %edx,%ecx
  8000b1:	89 d3                	mov    %edx,%ebx
  8000b3:	89 d7                	mov    %edx,%edi
  8000b5:	89 d6                	mov    %edx,%esi
  8000b7:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000b9:	5b                   	pop    %ebx
  8000ba:	5e                   	pop    %esi
  8000bb:	5f                   	pop    %edi
  8000bc:	5d                   	pop    %ebp
  8000bd:	c3                   	ret    

008000be <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	57                   	push   %edi
  8000c2:	56                   	push   %esi
  8000c3:	53                   	push   %ebx
  8000c4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c7:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000cc:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d1:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d4:	89 cb                	mov    %ecx,%ebx
  8000d6:	89 cf                	mov    %ecx,%edi
  8000d8:	89 ce                	mov    %ecx,%esi
  8000da:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000dc:	85 c0                	test   %eax,%eax
  8000de:	7e 17                	jle    8000f7 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e0:	83 ec 0c             	sub    $0xc,%esp
  8000e3:	50                   	push   %eax
  8000e4:	6a 03                	push   $0x3
  8000e6:	68 de 0d 80 00       	push   $0x800dde
  8000eb:	6a 23                	push   $0x23
  8000ed:	68 fb 0d 80 00       	push   $0x800dfb
  8000f2:	e8 27 00 00 00       	call   80011e <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000fa:	5b                   	pop    %ebx
  8000fb:	5e                   	pop    %esi
  8000fc:	5f                   	pop    %edi
  8000fd:	5d                   	pop    %ebp
  8000fe:	c3                   	ret    

008000ff <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  8000ff:	55                   	push   %ebp
  800100:	89 e5                	mov    %esp,%ebp
  800102:	57                   	push   %edi
  800103:	56                   	push   %esi
  800104:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800105:	ba 00 00 00 00       	mov    $0x0,%edx
  80010a:	b8 02 00 00 00       	mov    $0x2,%eax
  80010f:	89 d1                	mov    %edx,%ecx
  800111:	89 d3                	mov    %edx,%ebx
  800113:	89 d7                	mov    %edx,%edi
  800115:	89 d6                	mov    %edx,%esi
  800117:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800119:	5b                   	pop    %ebx
  80011a:	5e                   	pop    %esi
  80011b:	5f                   	pop    %edi
  80011c:	5d                   	pop    %ebp
  80011d:	c3                   	ret    

0080011e <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80011e:	55                   	push   %ebp
  80011f:	89 e5                	mov    %esp,%ebp
  800121:	56                   	push   %esi
  800122:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800123:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800126:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80012c:	e8 ce ff ff ff       	call   8000ff <sys_getenvid>
  800131:	83 ec 0c             	sub    $0xc,%esp
  800134:	ff 75 0c             	pushl  0xc(%ebp)
  800137:	ff 75 08             	pushl  0x8(%ebp)
  80013a:	56                   	push   %esi
  80013b:	50                   	push   %eax
  80013c:	68 0c 0e 80 00       	push   $0x800e0c
  800141:	e8 b1 00 00 00       	call   8001f7 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800146:	83 c4 18             	add    $0x18,%esp
  800149:	53                   	push   %ebx
  80014a:	ff 75 10             	pushl  0x10(%ebp)
  80014d:	e8 54 00 00 00       	call   8001a6 <vcprintf>
	cprintf("\n");
  800152:	c7 04 24 30 0e 80 00 	movl   $0x800e30,(%esp)
  800159:	e8 99 00 00 00       	call   8001f7 <cprintf>
  80015e:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800161:	cc                   	int3   
  800162:	eb fd                	jmp    800161 <_panic+0x43>

00800164 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800164:	55                   	push   %ebp
  800165:	89 e5                	mov    %esp,%ebp
  800167:	53                   	push   %ebx
  800168:	83 ec 04             	sub    $0x4,%esp
  80016b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80016e:	8b 13                	mov    (%ebx),%edx
  800170:	8d 42 01             	lea    0x1(%edx),%eax
  800173:	89 03                	mov    %eax,(%ebx)
  800175:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800178:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80017c:	3d ff 00 00 00       	cmp    $0xff,%eax
  800181:	75 1a                	jne    80019d <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800183:	83 ec 08             	sub    $0x8,%esp
  800186:	68 ff 00 00 00       	push   $0xff
  80018b:	8d 43 08             	lea    0x8(%ebx),%eax
  80018e:	50                   	push   %eax
  80018f:	e8 ed fe ff ff       	call   800081 <sys_cputs>
		b->idx = 0;
  800194:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019a:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80019d:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a4:	c9                   	leave  
  8001a5:	c3                   	ret    

008001a6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001a6:	55                   	push   %ebp
  8001a7:	89 e5                	mov    %esp,%ebp
  8001a9:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001af:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001b6:	00 00 00 
	b.cnt = 0;
  8001b9:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c0:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c3:	ff 75 0c             	pushl  0xc(%ebp)
  8001c6:	ff 75 08             	pushl  0x8(%ebp)
  8001c9:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001cf:	50                   	push   %eax
  8001d0:	68 64 01 80 00       	push   $0x800164
  8001d5:	e8 1a 01 00 00       	call   8002f4 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001da:	83 c4 08             	add    $0x8,%esp
  8001dd:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e3:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001e9:	50                   	push   %eax
  8001ea:	e8 92 fe ff ff       	call   800081 <sys_cputs>

	return b.cnt;
}
  8001ef:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f5:	c9                   	leave  
  8001f6:	c3                   	ret    

008001f7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001f7:	55                   	push   %ebp
  8001f8:	89 e5                	mov    %esp,%ebp
  8001fa:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001fd:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800200:	50                   	push   %eax
  800201:	ff 75 08             	pushl  0x8(%ebp)
  800204:	e8 9d ff ff ff       	call   8001a6 <vcprintf>
	va_end(ap);

	return cnt;
}
  800209:	c9                   	leave  
  80020a:	c3                   	ret    

0080020b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80020b:	55                   	push   %ebp
  80020c:	89 e5                	mov    %esp,%ebp
  80020e:	57                   	push   %edi
  80020f:	56                   	push   %esi
  800210:	53                   	push   %ebx
  800211:	83 ec 1c             	sub    $0x1c,%esp
  800214:	89 c7                	mov    %eax,%edi
  800216:	89 d6                	mov    %edx,%esi
  800218:	8b 45 08             	mov    0x8(%ebp),%eax
  80021b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80021e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800221:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800224:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800227:	bb 00 00 00 00       	mov    $0x0,%ebx
  80022c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80022f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800232:	39 d3                	cmp    %edx,%ebx
  800234:	72 05                	jb     80023b <printnum+0x30>
  800236:	39 45 10             	cmp    %eax,0x10(%ebp)
  800239:	77 45                	ja     800280 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80023b:	83 ec 0c             	sub    $0xc,%esp
  80023e:	ff 75 18             	pushl  0x18(%ebp)
  800241:	8b 45 14             	mov    0x14(%ebp),%eax
  800244:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800247:	53                   	push   %ebx
  800248:	ff 75 10             	pushl  0x10(%ebp)
  80024b:	83 ec 08             	sub    $0x8,%esp
  80024e:	ff 75 e4             	pushl  -0x1c(%ebp)
  800251:	ff 75 e0             	pushl  -0x20(%ebp)
  800254:	ff 75 dc             	pushl  -0x24(%ebp)
  800257:	ff 75 d8             	pushl  -0x28(%ebp)
  80025a:	e8 f1 08 00 00       	call   800b50 <__udivdi3>
  80025f:	83 c4 18             	add    $0x18,%esp
  800262:	52                   	push   %edx
  800263:	50                   	push   %eax
  800264:	89 f2                	mov    %esi,%edx
  800266:	89 f8                	mov    %edi,%eax
  800268:	e8 9e ff ff ff       	call   80020b <printnum>
  80026d:	83 c4 20             	add    $0x20,%esp
  800270:	eb 18                	jmp    80028a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800272:	83 ec 08             	sub    $0x8,%esp
  800275:	56                   	push   %esi
  800276:	ff 75 18             	pushl  0x18(%ebp)
  800279:	ff d7                	call   *%edi
  80027b:	83 c4 10             	add    $0x10,%esp
  80027e:	eb 03                	jmp    800283 <printnum+0x78>
  800280:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800283:	83 eb 01             	sub    $0x1,%ebx
  800286:	85 db                	test   %ebx,%ebx
  800288:	7f e8                	jg     800272 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028a:	83 ec 08             	sub    $0x8,%esp
  80028d:	56                   	push   %esi
  80028e:	83 ec 04             	sub    $0x4,%esp
  800291:	ff 75 e4             	pushl  -0x1c(%ebp)
  800294:	ff 75 e0             	pushl  -0x20(%ebp)
  800297:	ff 75 dc             	pushl  -0x24(%ebp)
  80029a:	ff 75 d8             	pushl  -0x28(%ebp)
  80029d:	e8 de 09 00 00       	call   800c80 <__umoddi3>
  8002a2:	83 c4 14             	add    $0x14,%esp
  8002a5:	0f be 80 32 0e 80 00 	movsbl 0x800e32(%eax),%eax
  8002ac:	50                   	push   %eax
  8002ad:	ff d7                	call   *%edi
}
  8002af:	83 c4 10             	add    $0x10,%esp
  8002b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002b5:	5b                   	pop    %ebx
  8002b6:	5e                   	pop    %esi
  8002b7:	5f                   	pop    %edi
  8002b8:	5d                   	pop    %ebp
  8002b9:	c3                   	ret    

008002ba <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002ba:	55                   	push   %ebp
  8002bb:	89 e5                	mov    %esp,%ebp
  8002bd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c4:	8b 10                	mov    (%eax),%edx
  8002c6:	3b 50 04             	cmp    0x4(%eax),%edx
  8002c9:	73 0a                	jae    8002d5 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002cb:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002ce:	89 08                	mov    %ecx,(%eax)
  8002d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d3:	88 02                	mov    %al,(%edx)
}
  8002d5:	5d                   	pop    %ebp
  8002d6:	c3                   	ret    

008002d7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002d7:	55                   	push   %ebp
  8002d8:	89 e5                	mov    %esp,%ebp
  8002da:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002dd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e0:	50                   	push   %eax
  8002e1:	ff 75 10             	pushl  0x10(%ebp)
  8002e4:	ff 75 0c             	pushl  0xc(%ebp)
  8002e7:	ff 75 08             	pushl  0x8(%ebp)
  8002ea:	e8 05 00 00 00       	call   8002f4 <vprintfmt>
	va_end(ap);
}
  8002ef:	83 c4 10             	add    $0x10,%esp
  8002f2:	c9                   	leave  
  8002f3:	c3                   	ret    

008002f4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f4:	55                   	push   %ebp
  8002f5:	89 e5                	mov    %esp,%ebp
  8002f7:	57                   	push   %edi
  8002f8:	56                   	push   %esi
  8002f9:	53                   	push   %ebx
  8002fa:	83 ec 2c             	sub    $0x2c,%esp
  8002fd:	8b 75 08             	mov    0x8(%ebp),%esi
  800300:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800303:	8b 7d 10             	mov    0x10(%ebp),%edi
  800306:	eb 12                	jmp    80031a <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800308:	85 c0                	test   %eax,%eax
  80030a:	0f 84 42 04 00 00    	je     800752 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800310:	83 ec 08             	sub    $0x8,%esp
  800313:	53                   	push   %ebx
  800314:	50                   	push   %eax
  800315:	ff d6                	call   *%esi
  800317:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80031a:	83 c7 01             	add    $0x1,%edi
  80031d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800321:	83 f8 25             	cmp    $0x25,%eax
  800324:	75 e2                	jne    800308 <vprintfmt+0x14>
  800326:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80032a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800331:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800338:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80033f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800344:	eb 07                	jmp    80034d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800346:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800349:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034d:	8d 47 01             	lea    0x1(%edi),%eax
  800350:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800353:	0f b6 07             	movzbl (%edi),%eax
  800356:	0f b6 d0             	movzbl %al,%edx
  800359:	83 e8 23             	sub    $0x23,%eax
  80035c:	3c 55                	cmp    $0x55,%al
  80035e:	0f 87 d3 03 00 00    	ja     800737 <vprintfmt+0x443>
  800364:	0f b6 c0             	movzbl %al,%eax
  800367:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  80036e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800371:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800375:	eb d6                	jmp    80034d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800377:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80037a:	b8 00 00 00 00       	mov    $0x0,%eax
  80037f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800382:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800385:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800389:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80038c:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80038f:	83 f9 09             	cmp    $0x9,%ecx
  800392:	77 3f                	ja     8003d3 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800394:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800397:	eb e9                	jmp    800382 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800399:	8b 45 14             	mov    0x14(%ebp),%eax
  80039c:	8b 00                	mov    (%eax),%eax
  80039e:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a4:	8d 40 04             	lea    0x4(%eax),%eax
  8003a7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ad:	eb 2a                	jmp    8003d9 <vprintfmt+0xe5>
  8003af:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b2:	85 c0                	test   %eax,%eax
  8003b4:	ba 00 00 00 00       	mov    $0x0,%edx
  8003b9:	0f 49 d0             	cmovns %eax,%edx
  8003bc:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c2:	eb 89                	jmp    80034d <vprintfmt+0x59>
  8003c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003c7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003ce:	e9 7a ff ff ff       	jmp    80034d <vprintfmt+0x59>
  8003d3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003d6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003d9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003dd:	0f 89 6a ff ff ff    	jns    80034d <vprintfmt+0x59>
				width = precision, precision = -1;
  8003e3:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003e9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f0:	e9 58 ff ff ff       	jmp    80034d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003f5:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003fb:	e9 4d ff ff ff       	jmp    80034d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800400:	8b 45 14             	mov    0x14(%ebp),%eax
  800403:	8d 78 04             	lea    0x4(%eax),%edi
  800406:	83 ec 08             	sub    $0x8,%esp
  800409:	53                   	push   %ebx
  80040a:	ff 30                	pushl  (%eax)
  80040c:	ff d6                	call   *%esi
			break;
  80040e:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800411:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800414:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800417:	e9 fe fe ff ff       	jmp    80031a <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80041c:	8b 45 14             	mov    0x14(%ebp),%eax
  80041f:	8d 78 04             	lea    0x4(%eax),%edi
  800422:	8b 00                	mov    (%eax),%eax
  800424:	99                   	cltd   
  800425:	31 d0                	xor    %edx,%eax
  800427:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800429:	83 f8 06             	cmp    $0x6,%eax
  80042c:	7f 0b                	jg     800439 <vprintfmt+0x145>
  80042e:	8b 14 85 18 10 80 00 	mov    0x801018(,%eax,4),%edx
  800435:	85 d2                	test   %edx,%edx
  800437:	75 1b                	jne    800454 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800439:	50                   	push   %eax
  80043a:	68 4a 0e 80 00       	push   $0x800e4a
  80043f:	53                   	push   %ebx
  800440:	56                   	push   %esi
  800441:	e8 91 fe ff ff       	call   8002d7 <printfmt>
  800446:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800449:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80044f:	e9 c6 fe ff ff       	jmp    80031a <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800454:	52                   	push   %edx
  800455:	68 53 0e 80 00       	push   $0x800e53
  80045a:	53                   	push   %ebx
  80045b:	56                   	push   %esi
  80045c:	e8 76 fe ff ff       	call   8002d7 <printfmt>
  800461:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800464:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800467:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80046a:	e9 ab fe ff ff       	jmp    80031a <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80046f:	8b 45 14             	mov    0x14(%ebp),%eax
  800472:	83 c0 04             	add    $0x4,%eax
  800475:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800478:	8b 45 14             	mov    0x14(%ebp),%eax
  80047b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80047d:	85 ff                	test   %edi,%edi
  80047f:	b8 43 0e 80 00       	mov    $0x800e43,%eax
  800484:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800487:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80048b:	0f 8e 94 00 00 00    	jle    800525 <vprintfmt+0x231>
  800491:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800495:	0f 84 98 00 00 00    	je     800533 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80049b:	83 ec 08             	sub    $0x8,%esp
  80049e:	ff 75 d0             	pushl  -0x30(%ebp)
  8004a1:	57                   	push   %edi
  8004a2:	e8 33 03 00 00       	call   8007da <strnlen>
  8004a7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004aa:	29 c1                	sub    %eax,%ecx
  8004ac:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004af:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004b2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004b9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004bc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004be:	eb 0f                	jmp    8004cf <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c0:	83 ec 08             	sub    $0x8,%esp
  8004c3:	53                   	push   %ebx
  8004c4:	ff 75 e0             	pushl  -0x20(%ebp)
  8004c7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c9:	83 ef 01             	sub    $0x1,%edi
  8004cc:	83 c4 10             	add    $0x10,%esp
  8004cf:	85 ff                	test   %edi,%edi
  8004d1:	7f ed                	jg     8004c0 <vprintfmt+0x1cc>
  8004d3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004d6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004d9:	85 c9                	test   %ecx,%ecx
  8004db:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e0:	0f 49 c1             	cmovns %ecx,%eax
  8004e3:	29 c1                	sub    %eax,%ecx
  8004e5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004eb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ee:	89 cb                	mov    %ecx,%ebx
  8004f0:	eb 4d                	jmp    80053f <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f6:	74 1b                	je     800513 <vprintfmt+0x21f>
  8004f8:	0f be c0             	movsbl %al,%eax
  8004fb:	83 e8 20             	sub    $0x20,%eax
  8004fe:	83 f8 5e             	cmp    $0x5e,%eax
  800501:	76 10                	jbe    800513 <vprintfmt+0x21f>
					putch('?', putdat);
  800503:	83 ec 08             	sub    $0x8,%esp
  800506:	ff 75 0c             	pushl  0xc(%ebp)
  800509:	6a 3f                	push   $0x3f
  80050b:	ff 55 08             	call   *0x8(%ebp)
  80050e:	83 c4 10             	add    $0x10,%esp
  800511:	eb 0d                	jmp    800520 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800513:	83 ec 08             	sub    $0x8,%esp
  800516:	ff 75 0c             	pushl  0xc(%ebp)
  800519:	52                   	push   %edx
  80051a:	ff 55 08             	call   *0x8(%ebp)
  80051d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800520:	83 eb 01             	sub    $0x1,%ebx
  800523:	eb 1a                	jmp    80053f <vprintfmt+0x24b>
  800525:	89 75 08             	mov    %esi,0x8(%ebp)
  800528:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800531:	eb 0c                	jmp    80053f <vprintfmt+0x24b>
  800533:	89 75 08             	mov    %esi,0x8(%ebp)
  800536:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800539:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80053f:	83 c7 01             	add    $0x1,%edi
  800542:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800546:	0f be d0             	movsbl %al,%edx
  800549:	85 d2                	test   %edx,%edx
  80054b:	74 23                	je     800570 <vprintfmt+0x27c>
  80054d:	85 f6                	test   %esi,%esi
  80054f:	78 a1                	js     8004f2 <vprintfmt+0x1fe>
  800551:	83 ee 01             	sub    $0x1,%esi
  800554:	79 9c                	jns    8004f2 <vprintfmt+0x1fe>
  800556:	89 df                	mov    %ebx,%edi
  800558:	8b 75 08             	mov    0x8(%ebp),%esi
  80055b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80055e:	eb 18                	jmp    800578 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800560:	83 ec 08             	sub    $0x8,%esp
  800563:	53                   	push   %ebx
  800564:	6a 20                	push   $0x20
  800566:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800568:	83 ef 01             	sub    $0x1,%edi
  80056b:	83 c4 10             	add    $0x10,%esp
  80056e:	eb 08                	jmp    800578 <vprintfmt+0x284>
  800570:	89 df                	mov    %ebx,%edi
  800572:	8b 75 08             	mov    0x8(%ebp),%esi
  800575:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800578:	85 ff                	test   %edi,%edi
  80057a:	7f e4                	jg     800560 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80057c:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80057f:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800582:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800585:	e9 90 fd ff ff       	jmp    80031a <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058a:	83 f9 01             	cmp    $0x1,%ecx
  80058d:	7e 19                	jle    8005a8 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80058f:	8b 45 14             	mov    0x14(%ebp),%eax
  800592:	8b 50 04             	mov    0x4(%eax),%edx
  800595:	8b 00                	mov    (%eax),%eax
  800597:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80059a:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8d 40 08             	lea    0x8(%eax),%eax
  8005a3:	89 45 14             	mov    %eax,0x14(%ebp)
  8005a6:	eb 38                	jmp    8005e0 <vprintfmt+0x2ec>
	else if (lflag)
  8005a8:	85 c9                	test   %ecx,%ecx
  8005aa:	74 1b                	je     8005c7 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8005af:	8b 00                	mov    (%eax),%eax
  8005b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b4:	89 c1                	mov    %eax,%ecx
  8005b6:	c1 f9 1f             	sar    $0x1f,%ecx
  8005b9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bf:	8d 40 04             	lea    0x4(%eax),%eax
  8005c2:	89 45 14             	mov    %eax,0x14(%ebp)
  8005c5:	eb 19                	jmp    8005e0 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ca:	8b 00                	mov    (%eax),%eax
  8005cc:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005cf:	89 c1                	mov    %eax,%ecx
  8005d1:	c1 f9 1f             	sar    $0x1f,%ecx
  8005d4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005da:	8d 40 04             	lea    0x4(%eax),%eax
  8005dd:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e0:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005e3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005e6:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005eb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005ef:	0f 89 0e 01 00 00    	jns    800703 <vprintfmt+0x40f>
				putch('-', putdat);
  8005f5:	83 ec 08             	sub    $0x8,%esp
  8005f8:	53                   	push   %ebx
  8005f9:	6a 2d                	push   $0x2d
  8005fb:	ff d6                	call   *%esi
				num = -(long long) num;
  8005fd:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800600:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800603:	f7 da                	neg    %edx
  800605:	83 d1 00             	adc    $0x0,%ecx
  800608:	f7 d9                	neg    %ecx
  80060a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80060d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800612:	e9 ec 00 00 00       	jmp    800703 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800617:	83 f9 01             	cmp    $0x1,%ecx
  80061a:	7e 18                	jle    800634 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80061c:	8b 45 14             	mov    0x14(%ebp),%eax
  80061f:	8b 10                	mov    (%eax),%edx
  800621:	8b 48 04             	mov    0x4(%eax),%ecx
  800624:	8d 40 08             	lea    0x8(%eax),%eax
  800627:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80062a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80062f:	e9 cf 00 00 00       	jmp    800703 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800634:	85 c9                	test   %ecx,%ecx
  800636:	74 1a                	je     800652 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800638:	8b 45 14             	mov    0x14(%ebp),%eax
  80063b:	8b 10                	mov    (%eax),%edx
  80063d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800642:	8d 40 04             	lea    0x4(%eax),%eax
  800645:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800648:	b8 0a 00 00 00       	mov    $0xa,%eax
  80064d:	e9 b1 00 00 00       	jmp    800703 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800652:	8b 45 14             	mov    0x14(%ebp),%eax
  800655:	8b 10                	mov    (%eax),%edx
  800657:	b9 00 00 00 00       	mov    $0x0,%ecx
  80065c:	8d 40 04             	lea    0x4(%eax),%eax
  80065f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800662:	b8 0a 00 00 00       	mov    $0xa,%eax
  800667:	e9 97 00 00 00       	jmp    800703 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  80066c:	83 ec 08             	sub    $0x8,%esp
  80066f:	53                   	push   %ebx
  800670:	6a 58                	push   $0x58
  800672:	ff d6                	call   *%esi
			putch('X', putdat);
  800674:	83 c4 08             	add    $0x8,%esp
  800677:	53                   	push   %ebx
  800678:	6a 58                	push   $0x58
  80067a:	ff d6                	call   *%esi
			putch('X', putdat);
  80067c:	83 c4 08             	add    $0x8,%esp
  80067f:	53                   	push   %ebx
  800680:	6a 58                	push   $0x58
  800682:	ff d6                	call   *%esi
			break;
  800684:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800687:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80068a:	e9 8b fc ff ff       	jmp    80031a <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  80068f:	83 ec 08             	sub    $0x8,%esp
  800692:	53                   	push   %ebx
  800693:	6a 30                	push   $0x30
  800695:	ff d6                	call   *%esi
			putch('x', putdat);
  800697:	83 c4 08             	add    $0x8,%esp
  80069a:	53                   	push   %ebx
  80069b:	6a 78                	push   $0x78
  80069d:	ff d6                	call   *%esi
			num = (unsigned long long)
  80069f:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a2:	8b 10                	mov    (%eax),%edx
  8006a4:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a9:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ac:	8d 40 04             	lea    0x4(%eax),%eax
  8006af:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006b2:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006b7:	eb 4a                	jmp    800703 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006b9:	83 f9 01             	cmp    $0x1,%ecx
  8006bc:	7e 15                	jle    8006d3 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006be:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c1:	8b 10                	mov    (%eax),%edx
  8006c3:	8b 48 04             	mov    0x4(%eax),%ecx
  8006c6:	8d 40 08             	lea    0x8(%eax),%eax
  8006c9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006cc:	b8 10 00 00 00       	mov    $0x10,%eax
  8006d1:	eb 30                	jmp    800703 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006d3:	85 c9                	test   %ecx,%ecx
  8006d5:	74 17                	je     8006ee <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006da:	8b 10                	mov    (%eax),%edx
  8006dc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006e1:	8d 40 04             	lea    0x4(%eax),%eax
  8006e4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006e7:	b8 10 00 00 00       	mov    $0x10,%eax
  8006ec:	eb 15                	jmp    800703 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f1:	8b 10                	mov    (%eax),%edx
  8006f3:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006f8:	8d 40 04             	lea    0x4(%eax),%eax
  8006fb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006fe:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800703:	83 ec 0c             	sub    $0xc,%esp
  800706:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80070a:	57                   	push   %edi
  80070b:	ff 75 e0             	pushl  -0x20(%ebp)
  80070e:	50                   	push   %eax
  80070f:	51                   	push   %ecx
  800710:	52                   	push   %edx
  800711:	89 da                	mov    %ebx,%edx
  800713:	89 f0                	mov    %esi,%eax
  800715:	e8 f1 fa ff ff       	call   80020b <printnum>
			break;
  80071a:	83 c4 20             	add    $0x20,%esp
  80071d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800720:	e9 f5 fb ff ff       	jmp    80031a <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800725:	83 ec 08             	sub    $0x8,%esp
  800728:	53                   	push   %ebx
  800729:	52                   	push   %edx
  80072a:	ff d6                	call   *%esi
			break;
  80072c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80072f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800732:	e9 e3 fb ff ff       	jmp    80031a <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800737:	83 ec 08             	sub    $0x8,%esp
  80073a:	53                   	push   %ebx
  80073b:	6a 25                	push   $0x25
  80073d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80073f:	83 c4 10             	add    $0x10,%esp
  800742:	eb 03                	jmp    800747 <vprintfmt+0x453>
  800744:	83 ef 01             	sub    $0x1,%edi
  800747:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80074b:	75 f7                	jne    800744 <vprintfmt+0x450>
  80074d:	e9 c8 fb ff ff       	jmp    80031a <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800752:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800755:	5b                   	pop    %ebx
  800756:	5e                   	pop    %esi
  800757:	5f                   	pop    %edi
  800758:	5d                   	pop    %ebp
  800759:	c3                   	ret    

0080075a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80075a:	55                   	push   %ebp
  80075b:	89 e5                	mov    %esp,%ebp
  80075d:	83 ec 18             	sub    $0x18,%esp
  800760:	8b 45 08             	mov    0x8(%ebp),%eax
  800763:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800766:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800769:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80076d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800770:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800777:	85 c0                	test   %eax,%eax
  800779:	74 26                	je     8007a1 <vsnprintf+0x47>
  80077b:	85 d2                	test   %edx,%edx
  80077d:	7e 22                	jle    8007a1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80077f:	ff 75 14             	pushl  0x14(%ebp)
  800782:	ff 75 10             	pushl  0x10(%ebp)
  800785:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800788:	50                   	push   %eax
  800789:	68 ba 02 80 00       	push   $0x8002ba
  80078e:	e8 61 fb ff ff       	call   8002f4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800793:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800796:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800799:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80079c:	83 c4 10             	add    $0x10,%esp
  80079f:	eb 05                	jmp    8007a6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007a1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007a6:	c9                   	leave  
  8007a7:	c3                   	ret    

008007a8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007a8:	55                   	push   %ebp
  8007a9:	89 e5                	mov    %esp,%ebp
  8007ab:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007ae:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007b1:	50                   	push   %eax
  8007b2:	ff 75 10             	pushl  0x10(%ebp)
  8007b5:	ff 75 0c             	pushl  0xc(%ebp)
  8007b8:	ff 75 08             	pushl  0x8(%ebp)
  8007bb:	e8 9a ff ff ff       	call   80075a <vsnprintf>
	va_end(ap);

	return rc;
}
  8007c0:	c9                   	leave  
  8007c1:	c3                   	ret    

008007c2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007c2:	55                   	push   %ebp
  8007c3:	89 e5                	mov    %esp,%ebp
  8007c5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007c8:	b8 00 00 00 00       	mov    $0x0,%eax
  8007cd:	eb 03                	jmp    8007d2 <strlen+0x10>
		n++;
  8007cf:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007d6:	75 f7                	jne    8007cf <strlen+0xd>
		n++;
	return n;
}
  8007d8:	5d                   	pop    %ebp
  8007d9:	c3                   	ret    

008007da <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007da:	55                   	push   %ebp
  8007db:	89 e5                	mov    %esp,%ebp
  8007dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007e0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007e3:	ba 00 00 00 00       	mov    $0x0,%edx
  8007e8:	eb 03                	jmp    8007ed <strnlen+0x13>
		n++;
  8007ea:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ed:	39 c2                	cmp    %eax,%edx
  8007ef:	74 08                	je     8007f9 <strnlen+0x1f>
  8007f1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007f5:	75 f3                	jne    8007ea <strnlen+0x10>
  8007f7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007f9:	5d                   	pop    %ebp
  8007fa:	c3                   	ret    

008007fb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007fb:	55                   	push   %ebp
  8007fc:	89 e5                	mov    %esp,%ebp
  8007fe:	53                   	push   %ebx
  8007ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800802:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800805:	89 c2                	mov    %eax,%edx
  800807:	83 c2 01             	add    $0x1,%edx
  80080a:	83 c1 01             	add    $0x1,%ecx
  80080d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800811:	88 5a ff             	mov    %bl,-0x1(%edx)
  800814:	84 db                	test   %bl,%bl
  800816:	75 ef                	jne    800807 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800818:	5b                   	pop    %ebx
  800819:	5d                   	pop    %ebp
  80081a:	c3                   	ret    

0080081b <strcat>:

char *
strcat(char *dst, const char *src)
{
  80081b:	55                   	push   %ebp
  80081c:	89 e5                	mov    %esp,%ebp
  80081e:	53                   	push   %ebx
  80081f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800822:	53                   	push   %ebx
  800823:	e8 9a ff ff ff       	call   8007c2 <strlen>
  800828:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80082b:	ff 75 0c             	pushl  0xc(%ebp)
  80082e:	01 d8                	add    %ebx,%eax
  800830:	50                   	push   %eax
  800831:	e8 c5 ff ff ff       	call   8007fb <strcpy>
	return dst;
}
  800836:	89 d8                	mov    %ebx,%eax
  800838:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80083b:	c9                   	leave  
  80083c:	c3                   	ret    

0080083d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80083d:	55                   	push   %ebp
  80083e:	89 e5                	mov    %esp,%ebp
  800840:	56                   	push   %esi
  800841:	53                   	push   %ebx
  800842:	8b 75 08             	mov    0x8(%ebp),%esi
  800845:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800848:	89 f3                	mov    %esi,%ebx
  80084a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80084d:	89 f2                	mov    %esi,%edx
  80084f:	eb 0f                	jmp    800860 <strncpy+0x23>
		*dst++ = *src;
  800851:	83 c2 01             	add    $0x1,%edx
  800854:	0f b6 01             	movzbl (%ecx),%eax
  800857:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80085a:	80 39 01             	cmpb   $0x1,(%ecx)
  80085d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800860:	39 da                	cmp    %ebx,%edx
  800862:	75 ed                	jne    800851 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800864:	89 f0                	mov    %esi,%eax
  800866:	5b                   	pop    %ebx
  800867:	5e                   	pop    %esi
  800868:	5d                   	pop    %ebp
  800869:	c3                   	ret    

0080086a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80086a:	55                   	push   %ebp
  80086b:	89 e5                	mov    %esp,%ebp
  80086d:	56                   	push   %esi
  80086e:	53                   	push   %ebx
  80086f:	8b 75 08             	mov    0x8(%ebp),%esi
  800872:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800875:	8b 55 10             	mov    0x10(%ebp),%edx
  800878:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80087a:	85 d2                	test   %edx,%edx
  80087c:	74 21                	je     80089f <strlcpy+0x35>
  80087e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800882:	89 f2                	mov    %esi,%edx
  800884:	eb 09                	jmp    80088f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800886:	83 c2 01             	add    $0x1,%edx
  800889:	83 c1 01             	add    $0x1,%ecx
  80088c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80088f:	39 c2                	cmp    %eax,%edx
  800891:	74 09                	je     80089c <strlcpy+0x32>
  800893:	0f b6 19             	movzbl (%ecx),%ebx
  800896:	84 db                	test   %bl,%bl
  800898:	75 ec                	jne    800886 <strlcpy+0x1c>
  80089a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80089c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80089f:	29 f0                	sub    %esi,%eax
}
  8008a1:	5b                   	pop    %ebx
  8008a2:	5e                   	pop    %esi
  8008a3:	5d                   	pop    %ebp
  8008a4:	c3                   	ret    

008008a5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008a5:	55                   	push   %ebp
  8008a6:	89 e5                	mov    %esp,%ebp
  8008a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008ae:	eb 06                	jmp    8008b6 <strcmp+0x11>
		p++, q++;
  8008b0:	83 c1 01             	add    $0x1,%ecx
  8008b3:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008b6:	0f b6 01             	movzbl (%ecx),%eax
  8008b9:	84 c0                	test   %al,%al
  8008bb:	74 04                	je     8008c1 <strcmp+0x1c>
  8008bd:	3a 02                	cmp    (%edx),%al
  8008bf:	74 ef                	je     8008b0 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008c1:	0f b6 c0             	movzbl %al,%eax
  8008c4:	0f b6 12             	movzbl (%edx),%edx
  8008c7:	29 d0                	sub    %edx,%eax
}
  8008c9:	5d                   	pop    %ebp
  8008ca:	c3                   	ret    

008008cb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008cb:	55                   	push   %ebp
  8008cc:	89 e5                	mov    %esp,%ebp
  8008ce:	53                   	push   %ebx
  8008cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d5:	89 c3                	mov    %eax,%ebx
  8008d7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008da:	eb 06                	jmp    8008e2 <strncmp+0x17>
		n--, p++, q++;
  8008dc:	83 c0 01             	add    $0x1,%eax
  8008df:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008e2:	39 d8                	cmp    %ebx,%eax
  8008e4:	74 15                	je     8008fb <strncmp+0x30>
  8008e6:	0f b6 08             	movzbl (%eax),%ecx
  8008e9:	84 c9                	test   %cl,%cl
  8008eb:	74 04                	je     8008f1 <strncmp+0x26>
  8008ed:	3a 0a                	cmp    (%edx),%cl
  8008ef:	74 eb                	je     8008dc <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f1:	0f b6 00             	movzbl (%eax),%eax
  8008f4:	0f b6 12             	movzbl (%edx),%edx
  8008f7:	29 d0                	sub    %edx,%eax
  8008f9:	eb 05                	jmp    800900 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008fb:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800900:	5b                   	pop    %ebx
  800901:	5d                   	pop    %ebp
  800902:	c3                   	ret    

00800903 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800903:	55                   	push   %ebp
  800904:	89 e5                	mov    %esp,%ebp
  800906:	8b 45 08             	mov    0x8(%ebp),%eax
  800909:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80090d:	eb 07                	jmp    800916 <strchr+0x13>
		if (*s == c)
  80090f:	38 ca                	cmp    %cl,%dl
  800911:	74 0f                	je     800922 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800913:	83 c0 01             	add    $0x1,%eax
  800916:	0f b6 10             	movzbl (%eax),%edx
  800919:	84 d2                	test   %dl,%dl
  80091b:	75 f2                	jne    80090f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80091d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800922:	5d                   	pop    %ebp
  800923:	c3                   	ret    

00800924 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800924:	55                   	push   %ebp
  800925:	89 e5                	mov    %esp,%ebp
  800927:	8b 45 08             	mov    0x8(%ebp),%eax
  80092a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80092e:	eb 03                	jmp    800933 <strfind+0xf>
  800930:	83 c0 01             	add    $0x1,%eax
  800933:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800936:	38 ca                	cmp    %cl,%dl
  800938:	74 04                	je     80093e <strfind+0x1a>
  80093a:	84 d2                	test   %dl,%dl
  80093c:	75 f2                	jne    800930 <strfind+0xc>
			break;
	return (char *) s;
}
  80093e:	5d                   	pop    %ebp
  80093f:	c3                   	ret    

00800940 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800940:	55                   	push   %ebp
  800941:	89 e5                	mov    %esp,%ebp
  800943:	57                   	push   %edi
  800944:	56                   	push   %esi
  800945:	53                   	push   %ebx
  800946:	8b 7d 08             	mov    0x8(%ebp),%edi
  800949:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80094c:	85 c9                	test   %ecx,%ecx
  80094e:	74 36                	je     800986 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800950:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800956:	75 28                	jne    800980 <memset+0x40>
  800958:	f6 c1 03             	test   $0x3,%cl
  80095b:	75 23                	jne    800980 <memset+0x40>
		c &= 0xFF;
  80095d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800961:	89 d3                	mov    %edx,%ebx
  800963:	c1 e3 08             	shl    $0x8,%ebx
  800966:	89 d6                	mov    %edx,%esi
  800968:	c1 e6 18             	shl    $0x18,%esi
  80096b:	89 d0                	mov    %edx,%eax
  80096d:	c1 e0 10             	shl    $0x10,%eax
  800970:	09 f0                	or     %esi,%eax
  800972:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800974:	89 d8                	mov    %ebx,%eax
  800976:	09 d0                	or     %edx,%eax
  800978:	c1 e9 02             	shr    $0x2,%ecx
  80097b:	fc                   	cld    
  80097c:	f3 ab                	rep stos %eax,%es:(%edi)
  80097e:	eb 06                	jmp    800986 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800980:	8b 45 0c             	mov    0xc(%ebp),%eax
  800983:	fc                   	cld    
  800984:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800986:	89 f8                	mov    %edi,%eax
  800988:	5b                   	pop    %ebx
  800989:	5e                   	pop    %esi
  80098a:	5f                   	pop    %edi
  80098b:	5d                   	pop    %ebp
  80098c:	c3                   	ret    

0080098d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80098d:	55                   	push   %ebp
  80098e:	89 e5                	mov    %esp,%ebp
  800990:	57                   	push   %edi
  800991:	56                   	push   %esi
  800992:	8b 45 08             	mov    0x8(%ebp),%eax
  800995:	8b 75 0c             	mov    0xc(%ebp),%esi
  800998:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80099b:	39 c6                	cmp    %eax,%esi
  80099d:	73 35                	jae    8009d4 <memmove+0x47>
  80099f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009a2:	39 d0                	cmp    %edx,%eax
  8009a4:	73 2e                	jae    8009d4 <memmove+0x47>
		s += n;
		d += n;
  8009a6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009a9:	89 d6                	mov    %edx,%esi
  8009ab:	09 fe                	or     %edi,%esi
  8009ad:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009b3:	75 13                	jne    8009c8 <memmove+0x3b>
  8009b5:	f6 c1 03             	test   $0x3,%cl
  8009b8:	75 0e                	jne    8009c8 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009ba:	83 ef 04             	sub    $0x4,%edi
  8009bd:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009c0:	c1 e9 02             	shr    $0x2,%ecx
  8009c3:	fd                   	std    
  8009c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009c6:	eb 09                	jmp    8009d1 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009c8:	83 ef 01             	sub    $0x1,%edi
  8009cb:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009ce:	fd                   	std    
  8009cf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009d1:	fc                   	cld    
  8009d2:	eb 1d                	jmp    8009f1 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d4:	89 f2                	mov    %esi,%edx
  8009d6:	09 c2                	or     %eax,%edx
  8009d8:	f6 c2 03             	test   $0x3,%dl
  8009db:	75 0f                	jne    8009ec <memmove+0x5f>
  8009dd:	f6 c1 03             	test   $0x3,%cl
  8009e0:	75 0a                	jne    8009ec <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009e2:	c1 e9 02             	shr    $0x2,%ecx
  8009e5:	89 c7                	mov    %eax,%edi
  8009e7:	fc                   	cld    
  8009e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ea:	eb 05                	jmp    8009f1 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009ec:	89 c7                	mov    %eax,%edi
  8009ee:	fc                   	cld    
  8009ef:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009f1:	5e                   	pop    %esi
  8009f2:	5f                   	pop    %edi
  8009f3:	5d                   	pop    %ebp
  8009f4:	c3                   	ret    

008009f5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009f5:	55                   	push   %ebp
  8009f6:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009f8:	ff 75 10             	pushl  0x10(%ebp)
  8009fb:	ff 75 0c             	pushl  0xc(%ebp)
  8009fe:	ff 75 08             	pushl  0x8(%ebp)
  800a01:	e8 87 ff ff ff       	call   80098d <memmove>
}
  800a06:	c9                   	leave  
  800a07:	c3                   	ret    

00800a08 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a08:	55                   	push   %ebp
  800a09:	89 e5                	mov    %esp,%ebp
  800a0b:	56                   	push   %esi
  800a0c:	53                   	push   %ebx
  800a0d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a10:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a13:	89 c6                	mov    %eax,%esi
  800a15:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a18:	eb 1a                	jmp    800a34 <memcmp+0x2c>
		if (*s1 != *s2)
  800a1a:	0f b6 08             	movzbl (%eax),%ecx
  800a1d:	0f b6 1a             	movzbl (%edx),%ebx
  800a20:	38 d9                	cmp    %bl,%cl
  800a22:	74 0a                	je     800a2e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a24:	0f b6 c1             	movzbl %cl,%eax
  800a27:	0f b6 db             	movzbl %bl,%ebx
  800a2a:	29 d8                	sub    %ebx,%eax
  800a2c:	eb 0f                	jmp    800a3d <memcmp+0x35>
		s1++, s2++;
  800a2e:	83 c0 01             	add    $0x1,%eax
  800a31:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a34:	39 f0                	cmp    %esi,%eax
  800a36:	75 e2                	jne    800a1a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a38:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a3d:	5b                   	pop    %ebx
  800a3e:	5e                   	pop    %esi
  800a3f:	5d                   	pop    %ebp
  800a40:	c3                   	ret    

00800a41 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a41:	55                   	push   %ebp
  800a42:	89 e5                	mov    %esp,%ebp
  800a44:	53                   	push   %ebx
  800a45:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a48:	89 c1                	mov    %eax,%ecx
  800a4a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a4d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a51:	eb 0a                	jmp    800a5d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a53:	0f b6 10             	movzbl (%eax),%edx
  800a56:	39 da                	cmp    %ebx,%edx
  800a58:	74 07                	je     800a61 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5a:	83 c0 01             	add    $0x1,%eax
  800a5d:	39 c8                	cmp    %ecx,%eax
  800a5f:	72 f2                	jb     800a53 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a61:	5b                   	pop    %ebx
  800a62:	5d                   	pop    %ebp
  800a63:	c3                   	ret    

00800a64 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a64:	55                   	push   %ebp
  800a65:	89 e5                	mov    %esp,%ebp
  800a67:	57                   	push   %edi
  800a68:	56                   	push   %esi
  800a69:	53                   	push   %ebx
  800a6a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a6d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a70:	eb 03                	jmp    800a75 <strtol+0x11>
		s++;
  800a72:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a75:	0f b6 01             	movzbl (%ecx),%eax
  800a78:	3c 20                	cmp    $0x20,%al
  800a7a:	74 f6                	je     800a72 <strtol+0xe>
  800a7c:	3c 09                	cmp    $0x9,%al
  800a7e:	74 f2                	je     800a72 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a80:	3c 2b                	cmp    $0x2b,%al
  800a82:	75 0a                	jne    800a8e <strtol+0x2a>
		s++;
  800a84:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a87:	bf 00 00 00 00       	mov    $0x0,%edi
  800a8c:	eb 11                	jmp    800a9f <strtol+0x3b>
  800a8e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a93:	3c 2d                	cmp    $0x2d,%al
  800a95:	75 08                	jne    800a9f <strtol+0x3b>
		s++, neg = 1;
  800a97:	83 c1 01             	add    $0x1,%ecx
  800a9a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a9f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800aa5:	75 15                	jne    800abc <strtol+0x58>
  800aa7:	80 39 30             	cmpb   $0x30,(%ecx)
  800aaa:	75 10                	jne    800abc <strtol+0x58>
  800aac:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ab0:	75 7c                	jne    800b2e <strtol+0xca>
		s += 2, base = 16;
  800ab2:	83 c1 02             	add    $0x2,%ecx
  800ab5:	bb 10 00 00 00       	mov    $0x10,%ebx
  800aba:	eb 16                	jmp    800ad2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800abc:	85 db                	test   %ebx,%ebx
  800abe:	75 12                	jne    800ad2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ac0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac5:	80 39 30             	cmpb   $0x30,(%ecx)
  800ac8:	75 08                	jne    800ad2 <strtol+0x6e>
		s++, base = 8;
  800aca:	83 c1 01             	add    $0x1,%ecx
  800acd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800ad2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ad7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ada:	0f b6 11             	movzbl (%ecx),%edx
  800add:	8d 72 d0             	lea    -0x30(%edx),%esi
  800ae0:	89 f3                	mov    %esi,%ebx
  800ae2:	80 fb 09             	cmp    $0x9,%bl
  800ae5:	77 08                	ja     800aef <strtol+0x8b>
			dig = *s - '0';
  800ae7:	0f be d2             	movsbl %dl,%edx
  800aea:	83 ea 30             	sub    $0x30,%edx
  800aed:	eb 22                	jmp    800b11 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aef:	8d 72 9f             	lea    -0x61(%edx),%esi
  800af2:	89 f3                	mov    %esi,%ebx
  800af4:	80 fb 19             	cmp    $0x19,%bl
  800af7:	77 08                	ja     800b01 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800af9:	0f be d2             	movsbl %dl,%edx
  800afc:	83 ea 57             	sub    $0x57,%edx
  800aff:	eb 10                	jmp    800b11 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b01:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b04:	89 f3                	mov    %esi,%ebx
  800b06:	80 fb 19             	cmp    $0x19,%bl
  800b09:	77 16                	ja     800b21 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b0b:	0f be d2             	movsbl %dl,%edx
  800b0e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b11:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b14:	7d 0b                	jge    800b21 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b16:	83 c1 01             	add    $0x1,%ecx
  800b19:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b1d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b1f:	eb b9                	jmp    800ada <strtol+0x76>

	if (endptr)
  800b21:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b25:	74 0d                	je     800b34 <strtol+0xd0>
		*endptr = (char *) s;
  800b27:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b2a:	89 0e                	mov    %ecx,(%esi)
  800b2c:	eb 06                	jmp    800b34 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b2e:	85 db                	test   %ebx,%ebx
  800b30:	74 98                	je     800aca <strtol+0x66>
  800b32:	eb 9e                	jmp    800ad2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b34:	89 c2                	mov    %eax,%edx
  800b36:	f7 da                	neg    %edx
  800b38:	85 ff                	test   %edi,%edi
  800b3a:	0f 45 c2             	cmovne %edx,%eax
}
  800b3d:	5b                   	pop    %ebx
  800b3e:	5e                   	pop    %esi
  800b3f:	5f                   	pop    %edi
  800b40:	5d                   	pop    %ebp
  800b41:	c3                   	ret    
  800b42:	66 90                	xchg   %ax,%ax
  800b44:	66 90                	xchg   %ax,%ax
  800b46:	66 90                	xchg   %ax,%ax
  800b48:	66 90                	xchg   %ax,%ax
  800b4a:	66 90                	xchg   %ax,%ax
  800b4c:	66 90                	xchg   %ax,%ax
  800b4e:	66 90                	xchg   %ax,%ax

00800b50 <__udivdi3>:
  800b50:	55                   	push   %ebp
  800b51:	57                   	push   %edi
  800b52:	56                   	push   %esi
  800b53:	53                   	push   %ebx
  800b54:	83 ec 1c             	sub    $0x1c,%esp
  800b57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b67:	85 f6                	test   %esi,%esi
  800b69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b6d:	89 ca                	mov    %ecx,%edx
  800b6f:	89 f8                	mov    %edi,%eax
  800b71:	75 3d                	jne    800bb0 <__udivdi3+0x60>
  800b73:	39 cf                	cmp    %ecx,%edi
  800b75:	0f 87 c5 00 00 00    	ja     800c40 <__udivdi3+0xf0>
  800b7b:	85 ff                	test   %edi,%edi
  800b7d:	89 fd                	mov    %edi,%ebp
  800b7f:	75 0b                	jne    800b8c <__udivdi3+0x3c>
  800b81:	b8 01 00 00 00       	mov    $0x1,%eax
  800b86:	31 d2                	xor    %edx,%edx
  800b88:	f7 f7                	div    %edi
  800b8a:	89 c5                	mov    %eax,%ebp
  800b8c:	89 c8                	mov    %ecx,%eax
  800b8e:	31 d2                	xor    %edx,%edx
  800b90:	f7 f5                	div    %ebp
  800b92:	89 c1                	mov    %eax,%ecx
  800b94:	89 d8                	mov    %ebx,%eax
  800b96:	89 cf                	mov    %ecx,%edi
  800b98:	f7 f5                	div    %ebp
  800b9a:	89 c3                	mov    %eax,%ebx
  800b9c:	89 d8                	mov    %ebx,%eax
  800b9e:	89 fa                	mov    %edi,%edx
  800ba0:	83 c4 1c             	add    $0x1c,%esp
  800ba3:	5b                   	pop    %ebx
  800ba4:	5e                   	pop    %esi
  800ba5:	5f                   	pop    %edi
  800ba6:	5d                   	pop    %ebp
  800ba7:	c3                   	ret    
  800ba8:	90                   	nop
  800ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bb0:	39 ce                	cmp    %ecx,%esi
  800bb2:	77 74                	ja     800c28 <__udivdi3+0xd8>
  800bb4:	0f bd fe             	bsr    %esi,%edi
  800bb7:	83 f7 1f             	xor    $0x1f,%edi
  800bba:	0f 84 98 00 00 00    	je     800c58 <__udivdi3+0x108>
  800bc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bc5:	89 f9                	mov    %edi,%ecx
  800bc7:	89 c5                	mov    %eax,%ebp
  800bc9:	29 fb                	sub    %edi,%ebx
  800bcb:	d3 e6                	shl    %cl,%esi
  800bcd:	89 d9                	mov    %ebx,%ecx
  800bcf:	d3 ed                	shr    %cl,%ebp
  800bd1:	89 f9                	mov    %edi,%ecx
  800bd3:	d3 e0                	shl    %cl,%eax
  800bd5:	09 ee                	or     %ebp,%esi
  800bd7:	89 d9                	mov    %ebx,%ecx
  800bd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bdd:	89 d5                	mov    %edx,%ebp
  800bdf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800be3:	d3 ed                	shr    %cl,%ebp
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	d3 e2                	shl    %cl,%edx
  800be9:	89 d9                	mov    %ebx,%ecx
  800beb:	d3 e8                	shr    %cl,%eax
  800bed:	09 c2                	or     %eax,%edx
  800bef:	89 d0                	mov    %edx,%eax
  800bf1:	89 ea                	mov    %ebp,%edx
  800bf3:	f7 f6                	div    %esi
  800bf5:	89 d5                	mov    %edx,%ebp
  800bf7:	89 c3                	mov    %eax,%ebx
  800bf9:	f7 64 24 0c          	mull   0xc(%esp)
  800bfd:	39 d5                	cmp    %edx,%ebp
  800bff:	72 10                	jb     800c11 <__udivdi3+0xc1>
  800c01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e6                	shl    %cl,%esi
  800c09:	39 c6                	cmp    %eax,%esi
  800c0b:	73 07                	jae    800c14 <__udivdi3+0xc4>
  800c0d:	39 d5                	cmp    %edx,%ebp
  800c0f:	75 03                	jne    800c14 <__udivdi3+0xc4>
  800c11:	83 eb 01             	sub    $0x1,%ebx
  800c14:	31 ff                	xor    %edi,%edi
  800c16:	89 d8                	mov    %ebx,%eax
  800c18:	89 fa                	mov    %edi,%edx
  800c1a:	83 c4 1c             	add    $0x1c,%esp
  800c1d:	5b                   	pop    %ebx
  800c1e:	5e                   	pop    %esi
  800c1f:	5f                   	pop    %edi
  800c20:	5d                   	pop    %ebp
  800c21:	c3                   	ret    
  800c22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c28:	31 ff                	xor    %edi,%edi
  800c2a:	31 db                	xor    %ebx,%ebx
  800c2c:	89 d8                	mov    %ebx,%eax
  800c2e:	89 fa                	mov    %edi,%edx
  800c30:	83 c4 1c             	add    $0x1c,%esp
  800c33:	5b                   	pop    %ebx
  800c34:	5e                   	pop    %esi
  800c35:	5f                   	pop    %edi
  800c36:	5d                   	pop    %ebp
  800c37:	c3                   	ret    
  800c38:	90                   	nop
  800c39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c40:	89 d8                	mov    %ebx,%eax
  800c42:	f7 f7                	div    %edi
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 c3                	mov    %eax,%ebx
  800c48:	89 d8                	mov    %ebx,%eax
  800c4a:	89 fa                	mov    %edi,%edx
  800c4c:	83 c4 1c             	add    $0x1c,%esp
  800c4f:	5b                   	pop    %ebx
  800c50:	5e                   	pop    %esi
  800c51:	5f                   	pop    %edi
  800c52:	5d                   	pop    %ebp
  800c53:	c3                   	ret    
  800c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c58:	39 ce                	cmp    %ecx,%esi
  800c5a:	72 0c                	jb     800c68 <__udivdi3+0x118>
  800c5c:	31 db                	xor    %ebx,%ebx
  800c5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c62:	0f 87 34 ff ff ff    	ja     800b9c <__udivdi3+0x4c>
  800c68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c6d:	e9 2a ff ff ff       	jmp    800b9c <__udivdi3+0x4c>
  800c72:	66 90                	xchg   %ax,%ax
  800c74:	66 90                	xchg   %ax,%ax
  800c76:	66 90                	xchg   %ax,%ax
  800c78:	66 90                	xchg   %ax,%ax
  800c7a:	66 90                	xchg   %ax,%ax
  800c7c:	66 90                	xchg   %ax,%ax
  800c7e:	66 90                	xchg   %ax,%ax

00800c80 <__umoddi3>:
  800c80:	55                   	push   %ebp
  800c81:	57                   	push   %edi
  800c82:	56                   	push   %esi
  800c83:	53                   	push   %ebx
  800c84:	83 ec 1c             	sub    $0x1c,%esp
  800c87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c97:	85 d2                	test   %edx,%edx
  800c99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ca1:	89 f3                	mov    %esi,%ebx
  800ca3:	89 3c 24             	mov    %edi,(%esp)
  800ca6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800caa:	75 1c                	jne    800cc8 <__umoddi3+0x48>
  800cac:	39 f7                	cmp    %esi,%edi
  800cae:	76 50                	jbe    800d00 <__umoddi3+0x80>
  800cb0:	89 c8                	mov    %ecx,%eax
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	f7 f7                	div    %edi
  800cb6:	89 d0                	mov    %edx,%eax
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	83 c4 1c             	add    $0x1c,%esp
  800cbd:	5b                   	pop    %ebx
  800cbe:	5e                   	pop    %esi
  800cbf:	5f                   	pop    %edi
  800cc0:	5d                   	pop    %ebp
  800cc1:	c3                   	ret    
  800cc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cc8:	39 f2                	cmp    %esi,%edx
  800cca:	89 d0                	mov    %edx,%eax
  800ccc:	77 52                	ja     800d20 <__umoddi3+0xa0>
  800cce:	0f bd ea             	bsr    %edx,%ebp
  800cd1:	83 f5 1f             	xor    $0x1f,%ebp
  800cd4:	75 5a                	jne    800d30 <__umoddi3+0xb0>
  800cd6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cda:	0f 82 e0 00 00 00    	jb     800dc0 <__umoddi3+0x140>
  800ce0:	39 0c 24             	cmp    %ecx,(%esp)
  800ce3:	0f 86 d7 00 00 00    	jbe    800dc0 <__umoddi3+0x140>
  800ce9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ced:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cf1:	83 c4 1c             	add    $0x1c,%esp
  800cf4:	5b                   	pop    %ebx
  800cf5:	5e                   	pop    %esi
  800cf6:	5f                   	pop    %edi
  800cf7:	5d                   	pop    %ebp
  800cf8:	c3                   	ret    
  800cf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d00:	85 ff                	test   %edi,%edi
  800d02:	89 fd                	mov    %edi,%ebp
  800d04:	75 0b                	jne    800d11 <__umoddi3+0x91>
  800d06:	b8 01 00 00 00       	mov    $0x1,%eax
  800d0b:	31 d2                	xor    %edx,%edx
  800d0d:	f7 f7                	div    %edi
  800d0f:	89 c5                	mov    %eax,%ebp
  800d11:	89 f0                	mov    %esi,%eax
  800d13:	31 d2                	xor    %edx,%edx
  800d15:	f7 f5                	div    %ebp
  800d17:	89 c8                	mov    %ecx,%eax
  800d19:	f7 f5                	div    %ebp
  800d1b:	89 d0                	mov    %edx,%eax
  800d1d:	eb 99                	jmp    800cb8 <__umoddi3+0x38>
  800d1f:	90                   	nop
  800d20:	89 c8                	mov    %ecx,%eax
  800d22:	89 f2                	mov    %esi,%edx
  800d24:	83 c4 1c             	add    $0x1c,%esp
  800d27:	5b                   	pop    %ebx
  800d28:	5e                   	pop    %esi
  800d29:	5f                   	pop    %edi
  800d2a:	5d                   	pop    %ebp
  800d2b:	c3                   	ret    
  800d2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d30:	8b 34 24             	mov    (%esp),%esi
  800d33:	bf 20 00 00 00       	mov    $0x20,%edi
  800d38:	89 e9                	mov    %ebp,%ecx
  800d3a:	29 ef                	sub    %ebp,%edi
  800d3c:	d3 e0                	shl    %cl,%eax
  800d3e:	89 f9                	mov    %edi,%ecx
  800d40:	89 f2                	mov    %esi,%edx
  800d42:	d3 ea                	shr    %cl,%edx
  800d44:	89 e9                	mov    %ebp,%ecx
  800d46:	09 c2                	or     %eax,%edx
  800d48:	89 d8                	mov    %ebx,%eax
  800d4a:	89 14 24             	mov    %edx,(%esp)
  800d4d:	89 f2                	mov    %esi,%edx
  800d4f:	d3 e2                	shl    %cl,%edx
  800d51:	89 f9                	mov    %edi,%ecx
  800d53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d5b:	d3 e8                	shr    %cl,%eax
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	89 c6                	mov    %eax,%esi
  800d61:	d3 e3                	shl    %cl,%ebx
  800d63:	89 f9                	mov    %edi,%ecx
  800d65:	89 d0                	mov    %edx,%eax
  800d67:	d3 e8                	shr    %cl,%eax
  800d69:	89 e9                	mov    %ebp,%ecx
  800d6b:	09 d8                	or     %ebx,%eax
  800d6d:	89 d3                	mov    %edx,%ebx
  800d6f:	89 f2                	mov    %esi,%edx
  800d71:	f7 34 24             	divl   (%esp)
  800d74:	89 d6                	mov    %edx,%esi
  800d76:	d3 e3                	shl    %cl,%ebx
  800d78:	f7 64 24 04          	mull   0x4(%esp)
  800d7c:	39 d6                	cmp    %edx,%esi
  800d7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d82:	89 d1                	mov    %edx,%ecx
  800d84:	89 c3                	mov    %eax,%ebx
  800d86:	72 08                	jb     800d90 <__umoddi3+0x110>
  800d88:	75 11                	jne    800d9b <__umoddi3+0x11b>
  800d8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d8e:	73 0b                	jae    800d9b <__umoddi3+0x11b>
  800d90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d94:	1b 14 24             	sbb    (%esp),%edx
  800d97:	89 d1                	mov    %edx,%ecx
  800d99:	89 c3                	mov    %eax,%ebx
  800d9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d9f:	29 da                	sub    %ebx,%edx
  800da1:	19 ce                	sbb    %ecx,%esi
  800da3:	89 f9                	mov    %edi,%ecx
  800da5:	89 f0                	mov    %esi,%eax
  800da7:	d3 e0                	shl    %cl,%eax
  800da9:	89 e9                	mov    %ebp,%ecx
  800dab:	d3 ea                	shr    %cl,%edx
  800dad:	89 e9                	mov    %ebp,%ecx
  800daf:	d3 ee                	shr    %cl,%esi
  800db1:	09 d0                	or     %edx,%eax
  800db3:	89 f2                	mov    %esi,%edx
  800db5:	83 c4 1c             	add    $0x1c,%esp
  800db8:	5b                   	pop    %ebx
  800db9:	5e                   	pop    %esi
  800dba:	5f                   	pop    %edi
  800dbb:	5d                   	pop    %ebp
  800dbc:	c3                   	ret    
  800dbd:	8d 76 00             	lea    0x0(%esi),%esi
  800dc0:	29 f9                	sub    %edi,%ecx
  800dc2:	19 d6                	sbb    %edx,%esi
  800dc4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800dc8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dcc:	e9 18 ff ff ff       	jmp    800ce9 <__umoddi3+0x69>
