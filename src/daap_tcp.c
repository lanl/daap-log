
#include <stdio.h>
#include <errno.h>
#include <strings.h>
#include <unistd.h>

/* TCP includes/struct */
# include <sys/socket.h>
# include <arpa/inet.h>

#define PORT 5555

int daapTCPConnect(void) {
  /* socket struct */
  struct sockaddr_in servaddr;
  int sockfd, ret_val;
  
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

  return sockfd;
}

int daapTCPClose(int sockfd) {
    // Close connection if using TCP
    close(sockfd);
}

int daapTCPLogWrite(char *buf, int buf_size) {
    int count, total_count = 0;
    int retries = 0;
    int sockfd;

    //Retry up to 5 times
    while (retries < 5) {
	sockfd = daapTCPConnect();
	if (sockfd < 0) {
	    retries++;
	}

	if (sockfd != -1) {
	    break;
	}
    }

    if (sockfd == -1) {
	fprintf(stderr, "Error connecting server, not writing message");
	return -1;
    }

    /* send log message over socket*/
    while (total_count != buf_size) {
      count = write(sockfd, buf, buf_size);
      total_count += count;
    }

    daapTCPClose(sockfd);

    return total_count;
}
