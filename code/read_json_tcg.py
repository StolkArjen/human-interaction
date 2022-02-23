#!/usr/bin/env python

"""
--------------------------------------------------------
READ_JSON_TCG reads communication game json files originating
from the web version of the tcg or tcg kids

INPUT
Use as: data = read_json_tcg('room001225')
where 'roomxxx' is a folder containing the '*.json' files

OUTPUT
A struct containing;
info      recording file, date and onset, and game type
trial     rows (trials) x columns (variables)
label     variable names
event     onsets and durations of task events
token     token positions

Arjen Stolk, 2022
--------------------------------------------------------
"""


import os
import datetime
import glob
import re
import json
import numpy as np


class Data(object):
    # initialize data structure
    def __init__(self):
        # logfile, date, player 1 ID, player 2 ID, player 1 date, player 2 date
        self.info = [None] * 6
        self.trial = []
        self.label = ['TrialNr', 'TrialType', 'TrialTypeNr', 'TrialOnset',
                      'SenderPlayer', 'SenderPlanTime', 'SenderMovTime', 'SenderNumMoves',
                      'TargetNum', 'TargetTime', 'NonTargetTime',
                      'ReceiverPlayer', 'ReceiverPlanTime', 'ReceiverMovTime', 'ReceiverNumMoves',
                      'Success', 'SenderLocSuccess', 'SenderOriSuccess', 'ReceiverLocSuccess', 'ReceiverOriSuccess',
                      'Level', 'TrialOffset']
        self.event = []  # onset timestamps of the five epochs
        # coord [xPos, yPos, angle], time, shape, control, action, target [xPos, yPos, angle]
        self.token_sender = []
        self.token_receiver = []


