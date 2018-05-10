/*
 * Lowlevel setup for ORIGEN board based on EXYNOS4210
 *
 * Copyright (C) 2011 Samsung Electronics
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <config.h>
#include <version.h>
#include <asm/arch/cpu.h>
#include "origen_setup.h"

#include <reg_val.h>
/*
 * Register usages:
 *
 * r5 has zero always
 * r7 has GPIO part1 base 0x11400000
 * r6 has GPIO part2 base 0x11000000
 */

_TEXT_BASE:
	.word	CONFIG_SYS_TEXT_BASE

	.globl lowlevel_init
lowlevel_init:
	push	{lr}

	/* r5 has always zero */
	mov	r5, #0
	ldr	r7, =EXYNOS4_GPIO_PART1_BASE
	ldr	r6, =EXYNOS4_GPIO_PART2_BASE

	/* check reset status */
	ldr	r0, =(EXYNOS4_POWER_BASE + INFORM1_OFFSET)
	ldr	r1, [r0]

	/* AFTR wakeup reset */
	ldr	r2, =S5P_CHECK_DIDLE
	cmp	r1, r2
	beq	exit_wakeup

	/* LPA wakeup reset */
	ldr	r2, =S5P_CHECK_LPA
	cmp	r1, r2
	beq	exit_wakeup

	/* Sleep wakeup reset */
	ldr	r2, =S5P_CHECK_SLEEP
	cmp	r1, r2
	beq	wakeup_reset

	/*
	 * If U-boot is already running in ram, no need to relocate U-Boot.
	 * Memory controller must be configured before relocating U-Boot
	 * in ram.
	 */
	ldr	r0, =0x0ffffff		/* r0 <- Mask Bits*/
	bic	r1, pc, r0		/* pc <- current addr of code */
					/* r1 <- unmasked bits of pc */
	ldr	r2, _TEXT_BASE		/* r2 <- original base addr in ram */
	bic	r2, r2, r0		/* r2 <- unmasked bits of r2*/
	cmp	r1, r2			/* compare r1, r2 */
	beq	1f			/* r0 == r1 then skip sdram init */

	/* init system clock */
	bl system_clock_init

	/* Memory initialize */
	bl mem_ctrl_asm_init

	/* SAM init for DM9000 */
	bl srom_ctrl_init
1:
	/* for UART */
	bl uart_asm_init
@	bl tzpc_init
	pop	{pc}

wakeup_reset:
	bl system_clock_init
	bl mem_ctrl_asm_init
@	bl tzpc_init

exit_wakeup:
	/* Load return address and jump to kernel */
	ldr	r0, =(EXYNOS4_POWER_BASE + INFORM0_OFFSET)

	/* r1 = physical address of exynos4210_cpu_resume function */
	ldr	r1, [r0]

	/* Jump to kernel*/
	mov	pc, r1
	nop
	nop

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */

	.globl system_clock_init

system_clock_init:
	push	{lr}
	
	ldr	r0, =ELFIN_CLOCK_BASE

	/* CMU_CPU MUX / DIV */
	ldr	r1, =0x0
	ldr	r2, =CLK_SRC_CPU_OFFSET
	str	r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x10000
1:	subs	r1, r1, #1
	bne	1b

	ldr	r1, =CLK_DIV_DMC0_VAL
	ldr	r2, =CLK_DIV_DMC0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_DMC1_VAL
	ldr	r2, =CLK_DIV_DMC1_OFFSET
	str	r1, [r0, r2]

	/* CMU_TOP MUX / DIV */
	ldr	r1, =CLK_SRC_TOP0_VAL
	ldr	r2, =CLK_SRC_TOP0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_SRC_TOP1_VAL
	ldr	r2, =CLK_SRC_TOP1_OFFSET
	str	r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x10000
3:	subs	r1, r1, #1
	bne	3b

	ldr	r1, =CLK_DIV_TOP_VAL
	ldr	r2, =CLK_DIV_TOP_OFFSET
	str	r1, [r0, r2]

	/* CMU_LEFTBUS MUX / DIV */
	ldr	r1, =CLK_SRC_LEFTBUS_VAL
	ldr	r2, =CLK_SRC_LEFTBUS_OFFSET
	str	r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x10000
