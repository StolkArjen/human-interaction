#!/usr/bin/env python

"""
--------------------------------------------------------
  READ_IWORX reads and converts various IWORX datafiles
  into a FieldTrip-type data structure

  Use as
    data, event = read_iworx(filename)
  where filename has a .mat extension

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


import scipy.io

def read_iworx(filename):

    # check the input
    if not filename.endswith('.mat'):
        print('warning: this function requires a .mat file as input')

    # read the data
    class Data(object):
        def __init__(self):
            self.trial = []
            self.time = []
            self.label = []
    data = Data()
    mat = scipy.io.loadmat(filename)
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
    marks = [i for i in mat if i.startswith('m')]
    if marks:
        for e in marks:
            event.type.append('trig')
            event.sample.append(mat[e]['time'][0][0][0][0])
            event.value.append(mat[e]['value'][0][0][0])

        # discard trials unlikely to match the events
        for t in range(len(data.trial)):
            if data.time[t][-1] < event.sample[-1]:
                data.trial[t] = []
                data.time[t] = []
        data.trial = [t for t in data.trial if t != []]
        data.time = [t for t in data.time if t != []]
    
    return data, event
