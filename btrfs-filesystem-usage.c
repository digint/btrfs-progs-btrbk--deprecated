/* btrfs-progs-btrbk: btrfs-filesystem-usage */

int cmd_filesystem_usage(int argc, char **argv);


// needs CAP_SYS_ADMIN

// NOTE: CAP_SYS_ADMIN is needed for BTRFS_IOC_TREE_SEARCH and BTRFS_IOC_FS_INFO
// in order to provide full level of detail, see btrfs-filesystem(8)
int main(int argc, char **argv)
{
	return cmd_filesystem_usage(argc, argv);
}
