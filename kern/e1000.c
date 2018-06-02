#include <kern/e1000.h>

// LAB 6: Your driver code here

//Ex 5 : Initialization of transmit descriptor queue and transmit packet buffer
struct e1000_tx_desc  e1000_txQ[E1000_TX_MAXDESC] __attribute__ ((aligned (16)));
struct packets_tx pkts_tx_buf[E1000_TX_MAXDESC];

struct e1000_rx_desc  e1000_rxQ[E1000_RX_MAXDESC] __attribute__ ((aligned (16)));
struct packets_rx pkts_rx_buf[E1000_RX_MAXDESC];

 uint32_t real_tail = 0;

//Ex 3 and 4 : enable pci device and create mmmio mapping for the device
int e1000_attach(struct pci_func *pcif){

	// enable PCI function
 	pci_func_enable(pcif);

	// initialize descriptor
	init_desc();

	// create virtual memory mapping
	mmio_e1000 = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
	cprintf("Printing the status register = %x\n", mmio_e1000[E1000_STATUS]);
	assert(mmio_e1000[E1000_STATUS] == 0x80080783);

	// initialize the e1000 hardware registers
	e1000_init();
	cprintf("RAL Register value : %x\n",mmio_e1000[E1000_RAL]);
	cprintf("RAH Register value : %x\n",mmio_e1000[E1000_RAH]);
	return 0;
}


// Ex 5
static void init_desc()
{
int i;
for (i = 0; i < E1000_TX_MAXDESC; ++i)
{
  e1000_txQ[i].buffer_addr = PADDR(&pkts_tx_buf[i]);
  e1000_txQ[i].upper.fields.status = E1000_TXD_STAT_DD;
}

for(i=0; i < E1000_RX_MAXDESC; i++)
	{
		e1000_rxQ[i].buffer_addr = PADDR(pkts_rx_buf[i].buffer); // set packet buffer address to Descriptor
		//e1000_rxQ[i].status = ~(E1000_RXD_STAT_DD); // set RS bit of CMD
		
}
}


static void e1000_init(){
	assert(mmio_e1000[E1000_STATUS] == 0x80080783);
	mmio_e1000[E1000_TDBAL] = PADDR(e1000_txQ);
	mmio_e1000[E1000_TDBAH] = 0x0;
	mmio_e1000[E1000_TDH] = 0x0;
	mmio_e1000[E1000_TDT] = 0x0;
	mmio_e1000[E1000_TDLEN] = sizeof(struct e1000_tx_desc) * E1000_TX_MAXDESC;
	

	mmio_e1000[E1000_TCTL] |= E1000_TCTL_EN;
	mmio_e1000[E1000_TCTL] |= E1000_TCTL_PSP;
	mmio_e1000[E1000_TCTL] |= (0x10) << 4;
	mmio_e1000[E1000_TCTL] |= (0x40) << 12;
	
	
	mmio_e1000[E1000_TIPG] = 0;
	mmio_e1000[E1000_TIPG] |= 0xA;
	mmio_e1000[E1000_TIPG] |= (0x4) << 10;
	mmio_e1000[E1000_TIPG] |= (0xC) << 20;


	
	/*mmio_e1000[E1000_RAL] = 0x12005452;
	mmio_e1000[E1000_RAH] = 0x00005634 | E1000_RAH_AV;*/
	// LAB 6: Challenge: read MAC Address from EEPROM
 mmio_e1000[E1000_EERD] = 0x0 << E1000_EEPROM_RW_ADDR_SHIFT;
 mmio_e1000[E1000_EERD] |= E1000_EEPROM_RW_REG_START;
 while (!(mmio_e1000[E1000_EERD] & E1000_EEPROM_RW_REG_DONE));
 mmio_e1000[E1000_RAL] = mmio_e1000[E1000_EERD] >> E1000_EEPROM_RW_REG_DATA;

 
 mmio_e1000[E1000_EERD] = 0x1 << E1000_EEPROM_RW_ADDR_SHIFT;
 mmio_e1000[E1000_EERD] |= E1000_EEPROM_RW_REG_START;
 while (!(mmio_e1000[E1000_EERD] & E1000_EEPROM_RW_REG_DONE));
 mmio_e1000[E1000_RAL] |= mmio_e1000[E1000_EERD] & 0xffff0000;
 
 mmio_e1000[E1000_EERD] = 0x2 << E1000_EEPROM_RW_ADDR_SHIFT;
 mmio_e1000[E1000_EERD] |= E1000_EEPROM_RW_REG_START;
 while (!(mmio_e1000[E1000_EERD] & E1000_EEPROM_RW_REG_DONE));
 mmio_e1000[E1000_RAH] = mmio_e1000[E1000_EERD] >> 16;

 mmio_e1000[E1000_RAH] |= E1000_RAH_AV;





	mmio_e1000[E1000_RDH] = 0x0;
	mmio_e1000[E1000_RDT] = E1000_RX_MAXDESC;
	//mmio_e1000[E1000_RDT] = 0x0;
	mmio_e1000[E1000_RDBAL] = PADDR(e1000_rxQ);
	mmio_e1000[E1000_RDBAH] = 0;
	mmio_e1000[E1000_RDLEN] = sizeof(struct e1000_rx_desc) * E1000_RX_MAXDESC;
	mmio_e1000[E1000_RCTL] = 0;
	
	
	// IMS for receiver
	/*mmio_e1000[E1000_RCTL] |= E1000_RCTL_LPE;
	mmio_e1000[E1000_RCTL] |= E1000_RCTL_LBM_NO;
	mmio_e1000[E1000_RCTL] |= E1000_RCTL_BAM;
	mmio_e1000[E1000_RCTL] |= E1000_RCTL_SZ_2048;
	mmio_e1000[E1000_RCTL] |= E1000_RCTL_SECRC;*/
	mmio_e1000[E1000_RCTL] = E1000_RCTL_EN |
          !E1000_RCTL_LPE |
           E1000_RCTL_LBM_NO |
           E1000_RCTL_RDMTS_HALF |
           E1000_RCTL_MO_0 |
           E1000_RCTL_BAM |
           E1000_RCTL_BSEX |
           E1000_RCTL_SZ_2048 |
           E1000_RCTL_SECRC;

}

