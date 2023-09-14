#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>

typedef struct Client Client;

typedef uint64_t BlockHeight;

typedef struct SubmitResult {
  BlockHeight _0;
} SubmitResult;

typedef uint8_t Namespace[32];

typedef uint8_t Commitment[32];

typedef uint32_t ShareVersion;

typedef struct BlobSafe {
  Namespace namespace_;
  Commitment commitment;
  ShareVersion share_version;
  const uint8_t *data;
  size_t len;
} BlobSafe;

typedef struct GetAllResult {
  const struct BlobSafe *blobs;
  size_t blob_len;
  const BlockHeight *heights;
  size_t heights_len;
} GetAllResult;

typedef struct RustSafeArray {
  const uint8_t *data;
  size_t len;
} RustSafeArray;

char *get_error(void);

const struct Client *new_client(const char *key_path,
                                const char *contract,
                                const char *network,
                                const uint8_t *namespace_);

void free_client(struct Client *client);

const struct SubmitResult *submit(const struct Client *client,
                                  const struct BlobSafe *blobs,
                                  size_t len);

void free_submit_result(struct SubmitResult *result);

const struct BlobSafe *get(const struct Client *client, BlockHeight height);

const struct BlobSafe *fast_get(const struct Client *client, const uint8_t *commitment, size_t len);

void free_blob(struct BlobSafe *blob);

const struct GetAllResult *get_all(const struct Client *client);

struct RustSafeArray submit_batch(const struct Client *client,
                                  const char *candidate_hex,
                                  const uint8_t *tx_data,
                                  size_t tx_data_len);
