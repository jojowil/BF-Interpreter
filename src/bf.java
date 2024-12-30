import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

public class bf {

    static final int DEFAULT_ARENA_SIZE = 30000;

    public static void usage() {
        System.out.println("java bf [-m memsize] <bffile.b>\nOptions:");
        System.out.println("\t-m memsize (if >30,000 cells is required)\n");
        System.exit(255);
    }

    public static void interpret(byte[] code, byte[] ARENA) {
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
        int ap = 0, arenaSize=ARENA.length; // arena pointer

        while (cp < code.length) {
            //System.out.printf("cp = %d, ap = %d, ARENA[%d] = %d, code=%c %n", cp, ap, ap, ARENA[ap], code[cp]);
            //fgetc(stdin);
            switch (code[cp]) {
                case '>':
                    ap++;
                    if (ap == arenaSize) {
                        System.err.println("Attempt to access unavailable cell (>areaSize).");
                        return;
                    }
                    break;
                case '<':
                    if (ap == 0) {
                        System.err.println("Attempt to access unavailable cell (<0).");
                        return;
                    }
                    ap--;
                    break;
                case '+': ARENA[ap]++; break;
                case '-': ARENA[ap]--; break;
                case '.': System.out.printf("%c", ARENA[ap]); break;
                case ',':
                    try {
                        ARENA[ap] = (byte)System.in.read();
                    } catch (IOException e) {
                        System.err.println("Cannot read stdin: " + e.getMessage());
                        return;
                    }
                    break;
                case '[':
                    if (ARENA[ap] == 0) {
                        int depth = 1;
                        cp++;
                        while (code[cp] != '\0' && depth > 0) {
                            switch(code[cp]) {
                                case '\0' :
                                    System.err.println("Reached unexpected end of program");
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
                            System.err.println("Attempt to move beyond beginning of program.\nLikely unbalanced ']'");
                            return;
                        }
                    }
                    break;
            }
            cp++;
        }
    }

    public static void main(String[] args) {
        int size=0;
        byte[] code, ARENA;
        FileInputStream in;

        /* handle argument processing */
        if (args.length < 1 || args.length > 3) usage(); // try again
        String fname = args[0];
        if (args.length == 3 && args[0].charAt(0) == '-') {
            if (args[0].charAt(1) == 'm') {
                try {
                    size = Integer.parseInt(args[1]);
                } catch (NumberFormatException e) {
                    usage();
                }
                fname = args[2];
            } else usage(); // unknown option
        }

        if (size == 0) size = DEFAULT_ARENA_SIZE;
        ARENA = new byte[size];

        try {
            in = new FileInputStream(fname);
        } catch (FileNotFoundException e) {
            System.err.println("Cannot find '"+fname+"': " + e.getMessage());
            return;
        }

        try {
            code = in.readAllBytes();
            in.close();
        } catch (IOException e) {
            System.err.println("Cannot read BF code: " + e.getMessage());
            return;
        }

        // finally!
        interpret(code, ARENA);
    }
}