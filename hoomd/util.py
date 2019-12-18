# Copyright (c) 2009-2019 The Regents of the University of Michigan
# This file is part of the HOOMD-blue project, released under the BSD 3-Clause License.

# Maintainer: joaander

R""" Utilities.
"""

import sys;
import traceback;
import os.path;
import linecache;
import re;
import hoomd;
from hoomd import _hoomd;

## \internal
# \brief Compatibility definition of a basestring for python 2/3
try:
    _basestring = basestring
except NameError:
    _basestring = str

## \internal
# \brief Checks if a variable is an instance of a string and always returns a list.
# \param s Variable to turn into a list
# \returns A list
def listify(s):
    if isinstance(s, _basestring):
        return [s]
    else:
        return list(s)

## \internal
# \brief Internal flag tracking if status lines should be quieted
_status_quiet_count = 0;

def cuda_profile_start():
    """ Start CUDA profiling.

    When using nvvp to profile CUDA kernels in hoomd jobs, you usually don't care about all the initialization and
    startup. cuda_profile_start() allows you to not even record that. To use, uncheck the box "start profiling on
    application start" in your nvvp session configuration. Then, call cuda_profile_start() in your hoomd script when
    you want nvvp to start collecting information.

    Example::

        from hoomd import *
        init.read_xml("init.xml");
        # setup....
        run(30000);  # warm up and auto-tune kernel block sizes
        option.set_autotuner_params(enable=False);  # prevent block sizes from further autotuning
        cuda_profile_start();
        run(100);

    """
    # check if initialization has occurred
    if not hoomd.init.is_initialized():
        raise RuntimeError("Cannot start profiling before initialization\n");

    if hoomd.context.current.device.cpp_exec_conf.isCUDAEnabled():
        hoomd.context.current.device.cpp_exec_conf.cudaProfileStart();

def cuda_profile_stop():
    """ Stop CUDA profiling.

        See Also:
            :py:func:`cuda_profile_start()`.
    """
    # check if initialization has occurred
    if not hoomd.init.is_initialized():
        hoomd.context.current.device.cpp_msg.error("Cannot stop profiling before initialization\n");
        raise RuntimeError('Error stopping profile');

    if hoomd.context.current.device.cpp_exec_conf.isCUDAEnabled():
        hoomd.context.current.device.cpp_exec_conf.cudaProfileStop();


def to_camel_case(string):
    return string.replace('_', ' ').title().replace(' ', '')


def is_iterable(obj):
    '''Returns True if object is iterable and not a str or dict.'''
    return hasattr(obj, '__iter__') and not bad_iterable_type(obj)


def bad_iterable_type(obj):
    '''Returns True if str or dict.'''
    return isinstance(obj, str) or isinstance(obj, dict)


def dict_map(dict_, func):
    new_dict = dict()
    for key, value in dict_.items():
        if isinstance(value, dict):
            new_dict[key] = dict_map(value, func)
        else:
            new_dict[key] = func(value)
    return new_dict


def dict_fold(dict_, func, init_value, use_keys=False):
    final_value = init_value
    for key, value in dict_.items():
        if isinstance(value, dict):
            final_value = dict_fold(value, func, final_value)
        else:
            if use_keys:
                final_value = func(key, final_value)
            else:
                final_value = func(value, final_value)
    return final_value
