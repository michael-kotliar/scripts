import sys
import re
import itertools
import gzip
import argparse
import os


def arg_parser():
    general_parser = argparse.ArgumentParser()
    general_parser.add_argument("-i1", "--input1",   help="Input fastq file 1, gzipped",  required=True)
    general_parser.add_argument("-i2", "--input2",   help="Input fastq file 2, gzipped",  required=True)
    general_parser.add_argument("-o1", "--output1",  help="Output fastq file 1, gzipped", default="filtered_1.fastq.gz")
    general_parser.add_argument("-o2", "--output2",  help="Output fastq file 2, gzipped", default="filtered_2.fastq.gz")
    general_parser.add_argument("-f",  "--filter",   help="List of filtering criteria",   required=True, nargs='+')
    general_parser.add_argument("-m",  "--mismatch", help="Maximum mismatch number. Default 1",      type=int, default=1)
    general_parser.add_argument("-s",  "--start",    help="Start position of the scanning interval. Default 0 (from the beginning)", type=check_not_negative, default=0)
    general_parser.add_argument("-l",  "--length",   help="Length of the scanning interval. Default 999 (till the end)",             type=check_positive,     default=999)
    return general_parser


def check_not_negative(value):
    ivalue = int(value)
    if ivalue < 0:
        raise argparse.ArgumentTypeError("%s  - should be >= 0" % value)
    return ivalue


def check_positive(value):
    ivalue = int(value)
    if ivalue <= 0:
        raise argparse.ArgumentTypeError("%s  - should be > 0" % value)
    return ivalue


def normalize_args(args, skip_list=[]):
    """Converts all relative path arguments to absolute ones relatively to the current working directory"""
    normalized_args = {}
    for key,value in args.__dict__.items():
        if key not in skip_list:
            normalized_args[key] = value if not value or os.path.isabs(value) else os.path.normpath(os.path.join(os.getcwd(), value))
        else:
            normalized_args[key]=value
    return argparse.Namespace (**normalized_args)


def get_compiled_regex(target_patterns, max_mismatch_counts):
    regex_list = []
    for pattern in target_patterns:
        pattern_l = list(pattern)
        combinations = itertools.combinations(range(len(pattern_l)), max_mismatch_counts) 
        for combination in combinations:
            pattern_l_copy = pattern_l[:]
            for i in combination:
                pattern_l_copy[i]="$"
            regex_list.append(''.join(pattern_l_copy).replace("$", ".?"))
    return re.compile("|".join(regex_list), re.IGNORECASE)


def run_filtering(args):
    print("Filter input files:\n", args.input1, "\n", args.input2)
    print("Filtering criteria:", args.filter)
    print("Max mismatches:", args.mismatch)
    print("Scanning interval ranges", args.start, args.start+args.length)
    
    compiled_regex = get_compiled_regex(args.filter, args.mismatch)
    total = 0
    with gzip.open(args.input2,'rb') as f2_input_stream:
        for l in f2_input_stream:
            total += 1
    total = int(total / 4)
    print("Total number of read:", total)

    count = 0
    with gzip.open(args.input1,'rb') as f1_input_stream:
        with gzip.open(args.input2,'rb') as f2_input_stream:
            with gzip.open(args.output1, 'wb') as f1_output_stream:
                with gzip.open(args.output2, 'wb') as f2_output_stream:
                    f1_read_data = []
                    f2_read_data = []
                    for f1_line, f2_line in zip(f1_input_stream, f2_input_stream):
                        f1_read_data.append(f1_line.decode("utf-8").rstrip())
                        f2_read_data.append(f2_line.decode("utf-8").rstrip())
                        if len(f1_read_data) == 4 and len(f2_read_data) == 4:
                            count += 1
                            f1_record = {k: v for k, v in zip(['name', 'sequence', 'strand', 'quality'], f1_read_data)}
                            f2_record = {k: v for k, v in zip(['name', 'sequence', 'strand', 'quality'], f2_read_data)}
                            scanned_seq = f2_record["sequence"][args.start:args.start+args.length]
                            if compiled_regex.search(scanned_seq):
                                f1_output_stream.write(("\n".join([ f1_record["name"], f1_record["sequence"], f1_record["strand"], f1_record["quality"]])+"\n").encode("utf-8"))
                                f2_output_stream.write(("\n".join([ f2_record["name"], f2_record["sequence"], f2_record["strand"], f2_record["quality"]])+"\n").encode("utf-8"))
                            f1_read_data = []
                            f2_read_data = []
                            if count % 10000 == 0:
                                print("Reads processed:", count, "/", total, "(", int(float(count)/float(total)*100) ,"%",")")


def main(argsl=None):
    if argsl is None:
        argsl = sys.argv[1:]
    args,_ = arg_parser().parse_known_args(argsl)
    args = normalize_args(args, ["filter", "mismatch", "start", "length"])
    run_filtering(args)
    print("Finished successfully")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))