4:	subs	r1, r1, #1
	bne	4b

	ldr	r1, =CLK_DIV_LEFRBUS_VAL
	ldr	r2, =CLK_DIV_LEFTBUS_OFFSET
	str	r1, [r0, r2]

	/* CMU_RIGHTBUS MUX / DIV */
	ldr	r1, =CLK_SRC_RIGHTBUS_VAL
	ldr	r2, =CLK_SRC_RIGHTBUS_OFFSET
	str	r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x10000
5:	subs	r1, r1, #1
	bne	5b

	ldr	r1, =CLK_DIV_RIGHTBUS_VAL
	ldr	r2, =CLK_DIV_RIGHTBUS_OFFSET
	str	r1, [r0, r2]

	/* Set PLL locktime */
	ldr	r1, =APLL_LOCK_VAL
	ldr	r2, =APLL_LOCK_OFFSET
	str	r1, [r0, r2]

	ldr	r1, =MPLL_LOCK_VAL
	ldr	r2, =MPLL_LOCK_OFFSET
	str	r1, [r0, r2]

	ldr	r1, =EPLL_LOCK_VAL
	ldr	r2, =EPLL_LOCK_OFFSET
	str	r1, [r0, r2]

	ldr	r1, =VPLL_LOCK_VAL
	ldr	r2, =VPLL_LOCK_OFFSET
	str	r1, [r0, r2]

	ldr	r1, =CLK_DIV_CPU0_VAL
	ldr	r2, =CLK_DIV_CPU0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_CPU1_VAL
	ldr	r2, =CLK_DIV_CPU1_OFFSET
	str	r1, [r0, r2]

	/* Set APLL */
	ldr	r1, =APLL_CON1_VAL
	ldr	r2, =APLL_CON1_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =APLL_CON0_VAL
	ldr	r2, =APLL_CON0_OFFSET
	str	r1, [r0, r2]

	/* Set MPLL */
	ldr	r1, =MPLL_CON1_VAL
	ldr	r2, =MPLL_CON1_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =MPLL_CON0_VAL
	ldr	r2, =MPLL_CON0_OFFSET
	str	r1, [r0, r2]

	/* Set EPLL */
	ldr     r1, =EPLL_CON2_VAL
	ldr     r2, =EPLL_CON2_OFFSET
	str     r1, [r0, r2]
	ldr     r1, =EPLL_CON1_VAL
	ldr     r2, =EPLL_CON1_OFFSET
	str     r1, [r0, r2]
	ldr     r1, =EPLL_CON0_VAL
	ldr     r2, =EPLL_CON0_OFFSET
	str     r1, [r0, r2]

	/* Set VPLL */
	ldr     r1, =VPLL_CON2_VAL
	ldr     r2, =VPLL_CON2_OFFSET
	str     r1, [r0, r2]
	ldr     r1, =VPLL_CON1_VAL
	ldr     r2, =VPLL_CON1_OFFSET
	str     r1, [r0, r2]
	ldr     r1, =VPLL_CON0_VAL
	ldr     r2, =VPLL_CON0_OFFSET
	str     r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x40000
6:	subs	r1, r1, #1
	bne	6b

	ldr	r1, =0x01000001
	ldr	r2, =CLK_SRC_CPU_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =0x00011000
	ldr	r2, =CLK_SRC_DMC_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =0x00000110
	ldr	r2, =CLK_SRC_TOP0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =0x01111000
	ldr	r2, =CLK_SRC_TOP1_OFFSET
	str	r1, [r0, r2]

	/* wait ?us */
	mov	r1, #0x10000
7:	subs	r1, r1, #1
	bne	7b

/*************************************************************************
 *
 * mmc_ch2_div_set
 *
 * Setup mmc2 clock divider. 
 *
 *************************************************************************/
mmc_ch2_div_set:
	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS2_OFFSET
	ldr	r1, [r0, r2]
	orr	r1, r1, #0xF
	orr	r1, r1, #0xF00
	str	r1, [r0, r2]

/*************************************************************************
 *
 * mmc_ch4_div_set
 *
 * Setup emmc clock divider. 
 *
 *************************************************************************/
mmc_ch4_div_set:
	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS3_OFFSET
	ldr	r1, [r0, r2]
	bic	r1, r1, #(0xFF << 8)
	bic	r1, r1, #(0xF)
	orr	r1, r1, #(0x9 << 8)
	orr	r1, r1, #0x1
	str	r1, [r0, r2]


	pop	{pc}


