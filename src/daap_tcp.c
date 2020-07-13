/* DAAP TCP functions with SSL capability
 *
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Hugh Greenberg, hng@lanl.gov
 * Additional authors: Charles Shereda, cpshereda@lanl.gov
 */
#include <stdio.h>
#include <errno.h>
#include <strings.h>
#include <unistd.h>
#include <pthread.h>

#include "daap_log.h"
#include "daap_log_internal.h"

/* SSL includes */
#include <openssl/crypto.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#define PORT 5555

//#define CHK_NULL(x) if ((x)==NULL) exit (1)
//#define CHK_ERR(err,s) if ((err)==-1) { perror(s); exit(1); }
#define CHK_SSL(err) if ((err)==-1) { ERR_print_errors_fp(stderr); exit(2); }

#define SSL_CLIENT_CERT "/daap_certs/client_cert.pem"
#define SSL_CLIENT_KEY "/daap_certs/client_key.pem"
static pthread_mutex_t write_mutex = PTHREAD_MUTEX_INITIALIZER;

SSL *cSSL = NULL;
int sockfd = -1;

static SSL_CTX *sslctx;

int daapInitializeSSL() {
  char ssl_client_cert[PATH_MAX];
  char ssl_client_key[PATH_MAX];
  int home_len;
  int ssl_client_key_len;
  int ssl_client_cert_len;
  char *home;
  long options;

  SSL_load_error_strings();
  SSL_library_init();
  OpenSSL_add_all_algorithms();

  home = getenv("HOME");
  ssl_client_cert_len = strlen(SSL_CLIENT_CERT);
  ssl_client_key_len = strlen(SSL_CLIENT_KEY);
  if (home != NULL && (strlen(home) + ssl_client_key_len < PATH_MAX) && 
      (strlen(home) + ssl_client_cert_len < PATH_MAX)) {
    home_len = strlen(home);
    snprintf(ssl_client_cert, home_len+ssl_client_cert_len+2,"%s%s", home, SSL_CLIENT_CERT);
    snprintf(ssl_client_key, home_len+ssl_client_key_len+2,"%s%s", home, SSL_CLIENT_KEY);
    if (access(ssl_client_cert, F_OK) == -1 || access(ssl_client_key, F_OK) == -1) {
      fprintf(stderr, "Cannot find DAAP ssl cert: %s or key: %s\n", 
	      ssl_client_cert, ssl_client_key);
      return -1;
    }
  } else{
      fprintf(stderr, "Invalid path length for certificates\n");
      return -1;
  }

  // create context, which will remain the same throughout the run
  // note: check to see that it is properly destroyed somewhere
  // (this code moved from daapTCPConnect())
  sslctx = SSL_CTX_new(SSLv23_client_method());
  if (sslctx == NULL) {
    ERROR_OUTPUT(("Error in creation of SSL_CTX object"));
    return -1;
  }
  SSL_CTX_clear_options(sslctx, options);
  // recommended to not allow use of SSLv3 protocol for security reasons, so we turn it off
  options = SSL_OP_NO_SSLv3;
  SSL_CTX_set_options(sslctx, options);
  int use_cert = SSL_CTX_use_certificate_file(sslctx, ssl_client_cert, 
					      SSL_FILETYPE_PEM);
  int use_prv = SSL_CTX_use_PrivateKey_file(sslctx, ssl_client_key, 
					    SSL_FILETYPE_PEM);
  SSL_CTX_set_verify(sslctx, SSL_VERIFY_NONE, NULL); 
}

