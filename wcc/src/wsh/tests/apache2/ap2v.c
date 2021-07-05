/**
* Test code for the Witchcraft Compiler Collection
*
* Copyright 2016 Jonathan Brossard.
*
* This file is licensed under the MIT License.
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>

#include "ap.h"

int main (int argc, char **argv){

	int *rev = 0;
	ap_get_server_revision(&rev);	/* Get server revision number from apache2 */
	printf("apache revision: %d\n", rev);
	exit(0);
	return 0;
}

