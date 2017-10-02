/* btrfs-progs-btrbk: btrfs-subvolume-list */

int cmd_subvol_list(int argc, char **argv);

int handle_command_group(const struct cmd_group *grp, int argc, char **argv) { ; }


// needs CAP_DAC_READ_SEARCH, CAP_FOWNER, CAP_SYS_ADMIN
// why CAP_SYS_ADMIN? shouldn't CAP_DAC_READ_SEARCH be enough?
// NOTE: CAP_FOWNER is only needed for O_NOATIME flag in open() system calls
int main(int argc, char **argv)
{
	return cmd_subvol_list(argc, argv);
}
