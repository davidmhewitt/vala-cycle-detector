import sys
from os import path, access, R_OK
import networkx as nx

def usage():
    sys.stderr.write("USAGE: find_cycles.py /path/to/file.dot\n")

def main():

    path = ""
    if (len(sys.argv) > 1):
        path = sys.argv[1]
    else:
        usage()
        sys.exit(1)

    try:
        fh = open(path)
    except IOError as e:
        sys.stderr.write("ERROR: could not read file " + path + "\n")
        usage()
        sys.exit(1)

    # read in the specified file, create a networkx DiGraph
    G = nx.DiGraph(nx.drawing.nx_pydot.read_dot(path))

    C = nx.simple_cycles(G)

    for i in C:
        print i

# Run
if __name__ == "__main__":
    main()
