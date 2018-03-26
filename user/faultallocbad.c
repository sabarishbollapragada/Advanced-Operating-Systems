// test user-level fault handler -- alloc pages to fix faults
// doesn't work because we sys_cputs instead of cprintf (exercise: why?)

#include <inc/lib.h>
//const char *hello = "hello, world\n";
//const char *DEADBEEF = "hello, world\n";
void
handler(struct UTrapframe *utf)
{
	int r;
	void *addr = (void*)utf->utf_fault_va;

	cprintf("fault %x\n", addr);
	if ((r = sys_page_alloc(0, ROUNDDOWN(addr, PGSIZE),
				PTE_P|PTE_U|PTE_W)) < 0)
		panic("allocating at %x in page fault handler: %e", addr, r);
	snprintf((char*) addr, 100, "this string was faulted in at %x", addr);
}

void
umain(int argc, char **argv)
{
	set_pgfault_handler(handler);
	
	sys_cputs((char*)0xDEADBEEF, 4);
	
	//sys_cputs((char*)0xeebfe000, 1024);//failure:ustacktop//
	//sys_cputs((char*)0xeebfefff, 1024);//failure:emptymemory:user exception stack+1//
	//sys_cputs((char*)0xeebff000, 1024);//no failure: user exception stack//
	//sys_cputs((char*)0xef400000, 1024);//no failure: uvpt//
	//sys_cputs((char*)0xef7fffff, 1024);//no failure: ulim-1//
	//sys_cputs((char*)0xef800000, 1024);//failure: ulim//	

/****************no failure when the address range is between uxstacktop and ulim**************/


	//sys_cputs("0xDEADBEEF\n", 1024);
	//sys_cputs(DEADBEEF, 1024);
	//sys_cputs(hello, 1024);
}
