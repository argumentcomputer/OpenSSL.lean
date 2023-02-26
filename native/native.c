#include <lean/lean.h>
#include "lean_utils.h"

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>

#include <arpa/inet.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

/**
 * SSL library initialisation
 * initLib: Unit → IO Unit
 */
lean_obj_res lean_ssl_lib_init(lean_obj_arg _u)
{
  SSL_library_init();
  OpenSSL_add_all_algorithms();
  SSL_load_error_strings();
  ERR_load_crypto_strings();
  return lean_io_result_mk_ok(lean_box(0));
}

// Context

static inline void ssl_ctx_finalize(void *ctx)
{
  SSL_CTX_free(ctx);
}

static lean_external_class *g_ssl_ctx_class = 0;

static lean_external_class *get_ssl_ctx_class() {
  if (g_ssl_ctx_class == 0) {
    g_ssl_ctx_class = lean_register_external_class(
        &ssl_ctx_finalize, &foreach_noop
    );
  }
  return g_ssl_ctx_class;
}

/**
 * Create a SSL_CTX* server context.
 * Context.init : Unit → IO Context
 */
lean_obj_res lean_ssl_ctx_init(b_lean_obj_arg _a)
{
  /* create the SSL server context */
  SSL_CTX* ctx = SSL_CTX_new(SSLv23_method());
  if (!ctx) {
    return lean_io_result_mk_error(lean_mk_io_error_other_error(0, lean_mk_string("SSL_CTX_new() failed")));
  }
  /* Recommended to avoid SSLv2 & SSLv3 */
  SSL_CTX_set_options(ctx, SSL_OP_ALL|SSL_OP_NO_SSLv2|SSL_OP_NO_SSLv3);
  return lean_io_result_mk_ok(lean_alloc_external(get_ssl_ctx_class(), ctx));
}

/**
 * Load certificate file into context.
 * Context.useCertificateFile : @& Context → @& String → IO Bool
 */
lean_obj_res lean_ssl_ctx_use_certificate_file(b_lean_obj_arg l_ctx, b_lean_obj_arg certfile)
{
  SSL_CTX* ctx = lean_get_external_data(l_ctx);
  bool res = SSL_CTX_use_certificate_file(ctx, lean_string_cstr(certfile),  SSL_FILETYPE_PEM);
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * Load private key file into context.
 * Context.usePrivateKeyFile : @& Context → @& String → IO Bool
 */
lean_obj_res lean_ssl_ctx_use_private_key_file(b_lean_obj_arg l_ctx, b_lean_obj_arg keyfile)
{
  SSL_CTX* ctx = lean_get_external_data(l_ctx);
  bool res = SSL_CTX_use_PrivateKey_file(ctx, lean_string_cstr(keyfile),  SSL_FILETYPE_PEM);
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * Make sure the key and certificate file match. 
 * Context.checkPrivateKey : @& Context → IO Bool
 */
lean_obj_res lean_ssl_ctx_check_private_key(b_lean_obj_arg l_ctx, b_lean_obj_arg keyfile)
{
  SSL_CTX* ctx = lean_get_external_data(l_ctx);
  bool res = SSL_CTX_check_private_key(ctx);
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * Context.loadVerifyLocations : @& Context → @& String → @& String → IO Bool
 */
lean_obj_res lean_ssl_ctx_load_verify_locations(b_lean_obj_arg l_ctx, b_lean_obj_arg cafile, b_lean_obj_arg capath)
{
  SSL_CTX* ctx = lean_get_external_data(l_ctx);
  bool res = SSL_CTX_load_verify_locations(ctx, lean_string_cstr(cafile), lean_string_cstr(capath));
  return lean_io_result_mk_ok(lean_box(res));
}

// SSL

void ssl_finalize(void *ssl)
{
  SSL_free(ssl);
}

static lean_external_class *g_ssl_class = 0;

static lean_external_class *get_ssl_class() {
  if (g_ssl_class == 0) {
    g_ssl_class = lean_register_external_class(
        &ssl_finalize, &foreach_noop
    );
  }
  return g_ssl_class;
}

/**
 * Create a SSL* struct.
 * Context.initSSL : @& Context → IO SSL
 */
lean_obj_res lean_ssl_init(b_lean_obj_arg l_ctx)
{
  SSL_CTX* ctx = lean_get_external_data(l_ctx);
  SSL* ssl = SSL_new(ctx);
  return lean_io_result_mk_ok(lean_alloc_external(get_ssl_class(), ssl));
}

/**
 * SSL.isInitFinished : @& SSL → IO Bool
 */
lean_obj_res lean_ssl_is_init_finished(b_lean_obj_arg l_ssl)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  bool b = SSL_is_init_finished(ssl);
  return lean_io_result_mk_ok(lean_box(b));
}

/**
 * SSL.isServer : @& SSL → IO Bool
 */
lean_obj_res lean_ssl_is_server(b_lean_obj_arg l_ssl)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  bool b = SSL_is_server(ssl);
  return lean_io_result_mk_ok(lean_box(b));
}

/**
 * SSL.setConectState : @& SSL → IO Unit
 */
lean_obj_res lean_ssl_set_connect_state(b_lean_obj_arg l_ssl)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  SSL_set_connect_state(ssl);
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * SSL.setAcceptState : @& SSL → IO Unit
 */
lean_obj_res lean_ssl_set_accept_state(b_lean_obj_arg l_ssl)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  SSL_set_accept_state(ssl);
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * SSL.write : @& SSL → @& ByteArray → IO Unit
 */
lean_obj_res lean_ssl_write(b_lean_obj_arg l_ssl, b_lean_obj_arg bs)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  uint8_t* buf = lean_sarray_cptr(bs);
  size_t len = lean_sarray_size(bs);
  bool b = SSL_write(ssl, buf, len);
  return lean_io_result_mk_ok(lean_box(b));
}