void read_mac_address(uint8_t* mac_address){
 *(uint32_t*)mac_address = (uint32_t)mmio_e1000[E1000_RAL];
 *(uint16_t*)(mac_address + 4) = (uint16_t)mmio_e1000[E1000_RAH];
 
 }
//Ex 12 : receive packet function
int receive_packet(void *pkt_outputData)
{
		
        struct e1000_rx_desc * tail_desc = &e1000_rxQ[real_tail];
        if (!(tail_desc->status & E1000_RXD_STAT_DD))
        {
                return -1;
        }
        size_t length = tail_desc->length;
        memmove(pkt_outputData, &pkts_rx_buf[real_tail], length);
        tail_desc->status = 0;
        mmio_e1000[E1000_RDT] = real_tail;
        real_tail = (real_tail + 1) % E1000_RX_MAXDESC;
	return length;


}
//Ex 6 : transmit packet function
int transmit_packet(void *pkt_inputData, size_t size)
{

	//assigning tail next to point to TDT register
	uint32_t tail_next = mmio_e1000[E1000_TDT];

	//check if DD bit is set
	if((e1000_txQ[tail_next].upper.fields.status & 0x1) == 1)
	{

		//move the packet data to the packet buffer pointed by tail next
		memmove((void *) &pkts_tx_buf[tail_next], pkt_inputData, size);

		//make the DD bit zero since packet has not transmitted yet
		e1000_txQ[tail_next].upper.fields.status &= 0xFE;

		//make the transmit descriptor length field equal to packet size
		e1000_txQ[tail_next].lower.flags.length = size;

		//Setting the RS bit and EOP bit to 1 to indicate for ethernet controller to report status
		//and to show end of packet
		e1000_txQ[tail_next].lower.flags.cmd |= 0x00000008 | 0x00000001;

		//making the TDT register point to next location in the trasnmit descriptor queue
		mmio_e1000[E1000_TDT] = (mmio_e1000[E1000_TDT] + 1) % E1000_TX_MAXDESC;

		
		return 0;
	}
	panic("The queue is full!!");
	return 0;
}


