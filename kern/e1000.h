#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <kern/pci.h>

#include <kern/pmap.h>
#include <inc/string.h>

//PCI Device ID and vendor ID
#define	PCI_E1000_VENDORID		0x8086
#define	PCI_E1000_DEVICEID		0x100E

//Ex 5: max number of the descriptors in the descriptor array is 64
//max size of ethernet packet is 1518 bytes
#define E1000_TX_MAXDESC        	64
#define E1000_TXPKT_MAX 		1518
#define E1000_TXD_STAT_DD 		0x00000001 /* Descriptor Done */
#define E1000_TDBAL    			0x03800/4  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    			0x03804/4  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    			0x03808/4  /* TX Descriptor Length - RW */
#define E1000_TDH      			0x03810/4  /* TX Descriptor Head - RW */
#define E1000_TDT      			0x03818/4  /* TX Descripotr Tail - RW */
#define E1000_TIPG     			0x00410/4  /* TX Inter-packet gap -RW */
#define E1000_CTRL_ILOS     		0x00000080/4  /* Invert Loss-Of Signal */
#define E1000_TCTL     			0x00400/4  /* TX Control - RW */

#define E1000_TCTL_EN     		0x00000002    /* enable tx */
#define E1000_TCTL_PSP    		0x00000008    /* pad short packets */
#define E1000_TCTL_CT     		0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD 		0x003ff000 /* collision distance */	


//Ex 4: volatile pointer and status reg address
#define E1000_STATUS   			0x00008/4  /* Device Status - RO */

#define E1000_RX_MAXDESC        128
#define E1000_RXPKT_MAX 2048

// Receivers definitions

#define E1000_RA       0x05400/4  /* Receive Address - RW Array */
#define E1000_RAL      0x05400 / 4  /* Receive Address Low - RW */
#define E1000_RAH      0x05404 / 4  /* Receive Address HIGH - RW */
#define E1000_IMS      0x000D0/4  /* Interrupt Mask Set - RW */
#define E1000_RDTR     0x02820/4  /* RX Delay Timer - RW */
#define E1000_RDBAL    0x02800/4  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804/4  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808/4  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810/4  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818/4  /* RX Descriptor Tail - RW */
#define E1000_RCTL     0x00100/4  /* RX Control - RW */