/**
 * SSL.read : @& SSL → USize → IO (Bool × ByteArray)
 */
lean_obj_res lean_ssl_read(b_lean_obj_arg l_ssl, size_t len)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  lean_object* bs = lean_alloc_sarray(1, len, len);
  uint8_t* buf = lean_sarray_cptr(bs);
  bool b = SSL_read(ssl, buf, len);
  return lean_io_result_mk_ok(lean_mk_tuple2(lean_box(b), bs));
}

/**
 * SSL.setReadBIO : @& SSL → @& BIO → IO Unit
 */
lean_obj_res lean_ssl_set_rbio(b_lean_obj_arg l_ssl, b_lean_obj_arg l_bio)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  BIO* rbio = lean_get_external_data(l_bio);
  SSL_set0_rbio(ssl, rbio);
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * SSL.setWriteBIO : @& SSL → @& BIO → IO Unit
 */
lean_obj_res lean_ssl_set_wbio(b_lean_obj_arg l_ssl, b_lean_obj_arg l_bio)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  BIO* wbio = lean_get_external_data(l_bio);
  SSL_set0_wbio(ssl, wbio);
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * SSL.getError : @& SSL → UInt32 → IO Unit
 */
lean_obj_res lean_ssl_get_error(b_lean_obj_arg l_ssl, uint32_t ret)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  int code = SSL_get_error(ssl, ret);
  return lean_io_result_mk_ok(lean_box(code));
}

/**
 * SSL.verifyResult : SSL → IO UInt64
 */
lean_obj_res lean_ssl_verify_result(lean_obj_arg l_ssl)
{
  SSL* ssl = lean_get_external_data(l_ssl);
  long code = SSL_get_verify_result(ssl);
  return lean_io_result_mk_ok(lean_box(code));
}

// BIO

static inline void bio_finalize(void *bio)
{
  BIO_free_all(bio);
}

static lean_external_class *g_bio_class = 0;

static lean_external_class *get_bio_class() {
  if (g_bio_class == 0) {
    g_bio_class = lean_register_external_class(
        &bio_finalize, &foreach_noop
    );
  }
  return g_bio_class;
}

/**
 * Create a BIO* struct.
 * BIO.init : IO BIO
 */
lean_obj_res lean_bio_init()
{
  BIO* bio = BIO_new(BIO_s_mem());
  if (bio == NULL) {
    return lean_io_result_mk_error(lean_mk_string("BIO_new() failed"));
  }
  return lean_io_result_mk_ok(lean_alloc_external(get_bio_class(), bio));
}

/**
 * BIO.read : @& BIO → USize → IO (Bool × ByteArray)
 */
lean_obj_res lean_bio_read(b_lean_obj_arg l_bio, size_t len)
{
  BIO* bio = lean_get_external_data(l_bio);
  lean_object* bs = lean_alloc_sarray(1, len, len);
  uint8_t* buf = lean_sarray_cptr(bs);
  bool b = BIO_read(bio, buf, len);
  return lean_io_result_mk_ok(lean_mk_tuple2(lean_box(b), bs));
}

