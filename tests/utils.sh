
# Check if a file is an ELF x86-64 binary.
#
# This command is used to determine if a file is a 64-bit ELF binary.
#
# Args:
#   $1: The path to check.
#
# Returns:
#   0 if the file is an ELF x86-64 binary, 99 otherwise.
is_app() {
  local path="${1}"
  local info=$(file "$path")
  case "$info" in
    *ELF*x86-64*)
      return 0
      ;;
    *)
      return 99
      ;;
  esac
}
