#!/usr/bin/env python

"""
--------------------------------------------------------
  IMPORT_IWORX reads and converts various IWORX datafiles
  into a FieldTrip-type data structure

  Use as
    data, event = import_iworx(folder)
  where folder contains a data (.mat) and a marks (.txt) file

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


import os
import glob
import scipy.io

def import_iworx(folder):

    # check the input
    matfile = glob.glob(os.path.join(folder, "*.mat"))[0]
    hasmat = 0
    if os.path.exists(matfile):
        hasmat = 1
    markfile = glob.glob(os.path.join(folder, "*.txt"))[0]
    hasmark = 0
    if os.path.exists(markfile):
        hasmark = 1

    # read the data
    class Data(object):
        def __init__(self):
            self.trial = []
            self.time = []
            self.label = []
    data = Data()
    if hasmat:
        mat = scipy.io.loadmat(matfile)
        for t in range(mat["n"][0][0]):  # n is a variable contained by the mat file
            data.trial.append(mat["b" + str(t + 1)].T)
            data.time.append(mat["b" + str(t + 1)][:, 0])
        data.label = ['Time', 'Corrugator supercilii muscle', 'Zygomaticus major muscle', 'Heart Rate', 'dunno', 'Skin Conductance']

    # read the markers
    class Event(object):
        def __init__(self):
            self.type = []
            self.sample = []
            self.value = []
    event = Event()
    if hasmark:
        with open(markfile) as f:
            contents = f.readlines()
        for e in range(1, len(contents)):
            event.type.append(contents[e].split("	")[0])
            event.sample.append(contents[e].split("	")[1])
            event.value.append(contents[e].split("	")[4])

    return data, event
    