/**
 * BIO.write : @& BIO → @& ByteArray → IO Unit
 */
lean_obj_res lean_bio_write(b_lean_obj_arg l_bio, b_lean_obj_arg bs)
{
  BIO* bio = lean_get_external_data(l_bio);
  uint8_t* buf = lean_sarray_cptr(bs);
  size_t len = lean_sarray_size(bs);
  bool b = BIO_write(bio, buf, len);
  return lean_io_result_mk_ok(lean_box(b));
}

/**
 * BIO.getSSL : @& BIO → IO SSL
 */
lean_obj_res lean_bio_get_ssl(lean_obj_arg l_bio)
{
  BIO* bio = lean_get_external_data(l_bio);
  SSL* ssl = NULL;
  BIO_get_ssl(bio, &ssl);
  if (ssl == NULL) {
    return lean_io_result_mk_error(lean_mk_io_error_other_error(0, lean_mk_string("BIO_get_ssl() is null")));
  }
  return lean_io_result_mk_ok(lean_alloc_external(get_ssl_class(), ssl));
}


// BIO ADDR

static inline void bio_addr_finalize(void *bio)
{
  BIO_ADDR_free(bio);
}

static lean_external_class *g_bio_addr_class = 0;

static lean_external_class *get_bio_addr_class() {
  if (g_bio_addr_class == 0) {
    g_bio_addr_class = lean_register_external_class(
        &bio_addr_finalize, &foreach_noop
    );
  }
  return g_bio_addr_class;
}

/**
 * Create a BIO_ADDR* struct.
 * BIO.init : IO BIO
 */
lean_obj_res lean_bio_addr_init()
{
  BIO_ADDR * addr = BIO_ADDR_new();
  if (addr == NULL) {
    return lean_io_result_mk_error(lean_mk_string("BIO_ADDR_new() failed"));
  }
  return lean_io_result_mk_ok(lean_alloc_external(get_bio_addr_class(), addr));
}

/**
 * BIO.socket : UInt32 -> UInt32 -> UInt32 -> IO UInt32
 */
lean_obj_res lean_bio_socket(uint32_t domain, uint32_t socktype, uint32_t protocol)
{
  int i = BIO_socket(domain, socktype, protocol, 0);
  if (i == BIO_R_INVALID_SOCKET) {
    return lean_io_result_mk_error(lean_mk_string("Invalid socket"));
  } else {
    return lean_io_result_mk_ok(lean_box(i));
  }
}

/**
 * Socket.connect (sock : Socket) (addr : Addr) : IO UInt32
 */
lean_obj_res lean_bio_connect(uint32_t sock, b_lean_obj_arg addr)
{
  uint32_t res = BIO_connect(sock, lean_get_external_data(addr), BIO_SOCK_KEEPALIVE | BIO_SOCK_NONBLOCK);
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * BIO.newSSLConnect (ctx : Context) : IO BIO
 */
lean_obj_res lean_bio_new_ssl_connect(lean_obj_arg context)
{
  BIO* bio = BIO_new_ssl_connect(lean_get_external_data(context));
  if (bio == NULL) {
    return lean_io_result_mk_error(lean_mk_io_error_other_error(0, lean_mk_string("BIO_new_ssl_connect() failed")));
  }
  return lean_io_result_mk_ok(lean_alloc_external(get_bio_class(), bio));
}

/**
 * Socket.close (socket : Socket) : IO UInt32
 */
lean_obj_res lean_bio_closesocket(uint32_t sock)
{
  uint32_t res = BIO_closesocket(sock);
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * BIO.setConnHostname (bio : BIO) (hostname : String) : IO UInt32
 */
lean_obj_res lean_bio_set_conn_hostname(lean_obj_arg bio, lean_obj_arg hostname)
{
  uint32_t res = BIO_set_conn_hostname(lean_get_external_data(bio), lean_string_cstr(hostname));
  return lean_io_result_mk_ok(lean_box(res));
}

/**
 * BIO.doConnect : IO UInt32
 */
lean_obj_res lean_bio_do_connect(lean_obj_arg bio)
{
  uint32_t res = BIO_do_connect(lean_get_external_data(bio));
  return lean_io_result_mk_ok(lean_box(res));
}
