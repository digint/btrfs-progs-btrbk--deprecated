/* btrfs-progs-btrbk: btrfs-subvolume-snapshot */

int cmd_subvol_snapshot(int argc, char **argv);

int handle_command_group(const struct cmd_group *grp, int argc, char **argv) { ; }


// needs CAP_SYS_ADMIN, CAP_FOWNER, CAP_DAC_OVERRIDE, CAP_DAC_READ_SEARCH
int main(int argc, char **argv)
{
	return cmd_subvol_snapshot(argc, argv);
}