def read_json_tcg(logfile):
    # recording information
    data = Data()
    data.info[0] = logfile
    data.info[1] = datetime.datetime.fromtimestamp(
        os.stat(logfile).st_mtime).strftime('%Y-%m-%d-%H:%M')

    # read all json files
    sess = ['practice', 'training', 'game']
    epoch = ['roleassignment', 'tokenassignment',
             'sender', 'receiver', 'feedback']
    for sidx, s in enumerate(sess):
        data.trial.append([])  # multiple trials per session
        data.event.append([])
        data.token_sender.append([])
        data.token_receiver.append([])

        # number of trials for this session
        list = glob.glob(logfile + os.path.sep + s + "*.json")
        ntrls = 0
        for l in list:
            dig = re.findall(r'\d+', l)
            trl = int(dig[len(dig)-1])
            if trl > ntrls:
                ntrls = trl

        # trial loop
        for t in range(ntrls):
            data.event[sidx].append([])  # multiple events/locations per trial
            data.token_sender[sidx].append([])
            data.token_receiver[sidx].append([])
            TrialOnset = np.nan
            TrialOffset = np.nan
            SenderPlayer = np.nan
            ReceiverPlayer = np.nan
            SenderPlanTime = np.nan
            SenderMovTime = np.nan
            SenderNumMoves = 0
            ReceiverPlanTime = np.nan
            ReceiverMovTime = np.nan
            ReceiverNumMoves = 0
            TargetNum = 0
            TargetTime = []
            NonTargetTime = []
            ReceiverTargetPos = np.nan
            Success = np.nan
            SenderLocSuccess = np.nan
            SenderOriSuccess = np.nan
            ReceiverLocSuccess = np.nan
            ReceiverOriSuccess = np.nan
            SenderTarget = np.nan
            ReceiverTarget = np.nan
            Level = np.nan

            # epoch loop
            for eidx, e in enumerate(epoch):
                filename = glob.glob(logfile + os.path.sep + s + \
                    '_trial_' + str(t+1) + '_' + e + '*.json')
                if filename:

                    # read in json structure
                    with open(filename[0]) as file:
                        val = json.load(file)

                        # trial onsets and roles
                        if (val[0]['epoch'] == 'roleassignment' and (s == 'training' or s == 'game')) or \
                                (val[0]['epoch'] == 'tokenassignment' and s == 'practice'):
                            TrialOnset = val[0]['timestamp']
                            if 'p1' in val[0] or 'p2' in val[0]:
                                if 'angle' in val[0]['p1']:  # tcg
                                    if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'sender':
                                        SenderPlayer = 1
                                        SenderTarget = [
                                            val[0]['p1']['goal']['xPos'], val[0]['p1']['goal']['yPos'], val[0]['p1']['goal']['angle']]
                                    elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'sender':
                                        SenderPlayer = 2
                                        SenderTarget = [
                                            val[0]['p2']['goal']['xPos'], val[0]['p2']['goal']['yPos'], val[0]['p2']['goal']['angle']]
                                    if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'receiver':
                                        ReceiverPlayer = 1
                                        ReceiverTarget = [
                                            val[0]['p1']['goal']['xPos'], val[0]['p1']['goal']['yPos'], val[0]['p1']['goal']['angle']]
                                        ReceiverTargetPos = [
                                            val[0]['p1']['goal']['xPos'], val[0]['p1']['goal']['yPos']]
                                    elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'receiver':
                                        ReceiverPlayer = 2
                                        ReceiverTarget = [
                                            val[0]['p2']['goal']['xPos'], val[0]['p2']['goal']['yPos'], val[0]['p2']['goal']['angle']]
                                        ReceiverTargetPos = [
                                            val[0]['p2']['goal']['xPos'], val[0]['p2']['goal']['yPos']]
                                else:  # tcg kids
                                    if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'sender':
                                        SenderPlayer = 1
                                        SenderTarget = [0, 0]
                                    elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'sender':
                                        SenderPlayer = 2
                                        SenderTarget = [0, 0]
                                    if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'receiver':
                                        ReceiverPlayer = 1
                                        ReceiverTarget = val[0]['p1']['goal']
                                        ReceiverTargetPos = val[0]['p1']['goal']
                                    elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'receiver':
                                        ReceiverPlayer = 2
                                        ReceiverTarget = val[0]['p2']['goal']
                                        ReceiverTargetPos = val[0]['p2']['goal']
                            # player IDs (for relating to userinput)
                            for v in val:
                                if 'Iamplayer' in v:
                                    if v['Iamplayer'] == 1:
                                        data.info[2] = 'player 1: ' + \
                                            v['player']
                                        try:
                                            data.info[4] = 'date 1: ' + \
                                                v['date']
                                        except:
                                            print('player 1 date not found')
                                    elif v['Iamplayer'] == 2:
                                        data.info[3] = 'player 2: ' + \
                                            v['player']
                                        try:
                                            data.info[5] = 'date 2: ' + \
                                                v['date']
                                        except:
                                            print('player 2 date not found')

                        # planning and movement times
                        if val[0]['epoch'] == 'sender':
                            for index, v in enumerate(val):
                                # planning & movement time
                                if 'action' in v:
                                    if v['action'] == 'start':
                                        SenderMovOnset = v['timestamp']
                                        SenderPlanTime = SenderMovOnset - \
                                            val[0]['timestamp']  # 1st timestamp is goal onset
                                        WaitForOffTarget = 0
                                    elif v['action'] == 'stop' or v['action'] == 'timeout':
                                        SenderMovOffset = v['timestamp']
                                        SenderMovTime = SenderMovOffset - SenderMovOnset
                                        if not TargetTime:  # empty
                                            TargetTime = np.nan
                                        elif TargetTime:  # not empty
                                            TargetTime = np.nanmean(TargetTime)
                                        if not NonTargetTime:  # empty
                                            NonTargetTime = np.nan
                                        elif NonTargetTime:  # not empty
                                            NonTargetTime = np.nanmean(
                                                NonTargetTime)
                                    elif v['action'] == 'up' or v['action'] == 'down' or \
                                            v['action'] == 'left' or v['action'] == 'right' or \
                                            v['action'] == 'rotateleft' or v['action'] == 'rotateright':
                                        SenderNumMoves = SenderNumMoves + 1
                                        # tcg kids
                                        if SenderNumMoves == 1 and str(v['token']['shape']).isalpha():
                                            SenderMovOnset = v['timestamp']
                                            SenderPlanTime = SenderMovOnset - \
                                                val[0]['timestamp']  # 1st timestamp is goal onset
                                            WaitForOffTarget = 0
                                        # time spent at location
                                        if WaitForOffTarget == 1:
                                            TargetTime.append(
                                                v['timestamp'] - val[index-1]['timestamp'])
                                            WaitForOffTarget = 0
                                        else:
                                            NonTargetTime.append(
                                                v['timestamp'] - val[index-1]['timestamp'])
                                        # on target
                                        # tcg
                                        if str(v['token']['shape']).isnumeric() and [v['token']['xPos'], v['token']['yPos']] == ReceiverTargetPos:
                                            TargetNum = TargetNum + 1
                                            WaitForOffTarget = 1
                                        # tcg kids
                                        elif str(v['token']['shape']).isalpha() and check_target(v['token']):
                                            TargetNum = TargetNum + 1
                                            WaitForOffTarget = 1
                                        # double check on target
                                        # overlooked targets
                                        if s != 'practice' and v['token']['onTarget'] and TargetNum == 0:
                                            print(
                                                'WARNING: on target missed for ' + logfile + ', ' + s + ', trial ' + str(t))
                                # token coord & timestamps
                                if 'token' in v:
                                    if 'angle' in v['token']:  # tcg
                                        data.token_sender[sidx][t].append([[v['token']['xPos'], v['token']['yPos'], v['token']['angle']],
                                                                           v['timestamp'], v['token']['shape'], v['token']['control'], v['action'], SenderTarget])
                                    else:  # tcg kids
                                        data.token_sender[sidx][t].append([[v['token']['xPos'], v['token']['yPos']],
                                                                           v['timestamp'], v['token']['shape'], v['token']['control'], v['action'], SenderTarget])

                        elif val[0]['epoch'] == 'receiver':
                            for index, v in enumerate(val):
                                # planning & movement time
                                if 'action' in v:
                                    if v['action'] == 'start':
                                        ReceiverMovOnset = v['timestamp']
                                        ReceiverPlanTime = ReceiverMovOnset - \
                                            val[0]['timestamp']  # 1st timestamp is goal onset
                                    elif v['action'] == 'stop' or v['action'] == 'timeout':
                                        ReceiverMovOffset = v['timestamp']
                                        ReceiverMovTime = ReceiverMovOffset - ReceiverMovOnset
                                    elif v['action'] == 'up' or v['action'] == 'down' or \
                                            v['action'] == 'left' or v['action'] == 'right' or \
                                            v['action'] == 'rotateleft' or v['action'] == 'rotateright' or \
                                            v['action'] == 'tracking':
                                        ReceiverNumMoves = ReceiverNumMoves + 1
                                        # tcg kids
                                        if ReceiverNumMoves == 1 and str(v['token']['shape']).isalpha():
                                            ReceiverMovOnset = v['timestamp']
                                            ReceiverPlanTime = ReceiverMovOnset - \
                                                val[0]['timestamp']  # 1st timestamp is goal onset
                                # token coord & timestamps
                                if 'token' in v:
                                    if 'angle' in v['token']:  # tcg
                                        data.token_receiver[sidx][t].append([[v['token']['xPos'], v['token']['yPos'], v['token']['angle']],
                                                                             v['timestamp'], v['token']['shape'], v['token']['control'], v['action'], ReceiverTarget])
                                    else:  # tcg kids
                                        data.token_receiver[sidx][t].append([[v['token']['xPos'], v['token']['yPos']],
                                                                             v['timestamp'], v['token']['shape'], v['token']['control'], v['action'], ReceiverTarget])

                        # feedback, level and trial offset
                        if val[0]['epoch'] == 'feedback':
                            Success = val[0]['success']
                            if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'sender':
                                SenderLocSuccess, SenderOriSuccess = check_feedback(
                                    val[0]['p1'])
                            elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'sender':
                                SenderLocSuccess, SenderOriSuccess = check_feedback(
                                    val[0]['p2'])
                            if 'p1' in val[0] and 'role' in val[0]['p1'] and val[0]['p1']['role'] == 'receiver':
                                ReceiverLocSuccess, ReceiverOriSuccess = check_feedback(
                                    val[0]['p1'])
                            elif 'p2' in val[0] and 'role' in val[0]['p2'] and val[0]['p2']['role'] == 'receiver':
                                ReceiverLocSuccess, ReceiverOriSuccess = check_feedback(
                                    val[0]['p2'])
                            if 'level' in val[0]:
                                Level = val[0]['level']
                            TrialOffset = val[0]['timestamp']+1000

                        # event timestamps
                        if val[0]['epoch'] == e:
                            # register the first timestamp
                            data.event[sidx][t].append(val[0]['timestamp'])

            # store in data structure
            data.trial[sidx].append([t+1, sidx+1, np.nan, TrialOnset,
                                     SenderPlayer, SenderPlanTime, SenderMovTime, SenderNumMoves, TargetNum, TargetTime, NonTargetTime,
                                     ReceiverPlayer, ReceiverPlanTime, ReceiverMovTime, ReceiverNumMoves,
                                     Success, SenderLocSuccess, SenderOriSuccess, ReceiverLocSuccess, ReceiverOriSuccess, Level, TrialOffset])
    return data


