//
//  ar.h
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/07
//
//

#ifndef ar_h
#define ar_h

// ref: https://github.com/apple-oss-distributions/binutils/blob/31b76a40673e65259aeaa8e8afa5bd445fae4aae/src/include/aout/ar.h

/* Note that the usual '\n' in magic strings may translate to different
 characters, as allowed by ANSI.  '\012' has a fixed value, and remains
 compatible with existing BSDish archives. */

#define ARMAG  "!<arch>\012"    /* For COFF and a.out archives */
#define ARMAGB "!<bout>\012"    /* For b.out archives */
#define SARMAG 8
#define ARFMAG "`\012"

/* The ar_date field of the armap (__.SYMDEF) member of an archive
 must be greater than the modified date of the entire file, or
 BSD-derived linkers complain.  We originally write the ar_date with
 this offset from the real file's mod-time.  After finishing the
 file, we rewrite ar_date if it's not still greater than the mod date.  */

#define ARMAP_TIME_OFFSET       60

struct ar_hdr {
    char ar_name[16];        /* name of this member */
    char ar_date[12];        /* file mtime */
    char ar_uid[6];        /* owner uid; printed as decimal */
    char ar_gid[6];        /* owner gid; printed as decimal */
    char ar_mode[8];        /* file mode, printed as octal   */
    char ar_size[10];        /* file size, printed as decimal */
    char ar_fmag[2];        /* should contain ARFMAG */
};


#endif /* ar_h */
