#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Characters on a 5x9 matrix.  This is padded up to 16 rows when the
// ROM is generated
static uint8_t saa5050_charset[] = {
	0,0,0,0,0,0,0,0,0,
	4,4,4,4,4,0,4,0,0,
	10,10,10,0,0,0,0,0,0,
	6,9,8,28,8,8,31,0,0,
	14,21,20,14,5,21,14,0,0,
	24,25,2,4,8,19,3,0,0,
	8,20,20,8,21,18,13,0,0,
	4,4,4,0,0,0,0,0,0,

	2,4,8,8,8,4,2,0,0,
	8,4,2,2,2,4,8,0,0,
	4,21,14,4,14,21,4,0,0,
	0,4,4,31,4,4,0,0,0,
	0,0,0,0,0,4,4,8,0,
	0,0,0,14,0,0,0,0,0,
	0,0,0,0,0,0,4,0,0,
	0,1,2,4,8,16,0,0,0,

	4,10,17,17,17,10,4,0,0,
	4,12,4,4,4,4,14,0,0,
	14,17,1,6,8,16,31,0,0,
	31,1,2,6,1,17,14,0,0,
	2,6,10,18,31,2,2,0,0,
	31,16,30,1,1,17,14,0,0,
	6,8,16,30,17,17,14,0,0,
	31,1,2,4,8,8,8,0,0,

	14,17,17,14,17,17,14,0,0,
	14,17,17,15,1,2,12,0,0,
	0,0,4,0,0,0,4,0,0,
	0,0,4,0,0,4,4,8,0,
	2,4,8,16,8,4,2,0,0,
	0,0,31,0,31,0,0,0,0,
	8,4,2,1,2,4,8,0,0,
	14,17,2,4,4,0,4,0,0,

	14,17,23,21,23,16,14,0,0,
	4,10,17,17,31,17,17,0,0,
	30,17,17,30,17,17,30,0,0,
	14,17,16,16,16,17,14,0,0,
	30,17,17,17,17,17,30,0,0,
	31,16,16,30,16,16,31,0,0,
	31,16,16,30,16,16,16,0,0,
	14,17,16,16,19,17,15,0,0,

	17,17,17,31,17,17,17,0,0,
	14,4,4,4,4,4,14,0,0,
	1,1,1,1,1,17,14,0,0,
	17,18,20,24,20,18,17,0,0,
	16,16,16,16,16,16,31,0,0,
	17,27,21,21,17,17,17,0,0,
	17,17,25,21,19,17,17,0,0,
	14,17,17,17,17,17,14,0,0,

	30,17,17,30,16,16,16,0,0,
	14,17,17,17,21,18,13,0,0,
	30,17,17,30,20,18,17,0,0,
	14,17,16,14,1,17,14,0,0,
	31,4,4,4,4,4,4,0,0,
	17,17,17,17,17,17,14,0,0,
	17,17,17,10,10,4,4,0,0,
	17,17,17,21,21,21,10,0,0,

	17,17,10,4,10,17,17,0,0,
	17,17,10,4,4,4,4,0,0,
	31,1,2,4,8,16,31,0,0,
	0,4,8,31,8,4,0,0,0,
	16,16,16,16,22,1,2,4,7,
	0,4,2,31,2,4,0,0,0,
	0,4,14,21,4,4,0,0,0,
	10,10,31,10,31,10,10,0,0,

	0,0,0,31,0,0,0,0,0,
	0,0,14,1,15,17,15,0,0,
	16,16,30,17,17,17,30,0,0,
	0,0,15,16,16,16,15,0,0,
	1,1,15,17,17,17,15,0,0,
	0,0,14,17,31,16,14,0,0,
	2,4,4,14,4,4,4,0,0,
	0,0,15,17,17,17,15,1,14,

	16,16,30,17,17,17,17,0,0,
	4,0,12,4,4,4,14,0,0,
	4,0,4,4,4,4,4,4,8,
	8,8,9,10,12,10,9,0,0,
	12,4,4,4,4,4,14,0,0,
	0,0,26,21,21,21,21,0,0,
	0,0,30,17,17,17,17,0,0,
	0,0,14,17,17,17,14,0,0,

	0,0,30,17,17,17,30,16,16,
	0,0,15,17,17,17,15,1,1,
	0,0,11,12,8,8,8,0,0,
	0,0,15,16,14,1,30,0,0,
	4,4,14,4,4,4,2,0,0,
	0,0,17,17,17,17,15,0,0,
	0,0,17,17,10,10,4,0,0,
	0,0,17,17,21,21,10,0,0,

	0,0,17,10,4,10,17,0,0,
	0,0,17,17,17,17,15,1,14,
	0,0,31,2,4,8,31,0,0,
	8,8,8,8,9,3,5,7,1,
	10,10,10,10,10,10,10,0,0,
	24,4,24,4,25,3,5,7,1,
	0,4,0,31,0,4,0,0,0,
	31,31,31,31,31,31,31,0,0,
};

