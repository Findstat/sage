#*****************************************************************************
#       Copyright (C) 2005 William Stein <wstein@gmail.com>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#
#    This code is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#  The full text of the GPL is available at:
#
#                  http://www.gnu.org/licenses/
#*****************************************************************************

include "../../ext/interrupt.pxi"
include "../../ext/stdsage.pxi"
include 'misc.pxi'
include 'decl.pxi'

from ntl_ZZ import unpickle_class_args
from ntl_GF2EContext import ntl_GF2EContext
from ntl_GF2EContext cimport ntl_GF2EContext_class
from ntl_GF2E cimport ntl_GF2E

##############################################################################
#
# ntl_GF2EX: Polynomials over GF(2) via NTL
#
# AUTHORS:
#  - Martin Albrecht <malb@informatik.uni-bremen.de> 2006-01: initial version
#
##############################################################################

cdef class ntl_GF2EX:
    r"""
    Minimal wrapper of NTL's GF2EX class.
    """
    def __init__(self, modulus=None, x=[]):
        """
        Minimal wrapper of NTL's GF2EX class.

        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            [[1] [0 1]]
        """
        if modulus is None:
            raise ValueError, "You must specify a modulus when creating a GF2E."

        s = str(x)
        sig_on()
        GF2EX_from_str(&self.x, s)
        sig_off()

    def __cinit__(self, modulus=None, x=[]):
        #################### WARNING ###################
        ## Before creating a GF2E, you must create a  ##
        ## GF2EContext, and restore it.  In Python,   ##
        ## the error checking in __init__ will prevent##
        ## you from constructing an ntl_GF2E          ##
        ## inappropriately.  However, from Cython, you##
        ## could do r = PY_NEW(ntl_GF2E) without      ##
        ## first restoring a GF2EContext, which could ##
        ## have unfortunate consequences.  See _new  ##
        ## defined below for an example of the right  ##
        ## way to short-circuit __init__ (or just call##
        ## _new in your own code).                    ##
        ################################################
        if modulus is None:
            return
        if PY_TYPE_CHECK( modulus, ntl_GF2EContext_class ):
            self.c = <ntl_GF2EContext_class>modulus
            self.c.restore_c()
            GF2EX_construct(&self.x)
        else:
            self.c = <ntl_GF2EContext_class>ntl_GF2EContext(modulus)
            self.c.restore_c()
            GF2EX_construct(&self.x)

    cdef ntl_GF2E _new_element(self):
        cdef ntl_GF2E r
        self.c.restore_c()
        r = PY_NEW(ntl_GF2E)
        r.c = self.c
        return r

    cdef ntl_GF2EX _new(self):
        cdef ntl_GF2EX r
        self.c.restore_c()
        r = PY_NEW(ntl_GF2EX)
        r.c = self.c
        return r

    def modulus_context(self):
        return self.c

    def __dealloc__(self):
        if <object>self.c is not None:
            self.c.restore_c()
        GF2EX_destruct(&self.x)

    def __reduce__(self):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0 1] [1 0 0 1] [1]]')
            sage: f == loads(dumps(f))
            True
        """
        return unpickle_class_args, (ntl_GF2EX, (self.c, self.__repr__()))

    def __cmp__(self, other):
        """
        Compare self to other.

        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0 1] [1 0 0 1] [1]]')
            sage: g = ntl.GF2EX(ctx, '[[1 0 1] [1 1] [1] [0 0 1]]')
            sage: f == f
            True
            sage: f == g
            False
        """
        ## TODO: this is shady. fix that.
        if (type(self) != type(other)):
            return cmp(type(self), type(other))
        return cmp(self.__repr__(), other.__repr__())

    def __repr__(self):
        """
        Return the string representation of self.

        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: ntl.GF2EX(ctx, '[[1 0] [2 1]]').__repr__()
            '[[1] [0 1]]'
        """
        return GF2EX_to_PyString(&self.x)

    def __mul__(ntl_GF2EX self, other):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            sage: g = ntl.GF2EX(ctx, '[[1 0 1 1] [0 1 1 0 1] [1 0 1]]')
            sage: f*g ## indirect doctest
            [[1 0 1 1] [0 0 1 1] [1 0 0 1 0 1] [0 1 0 1]]
        """
        cdef ntl_GF2EX y
        cdef ntl_GF2EX r = self._new()
        if not isinstance(other, ntl_GF2EX):
            other = ntl_GF2EX(self.c, other)
        y = other
        sig_on()
        GF2EX_mul(r.x, self.x, y.x)
        sig_off()
        return r

    def __sub__(ntl_GF2EX self, other):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            sage: g = ntl.GF2EX(ctx, '[[1 0 1 1] [0 1 1 0 1] [1 0 1]]')
            sage: f-g ## indirect doctest
            [[0 0 1 1] [0 0 1 0 1] [1 0 1]]
        """
        cdef ntl_GF2EX y
        cdef ntl_GF2EX r = self._new()
        if not isinstance(other, ntl_GF2EX):
            other = ntl_GF2EX(self.c, other)
        y = other
        sig_on()
        GF2EX_sub(r.x, self.x, y.x)
        sig_off()
        return r

    def __add__(ntl_GF2EX self, other):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            sage: g = ntl.GF2EX(ctx, '[[1 0 1 1] [0 1 1 0 1] [1 0 1]]')
            sage: f+g ## indirect doctest
            [[0 0 1 1] [0 0 1 0 1] [1 0 1]]
        """
        cdef ntl_GF2EX y
        cdef ntl_GF2EX r = self._new()
        if not isinstance(other, ntl_GF2EX):
            other = ntl_GF2EX(self.c, other)
        y = other
        sig_on()
        GF2EX_add(r.x, self.x, y.x)
        sig_off()
        return r

    def __neg__(ntl_GF2EX self):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            sage: -f ## indirect doctest
            [[1] [0 1]]
        """
        cdef ntl_GF2EX r = self._new()
        sig_on()
        GF2EX_negate(r.x, self.x)
        sig_off()
        return r

    def __pow__(ntl_GF2EX self, long e, ignored):
        """
        EXAMPLES:
            sage: ctx = ntl.GF2EContext(ntl.GF2X([1,1,0,1,1,0,1]))
            sage: f = ntl.GF2EX(ctx, '[[1 0] [2 1]]')
            sage: f**2 ## indirect doctest
            [[1] [] [0 0 1]]
        """
        cdef ntl_GF2EX r = self._new()
        sig_on()
        GF2EX_power(r.x, self.x, e)
        sig_off()
        return r