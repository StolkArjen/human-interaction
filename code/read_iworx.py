#!/usr/bin/env python

"""
--------------------------------------------------------
  READ_IWORX reads and converts various IWORX datafiles
  into a FieldTrip-type data structure

  Use as
    data, event = read_iworx(folder)
  where folder contains a data (.txt) and marks (.txt) file

  data has the following nested fields:
    .trial
    .time
    .label

  event has the following nested fields:
    .type
    .sample
    .value

  Copyright (C) 2022, Arjen Stolk
  --------------------------------------------------------
"""


import glob
import numpy as np


def read_iworx(folder):
    # check the input
    txtfiles = glob.glob(folder + '/*.txt')
    for l in txtfiles:
        if l.find('Marks') > 0:
            markfile = l
        else:
            datafile = l

    # read the marks file
    class Event(object):
        def __init__(self):
            self.type = []
            self.sample = []
            self.value = []
    event = Event()
    try:
        with open(markfile) as f:
            contents = f.readlines()
            for e in range(1, len(contents)):
                event.type.append('trig')
                h, m, s = contents[e].split("	")[contents[0].split(
                    '\t').index('Real Time')].split(':')
                event.sample.append(float(h) * 3600 + float(m) * 60 + float(s))
                event.value.append(contents[e].split(
                    "	")[contents[0].split('\t').index('MarkValue')])
    except:
        print('a problem arose extracting the events')

    # read the data file
    class Data(object):
        def __init__(self):
            self.trial = []
            self.time = []
            self.label = []
    data = Data()
    try:
        with open(datafile) as f:
            contents = f.readlines()
            # header
            data.label = contents[0].rstrip().split('\t')
            idx = []
            for i, l in enumerate(data.label):
                if l.find('Time'):
                    idx.append(i)
            data.label = [data.label[i] for i in idx]

            # data
            trl = 0
            data.trial.append([])
            data.time.append([])
            tmp = []
            for smp in range(1, len(contents)):
                if contents[smp].split('\t')[0] == 'TimeOfDay': # mark a new datablock/trial
                    data.trial[trl] = np.transpose(np.vstack(np.array(tmp)))
                    trl += 1
                    data.trial.append([])
                    data.time.append([])
                    tmp = []
                else: # read the data line by line
                    tmp.append([float(x) for i, x in enumerate(
                        contents[smp].rstrip().split('\t')) if i in idx])
                    if contents[0].split('\t')[0] == 'TimeOfDay': # if possible, add time information from TimeOfDay timestamps
                        h, m, s = contents[smp].split(
                            "	")[contents[0].split('\t').index('TimeOfDay')].split(':')
                        data.time[trl].append(
                            float(h) * 3600 + float(m) * 60 + float(s))
            data.trial[trl] = np.transpose(np.vstack(np.array(tmp)))
    except:
        print('a problem arose reading the data')

    return data, event
