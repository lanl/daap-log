
#include <stdio.h>
#include <errno.h>
#include <strings.h>
#include <unistd.h>
#include <pthread.h>

/* TCP includes/struct */
# include <sys/socket.h>
# include <arpa/inet.h>

/* SSL includes */
#include <openssl/crypto.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#define PORT 5555

#define CHK_NULL(x) if ((x)==NULL) exit (1)
#define CHK_ERR(err,s) if ((err)==-1) { perror(s); exit(1); }
#define CHK_SSL(err) if ((err)==-1) { ERR_print_errors_fp(stderr); exit(2); }

static pthread_mutex_t write_mutex = PTHREAD_MUTEX_INITIALIZER;

SSL *cSSL = NULL;
int sockfd = -1;

void daapInitializeSSL() {
  SSL_load_error_strings();
  SSL_library_init();
  OpenSSL_add_all_algorithms();
}

void daapDestroySSL() {
  ERR_free_strings();
  EVP_cleanup();
}

void daapShutdownSSL() {
  SSL_shutdown(cSSL);
  SSL_free(cSSL);
}

int daapTCPClose() {
    // Close connection if using TCP
    daapShutdownSSL();
    daapDestroySSL();
    close(sockfd);
}

int daapTCPLogWrite(char *buf, int buf_size) {
    int count = 0, total_count = 0;
    int retries = 0;

    pthread_mutex_lock(&write_mutex);
    daapTCPConnect();
    /* send log message over socket*/
    while (total_count != buf_size) {
        count = SSL_write(cSSL, buf+count, buf_size-count);
        CHK_SSL(count);
        if (count < 0) {
            printf("ssl write count is: %d\n", count);
            count = -1;
            break;
        }

        total_count += count;
    }

    daapTCPClose();
    pthread_mutex_unlock(&write_mutex);
    return count;
}

int daapTCPConnect(void) {
  /* socket struct */
  struct sockaddr_in servaddr;
  int ret_val = 0;
  int ssl_err = 0;
  SSL_CTX *sslctx;

  daapInitializeSSL();
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

  sslctx = SSL_CTX_new(SSLv23_client_method());
  int use_cert = SSL_CTX_use_certificate_file(sslctx, "/users/hng/daap_certs/daap_client_cert.pem", 
					      SSL_FILETYPE_PEM);
  int use_prv = SSL_CTX_use_PrivateKey_file(sslctx, "/users/hng/daap_certs/daap_client_key.pem", 
					    SSL_FILETYPE_PEM);
  SSL_CTX_set_verify(sslctx, SSL_VERIFY_NONE, NULL); 
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

