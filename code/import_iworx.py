#!/usr/bin/env python

"""
--------------------------------------------------------
  IMPORT_IWORX reads and converts various IWORX datafiles into a 
  FieldTrip-type data structure.

  Use as
    [data] = import_iworx(filename)
  where the filename should point to a .mat or .txt datafile.
  
  Copyright (C) 2022, Arjen Stolk
  --------------------------------------------------------
"""


import os
import scipy.io

def import_iworx(filename):
  # check the input
  path = os.path.split(filename)[0] # xxx/
  name = os.path.split(filename)[-1][:-4] # xxx
  ext  = os.path.splitext(filename)[-1] # .xxx
  if ext != '.mat' and ext != '.txt':
    print('file extension should be either .mat or .txt for this function')
  hasmat = False
  if ext == '.mat':
    hasmat = True
  hastxt = False
  hasmark = False
  if ext == '.txt':
    hastxt = True
    if name[-10:] == '_MarksData':
      hasmark = True

  # organize the input
  if hasmark:
    datafile   = os.path.join(path, name[:-10] + '.mat')
    headerfile = os.path.join(path, name[:-10] + '.txt')
    markerfile = filename
  elif hastxt or hasmat:
    datafile   = os.path.join(path, name + '.mat')
    headerfile = os.path.join(path, name + '.txt')
    markerfile = os.path.join(path, name + '_MarksData.txt')

  # read the data
  mat = scipy.io.loadmat(datafile)

  # initialize data structure
  class Data(object):
    def __init__(self):
      self.trial = []
      self.time  = []
      self.label = []

  # organize data structure
  data = Data()
  for t in range(mat['n'][0][0]): # n is a variable contained by the mat file
    data.trial.append(mat['b' + str(t+1)].T)
    data.time.append(mat['b' + str(t+1)][:,0])

  # read the header information
  try:
    with open(headerfile) as f:
      contents = f.readlines()
    data.label = contents[0].split('	')
  except:
    print('could not read the header information')
  
  # read the markers
  event = []
  try:
    class Event(object):
      def __init__(self):
        self.type   = []
        self.sample = []
        self.value  = []
    event = Event()  
    with open(markerfile) as f:
      contents = f.readlines()
    for e in range(1, len(contents)):
      event.type.append(contents[e].split('	')[0])
      event.sample.append(contents[e].split('	')[1])
      event.value.append(contents[e].split('	')[4])
  except:
    print('could not read the marker information')

  return data, event
