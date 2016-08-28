/* Proof of concept: dirty include of c-file, add main() */

#define DISABLE_BTRFS_MAIN
#include "btrfs.c"

int cmd_subvol_delete(int argc, char **argv);


// needs CAP_SYS_ADMIN, CAP_DAC_OVERRIDE
int main(int argc, char **argv)
{
	return cmd_subvol_delete(argc, argv);
}
