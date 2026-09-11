/* encode_dxt5.c
 *
 * Reads raw RGBA (w*h*4 bytes, row-major, top-to-bottom) and writes a
 * DXT5-compressed DDS file with a standard 128-byte header (1 mipmap).
 *
 * Usage: encode_dxt5 <in_raw> <width> <height> <out.dds>
 *
 * Header layout matches the reference DDS files in the mod (DXT5,
 * dwFlags = CAPS|HEIGHT|WIDTH|PITCH|PIXELFORMAT|VOLUMES|MIPMAP).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define STB_DXT_IMPLEMENTATION
#include "stb_dxt.h"

static void w32(unsigned char *p, unsigned int v) {
    p[0] = (unsigned char)(v & 0xff);
    p[1] = (unsigned char)((v >> 8) & 0xff);
    p[2] = (unsigned char)((v >> 16) & 0xff);
    p[3] = (unsigned char)((v >> 24) & 0xff);
}

int main(int argc, char **argv) {
    if (argc != 5) {
        fprintf(stderr, "usage: %s <in_raw> <width> <height> <out.dds>\n", argv[0]);
        return 1;
    }
    const char *in_path = argv[1];
    int w = atoi(argv[2]);
    int h = atoi(argv[3]);
    const char *out_path = argv[4];

    if (w <= 0 || h <= 0 || (w % 4) != 0 || (h % 4) != 0) {
        fprintf(stderr, "width/height must be positive and divisible by 4 (got %dx%d)\n", w, h);
        return 1;
    }

    size_t raw_size = (size_t)w * h * 4;
    unsigned char *rgba = (unsigned char *)malloc(raw_size);
    if (!rgba) { fprintf(stderr, "malloc rgba failed\n"); return 1; }

    FILE *fin = fopen(in_path, "rb");
    if (!fin) { fprintf(stderr, "cannot open %s\n", in_path); return 1; }
    if (fread(rgba, 1, raw_size, fin) != raw_size) {
        fprintf(stderr, "short read: expected %zu bytes\n", raw_size);
        fclose(fin); free(rgba); return 1;
    }
    fclose(fin);

    /* DXT5 = 16 bytes per 4x4 block = 2 bytes per pixel.
     * stb_compress_dxt_block with alpha=1 compresses one 4x4 block (16 px -> 16 bytes).
     * w and h are guaranteed divisible by 4. */
    int bw = w / 4;
    int bh = h / 4;
    size_t comp_size = (size_t)bw * bh * 16;
    unsigned char *comp = (unsigned char *)malloc(comp_size);
    if (!comp) { fprintf(stderr, "malloc comp failed\n"); free(rgba); return 1; }

    unsigned char block[16 * 4]; /* contiguous 4x4 RGBA block */
    for (int by = 0; by < bh; by++) {
        for (int bx = 0; bx < bw; bx++) {
            /* Extract the 4x4 block into a contiguous buffer (row-major). */
            for (int ry = 0; ry < 4; ry++) {
                const unsigned char *row = rgba + ((size_t)(by * 4 + ry) * w + (size_t)(bx * 4)) * 4;
                memcpy(block + ry * 16, row, 16);
            }
            unsigned char *dst = comp + ((size_t)by * bw + (size_t)bx) * 16;
            stb_compress_dxt_block(dst, block, 1, STB_DXT_NORMAL);
        }
    }
    free(rgba);

    /* Build the 128-byte DDS header. */
    unsigned char hdr[128];
    memset(hdr, 0, sizeof(hdr));
    /* Magic "DDS " */
    hdr[0] = 'D'; hdr[1] = 'D'; hdr[2] = 'S'; hdr[3] = ' ';
    w32(hdr + 4, 124);                 /* dwSize */
    w32(hdr + 8, 0x0008100F);          /* dwFlags: CAPS|HEIGHT|WIDTH|PITCH|PIXELFORMAT|VOLUMES|MIPMAP */
    w32(hdr + 12, (unsigned int)h);    /* dwHeight */
    w32(hdr + 16, (unsigned int)w);    /* dwWidth */
    w32(hdr + 20, (unsigned int)w);    /* dwPitchOrLinearSize */
    w32(hdr + 24, 0);                  /* dwDepth */
    w32(hdr + 28, 1);                  /* dwMipMapCount */
    /* dwReserved1[11] = 0 (offset 32..75) */
    /* DDS_PIXELFORMAT at offset 76 */
    w32(hdr + 76, 32);                 /* pf.dwSize */
    w32(hdr + 80, 0x4);                /* pf.dwFlags = DDPF_FOURCC */
    /* FourCC "DXT5" at offset 84 */
    hdr[84] = 'D'; hdr[85] = 'X'; hdr[86] = 'T'; hdr[87] = '5';
    /* pf.dwRGBBitCount / dwRBitMask etc. at offset 88..107 = 0 */
    /* dwCaps at offset 108 */
    w32(hdr + 108, 0x00001000);        /* DDS_CAPS_TEXTURE */
    /* dwCaps2/3/4 at offset 112..123 = 0 */
    /* dwTextureStageAt offset 124 = 0 */

    FILE *fout = fopen(out_path, "wb");
    if (!fout) { fprintf(stderr, "cannot open %s\n", out_path); free(comp); return 1; }
    if (fwrite(hdr, 1, sizeof(hdr), fout) != sizeof(hdr)) {
        fprintf(stderr, "header write failed\n"); fclose(fout); free(comp); return 1;
    }
    if (fwrite(comp, 1, comp_size, fout) != comp_size) {
        fprintf(stderr, "data write failed\n"); fclose(fout); free(comp); return 1;
    }
    fclose(fout);
    free(comp);

    printf("wrote %s (%d x %d, DXT5, %zu bytes compressed)\n", out_path, w, h, comp_size);
    return 0;
}
