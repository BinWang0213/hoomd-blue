# coding: utf-8

# Copyright (c) 2009-2019 The Regents of the University of Michigan
# This file is part of the HOOMD-blue project, released under the BSD 3-Clause
# License.

# Maintainer: joaander / All Developers are free to add commands for new
# features


from hoomd.md import _md
import hoomd
from hoomd.integrate import _DynamicIntegrator
from hoomd.parameterdicts import ParameterDict


class Integrator(_DynamicIntegrator):
    R""" Enables a variety of standard integration methods.

    Args: dt (float): Each time step of the simulation :py:func:`hoomd.run()`
    will advance the real time of the system forward by *dt* (in time units).
    aniso (bool): Whether to integrate rotational degrees of freedom (bool),
    default None (autodetect).

    :py:class:`mode_standard` performs a standard time step integration
    technique to move the system forward. At each time step, all of the
    specified forces are evaluated and used in moving the system forward to the
    next step.

    By itself, :py:class:`mode_standard` does nothing. You must specify one or
    more integration methods to apply to the system. Each integration method can
    be applied to only a specific group of particles enabling advanced
    simulation techniques.

    The following commands can be used to specify the integration methods used
    by integrate.mode_standard.

    - :py:class:`brownian`
    - :py:class:`langevin`
    - :py:class:`nve`
    - :py:class:`nvt`
    - :py:class:`npt`
    - :py:class:`nph`

    There can only be one integration mode active at a time. If there are more
    than one ``integrate.mode_*`` commands in a hoomd script, only the most
    recent before a given :py:func:`hoomd.run()` will take effect.

    Examples::

        integrate.mode_standard(dt=0.005) integrator_mode =
        integrate.mode_standard(dt=0.001)

    Some integration methods (notable :py:class:`nvt`, :py:class:`npt` and
    :py:class:`nph` maintain state between different :py:func:`hoomd.run()`
    commands, to allow for restartable simulations. After adding or removing
    particles, however, a new :py:func:`hoomd.run()` will continue from the old
    state and the integrator variables will re-equilibrate.  To ensure
    equilibration from a unique reference state (such as all integrator
            variables set to zero), the method :py:method:reset_methods() can be
    use to re-initialize the variables.
    """

    def __init__(self, dt, aniso=None, forces=None, constraint_forces=None,
                 methods=None):

        super().__init__(forces, constraint_forces, methods)

        def validate_aniso(value):
            if value is True:
                return "true"
            elif value is False:
                return "false"
            elif value.lower() == 'true':
                return "true"
            elif value.lower() == 'false':
                return "false"
            elif value.lower() == 'auto':
                return "auto"
            else:
                raise ValueError("input could not be converted to a proper "
                                 "anisotropic mode.")

        self.param_dict = ParameterDict(dt=float(dt), aniso=validate_aniso,
                                        explicit_defaults=dict(aniso="auto")
                                        )
        if aniso is not None:
            self.aniso = aniso

    def attach(self, simulation):
        # initialize the reflected c++ class
        self._cpp_obj = _md.IntegratorTwoStep(simulation.state._cpp_sys_def,
                                              self.dt)
        self._apply_param_dict()
        super().attach(simulation)
