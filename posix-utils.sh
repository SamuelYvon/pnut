# Bindings for POSIX shell utilities.
#
# ############################# Calling convention #############################
# The calling convention is the following:
#
# 1. C functions are prefixed with an underscore when compiled to shell.
#
# 2. The first argument is the return variable, it indicates where the return
#    value should be stored. The other arguments are the function arguments.
#
# 3. Variables are globally scoped, and the callee is responsible for restoring
#    their initial values when returning. Variables starting with `_` may be
#    global variables, variables starting with `__` are reserved for the runtime
#    library, and `___` is free to be used by the user.
#
# 4. The arguments and return value can either be immediates (int) or pointers.
#    Shell strings must always be converted to the C string format before being
#    returned using the `unpack_string` function.
#
#
# ############################# String conversions #############################
#
# To help with the calling convention, the `pack_string` and `unpack_string`
# functions can be used to convert to/from shell strings and C strings. For
# functions that return multiple strings, the `unpack_lines` function can be
# used to unpack them into an array of strings.
#
#
# ############################# Memory allocation ##############################
#
# Memory can be dynamically allocated using the `_malloc` function, and freed
# using the `_free` function. For long running scripts, it is recommended to
# free memory as it tends to slow down the execution of scripts. Because POSIX
# shell requires 32-bit signed integers, the maximum amount of memory that can
# be allocated is 2^31 - 1 words. In practice, most shells will become unusably
# slow or run out of memory before reaching this limit.
#
# Because memory is allocated using a simple bump allocator, address space is
# never reclaimed. Programs that allocate over 2^31 - 1 words may need to manage
# blocks of memory manually to avoid running out of memory.
#
# Because the memory is word-addressable, pointers, integers and
# characters all occupy the same amount of memory. Keep that in mind when
# allocating structures.

# Like `unpack_string` but for multiple strings separated by newlines.
# Returns a pointer to the first string in the array, and null terminates the
# array.
unpack_lines() {
  ___i=1 # Account for null delimiter
  IFS="\n"
  for ___line in $2; do
    : $((___i += 1))
  done
  _malloc $1 $___i
  ___i=0
  for ___line in $2; do
    unpack_string _$(($1 + ___i))  "$___line"
    : $((___i += 1))
  done
  : $((_$(($1 + ___i)) = 0)) # Null delimiter
}

_cat() { # $2 = file (char*)
  pack_string ___file $2
  cat $___file
}

# Return the current date with the format "YYYY-MM-DDTHH:MM:SS"
_date() {
  ___date=$(date -Iseconds)
  unpack_string $1 "$___date"
}

_pwd() {
  ___pwd=$(pwd)
  unpack_string $1 "$___pwd"
}

# Example of a variadic function.
# This function can take an optional string argument for the directory to list.
_ls() { # $2 = dir (char*)
  __file=
  if [ $# -eq 2 ]; then
    pack_string __file $2
  fi
  ___res=$(ls $__file)
  unpack_lines $1 "$___res"
}

_touch() { # $2 = file (char*)
  pack_string ___file $2
  touch $___file
}

# Create a directory and return the exit code.
_mkdir() { # $2 = dir (char*)
  pack_string ___dir $2
  set +e # Ignore errors
  mkdir -p $___dir
  : $(($1 = $?)) # Return the exit code
  set -e # Restore set -e
}

_file_permission() { # $2 = file (char*)
  pack_string ___file $2
  ___perms=$(ls -l $___file | cut -c1-10) # Produce -rwxr-xr-x
  unpack_string $1 "$___perms"
}

_chmod() { # $2 = mode (int), $3 = file (char*)
  pack_string ___file $3
  set +e # Ignore errors
  chmod "$2" $___file
  : $(($1 = $?)) # Return the exit code
  set -e # Restore set -e
}

_wc() { # $2 = file (char*), $3 = lines addr (int*), $4 = words addr (int*), $5 = chars addr (int*)
  pack_string ___file $2
  __res=$(wc $___file | read -r ___lines ___words ___chars _)
  # Write result to the addresses
  : $((_$3 = ___lines))
  : $((_$4 = ___words))
  : $((_$5 = ___chars))
}