def check_feedback(p):
    loc, ori = 0, 0
    # location
    if p['shape'] == 'bird' and [p['xPos'], p['yPos']] == [0, 0]:
        loc = 1
    elif p['shape'] == 'squirrel':
        loc = np.nan
    elif [p['xPos'], p['yPos']] == [p['goal']['xPos'], p['goal']['yPos']]:
        loc = 1
    # orientation
    if p['shape'] == 'bird' or p['shape'] == 'squirrel':
        ori = 1
    elif p['shape'] == 1:  # rectangle
        if p['angle'] == p['goal']['angle'] or abs(p['angle']-p['goal']['angle']) == 180:
            ori = 1
    elif p['shape'] == 2:  # circle
        if loc == 1:  # angle
            ori = 1
    elif p['shape'] == 3:  # triangle
        if p['angle'] == p['goal']['angle']:  # angle
            ori = 1
    return loc, ori


def check_target(t):
    # field
    field = [None] * 15
    field[0] = [-1, 1]
    field[1] = [0, 1]
    field[2] = [0, 1]
    field[3] = [1, 1]
    field[4] = [1, 1]
    field[5] = [-1, 0]
    field[6] = [-1, 0]
    field[7] = [-1, 0]
    field[8] = [1, 0]
    field[9] = [-1, -1]
    field[10] = [0, -1]
    field[11] = [0, -1]
    field[12] = [1, -1]
    field[13] = [1, -1]
    field[14] = [1, -1]
    return [t['xPos'], t['yPos']] == field[t['goal']-1]
