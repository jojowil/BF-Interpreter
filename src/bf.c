#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#define DEFAULT_ARENA_SIZE 30000

/*
 * This version is translated from https://brainfuck.org/brainfuck.html
 * Anything that was undefined is defined here with a specific outcome.
 */

/*===========================================*/

/**
 * reads all bytes from a given filename
 * @param fname string filename
 * @return pointer to bytes or NULL
 */
char* readAllBytes(const char* fname) {
    FILE *file;
    long fileSize;
    char *buffer;
    size_t bytesRead;

    // open file
    file = fopen(fname, "r");
    if (file == NULL) {
        perror("Error opening file");
        return NULL;
    }

    // get size
    fseek(file, 0, SEEK_END);
    fileSize = ftell(file);
    rewind(file);

    // get the mem
    buffer = (char*)malloc(fileSize * sizeof(char) + 1);

    // Read the entire file into the buffer
    bytesRead = fread(buffer, 1, fileSize, file);
    if (bytesRead != fileSize) {
        perror("Error reading file");
        fclose(file);
        free(buffer);
        return NULL;
    }
    // add the terminator
    buffer[fileSize] = '\0';
    return buffer;
}

/**
 * Simple usage message.
 */
void usage() {
    printf("bf [-m memsize] <bffile.b>\nOptions:\n");
    printf("\t-m memsize (if >30,000 cells is required)\n");
    exit(255);
}

/**
 * Provides a safe, deterministic ASCII to long
 * @param buf string to be converted to long
 * @return converted number. errno is set to ERANGE or EINVAL.
 */
long myatol(const char* buf) {
    errno = 0;
    char *p;
    long a = strtol(buf, &p, 10); // also sets ERANGE

    // *p can be '\0' or '\n', but p cannot be buf.
    if  (! ((!*p || *p == '\n')  && p != buf && !errno))
        errno = EINVAL;
    return a;
}

/**
 * BF interpreter engine
 * @param code pointer to the text code from the file
 * @param ARENA pointer to the memory arena
 * @param arenaSize size of the arena for bounds checking
 */
void interpret(const char *code, char *ARENA, long arenaSize) {
/*
 *  OP  Meaning
 *  --  -------
 *   >  Move the pointer to the right
 *   <  Move the pointer to the left
 *   +  Increment the memory cell at the pointer
 *   -  Decrement the memory cell at the pointer
 *   .  Output the character signified by the cell at the pointer
 *   ,  Input a character and store it in the cell at the pointer
 *   [  Jump past the matching ] if the cell at the pointer is 0
 *   ]  Jump back to the matching [ if the cell at the pointer is nonzero
 */
    int cp = 0; // code pointer
    long ap = 0; // arena pointer

    while (code[cp] != '\0') {
        //printf("cp = %d, ap = %d, ARENA[%d] = %d, code=%c \n", cp, ap, ap, ARENA[ap], code[cp]);
        //fgetc(stdin);
        char c;
        switch (code[cp]) {
            case '>':
                ap++;
                if (ap == arenaSize) {
                    errno = EADDRNOTAVAIL;
                    perror("Attempt to access unavailable cell (>areaSize).");
                    return;
                }
                break;
            case '<':
                if (ap == 0) {
                    errno = EADDRNOTAVAIL;
                    perror("Attempt to access unavailable cell (<0).");
                    return;
                }
                ap--;
                break;
            case '+': ARENA[ap]++; break;
            case '-': ARENA[ap]--; break;
            case '.': fputc(ARENA[ap], stdout); break;
            case ',':
                c = (char)fgetc(stdin);
                if (c != EOF)
                    ARENA[ap] = c;
                break;
            case '[':
                if (ARENA[ap] == 0) {
                    int depth = 1;
                    cp++;
                    while (code[cp] != '\0' && depth > 0) {
                        switch(code[cp]) {
                            case '\0' :
                                errno = EOF;
                                perror("Reached unexpected end of program");
                                return;
                            case '[': depth++; break;
                            case ']': depth--; break;
                        }
                        cp++;
                    }
                }
                break;
            case ']':
                if (ARENA[ap] != 0) {
                    int depth = 1;
                    cp--;
                    while (cp >= 0 && depth > 0) {
                        //printf("cp = %d, ap = %d, ARENA[%d] = %d, code=%c, depth=%d \n", cp, ap, ap, ARENA[ap], code[cp], depth);
                        switch(code[cp]) {
                            case ']': depth++; break;
                            case '[': depth--; break;
                        }
                        cp--;
                    }
                    if (cp < 0) {
                        errno = EADDRNOTAVAIL;
                        perror("Attempt to move beyond beginning of program.\nLikely unbalanced ']'");
                        return;
                    }
                }
                break;
        }
        cp++;
    }
}

int main(int argc, char **argv) {
    char *ARENA, *code;
    char *fname = argv[1]; // for now
    long size = 0; // for now

    // handle argument processing
    if (argc < 2 || argc > 4) usage(); // try again
    if (argc == 4 && argv[1][0] == '-') {
        if (argv[1][1] == 'm') {
            size = myatol(argv[2]);
            if (errno) usage();
            fname = argv[3];
        } else usage(); // unknown option
    }

    if (size == 0) size = DEFAULT_ARENA_SIZE;

    // set the arena!
    ARENA = calloc(size, sizeof(char));
    if (ARENA == NULL) {
        perror("Cannot allocate ARENA");
        return 1;
    }

    /* read the code! */
    code = readAllBytes(fname);
    if (code == NULL) {
        free(ARENA);
        perror("Cannot retrieve BF code");
        return 2;
    }

    // finally!
    interpret(code, ARENA, size);

    free(code);
    free(ARENA);
    return 0;
}
