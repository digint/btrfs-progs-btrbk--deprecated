/* Proof of concept: dirty include of c-file, add main() */

#define DISABLE_BTRFS_MAIN
#include "btrfs.c"

int cmd_subvol_show(int argc, char **argv);


// needs CAP_DAC_READ_SEARCH, CAP_FOWNER, CAP_SYS_ADMIN
// why CAP_SYS_ADMIN? shouldn't CAP_DAC_READ_SEARCH be enough?
// NOTE: CAP_FOWNER is only needed for O_NOATIME flag in open() system calls
int main(int argc, char **argv)
{
	return cmd_subvol_show(argc, argv);
}