/*
 * uart_asm_init: Initialize UART in asm mode, 115200bps fixed.
 * void uart_asm_init(void)
 */
	.globl uart_asm_init
uart_asm_init:

	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r1, =CLK_SRC_PERIL0_VAL
	ldr	r2, =CLK_SRC_PERIL0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_PERIL0_VAL
	ldr	r2, =CLK_DIV_PERIL0_OFFSET
	str	r1, [r0, r2]

	/* setup UART0-UART3 GPIOs (part1) */
	mov	r0, r7
	ldr	r1, =EXYNOS4_GPIO_A0_CON_VAL
	str	r1, [r0, #EXYNOS4_GPIO_A0_CON_OFFSET]
	ldr	r1, =EXYNOS4_GPIO_A1_CON_VAL
	str	r1, [r0, #EXYNOS4_GPIO_A1_CON_OFFSET]

	ldr r0, =EXYNOS4_UART_BASE
	add r0, r0, #EXYNOS4_DEFAULT_UART_OFFSET

	ldr	r1, =ULCON_VAL
	str	r1, [r0, #ULCON_OFFSET]
	ldr	r1, =UCON_VAL
	str	r1, [r0, #UCON_OFFSET]
	ldr	r1, =UFCON_VAL
	str	r1, [r0, #UFCON_OFFSET]
	ldr	r1, =UBRDIV_VAL
	str	r1, [r0, #UBRDIV_OFFSET]
	ldr	r1, =UFRACVAL_VAL
	str	r1, [r0, #UFRACVAL_OFFSET]
	mov	pc, lr
	nop
	nop
	nop

#define DM9000_Tacs	(0x1)	/* 0clk         address set-up		*/
#define DM9000_Tcos	(0x1)	/* 4clk         chip selection set-up	*/
#define DM9000_Tacc	(0x5)	/* 14clk        access cycle		*/
#define DM9000_Tcoh	(0x1)	/* 1clk         chip selection hold	*/
#define DM9000_Tah	(0xC)	/* 4clk         address holding time	*/
#define DM9000_Tacp	(0x9)	/* 6clk         page mode access cycle	*/
#define DM9000_PMC	(0x1)	/* normal(1data)page mode configuration	*/
#define SROM_BC1_VAL	((DM9000_Tacs << 28) \
				| (DM9000_Tcos << 24) \
				| (DM9000_Tacc << 16) \
				| (DM9000_Tcoh << 12) \
				| (DM9000_Tah << 8) \
				| (DM9000_Tacp << 4) \
				| (DM9000_PMC))
	
	.global srom_ctrl_init
srom_ctrl_init:
	/* CSn, WE, OE*/
	ldr r0, =0x11000120
	ldr r1, =0x00222222
	str r1, [r0]

	/* BE, WAIT, RD */
	ldr r0, =0x11000140
	ldr r1, =0x00002222
	str r1, [r0]

	/* ADDR[0-7], pull up */
	ldr r0, =0x11000180
	ldr r1, =0x22222222
	str r1, [r0]
	ldr r0, =0x11000188
	ldr r1, =0x0000FFFF
	str r1, [r0]

	/* DATA[0-7], pull up */
	ldr r0, =0x110001C0
	ldr r1, =0x22222222
	str r1, [r0]
	ldr r0, =0x110001C8
	ldr r1, =0x0000FFFF
	str r1, [r0]

	/* DATA[8-15], pull up */
	ldr r0, =0x110001E0
	ldr r1, =0x22222222
	str r1, [r0]
	ldr r0, =0x110001E8
	ldr r1, =0x0000FFFF
	str r1, [r0]

	/* SROM BANK 1 */
	ldr r0, =0x12570000
	ldr r1, [r0]
	orr r1, r1, #0xF0
	str r1, [r0]

	ldr r0, =0x12570008
	ldr r1, =SROM_BC1_VAL
	str r1, [r0]

	mov pc, lr


/* Setting TZPC[TrustZone Protection Controller] */
tzpc_init:
	ldr	r0, =TZPC0_BASE
	mov	r1, #R0SIZE
	str	r1, [r0]
	mov	r1, #DECPROTXSET
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =TZPC1_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =TZPC2_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =TZPC3_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =TZPC4_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =TZPC5_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	mov	pc, lr
