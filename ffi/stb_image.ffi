enum
{
   STBI_default = 0,

   STBI_grey = 1,
   STBI_grey_alpha = 2,
   STBI_rgb = 3,
   STBI_rgb_alpha = 4
};

typedef unsigned char stbi_uc;
extern stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len, int *x, int *y, int *comp, int req_comp);


extern stbi_uc *stbi_load (char const *filename, int *x, int *y, int *comp, int req_comp);
//extern stbi_uc *stbi_load_from_file (FILE *f, int *x, int *y, int *comp, int req_comp);



typedef struct
{
   int (*read) (void *user,char *data,int size);
   void (*skip) (void *user,unsigned n);
   int (*eof) (void *user);
} stbi_io_callbacks;

extern stbi_uc *stbi_load_from_callbacks (stbi_io_callbacks const *clbk, void *user, int *x, int *y, int *comp, int req_comp);


extern float *stbi_loadf_from_memory(stbi_uc const *buffer, int len, int *x, int *y, int *comp, int req_comp);

extern float *stbi_loadf (char const *filename, int *x, int *y, int *comp, int req_comp);
//extern float *stbi_loadf_from_file (FILE *f, int *x, int *y, int *comp, int req_comp);


extern float *stbi_loadf_from_callbacks (stbi_io_callbacks const *clbk, void *user, int *x, int *y, int *comp, int req_comp);

extern void stbi_hdr_to_ldr_gamma(float gamma);
extern void stbi_hdr_to_ldr_scale(float scale);

extern void stbi_ldr_to_hdr_gamma(float gamma);
extern void stbi_ldr_to_hdr_scale(float scale);



extern int stbi_is_hdr_from_callbacks(stbi_io_callbacks const *clbk, void *user);
extern int stbi_is_hdr_from_memory(stbi_uc const *buffer, int len);

extern int stbi_is_hdr (char const *filename);
//extern int stbi_is_hdr_from_file(FILE *f);

extern const char *stbi_failure_reason (void);


extern void stbi_image_free (void *retval_from_stbi_load);


extern int stbi_info_from_memory(stbi_uc const *buffer, int len, int *x, int *y, int *comp);
extern int stbi_info_from_callbacks(stbi_io_callbacks const *clbk, void *user, int *x, int *y, int *comp);


extern int stbi_info (char const *filename, int *x, int *y, int *comp);
//extern int stbi_info_from_file (FILE *f, int *x, int *y, int *comp);

extern void stbi_set_unpremultiply_on_load(int flag_true_if_should_unpremultiply);

extern char *stbi_zlib_decode_malloc_guesssize(const char *buffer, int len, int initial_size, int *outlen);
extern char *stbi_zlib_decode_malloc(const char *buffer, int len, int *outlen);
extern int stbi_zlib_decode_buffer(char *obuffer, int olen, const char *ibuffer, int ilen);

extern char *stbi_zlib_decode_noheader_malloc(const char *buffer, int len, int *outlen);
extern int stbi_zlib_decode_noheader_buffer(char *obuffer, int olen, const char *ibuffer, int ilen);