/* Generates 6x10 teletext graphics symbol according to specified code */
void gen_gfx(char code,char *base)
{
	char *c;
	int r;
	int v;

	for (r = 0, c = base; r < 10; r++) {
		/* Set unused bit 13 to 1 to flag these characters as graphics (the
		 * implementation uses this to determine whether hold and separated
		 * modes should be applied */
		v = 4096;
		if (r < 3) {
			// 1 2
			if (code & 1) v += 64 + 128 + 256 + 512 + 1024 + 2048;
			if (code & 2) v += 1 + 2 + 4 + 8 + 16 + 32;;
		} else if (r < 7) {
			// 4 8
			if (code & 4) v += 64 + 128 + 256 + 512 + 1024 + 2048;
			if (code & 8) v += 1 + 2 + 4 + 8 + 16 + 32;;
		} else {
			// 16 64
			if (code & 16) v += 64 + 128 + 256 + 512 + 1024 + 2048;
			if (code & 64) v += 1 + 2 + 4 + 8 + 16 + 32;
		}
		*c++ = v & 0xff;
		*c++ = (v << 8) & 0xff;
		*c++ = v & 0xff;
		*c++ = (v << 8) & 0xff;		
	}
}

void dumpchar(int* rows) {
	int row, p, pixels;
	fprintf(stderr, "\n");
	for (row = 0; row < 18; row++) {
		pixels = rows[row];
		p = 512;
		while (p > 0) {
			if (pixels & p) {
				fprintf(stderr, "#");
			} else {
				fprintf(stderr, ".");
			}
			p >>= 1;
		}
		fprintf(stderr, "\n");
	}
	fprintf(stderr, "\n");
}

int main(void) {
	char *outbuf;
	int ch,row,col;
	int p;
	int pixels;
	int doubled;
	int rows1[18];
	int rows2[18];
	int a,b,c,d,n;

	outbuf = malloc(256 * 64);
	if (outbuf == NULL) {
	   fprintf(stderr,"Out of memory\n");
		return 1;
	}

	/* Unused locations are blank (all zero) */
	memset(outbuf, 0, 256 * 64);

	/* Copy character bitmaps to locations 32-127 and 160-255 */
	for (ch = 0; ch < 96; ch++) {
		for (row = 0; row < 9; row++) {
			pixels = saa5050_charset[9 * ch + row];
			p = 32;
			doubled = 0;
			while (p > 0) {
				doubled <<= 2;
				if (pixels & p) {
					doubled += 3;
				} else {
				}
				p >>= 1;
			}
			rows1[2 * row] = doubled;
			rows1[2 * row + 1] = doubled;
			rows2[2 * row] = doubled;;
			rows2[2 * row + 1] = doubled;;
		}
		for (row = 1; row < 17; row++) {
			for (col = 1; col < 9; col++) {
				a = (rows1[row - 1] >> (col - 1)) & 1;
				b = (rows1[row - 1] >> (col + 1)) & 1;
				c = (rows1[row + 1] >> (col - 1)) & 1;
				d = (rows1[row + 1] >> (col + 1)) & 1;
				n = (rows1[row] >> col) & 1;

				if ( (n == 0) &&
					 (
					  (a == 1 && b == 0 & c == 0 & d == 1) ||
					  (a == 0 && b == 1 & c == 1 & d == 0)
					  )
					 ) {
					rows2[row] |= 1 << col;
				}
			}
		}
		dumpchar(rows1);
		dumpchar(rows2);
		for (row = 0; row < 18; row++) {
			outbuf[64 * ( 32 + ch) + row * 2 + 4] = (rows2[row]     ) & 0xff;
			outbuf[64 * ( 32 + ch) + row * 2 + 5] = (rows2[row] >> 8) & 0xff;
			outbuf[64 * (160 + ch) + row * 2 + 4] = (rows2[row]     ) & 0xff;
			outbuf[64 * (160 + ch) + row * 2 + 5] = (rows2[row] >> 8) & 0xff;
		}
	}

	/* Generate graphics in locations 160-191 and 224-255 */
	for (ch = 160; ch < 192; ch++) {
		gen_gfx(ch,&outbuf[64 * ch]);
	}
	for (ch = 224; ch < 256; ch++) {
		gen_gfx(ch,&outbuf[64 * ch]);
	}

	/* Write to stdout */
	fwrite(outbuf, 256 * 64, 1, stdout);

	free(outbuf);
	return 0;
}
