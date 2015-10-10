"""
FindStat Cartan Types
"""

from sage.combinat.root_system.cartan_type import CartanType

class CartanTypeFindStat(object):
    """
    A Cartan type class for FindStat
    """
    def __init__(self, ct):
        self._cartan_type = CartanType(ct)

    def __hash__(self):
        return hash(self._cartan_type)

    def _latex_(self):
        return self._cartan_type.dynkin_diagram()._latex_()

    def __repr__(self):
        return self._cartan_type._repr_()

    _repr_ = __repr__

