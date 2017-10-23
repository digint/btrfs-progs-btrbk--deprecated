/* btrfs-progs-btrbk: btrfs-receive */

int cmd_receive(int argc, char **argv);


// needs CAP_SYS_ADMIN, CAP_FOWNER, CAP_DAC_OVERRIDE, CAP_DAC_READ_SEARCH
// plus CAP_CHOWN, CAP_MKNOD (and probably others, see send_ops)
// plus CAP_SETFCAP for "lsetxattr" (in case a received file has xattrs)
int main(int argc, char **argv)
{
	return cmd_receive(argc, argv);
}