#define E1000_ICR_LSC           0x00000004 /* Link Status Change */
#define E1000_ICR_RXSEQ         0x00000008 /* rx sequence error */
#define E1000_ICR_RXDMT0        0x00000010 /* rx desc min. threshold (0) */
#define E1000_ICR_RXO           0x00000040 /* rx overrun */
#define E1000_ICR_RXT0          0x00000080 /* rx timer intr (ring 0) */
#define E1000_IMS_LSC       E1000_ICR_LSC       /* Link Status Change */
#define E1000_IMS_RXSEQ     E1000_ICR_RXSEQ     /* rx sequence error */
#define E1000_IMS_RXDMT0    E1000_ICR_RXDMT0    /* rx desc min. threshold */
#define E1000_IMS_RXO       E1000_ICR_RXO       /* rx overrun */
#define E1000_IMS_RXT0      E1000_ICR_RXT0      /* rx timer intr */
/* Receive Control */
#define E1000_RCTL_RST            0x00000001    /* Software reset */
#define E1000_RCTL_EN             0x00000002    /* enable */
#define E1000_RCTL_SBP            0x00000004    /* store bad packet */
#define E1000_RCTL_UPE            0x00000008    /* unicast promiscuous enable */
#define E1000_RCTL_MPE            0x00000010    /* multicast promiscuous enab */
#define E1000_RCTL_LPE            0x00000020    /* long packet enable */
#define E1000_RCTL_LBM_NO         0x00000000    /* no loopback mode */
#define E1000_RCTL_LBM_MAC        0x00000040    /* MAC loopback mode */
#define E1000_RCTL_LBM_SLP        0x00000080    /* serial link loopback mode */
#define E1000_RCTL_LBM_TCVR       0x000000C0    /* tcvr loopback mode */
#define E1000_RCTL_DTYP_MASK      0x00000C00    /* Descriptor type mask */
#define E1000_RCTL_DTYP_PS        0x00000400    /* Packet Split descriptor */
#define E1000_RCTL_RDMTS_HALF     0x00000000    /* rx desc min threshold size */
#define E1000_RCTL_RDMTS_QUAT     0x00000100    /* rx desc min threshold size */
#define E1000_RCTL_RDMTS_EIGTH    0x00000200    /* rx desc min threshold size */
#define E1000_RCTL_MO_SHIFT       12            /* multicast offset shift */
#define E1000_RCTL_MO_0           0x00000000    /* multicast offset 11:0 */
#define E1000_RCTL_MO_1           0x00001000    /* multicast offset 12:1 */
#define E1000_RCTL_MO_2           0x00002000    /* multicast offset 13:2 */
#define E1000_RCTL_MO_3           0x00003000    /* multicast offset 15:4 */
#define E1000_RCTL_MDR            0x00004000    /* multicast desc ring 0 */
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 0 */
#define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */
#define E1000_RCTL_SZ_1024        0x00010000    /* rx buffer size 1024 */
#define E1000_RCTL_SZ_512         0x00020000    /* rx buffer size 512 */
#define E1000_RCTL_SZ_256         0x00030000    /* rx buffer size 256 */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 1 */
#define E1000_RCTL_SZ_16384       0x00010000    /* rx buffer size 16384 */
#define E1000_RCTL_SZ_8192        0x00020000    /* rx buffer size 8192 */
#define E1000_RCTL_SZ_4096        0x00030000    /* rx buffer size 4096 */
#define E1000_RCTL_VFE            0x00040000    /* vlan filter enable */
#define E1000_RCTL_CFIEN          0x00080000    /* canonical form enable */
#define E1000_RCTL_CFI            0x00100000    /* canonical form indicator */
#define E1000_RCTL_DPF            0x00400000    /* discard pause frames */
#define E1000_RCTL_PMCF           0x00800000    /* pass MAC control frames */
#define E1000_RCTL_BSEX           0x02000000    /* Buffer size extension */
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */
#define E1000_RCTL_FLXBUF_MASK    0x78000000    /* Flexible buffer size */
#define E1000_RCTL_FLXBUF_SHIFT   27            /* Flexible buffer shift */

#define E1000_RAH_AV 0x80000000 /* Receive descriptor valid */
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP 0x02 /* End of Packet */

//Challenge
#define E1000_EERD     0x00014 / 4  /* EEPROM Read - RW */
/* EEPROM Control */
#define E1000_EEPROM_RW_REG_DONE   0x10 /* Offset to READ/WRITE done bit */
#define E1000_EEPROM_RW_REG_START  1    /* First bit for telling part to start operation */
#define E1000_EEPROM_RW_ADDR_SHIFT 8    /* Shift to the address bits */
#define E1000_EEPROM_RW_REG_DATA   16   /* Offset to data in EEPROM read/write registers */

volatile uint32_t *mmio_e1000;

//Ex 3: attach function
int e1000_attach(struct pci_func *pcif);

//Ex 5: transmit initialization functions
static void init_desc();
static void e1000_init();


//Ex 6 : transmitting a packet
int transmit_packet(void *pkt_inputData, size_t size);
//Ex 11 : receiving a packet
int receive_packet(void *pkt_outputData);
//Challenge
void read_mac_address(uint8_t* mac_address);

//Ex 5: transmit descriptor structure
struct e1000_tx_desc {
    uint64_t buffer_addr;       /* Address of the descriptor's data buffer */
    union {
        struct {
            uint16_t length;    /* Data buffer length */
            uint8_t cso;        /* Checksum offset */
            uint8_t cmd;        /* Command field */
        } flags;
    } lower;
    union {
        struct {
            uint8_t status;     /* Descriptor status */
            uint8_t css;        /* Checksum start */
            uint16_t special;
        } fields;
    } upper;
};


// transmit Packet Definition
struct packets_tx
{
	char buffer[E1000_TXPKT_MAX];
};

struct packets_rx
{
	char buffer[E1000_RXPKT_MAX];
};

/* Receive Descriptor */
struct e1000_rx_desc {
    uint64_t buffer_addr; /* Address of the descriptor's data buffer */
    uint16_t length;     /* Length of data DMAed into data buffer */
    uint16_t csum;       /* Packet checksum */
    uint8_t status;      /* Descriptor status */
    uint8_t errors;      /* Descriptor Errors */
    uint16_t special;
};


#endif	// JOS_KERN_E1000_H


