#include "../config.h"
#include "../parser/sdp/sdp.h"
#include "../parser/parse_uri.c"
#include "../parser/parse_hname2.h"
#include "../parser/contact/parse_contact.h"
#include "../parser/parse_from.h"
#include "../parser/parse_to.h"
#include "../parser/parse_rr.h"
#include "../parser/parse_refer_to.h"
#include "../parser/parse_ppi_pai.h"
#include "../parser/parse_privacy.h"
#include "../parser/parse_diversion.h"
#include "../parser/parse_identityinfo.h"
#include "../parser/parse_disposition.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "rb");
    if (!file) {
        perror("Failed to open input file");
        return 1;
    }

    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    fseek(file, 0, SEEK_SET);

    uint8_t *data = malloc(size);
    if (!data) {
        perror("Failed to allocate memory");
        fclose(file);
        return 1;
    }

    if (fread(data, 1, size, file) != size) {
        perror("Failed to read input file");
        free(data);
        fclose(file);
        return 1;
    }

    fclose(file);

    ksr_hname_init_index();

    sip_msg_t orig_inv = { };
    orig_inv.buf = (char*)data;
    orig_inv.len = size;

    if (size >= 4 * BUF_SIZE) {
        /* test with larger message than core accepts, but not indefinitely large */
        free(data);
        return 0;
    }

    if (parse_msg(orig_inv.buf, orig_inv.len, &orig_inv) < 0) {
        goto cleanup;
    }

    parse_headers(&orig_inv, HDR_EOH_F, 0);
    parse_sdp(&orig_inv);
    parse_from_header(&orig_inv);
    parse_from_uri(&orig_inv);
    parse_to_header(&orig_inv);
    parse_to_uri(&orig_inv);
    parse_contact_headers(&orig_inv);
    parse_refer_to_header(&orig_inv);
    parse_pai_header(&orig_inv);
    parse_diversion_header(&orig_inv);
    parse_privacy(&orig_inv);
    parse_content_disposition(&orig_inv);
    parse_identityinfo_header(&orig_inv);
    parse_record_route_headers(&orig_inv);
    parse_route_headers(&orig_inv);

    str uri;
    get_src_uri(&orig_inv, 0, &uri);

    str ssock;
    get_src_address_socket(&orig_inv, &ssock);

cleanup:
    free_sip_msg(&orig_inv);
    free(data);

    return 0;
}
