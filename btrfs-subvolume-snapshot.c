/* Proof of concept: dirty include of c-file, add main() */

#define DISABLE_BTRFS_MAIN
#include "btrfs.c"

int cmd_subvol_snapshot(int argc, char **argv);


// needs CAP_SYS_ADMIN, CAP_FOWNER, CAP_DAC_OVERRIDE, CAP_DAC_READ_SEARCH
int main(int argc, char **argv)
{
	return cmd_subvol_snapshot(argc, argv);
}
