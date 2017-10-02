/* btrfs-progs-btrbk: btrfs-subvolume-delete */

int cmd_subvol_delete(int argc, char **argv);

int handle_command_group(const struct cmd_group *grp, int argc, char **argv) { ; }


// needs CAP_SYS_ADMIN, CAP_DAC_OVERRIDE
int main(int argc, char **argv)
{
	return cmd_subvol_delete(argc, argv);
}
