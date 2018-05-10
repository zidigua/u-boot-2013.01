#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
int main(int argc, char **argv)
{
	if(3 != argc)
	{
		printf("Usage: %s <inf> <outf>\n", argv[0]);
		return;
	}

	int fdin = open(argv[1], O_RDONLY);
	if(-1 == fdin)
	{
		perror("open inf");
		return -1;
	}

	int fdout = open(argv[2], O_WRONLY|O_CREAT|O_TRUNC, 0666);
	if(-1 == fdout)
	{
		perror("open outf");
		return -1;
	}

	char buf[16*1024] = {0};
	printf("read: %d\n", read(fdin, buf, sizeof buf));

	int i = 0;
	unsigned int sum = 0;
	for(;i<14*1024-4; i++)
		sum += (unsigned char)buf[i];

	*((unsigned int*)&buf[14*1024-4]) = sum;

	printf("write: %d\n", write(fdout, buf, sizeof buf));


	close(fdin);
	close(fdout);
}
