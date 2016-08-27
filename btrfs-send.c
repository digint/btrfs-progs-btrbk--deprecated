/* Proof of concept: dirty include of c-file, add main() */

#define DISABLE_BTRFS_MAIN
#include "btrfs.c"

int cmd_send(int argc, char **argv);


// needs CAP_SYS_ADMIN, CAP_FOWNER, CAP_DAC_READ_SEARCH
// NOTE: CAP_FOWNER is only needed for O_NOATIME flag in open() system calls
int main(int argc, char **argv)
{
	return cmd_send(argc, argv);
}
