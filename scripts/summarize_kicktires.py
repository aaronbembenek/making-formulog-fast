#!/usr/bin/env python3

from collections import defaultdict
import csv
import fileinput

def main():
    reader = csv.DictReader(fileinput.input())
    data = defaultdict(list) 
    for line in reader:
        key = line["case_study"], line["benchmark"]
        data[key].append(line)
    for (case_study, bm), points in data.items():
        print(f"{case_study}/{bm}")
        for point in points:
            mode = point["mode"]
            if point["success"] == "y":
                time = point["execute_time"]
                if time == "NA":
                    time = point["interpret_time"]
                time = f"{time}s"
            else:
                time = "NA"
            print(f"\t{mode} {time}")

if __name__ == "__main__":
    main()