//
//  ranlib.h
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/16
//  
//

#ifndef ranlib_h
#define ranlib_h

#include <stdint.h>

// https://man.freebsd.org/cgi/man.cgi?query=ar&sektion=5

struct ranlib32 {
    uint32_t ran_strx;
    uint32_t ran_off;
};

struct ranlib64 {
    uint64_t ran_strx;
    uint64_t ran_off;
};

#endif /* ranlib_h */
