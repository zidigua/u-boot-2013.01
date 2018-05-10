/*
 * Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
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

/*
 * CBFS commands
 */
#include <common.h>
#include <command.h>
#include <cbfs.h>

int do_myled(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
#if 0
	static int a = 0;
	if(a) {
		led2_off();
		a = 0;
	} else {
		led2_on();
		a = 1;
	}
#endif

	if(argv[1][0] == '1') {
		my_led_on();
	}
	if(argv[1][0] == '0') {
		my_led_off();
	}

	return 0;
}


U_BOOT_CMD(
	myled,	2,	1,	do_myled,
	"++++",
	"----\n"
);