// function below integrated into daapShutdownSSL
/*
void daapDestroySSL() {
  ERR_free_strings();
  EVP_cleanup();
}
*/
void daapShutdownSSL() {
  SSL_CTX_free(sslctx);
  // One SSL_shutdown sends close_notify alert, other receives response from peer (server)
  SSL_shutdown(cSSL);
  SSL_shutdown(cSSL);
  SSL_free(cSSL);
  // migrated from daapDestroySSL()
  ERR_free_strings();
  EVP_cleanup();
}
/*
int daapTCPClose() {
    // Close connection if using TCP
    daapShutdownSSL();
    daapDestroySSL();
    close(sockfd);
}
*/
int daapTCPLogWrite(char *buf, int buf_size) {
    int count = 0, total_count = 0;
    int retries = 0;
    int ret;

    pthread_mutex_lock(&write_mutex);
    ret = daapTCPConnect();
    if (ret < 0) {
        pthread_mutex_unlock(&write_mutex);
        return DAAP_ERROR;
    }
    ERR_clear_error();
    /* send log message over socket*/
    while (total_count != buf_size) {
        count = SSL_write(cSSL, buf+count, buf_size-count);
        //err = SSL_get_error(ssl_connection, count);

        // the error handler below doesn't retry, it exits
        //upon failure. Is there a more robust way to handle problems?
        CHK_SSL(count);
        //will the below ever execute if the CHK_SSL above exits when count == -1?
        if (count < 0) {
            printf("ssl write count is: %d\n", count);
            count = -1;
            break;
        }
        total_count += count;
    }

    //daapTCPClose();
    close(sockfd);
    pthread_mutex_unlock(&write_mutex);
    return count;
}

int daapTCPConnect(void) {
  /* socket struct */
  struct sockaddr_in servaddr;
  int ret_val = 0;
  int ssl_err = 0;
  //SSL_CTX *sslctx; declared as static up top now

  // code below moved to daapInitializeSSL()
/*
  char ssl_client_cert[PATH_MAX];
  char ssl_client_key[PATH_MAX];
  int home_len;
  int ssl_client_key_len;
  int ssl_client_cert_len;
  char *home;

  home = getenv("HOME");
  ssl_client_cert_len = strlen(SSL_CLIENT_CERT);
  ssl_client_key_len = strlen(SSL_CLIENT_KEY);
  if (home != NULL && (strlen(home) + ssl_client_key_len < PATH_MAX) && 
      (strlen(home) + ssl_client_cert_len < PATH_MAX)) {
    home_len = strlen(home);
    snprintf(ssl_client_cert, home_len+ssl_client_cert_len+2,"%s%s", home, SSL_CLIENT_CERT);
    snprintf(ssl_client_key, home_len+ssl_client_key_len+2,"%s%s", home, SSL_CLIENT_KEY);
    if (access(ssl_client_cert, F_OK) == -1 || access(ssl_client_key, F_OK) == -1) {
      fprintf(stderr, "Cannot find DAAP ssl cert: %s or key: %s\n", 
	      ssl_client_cert, ssl_client_key);
      return -1;
    }
  } else{
      fprintf(stderr, "Invalid path length for certificates\n");
      return -1;
  }
*/
  //call moved to daapInit
  //daapInitializeSSL();
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if( sockfd < 0 ) {
      perror("socket creation failed");
      return sockfd;
  }
	
  bzero(&servaddr, sizeof(servaddr));
	
  /* assign IP, PORT */
  servaddr.sin_family = AF_INET;
  /* server is always on the local host */
  servaddr.sin_addr.s_addr = inet_addr("127.0.0.1");
  servaddr.sin_port = htons(PORT);
  
  /* connect the client to the server */
  ret_val = connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr));
  if( ret_val != 0 ) {
      perror("connection to the TCP server failed");
      return -1;
  }

  // code in comments below has been moved to daapInitializeSSL()
  /*
  sslctx = SSL_CTX_new(SSLv23_client_method());
  if (sslctx == NULL) {
    ERROR_OUTPUT(("Error in creation of SSL_CTX object"));
    return -1;
  }
  SSL_CTX_clear_options();
  // recommended to not allow use of SSLv3 protocol for security reasons, so we turn it off
  SSL_CTX_set_options(sslctx, SSL_OP_NO_SSLv3);
  int use_cert = SSL_CTX_use_certificate_file(sslctx, ssl_client_cert, 
					      SSL_FILETYPE_PEM);
  int use_prv = SSL_CTX_use_PrivateKey_file(sslctx, ssl_client_key, 
					    SSL_FILETYPE_PEM);
  SSL_CTX_set_verify(sslctx, SSL_VERIFY_NONE, NULL); 
  */
  cSSL = SSL_new(sslctx);
  SSL_set_fd(cSSL, sockfd);
  ret_val = SSL_connect (cSSL);
  if(ret_val < 0) {
      //Error occurred, log and close down ssl
      daapShutdownSSL();
      return -1;    
  }

  return 0;
}

